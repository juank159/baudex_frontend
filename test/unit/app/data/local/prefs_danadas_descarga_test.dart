// Qué descarga la app según el estado de las preferencias del equipo
// (donde viven las marcas "hasta dónde bajé"): sanas, vacías (recién
// apartadas) y dañadas. Servidor de mentira con 6.055 facturas.
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../core/storage/prefs_danadas_sesion_test.dart' show ArchivoDePreferencias;
import 'incremental_pull_test.dart' show FakeServer, uuid;

class _Red implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Future<bool> canReachServer({Duration timeout = const Duration(seconds: 5)}) async => true;
  @override
  Future<bool> get hasPhysicalConnection async => true;
  @override
  bool get isServerReachable => true;
  @override
  void markServerUnreachable() {}
  @override
  void resetServerReachability() {}
  @override
  void startMonitoring() {}
  @override
  void dispose() {}
}

const facturas = 6055;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ArchivoDePreferencias archivo;
  late FakeServer servidor;
  late FullSyncService sync;
  late int guardadas;

  /// Cierra y abre la app: se olvida lo que estaba en memoria.
  void abrirApp() {
    SharedPreferences.resetStatic();
    sync = FullSyncService(IsarDatabase.instance);
    sync.debugChangesClient = servidor;
    sync.debugOrganizationKey = 'org-1';
    sync.debugInstallFingerprint = () async => '1.0.10+1|1';
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          guardadas += items.length;
          return <String>{};
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    servidor.requests = 0;
    guardadas = 0;
    SyncWatermarkStore.debugForgetMemory();
  }

  setUp(() {
    Get.reset();
    Get.put<NetworkInfo>(_Red());
    archivo = ArchivoDePreferencias();
    SharedPreferencesStorePlatform.instance = archivo;
    servidor = FakeServer();
    final ahora = DateTime.now().toUtc();
    for (var i = 1; i <= facturas; i++) {
      // Historia de un año, unas pocas de los últimos días.
      servidor.put(
        uuid(i),
        ahora.subtract(Duration(minutes: 90 * (facturas - i) + 600)).toIso8601String(),
      );
    }
    servidor.now = ahora.toIso8601String();
    abrirApp();
  });
  tearDown(Get.reset);

  test('sanas: la primera vez baja todo; al reabrir, 1 petición y 0 facturas', () async {
    await sync.debugPullChanges('invoices');
    expect(guardadas, facturas);

    abrirApp();
    await sync.debugPullChanges('invoices');
    expect(guardadas, 0);
    expect(servidor.requests, 1);
  });

  test('vacías (recién apartadas): vuelve a bajar las $facturas facturas', () async {
    await sync.debugPullChanges('invoices');
    archivo.apartar();

    abrirApp();
    await sync.debugPullChanges('invoices');
    expect(guardadas, facturas);
    expect(servidor.requests, greaterThan(30), reason: 'páginas de 200');
  });

  test('dañadas: la descarga ya no muere (antes no bajaba NADA y terminaba '
      'con error); sin marca legible vuelve a bajar todo en segundo plano', () async {
    await sync.debugPullChanges('invoices');
    archivo.danado = true;

    abrirApp();
    sync.debugLocalCounts = {'invoices': () async => facturas};
    expect(await sync.isModuleDownloaded('invoices'), isTrue,
        reason: 'las pantallas siguen leyendo del equipo');
    expect(await sync.debugPullChanges('invoices'), isNotNull);
    expect(guardadas, facturas);

    // En la misma sesión ya es "solo lo que cambió" (marca en memoria).
    servidor.requests = 0;
    guardadas = 0;
    await sync.debugPullChanges('invoices');
    expect(servidor.requests, 1);
    expect(guardadas, 0);

    final resultado = await sync.performFullSync(skipCleanup: true);
    expect(resultado.errors['fatal'], isNull, reason: '${resultado.errors}');
  });

  test('marcas perdidas con datos en el equipo: las pantallas siguen leyendo '
      'del equipo mientras se vuelve a bajar todo', () async {
    await sync.debugPullChanges('invoices');
    archivo.apartar();

    abrirApp();
    sync.debugLocalCounts = {'invoices': () async => facturas};
    expect(await sync.isModuleDownloaded('invoices'), isTrue, reason: 'antes de bajar');

    var consultasDurante = 0;
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          guardadas += items.length;
          expect(await sync.isModuleDownloaded('invoices'), isTrue,
              reason: 'durante la descarga');
          consultasDurante++;
          return <String>{};
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    await sync.debugPullChanges('invoices');
    expect(guardadas, facturas, reason: 'igual se vuelve a bajar todo');
    expect(consultasDurante, greaterThan(20));
    expect(await sync.isModuleDownloaded('invoices'), isTrue);

    // Y al reabrir vuelve a ser "solo lo que cambió".
    abrirApp();
    sync.debugLocalCounts = {'invoices': () async => facturas};
    await sync.debugPullChanges('invoices');
    expect(servidor.requests, 1);
  });

  test('equipo nuevo (sin registros): hasta terminar la primera descarga las '
      'pantallas NO se fían del equipo, aunque se cierre a la mitad', () async {
    var enEquipo = 0;
    sync.debugLocalCounts = {'invoices': () async => enEquipo};
    expect(await sync.isModuleDownloaded('invoices'), isFalse);

    var paginas = 0;
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          enEquipo += items.length;
          expect(await sync.isModuleDownloaded('invoices'), isFalse);
          if (++paginas == 3) throw StateError('se cerró la app');
          return <String>{};
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    expect(await sync.debugPullChanges('invoices'), isNull);
    expect(enEquipo, greaterThan(0));

    // Al reabrir sigue siendo una primera descarga a medias.
    abrirApp();
    sync.debugLocalCounts = {'invoices': () async => enEquipo};
    expect(await sync.isModuleDownloaded('invoices'), isFalse);
  });
}
