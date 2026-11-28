// Equipo donde el almacén seguro de Windows es lento SIEMPRE (15 s por
// operación) o no contesta.
//
// Reporte (2026-11-28, 1.0.24 en un Windows de un cliente): en ese equipo
// cada arranque esperaba hasta 12 s la decisión de dónde guardar la sesión,
// y el complemento del almacén trabaja en el hilo de la ventana (mientras
// no termina, la ventana no responde). Ahora el equipo queda marcado y los
// arranques siguientes van directo a preferencias sin tocar el almacén.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/local_cache_store.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;

/// Almacén que funciona, pero tarda [delay] en cada operación.
class SlowStore extends TestFlutterSecureStoragePlatform {
  SlowStore(this.data, {this.delay = const Duration(seconds: 15)}) : super(data);
  final Map<String, String> data;
  Duration delay;
  int calls = 0;

  Future<T> _slow<T>(Future<T> Function() op) async {
    calls++;
    await Future<void>.delayed(delay);
    return op();
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) =>
      _slow(() => super.read(key: key, options: options));
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) =>
      _slow(() => super.write(key: key, value: value, options: options));
  @override
  Future<void> delete({required String key, required Map<String, String> options}) =>
      _slow(() => super.delete(key: key, options: options));
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) =>
      _slow(() => super.readAll(options: options));
}

const _user = {'id': 'u1', 'organizationId': 'o1'};

void _fakeAsync(void Function(FakeAsync async) body) => fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      body(async);
    });

/// Lo que tarda [f] en tiempo simulado (null si no terminó en [limit]).
Duration? _took<T>(FakeAsync async, Future<T> f,
    {Duration limit = const Duration(seconds: 60), void Function(T value)? onValue}) {
  final start = async.elapsed;
  Duration? took;
  f.then((v) {
    took = async.elapsed - start;
    onValue?.call(v);
  }, onError: (Object _) {
    took = async.elapsed - start;
  });
  var waited = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (took == null && waited < limit) {
    async.elapse(step);
    waited += step;
  }
  return took;
}

void _restart() {
  SecureStorageService.debugSimulateRestart();
  SessionStartupTrace.debugReset();
  SecureStorageService.debugResetQueue();
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SlowStore store;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    LocalCacheStore.debugForgetLegacyChecks();
    store = SlowStore({});
    FlutterSecureStoragePlatform.instance = store;
    // Así dejó las preferencias la 1.0.7: valores sin trasladar.
    SharedPreferences.setMockInitialValues({
      'secure_last_business_name': 'Tienda Uno',
      'secure_last_login_email': 'caja@tienda.co',
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
  });

  /// Arranque + inicio de sesión como los hace la app: leer negocio, correo
  /// y token; guardar la sesión; volver a leer el token.
  Duration? bootAndLogin(FakeAsync async, {String token = 'jwt.nuevo'}) {
    final s = SecureStorageService();
    return _took(async, () async {
      await s.getLastBusiness();
      await s.getLastEmail();
      await s.getToken();
      await s.saveAuthData(token: token, refreshToken: 'r1', userData: _user, tenantSlug: 'tienda');
      await s.saveLastBusiness('Tienda Uno');
      expect(await s.getToken(), token);
    }());
  }

  test('almacén que tarda 15 s en todo: el primer arranque espera el tope; '
      'desde el segundo, arranque + inicio de sesión en menos de 3 s y sin tocar el almacén', () {
    _fakeAsync((async) {
      final first = bootAndLogin(async);
      expect(first, isNotNull);
      expect(first!, greaterThanOrEqualTo(SecureStorageService.windowsDecisionTimeout),
          reason: 'el primer arranque todavía descubre que el almacén es lento');
      async.elapse(const Duration(seconds: 1));
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isTrue,
          reason: 'el equipo debe quedar marcado');

      for (var boot = 2; boot <= 4; boot++) {
        // Deja terminar lo que el arranque anterior dejó por detrás.
        async.elapse(const Duration(minutes: 3));
        _restart();
        final callsBefore = store.calls;
        final took = bootAndLogin(async, token: 'jwt.arranque$boot');
        expect(took, isNotNull, reason: 'arranque $boot no terminó');
        expect(took!, lessThan(const Duration(seconds: 3)), reason: 'arranque $boot tardó $took');
        expect(store.calls, callsBefore,
            reason: 'arranque $boot tocó el almacén seguro (congela la ventana)');
        expect(SessionStartupTrace.storageMode, contains('es lento'));
      }
    });
  });

  test('en el equipo marcado no se pierde negocio ni correo, y la sesión sigue tras reiniciar', () {
    _fakeAsync((async) {
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      _restart();

      final s = SecureStorageService();
      String? business, email, token;
      Map<String, dynamic>? user;
      final took = _took(async, () async {
        business = await s.getLastBusiness();
        email = await s.getLastEmail();
        token = await s.getToken();
        user = await s.getUserData();
      }());
      expect(took!, lessThan(const Duration(seconds: 1)));
      expect(business, 'Tienda Uno');
      expect(email, 'caja@tienda.co');
      expect(token, 'jwt.nuevo');
      expect(user?['id'], 'u1');
    });
  });

  test('cerrar sesión en el equipo marcado: deja la marca y la sesión vieja del almacén '
      'no revive cuando el almacén vuelve a usarse', () {
    _fakeAsync((async) {
      // El almacén guarda una sesión anterior.
      store.data[ApiConstants.tokenKey] = 'jwt.VIEJO';
      store.data[ApiConstants.userKey] = '{"id":"viejo"}';
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      _restart();

      final s = SecureStorageService();
      expect(_took(async, s.clearAuthData())!, lessThan(const Duration(seconds: 3)));
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();
      expect(prefs.getBool(SecureStorageService.storeWipePendingKey), isTrue);

      // Arranque siguiente, todavía marcado: sin sesión.
      async.elapse(const Duration(minutes: 3));
      _restart();
      String? token = 'sin respuesta';
      _took(async, SecureStorageService().getToken(), onValue: (v) => token = v);
      expect(token, isNull, reason: 'revivió una sesión cerrada');

      // El almacén se arregla y el equipo deja de estar marcado.
      async.elapse(const Duration(minutes: 3));
      store.delay = const Duration(milliseconds: 5);
      prefs.remove(SecureStorageService.storeSlowKey);
      async.elapse(const Duration(seconds: 1));
      _restart();
      token = 'sin respuesta';
      _took(async, SecureStorageService().getToken(), onValue: (v) => token = v);
      expect(token, isNull, reason: 'revivió la sesión vieja del almacén');
      expect(store.data.containsKey(ApiConstants.tokenKey), isFalse,
          reason: 'la sesión cerrada debía borrarse del almacén antes de usarlo');
    });
  });

  test('prueba por detrás: lejos del arranque, sin que nadie la espere; si el almacén sigue '
      'lento el equipo sigue marcado y se deja de probar por varios arranques', () {
    _fakeAsync((async) {
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      _restart();
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();

      final calls = store.calls;
      bootAndLogin(async, token: 'jwt.2');
      async.elapse(SecureStorageService.slowStoreProbeDelay - const Duration(seconds: 10));
      expect(store.calls, calls, reason: 'probó el almacén demasiado pronto');
      async.elapse(const Duration(minutes: 2));
      expect(store.calls, calls + 1, reason: 'una sola lectura de prueba');
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isTrue);
      final skip = prefs.getInt(SecureStorageService.storeProbeSkipKey) ?? 0;
      expect(skip, greaterThanOrEqualTo(2));

      // Los arranques siguientes no prueban (no congelan la ventana otra vez).
      for (var i = 0; i < skip; i++) {
        _restart();
        final before = store.calls;
        bootAndLogin(async, token: 'jwt.s$i');
        async.elapse(const Duration(minutes: 4));
        expect(store.calls, before, reason: 'arranque ${i + 1} tras una prueba lenta volvió a probar');
      }
    });
  });

  test('si el almacén responde rápido en 3 arranques seguidos, se vuelve a usar y recibe la '
      'sesión, el negocio y el correo de las preferencias', () {
    _fakeAsync((async) {
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();

      // El almacén se arregla (se fue el antivirus, se reparó Windows…).
      store.delay = const Duration(milliseconds: 5);
      for (var boot = 1; boot <= SecureStorageService.slowStoreHealthyBoots; boot++) {
        _restart();
        final took = bootAndLogin(async, token: 'jwt.sano$boot');
        expect(took!, lessThan(const Duration(seconds: 3)));
        expect(prefs.getBool(SecureStorageService.storeSlowKey), isTrue,
            reason: 'con ${boot - 1} arranques sanos todavía no se vuelve');
        async.elapse(const Duration(minutes: 3));
      }
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isNull,
          reason: 'tras 3 arranques sanos el equipo deja de estar marcado');

      // Arranque siguiente: decide como siempre y traslada desde preferencias.
      _restart();
      String? token, business;
      final s = SecureStorageService();
      _took(async, () async {
        token = await s.getToken();
        business = await s.getLastBusiness();
      }());
      expect(token, 'jwt.sano3');
      expect(business, 'Tienda Uno');
      expect(SessionStartupTrace.storageMode, contains('almacén seguro de Windows'));
      expect(store.data[ApiConstants.tokenKey], 'jwt.sano3');
      expect(store.data['last_business_name'], 'Tienda Uno');
    });
  });

  test('un arranque lento entre los sanos reinicia la cuenta', () {
    _fakeAsync((async) {
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();

      store.delay = const Duration(milliseconds: 5);
      _restart();
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      expect(prefs.getInt(SecureStorageService.storeHealthyBootsKey), 1);

      store.delay = const Duration(seconds: 15);
      _restart();
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      expect(prefs.getInt(SecureStorageService.storeHealthyBootsKey), 0);
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isTrue);
    });
  });

  test('las cachés no van a buscar al almacén lento (congelaría la ventana al abrir una pantalla)', () {
    _fakeAsync((async) {
      bootAndLogin(async);
      async.elapse(const Duration(minutes: 3));
      _restart();
      LocalCacheStore.debugForgetLegacyChecks();
      final calls = store.calls;
      String? value = 'sin respuesta';
      final took = _took(
        async,
        LocalCacheStore(prefix: 'inventory_cache_').read(key: 'inventory_out_of_stock_all'),
        onValue: (v) => value = v,
      );
      expect(took!, lessThan(const Duration(milliseconds: 500)));
      expect(value, isNull);
      expect(store.calls, calls);
    });
  });

  test('equipo sano: nada cambia (no queda marcado y usa el almacén)', () {
    _fakeAsync((async) {
      store.delay = const Duration(milliseconds: 5);
      final took = bootAndLogin(async);
      expect(took!, lessThan(const Duration(seconds: 3)));
      async.elapse(const Duration(minutes: 3));
      late SharedPreferences prefs;
      _prefs().then((p) => prefs = p);
      async.flushMicrotasks();
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isNull);
      expect(SessionStartupTrace.storageMode, contains('almacén seguro de Windows'));
      expect(store.data[ApiConstants.tokenKey], 'jwt.nuevo');
    });
  });
}
