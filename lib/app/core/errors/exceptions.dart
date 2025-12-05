// lib/app/core/errors/exceptions.dart

/// Excepción base para todas las excepciones de la aplicación
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Excepción del servidor - Errores de la API
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});

  /// Factory para crear desde código de estado HTTP
  factory ServerException.fromStatusCode(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return ServerException(
          'Solicitud incorrecta: $message',
          statusCode: statusCode,
        );
      case 401:
        return const ServerException('No autorizado', statusCode: 401);
      case 403:
        return const ServerException('Acceso prohibido', statusCode: 403);
      case 404:
        return ServerException(
          'No encontrado: $message',
          statusCode: statusCode,
        );
      case 409:
        return ServerException('Conflicto: $message', statusCode: statusCode);
      case 422:
        return ServerException(
          'Datos inválidos: $message',
          statusCode: statusCode,
        );
      case 500:
        return const ServerException(
          'Error interno del servidor',
          statusCode: 500,
        );
      case 502:
        return const ServerException('Servidor no disponible', statusCode: 502);
      case 503:
        return const ServerException('Servicio no disponible', statusCode: 503);
      default:
        return ServerException(
          'Error del servidor: $message',
          statusCode: statusCode,
        );
    }
  }
}

/// Excepción de conexión - Sin internet o problemas de red
class ConnectionException extends AppException {
  const ConnectionException([super.message = 'Error de conexión']);

  static const noInternet = ConnectionException('Sin conexión a internet');
  static const timeout = ConnectionException('Tiempo de conexión agotado');
  static const socketException = ConnectionException('Error de red');
}

/// Excepción de cache/almacenamiento local
class CacheException extends AppException {
  const CacheException([super.message = 'Error de cache']);

  static const notFound = CacheException('Datos no encontrados en cache');
  static const writeError = CacheException('Error al escribir en cache');
  static const readError = CacheException('Error al leer del cache');
}

/// Excepción de formato/parseo
class FormatException extends AppException {
  const FormatException([super.message = 'Error de formato']);

  static const jsonParse = FormatException('Error al parsear JSON');
  static const invalidData = FormatException('Datos inválidos');
}

/// Excepción de autenticación
class AuthException extends AppException {
  const AuthException([super.message = 'Error de autenticación']);

  static const invalidCredentials = AuthException('Credenciales inválidas');
  static const tokenExpired = AuthException('Sesión expirada');
  static const userNotFound = AuthException('Usuario no encontrado');
  static const emailAlreadyExists = AuthException(
    'El email ya está registrado',
  );
  static const noToken = AuthException('No hay token de acceso');
}

/// Excepción de validación
class ValidationException extends AppException {
  final List<String> errors;

  const ValidationException(this.errors) : super('Errores de validación');

  String get firstError => errors.isNotEmpty ? errors.first : message;
  String get allErrors => errors.join('\n');

  @override
  String toString() => allErrors;
}

/// Excepción de permisos
class PermissionException extends AppException {
  const PermissionException([super.message = 'Sin permisos']);

  static const accessDenied = PermissionException('Acceso denegado');
  static const insufficientPermissions = PermissionException(
    'Permisos insuficientes',
  );
}
