// Equipo marcado "almacén lento": la lectura de prueba de los 90 s corre en
// el hilo de la ventana y, si el almacén sigue lento, la congela. Solo debe
// correr con la app ociosa (sin vender, sin diálogo de pago, 30 s sin
// teclado ni ratón); si no es momento, se pospone.
// ignore_for_file: depend_on_referenced_packages
import 'package:baudex_desktop/app/core/navigation/route_stack_observer.dart';
import 'package:baudex_desktop/app/core/session/app_idle.dart';
import 'package:baudex_desktop/app/core/storage/local_cache_store.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;
import 'secure_storage_slow_device_test.dart' show SlowStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('regla de app ociosa', () {
    test('30 s sin teclado ni ratón, sin vender y sin diálogo: ociosa', () {
      expect(
          AppIdle.isIdle(
              idleFor: const Duration(seconds: 31), sellingVisible: false, dialogOpen: false),
          isTrue);
    });
    test('actividad reciente, venta en pantalla o diálogo abierto: no', () {
      expect(
          AppIdle.isIdle(
              idleFor: const Duration(seconds: 10), sellingVisible: false, dialogOpen: false),
          isFalse);
      expect(
          AppIdle.isIdle(idleFor: const Duration(hours: 1), sellingVisible: true, dialogOpen: false),
          isFalse);
      expect(
          AppIdle.isIdle(idleFor: const Duration(hours: 1), sellingVisible: false, dialogOpen: true),
          isFalse);
    });
    test('un diálogo abierto se nota hasta que se cierra', () {
      final observer = RouteStackObserver.instance..reset();
      final dialog = RawDialogRoute<void>(pageBuilder: (_, __, ___) => const SizedBox());
      observer.didPush(dialog, null);
      expect(observer.hasOpenPopup, isTrue);
      observer.didPop(dialog, null);
      expect(observer.hasOpenPopup, isFalse);
    });
  });

  group('prueba del almacén en equipo marcado lento', () {
    late SlowStore store;
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      SecureStorageService.debugSimulateRestart();
      SessionStartupTrace.debugReset();
      SecureStorageService.debugProtector = FakeProtector();
      LocalCacheStore.debugForgetLegacyChecks();
      store = SlowStore({}, delay: const Duration(milliseconds: 5));
      FlutterSecureStoragePlatform.instance = store;
      SharedPreferences.setMockInitialValues({SecureStorageService.storeSlowKey: true});
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      SecureStorageService.debugProtector = null;
      SecureStorageService.slowStoreProbeMayRun = () => true;
      SecureStorageService.debugSimulateRestart();
    });

    test('en plena venta no lee el almacén; lo hace cuando la app queda ociosa', () {
      fakeAsync((async) {
        SecureStorageService.debugResetQueue();
        var idle = false;
        SecureStorageService.slowStoreProbeMayRun = () => idle;
        SecureStorageService().getToken();
        async.elapse(const Duration(seconds: 5));
        final calls = store.calls;

        // Pasan los 90 s y varios minutos más vendiendo: no se toca.
        async.elapse(SecureStorageService.slowStoreProbeDelay + const Duration(minutes: 5));
        expect(store.calls, calls, reason: 'leyó el almacén con la app ocupada');

        // La app queda ociosa: la prueba corre en el siguiente intento.
        idle = true;
        async.elapse(SecureStorageService.slowStoreProbeRetry + const Duration(seconds: 1));
        expect(store.calls, calls + 1, reason: 'no probó al quedar ociosa');
        late SharedPreferences prefs;
        SharedPreferences.getInstance().then((p) => prefs = p);
        async.flushMicrotasks();
        expect(prefs.getInt(SecureStorageService.storeHealthyBootsKey), 1);
      });
    });
  });
}
