import 'dart:io';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_response_models.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_stats_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/domain/services/invoice_history_lookup.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/cancel_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/confirm_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/delete_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_stats_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoices_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_overdue_invoices_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/search_invoices_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_list_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_stats_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'invoice_perf_fixture.dart';

class _Net extends Mock implements NetworkInfo {}

class _Local extends Mock implements InvoiceLocalDataSource {}

class _Sync extends Mock implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

/// Servidor de mentiras LENTO: responde lo mismo que hay en el equipo, tras
/// [delay]. Cuenta cuántas veces lo llaman.
class _Remote extends Mock implements InvoiceRemoteDataSource {
  _Remote(this.delay);
  final Duration delay;
  int listCalls = 0, statsCalls = 0, overdueCalls = 0;
  static const onlyOnServer = 'VIEJA-SOLO-SERVIDOR';

  @override
  Future<InvoiceResponseModel> getInvoices(InvoiceQueryParams params) async {
    listCalls++;
    await Future.delayed(delay);
    // Una factura antigua que SOLO está en el servidor (aún no ha bajado).
    if (params.search == onlyOnServer) {
      final one = (await InvoiceOfflineRepositorySimple()
              .getInvoices(page: 1, limit: 1))
          .getOrElse(() => throw 'falló');
      return InvoiceResponseModel(
        data: one.data.map(InvoiceModel.fromEntity).toList(),
        meta: one.meta,
      );
    }
    final page = (await InvoiceOfflineRepositorySimple().getInvoices(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    ))
        .getOrElse(() => throw 'falló');
    return InvoiceResponseModel(
      data: page.data.map(InvoiceModel.fromEntity).toList(),
      meta: page.meta,
    );
  }

  @override
  Future<InvoiceStatsModel> getInvoiceStats() async {
    statsCalls++;
    await Future.delayed(delay);
    return const InvoiceStatsModel(
      total: 0, draft: 0, pending: 0, paid: 0, overdue: 0, cancelled: 0,
      partiallyPaid: 0, totalSales: 0, pendingAmount: 0, overdueAmount: 0,
    );
  }

  @override
  Future<List<InvoiceModel>> getOverdueInvoices() async {
    overdueCalls++;
    await Future.delayed(delay);
    return const [];
  }
}

/// Simulaciones de la lista de facturas con el controlador y el repositorio
/// REALES sobre una base Isar TEMPORAL (nunca la real). Tamaño con
/// `BAUDEX_PERF_INVOICES` (5000, 20000, 50000) y espera del servidor con
/// `BAUDEX_PERF_SERVER_MS` (por defecto 4000).
///
///   BAUDEX_PERF_INVOICES=50000 flutter test test/perf/invoice_list_scenarios_perf_test.dart
void main() {
  final count =
      int.tryParse(Platform.environment['BAUDEX_PERF_INVOICES'] ?? '') ?? 5000;
  final serverMs =
      int.tryParse(Platform.environment['BAUDEX_PERF_SERVER_MS'] ?? '') ?? 4000;
  late Isar isar;
  late _Remote remote;
  late _Net net;
  late InvoiceRepository repo;
  var rssBefore = 0;

  void out(String label, Object value) =>
      // ignore: avoid_print
      print('SIM $count | $label: $value');

  setUpAll(() async {
    tzdata.initializeTimeZones();
    rssBefore = ProcessInfo.currentRss;
    final w = Stopwatch()..start();
    isar = await openBigInvoiceDb(invoices: count);
    out('base creada en', '${w.elapsedMilliseconds} ms');
    final size = await isar.getSize();
    out('tamaño de la base', '${(size / 1048576).toStringAsFixed(0)} MB');
  });
  tearDownAll(() => closeBigInvoiceDb(isar));

  void wire({required bool moduleReady, bool online = true}) {
    Get.testMode = true;
    resetLocalCollectionsReady();
    net = _Net();
    when(() => net.isConnected).thenAnswer((_) async => online);
    when(net.resetServerReachability).thenReturn(null);
    when(net.markServerUnreachable).thenReturn(null);
    final local = _Local();
    when(() => local.cacheInvoices(any())).thenAnswer((_) async {});
    when(() => local.cacheInvoiceStats(any())).thenAnswer((_) async {});
    when(() => local.getCachedInvoices()).thenAnswer((_) async => []);
    final sync = _Sync();
    when(() => sync.isModuleDownloaded(any()))
        .thenAnswer((_) async => moduleReady);
    Get.put<FullSyncService>(sync);
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    remote = _Remote(Duration(milliseconds: serverMs));
    repo = InvoiceRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: net,
      offlineRepository: InvoiceOfflineRepositorySimple(),
    );
    InvoiceListController.invalidateCache();
  }

  InvoiceListController newController() => InvoiceListController(
        getInvoicesUseCase: GetInvoicesUseCase(repo),
        searchInvoicesUseCase: SearchInvoicesUseCase(repo),
        deleteInvoiceUseCase: DeleteInvoiceUseCase(repo),
        confirmInvoiceUseCase: ConfirmInvoiceUseCase(repo),
        cancelInvoiceUseCase: CancelInvoiceUseCase(repo),
        getInvoiceByIdUseCase: GetInvoiceByIdUseCase(repo),
        historyLookup: repo as InvoiceHistoryLookup,
      );

  /// Espera a que [done] sea cierto; devuelve los ms (o -1 si pasó [maxMs]).
  Future<int> until(bool Function() done, {int maxMs = 30000}) async {
    final w = Stopwatch()..start();
    while (!done()) {
      if (w.elapsedMilliseconds > maxMs) return -1;
      await Future.delayed(const Duration(milliseconds: 1));
    }
    return w.elapsedMilliseconds;
  }

  setUpAll(() {
    registerFallbackValue(const InvoiceQueryParams());
    registerFallbackValue(const InvoiceStatsModel(
      total: 0, draft: 0, pending: 0, paid: 0, overdue: 0, cancelled: 0,
      partiallyPaid: 0, totalSales: 0, pendingAmount: 0, overdueAmount: 0,
    ));
    registerFallbackValue(<InvoiceModel>[]);
  });
  tearDown(Get.reset);

  /// Abre la pantalla (crea el controlador, como el binding) y hace las
  /// acciones del usuario. [label] distingue el estado del equipo.
  ///
  /// GUARDIA: con facturas en el equipo, ninguna acción espera al servidor
  /// (cada una responde en menos de [maxMs]) y el servidor solo se consulta
  /// por detrás cuando una búsqueda no encuentra nada y el historial baja.
  Future<void> scenario(String label,
      {required bool moduleReady, bool online = true}) async {
    const maxMs = 1500; // incluye la pausa de teclado de 500 ms
    void fast(int ms, String what) => expect(ms, inInclusiveRange(0, maxMs),
        reason: '$label: "$what" no puede esperar al servidor');
    wire(moduleReady: moduleReady, online: online);
    // Como el binding real: primero las estadísticas, luego la lista.
    final statsW = Stopwatch()..start();
    final stats = Get.put(InvoiceStatsController(
      getInvoiceStatsUseCase: GetInvoiceStatsUseCase(repo),
      getOverdueInvoicesUseCase: GetOverdueInvoicesUseCase(repo),
    ));
    var c = Get.put(newController());
    final open = await until(() => c.filteredInvoices.isNotEmpty);
    out('$label | abrir: primera página lista',
        '$open ms (${c.filteredInvoices.length} filas, servidor ${remote.listCalls} llamadas)');
    fast(open, 'abrir');
    await until(() => !stats.isLoading);
    final statsMs = statsW.elapsedMilliseconds;
    out('$label | abrir: estadísticas del panel',
        '$statsMs ms (servidor ${remote.statsCalls + remote.overdueCalls} llamadas)');
    fast(statsMs, 'estadísticas');
    await until(() => !c.isLoading);
    await Future.delayed(const Duration(milliseconds: 700));
    expect(c.isHistoryDownloading, !moduleReady,
        reason: 'aviso de historial bajando');

    // Volver a la pantalla (el controlador es permanente): refresco.
    var t = Stopwatch()..start();
    await c.refreshAllData();
    out('$label | volver de Productos: refresco',
        '${t.elapsedMilliseconds} ms (filas a la vista mientras tanto: ${c.filteredInvoices.length})');
    fast(t.elapsedMilliseconds, 'volver');

    // Cerrar la pantalla del todo y abrir de nuevo (controlador nuevo, sin
    // caché en memoria).
    await Get.delete<InvoiceListController>(force: true);
    InvoiceListController.invalidateCache();
    c = Get.put(newController());
    var ms = await until(() => c.filteredInvoices.isNotEmpty);
    out('$label | cerrar y abrir de nuevo', '$ms ms');
    fast(ms, 'cerrar y abrir');
    await until(() => !c.isLoading);

    // Búsqueda por número (incluye la pausa de 500 ms del teclado).
    final target = 'FV-${(count ~/ 2).toString().padLeft(6, '0')}';
    c.searchController.text = target;
    ms = await until(() =>
        !c.isLoading &&
        c.searchQuery == target &&
        c.filteredInvoices.length == 1);
    out('$label | buscar número $target', '$ms ms (500 de pausa de teclado)');
    fast(ms, 'buscar número');

    // Búsqueda por cliente.
    c.searchController.text = 'Cliente12';
    ms = await until(() =>
        !c.isLoading &&
        c.searchQuery == 'Cliente12' &&
        c.filteredInvoices.isNotEmpty &&
        c.filteredInvoices.first.number != target);
    out('$label | buscar cliente "Cliente12"',
        '$ms ms (500 de pausa; ${c.totalItems} resultados)');
    fast(ms, 'buscar cliente');
    expect(remote.listCalls, 0,
        reason: '$label: con datos en el equipo no se pregunta al servidor');

    // Búsqueda de una factura que NO está en el equipo (solo en el servidor).
    c.searchController.text = _Remote.onlyOnServer;
    t = Stopwatch()..start();
    ms = await until(() =>
        !c.isLoading &&
        c.searchQuery == _Remote.onlyOnServer &&
        c.filteredInvoices.isEmpty);
    fast(ms, 'buscar lo que no está en el equipo');
    final expectServer = !moduleReady && online;
    if (expectServer) {
      await until(() => c.isSearchingServer, maxMs: 2000);
      expect(c.isLoading, isFalse);
      final arrived = await until(() => c.filteredInvoices.isNotEmpty);
      out('$label | buscar factura que no ha bajado',
          '"sin resultados" a los $ms ms (pantalla libre); el servidor la agrega a los ${t.elapsedMilliseconds} ms');
      expect(arrived, greaterThan(0));
      expect(remote.listCalls, 1, reason: 'una sola consulta, por detrás');
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      out('$label | buscar factura que no existe en el equipo',
          '"sin resultados" a los $ms ms (servidor ${remote.listCalls} llamadas)');
      expect(remote.listCalls, 0);
      expect(c.filteredInvoices, isEmpty);
    }
    final serverSoFar = remote.listCalls;
    c.searchController.text = '';
    await until(() => !c.isLoading && c.searchQuery.isEmpty && c.totalItems >= count ~/ 2);
    await Future.delayed(const Duration(milliseconds: 100));

    // Filtro por estado (pagadas: casi todas).
    t = Stopwatch()..start();
    c.filterByStatus(InvoiceStatus.paid);
    await until(() => !c.isLoading && t.elapsedMilliseconds > 0);
    out('$label | filtro estado Pagadas',
        '${t.elapsedMilliseconds} ms (${c.totalItems} facturas)');
    fast(t.elapsedMilliseconds, 'filtro Pagadas');

    // Filtro "Pendientes" (pendientes + abonadas): TODAS, desde la base.
    t = Stopwatch()..start();
    c.filterByStatus(InvoiceStatus.pending);
    await until(() => !c.isLoading && !c.isLoadingMore && t.elapsedMilliseconds > 0);
    final pendingMs = t.elapsedMilliseconds;
    final pendingReal = await isar.isarInvoices
        .filter()
        .statusEqualTo(IsarInvoiceStatus.pending)
        .or()
        .statusEqualTo(IsarInvoiceStatus.partiallyPaid)
        .count();
    out('$label | filtro estado Pendientes',
        '$pendingMs ms (primera página ${c.filteredInvoices.length}, total ${c.totalItems}; en la base hay $pendingReal)');
    fast(pendingMs, 'filtro Pendientes');
    expect(c.totalItems, pendingReal, reason: 'Pendientes completo');
    expect(c.filteredInvoices.length, pendingReal < 30 ? pendingReal : 30);
    expect(
        c.filteredInvoices.every((i) =>
            i.status == InvoiceStatus.pending ||
            i.status == InvoiceStatus.partiallyPaid),
        isTrue);
    c.filterByStatus(null);
    await until(() => !c.isLoading);

    // Filtro por fechas: últimos 30 días.
    t = Stopwatch()..start();
    final now = DateTime.now();
    c.filterByDateRange(now.subtract(const Duration(days: 30)), now);
    await until(() => !c.isLoading && t.elapsedMilliseconds > 0);
    out('$label | filtro últimos 30 días',
        '${t.elapsedMilliseconds} ms (${c.totalItems} facturas)');
    fast(t.elapsedMilliseconds, 'filtro fechas');

    // Dos filtros seguidos: gana el último.
    c.filterByDateRange(null, null);
    await until(() => !c.isLoading);
    c.filterByStatus(InvoiceStatus.paid);
    await Future.delayed(const Duration(milliseconds: 1));
    c.filterByStatus(InvoiceStatus.cancelled);
    await until(() => !c.isLoading);
    await Future.delayed(const Duration(milliseconds: 300));
    await until(() => !c.isLoading);
    final cancelledReal = await isar.isarInvoices
        .filter()
        .statusEqualTo(IsarInvoiceStatus.cancelled)
        .count();
    out('$label | dos filtros seguidos (Pagadas y enseguida Anuladas)',
        'con "Anuladas" marcado la pantalla muestra ${c.filteredInvoices.length} filas y dice ${c.totalItems} en total (en la base hay $cancelledReal anuladas)');
    expect(c.totalItems, cancelledReal);
    expect(c.filteredInvoices, isNotEmpty);
    expect(
        c.filteredInvoices.every((i) => i.status == InvoiceStatus.cancelled),
        isTrue);

    expect(remote.listCalls, serverSoFar,
        reason: '$label: los filtros no preguntan al servidor');
    expect(remote.statsCalls + remote.overdueCalls, 0,
        reason: '$label: las estadísticas salen del equipo');
  }

  test('equipo con todo descargado, servidor lento', () async {
    await scenario('descargado+servidor lento', moduleReady: true);
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('historial todavía bajando, servidor lento', () async {
    await scenario('bajando historial+servidor lento', moduleReady: false);
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('sin internet, historial sin terminar', () async {
    await scenario('sin internet (historial a medias)',
        moduleReady: false, online: false);
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('lecturas directas a la base y memoria', () async {
    final local = InvoiceOfflineRepositorySimple();
    Future<int> once(Future<void> Function() f) async {
      final w = Stopwatch()..start();
      await f();
      return w.elapsedMilliseconds;
    }

    Future<String> coldWarm(Future<void> Function() f) async {
      final first = await once(f);
      final times = <int>[for (var i = 0; i < 5; i++) await once(f)]..sort();
      return 'primera $first ms, luego ${times[2]} ms';
    }

    out('base | primera página', await coldWarm(
        () => local.getInvoices(page: 1, limit: 30)));
    out('base | página 100', await coldWarm(
        () => local.getInvoices(page: 100, limit: 30)));
    out('base | buscar número', await coldWarm(
        () => local.getInvoices(page: 1, limit: 30, search: 'FV-001234')));
    out('base | buscar número que no existe', await coldWarm(
        () => local.getInvoices(page: 1, limit: 30, search: 'ZZ-9')));
    out('base | buscar cliente', await coldWarm(
        () => local.getInvoices(page: 1, limit: 30, search: 'Cliente12')));
    out('base | estado pagadas', await coldWarm(() =>
        local.getInvoices(page: 1, limit: 30, status: InvoiceStatus.paid)));
    out('base | estado pendiente', await coldWarm(() =>
        local.getInvoices(page: 1, limit: 30, status: InvoiceStatus.pending)));
    final now = DateTime.now();
    out('base | últimos 30 días', await coldWarm(() => local.getInvoices(
        page: 1,
        limit: 30,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now)));
    out('base | orden por total', await coldWarm(
        () => local.getInvoices(page: 1, limit: 30, sortBy: 'total')));
    out('base | estadísticas', await coldWarm(local.getInvoiceStats));
    out('base | vencidas', await coldWarm(local.getOverdueInvoices));
    out('memoria del proceso',
        '${(rssBefore / 1048576).toStringAsFixed(0)} MB antes de crear la base, ${(ProcessInfo.currentRss / 1048576).toStringAsFixed(0)} MB ahora (incluye la base en memoria compartida)');

    // Leer TODAS las facturas a memoria (lo que NO se debe hacer).
    final rss0 = ProcessInfo.currentRss;
    final w = Stopwatch()..start();
    final all = await isar.isarInvoices.where().findAll();
    final entities = all.map((e) => e.toEntity()).toList();
    out('leer TODAS a memoria (comparación)',
        '${w.elapsedMilliseconds} ms, +${((ProcessInfo.currentRss - rss0) / 1048576).toStringAsFixed(0)} MB (${entities.length} facturas)');
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('equipo SIN facturas todavía (instalación nueva), servidor lento',
      () async {
    // Va de última: vacía la base temporal.
    await isar.writeTxn(() => isar.isarInvoices.clear());
    wire(moduleReady: false);
    final w = Stopwatch()..start();
    final c = Get.put(newController());
    // De inmediato: estado liviano "Descargando tus facturas…".
    final light = await until(() => c.isLoading && c.isHistoryDownloading);
    out('equipo vacío+servidor lento | abrir: estado "Descargando tus facturas…"',
        '$light ms');
    expect(light, inInclusiveRange(0, 300));
    final ms = await until(() => !c.isLoading && remote.listCalls > 0);
    out('equipo vacío+servidor lento | abrir: respuesta del servidor',
        '${w.elapsedMilliseconds} ms (servidor ${remote.listCalls} llamadas; la pantalla no se bloquea)');
    expect(ms, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
