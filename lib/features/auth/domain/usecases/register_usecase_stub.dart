// lib/features/auth/domain/usecases/register_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../entities/user.dart';
import '../../data/models/user_model.dart';
import 'register_usecase.dart' show RegisterParams;

/// Implementación stub de RegisterUseCase
class RegisterUseCaseStub implements UseCase<AuthResult, RegisterParams> {
  @override
  Future<Either<Failure, AuthResult>> call(RegisterParams params) async {
    try {
      // Validaciones básicas
      if (params.firstName.isEmpty ||
          params.lastName.isEmpty ||
          params.email.isEmpty ||
          params.password.isEmpty) {
        return Left(ValidationFailure(['Todos los campos son requeridos']));
      }

      if (!params.email.contains('@')) {
        return Left(ValidationFailure(['Email inválido']));
      }

      if (params.password.length < 6) {
        return Left(ValidationFailure(['Contraseña debe tener al menos 6 caracteres']));
      }

      if (params.password != params.confirmPassword) {
        return Left(ValidationFailure(['Las contraseñas no coinciden']));
      }

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 1200));

      // Crear usuario registrado
      final newUser = UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        firstName: params.firstName,
        lastName: params.lastName,
        email: params.email,
        role: UserRole.admin,
        status: UserStatus.active,
        organizationId: 'org-${DateTime.now().millisecondsSinceEpoch}',
        organizationSlug: _generateSlugFromName(params.organizationName ?? '${params.firstName} ${params.lastName}'),
        organizationName: params.organizationName ?? '${params.firstName} ${params.lastName} Org',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Crear resultado de auth
      final authResult = AuthResult(
        user: newUser.toEntity(),
        token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'demo-refresh-token',
      );

      print('✅ RegisterUseCaseStub: Registro exitoso para ${params.email}');
      return Right(authResult);

    } catch (e) {
      print('❌ RegisterUseCaseStub: Error inesperado - $e');
      return Left(ServerFailure('Error de conexión: $e'));
    }
  }

  /// Generar slug válido desde el nombre
  String _generateSlugFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .substring(0, name.length > 20 ? 20 : name.length);
  }
}