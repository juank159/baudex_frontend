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
/// de facturas aún sin terminar, la lista simple sale del equipo; con
/// búsqueda o filtros sí se pregunta al servidor (los datos están a medias).
void main() {
  late Isar isar;
  late _Remote remote;
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
    final net = _Net();
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

  test('con búsqueda y descarga sin terminar: pregunta al servidor', () async {
    await repo.getInvoices(page: 1, limit: 30, search: 'FV-0001');
    verify(() => remote.getInvoices(any())).called(1);
  });
}
