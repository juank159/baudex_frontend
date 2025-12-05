// lib/app/core/errors/failures.dart
import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los fallos
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => message;
}

/// Fallo de servidor - Errores de la API
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  factory ServerFailure.fromStatusCode(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return ServerFailure(
          'Solicitud incorrecta: $message',
          code: statusCode,
        );
      case 401:
        return const ServerFailure(
          'No autorizado. Inicie sesión nuevamente.',
          code: 401,
        );
      case 403:
        return ServerFailure(
          message.isNotEmpty ? message : 'Acceso prohibido.',
          code: 403,
        );
      case 404:
        return ServerFailure(
          'Recurso no encontrado: $message',
          code: statusCode,
        );
      case 409:
        return ServerFailure('Conflicto: $message', code: statusCode);
      case 422:
        return ServerFailure('Datos inválidos: $message', code: statusCode);
      case 500:
        return const ServerFailure('Error interno del servidor.', code: 500);
      case 502:
        return const ServerFailure('Servidor no disponible.', code: 502);
      case 503:
        return const ServerFailure('Servicio no disponible.', code: 503);
      default:
        return ServerFailure('Error del servidor: $message', code: statusCode);
    }
  }
}

/// Fallo de conexión - Sin internet o problemas de red
class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'Error de conexión']);

  static const noInternet = ConnectionFailure('Sin conexión a internet');
  static const timeout = ConnectionFailure('Tiempo de conexión agotado');
  static const socketException = ConnectionFailure('Error de red');
}

/// Fallo de red - Alias para ConnectionFailure para compatibilidad
class NetworkFailure extends ConnectionFailure {
  const NetworkFailure([super.message = 'Error de red']);
}

/// Fallo de cache/almacenamiento local
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de cache']);

  static const notFound = CacheFailure('Datos no encontrados en cache');
  static const writeError = CacheFailure('Error al escribir en cache');
  static const readError = CacheFailure('Error al leer del cache');
}

/// Fallo de validación - Datos inválidos
class ValidationFailure extends Failure {
  final List<String> errors;

  const ValidationFailure(this.errors) : super('Errores de validación');

  @override
  List<Object?> get props => [errors];

  /// Obtener el primer error
  String get firstError => errors.isNotEmpty ? errors.first : message;

  /// Obtener todos los errores como un string
  String get allErrors => errors.join('\n');

  @override
  String toString() => allErrors;
}

/// Fallo de autenticación
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación']);

  static const invalidCredentials = AuthFailure('Credenciales inválidas');
  static const tokenExpired = AuthFailure('Sesión expirada');
  static const userNotFound = AuthFailure('Usuario no encontrado');
  static const emailAlreadyExists = AuthFailure('El email ya está registrado');
  static const weakPassword = AuthFailure('La contraseña es muy débil');
  static const noToken = AuthFailure('No hay token de acceso');
}

/// Fallo de permisos
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Sin permisos']);

  static const accessDenied = PermissionFailure('Acceso denegado');
  static const insufficientPermissions = PermissionFailure(
    'Permisos insuficientes',
  );
}

/// Fallo de formato/parseo
class FormatFailure extends Failure {
  const FormatFailure([super.message = 'Error de formato']);

  static const jsonParse = FormatFailure('Error al parsear JSON');
  static const invalidData = FormatFailure('Datos inválidos');
}

/// Fallo genérico para casos no cubiertos
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error desconocido']);
}
