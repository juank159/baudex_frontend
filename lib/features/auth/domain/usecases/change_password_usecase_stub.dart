// lib/features/auth/domain/usecases/change_password_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import 'change_password_usecase.dart' show ChangePasswordParams;

/// Implementación stub de ChangePasswordUseCase
class ChangePasswordUseCaseStub implements UseCase<Unit, ChangePasswordParams> {
  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) async {
    try {
      // Validaciones básicas
      if (params.currentPassword.isEmpty ||
          params.newPassword.isEmpty ||
          params.confirmPassword.isEmpty) {
        return Left(ValidationFailure(['Todos los campos son requeridos']));
      }

      if (params.newPassword.length < 6) {
        return Left(ValidationFailure(['Nueva contraseña debe tener al menos 6 caracteres']));
      }

      if (params.newPassword != params.confirmPassword) {
        return Left(ValidationFailure(['Las contraseñas no coinciden']));
      }

      if (params.currentPassword == params.newPassword) {
        return Left(ValidationFailure(['La nueva contraseña debe ser diferente a la actual']));
      }

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      print('✅ ChangePasswordUseCaseStub: Contraseña cambiada exitosamente');
      return const Right(unit);

    } catch (e) {
      print('❌ ChangePasswordUseCaseStub: Error inesperado - $e');
      return Left(ServerFailure('Error de conexión: $e'));
    }
  }
}