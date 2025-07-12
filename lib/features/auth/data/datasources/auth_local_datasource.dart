// lib/features/auth/data/datasources/auth_local_datasource.dart
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';

/// Contrato para el datasource local de autenticación
abstract class AuthLocalDataSource {
  Future<void> saveAuthData(AuthResponseModel authResponse);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getUser();
  Future<bool> isAuthenticated();
  Future<void> clearAuthData();
  Future<void> saveToken(String token);
  Future<void> saveUser(UserModel user);
}

/// Implementación del datasource local usando SecureStorage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService storageService;

  const AuthLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> saveAuthData(AuthResponseModel authResponse) async {
    try {
      await storageService.saveAuthData(
        token: authResponse.token,
        refreshToken: authResponse.refreshToken,
        userData: authResponse.user.toJson(),
      );
    } catch (e) {
      throw CacheException('Error al guardar datos de autenticación: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await storageService.getToken();
    } catch (e) {
      throw CacheException('Error al obtener token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await storageService.getRefreshToken();
    } catch (e) {
      throw CacheException('Error al obtener refresh token: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw CacheException('Error al obtener datos del usuario: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await storageService.isAuthenticated();
    } catch (e) {
      // En caso de error, asumir que no está autenticado
      return false;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await storageService.clearAuthData();
    } catch (e) {
      throw CacheException('Error al limpiar datos de autenticación: $e');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await storageService.saveToken(token);
    } catch (e) {
      throw CacheException('Error al guardar token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await storageService.saveUserData(user.toJson());
    } catch (e) {
      throw CacheException('Error al guardar datos del usuario: $e');
    }
  }

  /// Verificar si existe token válido
  Future<bool> hasValidToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si existen datos del usuario
  Future<bool> hasUserData() async {
    try {
      final user = await getUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener datos completos de autenticación
  Future<AuthLocalData?> getAuthData() async {
    try {
      final token = await getToken();
      final refreshToken = await getRefreshToken();
      final user = await getUser();

      if (token != null && user != null) {
        return AuthLocalData(
          token: token,
          refreshToken: refreshToken,
          user: user,
        );
      }
      return null;
    } catch (e) {
      throw CacheException('Error al obtener datos de autenticación: $e');
    }
  }

  /// Actualizar solo el token (útil para refresh)
  Future<void> updateToken(String newToken) async {
    try {
      await storageService.saveToken(newToken);
    } catch (e) {
      throw CacheException('Error al actualizar token: $e');
    }
  }

  /// Actualizar solo los datos del usuario
  Future<void> updateUser(UserModel user) async {
    try {
      await storageService.saveUserData(user.toJson());
    } catch (e) {
      throw CacheException('Error al actualizar datos del usuario: $e');
    }
  }
}

/// Clase para encapsular datos de autenticación local
class AuthLocalData {
  final String token;
  final String? refreshToken;
  final UserModel user;

  const AuthLocalData({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  /// Convertir a AuthResponseModel
  AuthResponseModel toAuthResponse() {
    return AuthResponseModel(
      token: token,
      user: user,
      refreshToken: refreshToken,
    );
  }

  @override
  String toString() =>
      'AuthLocalData(token: ${token.substring(0, 10)}..., user: ${user.email})';
}
