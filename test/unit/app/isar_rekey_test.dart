import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_rekey.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Venta hecha sin conexión (id temporal). La descarga trae la copia del
/// servidor ANTES de que la sincronización le pase el id real a la local.
/// Antes: el cambio de id chocaba ("Unique index violated"), la venta quedaba
/// dos veces y lo que seguía en la sincronización no se hacía.
void main() {
  late Isar isar;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_rekey');
    isar = await Isar.open([IsarInvoiceSchema], directory: dir.path);
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  IsarInvoice invoice(String id, double paid) => IsarInvoice.create(
        serverId: id,
        number: 'INV-2026-455009',
        date: DateTime(2026, 10, 24),
        dueDate: DateTime(2026, 10, 24),
        status: IsarInvoiceStatus.partiallyPaid,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: 10000,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: 10000,
        paidAmount: paid,
        balanceDue: 10000 - paid,
        customerId: 'c',
        createdAt: DateTime(2026, 10, 24),
        updatedAt: DateTime(2026, 10, 24),
        isSynced: false,
      );

  test('pasar el id real con la copia del servidor ya en el equipo', () async {
    await isar.writeTxn(() async {
      await isar.isarInvoices.put(invoice('inv_temp_1', 7000)); // con abono local
      await isar.isarInvoices.putAllByServerId([invoice('real-uuid', 5000)]);
    });

    final local = (await isar.isarInvoices.filter().serverIdEqualTo('inv_temp_1').findFirst())!;
    local.serverId = 'real-uuid';
    await isar.writeTxn(() async {
      await dropServerCopy(isar.isarInvoices, local.id, local.serverId);
      await isar.isarInvoices.put(local);
    });

    final all = await isar.isarInvoices.where().findAll();
    expect(all, hasLength(1));
    expect(all.single.serverId, 'real-uuid');
    expect(all.single.paidAmount, 7000); // se conserva lo hecho en el equipo
  });

  test('sin copia del servidor no cambia nada más', () async {
    await isar.writeTxn(() => isar.isarInvoices.put(invoice('inv_temp_2', 0)));
    final local = (await isar.isarInvoices.filter().serverIdEqualTo('inv_temp_2').findFirst())!;
    local.serverId = 'real-2';
    await isar.writeTxn(() async {
      await dropServerCopy(isar.isarInvoices, local.id, local.serverId);
      await isar.isarInvoices.put(local);
    });

    final all = await isar.isarInvoices.where().findAll();
    expect(all.map((i) => i.serverId), ['real-2']);
  });
}
