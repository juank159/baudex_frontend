// Sesión en Windows cuando las preferencias del equipo no se pueden leer
// (archivo dañado). Antes el almacén de sesión elegía "seguir con
// preferencias" y la sesión guardada en el almacén seguro no se veía.
// ignore_for_file: depend_on_referenced_packages
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _BrokenPrefs extends SharedPreferencesStorePlatform {
  @override
  Future<Map<String, Object>> getAll() async =>
      throw const FormatException('Control character in string');
  @override
  Future<bool> clear() async => throw const FormatException('dañado');
  @override
  Future<bool> remove(String key) async => throw const FormatException('dañado');
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw const FormatException('dañado');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestFlutterSecureStoragePlatform store;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _BrokenPrefs();
    store = TestFlutterSecureStoragePlatform({
      'auth_token': 'jwt.guardado',
      'refresh_token': 'refresh-guardado',
    });
    FlutterSecureStoragePlatform.instance = store;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('la sesión guardada en el almacén seguro se sigue viendo', () async {
    final service = SecureStorageService();
    expect(await service.getToken(), 'jwt.guardado');
    expect(await service.getRefreshToken(), 'refresh-guardado');
  });

  test('iniciar sesión guarda en el almacén seguro y se conserva al '
      'reiniciar, aunque las preferencias vuelvan a funcionar', () async {
    var service = SecureStorageService();
    await service.saveToken('jwt.nuevo');
    expect(store.data['auth_token'], 'jwt.nuevo');

    // Siguiente arranque: las preferencias ya sirven (y están vacías).
    SecureStorageService.debugSimulateRestart();
    SharedPreferences.setMockInitialValues({});
    service = SecureStorageService();

    expect(await service.getToken(), 'jwt.nuevo');
  });

  test('las preferencias se reparan a mitad de la sesión: no se pierde la '
      'sesión ni se guarda el inicio de sesión donde no se va a leer', () async {
    final service = SecureStorageService();
    expect(await service.getToken(), 'jwt.guardado');

    // El archivo dañado se aparta: las preferencias vuelven, vacías.
    SharedPreferences.setMockInitialValues({});

    expect(await service.getToken(), 'jwt.guardado');
    await service.saveToken('jwt.despues');
    expect(store.data['auth_token'], 'jwt.despues');
  });
}
