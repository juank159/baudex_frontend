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
  final String? errorCode;

  const AuthFailure({
    String message = 'Error de autenticación',
    this.errorCode,
  }) : super(message);

  @override
  List<Object?> get props => [message, errorCode];

  static const invalidCredentials = AuthFailure(message: 'Credenciales inválidas', errorCode: 'INVALID_CREDENTIALS');
  static const tokenExpired = AuthFailure(message: 'Sesión expirada', errorCode: 'TOKEN_EXPIRED');
  static const userNotFound = AuthFailure(message: 'Usuario no encontrado', errorCode: 'USER_NOT_FOUND');
  static const emailAlreadyExists = AuthFailure(message: 'El email ya está registrado', errorCode: 'EMAIL_EXISTS');
  static const weakPassword = AuthFailure(message: 'La contraseña es muy débil', errorCode: 'WEAK_PASSWORD');
  static const noToken = AuthFailure(message: 'No hay token de acceso', errorCode: 'NO_TOKEN');
  static const noOfflineCredentials = AuthFailure(
    message: 'No hay sesión previa guardada. Necesitas conexión a internet para el primer login.',
    errorCode: 'NO_OFFLINE_CREDENTIALS',
  );
  static const sessionExpired = AuthFailure(
    message: 'Sesión expirada. Necesitas conexión a internet para renovar tu sesión.',
    errorCode: 'SESSION_EXPIRED',
  );
}

/// Fallo de permisos
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Sin permisos']);

  static const accessDenied = PermissionFailure('Acceso denegado');
  static const insufficientPermissions = PermissionFailure(
    'Permisos insuficientes',
  );
}

/// Fallo de suscripción - Suscripción expirada o inválida
class SubscriptionFailure extends Failure {
  const SubscriptionFailure([super.message = 'Suscripción expirada']);

  @override
  int? get code => 403; // Código para que el handler lo detecte

  static const expired = SubscriptionFailure(
    'Tu suscripción ha expirado. Renueva para continuar usando todas las funcionalidades.',
  );
  static const trialExpired = SubscriptionFailure(
    'Tu período de prueba ha expirado. Activa una suscripción para continuar.',
  );
  static const inactive = SubscriptionFailure(
    'Tu suscripción está inactiva. Contacta a soporte para más información.',
  );
  static const cancelled = SubscriptionFailure(
    'Tu suscripción ha sido cancelada. Reactívala para continuar.',
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
