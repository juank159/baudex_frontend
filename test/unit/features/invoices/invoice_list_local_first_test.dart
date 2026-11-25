import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_response_models.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoices_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../perf/invoice_perf_fixture.dart';

class _Net extends Mock implements NetworkInfo {}

class _Local extends Mock implements InvoiceLocalDataSource {}

class _Remote extends Mock implements InvoiceRemoteDataSource {}

class _Full extends Mock implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});
}

/// La lista de facturas no espera al servidor para pintar: con la descarga
/// de facturas aún sin terminar, la lista, la búsqueda, los filtros y las
/// estadísticas salen del equipo. Solo con el equipo vacío se va al servidor.
void main() {
  late Isar isar;
  late _Remote remote;
  late _Net net;
  late InvoiceRepositoryImpl repo;

  setUpAll(() async {
    registerFallbackValue(const InvoiceQueryParams());
    isar = await openBigInvoiceDb(invoices: 120, customers: 10);
  });
  tearDownAll(() => closeBigInvoiceDb(isar));

  setUp(() {
    Get.testMode = true;
    resetLocalCollectionsReady();
    final full = _Full();
    when(() => full.isModuleDownloaded(any())).thenAnswer((_) async => false);
    Get.put<FullSyncService>(full);
    net = _Net();
    when(() => net.isConnected).thenAnswer((_) async => true);
    when(net.resetServerReachability).thenReturn(null);
    final local = _Local();
    when(() => local.cacheInvoices(any())).thenAnswer((_) async {});
    remote = _Remote();
    when(() => remote.getInvoices(any())).thenAnswer((_) async =>
        const InvoiceResponseModel(
          data: [],
          meta: PaginationMeta(
              page: 1, limit: 30, totalItems: 0, totalPages: 0,
              hasNextPage: false, hasPreviousPage: false),
        ));
    repo = InvoiceRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: net,
      offlineRepository: InvoiceOfflineRepositorySimple(),
    );
  });
  tearDown(Get.reset);

  test('lista simple: sale del equipo sin llamar al servidor', () async {
    final r = (await repo.getInvoices(page: 1, limit: 30, sortOrder: 'DESC'))
        .getOrElse(() => throw 'falló');
    expect(r.data, hasLength(30));
    expect(r.data.first.id, 'inv-119');
    verifyNever(() => remote.getInvoices(any()));
  });

  test('con búsqueda o filtros y descarga sin terminar: también sale del equipo',
      () async {
    final found =
        (await repo.getInvoices(page: 1, limit: 30, search: 'FV-000001'))
            .getOrElse(() => throw 'falló');
    expect(found.data.map((i) => i.number), contains('FV-000001'));
    final paid = (await repo.getInvoices(
            page: 1, limit: 30, status: InvoiceStatus.paid))
        .getOrElse(() => throw 'falló');
    expect(paid.data, isNotEmpty);
    expect(paid.data.every((i) => i.status == InvoiceStatus.paid), isTrue);
    verifyNever(() => remote.getInvoices(any()));
  });

  test('estadísticas y vencidas con descarga sin terminar: del equipo',
      () async {
    final stats = (await repo.getInvoiceStats()).getOrElse(() => throw 'falló');
    expect(stats.total, 120);
    expect((await repo.getOverdueInvoices()).isRight(), isTrue);
    verifyNever(() => remote.getInvoiceStats());
    verifyNever(() => remote.getOverdueInvoices());
  });

  test('la pantalla puede saber que el historial sigue bajando', () async {
    expect(await repo.isHistoryDownloading(), isTrue);
  });

  test('consulta directa al servidor: llama una vez; sin internet, falla sin leer el equipo',
      () async {
    final r = await repo.getInvoicesFromServer(
        const GetInvoicesParams(page: 1, limit: 30, search: 'FV-VIEJA'));
    expect(r.getOrElse(() => throw 'falló').data, isEmpty);
    final sent = verify(() => remote.getInvoices(captureAny())).captured.single
        as InvoiceQueryParams;
    expect(sent.search, 'FV-VIEJA');

    when(() => net.isConnected).thenAnswer((_) async => false);
    final offline = await repo.getInvoicesFromServer(
        const GetInvoicesParams(page: 1, limit: 30, search: 'FV-VIEJA'));
    expect(offline.isLeft(), isTrue);
    verifyNever(() => remote.getInvoices(any()));
  });

  test('varios estados: al servidor va sin estado (solo sabe filtrar uno)',
      () async {
    await repo.getInvoicesFromServer(const GetInvoicesParams(
        statuses: [InvoiceStatus.pending, InvoiceStatus.partiallyPaid]));
    final sent = verify(() => remote.getInvoices(captureAny())).captured.single
        as InvoiceQueryParams;
    expect(sent.status, isNull);
  });

  test('equipo SIN facturas y descarga sin terminar: se pregunta al servidor',
      () async {
    // Va de última: vacía la base temporal.
    await isar.writeTxn(() => isar.isarInvoices.clear());
    await repo.getInvoices(page: 1, limit: 30);
    verify(() => remote.getInvoices(any())).called(1);
  });
}
