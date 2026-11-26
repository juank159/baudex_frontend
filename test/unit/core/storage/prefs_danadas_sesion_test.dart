// Qué le pasa a la sesión en Windows cuando `shared_preferences.json` está
// dañado, y cuando la reparación de 1.0.10 lo aparta a mitad de sesión.
// Todo en memoria: ni el llavero ni las preferencias reales del equipo.
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Preferencias como el archivo de Windows: se pueden dañar (cada lectura
/// lanza `FormatException`, igual que el complemento) y apartar (vacías).
class ArchivoDePreferencias extends SharedPreferencesStorePlatform {
  Map<String, Object> datos = {};
  bool danado = false;
  int lecturas = 0;

  void apartar() {
    danado = false;
    datos = {};
  }

  @override
  Future<Map<String, Object>> getAll() async {
    lecturas++;
    if (danado) throw const FormatException('Unexpected character (at character 1)');
    return Map.of(datos);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (danado) throw const FormatException('Unexpected character (at character 1)');
    datos[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    datos.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    datos.clear();
    return true;
  }
}

const usuario = {'id': 'u1', 'organizationId': 'org-1', 'email': 'caja@tienda.co'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArchivoDePreferencias archivo;
  late TestFlutterSecureStoragePlatform almacen;

  /// Cierra y vuelve a abrir la app.
  void reiniciarApp() {
    SecureStorageService.debugSimulateRestart();
    SharedPreferences.resetStatic();
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    archivo = ArchivoDePreferencias();
    SharedPreferencesStorePlatform.instance = archivo;
    // Sesión ya trasladada y confirmada en el almacén seguro (versiones
    // anteriores): lo normal en un equipo que venía funcionando.
    almacen = TestFlutterSecureStoragePlatform({
      'auth_token': 'jwt.sesion.vieja',
      'refresh_token': 'refresh-viejo',
      'user_data': '{"id":"u1","organizationId":"org-1","email":"caja@tienda.co"}',
    });
    FlutterSecureStoragePlatform.instance = almacen;
    archivo.datos = {'flutter.${PrefsToSecureStoreMigration.doneFlag}': true};
    reiniciarApp();
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('preferencias sanas: la sesión se conserva entre arranques', () async {
    final servicio = SecureStorageService();
    expect(await servicio.isAuthenticated(), isTrue);
    reiniciarApp();
    expect(await servicio.isAuthenticated(), isTrue);
  });

  test('preferencias dañadas y nadie las toca (1.0.9): la sesión se conserva', () async {
    archivo.danado = true;
    final servicio = SecureStorageService();
    expect(await servicio.isAuthenticated(), isTrue);
    expect(await servicio.getToken(), 'jwt.sesion.vieja');
    reiniciarApp();
    expect(await servicio.getToken(), 'jwt.sesion.vieja');
  });

  test('dañadas y apartadas a mitad de sesión (1.0.10): la sesión se pierde '
      'en ese momento', () async {
    archivo.danado = true;
    final servicio = SecureStorageService();
    expect(await servicio.isAuthenticated(), isTrue, reason: 'arranca con sesión');

    // La app lee las impresoras, falla y aparta el archivo.
    archivo.apartar();

    expect(await servicio.getToken(), isNull,
        reason: 'el almacén eligió "preferencias" al arrancar y ahora están vacías');
    expect(await servicio.isAuthenticated(), isFalse);
  });

  test('dañadas y apartadas AL ARRANCAR, antes de leer nada (arreglo): la '
      'sesión se conserva', () async {
    archivo.danado = true;
    // main.dart llama a repairDevicePreferencesFile() antes que todo.
    archivo.apartar();

    final servicio = SecureStorageService();
    expect(await servicio.isAuthenticated(), isTrue);
    expect(await servicio.getToken(), 'jwt.sesion.vieja');

    // Y sigue ahí en los arranques siguientes.
    reiniciarApp();
    expect(await servicio.isAuthenticated(), isTrue);
    reiniciarApp();
    expect(await servicio.isAuthenticated(), isTrue);
  });

  test('dañadas, apartadas y vuelta a entrar: la sesión nueva queda SOLO en '
      'preferencias; si el archivo se vuelve a dañar, al abrir vuelve la '
      'sesión vieja (vencida)', () async {
    archivo.danado = true;
    final servicio = SecureStorageService();
    expect(await servicio.isAuthenticated(), isTrue);
    archivo.apartar();

    // El cajero vuelve a entrar.
    await servicio.saveAuthData(
      token: 'jwt.sesion.nueva',
      refreshToken: 'refresh-nuevo',
      userData: usuario,
    );
    expect(almacen.data['auth_token'], 'jwt.sesion.vieja',
        reason: 'la sesión nueva no llegó al almacén seguro');
    expect(archivo.datos.keys.where((k) => k.contains('secure_auth_token')), isNotEmpty);

    // Arranque siguiente con preferencias sanas: se traslada y se conserva.
    reiniciarApp();
    expect(await servicio.getToken(), 'jwt.sesion.nueva');

    // Pero si el archivo se dañó otra vez antes de ese arranque…
    almacen.data['auth_token'] = 'jwt.sesion.vieja';
    archivo.danado = true;
    reiniciarApp();
    expect(await servicio.getToken(), 'jwt.sesion.vieja',
        reason: 'vuelve la sesión anterior, que el servidor ya no acepta');
  });

  test('con preferencias dañadas, cada lectura del token vuelve a leer el '
      'archivo dañado', () async {
    archivo.danado = true;
    final servicio = SecureStorageService();
    await servicio.getToken();
    final antes = archivo.lecturas;
    for (var i = 0; i < 20; i++) {
      await servicio.getToken();
    }
    expect(archivo.lecturas - antes, 20);
  });
}
