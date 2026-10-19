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

/// Internet lento: páginas grandes no alcanzan a llegar (tiempo de espera).
class SlowServer extends FakeServer {
  final int maxLimit;
  final List<int> limits = [];
  SlowServer(this.maxLimit);

  @override
  Future<SyncChangesPage> fetch(String entity,
      {required String since, String? afterId, int limit = 200}) {
    limits.add(limit);
    if (limit > maxLimit) {
      throw Exception('DioException [receive timeout]: tiempo de espera agotado');
    }
    return super.fetch(entity, since: since, afterId: afterId, limit: limit);
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
    await sync.debugPullChanges('invoices');
    expect(local.length, 450);
    // Histórico completo: 200 + 200 + 50 (más la fase de "lo reciente").
    expect(server.sinceLog.where((s) => s == SyncChangesClient.epoch).length, 1);

    // Segunda vez: pide desde la marca del servidor, no desde el principio.
    server.requests = 0;
    await sync.debugPullChanges('invoices');
    expect(server.sinceLog.last, server.now);
    expect(server.requests, 1);
  });

  test('descarga completa: lo de los últimos días llega primero', () async {
    final now = DateTime.now().toUtc();
    String ago(Duration d) => now.subtract(d).toIso8601String();
    server.put(uuid(1), ago(const Duration(days: 300))); // viejo
    server.put(uuid(2), ago(const Duration(hours: 2))); // de hoy
    final order = <String>[];
    final handlers = sync.debugChangeHandlers!;
    final original = handlers['invoices'];
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          order.addAll(items.map((i) => i['id'] as String));
          for (final i in items) {
            local[i['id'] as String] = server.rows[i['id']]!.stamp;
          }
          return <String>{};
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    await sync.debugPullChanges('invoices');
    expect(order.first, uuid(2)); // lo de hoy antes que el histórico
    expect(local.keys.toSet(), {uuid(1), uuid(2)});
    sync.debugChangeHandlers = {'invoices': original!};
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

  test('tras reiniciar la app, la descarga completa sigue donde quedó', () async {
    for (var i = 1; i <= 1500; i++) {
      server.put(uuid(i), '2025-01-01T00:${(i ~/ 60 % 60).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}.000000Z');
    }
    server.delay = const Duration(milliseconds: 40);
    await sync.debugPullChanges('invoices',
        deadline: DateTime.now().add(const Duration(milliseconds: 150)));
    final firstRun = local.length;
    expect(firstRun, inInclusiveRange(1, 1499));

    // "Reinicio": servicio nuevo (sin memoria), mismo almacenamiento.
    final restarted = FullSyncService(IsarDatabase.instance)
      ..debugChangesClient = server
      ..debugOrganizationKey = 'org-1'
      ..debugChangeHandlers = sync.debugChangeHandlers;
    server.delay = Duration.zero;
    server.sinceLog.clear();
    await restarted.debugPullChanges('invoices');
    expect(local.length, 1500);
    expect(server.sinceLog.contains(SyncChangesClient.epoch), isFalse,
        reason: 'no debe volver a empezar desde el principio');
    // Reanudada tras reinicio: no se limpia (no tiene todos los IDs vistos).
    expect(deletedLocally, isEmpty);
    // Terminada: la siguiente ya es incremental.
    await restarted.debugPullChanges('invoices');
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

  test('lo que el servidor repite por el margen no se reaplica ni cuenta como cambio', () async {
    final now = DateTime.now().toUtc();
    String ago(int seconds) =>
        now.subtract(Duration(seconds: seconds)).toIso8601String();
    server.now = ago(0);
    server.put(uuid(1), ago(30));
    server.put(uuid(2), ago(20));
    expect(await sync.debugPullChanges('invoices'), 2);

    // El servidor devuelve una marca 2 minutos atrás: repite los mismos dos.
    server.now = ago(120);
    await sync.debugPullChanges('invoices'); // guarda la marca con margen
    var applies = 0;
    final real = sync.debugChangeHandlers!['invoices']!;
    sync.debugChangeHandlers = {
      'invoices': FullSyncService.debugHandler(
        apply: (items) async {
          applies += items.length;
          return (real as dynamic).apply(items) as Future<Set<String>>;
        },
        delete: (ids) async => 0,
        sweep: (seen) async => 0,
      ),
    };
    expect(await sync.debugPullChanges('invoices'), 0);
    expect(applies, 0);

    // Uno cambia de verdad (marca nueva): ese sí se aplica.
    server.put(uuid(2), ago(1));
    expect(await sync.debugPullChanges('invoices'), 1);
    expect(applies, 1);
    expect(local[uuid(2)], server.rows[uuid(2)]!.stamp);
  });

  test('uno protegido por cambios locales se vuelve a intentar aunque llegue igual', () async {
    final now = DateTime.now().toUtc();
    String ago(int seconds) =>
        now.subtract(Duration(seconds: seconds)).toIso8601String();
    server.now = ago(120);
    server.put(uuid(1), ago(30));
    protectedIds.add(uuid(1));
    await sync.debugPullChanges('invoices');
    expect(local.containsKey(uuid(1)), isFalse);

    // Ya subió el cambio local: la misma versión del servidor sí se guarda.
    protectedIds.clear();
    await sync.debugPullChanges('invoices');
    expect(local[uuid(1)], server.rows[uuid(1)]!.stamp);
  });

  test('un módulo solo cuenta como descargado cuando su descarga completa terminó', () async {
    for (var i = 1; i <= 450; i++) {
      server.put(uuid(i), at(i % 60));
    }
    // Nada descargado todavía.
    expect(await sync.isModuleDownloaded('invoices'), isFalse);

    // Descarga cortada por tiempo: hay datos en el equipo, pero incompletos.
    await sync.debugPullChanges('invoices',
        deadline: DateTime.now().subtract(const Duration(seconds: 1)));
    expect(await sync.isModuleDownloaded('invoices'), isFalse);

    // Termina la descarga: ahora sí.
    await sync.debugPullChanges('invoices');
    expect(local.length, 450);
    expect(await sync.isModuleDownloaded('invoices'), isTrue);
  });

  test('con internet lento la descarga achica las páginas y termina completa', () async {
    final slow = SlowServer(50);
    for (var i = 1; i <= 230; i++) {
      slow.put(uuid(i), at(i % 60));
    }
    sync.debugChangesClient = slow;
    server.rows.addAll(slow.rows); // el manejador de prueba lee las marcas de `server`
    await sync.debugPullChanges('invoices');
    expect(local.length, 230);
    expect(await sync.isModuleDownloaded('invoices'), isTrue);
    expect(slow.limits.first, 200); // empezó con páginas grandes…
    expect(slow.limits.last, lessThanOrEqualTo(50)); // …y bajó hasta que pasaron
  });
}
