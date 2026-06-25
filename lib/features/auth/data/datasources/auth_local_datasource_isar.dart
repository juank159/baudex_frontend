// lib/features/auth/data/datasources/auth_local_datasource_isar.dart
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import 'auth_local_datasource.dart';

/// Implementación híbrida del datasource local de autenticación
///
/// Usa SecureStorage para datos sensibles persistentes (tokens)
/// y permite extensión futura a ISAR para datos complejos
class AuthLocalDataSourceIsar implements AuthLocalDataSource {
  final SecureStorageService _secureStorage;

  AuthLocalDataSourceIsar(this._secureStorage);

  // Keys for storage
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _isAuthenticatedKey = 'is_authenticated';

  @override
  Future<void> saveAuthData(AuthResponseModel authResponse) async {
    await _doSaveAuthData(authResponse, isRetry: false);
  }

  Future<void> _doSaveAuthData(AuthResponseModel authResponse, {required bool isRetry}) async {
    try {
      await _secureStorage.saveToken(authResponse.token);

      if (authResponse.refreshToken != null) {
        await _secureStorage.saveRefreshToken(authResponse.refreshToken!);
      }

      final userJson = authResponse.user.toJson();
      await _secureStorage.saveUserData(userJson);

    } catch (e) {
      if (!isRetry) {
        // Primera falla: intentar recuperar el storage corrupto y reintentar
        try {
          await _secureStorage.clearAll();
        } catch (_) {}
        await _doSaveAuthData(authResponse, isRetry: true);
      } else {
        throw CacheException('Error al guardar datos de autenticación: $e');
      }
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _secureStorage.getToken();
    } catch (e) {
      throw CacheException('Error al obtener token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.getRefreshToken();
    } catch (e) {
      throw CacheException('Error al obtener refresh token: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userData = await _secureStorage.getUserData();
      if (userData == null) {
        return null;
      }

      // Convert Map to UserModel
      return UserModel.fromJson(userData);
    } catch (e) {
      // If parsing fails, return null instead of throwing
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _secureStorage.isAuthenticated();
    } catch (e) {
      // En caso de error, asumir que no está autenticado
      return false;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await _secureStorage.clearAuthData();

    } catch (e) {
      throw CacheException('Error al limpiar datos de autenticación: $e');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.saveToken(token);
    } catch (e) {
      throw CacheException('Error al guardar token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      // Save user data using the secure method with fallback
      final userJson = user.toJson();
      await _secureStorage.saveUserData(userJson);
    } catch (e) {
      throw CacheException('Error al guardar datos del usuario: $e');
    }
  }

  /// Métodos adicionales útiles

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
      throw CacheException(
        'Error al obtener datos de autenticación desde ISAR: $e',
      );
    }
  }

  /// Actualizar solo el token (útil para refresh)
  Future<void> updateToken(String newToken) async {
    try {
      await saveToken(newToken);
    } catch (e) {
      throw CacheException('Error al actualizar token: $e');
    }
  }

  /// Actualizar solo los datos del usuario
  Future<void> updateUser(UserModel user) async {
    try {
      await saveUser(user);
    } catch (e) {
      throw CacheException('Error al actualizar datos del usuario: $e');
    }
  }

  // ==================== OFFLINE CREDENTIALS ====================

  @override
  Future<void> saveOfflineCredentials(String email, String passwordHash) async {
    try {
      await _secureStorage.saveOfflineCredentials(
        email: email,
        passwordHash: passwordHash,
      );
    } catch (e) {
      throw CacheException('Error al guardar credenciales offline: $e');
    }
  }

  @override
  Future<bool> verifyOfflineCredentials(String email, String passwordHash) async {
    try {
      return await _secureStorage.verifyOfflineCredentials(
        email: email,
        passwordHash: passwordHash,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasOfflineCredentials() async {
    try {
      return await _secureStorage.hasOfflineCredentials();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearOfflineCredentials() async {
    try {
      await _secureStorage.deleteOfflineCredentials();
    } catch (e) {
      throw CacheException('Error al limpiar credenciales offline: $e');
    }
  }
}

/// Clase auxiliar para datos de autenticación locales
class AuthLocalData {
  final String token;
  final String? refreshToken;
  final UserModel user;

  AuthLocalData({required this.token, this.refreshToken, required this.user});
}
