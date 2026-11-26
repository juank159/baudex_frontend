import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacén seguro en memoria (nunca el llavero ni el archivo DPAPI reales).
class MemoryStore implements SecureKeyValueStore {
  final Map<String, String> data = {};
  bool failProbe = false;
  String? failWriteOn;
  String? corruptReadOn;

  /// El archivo del almacén está dañado: la primera operación falla (el
  /// complemento lo borra) y las siguientes ya funcionan, vacías.
  bool corruptFile = false;
  int writes = 0;

  void _corruptCheck() {
    if (!corruptFile) return;
    corruptFile = false;
    data.clear();
    throw Exception('Failure on CryptUnprotectData()');
  }

  @override
  Future<String?> read(String key) async {
    _corruptCheck();
    if (failProbe && key.contains('probe')) throw Exception('DPAPI no disponible');
    if (key == corruptReadOn) return 'otra cosa';
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _corruptCheck();
    writes++;
    if (failProbe && key.contains('probe')) throw Exception('DPAPI no disponible');
    if (key == failWriteOn) throw Exception('disco lleno');
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late MemoryStore store;
  late List<Map<String, dynamic>> problems;

  // Lo que hoy guarda Windows en preferencias ("enc:" = cifrado casero).
  const legacyPrefs = <String, Object>{
    'secure_auth_token': 'enc:TOKEN',
    'secure_refresh_token': 'enc:REFRESH',
    'secure_user_data': 'enc:{"id":"u1"}',
    'secure_offline_credentials': 'enc:{"email":"a@b.co"}',
    'secure_last_user_id': 'u1',
    'secure_device_id': 'dev-1',
    'theme': 'light', // no es del almacén: no se toca
  };

  String? decode(String key, String stored) {
    if (stored == 'enc:ROTO') return null; // de otro equipo
    return stored.startsWith('enc:') ? stored.substring(4) : stored;
  }

  Future<PrefsToSecureStoreMigration> migration() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsToSecureStoreMigration(
      prefs: prefs,
      store: store,
      decode: decode,
      onProblem: (e, st, ctx) => problems.add({...ctx, 'error': '$e'}),
    );
  }

  setUp(() {
    store = MemoryStore();
    problems = [];
  });

  test('caso normal, arranque 1: copia descifrado y verifica, pero conserva preferencias', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.copied);
    expect(outcome.usePrefs, isFalse);
    expect(outcome.mirrorToPrefs, isTrue);
    expect(store.data, {
      'auth_token': 'TOKEN',
      'refresh_token': 'REFRESH',
      'user_data': '{"id":"u1"}',
      'offline_credentials': '{"email":"a@b.co"}',
      'last_user_id': 'u1',
      'device_id': 'dev-1',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_auth_token'), 'enc:TOKEN', reason: 'respaldo hasta confirmar');
    expect(prefs.getBool(PrefsToSecureStoreMigration.copiedFlag), isTrue);
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isNot(true));
    expect(problems, isEmpty);
  });

  test('caso normal, arranque 2: el almacén lee bien y se borra de preferencias', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    await (await migration()).run();
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.confirmed);
    expect(outcome.mirrorToPrefs, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('secure_')), isEmpty);
    expect(prefs.getString('theme'), 'light');
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isTrue);
    expect(prefs.getBool(PrefsToSecureStoreMigration.copiedFlag), isFalse);
    expect(store.data['auth_token'], 'TOKEN');
    // Arranque 3: ya migrado.
    expect(await (await migration()).run(), SecureMigrationOutcome.alreadyMigrated);
  });

  test('DPAPI falla en el arranque 2: vuelve a preferencias sin perder la sesión', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    await (await migration()).run(); // copiado
    // Durante el arranque 1 la app renovó el token: se guardó en ambos lados.
    store.data['auth_token'] = 'TOKEN_RENOVADO';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secure_auth_token', 'enc:TOKEN_RENOVADO');

    store.failProbe = true;
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.storeUnavailable);
    expect(outcome.usePrefs, isTrue);
    expect(prefs.getString('secure_auth_token'), 'enc:TOKEN_RENOVADO',
        reason: 'la sesión vigente sigue en preferencias');
    expect(prefs.getString('secure_offline_credentials'), 'enc:{"email":"a@b.co"}');
    expect(prefs.getBool(PrefsToSecureStoreMigration.copiedFlag), isFalse);
    expect(problems.single['step'], 'probe');

    // Vuelve DPAPI: se copia otra vez desde preferencias, ya al día.
    store.failProbe = false;
    store.data.clear();
    expect(await (await migration()).run(), SecureMigrationOutcome.copied);
    expect(store.data['auth_token'], 'TOKEN_RENOVADO');
  });

  test('arranque 2 con una clave que falta en el almacén: se repone desde preferencias', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    await (await migration()).run();
    store.data.remove('offline_credentials');
    expect(await (await migration()).run(), SecureMigrationOutcome.confirmed);
    expect(store.data['offline_credentials'], '{"email":"a@b.co"}');
  });

  test('arranque 2 con el almacén que falla al leer: no se borra nada', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    await (await migration()).run();
    store.data.remove('user_data');
    store.failWriteOn = 'user_data';
    expect(await (await migration()).run(), SecureMigrationOutcome.failed);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_user_data'), 'enc:{"id":"u1"}');
    expect(problems.single['step'], 'confirm');
  });

  test('almacén que no funciona: preferencias intactas, se sigue con ellas y se reporta', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    store.failProbe = true;
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.storeUnavailable);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_auth_token'), 'enc:TOKEN');
    expect(store.data, isEmpty);
    expect(problems.single['step'], 'probe');
  });

  test('falla a mitad de escribir: no se borra nada de preferencias', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    store.failWriteOn = 'user_data';
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.failed);
    final prefs = await SharedPreferences.getInstance();
    for (final k in legacyPrefs.keys) {
      expect(prefs.get(k), legacyPrefs[k], reason: k);
    }
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isNull);
    expect(problems.single['step'], 'write');
  });

  test('lo leído de vuelta no coincide: no se borra nada de preferencias', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    store.corruptReadOn = 'auth_token';
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.failed);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_auth_token'), 'enc:TOKEN');
    expect(problems.single['step'], 'verify');
  });

  test('después de un fallo, el siguiente arranque sí traslada', () async {
    SharedPreferences.setMockInitialValues(Map.of(legacyPrefs));
    store.failWriteOn = 'user_data';
    await (await migration()).run();
    store.failWriteOn = null;
    expect(await (await migration()).run(), SecureMigrationOutcome.copied);
    expect(store.data['user_data'], '{"id":"u1"}');
  });

  test('ya trasladado: no copia restos viejos encima de valores nuevos; los borra', () async {
    SharedPreferences.setMockInitialValues({
      PrefsToSecureStoreMigration.doneFlag: true,
      'secure_auth_token': 'enc:TOKEN_VIEJO', // resto de un borrado que falló
    });
    store.data['auth_token'] = 'TOKEN_NUEVO';
    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.alreadyMigrated);
    expect(store.data['auth_token'], 'TOKEN_NUEVO');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_auth_token'), isNull);
  });

  test('ya trasladado pero el almacén falla luego: se marca para trasladar otra vez', () async {
    SharedPreferences.setMockInitialValues({PrefsToSecureStoreMigration.doneFlag: true});
    store.failProbe = true;
    expect(await (await migration()).run(), SecureMigrationOutcome.storeUnavailable);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isFalse);

    // La app escribió en preferencias mientras tanto; al volver el almacén se traslada.
    await prefs.setString('secure_auth_token', 'enc:TOKEN_FALLBACK');
    store.failProbe = false;
    expect(await (await migration()).run(), SecureMigrationOutcome.copied);
    expect(store.data['auth_token'], 'TOKEN_FALLBACK');
  });

  test('valor que no se puede descifrar (de otro equipo) no frena el traslado', () async {
    SharedPreferences.setMockInitialValues({
      'secure_auth_token': 'enc:ROTO',
      'secure_device_id': 'dev-1',
    });
    expect(await (await migration()).run(), SecureMigrationOutcome.copied);
    expect(store.data, {'device_id': 'dev-1'});
  });

  test('SerialQueue: las operaciones no se cruzan', () async {
    final q = SerialQueue();
    final order = <String>[];
    Future<void> op(String name, int ms) => q.run(() async {
          order.add('$name-inicio');
          await Future<void>.delayed(Duration(milliseconds: ms));
          order.add('$name-fin');
        });
    await Future.wait([op('a', 20), op('b', 1), op('c', 5)]);
    expect(order, ['a-inicio', 'a-fin', 'b-inicio', 'b-fin', 'c-inicio', 'c-fin']);
  });

  test('SerialQueue: un error no bloquea la fila', () async {
    final q = SerialQueue();
    await expectLater(q.run(() async => throw Exception('x')), throwsException);
    expect(await q.run(() async => 42), 42);
  });

  test('con el traslado confirmado la prueba del almacén no escribe nada '
      '(no se reescribe el archivo de la sesión en cada arranque)', () async {
    SharedPreferences.setMockInitialValues({
      PrefsToSecureStoreMigration.doneFlag: true,
    });
    store.data['auth_token'] = 'jwt';
    store.writes = 0;

    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.alreadyMigrated);
    expect(store.writes, 0);
    expect(store.data, {'auth_token': 'jwt'});
  });

  test('archivo del almacén dañado: falla una vez, el complemento lo borra y '
      'el segundo intento ya funciona (se sigue con el almacén, y se reporta)', () async {
    SharedPreferences.setMockInitialValues({
      PrefsToSecureStoreMigration.doneFlag: true,
    });
    store.data['auth_token'] = 'jwt';
    store.corruptFile = true;

    final outcome = await (await migration()).run();

    expect(outcome, SecureMigrationOutcome.alreadyMigrated);
    expect(store.data, isEmpty, reason: 'lo guardado se perdió con el archivo');
    expect(problems.single['step'], 'probe-recovered');
  });
}
