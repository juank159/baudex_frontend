// lib/app/core/storage/secure_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
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

    // Windows desktop: forzar SharedPreferences porque FlutterSecureStorage
    // no garantiza persistencia cross-session en Windows desktop
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _useSharedPreferences = true;
      return true;
    }

    // En macOS, hacer una prueba rápida del secure storage
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        await _storage.write(key: 'test_key', value: 'test_value');
        final testVal = await _storage.read(key: 'test_key');
        await _storage.delete(key: 'test_key');
        if (testVal != 'test_value') {
          throw Exception('Secure storage read/write mismatch');
        }
        return false; // Secure storage funciona
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Secure storage no disponible en macOS, usando SharedPreferences como fallback: $e');
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

  /// Limpiar todo el almacenamiento excepto device ID y lastUserId.
  /// `lastUserId` se preserva para detectar cambio de tenant en el próximo
  /// login y poder hacer "logout perezoso": NO borrar la BD ISAR si el
  /// próximo login es del mismo usuario (mantener cache offline-first).
  /// Usa borrado selectivo para evitar race conditions.
  Future<void> clearAll() async {
    try {
      if (await _shouldUseSharedPreferences()) {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys()
            .where((key) =>
                key.startsWith('secure_') &&
                key != 'secure_$_deviceIdKey' &&
                key != 'secure_$_lastUserIdKey')
            .toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      } else {
        // Leer todas las keys y borrar solo las que NO son deviceId/lastUserId
        final allData = await _storage.readAll();
        for (final key in allData.keys) {
          if (key != _deviceIdKey && key != _lastUserIdKey) {
            await _storage.delete(key: key);
          }
        }
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
      await deleteTenantSlug();
      await deleteCurrentOrganization();
    } catch (e) {
      throw Exception('Error al limpiar datos de tenant: $e');
    }
  }

  // ===================== DEVICE ID MANAGEMENT =====================

  static const String _deviceIdKey = 'device_unique_id';

  /// Cache en memoria para evitar lecturas repetidas al storage
  static String? _cachedDeviceId;

  /// Obtener o generar un ID único para este dispositivo.
  /// Usa un fingerprint basado en hostname + plataforma + UUID persistido,
  /// hasheado con HMAC-SHA256 para no exponer datos del hardware.
  Future<String> getOrCreateDeviceId() async {
    // 1. Retornar cache en memoria si existe
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      // 2. Intentar leer del storage persistente
      final existing = await _readSecure(_deviceIdKey);
      if (existing != null && existing.isNotEmpty) {
        _cachedDeviceId = existing;
        return existing;
      }

      // 3. Generar nuevo device ID basado en fingerprint del hardware
      final fingerprint = _generateDeviceFingerprint();
      await _writeSecure(_deviceIdKey, fingerprint);
      _cachedDeviceId = fingerprint;

      if (kDebugMode) {
        print('🆔 Device ID generado y persistido (${fingerprint.substring(0, 12)}...)');
      }
      return fingerprint;
    } catch (e) {
      // 4. Si falla el storage, usar cache o generar temporal determinístico
      if (_cachedDeviceId != null) return _cachedDeviceId!;

      // Generar un fingerprint determinístico (mismo hardware = mismo ID)
      final fallback = _generateDeviceFingerprint();
      _cachedDeviceId = fallback;
      if (kDebugMode) {
        print('⚠️ Storage falló, usando fingerprint en memoria: $e');
      }
      return fallback;
    }
  }

  /// Genera un fingerprint determinístico basado en atributos del hardware.
  /// Mismo equipo físico = mismo fingerprint, incluso sin storage.
  static String _generateDeviceFingerprint() {
    try {
      final hostname = Platform.localHostname;
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      final processors = Platform.numberOfProcessors.toString();

      // HMAC-SHA256 con salt fijo para no exponer datos del hardware
      final data = '$hostname|$os|$osVersion|$processors|baudex-device';
      final hmac = Hmac(sha256, utf8.encode('baudex-device-fp-2024'));
      final digest = hmac.convert(utf8.encode(data));
      return digest.toString(); // 64 chars hex
    } catch (e) {
      // Fallback: UUID v4 aleatorio si Platform falla
      return _generateUuidV4();
    }
  }

  /// Generar UUID v4 usando Random.secure() (fallback)
  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
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

  /// Limpiar todos los datos de autenticación y datos de negocio del tenant
  Future<void> clearAuthData() async {
    try {
      // Limpiar tenant data + cache del interceptor
      await clearTenantData();

      // Limpiar datos de autenticación en paralelo
      await Future.wait([
        deleteToken(),
        deleteRefreshToken(),
        deleteUserData(),
      ]);

      // Limpiar datos de negocio cacheados
      await clearBusinessDataCache();
    } catch (e) {
      throw Exception('Error al limpiar datos: $e');
    }
  }

  /// Limpiar datos de negocio cacheados en SharedPreferences
  /// (warehouses, alert products, y cualquier cache de datos del tenant)
  Future<void> clearBusinessDataCache() async {
    try {
      print('🧹 SecureStorageService: Limpiando cache de datos de negocio...');
      final prefs = await SharedPreferences.getInstance();

      // Recopilar todas las claves de negocio a eliminar
      final keysToRemove = <String>[];
      for (final key in prefs.getKeys()) {
        // Warehouses cache
        if (key.contains('inventory_warehouses_cache')) keysToRemove.add(key);
        // Alert products cache (por warehouseId)
        if (key.contains('alert_products_')) keysToRemove.add(key);
        // Cualquier otro cache de datos de negocio
        if (key.contains('_cache') && !key.startsWith('flutter.')) keysToRemove.add(key);
      }

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        print('✅ SecureStorageService: ${keysToRemove.length} claves de cache de negocio eliminadas');
      } else {
        print('✅ SecureStorageService: No había cache de negocio que limpiar');
      }
    } catch (e) {
      print('⚠️ SecureStorageService: Error limpiando cache de negocio (no crítico): $e');
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

  // ===================== OFFLINE LOGIN CREDENTIALS =====================

  /// Key para credenciales offline
  static const String _offlineCredentialsKey = 'offline_credentials';

  /// Guardar credenciales hasheadas para login offline
  /// El password se guarda como hash SHA-256 para seguridad
  Future<void> saveOfflineCredentials({
    required String email,
    required String passwordHash,
  }) async {
    try {
      final credentials = {
        'email': email.toLowerCase().trim(),
        'passwordHash': passwordHash,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _writeSecure(_offlineCredentialsKey, jsonEncode(credentials));
      if (kDebugMode) {
        print('🔐 SecureStorageService: Credenciales offline guardadas para $email');
      }
    } catch (e) {
      throw Exception('Error al guardar credenciales offline: $e');
    }
  }

  /// Obtener credenciales offline guardadas
  Future<Map<String, dynamic>?> getOfflineCredentials() async {
    try {
      final credentialsJson = await _readSecure(_offlineCredentialsKey);
      if (credentialsJson != null) {
        return jsonDecode(credentialsJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verificar credenciales offline
  /// Retorna true si el email y passwordHash coinciden con los guardados
  Future<bool> verifyOfflineCredentials({
    required String email,
    required String passwordHash,
  }) async {
    try {
      final savedCredentials = await getOfflineCredentials();
      if (savedCredentials == null) return false;

      final savedEmail = savedCredentials['email'] as String?;
      final savedHash = savedCredentials['passwordHash'] as String?;

      if (savedEmail == null || savedHash == null) return false;

      return savedEmail == email.toLowerCase().trim() && savedHash == passwordHash;
    } catch (e) {
      return false;
    }
  }

  /// Eliminar credenciales offline
  Future<void> deleteOfflineCredentials() async {
    try {
      await _deleteSecure(_offlineCredentialsKey);
    } catch (e) {
      throw Exception('Error al eliminar credenciales offline: $e');
    }
  }

  /// Verificar si existen credenciales offline válidas
  Future<bool> hasOfflineCredentials() async {
    try {
      final credentials = await getOfflineCredentials();
      if (credentials == null) return false;

      final savedAt = credentials['savedAt'] as String?;
      if (savedAt == null) return false;

      // Las credenciales expiran después de 30 días
      final savedDate = DateTime.parse(savedAt);
      final daysSinceSaved = DateTime.now().difference(savedDate).inDays;

      return daysSinceSaved <= 30;
    } catch (e) {
      return false;
    }
  }

  // ===================== LAST USER ID (LOGOUT PEREZOSO) =====================

  /// Clave para guardar el ID del último usuario que estuvo logueado.
  /// Se persiste a través de logout para que el próximo login pueda detectar
  /// si es el MISMO usuario (no tocar BD) o uno DIFERENTE (cambio de tenant
  /// real → ahí sí borrar BD y descargar todo del nuevo tenant).
  static const String _lastUserIdKey = 'last_user_id';

  /// Lee el ID del último usuario guardado. `null` si nunca hubo login.
  Future<String?> getLastUserId() async {
    try {
      final v = await _readSecure(_lastUserIdKey);
      return (v != null && v.isNotEmpty) ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Guarda el ID del usuario actual. Llamar antes de logout o al confirmar
  /// login exitoso. Sobrevive al `clearAll()`.
  Future<void> setLastUserId(String userId) async {
    try {
      await _writeSecure(_lastUserIdKey, userId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ No se pudo persistir lastUserId: $e');
      }
    }
  }
}
