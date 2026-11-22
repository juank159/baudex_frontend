import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_response_models.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
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
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_list_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/invoice_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'invoice_perf_fixture.dart';

class _Net extends Mock implements NetworkInfo {}
class _Local extends Mock implements InvoiceLocalDataSource {}
class _Sync extends Mock implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});
}

/// El servidor de mentiras responde la misma página que hay en el equipo,
/// tras [delay] (el real tarda ~270 ms).
class _Remote extends Mock implements InvoiceRemoteDataSource {
  _Remote(this.delay);
  final Duration delay;
  int calls = 0;
  @override
  Future<InvoiceResponseModel> getInvoices(InvoiceQueryParams params) async {
    calls++;
    await Future.delayed(delay);
    final page = (await InvoiceOfflineRepositorySimple().getInvoices(
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    ))
        .getOrElse(() => throw 'falló');
    return InvoiceResponseModel(
      data: page.data.map(InvoiceModel.fromEntity).toList(),
      meta: page.meta,
    );
  }
}

/// Medición de punta a punta: se abre la pantalla "Facturas" real (con su
/// controlador y repositorio reales) sobre una base local de 20.000
/// facturas y se cuenta cuánto tarda en verse la primera fila.
/// Correr con: flutter test test/perf/invoice_list_screen_perf_test.dart
void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('es');
    await openBigInvoiceDb();
  });
  // Sin cerrar la base aquí: dentro de las pruebas de pantalla el cierre se
  // queda esperando; es temporal y se borra con el sistema.

  // La primera vuelta calienta (compilación, fuentes); no se cuenta.
  final runs = <(bool, String)>[
    (true, 'calentar'),
    for (var i = 1; i <= 3; i++) (true, 'módulo listo #$i'),
    for (var i = 1; i <= 2; i++) (false, 'módulo sin bajar #$i'),
  ];
  for (final (moduleReady, label) in runs) {
    testWidgets('medición: abrir Facturas ($label)', (tester) async {
      final previousOnError = FlutterError.onError;
      // Sin fuentes reales los textos se desbordan y la barra de
      // sincronización no tiene servicio: no afecta la medición.
      FlutterError.onError = (_) {};
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.testMode = true;
      resetLocalCollectionsReady();
      final net = _Net();
      when(() => net.isConnected).thenAnswer((_) async => true);
      final local = _Local();
      when(() => local.cacheInvoices(any())).thenAnswer((_) async {});
      final sync = _Sync();
      when(() => sync.isModuleDownloaded(any()))
          .thenAnswer((_) async => moduleReady);
      Get.put<FullSyncService>(sync);
      Get.put<TenantDateTimeService>(TenantDateTimeService());
      final remote = _Remote(const Duration(milliseconds: 270));
      final InvoiceRepository repo = InvoiceRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        networkInfo: net,
        offlineRepository: InvoiceOfflineRepositorySimple(),
      );
      Get.put(InvoiceStatsController(
        getInvoiceStatsUseCase: GetInvoiceStatsUseCase(repo),
        getOverdueInvoicesUseCase: GetOverdueInvoicesUseCase(repo),
      ));
      InvoiceListController.invalidateCache();

      final watch = Stopwatch();
      int? dataMs;
      await tester.runAsync(() async {
        watch.start();
        Get.put(InvoiceListController(
          getInvoicesUseCase: GetInvoicesUseCase(repo),
          searchInvoicesUseCase: SearchInvoicesUseCase(repo),
          deleteInvoiceUseCase: DeleteInvoiceUseCase(repo),
          confirmInvoiceUseCase: ConfirmInvoiceUseCase(repo),
          cancelInvoiceUseCase: CancelInvoiceUseCase(repo),
          getInvoiceByIdUseCase: GetInvoiceByIdUseCase(repo),
        ));
        await tester.pumpWidget(
            const GetMaterialApp(home: InvoiceListScreen()));
        final c = Get.find<InvoiceListController>();
        while (find.byType(InvoiceCardWidget).evaluate().isEmpty &&
            watch.elapsedMilliseconds < 20000) {
          if (dataMs == null && c.filteredInvoices.isNotEmpty) {
            dataMs = watch.elapsedMilliseconds;
          }
          await Future.delayed(const Duration(milliseconds: 1));
          await tester.pump();
        }
        watch.stop();
      });
      final c = Get.find<InvoiceListController>();
      // ignore: avoid_print
      print('PERF pantalla Facturas | $label: '
          'datos en ${dataMs ?? watch.elapsedMilliseconds} ms, primera fila en ${watch.elapsedMilliseconds} ms '
          '(${c.filteredInvoices.length} filas cargadas, servidor llamado ${remote.calls} veces)');
      expect(find.byType(InvoiceCardWidget), findsWidgets);
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      FlutterError.onError = previousOnError;
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
