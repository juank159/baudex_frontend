// Genera imágenes (PNG) de la pantalla "Facturas" con fuentes reales, sobre
// una base local TEMPORAL (nunca la real). Solo corre si se indica dónde
// guardar:
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/invoice_list_visual_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_response_models.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_stats_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/services/invoice_history_lookup.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../perf/invoice_perf_fixture.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

class _Net extends Mock implements NetworkInfo {}

class _Local extends Mock implements InvoiceLocalDataSource {}

class _Remote extends Mock implements InvoiceRemoteDataSource {}

class _Full extends Mock implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});
}

class _FakeSync extends SyncService {
  _FakeSync() : super(null);
  // Sin arrancar la sincronización real.
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
}

void main() {
  if (_out == null) {
    test('imágenes de Facturas (definir BAUDEX_VISUAL_OUT para generarlas)', () {});
    return;
  }

  final boundaryKey = GlobalKey();
  late Isar isar;

  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
    registerFallbackValue(const InvoiceQueryParams());
    isar = await openBigInvoiceDb(invoices: 400, customers: 60);
  });

  /// [historyDone] = false: el historial de facturas todavía está bajando.
  /// [serverNeverAnswers]: con internet, pero el servidor no responde aún.
  Future<InvoiceListController> mount(
    WidgetTester tester,
    double w,
    double h, {
    bool historyDone = true,
    bool serverNeverAnswers = false,
  }) async {
    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Get.testMode = true;
    resetLocalCollectionsReady();
    final net = _Net();
    when(() => net.isConnected).thenAnswer((_) async => serverNeverAnswers);
    final full = _Full();
    when(() => full.isModuleDownloaded(any()))
        .thenAnswer((_) async => historyDone);
    Get.put<FullSyncService>(full);
    Get.put<SyncService>(_FakeSync());
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    final remote = _Remote();
    if (serverNeverAnswers) {
      when(() => remote.getInvoices(any()))
          .thenAnswer((_) => Completer<InvoiceResponseModel>().future);
      when(() => remote.getInvoiceStats())
          .thenAnswer((_) => Completer<InvoiceStatsModel>().future);
      when(() => remote.getOverdueInvoices())
          .thenAnswer((_) => Completer<List<InvoiceModel>>().future);
    }
    final InvoiceRepository repo = InvoiceRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _Local(),
      networkInfo: net,
      offlineRepository: InvoiceOfflineRepositorySimple(),
    );
    Get.put(InvoiceStatsController(
      getInvoiceStatsUseCase: GetInvoiceStatsUseCase(repo),
      getOverdueInvoicesUseCase: GetOverdueInvoicesUseCase(repo),
    ));
    InvoiceListController.invalidateCache();
    late InvoiceListController c;
    await tester.runAsync(() async {
      c = Get.put(InvoiceListController(
        getInvoicesUseCase: GetInvoicesUseCase(repo),
        searchInvoicesUseCase: SearchInvoicesUseCase(repo),
        deleteInvoiceUseCase: DeleteInvoiceUseCase(repo),
        confirmInvoiceUseCase: ConfirmInvoiceUseCase(repo),
        cancelInvoiceUseCase: CancelInvoiceUseCase(repo),
        getInvoiceByIdUseCase: GetInvoiceByIdUseCase(repo),
        historyLookup: repo as InvoiceHistoryLookup,
      ));
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: const InvoiceListScreen(),
        ),
      ));
      await settle(tester);
    });
    return c;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pumpWidget(const SizedBox());
    Get.reset();
  }

  testWidgets('escritorio: primeras facturas', (tester) async {
    await mount(tester, 1440, 900);
    expect(find.byType(InvoiceCardWidget), findsWidgets);
    await shot(tester, 'facturas_escritorio');
    await cleanup(tester);
  });

  testWidgets('escritorio: al bajar carga la página siguiente', (tester) async {
    final c = await mount(tester, 1440, 900);
    final first = c.filteredInvoices.length;
    await tester.runAsync(() async {
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -1500));
        await settle(tester);
      }
    });
    expect(c.filteredInvoices.length, greaterThan(first));
    await shot(tester, 'facturas_escritorio_al_bajar');
    await cleanup(tester);
  });

  testWidgets('escritorio: filtro pendientes', (tester) async {
    final c = await mount(tester, 1440, 900);
    await tester.runAsync(() async {
      c.filterByStatus(InvoiceStatus.pending);
      await settle(tester);
    });
    await shot(tester, 'facturas_escritorio_pendientes');
    await cleanup(tester);
  });

  testWidgets('celular', (tester) async {
    await mount(tester, 390, 844);
    await shot(tester, 'facturas_celular');
    await cleanup(tester);
  });

  const notice = 'Descargando historial… puede faltar alguna factura antigua';

  testWidgets('historial completo: sin aviso', (tester) async {
    await mount(tester, 1440, 900);
    expect(find.text(notice), findsNothing);
    await cleanup(tester);
  });

  testWidgets('escritorio: historial bajando → aviso discreto sobre la lista',
      (tester) async {
    await mount(tester, 1440, 900, historyDone: false);
    expect(find.byType(InvoiceCardWidget), findsWidgets);
    expect(find.text(notice), findsOneWidget);
    await shot(tester, 'facturas_escritorio_historial_bajando');
    await cleanup(tester);
  });

  testWidgets('celular: historial bajando → aviso', (tester) async {
    await mount(tester, 390, 844, historyDone: false);
    expect(find.text(notice), findsOneWidget);
    await shot(tester, 'facturas_celular_historial_bajando');
    await cleanup(tester);
  });

  testWidgets('escritorio: búsqueda sin resultados con el historial bajando',
      (tester) async {
    final c = await mount(tester, 1440, 900, historyDone: false);
    await tester.runAsync(() async {
      c.searchController.text = 'FV-NO-EXISTE';
      await Future.delayed(const Duration(milliseconds: 600));
      await settle(tester);
    });
    expect(find.text('Sin resultados'), findsOneWidget);
    expect(
        find.text(
            'El historial aún se está descargando: puede faltar alguna factura antigua'),
        findsOneWidget);
    await shot(tester, 'facturas_escritorio_sin_resultados_historial_bajando');
    await tester.runAsync(() async {
      c.searchController.text = '';
      await Future.delayed(const Duration(milliseconds: 600));
    });
    await cleanup(tester);
  });

  testWidgets('equipo sin facturas todavía: "Descargando tus facturas…"',
      (tester) async {
    // Va de última: vacía la base temporal.
    await tester.runAsync(() => isar.writeTxn(() => isar.isarInvoices.clear()));
    await mount(tester, 1440, 900,
        historyDone: false, serverNeverAnswers: true);
    expect(find.text('Descargando tus facturas…'), findsOneWidget);
    await shot(tester, 'facturas_escritorio_equipo_vacio');
    await cleanup(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await Future.delayed(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
  }
}
