import '../../domain/entities/auth_result.dart';
import 'user_model.dart';

class AuthResponseModel {
  final String token;
  final UserModel user;
  final String? refreshToken;

  const AuthResponseModel({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'refreshToken': refreshToken,
    };
  }

  /// Convertir a AuthResult del domain
  AuthResult toAuthResult() {
    return AuthResult(
      token: token,
      user: user.toEntity(),
      refreshToken: refreshToken,
    );
  }

  /// Factory constructor desde AuthResult
  factory AuthResponseModel.fromAuthResult(AuthResult authResult) {
    return AuthResponseModel(
      token: authResult.token,
      user: UserModel.fromEntity(authResult.user),
      refreshToken: authResult.refreshToken,
    );
  }

  @override
  String toString() =>
      'AuthResponseModel(token: ${token.substring(0, 10)}..., user: ${user.email})';
}
