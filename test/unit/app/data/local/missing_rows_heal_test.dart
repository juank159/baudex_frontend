import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'incremental_pull_test.dart' show FakeServer, uuid, at;

/// El equipo perdió clientes (versiones anteriores los borraban al crear o
/// editar uno) y la descarga "solo lo que cambió" no los devolvía.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FullSyncService sync;
  late FakeServer server;
  late Map<String, String> local;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FullSyncService(IsarDatabase.instance);
    server = FakeServer();
    local = {};
    sync.debugChangesClient = server;
    sync.debugOrganizationKey = 'org-1';
    sync.debugChangeHandlers = {
      'customers': FullSyncService.debugHandler(
        apply: (items) async {
          for (final i in items) {
            local[i['id'] as String] = server.rows[i['id']]!.stamp;
          }
          return <String>{};
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    sync.debugSetCountCheck('customers',
        server: () async => server.rows.length, local: () async => local.length);
  });

  test('si el equipo tiene menos que el servidor, vuelve a bajar todo',
      () async {
    for (var i = 1; i <= 119; i++) {
      server.put(uuid(i), at(i % 60));
    }
    await sync.debugPullChanges('customers');
    expect(local.length, 119);

    // Se pierden 104 en el equipo; la marca sigue guardada.
    local.removeWhere((id, _) => int.parse(id.substring(24)) > 15);
    expect(local.length, 15);

    // Siguiente revisión (pasados los 15 min): detecta la diferencia...
    final fresh = FullSyncService(IsarDatabase.instance)
      ..debugChangesClient = server
      ..debugOrganizationKey = 'org-1'
      ..debugChangeHandlers = sync.debugChangeHandlers;
    fresh.debugSetCountCheck('customers',
        server: () async => server.rows.length, local: () async => local.length);
    await fresh.debugPullChanges('customers');
    // ...y la siguiente descarga es completa: vuelven los 119.
    expect(await fresh.isModuleDownloaded('customers'), isFalse);
    server.sinceLog.clear();
    await fresh.debugPullChanges('customers');
    expect(server.sinceLog, contains(SyncChangesClient.epoch));
    expect(local.length, 119);
  });

  test('si el equipo tiene todos, no se vuelve a descargar', () async {
    for (var i = 1; i <= 20; i++) {
      server.put(uuid(i), at(i));
    }
    await sync.debugPullChanges('customers');
    expect(await sync.isModuleDownloaded('customers'), isTrue);
    server.sinceLog.clear();
    await sync.debugPullChanges('customers');
    expect(server.sinceLog, [server.now]);
  });

  test('sin internet para contar, no cambia nada', () async {
    server.put(uuid(1), at(1));
    sync.debugSetCountCheck('customers',
        server: () async => throw Exception('sin conexión'),
        local: () async => 0);
    await sync.debugPullChanges('customers');
    expect(await sync.isModuleDownloaded('customers'), isTrue);
  });
}
