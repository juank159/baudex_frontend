// El almacén de sesión en Windows se lee del archivo UNA vez por ejecución
// y después se sirve de memoria (cada lectura real abre y descifra el
// archivo entero, y la app lee el token cientos de veces por minuto).
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_stats.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/core/storage/value_protector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProtector implements ValueProtector {
  @override
  String? protect(String plain) => 'fake:${base64Encode(utf8.encode(plain))}';
  @override
  String? unprotect(String stored) => !stored.startsWith('fake:')
      ? null
      : utf8.decode(base64Decode(stored.substring(5)));
}

/// Almacén que cuenta cada vez que se toca "el archivo".
class CountingStore extends TestFlutterSecureStoragePlatform {
  CountingStore(super.data);
  int reads = 0;
  int writes = 0;

  /// La próxima lectura falla y el archivo queda borrado (como hace el
  /// complemento cuando no puede descifrarlo).
  bool corrupt = false;

  void _maybeFail() {
    if (!corrupt) return;
    corrupt = false;
    data.clear();
    throw PlatformException(code: 'dpapi', message: 'Failure on CryptUnprotectData()');
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) {
    reads++;
    _maybeFail();
    return super.read(key: key, options: options);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) {
    reads++;
    _maybeFail();
    return super.readAll(options: options);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) {
    writes++;
    return super.write(key: key, value: value, options: options);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) {
    writes++;
    return super.delete(key: key, options: options);
  }
}

String jwt(String userId) =>
    'h.${base64Url.encode(utf8.encode(json.encode({'id': userId})))}.firma';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CountingStore store;

  SecureStorageService restart() {
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStoreStats.reset();
    store
      ..reads = 0
      ..writes = 0;
    return SecureStorageService();
  }

  Future<void> login(SecureStorageService s, String who) => s.saveAuthData(
    token: jwt('user-$who'),
    refreshToken: 'refresh-$who',
    userData: {'id': 'user-$who', 'organizationId': 'org-$who'},
    tenantSlug: 'tienda-$who',
    organization: {'id': 'org-$who', 'name': 'Negocio $who'},
  );

  /// Lo que la app lee una y otra vez mientras se usa.
  Future<void> useApp(SecureStorageService s, {int times = 60}) async {
    for (var i = 0; i < times; i++) {
      await s.getToken();
      await s.getRefreshToken();
      await s.getUserData();
      await s.getTenantSlug();
      await s.getCurrentOrganization();
      await s.getOrCreateDeviceId();
    }
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    store = CountingStore({});
    FlutterSecureStoragePlatform.instance = store;
    SecureStorageService.debugProtector = FakeProtector();
    // Un equipo en uso: sesión iniciada y traslado al almacén confirmado.
    var s = restart();
    await login(s, 'a');
    s = restart();
    await useApp(s, times: 1);
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
  });

  test('arranque normal y uso: el archivo se lee como mucho 2 veces y no se '
      'escribe', () async {
    final s = restart();
    await useApp(s);

    expect(await s.getToken(), jwt('user-a'));
    expect(store.reads, lessThanOrEqualTo(2), reason: 'comprobar el almacén + cargarlo');
    expect(store.writes, 0);
    expect(SecureStoreStats.fileReads, store.reads);
    expect(SecureStoreStats.memoryReads, greaterThanOrEqualTo(300));
  });

  test('guardar un valor igual al que ya está no toca el archivo; uno '
      'distinto sí, y se lee de memoria', () async {
    final s = restart();
    await useApp(s, times: 1);
    final reads = store.reads;

    await s.saveToken(jwt('user-a'));
    expect(store.writes, 0);

    await s.saveToken('${jwt('user-a')}-renovado');
    expect(store.writes, 1);
    expect(await s.getToken(), '${jwt('user-a')}-renovado');
    expect(store.data['auth_token'], '${jwt('user-a')}-renovado');
    expect(store.reads, reads, reason: 'sin volver a leer el archivo');
  });

  test('cerrar sesión: la memoria no conserva nada de la sesión', () async {
    final s = restart();
    await useApp(s, times: 2);

    await s.clearAuthData();

    expect(await s.getToken(), isNull);
    expect(await s.getRefreshToken(), isNull);
    expect(await s.getUserData(), isNull);
    expect(await s.getCurrentOrganization(), isNull);
    expect(store.data.containsKey('auth_token'), isFalse);
  });

  test('clearAll: tampoco, y conserva el id del equipo', () async {
    final s = restart();
    final device = await s.getOrCreateDeviceId();
    await useApp(s, times: 2);

    await s.clearAll();

    expect(await s.getToken(), isNull);
    expect(await s.getUserData(), isNull);
    expect(await s.getOrCreateDeviceId(), device);
  });

  test('negocio A y luego B: B no hereda nada de A, ni en memoria ni en el '
      'archivo', () async {
    final s = restart();
    await useApp(s, times: 2); // A en memoria

    await s.saveAuthData(
      token: jwt('user-b'),
      refreshToken: 'refresh-b',
      userData: {'id': 'user-b', 'organizationId': 'org-b'},
      tenantSlug: 'tienda-b',
    );

    expect(await s.getToken(), jwt('user-b'));
    expect((await s.getUserData())?['organizationId'], 'org-b');
    expect(await s.getTenantSlug(), 'tienda-b');
    expect(await s.getCurrentOrganization(), isNull);
    expect(store.data.values.join(), isNot(contains('org-a')));
  });

  test('archivo borrado al encender: la sesión vuelve de la copia, la '
      'memoria queda al día y el archivo se repone', () async {
    store.data.clear();
    final s = restart();

    expect(await s.getToken(), jwt('user-a'));
    expect(SessionStartupTrace.tokenSource, 'copia protegida');
    final reads = store.reads;
    await useApp(s);

    expect(await s.getToken(), jwt('user-a'));
    expect(store.data['auth_token'], jwt('user-a'));
    expect(store.reads, reads, reason: 'después de reponer, todo sale de memoria');
  });

  test('archivo dañado (la lectura falla y el complemento lo borra): entra '
      'con la copia y queda contado', () async {
    store.corrupt = true;
    final s = restart();

    expect(await s.getToken(), jwt('user-a'));
    await useApp(s, times: 5);

    expect(SecureStoreStats.failedReads, 1);
    expect(store.reads, lessThanOrEqualTo(4));
    expect(SecureStoreStats.report(), contains('no se pudo leer: 1'));
    expect(SecureStoreStats.report(), contains('restaurados de la copia protegida: '));
  });

  test('bloque del reporte de Diagnóstico', () async {
    final s = restart();
    await useApp(s, times: 10);
    final report = SecureStoreStats.report();
    // ignore: avoid_print
    print(report);
    expect(report, contains('Almacén de sesión'));
    expect(report, contains('lecturas de archivo: ${store.reads}'));
    expect(report, contains('escrituras de archivo: 0'));
  });
}
