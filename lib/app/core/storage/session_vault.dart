// lib/app/core/storage/session_vault.dart
//
// Copia protegida de la sesión (ver `secure_storage_service.dart`): lo que
// hace falta para seguir con la sesión abierta cuando el almacén seguro de
// Windows no devuelve nada.
//
// Reglas de seguridad:
//  - La sesión se guarda como UN solo dato cifrado: o está toda, o no hay
//    copia. Nunca queda mezclada a medias.
//  - Iniciar sesión empieza la copia de cero: no puede quedar nada del
//    usuario o negocio anterior.
//  - Al reponer, se comprueba que el token, el usuario y el negocio sean
//    del mismo dueño; si no cuadran, la copia no se usa.
//  - Cerrar sesión borra la copia y lo comprueba; si no se pudo borrar,
//    queda anulada.
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants/api_constants.dart';
import 'value_protector.dart';

/// Id de usuario dentro de un JWT (sin validar la firma: solo para saber
/// de quién es). Null si no se puede leer.
String? jwtUserId(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return null;
    final id = payload['id'] ?? payload['sub'];
    return id?.toString();
  } catch (_) {
    return null;
  }
}

/// Lo que se puede usar de una copia de sesión. Vacío si no es coherente:
/// falta el token o el usuario, o el token es de otro usuario. El negocio
/// solo se devuelve si es el del usuario.
Map<String, String> coherentSessionCopy(Map<String, String> copy) {
  final token = copy[ApiConstants.tokenKey];
  final userRaw = copy[ApiConstants.userKey];
  if (token == null || token.isEmpty || userRaw == null) return const {};
  final Map<String, dynamic> user;
  try {
    final decoded = json.decode(userRaw);
    if (decoded is! Map) return const {};
    user = Map<String, dynamic>.from(decoded);
  } catch (_) {
    return const {};
  }
  final userId = user['id']?.toString();
  final owner = jwtUserId(token);
  if (owner != null && userId != null && owner != userId) return const {};

  final out = Map<String, String>.of(copy);
  final userOrg = user['organizationId']?.toString();
  final orgRaw = out['current_organization'];
  if (orgRaw != null && userOrg != null) {
    try {
      final org = json.decode(orgRaw);
      if (org is! Map || org['id']?.toString() != userOrg) {
        out.remove('current_organization');
      }
    } catch (_) {
      out.remove('current_organization');
    }
  }
  final userSlug = user['organizationSlug']?.toString();
  final slug = out['tenant_slug'];
  if (slug != null && userSlug != null && userSlug.isNotEmpty && slug != userSlug) {
    out.remove('tenant_slug');
  }
  return out;
}

class SessionVault {
  SessionVault({required this.protector, this.revokedFlag});

  final ValueProtector protector;

  /// Archivo aparte que anula la copia cuando no se pudo borrar de las
  /// preferencias (null = solo en memoria).
  final File? revokedFlag;

  static const String sessionEntry = 'vault_session_v2';
  static const String deviceEntry = 'vault_device_v2';

  static const String _deviceIdKey = 'device_unique_id';
  static const String _lastUserIdKey = 'last_user_id';

  /// Se van al cerrar sesión.
  static const Set<String> sessionKeys = {
    ApiConstants.tokenKey,
    ApiConstants.refreshTokenKey,
    ApiConstants.userKey,
    'tenant_slug',
    'current_organization',
    'offline_credentials',
  };

  /// Identifican al equipo y al último usuario: sobreviven al cierre.
  static const Set<String> deviceKeys = {_deviceIdKey, _lastUserIdKey};

  /// Entradas de la primera versión (una por clave): ya no se usan.
  static const List<String> legacyEntries = [
    'vault_${ApiConstants.tokenKey}',
    'vault_${ApiConstants.refreshTokenKey}',
    'vault_${ApiConstants.userKey}',
    'vault_tenant_slug',
    'vault_current_organization',
    'vault_offline_credentials',
    'vault_$_deviceIdKey',
    'vault_$_lastUserIdKey',
  ];

  static bool handles(String key) =>
      sessionKeys.contains(key) || deviceKeys.contains(key);

  Map<String, String>? _session;
  Map<String, String>? _device;
  bool _revoked = false;

  /// Cambia con cada borrado o reinicio de la copia: una escritura que
  /// empezó antes (sembrar lo leído) no puede revivir lo ya cerrado.
  int _generation = 0;

  Future<Map<String, String>> _load(String entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (entry == sessionEntry) {
        for (final old in legacyEntries) {
          if (prefs.containsKey(old)) await prefs.remove(old);
        }
      }
      final stored = prefs.getString(entry);
      if (stored == null) return {};
      final plain = protector.unprotect(stored);
      if (plain == null) return {};
      final decoded = json.decode(plain);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is String) e.key.toString(): e.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, String>> _sessionMap() async =>
      _session ??= await _load(sessionEntry);
  Future<Map<String, String>> _deviceMap() async =>
      _device ??= await _load(deviceEntry);

  bool get _isRevoked {
    if (_revoked) return true;
    try {
      return revokedFlag?.existsSync() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Deja [entry] en las preferencias igual a [values] y lo comprueba.
  /// Si no se puede cifrar o guardar, la entrada se quita entera (nunca
  /// queda una versión anterior). Devuelve false si quedó algo que no
  /// debía.
  Future<bool> _persist(String entry, Map<String, String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? stored;
      if (values.isNotEmpty) stored = protector.protect(json.encode(values));
      if (stored != null) {
        if (await prefs.setString(entry, stored) && prefs.getString(entry) == stored) {
          return true;
        }
        // No quedó guardado lo nuevo: que tampoco quede lo viejo.
        values.clear();
      } else {
        // Vacío, o no se pudo cifrar: sin copia.
        values.clear();
      }
      for (var attempt = 0; attempt < 2; attempt++) {
        await prefs.remove(entry);
        if (!prefs.containsKey(entry)) return true;
      }
      return false;
    } catch (_) {
      values.clear();
      return false;
    }
  }

  void _revoke() {
    _revoked = true;
    try {
      revokedFlag?.parent.createSync(recursive: true);
      revokedFlag?.writeAsStringSync('1', flush: true);
    } catch (_) {}
  }

  Future<bool> _clearRevocation() async {
    try {
      if (revokedFlag != null && revokedFlag!.existsSync()) revokedFlag!.deleteSync();
    } catch (_) {
      return false; // no se pudo quitar la anulación: la copia sigue anulada
    }
    _revoked = false;
    return true;
  }

  Future<void> write(String key, String value) async {
    if (deviceKeys.contains(key)) {
      final map = await _deviceMap();
      if (map[key] == value) return;
      map[key] = value;
      await _persist(deviceEntry, map);
      return;
    }
    if (!sessionKeys.contains(key)) return;
    if (_isRevoked) return; // solo un inicio de sesión la vuelve a activar
    final map = await _sessionMap();
    if (map[key] == value) return;
    map[key] = value;
    if (!await _persist(sessionEntry, map)) _revoke();
  }

  /// Valor de la copia, o null. Las claves de sesión solo se devuelven si
  /// la copia entera es coherente.
  Future<String?> read(String key) async {
    if (deviceKeys.contains(key)) return (await _deviceMap())[key];
    if (!sessionKeys.contains(key) || _isRevoked) return null;
    return coherentSessionCopy(await _sessionMap())[key];
  }

  /// Quita [key] de la copia y comprueba que ya no esté. Quitar el token
  /// es cerrar la sesión: se va toda la copia de sesión.
  Future<void> delete(String key) async {
    _generation++;
    if (deviceKeys.contains(key)) {
      final map = await _deviceMap();
      if (map.remove(key) != null) await _persist(deviceEntry, map);
      return;
    }
    if (!sessionKeys.contains(key)) return;
    final map = await _sessionMap();
    if (key == ApiConstants.tokenKey) {
      // Las credenciales sin internet no son la sesión: se conservan en
      // memoria solo si se piden aparte; aquí se va todo.
      map.clear();
    } else {
      map.remove(key);
    }
    final ok = await _persist(sessionEntry, map);
    // Comprobar contra lo que de verdad quedó guardado.
    _session = null;
    final after = await _sessionMap();
    final gone = key == ApiConstants.tokenKey ? after.isEmpty : !after.containsKey(key);
    if (!ok || !gone) {
      _session = <String, String>{};
      _revoke();
    }
  }

  /// Inicio de sesión: la copia empieza de cero.
  Future<void> resetSession() async {
    _generation++;
    final map = await _sessionMap();
    map.clear();
    final ok = await _persist(sessionEntry, map);
    if (ok) {
      await _clearRevocation();
    } else {
      _revoke();
    }
  }

  /// Copia un valor que el almacén seguro sí devolvió (sesiones abiertas
  /// antes de existir la copia). No pisa nada ni revive una sesión que se
  /// cerró mientras tanto.
  Future<void> seed(String key, String value) async {
    if (!handles(key)) return;
    final generation = _generation;
    final map = deviceKeys.contains(key) ? await _deviceMap() : await _sessionMap();
    if (generation != _generation) return; // se cerró sesión mientras tanto
    if (map.containsKey(key)) return;
    if (sessionKeys.contains(key) && _isRevoked) return;
    await write(key, value);
    if (generation != _generation && sessionKeys.contains(key)) {
      // Carrera con un cierre de sesión: lo sembrado no debe quedar.
      await delete(ApiConstants.tokenKey);
    }
  }
}
