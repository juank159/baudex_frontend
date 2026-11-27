// El almacén seguro de Windows no responde (ni lee ni escribe ni falla).
//
// Reporte (2026-11-27, Windows de un cliente que pasó de 1.0.7 a 1.0.20):
// al abrir, la app no recordó negocio ni correo, y el botón de iniciar
// sesión quedó cargando para siempre. Todo lo que lee o guarda la sesión
// espera la decisión de dónde guardarla; sin tope, una sola operación
// colgada del almacén dejaba a todas las demás esperando.
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

/// Almacén que nunca contesta.
class HungStore extends TestFlutterSecureStoragePlatform {
  HungStore() : super({});
  int calls = 0;
  Future<T> _hang<T>() {
    calls++;
    return Completer<T>().future;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) => _hang();
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) =>
      _hang();
  @override
  Future<void> delete({required String key, required Map<String, String> options}) => _hang();
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) => _hang();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    FlutterSecureStoragePlatform.instance = HungStore();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
  });

  test('con el almacén colgado, la app recuerda el negocio (como lo dejó la 1.0.7) '
      'y puede leer y guardar la sesión', () {
    fakeAsync((async) {
      // Así quedaban las preferencias en la 1.0.7: valores `secure_*` sin
      // trasladar todavía al almacén seguro.
      SharedPreferences.setMockInitialValues({
        'secure_last_business_name': 'Tienda Uno',
      });
      final service = SecureStorageService();

      String? business = 'sin respuesta';
      String? token = 'sin respuesta';
      var saved = false;
      service.getLastBusiness().then((v) => business = v);
      service.getToken().then((v) => token = v);
      async.elapse(SecureStorageService.windowsDecisionTimeout + const Duration(seconds: 1));

      expect(business, 'Tienda Uno', reason: 'se quedó esperando al almacén seguro');
      expect(token, isNull);
      expect(SessionStartupTrace.storageMode, contains('no respondió a tiempo'));

      service
          .saveAuthData(token: 'jwt.nuevo', refreshToken: 'r1', userData: {'id': 'u1', 'organizationId': 'o1'})
          .then((_) => saved = true);
      async.elapse(const Duration(seconds: 2));
      expect(saved, isTrue, reason: 'guardar la sesión se quedó esperando');

      String? again;
      service.getToken().then((v) => again = v);
      async.elapse(const Duration(seconds: 1));
      expect(again, 'jwt.nuevo');
    });
  });

  test('una operación colgada no deja esperando a las siguientes de la fila', () {
    fakeAsync((async) {
      final queue = SerialQueue();
      Object? firstError;
      String? second;
      queue.run<void>(() => Completer<void>().future).catchError((Object e) {
        firstError = e;
      });
      queue.run(() async => 'listo').then((v) => second = v);
      async.elapse(SerialQueue.operationTimeout + const Duration(seconds: 1));
      expect(firstError, isA<TimeoutException>());
      expect(second, 'listo');
    });
  });
}
