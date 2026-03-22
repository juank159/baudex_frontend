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

  ApiInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Agregar token de autorización si existe
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authorization] =
          '${ApiConstants.bearerPrefix}$token';
    }

    // Agregar headers adicionales
    options.headers['X-Requested-With'] = 'XMLHttpRequest';

    // Agregar Device ID único para identificar este dispositivo
    try {
      final deviceId = await _storageService.getOrCreateDeviceId();
      options.headers['X-Device-ID'] = deviceId;
    } catch (_) {
      // No bloquear requests si falla obtener device ID
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
        final newToken = await _refreshToken(refreshToken);

        if (newToken != null) {
          // Guardar nuevo token
          await _storageService.saveToken(newToken);

          // Reintentar la solicitud original
          final options = err.requestOptions;
          options.headers[ApiConstants.authorization] =
              '${ApiConstants.bearerPrefix}$newToken';

          try {
            final response = await Dio().fetch(options);
            return handler.resolve(response);
          } catch (e) {
            // Si falla el reintento, continuar con el error original
          }
        }
      }

      // Si no se pudo refrescar el token, limpiar datos
      await _storageService.deleteToken();
      await _storageService.deleteRefreshToken();
      await _storageService.deleteUserData();
    }

    super.onError(err, handler);
  }

  // Método para refrescar token
  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;

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
        return data['token'] as String?;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }

    return null;
  }
}
