// lib/app/core/network/api_interceptor.dart
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
    // Verificar si se debe saltar el interceptor de auth para esta request
    final skipAuthInterceptor = err.requestOptions.extra['skip_auth_interceptor'] == true;

    // Manejo específico para token expirado (401)
    if (err.response?.statusCode == 401 && !skipAuthInterceptor) {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken != null) {
        // Intentar refrescar token
        final refreshResult = await _refreshToken(refreshToken);

        if (refreshResult.token != null) {
          // Guardar nuevo token y actualizar cache
          await _storageService.saveToken(refreshResult.token!);
          _cachedToken = refreshResult.token;

          // Reintentar la solicitud original
          final options = err.requestOptions;
          options.headers[ApiConstants.authorization] =
              '${ApiConstants.bearerPrefix}${refreshResult.token}';

          try {
            final response = await Dio().fetch(options);
            return handler.resolve(response);
          } catch (e) {
            // Si falla el reintento, continuar con el error original
          }
        } else if (refreshResult.wasAuthError) {
          // Solo limpiar datos si el servidor EXPLÍCITAMENTE rechazó el refresh token (401/403)
          // NO limpiar si fue un error de red (servidor inalcanzable)
          print('🔑 Refresh token rechazado por servidor - limpiando auth data');
          await _storageService.deleteToken();
          await _storageService.deleteRefreshToken();
          await _storageService.deleteUserData();
          _cachedToken = null;
        }
        // Si fue error de red, NO borrar datos - el token podría seguir siendo válido
      }
      // Si no hay refresh token pero sí había un access token, no borrar nada
      // El DioClient decidirá si hacer logout
    }

    super.onError(err, handler);
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
        final data = response.data;
        final token = data['token'] as String?;
        if (token != null) {
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
