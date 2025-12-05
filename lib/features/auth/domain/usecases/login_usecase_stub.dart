// lib/features/auth/domain/usecases/login_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_usecase.dart' show LoginParams;

/// Implementación que usa el API real del backend
///
/// Realiza login real contra el backend y obtiene tokens válidos
class LoginUseCaseStub implements UseCase<AuthResult, LoginParams> {
  final AuthRepository authRepository;

  const LoginUseCaseStub({required this.authRepository});

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) async {
    try {
      // Validaciones básicas
      if (params.email.isEmpty || params.password.isEmpty) {
        return Left(ValidationFailure(['Email y contraseña son requeridos']));
      }

      if (!params.email.contains('@')) {
        return Left(ValidationFailure(['Email inválido']));
      }

      if (params.password.length < 3) {
        return Left(ValidationFailure(['Contraseña muy corta']));
      }

      print(
        '🔐 LoginUseCaseStub: Iniciando login real contra backend API para ${params.email}',
      );

      // Usar el repositorio real que llama al backend API
      final result = await authRepository.login(
        email: params.email,
        password: params.password,
      );

      return result.fold(
        (failure) {
          print('❌ LoginUseCaseStub: Error de login - ${failure.message}');
          return Left(failure);
        },
        (authResult) {
          print(
            '✅ LoginUseCaseStub: Login exitoso contra backend API para ${params.email}',
          );
          print(
            '🔑 Token real recibido: ${authResult.token.substring(0, 20)}...',
          );
          print(
            '🏢 Organización: ${authResult.user.organizationName} (${authResult.user.organizationSlug})',
          );
          return Right(authResult);
        },
      );
    } catch (e) {
      print('❌ LoginUseCaseStub: Error inesperado - $e');
      return Left(ServerFailure('Error de conexión: $e'));
    }
  }

  /// Extraer nombre del email para personalización
  String _getFirstNameFromEmail(String email) {
    final username = email.split('@').first;
    final capitalized = username
        .split('.')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');

    return capitalized.isEmpty ? 'Usuario' : capitalized;
  }
}
