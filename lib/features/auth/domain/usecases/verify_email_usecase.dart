// lib/features/auth/domain/usecases/verify_email_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para verificar email con código de 6 dígitos
class VerifyEmailUseCase implements UseCase<bool, VerifyEmailParams> {
  final AuthRepository repository;

  const VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyEmailParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar verificación
    return await repository.verifyEmail(
      email: params.email.trim().toLowerCase(),
      code: params.code.trim(),
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(VerifyEmailParams params) {
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

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parámetros para el caso de uso de verificación de email
class VerifyEmailParams extends Equatable {
  final String email;
  final String code;

  const VerifyEmailParams({required this.email, required this.code});

  @override
  List<Object> get props => [email, code];

  @override
  String toString() => 'VerifyEmailParams(email: $email, code: ${code.substring(0, 2)}***)';
}
