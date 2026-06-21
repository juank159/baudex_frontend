// lib/app/core/network/api_interceptor.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../config/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

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

    // Agregar Idempotency-Key para operaciones que modifican datos
    if (_requiresIdempotency(options.method)) {
      // Verificar si ya tiene un idempotency key en extras
      final customKey = options.extra['idempotency_key'] as String?;

      if (customKey != null && customKey.isNotEmpty) {
        options.headers[idempotencyKeyHeader] = customKey;
      } else if (options.headers[idempotencyKeyHeader] == null) {
        // Generar idempotency key automáticamente basado en el request
        final generatedKey = _generateIdempotencyKey(options);
        options.headers[idempotencyKeyHeader] = generatedKey;
      }
    }

    super.onRequest(options, handler);
  }

  /// Verifica si el método HTTP requiere idempotencia
  bool _requiresIdempotency(String method) {
    final methodUpper = method.toUpperCase();
    return methodUpper == 'POST' || methodUpper == 'PUT' || methodUpper == 'PATCH';
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
        print('🔑 Refresh token expirado (${e.response?.statusCode})');
        return _RefreshResult(wasAuthError: true);
      }
      // Cualquier otro error (timeout, red, 500) = no sabemos si el token es válido
      print('⚠️ Error de red al refrescar token (NO se borra auth): $e');
      return _RefreshResult(wasNetworkError: true);
    } catch (e) {
      print('⚠️ Error inesperado al refrescar token: $e');
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
