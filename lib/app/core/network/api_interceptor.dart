// lib/app/core/network/api_interceptor.dart
import 'package:dio/dio.dart';
import '../../config/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorageService _storageService;

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

    // Agregar headers adicionales si es necesario
    options.headers['X-Requested-With'] = 'XMLHttpRequest';

    super.onRequest(options, handler);
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
