// lib/features/auth/domain/usecases/login_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión
class LoginUseCase implements UseCase<AuthResult, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar login
    return await repository.login(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(LoginParams params) {
    final errors = <String>[];

    // Validar email
    if (params.email.isEmpty) {
      errors.add('El email es requerido');
    } else if (!_isValidEmail(params.email)) {
      errors.add('El email no tiene un formato válido');
    }

    // Validar contraseña
    if (params.password.isEmpty) {
      errors.add('La contraseña es requerida');
    } else if (params.password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    }

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parámetros para el caso de uso de login
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];

  @override
  String toString() => 'LoginParams(email: $email)';
}
