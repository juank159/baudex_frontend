// lib/features/auth/domain/usecases/reset_password_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para restablecer contraseña con código
class ResetPasswordUseCase implements UseCase<bool, ResetPasswordParams> {
  final AuthRepository repository;

  const ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ResetPasswordParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar restablecimiento de contraseña
    return await repository.resetPassword(
      email: params.email.trim().toLowerCase(),
      code: params.code.trim(),
      newPassword: params.newPassword,
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(ResetPasswordParams params) {
    final errors = <String>[];

    // Validar email
    if (params.email.isEmpty) {
      errors.add('El email es requerido');
    } else if (!_isValidEmail(params.email)) {
      errors.add('El email no tiene un formato válido');
    }

    // Validar código
    if (params.code.isEmpty) {
      errors.add('El código es requerido');
    } else if (params.code.length != 6) {
      errors.add('El código debe tener 6 dígitos');
    } else if (!RegExp(r'^\d{6}$').hasMatch(params.code)) {
      errors.add('El código debe contener solo números');
    }

    // Validar nueva contraseña
    if (params.newPassword.isEmpty) {
      errors.add('La nueva contraseña es requerida');
    } else if (params.newPassword.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    }

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parámetros para el caso de uso de restablecimiento de contraseña
class ResetPasswordParams extends Equatable {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, code, newPassword];

  @override
  String toString() => 'ResetPasswordParams(email: $email, code: ${code.substring(0, 2)}***)';
}
