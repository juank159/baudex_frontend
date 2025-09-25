// lib/features/auth/domain/usecases/register_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/user.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para registrar un nuevo usuario
class RegisterUseCase implements UseCase<AuthResult, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(RegisterParams params) async {
    // Validaciones de entrada
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Ejecutar registro
    return await repository.register(
      firstName: params.firstName.trim(),
      lastName: params.lastName.trim(),
      email: params.email.trim().toLowerCase(),
      password: params.password,
      role: params.role,
      organizationName: params.organizationName,
    );
  }

  /// Validar parámetros de entrada
  ValidationFailure? _validateParams(RegisterParams params) {
    final errors = <String>[];

    // Validar nombre
    if (params.firstName.isEmpty) {
      errors.add('El nombre es requerido');
    } else if (params.firstName.trim().length < 2) {
      errors.add('El nombre debe tener al menos 2 caracteres');
    } else if (params.firstName.trim().length > 100) {
      errors.add('El nombre no puede exceder 100 caracteres');
    }

    // Validar apellido
    if (params.lastName.isEmpty) {
      errors.add('El apellido es requerido');
    } else if (params.lastName.trim().length < 2) {
      errors.add('El apellido debe tener al menos 2 caracteres');
    } else if (params.lastName.trim().length > 100) {
      errors.add('El apellido no puede exceder 100 caracteres');
    }

    // Validar email
    if (params.email.isEmpty) {
      errors.add('El email es requerido');
    } else if (!_isValidEmail(params.email)) {
      errors.add('El email no tiene un formato válido');
    }

    // Validar contraseña
    if (params.password.isEmpty) {
      errors.add('La contraseña es requerida');
    } else {
      final passwordErrors = _validatePassword(params.password);
      errors.addAll(passwordErrors);
    }

    // Validar confirmación de contraseña
    if (params.confirmPassword.isEmpty) {
      errors.add('La confirmación de contraseña es requerida');
    } else if (params.password != params.confirmPassword) {
      errors.add('Las contraseñas no coinciden');
    }

    return errors.isNotEmpty ? ValidationFailure(errors) : null;
  }

  /// Validar formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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

    // Verificar que contenga al menos una minúscula
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos una letra minúscula');
    }

    // Verificar que contenga al menos una mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos una letra mayúscula');
    }

    // Verificar que contenga al menos un número
    if (!RegExp(r'\d').hasMatch(password)) {
      errors.add('La contraseña debe contener al menos un número');
    }

    return errors;
  }
}

/// Parámetros para el caso de uso de registro
class RegisterParams extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final UserRole? role;
  final String? organizationName;

  const RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.role,
    this.organizationName,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    password,
    confirmPassword,
    role,
    organizationName,
  ];

  @override
  String toString() =>
      'RegisterParams(firstName: $firstName, lastName: $lastName, email: $email, organizationName: $organizationName)';
}
