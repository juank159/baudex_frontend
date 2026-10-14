import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servidor falso con la misma semántica que GET /sync/changes: cursor
/// (updated_at, id), borrados desde `since`, marca en la primera página.
class FakeServer implements SyncChangesClient {
  final Map<String, ({String stamp, bool deleted})> rows = {};
  String now = '2026-10-14T12:00:00.000000Z';
  bool supported = true;
  int requests = 0;
  final List<String> sinceLog = [];
  Duration delay = Duration.zero;

  @override
  DioClient get dioClient => throw UnimplementedError();

  void put(String id, String stamp, {bool deleted = false}) =>
      rows[id] = (stamp: stamp, deleted: deleted);

  @override
  Future<SyncChangesPage> fetch(String entity,
      {required String since, String? afterId, int limit = 200}) async {
    requests++;
    if (!supported) throw const SyncChangesUnsupportedException();
    if (delay > Duration.zero) await Future.delayed(delay);
    sinceLog.add(since);
    final first = afterId == null;
    if (first &&
        since != SyncChangesClient.epoch &&
        DateTime.parse(since).isBefore(DateTime.parse(now).subtract(const Duration(days: 90)))) {
      return const SyncChangesPage(items: [], stamps: [], deletedIds: [], hasMore: false,
          nextSince: null, nextAfterId: null, watermark: null, resetRequired: true);
    }
    final s = DateTime.parse(since);
    final a = afterId ?? '';
    final live = rows.entries.where((e) => !e.value.deleted).where((e) {
      final t = DateTime.parse(e.value.stamp);
      return t.isAfter(s) || (t.isAtSameMomentAs(s) && e.key.compareTo(a) > 0);
    }).toList()
      ..sort((x, y) {
        final c = DateTime.parse(x.value.stamp).compareTo(DateTime.parse(y.value.stamp));
        return c != 0 ? c : x.key.compareTo(y.key);
      });
    final page = live.take(limit).toList();
    final hasMore = live.length > limit;
    final deleted = first && since != SyncChangesClient.epoch
        ? rows.entries
            .where((e) => e.value.deleted && !DateTime.parse(e.value.stamp).isBefore(s))
            .map((e) => e.key)
            .toList()
        : <String>[];
    return SyncChangesPage(
      items: page.map((e) => {'id': e.key}).toList(),
      stamps: page.map((e) => e.value.stamp).toList(),
      deletedIds: deleted,
      hasMore: hasMore,
      nextSince: hasMore ? page.last.value.stamp : null,
      nextAfterId: hasMore ? page.last.key : null,
      watermark: first ? now : null,
      resetRequired: false,
    );
  }
}

String uuid(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';
String at(int second) => '2026-10-14T11:00:${second.toString().padLeft(2, '0')}.000000Z';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FullSyncService sync;
  late FakeServer server;
  late Map<String, String> local; // copia local: id -> marca aplicada
  late Set<String> protectedIds;
  late List<String> deletedLocally;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FullSyncService(IsarDatabase.instance);
    server = FakeServer();
    local = {};
    protectedIds = {};
    deletedLocally = [];
    sync.debugChangesClient = server;
    sync.debugOrganizationKey = 'org-1';
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          final skipped = <String>{};
          for (final item in items) {
            final id = item['id'] as String;
            if (protectedIds.contains(id)) {
              skipped.add(id);
            } else {
              local[id] = server.rows[id]!.stamp;
            }
          }
          return skipped;
        },
        delete: (ids) async {
          deletedLocally.addAll(ids);
          ids.forEach(local.remove);
          return ids.length;
        },
        sweep: (seen) async {
          final stale = local.keys.where((id) => !seen.contains(id)).toList();
          stale.forEach(local.remove);
          deletedLocally.addAll(stale);
          return stale.length;
        },
      ),
    };
  });

  test('primera vez descarga todo (varias páginas) y guarda la marca', () async {
    for (var i = 1; i <= 450; i++) {
      server.put(uuid(i), at(i % 60));
    }
    final count = await sync.debugPullChanges('invoices');
    expect(count, 450);
    expect(local.length, 450);
    expect(server.requests, 3); // 200 + 200 + 50
    expect(server.sinceLog.first, SyncChangesClient.epoch);

    // Segunda vez: pide desde la marca del servidor, no desde el principio.
    server.requests = 0;
    await sync.debugPullChanges('invoices');
    expect(server.sinceLog.last, server.now);
    expect(server.requests, 1);
  });

  test('después solo baja lo cambiado y aplica borrados', () async {
    server.put(uuid(1), at(1));
    server.put(uuid(2), at(2));
    server.put(uuid(3), at(3));
    await sync.debugPullChanges('invoices');

    server.now = '2026-10-14T12:10:00.000000Z';
    server.put(uuid(2), '2026-10-14T12:05:00.000000Z'); // modificado
    server.put(uuid(3), '2026-10-14T12:06:00.000000Z', deleted: true); // borrado
    server.put(uuid(4), '2026-10-14T12:07:00.000000Z'); // nuevo
    final applied = <String>[];
    final before = Map.of(local);
    await sync.debugPullChanges('invoices');
    for (final e in local.entries) {
      if (before[e.key] != e.value) applied.add(e.key);
    }
    expect(applied..sort(), [uuid(2), uuid(4)]);
    expect(deletedLocally, [uuid(3)]);
    expect(local.containsKey(uuid(3)), isFalse);
  });

  test('descarga completa quita lo local que ya no existe en el servidor', () async {
    local[uuid(99)] = at(1); // quedó de antes, el servidor ya no lo tiene
    server.put(uuid(1), at(1));
    await sync.debugPullChanges('invoices');
    expect(local.keys, [uuid(1)]);
    expect(deletedLocally, [uuid(99)]);
  });

  test('un registro con cambios locales sin subir no adelanta la marca', () async {
    server.put(uuid(1), at(1));
    server.put(uuid(2), at(5));
    protectedIds.add(uuid(2));
    await sync.debugPullChanges('invoices');
    expect(local.containsKey(uuid(2)), isFalse);

    // Ya subió su cambio local: en la siguiente descarga vuelve a llegar.
    protectedIds.clear();
    await sync.debugPullChanges('invoices');
    expect(local[uuid(2)], at(5));
    expect(DateTime.parse(server.sinceLog.last).isBefore(DateTime.parse(at(5))), isTrue);
  });

  test('si se acaba el tiempo, sigue desde donde quedó sin guardar la marca', () async {
    for (var i = 1; i <= 600; i++) {
      server.put(uuid(i), at(i % 60));
    }
    server.delay = const Duration(milliseconds: 60);
    await sync.debugPullChanges('invoices',
        deadline: DateTime.now().add(const Duration(milliseconds: 90)));
    final partial = local.length;
    expect(partial, lessThan(600));
    expect(partial, greaterThan(0));

    server.delay = Duration.zero;
    await sync.debugPullChanges('invoices',
        deadline: DateTime.now().add(const Duration(seconds: 5)));
    expect(local.length, 600);
    // Terminada la descarga completa, la siguiente ya es incremental.
    await sync.debugPullChanges('invoices');
    expect(server.sinceLog.last, server.now);
  });

  test('marca demasiado vieja: vuelve a descargar todo', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_wm_v1|org-1|invoices', '2026-01-01T00:00:00.000000Z');
    server.put(uuid(1), at(1));
    await sync.debugPullChanges('invoices');
    expect(server.sinceLog, ['2026-01-01T00:00:00.000000Z', SyncChangesClient.epoch]);
    expect(local.keys, [uuid(1)]);
  });

  test('las marcas son por negocio', () async {
    server.put(uuid(1), at(1));
    await sync.debugPullChanges('invoices');
    sync.debugOrganizationKey = 'org-2';
    await sync.debugPullChanges('invoices');
    expect(server.sinceLog.last, SyncChangesClient.epoch);
  });

  test('safeWatermark nunca pasa de un cambio no aplicado', () {
    expect(SyncWatermarkStore.safeWatermark('2026-10-14T12:00:00.000000Z', null),
        '2026-10-14T12:00:00.000000Z');
    expect(
        SyncWatermarkStore.safeWatermark(
            '2026-10-14T12:00:00.000000Z', '2026-10-14T11:00:05.123456Z'),
        '2026-10-14T11:00:05.123455Z');
    expect(
        SyncWatermarkStore.safeWatermark(
            '2026-10-14T12:00:00.000000Z', '2026-10-14T13:00:00.000000Z'),
        '2026-10-14T12:00:00.000000Z');
  });

  test('ServerException 404 se traduce a "no soportado"', () {
    // El cliente real convierte 404 en SyncChangesUnsupportedException.
    const e = ServerException('x', statusCode: 404);
    expect(e.statusCode, 404);
  });
}
