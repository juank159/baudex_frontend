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
      groupId: 'com.example.baudexDesktop',
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
      await _writeSecure(key, value);
    } catch (e) {
      throw Exception('Error al escribir $key: $e');
    }
  }

  /// Leer valor genérico
  Future<String?> read(String key) async {
    try {
      return await _readSecure(key);
    } catch (e) {
      throw Exception('Error al leer $key: $e');
    }
  }

  /// Eliminar valor genérico
  Future<void> delete(String key) async {
    try {
      await _deleteSecure(key);
    } catch (e) {
      throw Exception('Error al eliminar $key: $e');
    }
  }

  /// Limpiar todo el almacenamiento
  Future<void> clearAll() async {
    try {
      if (await _shouldUseSharedPreferences()) {
        final prefs = await SharedPreferences.getInstance();
        // Obtener todas las claves que empiecen con 'secure_'
        final keys = prefs.getKeys().where((key) => key.startsWith('secure_')).toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      } else {
        await _storage.deleteAll();
      }
    } catch (e) {
      throw Exception('Error al limpiar almacenamiento: $e');
    }
  }

  /// Obtener todas las claves
  Future<Map<String, String>> readAll() async {
    try {
      if (await _shouldUseSharedPreferences()) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, String> result = {};
        final keys = prefs.getKeys().where((key) => key.startsWith('secure_')).toList();
        for (final key in keys) {
          final value = prefs.getString(key);
          if (value != null) {
            // Remover el prefijo 'secure_' para devolver la clave original
            final originalKey = key.replaceFirst('secure_', '');
            result[originalKey] = value;
          }
        }
        return result;
      } else {
        return await _storage.readAll();
      }
    } catch (e) {
      throw Exception('Error al leer todo el almacenamiento: $e');
    }
  }

  /// Verificar si una clave existe
  Future<bool> containsKey(String key) async {
    try {
      final value = await _readSecure(key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  // ===================== TENANT MANAGEMENT =====================

  /// Guardar slug del tenant actual
  Future<void> saveTenantSlug(String tenantSlug) async {
    try {
      await _writeSecure('tenant_slug', tenantSlug);
    } catch (e) {
      throw Exception('Error al guardar tenant slug: $e');
    }
  }

  /// Obtener slug del tenant actual
  Future<String?> getTenantSlug() async {
    try {
      return await _readSecure('tenant_slug');
    } catch (e) {
      throw Exception('Error al obtener tenant slug: $e');
    }
  }

  /// Eliminar slug del tenant
  Future<void> deleteTenantSlug() async {
    try {
      await _deleteSecure('tenant_slug');
    } catch (e) {
      throw Exception('Error al eliminar tenant slug: $e');
    }
  }

  /// Guardar datos de la organización actual
  Future<void> saveCurrentOrganization(Map<String, dynamic> organization) async {
    try {
      final orgJson = jsonEncode(organization);
      await _writeSecure('current_organization', orgJson);
    } catch (e) {
      throw Exception('Error al guardar organización actual: $e');
    }
  }

  /// Obtener datos de la organización actual
  Future<Map<String, dynamic>?> getCurrentOrganization() async {
    try {
      final orgJson = await _readSecure('current_organization');
      if (orgJson != null) {
        return jsonDecode(orgJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener organización actual: $e');
    }
  }

  /// Eliminar datos de la organización actual
  Future<void> deleteCurrentOrganization() async {
    try {
      await _deleteSecure('current_organization');
    } catch (e) {
      throw Exception('Error al eliminar organización actual: $e');
    }
  }

  /// Limpiar todos los datos de tenant
  Future<void> clearTenantData() async {
    try {
      await Future.wait([
        deleteTenantSlug(),
        deleteCurrentOrganization(),
      ]);
    } catch (e) {
      throw Exception('Error al limpiar datos de tenant: $e');
    }
  }

  // ===================== AUTH HELPER METHODS =====================

  /// Guardar datos completos de autenticación
  Future<void> saveAuthData({
    required String token,
    String? refreshToken,
    required Map<String, dynamic> userData,
    String? tenantSlug,
    Map<String, dynamic>? organization,
  }) async {
    try {
      await saveToken(token);
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      await saveUserData(userData);
      
      // Guardar datos de tenant si se proporcionan
      if (tenantSlug != null) {
        await saveTenantSlug(tenantSlug);
      }
      if (organization != null) {
        await saveCurrentOrganization(organization);
      }
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
        clearTenantData(), // También limpiar datos de tenant al cerrar sesión
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

  // ===================== EMAIL MANAGEMENT =====================

  /// Guardar lista de correos recordados
  Future<void> saveSavedEmails(List<String> emails) async {
    try {
      final emailsJson = jsonEncode(emails);
      await _writeSecure(ApiConstants.savedEmailsKey, emailsJson);
    } catch (e) {
      throw Exception('Error al guardar correos: $e');
    }
  }

  /// Obtener lista de correos recordados
  Future<List<String>> getSavedEmails() async {
    try {
      final emailsJson = await _readSecure(ApiConstants.savedEmailsKey);
      if (emailsJson != null) {
        final List<dynamic> emailsList = jsonDecode(emailsJson);
        return emailsList.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Añadir un correo a la lista de recordados
  Future<void> addSavedEmail(String email) async {
    try {
      final currentEmails = await getSavedEmails();
      
      // Remover el email si ya existe para evitar duplicados
      currentEmails.removeWhere((e) => e.toLowerCase() == email.toLowerCase());
      
      // Añadir al principio de la lista
      currentEmails.insert(0, email);
      
      // Mantener solo los últimos 5 correos
      if (currentEmails.length > 5) {
        currentEmails.removeRange(5, currentEmails.length);
      }
      
      await saveSavedEmails(currentEmails);
    } catch (e) {
      throw Exception('Error al añadir correo: $e');
    }
  }

  /// Eliminar un correo específico de la lista
  Future<void> removeSavedEmail(String email) async {
    try {
      final currentEmails = await getSavedEmails();
      currentEmails.removeWhere((e) => e.toLowerCase() == email.toLowerCase());
      await saveSavedEmails(currentEmails);
    } catch (e) {
      throw Exception('Error al eliminar correo: $e');
    }
  }

  /// Guardar el último email usado para login
  Future<void> saveLastEmail(String email) async {
    try {
      await _writeSecure(ApiConstants.lastEmailKey, email);
    } catch (e) {
      throw Exception('Error al guardar último email: $e');
    }
  }

  /// Obtener el último email usado para login
  Future<String?> getLastEmail() async {
    try {
      return await _readSecure(ApiConstants.lastEmailKey);
    } catch (e) {
      return null;
    }
  }

  /// Limpiar todos los correos guardados
  Future<void> clearSavedEmails() async {
    try {
      await Future.wait([
        _deleteSecure(ApiConstants.savedEmailsKey),
        _deleteSecure(ApiConstants.lastEmailKey),
      ]);
    } catch (e) {
      throw Exception('Error al limpiar correos guardados: $e');
    }
  }
}
