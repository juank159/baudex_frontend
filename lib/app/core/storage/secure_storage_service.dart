// lib/app/core/storage/secure_storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../config/constants/api_constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
    mOptions: MacOsOptions(
      groupId: 'com.example.baudex_desktop',
      accountName: 'baudex_desktop',
      synchronizable: false,
    ),
  );

  // Fallback para macOS cuando hay problemas con Keychain
  static bool _useSharedPreferences = false;

  /// Método para detectar si debemos usar SharedPreferences como fallback
  static Future<bool> _shouldUseSharedPreferences() async {
    if (_useSharedPreferences) return true;
    
    // Solo en macOS, hacer una prueba rápida
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        await _storage.write(key: 'test_key', value: 'test_value');
        await _storage.delete(key: 'test_key');
        return false; // Keychain funciona
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Keychain no disponible en macOS, usando SharedPreferences como fallback');
        }
        _useSharedPreferences = true;
        return true;
      }
    }
    return false;
  }

  /// Wrapper para escribir datos con fallback
  static Future<void> _writeSecure(String key, String value) async {
    if (await _shouldUseSharedPreferences()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_$key', value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  /// Wrapper para leer datos con fallback
  static Future<String?> _readSecure(String key) async {
    if (await _shouldUseSharedPreferences()) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure_$key');
    } else {
      return await _storage.read(key: key);
    }
  }

  /// Wrapper para eliminar datos con fallback
  static Future<void> _deleteSecure(String key) async {
    if (await _shouldUseSharedPreferences()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
    } else {
      await _storage.delete(key: key);
    }
  }

  // ===================== TOKEN MANAGEMENT =====================

  /// Guardar token de acceso
  Future<void> saveToken(String token) async {
    try {
      await _writeSecure(ApiConstants.tokenKey, token);
    } catch (e) {
      throw Exception('Error al guardar token: $e');
    }
  }

  /// Obtener token de acceso
  Future<String?> getToken() async {
    try {
      return await _readSecure(ApiConstants.tokenKey);
    } catch (e) {
      throw Exception('Error al obtener token: $e');
    }
  }

  /// Eliminar token de acceso
  Future<void> deleteToken() async {
    try {
      await _deleteSecure(ApiConstants.tokenKey);
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
      await _writeSecure(ApiConstants.refreshTokenKey, refreshToken);
    } catch (e) {
      throw Exception('Error al guardar refresh token: $e');
    }
  }

  /// Obtener refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _readSecure(ApiConstants.refreshTokenKey);
    } catch (e) {
      throw Exception('Error al obtener refresh token: $e');
    }
  }

  /// Eliminar refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _deleteSecure(ApiConstants.refreshTokenKey);
    } catch (e) {
      throw Exception('Error al eliminar refresh token: $e');
    }
  }

  // ===================== USER DATA MANAGEMENT =====================

  /// Guardar datos del usuario
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userJson = jsonEncode(userData);
      await _writeSecure(ApiConstants.userKey, userJson);
    } catch (e) {
      throw Exception('Error al guardar datos del usuario: $e');
    }
  }

  /// Obtener datos del usuario
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _readSecure(ApiConstants.userKey);
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
      await _deleteSecure(ApiConstants.userKey);
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
