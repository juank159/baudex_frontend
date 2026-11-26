// "Si cierro la app me recupera la sesión; si apago el equipo me toca
// volver a iniciar sesión."
//
// En Windows el almacén seguro (flutter_secure_storage 3.1.2) guarda cada
// valor en un archivo cifrado con una llave que vive en el Administrador
// de credenciales. Si al encender esa llave no está, el complemento
// devuelve null para TODO sin avisar. La sesión no puede depender de eso:
// hay una copia protegida (DPAPI) en las preferencias del equipo.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/core/storage/value_protector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cifrador de mentira (en la app es DPAPI).
class FakeProtector implements ValueProtector {
  bool broken = false;
  @override
  String? protect(String plain) =>
      broken ? null : 'fake:${base64Encode(utf8.encode(plain))}';
  @override
  String? unprotect(String stored) => broken || !stored.startsWith('fake:')
      ? null
      : utf8.decode(base64Decode(stored.substring(5)));
}

/// Sin copia protegida, como las versiones anteriores. (No basta con dejar
/// `debugProtector` en null: en Windows real la app usaría DPAPI de
/// verdad y la prueba dejaría de simular la versión vieja.)
class NoProtector implements ValueProtector {
  const NoProtector();
  @override
  String? protect(String plain) => null;
  @override
  String? unprotect(String stored) => null;
}

/// Almacén seguro al que se le puede "perder la llave" (todo lee null,
/// como hace el complemento) o dejar sin responder.
class FragileStore extends TestFlutterSecureStoragePlatform {
  FragileStore(super.data);
  bool unavailable = false;

  /// Encender el equipo sin la llave: lo guardado ya no se puede leer.
  void loseKey() => data.clear();

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    if (unavailable) throw PlatformException(code: 'cred', message: 'no disponible');
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    if (unavailable) throw PlatformException(code: 'cred', message: 'no disponible');
    return super.write(key: key, value: value, options: options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FragileStore store;
  late FakeProtector protector;

  SecureStorageService restart() {
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    return SecureStorageService();
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    store = FragileStore({});
    FlutterSecureStoragePlatform.instance = store;
    protector = FakeProtector();
    SecureStorageService.debugProtector = protector;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
  });

  /// Inicia sesión y abre la app una vez más: en ese segundo arranque el
  /// traslado al almacén seguro queda confirmado y las preferencias dejan
  /// de tener el respaldo `secure_*` (así está un equipo en uso normal).
  Future<void> login(SecureStorageService service) async {
    await service.saveAuthData(
      token: 'jwt.de.hoy',
      refreshToken: 'refresh-1',
      userData: {'id': 'u1', 'organizationId': 'org-1'},
      tenantSlug: 'mi-tienda',
    );
    final again = restart();
    expect(await again.getToken(), 'jwt.de.hoy');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('secure_')), isEmpty);
  }

  test('sin copia protegida (como en 1.0.11): perder la llave del almacén '
      'deja la app sin sesión', () async {
    SecureStorageService.debugProtector = const NoProtector();
    var service = restart();
    await login(service);
    expect(await service.getToken(), 'jwt.de.hoy'); // cerrar y abrir: sigue

    store.loseKey(); // apagar y encender
    service = restart();
    // Sin copia: es exactamente el comportamiento anterior.
    expect(await service.getToken(), isNull);
  });

  test('apagar y encender con la llave perdida: la sesión sigue y el '
      'almacén se repone', () async {
    var service = restart();
    await login(service);

    store.loseKey();
    service = restart();

    expect(await service.getToken(), 'jwt.de.hoy');
    expect(await service.getRefreshToken(), 'refresh-1');
    expect((await service.getUserData())?['organizationId'], 'org-1');
    expect(await service.getTenantSlug(), 'mi-tienda');
    expect(store.data['auth_token'], 'jwt.de.hoy', reason: 'se repone');
    expect(SessionStartupTrace.tokenSource, 'copia protegida');
    SessionStartupTrace.authChecked(true);
    expect(SessionStartupTrace.sessionLine(), contains('entró directo'));
    expect(SessionStartupTrace.sessionLine(), contains('había perdido'));
  });

  test('primer arranque tras encender con el almacén sin responder: la '
      'sesión sigue; al siguiente arranque también', () async {
    var service = restart();
    await login(service);

    store.unavailable = true;
    service = restart();
    expect(await service.getToken(), 'jwt.de.hoy');
    expect(SessionStartupTrace.storageMode, contains('no respondió'));

    store.unavailable = false;
    service = restart();
    expect(await service.getToken(), 'jwt.de.hoy');
  });

  test('sesión abierta en una versión anterior: se copia al leerla y ya '
      'aguanta perder la llave', () async {
    SecureStorageService.debugProtector = const NoProtector();
    var service = restart();
    await login(service);

    SecureStorageService.debugProtector = protector; // se instala la versión nueva
    service = restart();
    // Lo que la app lee al arrancar con sesión.
    expect(await service.getToken(), 'jwt.de.hoy');
    expect(await service.getRefreshToken(), 'refresh-1');
    expect(await service.getUserData(), isNotNull);

    store.loseKey();
    service = restart();
    expect(await service.getToken(), 'jwt.de.hoy');
    expect(await service.getRefreshToken(), 'refresh-1');
  });

  test('token renovado: la copia guarda el nuevo, no el viejo', () async {
    var service = restart();
    await login(service);
    await service.saveToken('jwt.renovado');

    store.loseKey();
    service = restart();
    expect(await service.getToken(), 'jwt.renovado');
  });

  test('cerrar sesión borra también la copia: tras apagar NO revive', () async {
    var service = restart();
    await login(service);

    await service.clearAuthData();
    store.loseKey();
    service = restart();

    expect(await service.getToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.contains('auth_token')), isEmpty);
  });

  test('sesión expirada (borrar token): la copia no la revive', () async {
    var service = restart();
    await login(service);
    await service.deleteToken();
    await service.deleteRefreshToken();
    await service.deleteUserData();

    service = restart();
    expect(await service.getToken(), isNull);
    SessionStartupTrace.authChecked(false);
    expect(
      SessionStartupTrace.sessionLine(),
      contains('no había ninguna sesión guardada'),
    );
  });

  test('si la copia no se puede descifrar no inventa nada', () async {
    var service = restart();
    await login(service);
    store.loseKey();
    protector.broken = true;
    service = restart();
    expect(await service.getToken(), isNull);
  });

  test('renglones de Diagnóstico: se escriben una vez, cuando ya se conoce '
      'el negocio', () async {
    SessionStartupTrace.debugReset();
    final lines = <String>[];
    var known = false;
    SessionStartupTrace.organizationKnown = () => known;
    SessionStartupTrace.sink = (message, {warning = false}) async => lines.add(message);
    SessionStartupTrace.tokenSource = 'almacén seguro';
    SessionStartupTrace.storageMode = 'almacén seguro de Windows + copia protegida';
    SessionStartupTrace.authChecked(true);

    await SessionStartupTrace.flush();
    expect(lines, isEmpty);
    known = true;
    await SessionStartupTrace.flush();
    await SessionStartupTrace.flush();

    expect(lines.length, 2);
    expect(lines.first, startsWith('Sesión: entró directo (token leído de: almacén seguro)'));
    expect(lines.last, startsWith('Preferencias:'));
    SessionStartupTrace.debugReset();
  });

  test('modo preferencias y el respaldo `secure_*` ya no se puede descifrar '
      '(cambió el nombre del equipo o la versión de Windows): se usa la copia', () async {
    var service = restart();
    await login(service);
    // El almacén no responde → la app sigue con preferencias.
    store.unavailable = true;
    service = restart();
    await service.saveToken('jwt.en.preferencias');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_auth_token'), startsWith('enc:v1:'));

    // Como si la clave del cifrado casero ya fuera otra.
    await prefs.setString('secure_auth_token', 'enc:v1:${base64Encode(List<int>.filled(48, 7))}');
    service = restart();

    expect(await service.getToken(), 'jwt.en.preferencias');
    expect(SessionStartupTrace.tokenSource, 'copia protegida');
  });
}
