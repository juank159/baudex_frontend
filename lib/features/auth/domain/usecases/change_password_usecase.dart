import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cambiar contraseña
class ChangePasswordUseCase implements UseCase<Unit, ChangePasswordParams> {
  final AuthRepository repository;

  const ChangePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar cambio de contraseña
    return await repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(ChangePasswordParams params) {
    final errors = <String>[];

    // Validar contraseña actual
    if (params.currentPassword.isEmpty) {
      errors.add('La contraseña actual es requerida');
    }

    // Validar nueva contraseña
    if (params.newPassword.isEmpty) {
      errors.add('La nueva contraseña es requerida');
    } else {
      final passwordErrors = _validatePassword(params.newPassword);
      errors.addAll(passwordErrors);
    }

    // Validar confirmación
    if (params.confirmPassword.isEmpty) {
      errors.add('La confirmación de contraseña es requerida');
    } else if (params.newPassword != params.confirmPassword) {
      errors.add('Las contraseñas nuevas no coinciden');
    }

    // Validar que sea diferente a la actual
    if (params.currentPassword == params.newPassword) {
      errors.add('La nueva contraseña debe ser diferente a la actual');
    }

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar contraseña según reglas de negocio
  List<String> _validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    }

    if (password.length > 50) {
      errors.add('La contraseña no puede exceder 50 caracteres');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos una letra minúscula');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos una letra mayúscula');
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos un número');
    }

    return errors;
  }
}

/// Parámetros para cambiar contraseña
class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword, confirmPassword];
}
