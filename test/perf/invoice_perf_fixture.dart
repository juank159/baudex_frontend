import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/isar/isar_bank_account.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:isar/isar.dart';

/// Base Isar TEMPORAL de prueba (nunca la real) con muchas facturas y sus
/// ítems, como la de un negocio grande. Fechas cada 50 minutos hacia atrás
/// desde hoy; 1 de cada 10 con un estado al azar, el resto pagadas.
Future<Isar> openBigInvoiceDb({
  int invoices = 20000,
  int customers = 3000,
}) async {
  final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
      'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
  await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  final dir = await Directory.systemTemp.createTemp('isar_invoice_perf');
  final isar = await Isar.open(
    [IsarInvoiceSchema, IsarCustomerSchema, IsarBankAccountSchema],
    directory: dir.path,
    maxSizeMiB: 4096,
  );
  IsarDatabase.debugSetDatabase(isar);

  final rnd = Random(7);
  final customerList = List.generate(
    customers,
    (i) => IsarCustomer.create(
      serverId: 'cust-$i',
      firstName: 'Cliente$i',
      lastName: 'Apellido${i % 97}',
      email: 'c$i@x.com',
      documentType: IsarDocumentType.cc,
      documentNumber: '10$i',
      status: IsarCustomerStatus.active,
      creditLimit: 0,
      currentBalance: 0,
      paymentTerms: 30,
      totalPurchases: 0,
      totalOrders: 0,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      isSynced: true,
    ),
  );
  String items(int n, String invoiceId) => jsonEncode(List.generate(
        n,
        (k) => {
          'id': '$invoiceId-it$k',
          'description':
              'Producto de prueba número ${rnd.nextInt(2900)} presentación x1',
          'quantity': 1 + rnd.nextInt(5),
          'unitPrice': 1000 + rnd.nextInt(50000),
          'discountPercentage': 0,
          'discountAmount': 0,
          'subtotal': 5000,
          'unit': 'und',
          'invoiceId': invoiceId,
          'productId': 'prod-${rnd.nextInt(2900)}',
          'unitCost': 800,
          'totalCost': 800,
          'createdAt': '2026-01-01T10:00:00.000Z',
          'updatedAt': '2026-01-01T10:00:00.000Z',
        },
      ));
  final newest = DateTime.now().subtract(const Duration(hours: 1));
  const statuses = IsarInvoiceStatus.values;
  for (var b = 0; b < invoices; b += 2000) {
    final batch = <IsarInvoice>[];
    for (var i = b; i < min(b + 2000, invoices); i++) {
      // i más alto = más reciente.
      final d = newest.subtract(Duration(minutes: (invoices - 1 - i) * 50));
      final st = i % 10 == 0
          ? statuses[rnd.nextInt(statuses.length)]
          : IsarInvoiceStatus.paid;
      batch.add(IsarInvoice.create(
        serverId: 'inv-$i',
        number: 'FV-${i.toString().padLeft(6, '0')}',
        date: d,
        dueDate: d.add(const Duration(days: 30)),
        status: st,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: 10000,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: 10000.0 + i,
        paidAmount: st == IsarInvoiceStatus.paid ? 10000.0 + i : 9500.0 + i,
        balanceDue: st == IsarInvoiceStatus.paid ? 0 : 500,
        itemsJson: items(2 + rnd.nextInt(10), 'inv-$i'),
        paymentsJson:
            '[{"amount":10000,"bankAccountId":"bank-${i % 3}","method":"cash"}]',
        customerId: 'cust-${rnd.nextInt(customers)}',
        createdAt: d,
        updatedAt: d,
        isSynced: true,
      ));
    }
    await isar.writeTxn(() => isar.isarInvoices.putAll(batch));
  }
  await isar.writeTxn(() => isar.isarCustomers.putAll(customerList));
  return isar;
}

Future<void> closeBigInvoiceDb(Isar isar) async {
  IsarDatabase.debugSetDatabase(null);
  await isar.close(deleteFromDisk: true);
}
