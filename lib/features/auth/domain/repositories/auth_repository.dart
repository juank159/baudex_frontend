// // lib/features/auth/domain/repositories/auth_repository.dart
// import 'package:dartz/dartz.dart';
// import '../../../../app/core/errors/failures.dart';
// import '../entities/user.dart';

// /// Contrato abstracto para operaciones de autenticación
// abstract class AuthRepository {
//   /// Iniciar sesión con email y contraseña
//   ///
//   /// Retorna [Right] con [AuthResult] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, AuthResult>> login({
//     required String email,
//     required String password,
//   });

//   /// Registrar nuevo usuario
//   ///
//   /// Retorna [Right] con [AuthResult] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, AuthResult>> register({
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String password,
//     UserRole? role,
//   });

//   /// Obtener perfil del usuario actual
//   ///
//   /// Retorna [Right] con [User] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, User>> getProfile();

//   /// Refrescar token de acceso
//   ///
//   /// Retorna [Right] con nuevo token si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, String>> refreshToken();

//   /// Cerrar sesión
//   ///
//   /// Retorna [Right] con [Unit] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, Unit>> logout();

//   /// Actualizar perfil del usuario
//   ///
//   /// Retorna [Right] con [User] actualizado si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, User>> updateProfile({
//     String? firstName,
//     String? lastName,
//     String? phone,
//     String? avatar,
//   });

//   /// Cambiar contraseña
//   ///
//   /// Retorna [Right] con [Unit] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, Unit>> changePassword({
//     required String currentPassword,
//     required String newPassword,
//     required String confirmPassword,
//   });

//   /// Verificar si el usuario está autenticado localmente
//   ///
//   /// Retorna [true] si tiene token válido almacenado
//   Future<bool> isAuthenticated();

//   /// Obtener usuario desde almacenamiento local
//   ///
//   /// Retorna [Right] con [User] si existe
//   /// Retorna [Left] con [Failure] si no existe o hay error
//   Future<Either<Failure, User>> getLocalUser();

//   /// Limpiar datos de autenticación local
//   ///
//   /// Retorna [Right] con [Unit] si es exitoso
//   /// Retorna [Left] con [Failure] si hay error
//   Future<Either<Failure, Unit>> clearLocalAuth();
// }

// /// Resultado de operaciones de autenticación exitosas
// class AuthResult {
//   final String token;
//   final User user;
//   final String? refreshToken;

//   const AuthResult({
//     required this.token,
//     required this.user,
//     this.refreshToken,
//   });

//   @override
//   String toString() {
//     return 'AuthResult(token: ${token.substring(0, 10)}..., user: ${user.email})';
//   }
// }

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/user.dart';

/// Contrato abstracto para operaciones de autenticación
abstract class AuthRepository {
  /// Iniciar sesión con email y contraseña
  ///
  /// Retorna [Right] con [AuthResult] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// Registrar nuevo usuario
  ///
  /// Retorna [Right] con [AuthResult] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, AuthResult>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    UserRole? role,
  });

  /// Obtener perfil del usuario actual
  ///
  /// Retorna [Right] con [User] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, User>> getProfile();

  /// Refrescar token de acceso
  ///
  /// Retorna [Right] con nuevo token si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, String>> refreshToken();

  /// Cerrar sesión
  ///
  /// Retorna [Right] con [Unit] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, Unit>> logout();

  // Actualizar perfil del usuario
  ///
  /// Retorna [Right] con [User] actualizado si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  });

  /// Cambiar contraseña
  ///
  /// Retorna [Right] con [Unit] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Verificar si el usuario está autenticado localmente
  ///
  /// Retorna [Right(true)] si tiene token válido, [Right(false)] si no,
  /// o [Left(Failure)] si hay un error en la verificación.
  // ✅ LÍNEA MODIFICADA: Ahora el tipo de retorno es Future<Either<Failure, bool>>
  Future<Either<Failure, bool>> isAuthenticated();

  /// Obtener usuario desde almacenamiento local
  ///
  /// Retorna [Right] con [User] si existe
  /// Retorna [Left] con [Failure] si no existe o hay error
  Future<Either<Failure, User>> getLocalUser();

  /// Limpiar datos de autenticación local
  ///
  /// Retorna [Right] con [Unit] si es exitoso
  /// Retorna [Left] con [Failure] si hay error
  Future<Either<Failure, Unit>> clearLocalAuth();
}

/// Resultado de operaciones de autenticación exitosas
class AuthResult {
  final String token;
  final User user;
  final String? refreshToken;

  const AuthResult({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  // Nota: Faltaba @override y la implementación de equatable si AuthResult extiende Equatable
  // O una implementación de hashCode y operator == si no extiende Equatable
  // Asumiendo que Equatable está siendo usado en tus entidades.
  // @override
  // List<Object?> get props => [token, user, refreshToken];
}
