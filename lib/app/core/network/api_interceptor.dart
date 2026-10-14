// lib/app/core/network/api_interceptor.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../config/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/wire_date.dart';

/// Escritura en línea cuyo resultado quedó incierto (sin respuesta o 5xx).
class UncertainWrite {
  final String method;
  final String path;
  final String key;
  final DateTime at;
  bool used = false;

  UncertainWrite({
    required this.method,
    required this.path,
    required this.key,
    required this.at,
  });

  Map<String, dynamic> toJson() => {'method': method, 'path': path, 'key': key};

  static UncertainWrite? fromJson(dynamic json) {
    if (json is! Map) return null;
    final method = json['method'];
    final path = json['path'];
    final key = json['key'];
    if (method is! String || path is! String || key is! String) return null;
    return UncertainWrite(method: method, path: path, key: key, at: DateTime.now());
  }
}

class ApiInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  // Header key para idempotencia
  static const String idempotencyKeyHeader = 'Idempotency-Key';

  // Cache en memoria para evitar lecturas repetidas
  String? _cachedToken;
  String? _cachedDeviceId;
  bool _cacheInitialized = false;

  // ── Token refresh mutex ──────────────────────────────────────────────────────
  // Garantiza que solo UN refresh ocurra a la vez aunque lleguen varios 401
  // simultáneos. Los demás esperan el resultado del primero.
  static bool _isRefreshing = false;
  static final List<Completer<String?>> _refreshWaiters = [];

  // ── Session-expired signal ───────────────────────────────────────────────────
  // Flag consumible que DioClient lee para saber si el interceptor confirmó
  // que la sesión expiró (vs. un error de red temporal).
  static bool _sessionDefinitelyExpired = false;

  // Callback opcional para notificación inmediata (registrado por DioClient).
  static void Function()? _sessionExpiredCallback;

  /// Registra el callback que se llama cuando el servidor rechaza el refresh
  /// token. DioClient lo usa para notificar a AuthController sin import cíclico.
  static void setSessionExpiredCallback(void Function() callback) {
    _sessionExpiredCallback = callback;
  }

  /// Consume y resetea el flag de sesión expirada.
  /// DioClient lo llama en _handleUnauthorizedRedirect para distinguir
  /// "sesión expirada confirmada" de "error de red temporal".
  static bool takeSessionExpiredFlag() {
    final value = _sessionDefinitelyExpired;
    _sessionDefinitelyExpired = false;
    return value;
  }

  ApiInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // I/O paralelo en primera request, cache en las siguientes
      if (!_cacheInitialized) {
        final results = await Future.wait([
          _storageService.getToken(),
          _storageService.getOrCreateDeviceId(),
        ]);
        _cachedToken = results[0];
        _cachedDeviceId = results[1];
        _cacheInitialized = true;
      } else {
        // Refrescar solo el token (puede cambiar durante la sesión)
        _cachedToken = await _storageService.getToken();
      }

      // Token de autorización
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        options.headers[ApiConstants.authorization] =
            '${ApiConstants.bearerPrefix}$_cachedToken';
      }

      // Headers estándar
      options.headers['X-Requested-With'] = 'XMLHttpRequest';

      // Device ID (estable durante toda la sesión)
      if (_cachedDeviceId != null) {
        options.headers['X-Device-ID'] = _cachedDeviceId;
      }
    } catch (_) {
      // Fallback: intentar solo el token si algo falla
      try {
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers[ApiConstants.authorization] =
              '${ApiConstants.bearerPrefix}$token';
        }
      } catch (_) {}
      options.headers['X-Requested-With'] = 'XMLHttpRequest';
    }

    // ZONA HORARIA: ninguna fecha-hora sale del dispositivo sin su desfase.
    // Aplica a TODOS los módulos y a las operaciones de la cola offline:
    // el servidor recibe el instante exacto en vez de tener que adivinar la
    // zona (antes los abonos quedaban guardados varias horas corridos).
    try {
      final data = options.data;
      if (data is Map || data is List) {
        options.data = withExplicitOffsets(data);
      }
      if (options.queryParameters.isNotEmpty) {
        options.queryParameters = Map<String, dynamic>.from(
          withExplicitOffsets(options.queryParameters) as Map,
        );
      }
    } catch (_) {
      // Si algo falla aquí, la petición sale como estaba: el servidor
      // interpreta las horas sin zona con la zona del negocio.
    }

    // Agregar Idempotency-Key para operaciones que modifican datos
    if (_requiresIdempotency(options.method)) {
      // Verificar si ya tiene un idempotency key en extras
      final customKey = options.extra['idempotency_key'] as String?;

      if (customKey != null && customKey.isNotEmpty) {
        options.headers[idempotencyKeyHeader] = customKey;
      } else if (options.headers[idempotencyKeyHeader] == null) {
        // Petición hecha mientras se procesa una operación de la cola de
        // sincronización: clave ESTABLE, igual en cada reintento de esa
        // operación, para que el servidor nunca la ejecute dos veces.
        final syncKey = _syncOperationIdempotencyKey(options);
        if (syncKey != null) {
          options.headers[idempotencyKeyHeader] = syncKey;
        } else {
          // Generar idempotency key automáticamente basado en el request
          final generatedKey = _generateIdempotencyKey(options);
          options.headers[idempotencyKeyHeader] = generatedKey;
        }
      }
    }

    super.onRequest(options, handler);
  }

  /// Verifica si el método HTTP requiere idempotencia
  bool _requiresIdempotency(String method) {
    final methodUpper = method.toUpperCase();
    return methodUpper == 'POST' || methodUpper == 'PUT' || methodUpper == 'PATCH';
  }

  /// Clave de zona con el identificador de la operación de la cola que se
  /// está sincronizando (la fija `SyncService` al procesar cada operación).
  static const Symbol syncOperationZoneKey = #baudexSyncOperationKey;

  /// Clave de zona con el contador de peticiones ya hechas por esa operación.
  static const Symbol syncOperationSeqZoneKey = #baudexSyncOperationSeq;

  /// Clave de zona con las claves heredadas del intento en línea que
  /// originó la operación (ver [claimUncertainWrites]).
  static const Symbol syncOperationInheritedKeysZoneKey =
      #baudexSyncOperationInheritedKeys;

  // ── Escrituras "inciertas" ─────────────────────────────────────────────────
  // Una escritura hecha en línea que terminó SIN respuesta (timeout, red
  // caída) o con error del servidor (5xx) pudo haberse aplicado igual. Los
  // repositorios, al fallar, guardan el cambio offline y lo encolan; al subir
  // la cola se enviaría OTRA vez → duplicado.
  //
  // Para evitarlo en todos los módulos, se recuerda la clave de idempotencia
  // de esa escritura incierta y la operación encolada justo después la
  // HEREDA: su envío usa la misma clave, y el servidor devuelve lo que ya
  // había procesado en vez de crearlo de nuevo.
  static final List<UncertainWrite> _uncertainWrites = <UncertainWrite>[];
  static const Duration _uncertainWriteMaxAge = Duration(seconds: 10);

  void _recordUncertainWrite(DioException err) {
    try {
      final options = err.requestOptions;
      final method = options.method.toUpperCase();
      if (!_requiresIdempotency(method)) return;
      // Las peticiones de la propia cola ya tienen su clave estable.
      if (Zone.current[syncOperationZoneKey] != null) return;

      final status = err.response?.statusCode;
      final uncertain = status == null || status >= 500 || status == 408;
      if (!uncertain) return;

      final key = options.headers[idempotencyKeyHeader];
      if (key is! String || key.isEmpty) return;

      final now = DateTime.now();
      _uncertainWrites.removeWhere(
        (w) => now.difference(w.at) > _uncertainWriteMaxAge,
      );
      _uncertainWrites.add(
        UncertainWrite(method: method, path: options.path, key: key, at: now),
      );
    } catch (_) {}
  }

  /// Entrega (y retira) las escrituras inciertas recientes que corresponden
  /// al tipo de entidad que se está encolando, para que esa operación herede
  /// sus claves. La llama `SyncService.addOperation`, que corre
  /// inmediatamente después del intento en línea fallido, dentro de la misma
  /// acción del usuario.
  ///
  /// Cada escritura incierta la hereda UNA sola operación (se retira al
  /// entregarla) y solo si su ruta corresponde a la entidad: así una venta
  /// posterior nunca recibe la clave de una venta anterior, y las operaciones
  /// auxiliares que se encolan junto a la principal (inventario, etc.) no se
  /// la quitan.
  static List<UncertainWrite> claimUncertainWrites({String? entityType}) {
    final now = DateTime.now();
    _uncertainWrites.removeWhere(
      (w) => now.difference(w.at) > _uncertainWriteMaxAge,
    );
    if (entityType == null) {
      final all = List<UncertainWrite>.from(_uncertainWrites);
      _uncertainWrites.clear();
      return all;
    }

    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final entityToken = normalize(entityType);
    if (entityToken.isEmpty) return <UncertainWrite>[];

    final claimed = _uncertainWrites
        .where((w) => normalize(w.path).contains(entityToken))
        .toList();
    _uncertainWrites.removeWhere(claimed.contains);
    return claimed;
  }

  /// Clave de idempotencia estable para una petición hecha dentro del
  /// procesamiento de una operación de la cola. Devuelve `null` si la
  /// petición no pertenece a ninguna operación de la cola.
  ///
  /// Se compone de: dispositivo + operación + método + ruta + contenido +
  /// número de repetición dentro de la operación. Así:
  ///  - el reintento de la misma operación produce exactamente las mismas
  ///    claves, y el servidor devuelve lo ya procesado sin duplicar;
  ///  - dos peticiones distintas de la misma operación nunca comparten clave.
  String? _syncOperationIdempotencyKey(RequestOptions options) {
    final operationKey = Zone.current[syncOperationZoneKey];
    final sequence = Zone.current[syncOperationSeqZoneKey];
    if (operationKey is! String || sequence is! Map<String, int>) return null;

    // ¿La operación heredó la clave de un intento en línea que quedó
    // incierto? Entonces esta petición (mismo método y ruta) es el reenvío
    // de aquel intento: usar SU clave, una sola vez por intento de sync.
    final inherited = Zone.current[syncOperationInheritedKeysZoneKey];
    if (inherited is List<UncertainWrite>) {
      final method = options.method.toUpperCase();
      final index = inherited.indexWhere(
        (w) => !w.used && w.method == method && w.path == options.path,
      );
      if (index >= 0) {
        inherited[index].used = true;
        return inherited[index].key;
      }
    }

    String bodyHash = '';
    final data = options.data;
    if (data != null) {
      if (data is FormData) return null; // subidas de archivos: no aplica
      try {
        final bodyString = data is String ? data : jsonEncode(data);
        bodyHash = md5.convert(utf8.encode(bodyString)).toString();
      } catch (_) {
        return null;
      }
    }

    final slot = '${options.method.toUpperCase()}|${options.path}|$bodyHash';
    final repetition = (sequence[slot] ?? 0) + 1;
    sequence[slot] = repetition;

    final material = '${_cachedDeviceId ?? ''}|$operationKey|$slot|$repetition';
    final hash = sha256.convert(utf8.encode(material)).toString();
    return 'op_${hash.substring(0, 48)}';
  }

  /// Genera una clave de idempotencia basada en el request
  /// La clave es un hash del path + body + timestamp (redondeado a 5 segundos)
  String _generateIdempotencyKey(RequestOptions options) {
    // Usar timestamp redondeado a ventana de 5 segundos para permitir reintentos rápidos
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 5000) * 5000;
    final path = options.path;
    final method = options.method;

    // Serializar body de forma consistente
    String bodyHash = '';
    if (options.data != null) {
      try {
        final bodyString = options.data is String
            ? options.data as String
            : jsonEncode(options.data);
        final bytes = utf8.encode(bodyString);
        bodyHash = md5.convert(bytes).toString();
      } catch (e) {
        bodyHash = options.data.hashCode.toString();
      }
    }

    // Crear key combinando elementos
    final keyData = '$method:$path:$bodyHash:$timestamp';
    final keyBytes = utf8.encode(keyData);
    final keyHash = sha256.convert(keyBytes).toString();

    return 'idem_${keyHash.substring(0, 32)}';
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Procesar respuesta si es necesario
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _recordUncertainWrite(err);

    final skipAuthInterceptor =
        err.requestOptions.extra['skip_auth_interceptor'] == true;

    if (err.response?.statusCode == 401 && !skipAuthInterceptor) {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null) {
        // Sin refresh token → sesión definitivamente expirada
        _cachedToken = null;
        _markSessionExpired();
      } else if (_isRefreshing) {
        // Otro refresh ya está en curso → encolar y esperar su resultado
        final completer = Completer<String?>();
        _refreshWaiters.add(completer);
        final newToken = await completer.future;

        if (newToken != null) {
          // El primer refresh tuvo éxito: reintentar con el nuevo token
          final opts = err.requestOptions;
          opts.headers[ApiConstants.authorization] =
              '${ApiConstants.bearerPrefix}$newToken';
          try {
            final response = await Dio().fetch(opts);
            return handler.resolve(response);
          } catch (_) {}
        }
        // newToken == null → sesión expirada ya fue marcada por el primer refresh
      } else {
        // Somos el primer 401 → iniciar el refresh
        _isRefreshing = true;
        try {
          final result = await _refreshToken(refreshToken);

          if (result.token != null) {
            // ✅ Refresh exitoso: guardar token y desbloquear waiters
            await _storageService.saveToken(result.token!);
            _cachedToken = result.token;

            final newToken = result.token!;
            for (final c in _refreshWaiters) {
              if (!c.isCompleted) c.complete(newToken);
            }
            _refreshWaiters.clear();

            // Reintentar la request original con el nuevo token
            final opts = err.requestOptions;
            opts.headers[ApiConstants.authorization] =
                '${ApiConstants.bearerPrefix}$newToken';
            try {
              final response = await Dio().fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          } else if (result.wasAuthError) {
            // ❌ Servidor rechazó el refresh token → sesión expirada definitivamente
            await _storageService.deleteToken();
            await _storageService.deleteRefreshToken();
            await _storageService.deleteUserData();
            _cachedToken = null;

            for (final c in _refreshWaiters) {
              if (!c.isCompleted) c.complete(null);
            }
            _refreshWaiters.clear();

            _markSessionExpired();
          }
          // wasNetworkError: no marcar sesión expirada, el token podría seguir válido
        } finally {
          _isRefreshing = false;
        }
      }
    }

    super.onError(err, handler);
  }

  /// Marca la sesión como definitivamente expirada y notifica al listener.
  void _markSessionExpired() {
    _sessionDefinitelyExpired = true;
    try {
      _sessionExpiredCallback?.call();
    } catch (_) {}
  }

  // Resultado del intento de refresh
  // Método para refrescar token
  Future<_RefreshResult> _refreshToken(String refreshToken) async {
    try {
      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final response = await dio.post(
        ApiConstants.refreshToken,
        options: Options(
          headers: {
            ApiConstants.authorization:
                '${ApiConstants.bearerPrefix}$refreshToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        // Soportar respuesta plana {token:...} Y envuelta {success:true,data:{token:...}}
        final data = (raw is Map && raw['data'] is Map)
            ? raw['data'] as Map
            : raw;
        final token = data is Map ? data['token'] as String? : null;
        if (token != null && token.isNotEmpty) {
          return _RefreshResult(token: token);
        }
      }
      // Respuesta sin token = auth error
      return _RefreshResult(wasAuthError: true);
    } on DioException catch (e) {
      // 401/403 del endpoint de refresh = refresh token inválido/expirado
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return _RefreshResult(wasAuthError: true);
      }
      // Cualquier otro error (timeout, red, 500) = no sabemos si el token es válido
      return _RefreshResult(wasNetworkError: true);
    } catch (e) {
      return _RefreshResult(wasNetworkError: true);
    }
  }
}

/// Resultado del intento de refresh token
class _RefreshResult {
  final String? token;
  final bool wasAuthError;
  final bool wasNetworkError;

  _RefreshResult({
    this.token,
    this.wasAuthError = false,
    this.wasNetworkError = false,
  });
}
