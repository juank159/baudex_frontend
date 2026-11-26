// Medición: abrir Diagnóstico con una base como la de un negocio real
// (2.950 productos, 2.539 presentaciones, 6.055 facturas, una semana de
// operaciones ya sincronizadas y 5.000 eventos). ¿Cuánto tarda la carga y
// cuánto frena el hilo de la pantalla?
//
//   flutter test test/perf/diagnostic_refresh_perf_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_event_log.dart';
import 'package:baudex_desktop/app/data/local/sync_event_log_service.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/controllers/sync_diagnostic_controller.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../helpers/isar_test_lib.dart';

/// Base Isar TEMPORAL con el tamaño de un negocio real.
Future<Isar> openRealLikeDb({
  int products = 2950,
  int presentations = 2539,
  int invoices = 6055,
  int completedOps = 3000,
  int events = 5000,
}) async {
  await initIsarForTests();
  final dir = await Directory.systemTemp.createTemp('isar_diag_perf');
  final isar = await Isar.open(IsarDatabase.schemas,
      directory: dir.path, maxSizeMiB: 2048);
  IsarDatabase.debugSetDatabase(isar);
  final rnd = Random(3);
  final item = '{"id":"it","description":"Producto de prueba presentación x1",'
      '"quantity":2,"unitPrice":12000,"subtotal":24000,"productId":"p1"}';
  await isar.writeTxn(() async {
    await isar.isarProducts.putAll([
      for (var i = 0; i < products; i++)
        IsarProduct.create(
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
          // Algunos con cambios locales sin subir, como en la vida real.
          isSynced: i % 40 != 0,
          taxCategory: IsarTaxCategory.noGravado,
          taxRate: 0,
          isTaxable: false,
          hasRetention: false,
        ),
    ]);
    await isar.isarProductPresentations.putAll([
      for (var i = 0; i < presentations; i++)
        IsarProductPresentation()
          ..serverId = 'pp$i'
          ..productId = 'p$i'
          ..name = 'Unidad'
          ..factor = 1
          ..price = 1000
          ..currency = 'COP'
          ..isDefault = true
          ..isActive = true
          ..sortOrder = 0
          ..createdAt = DateTime(2026)
          ..updatedAt = DateTime(2026)
          ..isSynced = true
          ..version = 1,
    ]);
  });
  for (var from = 0; from < invoices; from += 1000) {
    await isar.writeTxn(() => isar.isarInvoices.putAll([
          for (var i = from; i < min(from + 1000, invoices); i++)
            IsarInvoice.create(
              serverId: 'inv-$i',
              number: 'FV-$i',
              date: DateTime(2026, 11, 1),
              dueDate: DateTime(2026, 12, 1),
              status: IsarInvoiceStatus.paid,
              paymentMethod: IsarPaymentMethod.cash,
              subtotal: 10000,
              taxPercentage: 0,
              taxAmount: 0,
              discountPercentage: 0,
              discountAmount: 0,
              total: 10000,
              paidAmount: 10000,
              balanceDue: 0,
              itemsJson: '[${List.filled(2 + rnd.nextInt(8), item).join(',')}]',
              paymentsJson: '[{"amount":10000,"method":"cash"}]',
              customerId: 'cust-1',
              createdAt: DateTime(2026, 11, 1),
              updatedAt: DateTime(2026, 11, 1),
              isSynced: true,
            ),
        ]));
  }
  // Una semana de ventas ya subidas (cada operación guarda la factura).
  final payload = '{"items":[${List.filled(8, item).join(',')}]}';
  for (var from = 0; from < completedOps; from += 1000) {
    await isar.writeTxn(() => isar.syncOperations.putAll([
          for (var i = from; i < min(from + 1000, completedOps); i++)
            SyncOperation()
              ..organizationId = ''
              ..entityType = 'Invoice'
              ..entityId = 'inv-$i'
              ..operationType = SyncOperationType.create
              ..status = SyncStatus.completed
              ..payload = payload
              ..createdAt = DateTime(2026, 11, 20),
          if (from == 0)
            for (var i = 0; i < 4; i++)
              SyncOperation()
                ..organizationId = ''
                ..entityType = 'Invoice'
                ..entityId = 'invoice_offline_$i'
                ..operationType = SyncOperationType.create
                ..status = i == 0 ? SyncStatus.failed : SyncStatus.pending
                ..payload = payload
                ..createdAt = DateTime(2026, 11, 25),
        ]));
  }
  for (var from = 0; from < events; from += 1000) {
    await isar.writeTxn(() => isar.isarSyncEventLogs.putAll([
          for (var i = from; i < min(from + 1000, events); i++)
            IsarSyncEventLog()
              ..timestamp = DateTime(2026, 11, 25).add(Duration(seconds: i))
              ..severity = SyncEventSeverity.values[i % SyncEventSeverity.values.length]
              ..eventType = SyncEventType.values[i % SyncEventType.values.length]
              ..entityType = 'Product'
              ..operation = 'pull'
              ..message = 'Descarga: 50 productos actualizados (tanda $i)'
              ..organizationId = '',
        ]));
  }
  return isar;
}

/// Pausa más larga del hilo mientras corre [action] (latido cada 4 ms).
Future<(double, double)> timed(Future<void> Function() action) async {
  var worst = 0.0;
  var last = Stopwatch()..start();
  final beat = Timer.periodic(const Duration(milliseconds: 4), (_) {
    final gap = last.elapsedMicroseconds / 1000;
    if (gap > worst) worst = gap;
    last = Stopwatch()..start();
  });
  final total = Stopwatch()..start();
  await action();
  final ms = total.elapsedMicroseconds / 1000;
  beat.cancel();
  return (ms, worst);
}

void main() {
  late Isar isar;
  setUpAll(() async => isar = await openRealLikeDb());
  tearDownAll(() => isar.close(deleteFromDisk: true));
  setUp(() {
    Get.testMode = true;
    Get.put<SyncEventLogService>(SyncEventLogService());
  });
  tearDown(Get.reset);

  test('medición: carga de Diagnóstico con base real', () async {
    final c = SyncDiagnosticController(background: true);
    await timed(c.refreshAll); // calentar
    final rounds = <(double, double)>[];
    for (var i = 0; i < 5; i++) {
      rounds.add(await timed(c.refreshAll));
    }
    final status = <(double, double)>[];
    for (var i = 0; i < 5; i++) {
      status.add(await timed(c.refreshDownloadStatus));
    }
    String f(List<(double, double)> v) =>
        v.map((e) => '${e.$1.toStringAsFixed(0)}/${e.$2.toStringAsFixed(0)}').join(', ');
    // ignore: avoid_print
    print('MEDICION DIAGNOSTICO | carga completa (ms total / pausa más larga del hilo): ${f(rounds)}');
    // ignore: avoid_print
    print('MEDICION DIAGNOSTICO | estado de descarga, cada 5 s: ${f(status)}');

    // Por consulta, para saber cuál pesa.
    Future<void> q(String name, Future<Object?> Function() run) async {
      final r = await timed(() async => run());
      // ignore: avoid_print
      print('MEDICION DIAGNOSTICO |   $name: ${r.$1.toStringAsFixed(0)} ms '
          '(pausa del hilo ${r.$2.toStringAsFixed(0)} ms)');
    }

    await q('cola: operaciones no terminadas (recorre todas)', () => isar
        .syncOperations.filter().not().statusEqualTo(SyncStatus.completed).findAll());
    await q('productos sin subir (trae los productos enteros)',
        () => isar.isarProducts.filter().isSyncedEqualTo(false).findAll());
    await q('productos sin subir (solo contar)',
        () => isar.isarProducts.filter().isSyncedEqualTo(false).count());
    await q('facturas con id temporal (recorre todas)', () => isar.isarInvoices
        .filter().serverIdStartsWith('invoice_offline_').findAll());
    await q('eventos recientes (100)',
        () => Get.find<SyncEventLogService>().getRecent(limit: 100));
    await q('eventos por severidad',
        () => Get.find<SyncEventLogService>().countBySeverity());
    // ignore: avoid_print
    print('MEDICION DIAGNOSTICO | datos: ${c.entityCounts.length} entidades, '
        'cola ${c.pendingQueueOps.value}, bloqueados ${c.stuckProducts.length}, '
        'huérfanos ${c.orphanedRecords.length}, eventos ${c.recentEvents.length}');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
