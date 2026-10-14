// lib/app/core/storage/local_cache_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacén para CACHÉS de datos no sensibles (listas de inventario, reportes),
/// sobre SharedPreferences, con la misma forma de uso que
/// `FlutterSecureStorage` (read / write / delete).
///
/// El llavero del sistema (FlutterSecureStorage) es para secretos (tokens,
/// contraseñas). Usarlo para cachés fallaba en macOS con el error -34018
/// (falta un permiso especial) y esas listas no se guardaban.
///
/// Si un valor todavía está en el llavero de una versión anterior, se lee de
/// ahí una vez y se migra; los errores del llavero se ignoran.
class LocalCacheStore {
  LocalCacheStore({String prefix = 'cache_'}) : _prefix = prefix;

  final String _prefix;
  static const FlutterSecureStorage _legacyKeychain = FlutterSecureStorage();

  Future<String?> read({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_prefix$key');
    if (value != null) return value;
    try {
      final legacy = await _legacyKeychain.read(key: key);
      if (legacy != null) {
        await prefs.setString('$_prefix$key', legacy);
        try {
          await _legacyKeychain.delete(key: key);
        } catch (_) {}
      }
      return legacy;
    } catch (_) {
      return null;
    }
  }

  Future<void> write({required String key, required String? value}) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('$_prefix$key');
    } else {
      await prefs.setString('$_prefix$key', value);
    }
  }

  /// Todas las entradas de este almacén (claves sin el prefijo interno).
  Future<Map<String, String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, String>{};
    for (final fullKey in prefs.getKeys()) {
      if (!fullKey.startsWith(_prefix)) continue;
      final value = prefs.getString(fullKey);
      if (value != null) result[fullKey.substring(_prefix.length)] = value;
    }
    return result;
  }

  Future<void> delete({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
    try {
      await _legacyKeychain.delete(key: key);
    } catch (_) {}
  }
}
