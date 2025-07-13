// // lib/app/core/network/dio_client.dart
// import 'package:dio/dio.dart';
// import 'package:get/get.dart' as getx;
// import '../../config/constants/api_constants.dart';
// import '../storage/secure_storage_service.dart';
// import 'api_interceptor.dart';

// class DioClient {
//   late Dio _dio;
//   final SecureStorageService _storageService = getx.Get.find();

//   DioClient() {
//     _dio = Dio();
//     _initializeDio();
//   }

//   void _initializeDio() {
//     _dio.options = BaseOptions(
//       baseUrl: ApiConstants.baseUrl,
//       connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
//       receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
//       sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
//       headers: {
//         'Content-Type': ApiConstants.contentType,
//         'Accept': ApiConstants.accept,
//       },
//     );

//     // Agregar interceptors
//     _dio.interceptors.add(ApiInterceptor(_storageService));

//     // Interceptor para logs en desarrollo
//     if (getx.GetPlatform.isDebug) {
//       _dio.interceptors.add(
//         LogInterceptor(
//           requestBody: true,
//           responseBody: true,
//           requestHeader: true,
//           responseHeader: false,
//           error: true,
//           logPrint: (obj) => print('DIO: $obj'),
//         ),
//       );
//     }
//   }

//   // GET Request
//   Future<Response> get(
//     String endpoint, {
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     try {
//       final response = await _dio.get(
//         endpoint,
//         queryParameters: queryParameters,
//         options: options,
//       );
//       return response;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // POST Request
//   Future<Response> post(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     try {
//       final response = await _dio.post(
//         endpoint,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//       );
//       return response;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // PUT Request
//   Future<Response> put(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     try {
//       final response = await _dio.put(
//         endpoint,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//       );
//       return response;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // PATCH Request
//   Future<Response> patch(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     try {
//       final response = await _dio.patch(
//         endpoint,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//       );
//       return response;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // DELETE Request
//   Future<Response> delete(
//     String endpoint, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//   }) async {
//     try {
//       final response = await _dio.delete(
//         endpoint,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//       );
//       return response;
//     } on DioException catch (e) {
//       throw _handleDioError(e);
//     }
//   }

//   // Manejo de errores de Dio
//   Exception _handleDioError(DioException error) {
//     switch (error.type) {
//       case DioExceptionType.connectionTimeout:
//       case DioExceptionType.sendTimeout:
//       case DioExceptionType.receiveTimeout:
//         return Exception('Tiempo de conexión agotado');

//       case DioExceptionType.badResponse:
//         final statusCode = error.response?.statusCode;
//         final message = error.response?.data?['message'] ?? 'Error desconocido';

//         switch (statusCode) {
//           case 400:
//             return Exception('Solicitud incorrecta: $message');
//           case 401:
//             // Token expirado o inválido
//             _handleUnauthorized();
//             return Exception('No autorizado: $message');
//           case 403:
//             return Exception('Acceso prohibido: $message');
//           case 404:
//             return Exception('Recurso no encontrado: $message');
//           case 409:
//             return Exception('Conflicto: $message');
//           case 500:
//             return Exception('Error interno del servidor');
//           default:
//             return Exception('Error: $message');
//         }

//       case DioExceptionType.cancel:
//         return Exception('Solicitud cancelada');

//       case DioExceptionType.unknown:
//         if (error.message?.contains('SocketException') == true) {
//           return Exception('Sin conexión a internet');
//         }
//         return Exception('Error de conexión');

//       default:
//         return Exception('Error desconocido: ${error.message}');
//     }
//   }

//   // Manejo de token expirado
//   void _handleUnauthorized() {
//     // Limpiar datos de autenticación
//     _storageService.deleteToken();
//     _storageService.deleteUserData();

//     // Redirigir al login
//     getx.Get.offAllNamed('/login');
//   }

//   // Getter para acceso directo a Dio si es necesario
//   Dio get dio => _dio;
// }

// lib/app/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../../config/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptor.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

class DioClient {
  late Dio _dio;
  final SecureStorageService _storageService = getx.Get.find();

  DioClient() {
    _dio = Dio();
    _initializeDio();
  }

  void _initializeDio() {
    // Mostrar configuración actual
    ApiConstants.printCurrentConfig();

    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
      },
    );

    // Agregar interceptors
    _dio.interceptors.add(ApiInterceptor(_storageService));

    // Interceptor para logs en desarrollo
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => print('DIO: $obj'),
        ),
      );
    }
  }

  // GET Request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🔍 GET Request: ${ApiConstants.baseUrl}$endpoint');
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ GET Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ GET Error: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('📤 POST Request: ${ApiConstants.baseUrl}$endpoint');
      if (data != null) {
        print('📋 POST Data: $data');
      }
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ POST Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ POST Error: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🔄 PUT Request: ${ApiConstants.baseUrl}$endpoint');
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ PUT Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ PUT Error: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🔧 PATCH Request: ${ApiConstants.baseUrl}$endpoint');
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ PATCH Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ PATCH Error: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('🗑️ DELETE Request: ${ApiConstants.baseUrl}$endpoint');
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('✅ DELETE Success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ DELETE Error: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Manejo de errores de Dio
  Exception _handleDioError(DioException error) {
    print('🚨 DioError Details:');
    print('   Type: ${error.type}');
    print('   Message: ${error.message}');
    print('   Response: ${error.response?.data}');
    print('   Status Code: ${error.response?.statusCode}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Tiempo de conexión agotado. Verifica tu conexión a internet.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Error desconocido';

        switch (statusCode) {
          case 400:
            return Exception('Solicitud incorrecta: $message');
          case 401:
            // Token expirado o inválido
            _handleUnauthorized();
            return Exception('No autorizado: $message');
          case 403:
            return Exception('Acceso prohibido: $message');
          case 404:
            return Exception('Recurso no encontrado: $message');
          case 409:
            return Exception('Conflicto: $message');
          case 500:
            return Exception('Error interno del servidor');
          default:
            return Exception('Error: $message');
        }

      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return Exception(
            'Sin conexión a internet. Verifica que el servidor esté corriendo en ${ApiConstants.baseUrl}',
          );
        }
        if (error.message?.contains('No route to host') == true) {
          return Exception(
            'No se puede conectar al servidor. Verifica la URL: ${ApiConstants.baseUrl}',
          );
        }
        return Exception('Error de conexión: ${error.message}');

      default:
        return Exception('Error desconocido: ${error.message}');
    }
  }

  // Manejo de token expirado
  void _handleUnauthorized() {
    print('🔑 Token expirado - limpiando datos de autenticación');
    // Limpiar datos de autenticación
    _storageService.deleteToken();
    _storageService.deleteUserData();

    // ✅ SOLUCIÓN: No hacer redirect automático desde interceptor HTTP
    // El AuthController manejará el redirect cuando detecte que no hay token
    print('⚠️ Sesión expirada - AuthController manejará el redirect');
    
    // Notificar al AuthController para que maneje el logout
    try {
      if (getx.Get.isRegistered<AuthController>()) {
        final authController = getx.Get.find<AuthController>();
        // Usar el método de logout que ya maneja la navegación correctamente
        authController.logout();
      }
    } catch (e) {
      print('⚠️ No se pudo notificar al AuthController: $e');
      // Como fallback, solo mostrar mensaje al usuario sin redirect inmediato
      getx.Get.snackbar(
        'Sesión Expirada',
        'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        snackPosition: getx.SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Getter para acceso directo a Dio si es necesario
  Dio get dio => _dio;
}
