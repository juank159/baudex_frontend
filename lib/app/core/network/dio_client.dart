import 'dart:convert';
// // lib/app/core/network/dio_client.dart
// import 'package:dio/dio.dart';
// import 'package:get/get.dart' as getx;
// import '../../config/constants/api_constants.dart';
// import '../storage/secure_storage_service.dart';
// import 'api_interceptor.dart';
import 'bundled_roots.dart';

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
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../../config/constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptor.dart';
import '../../../core/network/tenant_interceptor.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../errors/exceptions.dart';

class DioClient {
  late Dio _dio;
  final SecureStorageService _storageService = getx.Get.find();

  DioClient() {
    BundledRoots.ensureTrusted();
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
        'User-Agent': _buildUserAgent(),
      },
    );

    // Agregar interceptors
    _dio.interceptors.add(ApiInterceptor(_storageService));
    // Registrar handler de sesión expirada para que el interceptor pueda
    // notificar a AuthController sin crear un import cíclico.
    ApiInterceptor.setSessionExpiredCallback(_onSessionDefinitelyExpired);
    
    // Agregar interceptor de tenant para multitenant
    _dio.interceptors.add(TenantInterceptor(_storageService));

    // Interceptor de logs DIO desactivado por defecto.
    // Generaba ~880 líneas por sesión (uri, headers, response body completo)
    // y dificultaba leer logs reales. Para reactivar puntualmente durante un
    // debug específico, exporta `BAUDEX_DIO_LOG=1` antes de `flutter run`.
    if (kDebugMode &&
        const bool.fromEnvironment('BAUDEX_DIO_LOG', defaultValue: false)) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestBody: false,
          requestHeader: false,
          responseBody: true,
          responseHeader: false,
          error: false,
          logPrint: (obj) {
            final str = obj.toString();
            if (!str.contains('DioException') &&
                !str.contains('Connection refused') &&
                !str.contains('SocketException')) {
            }
          },
        ),
      );
    }
  }

  static String _buildUserAgent() {
    try {
      final os = Platform.operatingSystem; // macos, windows, linux, android, ios
      final osVersion = Platform.operatingSystemVersion;
      final String deviceType;
      final String osName;

      if (Platform.isMacOS) {
        deviceType = 'Desktop';
        osName = 'macOS';
      } else if (Platform.isWindows) {
        deviceType = 'Desktop';
        osName = 'Windows';
      } else if (Platform.isLinux) {
        deviceType = 'Desktop';
        osName = 'Linux';
      } else if (Platform.isAndroid) {
        deviceType = 'Mobile';
        osName = 'Android';
      } else if (Platform.isIOS) {
        deviceType = 'Mobile';
        osName = 'iOS';
      } else {
        deviceType = 'Unknown';
        osName = os;
      }

      return 'Baudex/$deviceType ($osName; $osVersion)';
    } catch (e) {
      return 'Baudex/Unknown';
    }
  }

  // GET Request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
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
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
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
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
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
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
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
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Manejo de errores de Dio
  Exception _handleDioError(DioException error) {
    // NO imprimir ningún detalle de error

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException(
          'Tiempo de conexión agotado. Verifica tu conexión a internet.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);

        // 🔒 CRITICAL FIX: Return ServerException with statusCode for subscription errors
        if (statusCode == 403) {
          return ServerException(message, statusCode: 403);
        }

        switch (statusCode) {
          case 400:
            return ServerException('Solicitud incorrecta: $message', statusCode: 400);
          case 401:
            // Token expirado o inválido
            // NOTA: ApiInterceptor ya maneja refresh + limpieza de auth.
            // Solo notificar al AuthController para redirigir si auth data ya fue limpiada.
            final skipAuthInterceptor = error.requestOptions.extra['skip_auth_interceptor'] == true;
            if (!skipAuthInterceptor) {
              _handleUnauthorizedRedirect();
            }
            return ServerException(message, statusCode: 401);
          case 404:
            return ServerException('Recurso no encontrado: $message', statusCode: 404);
          case 409:
            return ServerException('Conflicto: $message', statusCode: 409);
          case 500:
            return ServerException('Error interno del servidor: $message', statusCode: 500);
          default:
            return ServerException('Error: $message', statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada');

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return connectionExceptionFor(error);
    }
  }

  /// La app no logró hablar con el servidor (sin internet, DNS, conexión
  /// rechazada, certificado que el equipo no reconoce, fecha del equipo
  /// mal...). Siempre es un [ConnectionException], con la causa real en el
  /// mensaje: antes un fallo de certificado salía como "Error de conexión:
  /// null" y uno de red como `ServerException('Error desconocido')`, y
  /// quien llamaba no podía saber que era la conexión.
  @visibleForTesting
  static ConnectionException connectionExceptionFor(DioException error) {
    final cause = (error.error ?? error.message ?? 'sin detalle').toString();
    if (error.type == DioExceptionType.badCertificate ||
        cause.contains('HandshakeException') ||
        cause.contains('CERTIFICATE_VERIFY_FAILED') ||
        cause.contains('TlsException')) {
      return ConnectionException(
        'No se pudo establecer una conexión segura con el servidor '
        '(certificado). Revisa la fecha y la hora del equipo, las '
        'actualizaciones de Windows y el antivirus. Detalle: $cause',
      );
    }
    if (cause.contains('No route to host')) {
      return ConnectionException(
        'No se puede conectar al servidor. Verifica la URL: ${ApiConstants.baseUrl}. Detalle: $cause',
      );
    }
    return ConnectionException(
      'Sin conexión con el servidor (${ApiConstants.baseUrl}). Detalle: $cause',
    );
  }

  // Notifica a AuthController que la sesión expiró de forma definitiva.
  // Es el target del callback registrado en ApiInterceptor.
  void _onSessionDefinitelyExpired() {
    final route = getx.Get.currentRoute;
    if (route == '/login' || route == '/register' ||
        route == '/forgot-password' || route == '/verify-email' ||
        route.contains('/reset')) {
      return;
    }
    try {
      if (getx.Get.isRegistered<AuthController>()) {
        getx.Get.find<AuthController>().handleSessionExpired();
      }
    } catch (_) {}
  }

  // Fallback para 401s que llegan a DioClient después de que el interceptor
  // propagó el error. Solo actúa si el interceptor confirmó que la sesión
  // expiró definitivamente (vs. un error de red temporal).
  void _handleUnauthorizedRedirect() {
    if (ApiInterceptor.takeSessionExpiredFlag()) {
      _onSessionDefinitelyExpired();
    }
    // Si el flag no está activo, fue un error de red temporal:
    // el token podría seguir siendo válido, NO redirigir.
  }

  /// Extrae mensaje de error de forma segura de response.data
  /// Maneja Map, String, List y null sin crashear
  static String _extractErrorMessage(dynamic data, [String defaultMessage = 'Error desconocido']) {
    if (data == null) return defaultMessage;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? defaultMessage;
    }
    if (data is Map) {
      return data['message']?.toString() ?? defaultMessage;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    // Peticiones que piden la respuesta en bytes (descarga de cambios).
    if (data is List<int> && data.isNotEmpty) {
      try {
        return _extractErrorMessage(
            jsonDecode(utf8.decode(data)), defaultMessage);
      } catch (_) {
        return defaultMessage;
      }
    }
    return defaultMessage;
  }

  // Getter para acceso directo a Dio si es necesario
  Dio get dio => _dio;
}
