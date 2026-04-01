// lib/features/auth/domain/usecases/resend_verification_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para reenviar código de verificación
class ResendVerificationUseCase implements UseCase<bool, ResendVerificationParams> {
  final AuthRepository repository;

  const ResendVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ResendVerificationParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar reenvío de código
    return await repository.resendVerificationCode(
      email: params.email.trim().toLowerCase(),
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(ResendVerificationParams params) {
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

/// Parámetros para el caso de uso de reenvío de código
class ResendVerificationParams extends Equatable {
  final String email;

  const ResendVerificationParams({required this.email});

  @override
  List<Object> get props => [email];

  @override
  String toString() => 'ResendVerificationParams(email: $email)';
}
