// Cerrar sesión con el almacén seguro roto deja una marca en preferencias:
// el siguiente arranque borra la sesión del almacén ANTES de usarlo, y si no
// puede, no usa el token del almacén. En un equipo normal nada cambia.
import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa_login_review2_test.dart' show ThrowingStore;
import 'secure_storage_lost_key_test.dart' show FakeProtector;

T? _get<T>(FakeAsync async, Future<T> f, {Duration wait = const Duration(seconds: 30)}) {
  T? out;
  Object? error;
  var done = false;
  f.then((v) {
    out = v;
    done = true;
  }, onError: (Object e) {
    error = e;
    done = true;
  });
  async.elapse(wait);
  expect(done, isTrue, reason: 'no terminó');
  expect(error, isNull);
  return out;
}

/// La fila del almacén se crea DENTRO del tiempo simulado de cada prueba
/// (creada fuera, sus pasos nunca corren).
void _fakeAsync(void Function(FakeAsync async) body) => fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      body(async);
    });

const _user = {'id': 'u1', 'organizationId': 'o1'};

Future<bool> _marker() async =>
    (await SharedPreferences.getInstance()).getBool(SecureStorageService.storeWipePendingKey) == true;

/// Arranque con el almacén roto (sesión vieja dentro), login, negocio,
/// correo y cerrar sesión. Devuelve los datos del almacén.
Map<String, String> _logoutWithBrokenStore(FakeAsync async) {
  SharedPreferences.setMockInitialValues({'baudex_secure_store_migrated_v1': true});
  final data = <String, String>{
    ApiConstants.tokenKey: 'jwt.VIEJO',
    ApiConstants.refreshTokenKey: 'r.VIEJO',
    ApiConstants.userKey: '{"id":"viejo"}',
  };
  FlutterSecureStoragePlatform.instance = ThrowingStore(data);
  final s = SecureStorageService();
  expect(_get(async, s.getToken()), isNull);
  _get(async, s.saveAuthData(token: 'jwt.NUEVO', refreshToken: 'r1', userData: _user));
  _get(async, s.saveLastBusiness('Tienda'));
  _get(async, s.saveLastEmail('a@b.co'));
  _get(async, s.clearAuthData());
  expect(_get(async, s.getToken()), isNull);
  expect(_get(async, _marker()), isTrue);
  return data;
}

SecureStorageService _restart(FlutterSecureStoragePlatform store) {
  SecureStorageService.debugSimulateRestart();
  FlutterSecureStoragePlatform.instance = store;
  return SecureStorageService();
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

  test('marca presente y el almacén sigue roto: no usa token, pide login; sano después: limpia', () {
    _fakeAsync((async) {
      final data = _logoutWithBrokenStore(async);

      final s2 = _restart(ThrowingStore(data));
      expect(_get(async, s2.getToken()), isNull);
      expect(_get(async, s2.getRefreshToken()), isNull);
      expect(_get(async, s2.getLastBusiness()), 'Tienda');
      expect(_get(async, _marker()), isTrue, reason: 'no se pudo borrar: la marca se queda');
      expect(data[ApiConstants.tokenKey], 'jwt.VIEJO');

      final s3 = _restart(TestFlutterSecureStoragePlatform(data));
      expect(_get(async, s3.getToken()), isNull);
      expect(_get(async, s3.getLastBusiness()), 'Tienda');
      expect(_get(async, s3.getLastEmail()), 'a@b.co');
      expect(_get(async, _marker()), isFalse);
      expect(data.containsKey(ApiConstants.tokenKey), isFalse);
      expect(data.containsKey(ApiConstants.refreshTokenKey), isFalse);
      expect(data.containsKey(ApiConstants.userKey), isFalse);

      final s4 = _restart(TestFlutterSecureStoragePlatform(data));
      expect(_get(async, s4.getToken()), isNull);
    });
  });

  test('login nuevo tras la marca (almacén aún roto): manda la sesión nueva al reabrir sano', () {
    _fakeAsync((async) {
      final data = _logoutWithBrokenStore(async);

      final s2 = _restart(ThrowingStore(data));
      expect(_get(async, s2.getToken()), isNull);
      _get(async, s2.saveAuthData(token: 'jwt.OTRO', refreshToken: 'r.OTRO', userData: _user));
      expect(_get(async, s2.getToken()), 'jwt.OTRO');

      for (var i = 0; i < 2; i++) {
        final s = _restart(TestFlutterSecureStoragePlatform(data));
        expect(_get(async, s.getToken()), 'jwt.OTRO', reason: 'reabrir $i');
        expect(_get(async, s.getRefreshToken()), 'r.OTRO');
        expect(_get(async, s.getLastBusiness()), 'Tienda');
      }
      expect(_get(async, _marker()), isFalse);
      expect(data[ApiConstants.tokenKey], 'jwt.OTRO');
    });
  });

  test('cierre cortado: markSessionClosed deja la marca y el token no entra solo', () {
    _fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final data = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
      final s = SecureStorageService();
      _get(async, s.saveAuthData(token: 'jwt.X', refreshToken: 'r', userData: _user));
      _get(async, s.saveLastBusiness('Tienda'));
      _get(async, s.markSessionClosed()); // el cierre normal no llegó a terminar
      expect(data[ApiConstants.tokenKey], 'jwt.X');

      final s2 = _restart(TestFlutterSecureStoragePlatform(data));
      expect(_get(async, s2.getToken()), isNull);
      expect(_get(async, s2.getLastBusiness()), 'Tienda');
      expect(_get(async, _marker()), isFalse);
    });
  });

  test('cierre cortado en modo preferencias: el token se va ya y no vuelve', () {
    _fakeAsync((async) {
      SharedPreferences.setMockInitialValues({'baudex_secure_store_migrated_v1': true});
      final data = <String, String>{ApiConstants.tokenKey: 'jwt.VIEJO'};
      FlutterSecureStoragePlatform.instance = ThrowingStore(data);
      final s = SecureStorageService();
      _get(async, s.saveAuthData(token: 'jwt.N', refreshToken: 'r', userData: _user));
      _get(async, s.markSessionClosed());
      expect(_get(async, s.getToken()), isNull);
      final s2 = _restart(TestFlutterSecureStoragePlatform(data));
      expect(_get(async, s2.getToken()), isNull);
    });
  });

  test('equipo normal: cerrar sesión y reabrir x2, login y reabrir x2; nunca hay marca', () {
    _fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final data = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
      var s = SecureStorageService();
      _get(async, s.saveAuthData(token: 'jwt.X', refreshToken: 'r', userData: _user));
      _get(async, s.saveLastBusiness('Tienda'));
      _get(async, s.saveLastEmail('a@b.co'));
      _get(async, s.clearAuthData());
      expect(_get(async, _marker()), isFalse);
      for (var i = 0; i < 2; i++) {
        s = _restart(TestFlutterSecureStoragePlatform(data));
        expect(_get(async, s.getToken()), isNull);
        expect(_get(async, s.getLastBusiness()), 'Tienda');
        expect(_get(async, s.getLastEmail()), 'a@b.co');
      }
      _get(async, s.saveAuthData(token: 'jwt.Y', refreshToken: 'r2', userData: _user));
      for (var i = 0; i < 2; i++) {
        s = _restart(TestFlutterSecureStoragePlatform(data));
        expect(_get(async, s.getToken()), 'jwt.Y');
        expect(_get(async, s.getLastBusiness()), 'Tienda');
      }
      expect(_get(async, _marker()), isFalse);
    });
  });
}
