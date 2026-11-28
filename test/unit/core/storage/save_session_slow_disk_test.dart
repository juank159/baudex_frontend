// Disco lento: cada guardado en preferencias reescribe el archivo entero y
// espera al disco. Guardar la sesión al iniciar hacía ~11 guardados seguidos
// (copia protegida + preferencias, clave por clave): con 1 s por guardado,
// 11 s con el botón de iniciar sesión cargando.
// ignore_for_file: depend_on_referenced_packages
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;

/// Preferencias en un disco lento: cada guardado tarda [delay]. Como el
/// almacén real de Windows, el valor queda en memoria al pedirlo y los
/// guardados pedidos mientras hay una escritura en curso salen juntos en
/// la siguiente.
class SlowDiskPrefs extends SharedPreferencesStorePlatform {
  SlowDiskPrefs(this.values, {this.delay = const Duration(seconds: 1)});
  final Map<String, Object> values;
  final Duration delay;
  int diskWrites = 0;
  Future<bool>? _writer;
  bool _dirty = false;

  Future<bool> _persist() {
    _dirty = true;
    return _writer ??= () async {
      try {
        await Future<void>.delayed(Duration.zero);
        while (_dirty) {
          _dirty = false;
          diskWrites++;
          await Future<void>.delayed(delay);
        }
      } finally {
        _writer = null;
      }
      return true;
    }();
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return _persist();
  }

  @override
  Future<Map<String, Object>> getAll() async => Map.of(values);

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async =>
      Map.of(values)..removeWhere((k, _) => !k.startsWith(parameters.filter.prefix));

  @override
  Future<bool> remove(String key) {
    if (values.remove(key) == null) return Future.value(true);
    return _persist();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (values[key] == value) return Future.value(true);
    values[key] = value;
    return _persist();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SlowDiskPrefs disk;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    // Equipo marcado: la sesión vive en preferencias.
    disk = SlowDiskPrefs({'flutter.${SecureStorageService.storeSlowKey}': true});
    SharedPreferencesStorePlatform.instance = disk;
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.resetStatic();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.resetStatic();
  });

  test('guardar la sesión con 1 s por escritura de disco: pocas escrituras y todo queda guardado', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      final s = SecureStorageService();
      // Arranque: decide el modo (sin escribir).
      String? token = 'x';
      s.getToken().then((v) => token = v);
      async.elapse(const Duration(seconds: 1));
      expect(token, isNull);
      final before = disk.diskWrites;

      Duration? took;
      final start = async.elapsed;
      s
          .saveAuthData(
            token: 'jwt.nuevo',
            refreshToken: 'r1',
            userData: {'id': 'u1', 'organizationId': 'o1'},
            tenantSlug: 'tienda',
            organization: {'id': 'o1', 'name': 'Tienda'},
          )
          .then((_) => took = async.elapsed - start);
      async.elapse(const Duration(seconds: 30));

      expect(took, isNotNull, reason: 'no terminó');
      // Antes: 11 escrituras seguidas (11 s). Ahora: copia protegida al
      // empezar, la sesión en una, el token y el resto junto.
      expect(disk.diskWrites - before, lessThanOrEqualTo(5));
      expect(took!, lessThanOrEqualTo(const Duration(seconds: 5)), reason: 'tardó $took');

      String? savedToken, refresh, tenant;
      Map<String, dynamic>? user, org;
      () async {
        savedToken = await s.getToken();
        refresh = await s.getRefreshToken();
        user = await s.getUserData();
        tenant = await s.getTenantSlug();
        org = await s.getCurrentOrganization();
      }();
      async.elapse(const Duration(seconds: 1));
      expect(savedToken, 'jwt.nuevo');
      expect(refresh, 'r1');
      expect(user?['id'], 'u1');
      expect(tenant, 'tienda');
      expect(org?['name'], 'Tienda');

      // Y sobrevive a reiniciar (lo que quedó en "disco").
      SecureStorageService.debugSimulateRestart();
      SecureStorageService.debugResetQueue();
      String? afterRestart;
      Map<String, dynamic>? orgAfter;
      () async {
        afterRestart = await SecureStorageService().getToken();
        orgAfter = await SecureStorageService().getCurrentOrganization();
      }();
      async.elapse(const Duration(seconds: 1));
      expect(afterRestart, 'jwt.nuevo');
      expect(orgAfter?['id'], 'o1');
    });
  });
}
