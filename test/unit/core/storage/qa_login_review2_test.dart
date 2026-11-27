// QA segunda revisión (2026-11-27) del commit ebb781f: casos que el arreglo
// no tenía cubiertos. Cada caso arranca con la fila del almacén nueva
// (`debugResetQueue`): un caso colgado ya no contamina al siguiente.
// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:async';

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_late_migration_race_test.dart' show FirstHangsThenSlow;
import 'secure_storage_lost_key_test.dart' show FakeProtector;

/// Cada operación tarda [delay].
class SlowStore extends TestFlutterSecureStoragePlatform {
  SlowStore(this.delay, Map<String, String> data) : super(data);
  final Duration delay;
  Future<T> _go<T>(T Function() f) => Future<T>.delayed(delay, f);
  @override
  Future<String?> read({required String key, required Map<String, String> options}) =>
      _go(() => data[key]);
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) =>
      _go(() => data[key] = value);
  @override
  Future<void> delete({required String key, required Map<String, String> options}) =>
      _go(() => data.remove(key));
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) =>
      _go(() => Map.of(data));
}

/// Siempre falla (el caso "almacén roto" que ya existía en eb52756).
class ThrowingStore extends TestFlutterSecureStoragePlatform {
  ThrowingStore(Map<String, String> data) : super(data);
  @override
  Future<String?> read({required String key, required Map<String, String> options}) =>
      Future.error(StateError('roto'));
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) =>
      Future.error(StateError('roto'));
  @override
  Future<void> delete({required String key, required Map<String, String> options}) =>
      Future.error(StateError('roto'));
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) =>
      Future.error(StateError('roto'));
}

T? _get<T>(FakeAsync async, Future<T> f, {Duration wait = const Duration(seconds: 90)}) {
  T? out;
  var done = false;
  f.then((v) {
    out = v;
    done = true;
  }, onError: (Object e) {
    print('error: $e');
    done = true;
  });
  async.elapse(wait);
  expect(done, isTrue, reason: 'no terminó');
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
  });

  // Riesgo (d): sesión vieja en el almacén + arranque lento + login + cerrar
  // sesión + reabrir con el almacén sano.
  for (final kind in ['lento', 'roto']) {
    test('d) token viejo revive tras cerrar sesión (almacén $kind)', () {
      fakeAsync((async) {
        SecureStorageService.debugResetQueue(); // fila nueva dentro del tiempo simulado
        SharedPreferences.setMockInitialValues({'baudex_secure_store_migrated_v1': true});
        final data = <String, String>{
          ApiConstants.tokenKey: 'jwt.VIEJO',
          ApiConstants.refreshTokenKey: 'r.VIEJO',
        };
        FlutterSecureStoragePlatform.instance = kind == 'lento'
            ? (FirstHangsThenSlow(const Duration(seconds: 4))..data.addAll(data))
            : ThrowingStore(data);
        final s = SecureStorageService();
        final t0 = _get(async, s.getToken(), wait: const Duration(seconds: 13));
        print('arranque 1 ($kind): token=$t0 modo=${SessionStartupTrace.storageMode}');

        _get(async, s.saveAuthData(token: 'jwt.NUEVO', refreshToken: 'r1', userData: {'id': 'u1', 'organizationId': 'o1'}),
            wait: const Duration(seconds: 2));
        _get(async, s.saveLastBusiness('Tienda'), wait: const Duration(seconds: 1));
        _get(async, s.clearAuthData(), wait: const Duration(seconds: 5));
        final afterLogout = _get(async, s.getToken(), wait: const Duration(seconds: 1));
        print('tras cerrar sesión misma ejecución: token=$afterLogout');
        async.elapse(const Duration(seconds: 120)); // termina el traslado tardío

        // Reabrir con el almacén sano.
        SecureStorageService.debugSimulateRestart();
        FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
            (FlutterSecureStoragePlatform.instance as TestFlutterSecureStoragePlatform).data);
        final s2 = SecureStorageService();
        final t2 = _get(async, s2.getToken());
        final b2 = _get(async, s2.getLastBusiness());
        print('reabrir 1 ($kind): token=$t2 negocio=$b2 modo=${SessionStartupTrace.storageMode}');
        SecureStorageService.debugSimulateRestart();
        final t3 = _get(async, SecureStorageService().getToken());
        print('reabrir 2 ($kind): token=$t3');
        expect(afterLogout, isNull);
        expect(t2, isNull, reason: 'la sesión cerrada revivió al reabrir');
        expect(t3, isNull, reason: 'la sesión cerrada revivió al reabrir (2)');
      });
    });
  }

  // a) almacén que contesta a los N s en cada operación.
  for (final secs in [11, 13, 59, 61]) {
    test('a) almacén que tarda ${secs}s por operación', () {
      fakeAsync((async) {
        SecureStorageService.debugResetQueue(); // fila nueva dentro del tiempo simulado
        SharedPreferences.setMockInitialValues({
          'baudex_secure_store_migrated_v1': true,
        });
        final data = <String, String>{'last_business_name': 'Tienda'};
        FlutterSecureStoragePlatform.instance = SlowStore(Duration(seconds: secs), data);
        final s = SecureStorageService();
        final sw = Stopwatch();
        final t0 = _get(async, s.getToken(), wait: const Duration(seconds: 13));
        final b0 = _get(async, s.getLastBusiness(), wait: const Duration(seconds: 1));
        print('${secs}s arranque: token=$t0 negocio=$b0 modo=${SessionStartupTrace.storageMode}');
        sw.start();
        var saved = false;
        s.saveAuthData(token: 'jwt.N', refreshToken: 'r', userData: {'id': 'u', 'organizationId': 'o'})
            .then((_) => saved = true, onError: (e) => print('save error $e'));
        async.elapse(const Duration(seconds: 20));
        print('${secs}s guardado en 20 s: $saved');
        expect(saved, isTrue);
        async.elapse(const Duration(seconds: 300));
        SecureStorageService.debugSimulateRestart();
        FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
        final t2 = _get(async, SecureStorageService().getToken());
        print('${secs}s reabrir sano: token=$t2 datos almacén=${data.keys.toList()}');
        expect(t2, 'jwt.N');
      });
    });
  }

  // a) dos arranques lentos seguidos, luego sano dos veces.
  test('a) dos arranques lentos seguidos y luego sano', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue(); // fila nueva dentro del tiempo simulado
      SharedPreferences.setMockInitialValues({'baudex_secure_store_copied_v1': true});
      var data = <String, String>{};
      FlutterSecureStoragePlatform.instance = FirstHangsThenSlow(const Duration(seconds: 4));
      var s = SecureStorageService();
      _get(async, s.getToken(), wait: const Duration(seconds: 13));
      _get(async, s.saveAuthData(token: 'jwt.A', refreshToken: 'r', userData: {'id': 'u', 'organizationId': 'o'}),
          wait: const Duration(seconds: 2));
      _get(async, s.saveLastBusiness('Tienda A'), wait: const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 120));
      data = (FlutterSecureStoragePlatform.instance as TestFlutterSecureStoragePlatform).data;

      SecureStorageService.debugSimulateRestart();
      FlutterSecureStoragePlatform.instance = FirstHangsThenSlow(const Duration(seconds: 4))..data.addAll(data);
      s = SecureStorageService();
      final tb = _get(async, s.getToken(), wait: const Duration(seconds: 13));
      final bb = _get(async, s.getLastBusiness(), wait: const Duration(seconds: 1));
      print('2º lento: token=$tb negocio=$bb');
      async.elapse(const Duration(seconds: 120));
      data = (FlutterSecureStoragePlatform.instance as TestFlutterSecureStoragePlatform).data;

      for (var i = 0; i < 3; i++) {
        SecureStorageService.debugSimulateRestart();
        FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
        final t = _get(async, SecureStorageService().getToken());
        final b = _get(async, SecureStorageService().getLastBusiness());
        print('sano $i: token=$t negocio=$b modo=${SessionStartupTrace.storageMode}');
        expect(t, 'jwt.A');
        expect(b, 'Tienda A');
      }
      expect(tb, 'jwt.A');
      expect(bb, 'Tienda A');
    });
  });

  // b) equipo normal.
  test('b) equipo normal: login, cerrar sesión, reabrir', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue(); // fila nueva dentro del tiempo simulado
      SharedPreferences.setMockInitialValues({});
      final data = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
      final s = SecureStorageService();
      _get(async, s.saveAuthData(token: 'jwt.X', refreshToken: 'r', userData: {'id': 'u', 'organizationId': 'o'}),
          wait: const Duration(seconds: 1));
      _get(async, s.saveLastBusiness('Tienda'), wait: const Duration(seconds: 1));
      _get(async, s.saveLastEmail('a@b.co'), wait: const Duration(seconds: 1));
      expect(_get(async, s.getToken(), wait: const Duration(seconds: 1)), 'jwt.X');
      for (var i = 0; i < 2; i++) {
        SecureStorageService.debugSimulateRestart();
        expect(_get(async, SecureStorageService().getToken(), wait: const Duration(seconds: 1)), 'jwt.X');
      }
      _get(async, SecureStorageService().clearAuthData(), wait: const Duration(seconds: 1));
      for (var i = 0; i < 2; i++) {
        SecureStorageService.debugSimulateRestart();
        final x = SecureStorageService();
        final t = _get(async, x.getToken(), wait: const Duration(seconds: 1));
        final b = _get(async, x.getLastBusiness(), wait: const Duration(seconds: 1));
        final e = _get(async, x.getLastEmail(), wait: const Duration(seconds: 1));
        print('normal reabrir $i: token=$t negocio=$b correo=$e modo=${SessionStartupTrace.storageMode}');
        expect(t, isNull);
        expect(b, 'Tienda');
        expect(e, 'a@b.co');
      }
    });
  });

  test('a) fila: el que pide DETRÁS de una operación colgada espera hasta 60 s, no 10 s', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue(); // fila nueva dentro del tiempo simulado
      final queue = SerialQueue();
      queue.run(() => Completer<void>().future).catchError((_) {});
      Duration? answered;
      final sw = Stopwatch()..start();
      final start = async.elapsed;
      queue.run(() async => 'memoria').then((_) => answered = async.elapsed - start,
          onError: (_) => answered = async.elapsed - start);
      async.elapse(const Duration(seconds: 15));
      print('a los 15 s respondido: $answered');
      async.elapse(const Duration(seconds: 60));
      print('respondido a los: $answered');
      expect(answered, isNotNull);
      expect(answered! >= const Duration(seconds: 60), isTrue);
    });
  });
}
