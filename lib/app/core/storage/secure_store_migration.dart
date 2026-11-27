import 'dart:async';
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

  /// Tope de la respuesta al que pidió la operación. Si no termina (el
  /// almacén del sistema no responde), el que la pidió recibe
  /// `TimeoutException` y deja de esperar.
  static Duration operationTimeout = const Duration(seconds: 10);

  /// Tope para soltar la fila. Aunque al que la pidió ya se le contestó, la
  /// operación puede seguir escribiendo el archivo por detrás: la siguiente
  /// NO arranca hasta que termine de verdad (dos a la vez se pisan). Solo si
  /// pasa este tope largo se da por perdida y la fila sigue.
  static Duration releaseTimeout = const Duration(seconds: 60);

  Future<T> run<T>(Future<T> Function() op) {
    final released = Completer<void>();
    final result = _tail.then((_) {
      final Future<T> real;
      try {
        real = op();
      } catch (_) {
        released.complete();
        rethrow;
      }
      real
          .then<void>((_) {}, onError: (_) {})
          .timeout(releaseTimeout, onTimeout: () {})
          .whenComplete(released.complete);
      return real.timeout(operationTimeout);
    });
    _tail = released.future;
    return result;
  }
}

enum SecureMigrationOutcome {
  /// Ya estaba confirmado antes (solo se limpian restos).
  alreadyMigrated,

  /// Primer arranque: copiado y verificado en el almacén seguro, pero
  /// preferencias se conservan (y se siguen actualizando) hasta confirmar.
  copied,

  /// Segundo arranque: el almacén seguro se leyó bien otra vez; se borró
  /// todo de preferencias.
  confirmed,

  /// El almacén seguro no funciona: se sigue con preferencias.
  storeUnavailable,

  /// Falló a mitad: preferencias quedan intactas y se sigue con ellas.
  failed,
}

extension SecureMigrationOutcomeX on SecureMigrationOutcome {
  /// true = la app debe seguir leyendo y escribiendo en preferencias.
  bool get usePrefs =>
      this == SecureMigrationOutcome.storeUnavailable || this == SecureMigrationOutcome.failed;

  /// true = escribir también en preferencias (respaldo hasta confirmar).
  bool get mirrorToPrefs => this == SecureMigrationOutcome.copied;
}

/// Lleva los valores `secure_*` de SharedPreferences (donde Windows los
/// guardaba con un cifrado casero) al almacén seguro del sistema, en dos
/// arranques para que un fallo de DPAPI nunca obligue a volver a entrar:
///
/// Arranque 1: prueba el almacén, escribe cada valor descifrado, lo lee de
///   vuelta y compara. Preferencias NO se borran: la app usa el almacén y
///   además sigue copiando cada cambio en preferencias ([mirrorToPrefs]).
/// Arranque 2: si el almacén vuelve a leer bien todas las claves, se borran
///   de preferencias y queda confirmado.
/// Si el almacén falla en cualquier momento antes de confirmar, preferencias
///   siguen al día y la app vuelve a ellas sin perder la sesión.
class PrefsToSecureStoreMigration {
  PrefsToSecureStoreMigration({
    required this.prefs,
    required this.store,
    required this.decode,
    this.onProblem,
    this.abandoned,
  });

  /// Traslado confirmado (preferencias limpias). No empieza por `secure_`
  /// para que `clearAll()` (cerrar sesión) no lo borre.
  static const doneFlag = 'baudex_secure_store_migrated_v1';

  /// Copiado y verificado una vez; falta el arranque de confirmación.
  static const copiedFlag = 'baudex_secure_store_copied_v1';
  static const keyPrefix = 'secure_';
  static const _probeKey = 'baudex_secure_store_probe';

  final SharedPreferences prefs;
  final SecureKeyValueStore store;

  /// Pasa el valor guardado en preferencias al valor real (descifra las
  /// claves sensibles). null si no se puede leer (por ejemplo, copiado de
  /// otro equipo): ese valor ya estaba perdido y no se traslada.
  final String? Function(String key, String stored) decode;

  final void Function(Object error, StackTrace? stack, Map<String, dynamic> context)? onProblem;

  /// true = la app dejó de esperar este traslado y ya sigue con
  /// preferencias (guardó o va a guardar ahí la sesión, el negocio y el
  /// correo). Desde ese momento el traslado NO borra nada de preferencias ni
  /// marca nada como hecho: lo deja pendiente para el próximo arranque.
  final bool Function()? abandoned;

  bool get _abandoned {
    try {
      return abandoned?.call() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Llegó tarde: preferencias quedan intactas y como fuente de verdad.
  Future<SecureMigrationOutcome> _leavePending() async {
    await markPending(prefs);
    return SecureMigrationOutcome.failed;
  }

  /// La app volvió a preferencias porque el almacén falló: lo que se escriba
  /// ahora en preferencias se trasladará de nuevo cuando el almacén funcione.
  static Future<void> markPending(SharedPreferences prefs) async {
    try {
      await prefs.setBool(doneFlag, false);
      await prefs.setBool(copiedFlag, false);
    } catch (_) {}
  }

  Future<SecureMigrationOutcome> run() async {
    String step = 'probe';
    final wasDone = prefs.getBool(doneFlag) == true;
    // En Windows el almacén seguro es UN archivo (`flutter_secure_storage
    // .dat`) que el complemento reescribe entero en cada cambio y BORRA si
    // no lo puede descifrar. Por eso:
    //  - con el traslado ya confirmado la prueba es solo de lectura (no se
    //    reescribe el archivo de la sesión en cada arranque);
    //  - si falla se reintenta una vez: cuando el archivo estaba dañado el
    //    complemento lo borra al primer intento y el segundo ya funciona.
    Future<void> probeOnce() async {
      if (wasDone) {
        await store.read(_probeKey);
        return;
      }
      final probe = DateTime.now().microsecondsSinceEpoch.toString();
      await store.write(_probeKey, probe);
      final back = await store.read(_probeKey);
      await store.delete(_probeKey);
      if (back != probe) throw StateError('el almacén seguro no devolvió lo escrito');
    }

    try {
      await probeOnce();
    } catch (first, firstStack) {
      try {
        await probeOnce();
        // Se recuperó solo: queda anotado que el archivo estaba dañado.
        _report(first, firstStack, {'step': 'probe-recovered', 'confirmed_before': wasDone});
      } catch (e, st) {
        _report(e, st, {'step': step, 'confirmed_before': wasDone});
        await markPending(prefs);
        return SecureMigrationOutcome.storeUnavailable;
      }
    }

    if (_abandoned) return _leavePending();
    final keys = prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();

    if (wasDone) {
      // Restos de un borrado que falló: ya no son la fuente de verdad.
      await _removeAll(keys);
      return SecureMigrationOutcome.alreadyMigrated;
    }

    if (prefs.getBool(copiedFlag) == true) {
      return _confirm(keys);
    }

    final values = <String, String>{};
    try {
      step = 'write';
      for (final fullKey in keys) {
        final value = _decoded(fullKey);
        if (value == null) continue;
        final key = fullKey.substring(keyPrefix.length);
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

    if (_abandoned) return _leavePending();
    await prefs.setBool(copiedFlag, true);
    return SecureMigrationOutcome.copied;
  }

  /// Segundo arranque: el almacén debe tener (y leer bien) cada clave que
  /// sigue en preferencias. Si falta alguna se repone desde preferencias.
  Future<SecureMigrationOutcome> _confirm(List<String> keys) async {
    try {
      for (final fullKey in keys) {
        final key = fullKey.substring(keyPrefix.length);
        final inStore = await store.read(key);
        if (inStore != null) continue; // el almacén es la fuente de verdad
        final value = _decoded(fullKey);
        if (value == null) continue;
        await store.write(key, value);
        if (await store.read(key) != value) {
          throw StateError('la clave $key no quedó igual');
        }
      }
    } catch (e, st) {
      _report(e, st, {'step': 'confirm', 'keys': keys.length});
      return SecureMigrationOutcome.failed;
    }
    if (_abandoned) return _leavePending();
    await _removeAll(keys);
    await prefs.setBool(doneFlag, true);
    await prefs.setBool(copiedFlag, false);
    return SecureMigrationOutcome.confirmed;
  }

  String? _decoded(String fullKey) {
    final stored = prefs.getString(fullKey);
    if (stored == null) return null;
    return decode(fullKey.substring(keyPrefix.length), stored);
  }

  Future<void> _removeAll(List<String> keys) async {
    for (final k in keys) {
      try {
        await prefs.remove(k);
      } catch (_) {}
    }
  }

  void _report(Object e, StackTrace? st, Map<String, dynamic> context) {
    try {
      onProblem?.call(e, st, context);
    } catch (_) {}
  }
}
