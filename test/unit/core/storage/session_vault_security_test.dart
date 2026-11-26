// Seguridad de la copia protegida de la sesión: nunca mezcla dos negocios,
// una sesión cerrada no revive y los archivos viejos no guardan sesiones.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/storage/durable_prefs_store.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/core/storage/session_vault.dart';
import 'package:baudex_desktop/app/core/storage/value_protector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class FakeProtector implements ValueProtector {
  bool broken = false;
  @override
  String? protect(String plain) =>
      broken ? null : 'fake:${base64Encode(utf8.encode(plain))}';
  @override
  String? unprotect(String stored) => !stored.startsWith('fake:')
      ? null
      : utf8.decode(base64Decode(stored.substring(5)));
}

/// Preferencias en memoria a las que se les puede impedir borrar.
class StubbornPrefs extends SharedPreferencesStorePlatform {
  final values = <String, Object>{};
  bool refuseRemove = false;

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async => Map.of(values);

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async =>
      Map.of(values);

  @override
  Future<bool> remove(String key) async {
    if (refuseRemove) return false;
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    values[key] = value;
    return true;
  }
}

/// JWT de mentira con el id de usuario en el cuerpo (como los del servidor).
String jwt(String userId) =>
    'h.${base64Url.encode(utf8.encode(json.encode({'id': userId, 'jti': 'j-$userId'})))}.firma';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestFlutterSecureStoragePlatform store;
  late FakeProtector protector;
  late Directory dir;

  SecureStorageService restart() {
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    return SecureStorageService();
  }

  /// Encender el equipo sin la llave del almacén: lo guardado no se lee.
  void loseKey() => store.data.clear();

  /// Un arranque normal más: confirma el traslado al almacén seguro, con lo
  /// que las preferencias dejan de tener el respaldo antiguo `secure_*`
  /// (así está un equipo en uso). Lee lo que la app lee al arrancar.
  Future<void> normalStart() async {
    final s = restart();
    await s.getToken();
    await s.getRefreshToken();
    await s.getUserData();
    await s.getTenantSlug();
    await s.getCurrentOrganization();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('secure_')), isEmpty);
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    store = TestFlutterSecureStoragePlatform({});
    FlutterSecureStoragePlatform.instance = store;
    protector = FakeProtector();
    dir = Directory.systemTemp.createTempSync('baudex_vault');
    SecureStorageService.debugProtector = protector;
    SecureStorageService.debugRevokedFlag = File('${dir.path}/anulada');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugRevokedFlag = null;
    installedDurablePrefs = null;
    dir.deleteSync(recursive: true);
  });

  Future<void> login(SecureStorageService s, String who, {bool withOrg = true}) =>
      s.saveAuthData(
        token: jwt('user-$who'),
        refreshToken: 'refresh-$who',
        userData: {'id': 'user-$who', 'organizationId': 'org-$who'},
        tenantSlug: 'tienda-$who',
        organization: withOrg ? {'id': 'org-$who', 'name': 'Negocio $who'} : null,
      );

  group('copia coherente', () {
    test('token de un usuario con datos de otro: no se usa nada', () {
      final copy = coherentSessionCopy({
        'auth_token': jwt('user-b'),
        'user_data': json.encode({'id': 'user-a', 'organizationId': 'org-a'}),
        'current_organization': json.encode({'id': 'org-a'}),
      });
      expect(copy, isEmpty);
    });

    test('negocio que no es el del usuario: se descarta el negocio', () {
      final copy = coherentSessionCopy({
        'auth_token': jwt('user-b'),
        'user_data': json.encode({'id': 'user-b', 'organizationId': 'org-b'}),
        'current_organization': json.encode({'id': 'org-a'}),
      });
      expect(copy.containsKey('auth_token'), isTrue);
      expect(copy.containsKey('current_organization'), isFalse);
    });

    test('sin usuario o sin token: no se usa nada', () {
      expect(coherentSessionCopy({'auth_token': jwt('u')}), isEmpty);
      expect(coherentSessionCopy({'user_data': '{"id":"u"}'}), isEmpty);
    });
  });

  test('negocio A y luego B: tras perder la llave entra como B y no queda '
      'nada de A', () async {
    var s = restart();
    await login(s, 'a');
    await login(s, 'b', withOrg: false); // B llega sin datos del negocio
    await normalStart();

    loseKey();
    s = restart();

    expect(await s.getToken(), jwt('user-b'));
    expect((await s.getUserData())?['organizationId'], 'org-b');
    expect(await s.getTenantSlug(), 'tienda-b');
    expect(await s.getCurrentOrganization(), isNull, reason: 'el negocio de A no puede seguir');
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getKeys().map((k) => '${prefs.get(k)}').join();
    expect(utf8.decode(base64Decode(prefs.getString(SessionVault.sessionEntry)!.substring(5))),
        isNot(contains('org-a')));
    expect(all, isNot(contains('Negocio a')));
  });

  test('si no se puede cifrar al iniciar sesión con B, no queda copia de '
      'nadie (ni la vieja de A)', () async {
    var s = restart();
    await login(s, 'a');
    protector.broken = true;
    await login(s, 'b');
    protector.broken = false;

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SessionVault.sessionEntry), isFalse);

    // Arranque normal (la copia se vuelve a sembrar, ya solo con B) y
    // luego se pierde la llave: lo que haya es de B, nunca de A.
    await normalStart();
    loseKey();
    s = restart();
    expect(await s.getToken(), anyOf(isNull, jwt('user-b')));
    expect((await s.getUserData())?['organizationId'], anyOf(isNull, 'org-b'));
    expect((await s.getCurrentOrganization())?['id'], anyOf(isNull, 'org-b'));
    final entry = prefs.getString(SessionVault.sessionEntry);
    if (entry != null) {
      expect(utf8.decode(base64Decode(entry.substring(5))), isNot(contains('-a')));
    }
  });

  test('cifrar falla solo en una escritura suelta (renovar token): la copia '
      'entera se quita, no queda la versión anterior', () async {
    final s = restart();
    await login(s, 'a');
    protector.broken = true;
    await s.saveToken(jwt('user-a'));
    await s.saveToken('${jwt('user-a')}x');
    protector.broken = false;

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SessionVault.sessionEntry), isFalse);
  });

  test('cerrar sesión y que las preferencias NO dejen borrar: la copia '
      'queda anulada y no repone la sesión; un inicio nuevo la reactiva', () async {
    final stubborn = StubbornPrefs();
    SharedPreferencesStorePlatform.instance = stubborn;
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.resetStatic();
    var s = restart();
    await login(s, 'a');
    expect(stubborn.values.keys, contains('flutter.${SessionVault.sessionEntry}'));

    stubborn.refuseRemove = true;
    await s.clearAuthData();
    expect(stubborn.values.keys, contains('flutter.${SessionVault.sessionEntry}'),
        reason: 'la prueba exige que el borrado haya fallado');

    stubborn.values.removeWhere((k, _) => k.startsWith('flutter.secure_'));
    loseKey();
    s = restart();
    expect(await s.getToken(), isNull, reason: 'una sesión cerrada no revive');
    expect(await s.getUserData(), isNull);

    stubborn.refuseRemove = false;
    await login(s, 'b');
    stubborn.values.removeWhere((k, _) => k.startsWith('flutter.secure_'));
    loseKey();
    s = restart();
    expect(await s.getToken(), jwt('user-b'));
  });

  test('sembrar la copia mientras se cierra sesión no la revive', () async {
    final vault = SessionVault(protector: protector);
    await vault.write('auth_token', jwt('user-a'));
    await vault.write('user_data', json.encode({'id': 'user-a'}));

    final seeding = vault.seed('refresh_token', 'refresh-a');
    final closing = vault.delete('auth_token');
    await Future.wait([seeding, closing]);

    expect(await vault.read('auth_token'), isNull);
    expect(await vault.read('refresh_token'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SessionVault.sessionEntry), isFalse);
  });

  group('archivo real de preferencias', () {
    late File file;
    File bak() => File('${file.path}.bak');

    Future<void> startPrefs() async {
      await installDurablePrefs(fileOverride: file);
    }

    setUp(() => file = File('${dir.path}/prefs/shared_preferences.json'));

    test('cerrar sesión → se daña el archivo → arrancar: pide iniciar sesión '
        '(la copia .bak ya no tiene la sesión)', () async {
      await startPrefs();
      var s = restart();
      await login(s, 'a');
      await installedDurablePrefs!.flush();
      expect(bak().readAsStringSync(), contains('vault_'), reason: 'antes de cerrar');

      await s.clearAuthData();
      await installedDurablePrefs!.flush();

      expect(file.readAsStringSync(), isNot(contains(SessionVault.sessionEntry)));
      expect(bak().readAsStringSync(), isNot(contains(SessionVault.sessionEntry)));
      expect(File('${file.path}.tmp').existsSync(), isFalse);

      // Apagón: el principal queda en ceros; se restaura de la copia.
      file.writeAsBytesSync(List<int>.filled(file.lengthSync(), 0));
      loseKey();
      final report = await installDurablePrefs(fileOverride: file);
      s = restart();

      expect(report!.source, PrefsLoadSource.backup);
      expect(await s.getToken(), isNull);
      expect(await s.getUserData(), isNull);
    });

    test('sesión expirada (borrar el token) también limpia la copia .bak', () async {
      await startPrefs();
      final s = restart();
      await login(s, 'a');
      await s.deleteToken();
      await s.deleteRefreshToken();
      await s.deleteUserData();
      await installedDurablePrefs!.flush();

      expect(bak().readAsStringSync(), isNot(contains(SessionVault.sessionEntry)));
    });

    test('archivos dañados apartados: queda como mucho el más reciente y '
        'sin claves de sesión', () async {
      file.parent.createSync(recursive: true);
      String damaged(int n) => '${file.path}.danado-$n';
      File(damaged(1000)).writeAsStringSync('{"flutter.secure_auth_token":"viejo"}');
      File(damaged(2000)).writeAsStringSync('{"flutter.vault_session_v2":"x","flutter.a":1}');
      File(damaged(3000)).writeAsStringSync(
        '{"flutter.sync_wm_v1|o|p":"2026","flutter.secure_auth_token":"enc:v1:AAA",'
        '"flutter.vault_session_v2":"fake:BBB","flutter.cortado":"se ac',
      );

      await startPrefs();

      // Solo los nombres: en Windows las rutas mezclan / y \.
      final left = file.parent
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.contains('.danado-'))
          .toList();
      expect(left, ['shared_preferences.json.danado-3000']);
      final text = File(damaged(3000)).readAsStringSync();
      expect(text, contains('sync_wm_v1'));
      expect(text, isNot(contains('secure_')));
      expect(text, isNot(contains('vault_')));
    });

    test('un dañado que solo tenía claves de sesión se borra', () async {
      file.parent.createSync(recursive: true);
      final damaged = File('${file.path}.danado-1');
      damaged.writeAsStringSync('{"flutter.vault_session_v2":"fake:BBB"}');
      await startPrefs();
      expect(damaged.existsSync(), isFalse);
    });
  });
}
