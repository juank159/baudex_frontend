import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'incremental_pull_test.dart' show FakeServer, uuid, at;

/// Versión nueva instalada: los módulos ya descargados se vuelven a bajar
/// solos, sin dejar de mostrar lo del equipo (antes había que forzarlo
/// desde Diagnóstico).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeServer server;
  late Map<String, String> local;

  FullSyncService device(String fingerprint) {
    final sync = FullSyncService(IsarDatabase.instance)
      ..debugChangesClient = server
      ..debugOrganizationKey = 'org-1'
      ..debugInstallFingerprint = (() async => fingerprint)
      ..debugChangeHandlers = {
        'products': FullSyncService.debugHandler(
          apply: (items) async {
            for (final i in items) {
              local[i['id'] as String] = server.rows[i['id']]!.stamp;
            }
            return <String>{};
          },
          delete: (ids) async => 0,
          sweep: (seen) async {
            final stale = local.keys.where((id) => !seen.contains(id)).toList();
            stale.forEach(local.remove);
            return stale.length;
          },
        ),
      };
    return sync;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    local = {};
    for (var i = 1; i <= 50; i++) {
      server.put(uuid(i), at(i));
    }
  });

  Future<void> firstInstall() async {
    final sync = device('1.0.0+1|100');
    await sync.debugCheckAppUpdate();
    await sync.debugPullChanges('products');
    expect(local.length, 50);
  }

  test('misma instalación: solo baja lo que cambió', () async {
    await firstInstall();
    final again = device('1.0.0+1|100');
    await again.debugCheckAppUpdate();
    expect(again.hasPendingFullDownload, isFalse);
    server.sinceLog.clear();
    await again.debugPullChanges('products');
    expect(server.sinceLog, [server.now]);
  });

  test('versión nueva: vuelve a bajar todo, sin dejar de leer del equipo', () async {
    await firstInstall();
    // Un registro que el equipo tenía viejo y otro que ya no existe.
    local[uuid(3)] = 'viejo';
    local['00000000-0000-0000-0000-999999999999'] = at(1);

    final updated = device('1.0.0+1|200');
    await updated.debugCheckAppUpdate();
    expect(updated.hasPendingFullDownload, isTrue);
    // Mientras baja, las pantallas siguen usando lo del equipo.
    expect(await updated.isModuleDownloaded('products'), isTrue);

    server.sinceLog.clear();
    await updated.debugPullChanges('products');
    expect(server.sinceLog, contains(SyncChangesClient.epoch));
    expect(local[uuid(3)], server.rows[uuid(3)]!.stamp);
    expect(local.containsKey('00000000-0000-0000-0000-999999999999'), isFalse);
    expect(local.length, 50);
    expect(updated.hasPendingFullDownload, isFalse);

    // Y no se repite en la siguiente apertura.
    final next = device('1.0.0+1|200');
    await next.debugCheckAppUpdate();
    expect(next.hasPendingFullDownload, isFalse);
  });

  test('equipo nuevo: no hay nada que actualizar (sigue la descarga normal)', () async {
    final sync = device('1.0.0+1|300');
    await sync.debugCheckAppUpdate();
    expect(sync.hasPendingFullDownload, isFalse);
    expect(await sync.isModuleDownloaded('products'), isFalse);
  });
}
