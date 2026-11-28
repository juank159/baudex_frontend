// La marca de "almacén seguro lento" caduca: un equipo SANO que tuvo UNA
// demora pasajera vuelve al almacén seguro y a sus caminos de recuperación.
//
// Batería de Windows real (probar-arranque, 2026-11-28, 1.0.25): el paso
// "04g EQUIPO MUY LENTO (1 núcleo)" hizo que el almacén no respondiera a
// tiempo UNA vez y el equipo quedó marcado. La marca solo se quitaba con la
// app abierta y ociosa más de 90 s en tres arranques; con arranques cortos
// no se quitó nunca: 28 arranques seguidos con la sesión en preferencias
// (sin la protección del almacén) y los pasos 16, 17a, 18, 20, 21 y 24 (que
// dañan el archivo del almacén) fallaron: la app ya no lo usaba ni lo
// volvía a crear.
//
// En Mac el archivo dañado se simula como lo deja el complemento de
// Windows: lo borra y todo lee null (en ceros, cortado y borrado terminan
// igual para la app).
// ignore_for_file: depend_on_referenced_packages

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/local_cache_store.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;
import 'secure_storage_slow_device_test.dart' show SlowStore;

const _fast = Duration(milliseconds: 5);
const _userA = {'id': 'ua', 'organizationId': 'negocio-a'};
const _userB = {'id': 'ub', 'organizationId': 'negocio-b'};

T _wait<T>(FakeAsync async, Future<T> f, {Duration limit = const Duration(seconds: 60)}) {
  T? value;
  var done = false;
  Object? error;
  f.then((v) {
    value = v;
    done = true;
  }, onError: (Object e) {
    error = e;
    done = true;
  });
  var waited = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (!done && waited < limit) {
    async.elapse(step);
    waited += step;
  }
  if (!done) fail('no terminó en $limit');
  if (error != null) fail('falló: $error');
  return value as T;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SlowStore store;
  late bool Function() mayRunBefore;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    LocalCacheStore.debugForgetLegacyChecks();
    store = SlowStore({}, delay: _fast);
    FlutterSecureStoragePlatform.instance = store;
    SharedPreferences.setMockInitialValues({});
    // Como en la batería: arranques cortos, la app nunca queda ociosa, la
    // prueba por detrás no llega a correr.
    mayRunBefore = SecureStorageService.slowStoreProbeMayRun;
    SecureStorageService.slowStoreProbeMayRun = () => false;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.slowStoreProbeMayRun = mayRunBefore;
    SecureStorageService.debugSimulateRestart();
  });

  /// Cierra la app tras [openFor] y la vuelve a abrir. [damaged]: con la
  /// app cerrada, el archivo del almacén queda ilegible.
  SecureStorageService restart(FakeAsync async,
      {Duration openFor = const Duration(seconds: 8), bool damaged = false}) {
    async.elapse(openFor);
    if (damaged) store.data.clear();
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugResetQueue();
    return SecureStorageService();
  }

  SharedPreferences prefsNow(FakeAsync async) => _wait(async, SharedPreferences.getInstance());

  bool sessionInPrefs(SharedPreferences prefs) =>
      prefs.containsKey('secure_${ApiConstants.tokenKey}');

  /// Equipo sano con sesión del negocio A; UN arranque en que el almacén
  /// tarda 15 s (queda marcado) y vuelve a responder rápido. Después,
  /// [quickBoots] arranques cortos (el cuarto vuelve al almacén y, como
  /// todo traslado, deja un respaldo en preferencias un arranque más; en la
  /// batería hay ocho arranques entre ese y el paso 16). Devuelve el
  /// servicio del último.
  SecureStorageService oneOffSlowness(FakeAsync async, {int quickBoots = 6}) {
    SecureStorageService.debugResetQueue();
    var s = SecureStorageService();
    _wait(async, s.saveAuthData(token: 'jwt.a', refreshToken: 'r.a', userData: _userA, tenantSlug: 'a'));
    expect(SessionStartupTrace.storageMode, startsWith('almacén seguro de Windows'));

    s = restart(async);
    store.delay = const Duration(seconds: 15);
    expect(_wait(async, s.getToken()), 'jwt.a');
    expect(SessionStartupTrace.storageMode, contains('no respondió a tiempo'));
    // Lo que quedó corriendo por detrás termina; el equipo vuelve a ser sano.
    async.elapse(const Duration(minutes: 5));
    store.delay = _fast;
    expect(prefsNow(async).getBool(SecureStorageService.storeSlowKey), isTrue);

    for (var boot = 1; boot <= quickBoots; boot++) {
      s = restart(async);
      expect(_wait(async, s.getToken()), 'jwt.a', reason: 'arranque $boot perdió la sesión');
    }
    return s;
  }

  test('una demora pasajera: tres arranques rápidos sin tocar el almacén y el cuarto '
      'vuelve al almacén seguro, sin sesión en preferencias y sin marca', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      var s = SecureStorageService();
      _wait(async, s.saveAuthData(token: 'jwt.a', refreshToken: 'r.a', userData: _userA, tenantSlug: 'a'));
      s = restart(async);
      store.delay = const Duration(seconds: 15);
      expect(_wait(async, s.getToken()), 'jwt.a');
      async.elapse(const Duration(minutes: 5));
      store.delay = _fast;

      for (var boot = 1; boot <= SecureStorageService.slowStoreMarkedBoots; boot++) {
        s = restart(async);
        final calls = store.calls;
        final watch = async.elapsed;
        expect(_wait(async, s.getToken()), 'jwt.a');
        expect(async.elapsed - watch, lessThan(const Duration(seconds: 3)));
        expect(store.calls, calls, reason: 'arranque marcado $boot tocó el almacén');
        expect(SessionStartupTrace.storageMode, contains('es lento'));
      }

      s = restart(async);
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(SessionStartupTrace.storageMode, startsWith('almacén seguro de Windows'),
          reason: 'un equipo sano no puede quedarse en preferencias sin plazo');
      final prefs = prefsNow(async);
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isNull);
      expect(prefs.getInt(SecureStorageService.storeSlowBootsLifeKey), isNull);
      expect(store.data[ApiConstants.tokenKey], isNotNull, reason: 'la sesión vuelve al almacén');

      // Y el siguiente ya no deja la sesión en preferencias.
      s = restart(async);
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(sessionInPrefs(prefsNow(async)), isFalse,
          reason: 'la sesión siguió en preferencias, sin la protección del almacén');
    });
  });

  test('paso 16/17a (almacén en ceros o borrado): entra directo y el token viene de la '
      'copia protegida; el archivo del almacén se vuelve a crear', () {
    fakeAsync((async) {
      oneOffSlowness(async);
      final s = restart(async, damaged: true);
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(SessionStartupTrace.tokenSource, 'copia protegida');
      expect(_wait(async, s.getUserData())?['organizationId'], 'negocio-a');
      async.elapse(const Duration(seconds: 5));
      // Pasos 18, 20, 21 y 24: "no había archivo del almacén seguro".
      expect(store.data[ApiConstants.tokenKey], isNotNull,
          reason: 'el almacén debía quedar repuesto para el siguiente arranque');
    });
  });

  test('paso 18 (almacén cortado tras uno borrado): el segundo daño también se '
      'recupera de la copia protegida', () {
    fakeAsync((async) {
      oneOffSlowness(async);
      var s = restart(async, damaged: true);
      expect(_wait(async, s.getToken()), 'jwt.a');
      s = restart(async);
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(store.data, isNotEmpty, reason: 'no había archivo que dañar: el paso no simula nada');
      s = restart(async, damaged: true);
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(SessionStartupTrace.tokenSource, 'copia protegida');
    });
  });

  test('pasos 20/21 (sesión cerrada y almacén dañado): pide iniciar sesión', () {
    fakeAsync((async) {
      var s = oneOffSlowness(async);
      expect(SessionStartupTrace.storageMode, startsWith('almacén seguro de Windows'));
      _wait(async, s.deleteToken());
      _wait(async, s.deleteRefreshToken());
      async.elapse(const Duration(seconds: 5));
      expect(store.data, isNotEmpty, reason: 'no había archivo que dañar: el paso no simula nada');
      s = restart(async, damaged: true);
      expect(_wait(async, s.getToken()), isNull, reason: 'revivió una sesión cerrada');
      expect(SessionStartupTrace.storageMode, startsWith('almacén seguro de Windows'));
    });
  });

  test('paso 24 (negocio B y almacén en ceros): entra directo como B desde la copia protegida', () {
    fakeAsync((async) {
      var s = oneOffSlowness(async);
      _wait(async, s.clearAuthData());
      s = restart(async);
      _wait(async, s.saveAuthData(token: 'jwt.b', refreshToken: 'r.b', userData: _userB, tenantSlug: 'b'));
      s = restart(async);
      expect(_wait(async, s.getToken()), 'jwt.b');
      expect(store.data[ApiConstants.tokenKey], isNotNull,
          reason: 'no había archivo que dañar: el paso no simula nada');
      s = restart(async, damaged: true);
      expect(_wait(async, s.getToken()), 'jwt.b');
      expect(SessionStartupTrace.tokenSource, 'copia protegida');
      expect(_wait(async, s.getUserData())?['organizationId'], 'negocio-b');
    });
  });

  test('almacén dañado en un equipo sano (sin lentitud) no marca el equipo como lento', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      var s = SecureStorageService();
      _wait(async, s.saveAuthData(token: 'jwt.a', refreshToken: 'r.a', userData: _userA, tenantSlug: 'a'));
      // El respaldo del primer traslado dura un arranque más.
      for (var i = 0; i < 2; i++) {
        s = restart(async);
        expect(_wait(async, s.getToken()), 'jwt.a');
      }
      for (var i = 0; i < 3; i++) {
        s = restart(async, damaged: true);
        expect(_wait(async, s.getToken()), 'jwt.a');
        expect(SessionStartupTrace.tokenSource, 'copia protegida');
        expect(SessionStartupTrace.storageMode, startsWith('almacén seguro de Windows'));
        expect(prefsNow(async).getBool(SecureStorageService.storeSlowKey), isNull);
      }
    });
  });

  test('equipo de verdad lento: al caducar la marca vuelve a esperar UNA vez y después '
      'la marca dura el doble (seis arranques rápidos sin tocar el almacén)', () {
    fakeAsync((async) {
      store.delay = const Duration(seconds: 15);
      SecureStorageService.debugResetQueue();
      var s = SecureStorageService();
      _wait(async, s.saveAuthData(token: 'jwt.a', refreshToken: 'r.a', userData: _userA, tenantSlug: 'a'));
      async.elapse(const Duration(minutes: 5));

      void fastBoots(int count, String why) {
        for (var boot = 1; boot <= count; boot++) {
          s = restart(async);
          final calls = store.calls;
          final start = async.elapsed;
          expect(_wait(async, s.getToken()), 'jwt.a');
          expect(async.elapsed - start, lessThan(const Duration(seconds: 3)), reason: '$why, arranque $boot');
          expect(store.calls, calls, reason: '$why, arranque $boot tocó el almacén');
        }
      }

      fastBoots(SecureStorageService.slowStoreMarkedBoots, 'marca recién puesta');
      // Caducó: este arranque vuelve a preguntarle al almacén y espera el tope.
      s = restart(async);
      final start = async.elapsed;
      expect(_wait(async, s.getToken()), 'jwt.a');
      expect(async.elapsed - start, greaterThanOrEqualTo(SecureStorageService.windowsDecisionTimeout));
      async.elapse(const Duration(minutes: 5));
      expect(prefsNow(async).getBool(SecureStorageService.storeSlowKey), isTrue);
      fastBoots(SecureStorageService.slowStoreMarkedBoots * 2, 'marca renovada');
    });
  });
}
