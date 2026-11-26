// Pantalla real de Diagnóstico sobre una base Isar TEMPORAL: nunca queda en
// blanco, y "Exportar reporte" siempre entrega un texto.
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/controllers/sync_diagnostic_controller.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/screens/sync_diagnostic_screen.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../helpers/isar_test_lib.dart';

IsarProduct _product(int i) => (IsarProduct.create(
      serverId: 'p$i',
      name: 'PRODUCTO $i',
      sku: 'SKU-$i',
      barcode: '770${i.toString().padLeft(10, '0')}',
      type: IsarProductType.product,
      status: IsarProductStatus.active,
      stock: 10,
      minStock: 0,
      categoryId: 'c',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isSynced: true,
      taxCategory: IsarTaxCategory.noGravado,
      taxRate: 0,
      isTaxable: false,
      hasRetention: false,
    ))
      ..id = i + 1;

void main() {
  late Isar isar;

  setUpAll(() async {
    await initIsarForTests();
    final dir = await Directory.systemTemp.createTemp('isar_diagnostico');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    await isar.writeTxn(() => isar.isarProducts
        .putAll([for (var i = 0; i < 2950; i++) _product(i)]));
  });

  setUp(() {
    Get.testMode = true;
    InvoiceEntryMetrics.instance.reset();
  });
  tearDown(Get.reset);

  Future<SyncDiagnosticController> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final controller = Get.put(SyncDiagnosticController());
    await t.pumpWidget(const GetMaterialApp(home: SyncDiagnosticScreen()));
    for (var i = 0; i < 150 && (i < 20 || controller.isLoading.value); i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 200));
    }
    return controller;
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await Get.delete<SyncDiagnosticController>(force: true);
    Get.reset();
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(seconds: 10));
    }
  }

  /// Texto que "Exportar" dejó en el portapapeles.
  Future<String?> export(WidgetTester t) async {
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    await t.tap(find.text('Exportar'));
    await t.pump();
    await t.pump(const Duration(seconds: 4)); // el aviso "Reporte copiado"
    t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    return copied;
  }

  void expectScreenWithSections(WidgetTester t, SyncDiagnosticController c) {
    expect(c.isLoading.value, isFalse, reason: 'no se queda cargando');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Estado de conexion'), findsOneWidget);
    expect(find.text('Salud por entidad'), findsOneWidget);
    expect(find.textContaining('Sección no disponible'), findsNothing);
    expect(find.text('Exportar'), findsOneWidget);
  }

  void expectFullReport(String? report) {
    expect(report, isNotNull, reason: 'Exportar copió algo');
    expect(report, contains('=== Reporte de diagnóstico Baudex ==='));
    expect(report, contains('Operaciones en cola:'));
    expect(report, contains('Conteos locales por entidad:'));
    expect(report, contains('Productos: 2950'));
    expect(report, contains('Rendimiento al facturar'));
    expect(report, contains('Eventos recientes'));
    expect(report, isNot(contains('no disponible')));
  }

  final states = <String, void Function(InvoiceEntryMetrics m)>{
    'recién abierta la app, sin ninguna lectura': (m) {},
    'con lecturas directas pero sin cuadros': (m) => m
      ..recordScan(keys: 13, avgGapMs: 1.8, frames: 0, burst: true, direct: true)
      ..recordScan(keys: 13, avgGapMs: 0.7, frames: 0, burst: true, direct: true)
      ..record(EntryMetric.scanFirstKeyToCode, 25)
      ..record(EntryMetric.scanEnterToLine, 248,
          const EntryContext(indexLoaded: false)),
    'con presentaciones sin descargar': (m) => m
      ..presentationsFromServer = 26
      ..record(EntryMetric.presentations, 0.4),
    'con cargas del índice fallidas': (m) => m
      ..indexLoadFailures = 4
      ..lastIndexLoadError = 'IsarError: base ocupada',
    'con todo a la vez y cuadros medidos': (m) {
      for (final metric in EntryMetric.values) {
        m.record(metric, 120, const EntryContext());
      }
      m
        ..recordFrame(18, buildMs: 4, rasterMs: 9)
        ..recordFrame(321)
        ..recordPrint('USB Windows (directo)', 80, buildMs: 12);
    },
  };

  for (final entry in states.entries) {
    testWidgets('${entry.key}: la pantalla muestra sus secciones y Exportar '
        'copia el reporte completo', (t) async {
      entry.value(InvoiceEntryMetrics.instance);
      final c = await open(t);
      expectScreenWithSections(t, c);
      expectFullReport(await export(t));
      await close(t);
    });
  }

  testWidgets('cola con operaciones fallidas: se ven y salen en el reporte',
      (t) async {
    await t.runAsync(() => isar.writeTxn(() => isar.syncOperations.putAll([
          for (var i = 0; i < 3; i++)
            SyncOperation()
              ..organizationId = 'org-1'
              ..entityType = 'Invoice'
              ..entityId = 'invoice_offline_$i'
              ..operationType = SyncOperationType.create
              ..status = i == 0 ? SyncStatus.pending : SyncStatus.failed
              ..payload = '{}'
              ..createdAt = DateTime(2026, 11, 25)
              ..error = i == 0 ? null : 'Solicitud incorrecta: cliente inválido',
        ])));
    addTearDown(() => isar.writeTxn(() => isar.syncOperations.clear()));
    final c = await open(t);
    expect(c.isLoading.value, isFalse);
    expect(c.pendingQueueOps.value, greaterThan(0));
    expect(find.text('Operaciones pendientes'), findsOneWidget);
    expect(find.textContaining('Sección no disponible'), findsNothing);
    final report = await export(t);
    expect(report, contains('=== Reporte de diagnóstico Baudex ==='));
    expect(report, contains('  - failed:     2'));
    expect(report, contains('Invoice'));
    expect(report, isNot(contains('no disponible')));
    await close(t);
  });

  testWidgets('una sección del reporte falla: Exportar entrega el resto y '
      'dice cuál no está', (t) async {
    final c = await open(t);
    c.debugBillingReport = () => throw StateError('No element');
    final report = await export(t);
    expect(report, contains('=== Reporte de diagnóstico Baudex ==='));
    expect(report, contains('Conteos locales por entidad:'));
    expect(report,
        contains('Sección "Rendimiento al facturar" no disponible: Bad state: No element'));
    expect(report, contains('Eventos recientes'));
    await close(t);
  });

  testWidgets('la base local no responde: la pantalla no se queda cargando '
      'y Exportar entrega lo que hay', (t) async {
    SyncDiagnosticController.refreshTimeout = const Duration(seconds: 2);
    addTearDown(() => SyncDiagnosticController.refreshTimeout =
        const Duration(seconds: 12));
    // Sin base: todas las lecturas fallan.
    IsarDatabase.debugSetDatabase(null);
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = Get.put(SyncDiagnosticController());
    await t.pumpWidget(const GetMaterialApp(home: SyncDiagnosticScreen()));
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(seconds: 3));
    IsarDatabase.debugSetDatabase(isar);
    expect(c.isLoading.value, isFalse);
    expect(find.text('Estado de conexion'), findsOneWidget,
        reason: 'la pantalla sale aunque falten datos');
    final report = c.exportDiagnosticReport();
    expect(report, contains('=== Reporte de diagnóstico Baudex ==='));
    await close(t);
  });

  testWidgets('una sección que falla al dibujarse muestra un aviso corto, no '
      'un recuadro que tapa toda la pantalla', (t) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (_) {};
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DiagnosticSectionGuard(
          child: ListView(
            children: [
              const Text('Antes'),
              Builder(builder: (_) => throw StateError('dato inesperado')),
              const Text('Después'),
            ],
          ),
        ),
      ),
    ));
    FlutterError.onError = previous;
    expect(find.text('Antes'), findsOneWidget);
    expect(find.textContaining('Sección no disponible: Bad state: dato inesperado'),
        findsOneWidget);
    expect(find.text('Después'), findsOneWidget,
        reason: 'lo que sigue queda a la vista');
    expect(t.getSize(find.textContaining('Sección no disponible')).height,
        lessThan(100));
    // Al salir de Diagnóstico, el resto de la app queda como estaba.
    final builder = ErrorWidget.builder;
    await t.pumpWidget(const SizedBox());
    expect(ErrorWidget.builder, isNot(same(builder)));
  });
}
