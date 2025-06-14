// lib/app/core/storage/secure_storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants/api_constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
    mOptions: MacOsOptions(),
  );

  // ===================== TOKEN MANAGEMENT =====================

  /// Guardar token de acceso
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: ApiConstants.tokenKey, value: token);
    } catch (e) {
      throw Exception('Error al guardar token: $e');
    }
  }

  /// Obtener token de acceso
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: ApiConstants.tokenKey);
    } catch (e) {
      throw Exception('Error al obtener token: $e');
    }
  }

  /// Eliminar token de acceso
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: ApiConstants.tokenKey);
    } catch (e) {
      throw Exception('Error al eliminar token: $e');
    }
  }

  /// Verificar si existe token
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ===================== REFRESH TOKEN MANAGEMENT =====================

  /// Guardar refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(
        key: ApiConstants.refreshTokenKey,
        value: refreshToken,
      );
    } catch (e) {
      throw Exception('Error al guardar refresh token: $e');
    }
  }

  /// Obtener refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: ApiConstants.refreshTokenKey);
    } catch (e) {
      throw Exception('Error al obtener refresh token: $e');
    }
  }

  /// Eliminar refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: ApiConstants.refreshTokenKey);
    } catch (e) {
      throw Exception('Error al eliminar refresh token: $e');
    }
  }

  // ===================== USER DATA MANAGEMENT =====================

  /// Guardar datos del usuario
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userJson = jsonEncode(userData);
      await _storage.write(key: ApiConstants.userKey, value: userJson);
    } catch (e) {
      throw Exception('Error al guardar datos del usuario: $e');
    }
  }

  /// Obtener datos del usuario
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _storage.read(key: ApiConstants.userKey);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  /// Eliminar datos del usuario
  Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: ApiConstants.userKey);
    } catch (e) {
      throw Exception('Error al eliminar datos del usuario: $e');
    }
  }

  /// Verificar si existen datos del usuario
  Future<bool> hasUserData() async {
    try {
      final userData = await getUserData();
      return userData != null;
    } catch (e) {
      return false;
    }
  }

  // ===================== GENERAL STORAGE METHODS =====================

  /// Guardar valor genérico
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Error al escribir $key: $e');
    }
  }

  /// Leer valor genérico
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw Exception('Error al leer $key: $e');
    }
  }

  /// Eliminar valor genérico
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw Exception('Error al eliminar $key: $e');
    }
  }

  /// Limpiar todo el almacenamiento
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Error al limpiar almacenamiento: $e');
    }
  }

  /// Obtener todas las claves
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw Exception('Error al leer todo el almacenamiento: $e');
    }
  }

  /// Verificar si una clave existe
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  // ===================== AUTH HELPER METHODS =====================

  /// Guardar datos completos de autenticación
  Future<void> saveAuthData({
    required String token,
    String? refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await saveToken(token);
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      await saveUserData(userData);
    } catch (e) {
      throw Exception('Error al guardar datos de autenticación: $e');
    }
  }

  /// Limpiar todos los datos de autenticación
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        deleteToken(),
        deleteRefreshToken(),
        deleteUserData(),
      ]);
    } catch (e) {
      throw Exception('Error al limpiar datos de autenticación: $e');
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    try {
      final hasTokenResult = await hasToken();
      final hasUserResult = await hasUserData();
      return hasTokenResult && hasUserResult;
    } catch (e) {
      return false;
    }
  }
}
