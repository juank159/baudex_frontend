// lib/app/core/storage/secure_store_migration.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Almacén seguro mínimo (en la app: `flutter_secure_storage`; en pruebas,
/// uno en memoria).
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Ejecuta las operaciones de una en una. En Windows `flutter_secure_storage`
/// guarda TODO en un solo archivo cifrado y cada operación lo lee, cambia y
/// reescribe: dos a la vez (por ejemplo borrar token y refresh en paralelo al
/// cerrar sesión) se pisan y una clave borrada puede "revivir".
class SerialQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}

enum SecureMigrationOutcome {
  /// Ya se había trasladado antes (solo se limpian restos).
  alreadyMigrated,

  /// Se trasladó en este arranque y quedó verificado.
  migrated,

  /// El almacén seguro no funciona: se sigue con preferencias.
  storeUnavailable,

  /// Falló a mitad: preferencias quedan intactas y se sigue con ellas.
  failed,
}

/// Lleva los valores `secure_*` de SharedPreferences (donde Windows los
/// guardaba con un cifrado casero) al almacén seguro del sistema.
///
/// Orden (no puede hacer perder la sesión):
/// 1. Prueba que el almacén escribe y lee.
/// 2. Escribe cada valor, ya descifrado.
/// 3. Lee cada uno de vuelta y compara.
/// 4. Solo entonces los borra de preferencias y marca el traslado.
/// Si algo falla en 1-3, preferencias quedan como estaban y la app sigue
/// usándolas; el próximo arranque lo reintenta.
class PrefsToSecureStoreMigration {
  PrefsToSecureStoreMigration({
    required this.prefs,
    required this.store,
    required this.decode,
    this.onProblem,
  });

  /// Bandera en preferencias. No empieza por `secure_` para que
  /// `clearAll()` (cerrar sesión) no la borre.
  static const doneFlag = 'baudex_secure_store_migrated_v1';
  static const keyPrefix = 'secure_';
  static const _probeKey = 'baudex_secure_store_probe';

  final SharedPreferences prefs;
  final SecureKeyValueStore store;

  /// Pasa el valor guardado en preferencias al valor real (descifra las
  /// claves sensibles). null si no se puede leer (por ejemplo, copiado de
  /// otro equipo): ese valor ya estaba perdido y no se traslada.
  final String? Function(String key, String stored) decode;

  final void Function(Object error, StackTrace? stack, Map<String, dynamic> context)? onProblem;

  /// Marca que el traslado ya no vale (la app volvió a preferencias porque el
  /// almacén falló): lo que se escriba ahora en preferencias se trasladará
  /// de nuevo en el próximo arranque que funcione el almacén.
  static Future<void> markPending(SharedPreferences prefs) async {
    try {
      await prefs.setBool(doneFlag, false);
    } catch (_) {}
  }

  Future<SecureMigrationOutcome> run() async {
    String step = 'probe';
    try {
      final probe = DateTime.now().microsecondsSinceEpoch.toString();
      await store.write(_probeKey, probe);
      final back = await store.read(_probeKey);
      await store.delete(_probeKey);
      if (back != probe) throw StateError('el almacén seguro no devolvió lo escrito');
    } catch (e, st) {
      _report(e, st, {'step': step});
      await markPending(prefs);
      return SecureMigrationOutcome.storeUnavailable;
    }

    final keys = prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();

    if (prefs.getBool(doneFlag) == true) {
      // Restos de un borrado que falló: ya no son la fuente de verdad.
      for (final k in keys) {
        try {
          await prefs.remove(k);
        } catch (_) {}
      }
      return SecureMigrationOutcome.alreadyMigrated;
    }

    final values = <String, String>{};
    try {
      step = 'write';
      for (final fullKey in keys) {
        final stored = prefs.getString(fullKey);
        if (stored == null) continue;
        final key = fullKey.substring(keyPrefix.length);
        final value = decode(key, stored);
        if (value == null) continue;
        await store.write(key, value);
        values[key] = value;
      }
      step = 'verify';
      for (final entry in values.entries) {
        final back = await store.read(entry.key);
        if (back != entry.value) {
          throw StateError('la clave ${entry.key} no quedó igual');
        }
      }
    } catch (e, st) {
      _report(e, st, {'step': step, 'keys': keys.length});
      return SecureMigrationOutcome.failed;
    }

    for (final k in keys) {
      try {
        await prefs.remove(k);
      } catch (_) {}
    }
    await prefs.setBool(doneFlag, true);
    return SecureMigrationOutcome.migrated;
  }

  void _report(Object e, StackTrace? st, Map<String, dynamic> context) {
    try {
      onProblem?.call(e, st, context);
    } catch (_) {}
  }
}
