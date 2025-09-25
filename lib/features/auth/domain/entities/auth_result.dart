// lib/features/auth/domain/entities/auth_result.dart
import 'package:equatable/equatable.dart';
import 'user.dart';

/// Resultado de operaciones de autenticación (login/register)
class AuthResult extends Equatable {
  final User user;
  final String token;
  final String? refreshToken;

  const AuthResult({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  @override
  List<Object?> get props => [user, token, refreshToken];

  @override
  String toString() {
    return 'AuthResult(user: ${user.email}, token: ${token.substring(0, 10)}...)';
  }
}