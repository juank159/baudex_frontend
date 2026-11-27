// QA (2026-11-27): el traslado al almacén seguro sigue corriendo después del
// tope de 12 s. Si termina tarde, ¿pisa lo que la app guardó mientras tanto?
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;

/// Almacén cuya PRIMERA operación nunca contesta y las demás tardan [slow].
class FirstHangsThenSlow extends TestFlutterSecureStoragePlatform {
  FirstHangsThenSlow(this.slow) : super({});
  final Duration slow;
  int calls = 0;
  Future<T> _go<T>(T Function() f) {
    calls++;
    if (calls == 1) return Completer<T>().future;
    return Future<T>.delayed(slow, f);
  }

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

  for (final flags in [
    {'baudex_secure_store_migrated_v1': true},
    {'baudex_secure_store_copied_v1': true},
  ]) {
    test('traslado que termina tarde (${flags.keys.first}): lo guardado en '
        'preferencias tras el tope sigue ahí', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({...flags});
        FlutterSecureStoragePlatform.instance =
            FirstHangsThenSlow(const Duration(seconds: 4));
        final service = SecureStorageService();

        String? first = 'x';
        service.getToken().then((v) => first = v);
        async.elapse(const Duration(seconds: 12, milliseconds: 100));
        expect(SessionStartupTrace.storageMode, contains('no respondió a tiempo'));
        expect(first, isNull);

        // El usuario entra justo después del tope.
        var saved = false;
        service
            .saveAuthData(token: 'jwt.nuevo', refreshToken: 'r1', userData: {'id': 'u1', 'organizationId': 'o1'})
            .then((_) => saved = true);
        service.saveLastBusiness('Tienda Uno');
        async.elapse(const Duration(seconds: 1));
        expect(saved, isTrue);

        // Termina el segundo intento del traslado (10 s + 4 s ≈ 14 s).
        async.elapse(const Duration(seconds: 30));

        String? business = 'x';
        String? token = 'x';
        service.getLastBusiness().then((v) => business = v);
        service.getToken().then((v) => token = v);
        async.elapse(const Duration(seconds: 1));
        // ignore: avoid_print
        print('misma ejecución -> token=$token negocio=$business');

        // Reabrir la app con el almacén ya sano.
        SecureStorageService.debugSimulateRestart();
        final healthy = TestFlutterSecureStoragePlatform(
            (FlutterSecureStoragePlatform.instance as FirstHangsThenSlow).data);
        FlutterSecureStoragePlatform.instance = healthy;
        String? token2 = 'x';
        String? business2 = 'x';
        SecureStorageService().getToken().then((v) => token2 = v);
        SecureStorageService().getLastBusiness().then((v) => business2 = v);
        async.elapse(const Duration(seconds: 30));
        // ignore: avoid_print
        print('al reabrir -> token=$token2 negocio=$business2');

        expect(token, 'jwt.nuevo');
        expect(business, 'Tienda Uno');
        expect(token2, 'jwt.nuevo');
        expect(business2, 'Tienda Uno');
      });
    });
  }

  test('operación lenta (11 s) cortada por la fila: ¿la siguiente corre '
      'mientras la primera sigue escribiendo?', () {
    fakeAsync((async) {
      final queue = SerialQueue();
      var running = 0;
      var maxRunning = 0;
      Future<void> op() async {
        running++;
        if (running > maxRunning) maxRunning = running;
        await Future<void>.delayed(const Duration(seconds: 11));
        running--;
      }

      queue.run(op).catchError((_) {});
      queue.run(op).catchError((_) {});
      async.elapse(const Duration(seconds: 30));
      // ignore: avoid_print
      print('operaciones a la vez en el almacén: $maxRunning');
      expect(maxRunning, 1, reason: 'la fila ya no serializa operaciones lentas');
    });
  });
}
