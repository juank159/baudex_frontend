// lib/app/core/storage/local_cache_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

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
  static final Set<String> _legacyChecked = <String>{};

  /// Tope de la consulta al llavero viejo (una caché no vale la espera).
  static Duration legacyReadTimeout = const Duration(seconds: 3);

  /// Solo para pruebas.
  static void debugForgetLegacyChecks() => _legacyChecked.clear();

  Future<String?> read({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_prefix$key');
    if (value != null) return value;
    // El llavero viejo se consulta una sola vez por clave en cada ejecución:
    // en Windows cada consulta abre y descifra el archivo entero de la
    // sesión, y una caché que aún no existe se pedía una y otra vez.
    if (!_legacyChecked.add('$_prefix$key')) return null;
    // En un equipo donde el almacén seguro es lento o no responde, ir a
    // buscar una caché vieja allí congela la ventana (el complemento
    // trabaja en el hilo de la ventana): una caché se vuelve a llenar sola.
    if (SecureStorageService.avoidsSystemStore || SecureStorageService.isMarkedSlow(prefs)) {
      return null;
    }
    try {
      final legacy = await _legacyKeychain.read(key: key).timeout(legacyReadTimeout);
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
