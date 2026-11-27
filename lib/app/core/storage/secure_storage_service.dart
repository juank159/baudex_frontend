// lib/app/core/storage/secure_storage_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/constants/api_constants.dart';
import '../ops/ops_reporter.dart';
import '../security/offline_password_hasher.dart';
import 'secure_store_migration.dart';
import 'secure_store_stats.dart';
import 'durable_prefs_store.dart';
import 'session_startup_trace.dart';
import 'session_vault.dart';
import 'value_protector.dart';

/// Cifrador simétrico ligero para el fallback de SharedPreferences en macOS
/// y Windows cuando el keychain falla. Usa HMAC-SHA256 como keystream
/// (XOR cipher) + tag de autenticación, sin agregar dependencias.
///
/// **NO es AES-GCM ni reemplaza el keychain.** Sirve para que un atacante
/// que abra el archivo `.plist`/registry NO vea el JWT en plaintext.
/// La clave se deriva de un salt del hardware (hostname + OS version +
/// procesadores) + un secret de la app. Si el atacante se lleva SOLO el
/// archivo (no el Mac entero), no puede descifrar.
class _TokenCipher {
  static const _appSecret = 'baudex-token-2026-v1';

  static List<int> _deriveKey() {
    final salt = '${Platform.localHostname}|'
        '${Platform.operatingSystem}|'
        '${Platform.operatingSystemVersion}|'
        '${Platform.numberOfProcessors}|'
        '$_appSecret';
    return Hmac(sha256, utf8.encode(_appSecret)).convert(utf8.encode(salt)).bytes;
  }

  static List<int> _keystream(List<int> key, int length) {
    final out = <int>[];
    int counter = 0;
    while (out.length < length) {
      final block = Hmac(sha256, key)
          .convert(utf8.encode('ctr-$counter'))
          .bytes;
      out.addAll(block);
      counter++;
    }
    return out.sublist(0, length);
  }

  /// Cifra un string. Devuelve `enc:v1:<base64(tag+ciphertext)>`. El
  /// prefijo permite distinguir valores cifrados de los antiguos sin
  /// cifrar y migrarlos transparentemente.
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    try {
      final key = _deriveKey();
      final pt = utf8.encode(plaintext);
      final ks = _keystream(key, pt.length);
      final ct = List<int>.generate(pt.length, (i) => pt[i] ^ ks[i]);
      final tag = Hmac(sha256, key).convert(ct).bytes.sublist(0, 16);
      return 'enc:v1:${base64Encode(tag + ct)}';
    } catch (_) {
      // Si la derivación falla, mejor guardar plaintext que perder el dato.
      return plaintext;
    }
  }

  /// Descifra un valor. Si NO empieza con `enc:v1:`, lo devuelve tal cual
  /// (compatibilidad con valores plaintext del esquema viejo). Si el tag
  /// no coincide → null (token corrupto o de OTRO equipo: rechazamos).
  static String? decrypt(String value) {
    if (!value.startsWith('enc:v1:')) return value; // formato viejo
    try {
      final raw = base64Decode(value.substring(7));
      if (raw.length < 16) return null;
      final key = _deriveKey();
      final tag = raw.sublist(0, 16);
      final ct = raw.sublist(16);
      final expectedTag = Hmac(sha256, key).convert(ct).bytes.sublist(0, 16);
      if (!_constantTimeEquals(tag, expectedTag)) return null;
      final ks = _keystream(key, ct.length);
      final pt = List<int>.generate(ct.length, (i) => ct[i] ^ ks[i]);
      return utf8.decode(pt);
    } catch (_) {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// `flutter_secure_storage` con las operaciones en fila en Windows (allí todo
/// vive en un solo archivo cifrado con DPAPI y dos escrituras a la vez se
/// pisan; ver [SerialQueue]).
class _QueuedSecureStorage implements SecureKeyValueStore {
  const _QueuedSecureStorage(this._inner, {this.cached = true});

  final FlutterSecureStorage _inner;

  /// false = cada operación va al archivo (para comprobar el almacén de
  /// verdad al decidir dónde se guarda la sesión).
  final bool cached;
  static final SerialQueue _queue = SerialQueue();

  bool get _serialize => defaultTargetPlatform == TargetPlatform.windows;

  Future<T> _run<T>(Future<T> Function() op) => _serialize ? _queue.run(op) : op();

  // ---- Caché en memoria (Windows) ----
  //
  // En Windows cada lectura abre `flutter_secure_storage.dat` entero y lo
  // descifra, en el hilo de la pantalla, y la app lee el token en cada
  // petición (cientos de veces por minuto). Además, si justo no puede
  // leerlo, el complemento BORRA el archivo. Por eso el archivo se lee una
  // vez por ejecución y después todo sale de memoria; escribir y borrar
  // actualizan memoria y archivo, y solo tocan el archivo si algo cambió.
  static Map<String, String>? _cache;

  /// Olvida lo leído: la próxima lectura vuelve al archivo.
  static void invalidateCache() => _cache = null;

  bool get _useCache => cached && _serialize;

  Future<Map<String, String>> _load() async {
    final current = _cache;
    if (current != null) return current;
    final watch = Stopwatch()..start();
    try {
      final all = await _inner.readAll();
      SecureStoreStats.fileRead(watch.elapsed);
      return _cache = Map<String, String>.of(all);
    } catch (_) {
      SecureStoreStats.fileRead(watch.elapsed, failed: true);
      rethrow;
    }
  }

  Future<T> _timedRead<T>(Future<T> Function() op) async {
    final watch = Stopwatch()..start();
    try {
      final result = await op();
      SecureStoreStats.fileRead(watch.elapsed);
      return result;
    } catch (_) {
      SecureStoreStats.fileRead(watch.elapsed, failed: true);
      rethrow;
    }
  }

  Future<void> _timedWrite(Future<void> Function() op) async {
    final watch = Stopwatch()..start();
    try {
      await op();
    } finally {
      SecureStoreStats.fileWrite(watch.elapsed);
    }
  }

  @override
  Future<String?> read(String key) => _run(() async {
    if (!_useCache) return _timedRead(() => _inner.read(key: key));
    final hadCache = _cache != null;
    final value = (await _load())[key];
    if (hadCache) SecureStoreStats.memoryRead();
    return value;
  });

  @override
  Future<void> write(String key, String value) => _run(() async {
    if (!_useCache) {
      await _timedWrite(() => _inner.write(key: key, value: value));
      if (_serialize) _cache = null;
      return;
    }
    Map<String, String>? map;
    try {
      map = await _load();
    } catch (_) {
      // Archivo dañado: el complemento ya lo borró; se escribe de cero.
      try {
        map = await _load();
      } catch (_) {}
    }
    // Cada escritura reescribe el archivo entero de la sesión: si el valor
    // ya es ese, no se toca.
    if (map != null && map[key] == value) return;
    try {
      await _timedWrite(() => _inner.write(key: key, value: value));
      map?[key] = value;
    } catch (_) {
      _cache = null; // no se sabe qué quedó: releer
      rethrow;
    }
  });

  @override
  Future<void> delete(String key) => _run(() async {
    if (!_useCache) {
      await _timedWrite(() => _inner.delete(key: key));
      if (_serialize) _cache = null;
      return;
    }
    Map<String, String>? map;
    try {
      map = await _load();
    } catch (_) {}
    if (map != null && !map.containsKey(key)) return; // nada que borrar
    try {
      await _timedWrite(() => _inner.delete(key: key));
      map?.remove(key);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  });

  Future<Map<String, String>> readAll() => _run(() async {
    if (!_useCache) return _timedRead(() => _inner.readAll());
    final hadCache = _cache != null;
    final all = Map<String, String>.of(await _load());
    if (hadCache) SecureStoreStats.memoryRead();
    return all;
  });
}

class SecureStorageService {
  static const _storage = _QueuedSecureStorage(_plugin);

  /// El mismo almacén sin memoria intermedia: para probarlo de verdad.
  static const _rawStorage = _QueuedSecureStorage(_plugin, cached: false);
  static const _plugin = FlutterSecureStorage(
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
  // Una vez testeado el keychain (exitosamente), no volver a testear
  static bool _keychainTested = false;

  /// En Windows: true = seguir con preferencias (se decide una vez).
  static Future<bool>? _windowsDecision;

  /// Windows, primer arranque tras el traslado: cada cambio también se
  /// guarda en preferencias, para volver a ellas sin perder la sesión si el
  /// almacén seguro falla antes de confirmarse.
  static bool _mirrorToPrefs = false;

  /// Solo para pruebas: simula un arranque nuevo de la app.
  @visibleForTesting
  static void debugSimulateRestart() {
    _QueuedSecureStorage.invalidateCache();
    _vaultSeeded.clear();
    _vaultInstance = null;
    _windowsDecision = null;
    _windowsDecisionTimedOut = false;
    _useSharedPreferences = false;
    _keychainTested = false;
    _mirrorToPrefs = false;
    _decryptedCache.clear();
  }

  // ===================== COPIA PROTEGIDA (WINDOWS) =====================
  //
  // `flutter_secure_storage` en Windows guarda cada valor en un archivo
  // cifrado con una llave que vive en el Administrador de credenciales. Si
  // esa llave no está al encender el equipo (hay equipos que no la
  // conservan entre reinicios, o el servicio aún no responde), el
  // complemento devuelve null sin avisar: la sesión "desaparece" aunque el
  // archivo siga ahí. Por eso lo esencial de la sesión se guarda además en
  // las preferencias del equipo, cifrado con la protección de datos de
  // Windows (DPAPI: solo este usuario en este equipo lo puede leer), y se
  // usa cuando el almacén seguro no devuelve nada.

  /// Solo para pruebas: cifrador de la copia protegida (en la app, DPAPI).
  @visibleForTesting
  static ValueProtector? debugProtector;

  /// Solo para pruebas: archivo que anula la copia.
  @visibleForTesting
  static File? debugRevokedFlag;

  static ValueProtector? get _protector {
    if (debugProtector != null) return debugProtector;
    if (defaultTargetPlatform != TargetPlatform.windows) return null;
    return DpapiProtector.isSupported ? const DpapiProtector() : null;
  }

  static SessionVault? _vaultInstance;
  static ValueProtector? _vaultProtector;

  /// La copia protegida (ver `session_vault.dart`), o null donde no aplica.
  static Future<SessionVault?> _vault() async {
    final protector = _protector;
    if (protector == null) return null;
    if (_vaultInstance != null && identical(_vaultProtector, protector)) {
      return _vaultInstance;
    }
    File? flag = debugRevokedFlag;
    if (flag == null && debugProtector == null && Platform.isWindows) {
      try {
        final dir = await getApplicationSupportDirectory();
        flag = File('${dir.path}${Platform.pathSeparator}sesion_copia_anulada');
      } catch (_) {}
    }
    _vaultProtector = protector;
    return _vaultInstance = SessionVault(protector: protector, revokedFlag: flag);
  }

  static Future<void> _vaultWrite(String key, String value) async {
    try {
      await (await _vault())?.write(key, value);
    } catch (_) {}
  }

  static Future<String?> _vaultRead(String key) async {
    try {
      return await (await _vault())?.read(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _vaultDelete(String key) async {
    final vault = await _vault();
    if (vault == null || !SessionVault.handles(key)) return;
    await vault.delete(key);
  }

  static bool _closesSession(String key) =>
      key == ApiConstants.tokenKey ||
      key == ApiConstants.refreshTokenKey ||
      key == ApiConstants.userKey;

  /// Tras cerrar sesión: que ni la copia `.bak` de las preferencias ni los
  /// archivos dañados apartados conserven la sesión cerrada.
  static Future<void> _scrubPrefsHistory() async {
    try {
      await installedDurablePrefs?.scrubHistory();
    } catch (_) {}
  }

  /// El almacén principal no devolvió [key]: usar la copia protegida y,
  /// si la hay, reponerla en el almacén.
  static Future<String?> _recoverFromVault(String key, {required bool heal}) async {
    final value = await _vaultRead(key);
    if (value == null) return null;
    SessionStartupTrace.recoveredKeys.add(key);
    if (key == ApiConstants.tokenKey) {
      SessionStartupTrace.tokenSource ??= 'copia protegida';
    }
    if (heal) {
      try {
        await _storage.write(key, value);
      } catch (_) {}
    }
    return value;
  }

  static Future<void> _mirrorWrite(String key, String value) async {
    if (!_mirrorToPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_$key', _isSensitive(key) ? _TokenCipher.encrypt(value) : value);
    } catch (_) {}
  }

  static Future<void> _mirrorDelete(String key) async {
    if (!_mirrorToPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
    } catch (_) {}
  }

  /// Tope para decidir dónde se guarda la sesión. Todo lo que lee o guarda
  /// la sesión espera esta decisión: si el almacén seguro del sistema no
  /// responde, sin tope la app no recordaba negocio ni correo y el botón de
  /// iniciar sesión quedaba cargando para siempre.
  @visibleForTesting
  static Duration windowsDecisionTimeout = const Duration(seconds: 12);
  static bool _windowsDecisionTimedOut = false;

  static Future<bool> _decideWindowsStorageInTime() {
    _windowsDecisionTimedOut = false;
    // Cada decisión lleva su propia marca: un traslado que quedó corriendo
    // por detrás sabe que a ÉL ya no lo esperan y no borra ni marca nada.
    final run = _WindowsDecisionRun();
    return _decideWindowsStorage(run).timeout(
      windowsDecisionTimeout,
      onTimeout: () {
        // Se sigue con las preferencias del equipo (el modo de respaldo que
        // ya existe) durante TODA esta ejecución; el próximo arranque vuelve
        // a trasladar desde preferencias, que quedan como fuente de verdad.
        run.timedOut = true;
        _windowsDecisionTimedOut = true;
        _useSharedPreferences = true;
        _mirrorToPrefs = false;
        unawaited(SharedPreferences.getInstance()
            .then(PrefsToSecureStoreMigration.markPending)
            .catchError((Object _) {}));
        SessionStartupTrace.storageMode =
            'preferencias del equipo (el almacén seguro de Windows no respondió a tiempo)';
        OpsReporter.capture(
          TimeoutException('El almacén seguro no respondió', windowsDecisionTimeout),
          StackTrace.current,
          errorType: 'SecureStoreMigration',
          fingerprint: 'secure_store_migration|timeout',
        );
        return true;
      },
    );
  }

  static Future<bool> _decideWindowsStorage(_WindowsDecisionRun run) async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, st) {
      // Las preferencias no se pueden leer: NO son un respaldo utilizable.
      // Antes se elegía "seguir con preferencias" y cada lectura del token
      // fallaba; la sesión está (o se guardará) en el almacén seguro.
      OpsReporter.capture(e, st,
          errorType: 'SecureStoreMigration', fingerprint: 'secure_store_migration|prefs_unreadable');
      _useSharedPreferences = false;
      _mirrorToPrefs = false;
      SessionStartupTrace.storageMode =
          'almacén seguro de Windows (las preferencias no se pudieron leer)';
      return false;
    }
    try {
      final outcome = await PrefsToSecureStoreMigration(
        prefs: prefs,
        // Sin caché: aquí se comprueba el archivo de verdad.
        store: _rawStorage,
        decode: (key, stored) => _isSensitive(key) ? _TokenCipher.decrypt(stored) : stored,
        onProblem: (e, st, context) => OpsReporter.capture(
          e,
          st,
          errorType: 'SecureStoreMigration',
          fingerprint: 'secure_store_migration|${context['step']}',
          context: context,
        ),
        abandoned: () => run.timedOut,
      ).run();
      // El traslado pudo escribir o borrar: lo leído antes ya no vale.
      _QueuedSecureStorage.invalidateCache();
      // Llegó tarde: esta ejecución ya sigue con preferencias; no se cambia
      // de almacén a mitad de camino.
      if (run.timedOut) return true;
      _useSharedPreferences = outcome.usePrefs;
      _mirrorToPrefs = outcome.mirrorToPrefs;
      SessionStartupTrace.storageMode = outcome.usePrefs
          ? 'preferencias del equipo (el almacén seguro de Windows no respondió: ${outcome.name})'
          : 'almacén seguro de Windows + copia protegida';
      return outcome.usePrefs;
    } catch (e, st) {
      OpsReporter.capture(e, st,
          errorType: 'SecureStoreMigration', fingerprint: 'secure_store_migration|unexpected');
      if (run.timedOut) return true;
      _useSharedPreferences = true;
      return true;
    }
  }

  /// Método para detectar si debemos usar SharedPreferences como fallback.
  /// El resultado se cachea: si el keychain funciona, nunca vuelve a testear.
  static Future<bool> _shouldUseSharedPreferences() async {
    // Tras el tope de Windows la decisión no cambia en toda la ejecución.
    if (_useSharedPreferences || _windowsDecisionTimedOut) return true;

    // Windows: el almacén seguro (archivo cifrado con DPAPI) reemplaza a
    // SharedPreferences. La primera vez se trasladan los valores y solo si
    // quedan verificados; si el almacén falla, se sigue con preferencias.
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _windowsDecision ??= _decideWindowsStorageInTime();
      return await _windowsDecision!;
    }

    // En macOS, hacer UNA SOLA prueba del secure storage y cachear el resultado.
    // Antes se hacía el test en cada llamada, lo cual era N tests por N writes.
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      if (_keychainTested) return false; // ya sabemos que funciona
      try {
        await _storage.write('test_key', 'test_value');
        final testVal = await _storage.read('test_key');
        await _storage.delete('test_key');
        if (testVal != 'test_value') {
          throw Exception('Secure storage read/write mismatch');
        }
        _keychainTested = true;
        return false; // Secure storage funciona
      } catch (e) {
        if (kDebugMode) {
        }
        _useSharedPreferences = true;
        return true;
      }
    }
    return false;
  }

  /// Conjunto de claves SENSIBLES (tokens, credenciales) que se cifran
  /// con `_TokenCipher` cuando se usa el fallback de SharedPreferences.
  /// Para el resto de claves (preferencias, lista de emails, etc.) no
  /// vale la pena el costo de cifrado.
  static const Set<String> _sensitiveKeys = {
    // ApiConstants.tokenKey, refreshTokenKey, userKey — añadidos al
    // calcular runtime ya que son strings dinámicos. Ver _isSensitive().
  };

  static bool _isSensitive(String key) {
    return key == ApiConstants.tokenKey ||
        key == ApiConstants.refreshTokenKey ||
        key == ApiConstants.userKey ||
        key == _offlineCredentialsKey ||
        _sensitiveKeys.contains(key);
  }

  /// Wrapper para escribir datos con fallback. Cifra automáticamente
  /// las claves sensibles cuando se cae en SharedPreferences.
  /// Si SharedPreferences falla (datos corruptos/demasiado grandes),
  /// intenta recuperarse limpiando el storage y reintentando con keychain.
  static Future<void> _writeSecure(String key, String value) async {
    // Primero la copia protegida: si el almacén principal falla o pierde
    // el dato, la sesión no depende de él.
    await _vaultWrite(key, value);
    if (await _shouldUseSharedPreferences()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = _isSensitive(key) ? _TokenCipher.encrypt(value) : value;
        await prefs.setString('secure_$key', stored);
      } catch (e) {
        // SharedPreferences falló (posiblemente datos corruptos/muy grandes).
        // Resetear flags y reintentar con keychain directamente.
        if (kDebugMode) {
        }
        _useSharedPreferences = false;
        _keychainTested = false;
        // Intentar usar el keychain directamente
        await _storage.write(key, value);
        _keychainTested = true;
      }
    } else {
      await _storage.write(key, value);
      await _mirrorWrite(key, value);
    }
  }

  /// Wrapper para leer datos con fallback. Descifra transparentemente
  /// si la clave es sensible. Si el formato es viejo (sin prefijo
  /// `enc:v1:`), lo retorna tal cual y se reescribirá cifrado en el
  /// próximo write.
  /// Valor descifrado de cada clave sensible, junto al texto cifrado del
  /// que salió (para saber si sigue vigente).
  static final Map<String, MapEntry<String, String?>> _decryptedCache = {};

  static Future<String?> _readSecure(String key) async {
    if (await _shouldUseSharedPreferences()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('secure_$key');
        if (raw == null) return _recoverFromVault(key, heal: false);
        if (_isSensitive(key)) {
          // Descifrar cuesta (varias rondas de HMAC en Dart) y el token se
          // lee en CADA petición al servidor. Se recuerda el resultado
          // mientras el valor guardado sea exactamente el mismo; si cambia
          // (login, refresh, logout), se vuelve a descifrar.
          final cached = _decryptedCache[key];
          if (cached != null && cached.key == raw) return cached.value;
          final plain = _TokenCipher.decrypt(raw);
          _decryptedCache[key] = MapEntry(raw, plain);
          // No se pudo descifrar (cambió el equipo o el sistema): copia.
          if (plain == null) return _recoverFromVault(key, heal: false);
          return plain;
        }
        return raw;
      } catch (e) {
        // SharedPreferences falló en lectura — intentar keychain directo
        if (kDebugMode) {
        }
        _useSharedPreferences = false;
        _keychainTested = false;
        try {
          final val = await _storage.read(key);
          _keychainTested = true;
          return val ?? await _recoverFromVault(key, heal: false);
        } catch (_) {
          return _recoverFromVault(key, heal: false);
        }
      }
    } else {
      String? value;
      try {
        value = await _storage.read(key);
      } catch (_) {
        // El almacén falló al leer: que decida la copia protegida.
        if (_protector == null) rethrow;
      }
      if (value != null) {
        if (key == ApiConstants.tokenKey) {
          SessionStartupTrace.tokenSource ??= 'almacén seguro';
        }
        await _seedVault(key, value);
        return value;
      }
      final recovered = await _recoverFromVault(key, heal: true);
      if (recovered == null && key == ApiConstants.tokenKey) {
        SessionStartupTrace.secureFileExists ??= await _secureFileExists(key);
      }
      return recovered;
    }
  }

  static final Set<String> _vaultSeeded = <String>{};

  /// Sesiones abiertas antes de existir la copia protegida: se copia lo
  /// que el almacén seguro sí devolvió, una vez por arranque.
  static Future<void> _seedVault(String key, String value) async {
    if (!SessionVault.handles(key) || !_vaultSeeded.add(key)) return;
    try {
      await (await _vault())?.seed(key, value);
    } catch (_) {}
  }

  /// ¿Sigue en disco el archivo de [key] del almacén seguro de Windows?
  /// (Si está pero no se pudo leer, se perdió la llave que lo descifra.)
  static Future<bool?> _secureFileExists(String key) async {
    if (!Platform.isWindows) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return dir
          .listSync()
          .whereType<File>()
          .any((f) => f.path.endsWith('$key.secure'));
    } catch (_) {
      return null;
    }
  }

  /// Wrapper para eliminar datos con fallback
  static Future<void> _deleteSecure(String key) async {
    try {
      await _deleteSecureNow(key);
    } finally {
      // Después de borrar de todos lados: que los archivos viejos de
      // preferencias no conserven la sesión cerrada.
      if (_closesSession(key)) await _scrubPrefsHistory();
    }
  }

  static Future<void> _deleteSecureNow(String key) async {
    await _vaultDelete(key);
    if (await _shouldUseSharedPreferences()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('secure_$key');
      } catch (_) {
        // Si SharedPreferences falla en delete, intentar keychain
        try { await _storage.delete(key); } catch (_) {}
      }
    } else {
      await _storage.delete(key);
      await _mirrorDelete(key);
    }
  }

  // ===================== TOKEN MANAGEMENT =====================

  /// Guardar token de acceso.
  /// Valida que el token sea razonable (un JWT no es un blob JSON de 10MB).
  /// Si el write falla, intenta limpiar el storage corrupto y reintenta.
  Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Error al guardar token: token vacío');
    }
    // Un JWT legítimo tiene formato: header.payload.signature (3 partes, < 16KB)
    // Un blob de 10MB no es un token válido — rechazar antes de intentar guardarlo.
    if (token.length > 16384) {
      throw Exception(
        'Error al guardar token: token inválido '
        '(${token.length} bytes; máximo esperado 16384). '
        'La sesión puede estar corrupta — cierra la app y vuelve a entrar.',
      );
    }
    try {
      await _writeSecure(ApiConstants.tokenKey, token);
    } catch (e) {
      // Si el write normal falla, intentar recuperación: limpiar y reintentar.
      if (kDebugMode) {
      }
      try {
        await _recoverCorruptedStorage();
        await _writeSecure(ApiConstants.tokenKey, token);
      } catch (e2) {
        throw Exception('Error al guardar token: $e2');
      }
    }
  }

  /// Limpia datos de auth del storage cuando está corrupto.
  /// Intenta limpiar SharedPreferences secure keys y keychain entries.
  static Future<void> _recoverCorruptedStorage() async {
    _useSharedPreferences = false;
    _keychainTested = false;
    // Borrar claves sensibles del keychain directamente
    for (final key in [
      ApiConstants.tokenKey,
      ApiConstants.refreshTokenKey,
      ApiConstants.userKey,
    ]) {
      try { await _storage.delete(key); } catch (_) {}
    }
    // Limpiar SharedPreferences de claves secure_
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final toRemove = prefs.getKeys()
          .where((k) => k.startsWith('secure_'))
          .toList();
      for (final k in toRemove) {
        try { await prefs.remove(k); } catch (_) {}
      }
    } catch (_) {}
    if (kDebugMode) {
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
  /// Si SharedPreferences está corrupto, resetea los flags y limpia el keychain.
  Future<void> clearAll() async {
    // Siempre resetear el flag de keychain-tested para que el próximo acceso
    // re-evalúe el estado del storage limpio.
    _keychainTested = false;

    // Intentar limpiar SharedPreferences (puede fallar si está corrupto)
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      final keys = prefs.getKeys()
          .where((key) =>
              key.startsWith('secure_') &&
              key != 'secure_$_deviceIdKey' &&
              key != 'secure_$_lastUserIdKey')
          .toList();
      for (final key in keys) {
        try { await prefs.remove(key); } catch (_) {}
      }
    } catch (e) {
      // SharedPreferences corrupto — continuar con keychain
      _useSharedPreferences = false;
      if (kDebugMode) print('⚠️ clearAll: SharedPreferences falló ($e), limpiando keychain');
    }

    // La copia protegida de la sesión también se va (cerrar sesión de
    // verdad), menos lo que identifica al equipo y al último usuario.
    for (final key in [
      ApiConstants.tokenKey,
      ApiConstants.refreshTokenKey,
      ApiConstants.userKey,
      'tenant_slug',
      'current_organization',
      _offlineCredentialsKey,
    ]) {
      await _vaultDelete(key);
    }

    // Siempre limpiar keychain también (en caso de que se use o haya datos ahí)
    try {
      final allData = await _storage.readAll();
      for (final key in allData.keys) {
        if (key != _deviceIdKey && key != _lastUserIdKey) {
          try { await _storage.delete(key); } catch (_) {}
        }
      }
    } catch (e) {
      // Si readAll falla, borrar individualmente las keys conocidas
      for (final key in [
        ApiConstants.tokenKey,
        ApiConstants.refreshTokenKey,
        ApiConstants.userKey,
        'tenant_slug',
        'current_organization',
        'offline_credentials',
      ]) {
        try { await _storage.delete(key); } catch (_) {}
      }
    }
      await _scrubPrefsHistory();
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

  /// Id de este equipo SIN tocar el almacén seguro: el que ya está en
  /// memoria, el de las preferencias del equipo o el de la copia protegida.
  /// null si no hay ninguno (no se inventa uno: un id distinto al guardado
  /// contaría como otro equipo en el servidor).
  Future<String?> peekDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final inPrefs = prefs.getString('secure_$_deviceIdKey');
      if (inPrefs != null && inPrefs.isNotEmpty) return inPrefs;
    } catch (_) {}
    final inVault = await _vaultRead(_deviceIdKey);
    return (inVault != null && inVault.isNotEmpty) ? inVault : null;
  }

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
      }
      return fingerprint;
    } catch (e) {
      // 4. Si falla el storage, usar cache o generar temporal determinístico
      if (_cachedDeviceId != null) return _cachedDeviceId!;

      // Generar un fingerprint determinístico (mismo hardware = mismo ID)
      final fallback = _generateDeviceFingerprint();
      _cachedDeviceId = fallback;
      if (kDebugMode) {
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
      // Sesión nueva: la copia protegida empieza de cero, para que no
      // quede nada del usuario o negocio anterior.
      try {
        await (await _vault())?.resetSession();
      } catch (_) {}
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
      } else {
        // El inicio de sesión no trajo el negocio: si el guardado es de
        // OTRO negocio (sesión anterior), no puede quedar junto al token
        // nuevo.
        final userOrg = userData['organizationId']?.toString();
        if (userOrg != null && userOrg.isNotEmpty) {
          try {
            final stored = await getCurrentOrganization();
            if (stored != null && stored['id']?.toString() != userOrg) {
              await deleteCurrentOrganization();
            }
          } catch (_) {
            await deleteCurrentOrganization();
          }
        }
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
      } else {
      }

      // CRÍTICO: caches que viven en SecureStorage (keychain/keystore) NO se
      // limpian con SharedPreferences. Por ejemplo `cash_register_current_cache`
      // está en SecureStorage y sobreviviría al cambio de tenant si solo
      // tocáramos SharedPreferences. Aquí los purgamos explícitamente.
      await _clearTenantSecureStorageCaches();
    } catch (e) {
    }
  }

  /// Lista de keys del SecureStorage que pertenecen al TENANT (datos de
  /// negocio) y deben borrarse al hacer logout o cambiar de tenant.
  /// Listadas explícitamente para evitar borrar accidentalmente claves
  /// de dispositivo o de auth recién creadas durante el login.
  ///
  /// **NO incluir aquí**: token, refresh_token, user_data, device_id,
  /// last_user_id, last_email, saved_emails, last_business_name,
  /// offline_credentials. Esas se manejan en otros métodos o sobreviven
  /// al cambio de tenant intencionalmente.
  static const List<String> _tenantBusinessCacheKeys = [
    'cash_register_current_cache',
    // Si hay otros caches específicos por feature, agregarlos aquí.
  ];

  /// Borra los caches del SecureStorage que pertenecen al tenant.
  /// Idempotente y silenciosa: si una key no existe, no falla.
  Future<void> _clearTenantSecureStorageCaches() async {
    int cleared = 0;
    for (final key in _tenantBusinessCacheKeys) {
      try {
        if (await containsKey(key)) {
          await _deleteSecure(key);
          cleared++;
        }
      } catch (_) {
        // No bloquear flujo por error en una key.
      }
    }
    if (cleared > 0) {
    }
  }

  /// Versión PÚBLICA para que otros componentes (ej: cambio de tenant en
  /// login) puedan disparar la limpieza sin pasar por todo `clearAuthData`.
  Future<void> clearTenantBusinessCaches() async {
    await _clearTenantSecureStorageCaches();
    // También limpiamos los de SharedPreferences para mantener consistencia.
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = <String>[];
      for (final key in prefs.getKeys()) {
        if (key.contains('inventory_warehouses_cache')) keysToRemove.add(key);
        if (key.contains('alert_products_')) keysToRemove.add(key);
        if (key.contains('_cache') && !key.startsWith('flutter.')) keysToRemove.add(key);
      }
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      if (keysToRemove.isNotEmpty) {
      }
    } catch (_) {}
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

  /// Phase 3 — Persistir nombre del negocio para mostrarlo pre-login.
  /// No es información sensible (es solo display) pero igual va al
  /// SecureStorage para reusar la API existente. Permite recordar
  /// el "negocio" del último login en este dispositivo.
  static const _lastBusinessKey = 'last_business_name';

  Future<void> saveLastBusiness(String name) async {
    try {
      await _writeSecure(_lastBusinessKey, name);
    } catch (_) {
      // No bloquear flujo por error de cache
    }
  }

  Future<String?> getLastBusiness() async {
    try {
      return await _readSecure(_lastBusinessKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLastBusiness() async {
    try {
      await _deleteSecure(_lastBusinessKey);
    } catch (_) {}
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
  /// [passwordHash] es la huella de [OfflinePasswordHasher] (nunca la contraseña).
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

  /// Verificar credenciales offline.
  /// Acepta la huella nueva (PBKDF2) y la vieja (SHA-256). Si coincide y la
  /// huella es vieja, la reemplaza por la nueva (inicio de sesión exitoso).
  Future<bool> verifyOfflineCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final savedCredentials = await getOfflineCredentials();
      if (savedCredentials == null) return false;

      final savedEmail = savedCredentials['email'] as String?;
      final savedHash = savedCredentials['passwordHash'] as String?;

      if (savedEmail == null || savedHash == null) return false;
      if (savedEmail != email.toLowerCase().trim()) return false;

      final ok = await OfflinePasswordHasher.verify(
        password: password,
        email: email,
        stored: savedHash,
      );
      if (ok && OfflinePasswordHasher.needsUpgrade(savedHash)) {
        try {
          await saveOfflineCredentials(
            email: email,
            passwordHash: await OfflinePasswordHasher.hash(password),
          );
        } catch (_) {
          // Se reintenta en el próximo inicio de sesión; la vieja sigue sirviendo.
        }
      }
      return ok;
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
      }
    }
  }
}

/// Marca de UNA decisión de almacén en Windows (ver
/// `_decideWindowsStorageInTime`).
class _WindowsDecisionRun {
  bool timedOut = false;
}
