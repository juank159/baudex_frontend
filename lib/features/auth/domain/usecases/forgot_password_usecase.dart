// lib/features/auth/domain/usecases/forgot_password_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para solicitar código de recuperación de contraseña
class ForgotPasswordUseCase implements UseCase<bool, ForgotPasswordParams> {
  final AuthRepository repository;

  const ForgotPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ForgotPasswordParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar solicitud de recuperación
    return await repository.forgotPassword(
      email: params.email.trim().toLowerCase(),
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(ForgotPasswordParams params) {
    final errors = <String>[];

    // Validar email
    if (params.email.isEmpty) {
      errors.add('El email es requerido');
    } else if (!_isValidEmail(params.email)) {
      errors.add('El email no tiene un formato válido');
    }

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parámetros para el caso de uso de recuperación de contraseña
class ForgotPasswordParams extends Equatable {
  final String email;

  const ForgotPasswordParams({required this.email});

  @override
  List<Object> get props => [email];

  @override
  String toString() => 'ForgotPasswordParams(email: $email)';
}
