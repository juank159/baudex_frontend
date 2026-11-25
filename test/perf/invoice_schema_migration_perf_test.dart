import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'schema_1_0_7/isar_invoice.dart' as v107;

/// Migración del esquema de facturas en el equipo de un cliente.
///
/// La versión nueva cambia índices de `IsarInvoice` (número por valor,
/// estado + creación, cliente + creación). Isar los construye solo la
/// PRIMERA vez que abre la base con el esquema nuevo. Esta prueba crea una
/// base con el esquema de la 1.0.7 (copia en `schema_1_0_7/`), la abre con
/// el esquema actual y mide esa primera apertura; también comprueba que no
/// se pierde ninguna factura y que los índices nuevos responden bien.
///
/// Siempre sobre una carpeta temporal; nunca la base real. Tamaño con
/// `BAUDEX_PERF_INVOICES` (por defecto 5.000):
///
///   BAUDEX_PERF_INVOICES=50000 flutter test test/perf/invoice_schema_migration_perf_test.dart
void main() {
  final count =
      int.tryParse(Platform.environment['BAUDEX_PERF_INVOICES'] ?? '') ?? 5000;

  test('abrir una base 1.0.7 con el esquema nuevo ($count facturas)', () async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    final dir = await Directory.systemTemp.createTemp('isar_migration');
    addTearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    // ---- 1. Base "vieja": esquema 1.0.7 con facturas e ítems ----
    var old = await Isar.open([v107.IsarInvoiceSchema],
        directory: dir.path, maxSizeMiB: 4096);
    final rnd = Random(7);
    String items(int n, String id) => jsonEncode([
          for (var k = 0; k < n; k++)
            {
              'id': '$id-it$k',
              'description':
                  'Producto de prueba número ${rnd.nextInt(2900)} presentación x1',
              'quantity': 1 + rnd.nextInt(5),
              'unitPrice': 1000 + rnd.nextInt(50000),
              'discountPercentage': 0,
              'discountAmount': 0,
              'subtotal': 5000,
              'unit': 'und',
              'invoiceId': id,
              'productId': 'prod-${rnd.nextInt(2900)}',
              'unitCost': 800,
              'totalCost': 800,
              'createdAt': '2026-01-01T10:00:00.000Z',
              'updatedAt': '2026-01-01T10:00:00.000Z',
            },
        ]);
    final newest = DateTime(2026, 11, 1);
    const statuses = IsarInvoiceStatus.values;
    for (var b = 0; b < count; b += 2000) {
      final batch = <v107.IsarInvoice>[];
      for (var i = b; i < min(b + 2000, count); i++) {
        final d = newest.subtract(Duration(minutes: (count - 1 - i) * 50));
        batch.add(v107.IsarInvoice.create(
          serverId: 'inv-$i',
          number: 'FV-${i.toString().padLeft(6, '0')}',
          date: d,
          dueDate: d.add(const Duration(days: 30)),
          status: i % 10 == 0
              ? statuses[rnd.nextInt(statuses.length)]
              : IsarInvoiceStatus.paid,
          paymentMethod: IsarPaymentMethod.cash,
          subtotal: 10000,
          taxPercentage: 0,
          taxAmount: 0,
          discountPercentage: 0,
          discountAmount: 0,
          total: 10000.0 + i,
          paidAmount: 10000.0 + i,
          balanceDue: 0,
          itemsJson: items(2 + rnd.nextInt(10), 'inv-$i'),
          paymentsJson:
              '[{"amount":10000,"bankAccountId":"bank-${i % 3}","method":"cash"}]',
          customerId: 'cust-${rnd.nextInt(3000)}',
          createdAt: d,
          updatedAt: d,
          isSynced: true,
        ));
      }
      await old.writeTxn(
          () => old.collection<v107.IsarInvoice>().putAll(batch));
    }
    final oldSize = await old.getSize();
    await old.close();

    // Control: volver a abrir con el MISMO esquema (sin migrar nada).
    final control = Stopwatch()..start();
    old = await Isar.open([v107.IsarInvoiceSchema],
        directory: dir.path, maxSizeMiB: 4096);
    control.stop();
    await old.close();

    // ---- 2. Primera apertura con el esquema NUEVO ----
    final first = Stopwatch()..start();
    var isar = await Isar.open([IsarInvoiceSchema],
        directory: dir.path, maxSizeMiB: 4096);
    first.stop();

    // No se pierde nada.
    expect(await isar.collection<IsarInvoice>().count(), count);
    final sample = await isar.collection<IsarInvoice>().getByServerId('inv-${count ~/ 2}');
    expect(sample, isNotNull);
    expect(sample!.number, 'FV-${(count ~/ 2).toString().padLeft(6, '0')}');
    expect(sample.toEntity().items, isNotEmpty);

    // Los índices nuevos quedaron construidos: responden igual que
    // recorrer toda la base.
    for (final st in IsarInvoiceStatus.values) {
      expect(
        await isar.collection<IsarInvoice>().where().statusEqualToAnyCreatedAt(st).count(),
        await isar.collection<IsarInvoice>().filter().statusEqualTo(st).count(),
        reason: 'índice estado+creación ($st)',
      );
    }
    expect(
        await isar.collection<IsarInvoice>().where().numberStartsWith('fv-00000').count(),
        10,
        reason: 'índice de número por valor, sin distinguir mayúsculas');
    expect(
      await isar.collection<IsarInvoice>()
          .where()
          .customerIdEqualToAnyCreatedAt(sample.customerId)
          .count(),
      await isar.collection<IsarInvoice>()
          .filter()
          .customerIdEqualTo(sample.customerId)
          .count(),
      reason: 'índice cliente+creación',
    );
    // Y en orden: las más nuevas de un estado primero.
    final newestPaid = await isar.collection<IsarInvoice>()
        .where(sort: Sort.desc)
        .statusEqualToAnyCreatedAt(IsarInvoiceStatus.paid)
        .limit(50)
        .findAll();
    for (var i = 1; i < newestPaid.length; i++) {
      expect(newestPaid[i - 1].createdAt.isBefore(newestPaid[i].createdAt),
          isFalse);
    }
    final newSize = await isar.getSize();
    await isar.close();

    // ---- 3. Segunda apertura: ya no hay nada que construir ----
    final second = Stopwatch()..start();
    isar = await Isar.open([IsarInvoiceSchema],
        directory: dir.path, maxSizeMiB: 4096);
    second.stop();
    expect(await isar.collection<IsarInvoice>().count(), count);
    await isar.close(deleteFromDisk: true);

    String mb(int bytes) => (bytes / 1048576).toStringAsFixed(0);
    // ignore: avoid_print
    print('MIGRACION $count | base 1.0.7: ${mb(oldSize)} MB → ${mb(newSize)} MB | '
        'abrir sin cambios: ${control.elapsedMilliseconds} ms | '
        'PRIMERA apertura con el esquema nuevo: ${first.elapsedMilliseconds} ms | '
        'segunda: ${second.elapsedMilliseconds} ms');
    // Guardia amplia: construir los índices no puede volverse un bloqueo.
    expect(first.elapsedMilliseconds, lessThan(10000));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
