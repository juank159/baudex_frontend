import 'package:baudex_desktop/app/core/security/offline_password_hasher.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SecureStorageService como en Windows, con el almacén seguro y las
/// preferencias de prueba en memoria (nunca el llavero ni el plist reales).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  test('Windows: la sesión guardada en preferencias pasa al almacén seguro sin perderse, '
      'y la huella vieja de la contraseña se cambia al entrar sin internet', () async {
    final legacyCredentials =
        '{"email":"caja@tienda.co","passwordHash":"${OfflinePasswordHasher.legacyHash('Clave#9', 'caja@tienda.co')}","savedAt":"2026-11-01T10:00:00.000"}';
    SharedPreferences.setMockInitialValues({
      // Formato sin prefijo "enc:" (versión aún más vieja): se lee tal cual.
      'secure_auth_token': 'jwt.token.firma',
      'secure_refresh_token': 'refresh-1',
      'secure_last_user_id': 'u1',
      'secure_offline_credentials': legacyCredentials,
    });
    FlutterSecureStorage.setMockInitialValues({});

    final service = SecureStorageService();

    // Sesión intacta tras el traslado.
    expect(await service.getToken(), 'jwt.token.firma');
    expect(await service.getRefreshToken(), 'refresh-1');
    expect(await service.getLastUserId(), 'u1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('secure_')), isEmpty,
        reason: 'ya no queda nada sensible en preferencias');
    expect(prefs.getBool(PrefsToSecureStoreMigration.doneFlag), isTrue);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'), 'jwt.token.firma');

    // Entrar sin internet con la huella vieja funciona y la reemplaza.
    expect(await service.verifyOfflineCredentials(
        email: 'caja@tienda.co', password: 'Clave#9'), isTrue);
    final upgraded = (await service.getOfflineCredentials())!['passwordHash'] as String;
    expect(upgraded, startsWith('pbkdf2-sha256\$'));
    expect(OfflinePasswordHasher.needsUpgrade(upgraded), isFalse);

    // Con la huella nueva sigue entrando; con otra clave no.
    expect(await service.verifyOfflineCredentials(
        email: 'caja@tienda.co', password: 'Clave#9'), isTrue);
    expect(await service.verifyOfflineCredentials(
        email: 'caja@tienda.co', password: 'clave#9'), isFalse);

    // Cerrar sesión borra token, refresh y usuario (en paralelo, sin que
    // una escritura reviva otra).
    await service.clearAuthData();
    expect(await service.getToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
    expect(await service.getLastUserId(), 'u1', reason: 'sobrevive al cierre de sesión');
  });
}
