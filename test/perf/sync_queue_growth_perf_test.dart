// Medición: la cola de sincronización guarda para siempre las operaciones
// ya subidas (con el JSON completo de cada factura). ¿Cuánto cuestan las
// lecturas que la sincronización repite después de cada venta, según el
// tamaño de la cola? ¿Y cuánto se demora mientras tanto una lectura de la
// factura (producto por código)?
//
//   flutter test test/perf/sync_queue_growth_perf_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../helpers/isar_test_lib.dart';

void main() {
  final total =
      int.tryParse(Platform.environment['BAUDEX_PERF_QUEUE'] ?? '') ?? 60000;
  late Isar isar;

  final payload = jsonEncode({
    'customerId': '0f8fad5b-d9cb-469f-a165-70867728950e',
    'items': [
      for (var i = 0; i < 12; i++)
        {
          'productId': '7c9e6679-7425-40de-944b-e07fc1f9$i',
          'description': 'PRODUCTO DE PRUEBA NUMERO $i PRESENTACION 500 GR',
          'quantity': 2,
          'unitPrice': 3500,
          'discountPercentage': 0,
          'taxRate': 19,
        },
    ],
    'notes': 'x' * 200,
  });

  SyncOperation op(int i, SyncStatus status) => SyncOperation.create(
        entityType: i % 3 == 0 ? 'Invoice' : 'inventory_movement_fifo',
        entityId: 'invoice_offline_$i',
        operationType: SyncOperationType.create,
        payload: payload,
        organizationId: 'org',
      )
        ..status = status
        ..syncedAt = DateTime(2026, 1, 1).add(Duration(minutes: i));

  setUpAll(() async {
    await initIsarForTests();
    final dir = await Directory.systemTemp.createTemp('isar_queue_growth');
    isar = await Isar.open([SyncOperationSchema], directory: dir.path);
  });
  tearDownAll(() => isar.close(deleteFromDisk: true));

  /// Lo que hace la sincronización tras cada venta (ver SyncService.syncAll
  /// y _updateHealthInfo): pendientes dos veces, fallidas y cuatro conteos.
  Future<double> syncReads() async {
    final w = Stopwatch()..start();
    for (var i = 0; i < 2; i++) {
      await isar.syncOperations
          .filter()
          .group((q) => q
              .statusEqualTo(SyncStatus.pending)
              .or()
              .statusEqualTo(SyncStatus.failed))
          .sortByPriority()
          .thenByCreatedAt()
          .findAll();
    }
    for (final s in SyncStatus.values) {
      await isar.syncOperations.filter().statusEqualTo(s).count();
    }
    await isar.syncOperations.filter().statusEqualTo(SyncStatus.failed).findAll();
    return w.elapsedMicroseconds / 1000;
  }

  test('lecturas de la cola según su tamaño', () async {
    var written = 0;
    for (final size in [1000, total ~/ 4, total]) {
      while (written < size) {
        final n = (size - written).clamp(0, 2000);
        await isar.writeTxn(() => isar.syncOperations.putAll([
              for (var i = 0; i < n; i++)
                op(written + i,
                    (written + i) % 5000 == 0 ? SyncStatus.pending : SyncStatus.completed),
            ]));
        written += n;
      }
      final runs = [for (var i = 0; i < 5; i++) await syncReads()]..sort();
      final mb = (await isar.getSize()) / (1024 * 1024);
      // ignore: avoid_print
      print('MEDICION cola con $size operaciones '
          '(${mb.toStringAsFixed(0)} MB): lecturas de una sincronización '
          '${runs[2].toStringAsFixed(0)} ms (peor ${runs.last.toStringAsFixed(0)} ms)');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
