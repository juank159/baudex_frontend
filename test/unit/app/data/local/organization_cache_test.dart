// La sincronización pregunta "¿de qué negocio soy?" por cada módulo en cada
// descarga. Antes cada pregunta leía el almacén de sesión (en Windows, abrir
// y descifrar un archivo); ahora se recuerda en memoria y se olvida al
// cambiar la sesión.
import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingStore extends TestFlutterSecureStoragePlatform {
  _CountingStore(super.data);
  int reads = 0;

  @override
  Future<String?> read({required String key, required Map<String, String> options}) {
    reads++;
    return super.read(key: key, options: options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _CountingStore store;
  late FullSyncService sync;

  String user(String organization) => '{"id":"u1","organizationId":"$organization"}';

  setUp(() {
    Get.reset();
    SecureStorageService.debugSimulateRestart();
    store = _CountingStore({ApiConstants.userKey: user('org-1')});
    FlutterSecureStoragePlatform.instance = store;
    SharedPreferences.setMockInitialValues({
      'sync_wm_v1|org-1|invoices': '2026-11-01T00:00:00.000000Z',
    });
    Get.put(SecureStorageService());
    sync = FullSyncService(IsarDatabase.instance);
  });
  tearDown(Get.reset);

  test('50 consultas seguidas leen el almacén de sesión una sola vez', () async {
    expect(await sync.isModuleDownloaded('invoices'), isTrue);
    final afterFirst = store.reads;
    expect(afterFirst, greaterThan(0));
    for (var i = 0; i < 50; i++) {
      expect(await sync.isModuleDownloaded('invoices'), isTrue);
    }
    expect(store.reads, afterFirst);
  });

  test('al cambiar la sesión se vuelve a leer: otro negocio no hereda las '
      'marcas del anterior', () async {
    expect(await sync.isModuleDownloaded('invoices'), isTrue);

    // Cierra sesión y entra otro negocio.
    store.data[ApiConstants.userKey] = user('org-2');
    sync.forgetOrganization();
    expect(await sync.isModuleDownloaded('invoices'), isFalse);
  });

  test('sin sesión no se recuerda nada: al entrar se usa el negocio real', () async {
    store.data.remove(ApiConstants.userKey);
    expect(await sync.isModuleDownloaded('invoices'), isFalse);
    store.data[ApiConstants.userKey] = user('org-1');
    expect(await sync.isModuleDownloaded('invoices'), isTrue);
  });
}
