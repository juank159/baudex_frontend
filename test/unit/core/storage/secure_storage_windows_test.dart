import 'package:baudex_desktop/app/core/security/offline_password_hasher.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacén seguro de prueba que se puede "romper" (DPAPI que falla).
class BreakableStore extends TestFlutterSecureStoragePlatform {
  BreakableStore(super.data);
  bool broken = false;

  void _check() {
    if (broken) throw PlatformException(code: 'DPAPI', message: 'CryptUnprotectData falló');
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    _check();
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    _check();
    return super.write(key: key, value: value, options: options);
  }
}

/// SecureStorageService como en Windows, con el almacén seguro y las
/// preferencias de prueba en memoria (nunca el llavero ni el plist reales).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BreakableStore store;
  final legacyCredentials =
      '{"email":"caja@tienda.co","passwordHash":"${OfflinePasswordHasher.legacyHash('Clave#9', 'caja@tienda.co')}","savedAt":"2026-11-01T10:00:00.000"}';

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SharedPreferences.setMockInitialValues({
      // Formato sin prefijo "enc:" (versión aún más vieja): se lee tal cual.
      'secure_auth_token': 'jwt.token.firma',
      'secure_refresh_token': 'refresh-1',
      'secure_last_user_id': 'u1',
      'secure_offline_credentials': legacyCredentials,
    });
    store = BreakableStore({});
    FlutterSecureStoragePlatform.instance = store;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<List<String>> secureKeysInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith('secure_')).toList();
  }

  test('arranque 1 copia y conserva respaldo; arranque 2 confirma y limpia; '
      'la huella vieja se cambia al entrar sin internet', () async {
    final service = SecureStorageService();

    // Arranque 1: sesión intacta, ya leída del almacén seguro.
    expect(await service.getToken(), 'jwt.token.firma');
    expect(await service.getLastUserId(), 'u1');
    expect(store.data['auth_token'], 'jwt.token.firma');
    expect(await secureKeysInPrefs(), isNotEmpty, reason: 'respaldo hasta confirmar');

    // Entrar sin internet con la huella vieja funciona y la reemplaza (en
    // el almacén y en el respaldo).
    expect(await service.verifyOfflineCredentials(email: 'caja@tienda.co', password: 'Clave#9'), isTrue);
    final upgraded = (await service.getOfflineCredentials())!['passwordHash'] as String;
    expect(upgraded, startsWith('pbkdf2-sha256\$'));
    expect(OfflinePasswordHasher.needsUpgrade(upgraded), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('secure_offline_credentials'), isNot(legacyCredentials));

    // Arranque 2: confirma y no queda nada sensible en preferencias.
    SecureStorageService.debugSimulateRestart();
    expect(await service.getToken(), 'jwt.token.firma');
    expect(await secureKeysInPrefs(), isEmpty);
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isTrue);
    expect(await service.verifyOfflineCredentials(email: 'caja@tienda.co', password: 'Clave#9'), isTrue);
    expect(await service.verifyOfflineCredentials(email: 'caja@tienda.co', password: 'clave#9'), isFalse);

    // Cerrar sesión borra token, refresh y usuario (en fila, sin que una
    // escritura reviva otra).
    await service.clearAuthData();
    expect(await service.getToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
    expect(await service.getLastUserId(), 'u1', reason: 'sobrevive al cierre de sesión');
  });

  test('DPAPI falla después del traslado (arranque 2): el cajero no vuelve a entrar', () async {
    final service = SecureStorageService();

    // Arranque 1: copia; la app renueva el token (va al almacén y al respaldo).
    expect(await service.getToken(), 'jwt.token.firma');
    await service.saveToken('jwt.token.renovado');
    await service.deleteRefreshToken();

    // Arranque 2: DPAPI ya no descifra (perfil movido, etc.).
    store.broken = true;
    SecureStorageService.debugSimulateRestart();

    expect(await service.getToken(), 'jwt.token.renovado', reason: 'sesión vigente desde el respaldo');
    expect(await service.getRefreshToken(), isNull, reason: 'el borrado también llegó al respaldo');
    expect(await service.getLastUserId(), 'u1');
    expect(await service.verifyOfflineCredentials(email: 'caja@tienda.co', password: 'Clave#9'), isTrue,
        reason: 'puede entrar sin internet');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsToSecureStoreMigration.copiedFlag), isFalse);

    // Arranque 3: DPAPI vuelve; se copia de nuevo desde el respaldo al día.
    store.broken = false;
    SecureStorageService.debugSimulateRestart();
    expect(await service.getToken(), 'jwt.token.renovado');
    expect(store.data['auth_token'], 'jwt.token.renovado');
  });
}
