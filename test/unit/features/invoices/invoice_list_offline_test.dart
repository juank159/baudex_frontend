import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/isar/isar_bank_account.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// La lista de facturas se lee del equipo (con o sin internet) y debe dar
/// lo mismo que el servidor: mismos filtros, mismo orden, solo la página
/// pedida, y estadísticas con las mismas definiciones.
void main() {
  late Isar isar;
  late InvoiceOfflineRepositorySimple repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarInvoice inv(
    String id,
    String number, {
    required String customer,
    required DateTime date,
    double total = 10000,
    double balance = 0,
    IsarInvoiceStatus status = IsarInvoiceStatus.paid,
    IsarPaymentMethod method = IsarPaymentMethod.cash,
    String? payments,
    DateTime? due,
    DateTime? deletedAt,
  }) =>
      IsarInvoice.create(
        serverId: id,
        number: number,
        date: date,
        dueDate: due ?? date.add(const Duration(days: 30)),
        status: status,
        paymentMethod: method,
        subtotal: total,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: total,
        paidAmount: total - balance,
        balanceDue: balance,
        paymentsJson: payments,
        customerId: customer,
        createdAt: date,
        updatedAt: date,
        deletedAt: deletedAt,
        isSynced: true,
      );

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_invoices');
    isar = await Isar.open(
      [IsarInvoiceSchema, IsarCustomerSchema, IsarBankAccountSchema],
      directory: dir.path,
    );
    IsarDatabase.debugSetDatabase(isar);
    repo = InvoiceOfflineRepositorySimple();

    IsarCustomer c(String id, String first, String last) => IsarCustomer.create(
          serverId: id,
          firstName: first,
          lastName: last,
          email: '$id@x.com',
          documentType: IsarDocumentType.cc,
          documentNumber: id,
          status: IsarCustomerStatus.active,
          creditLimit: 0,
          currentBalance: 0,
          paymentTerms: 30,
          totalPurchases: 0,
          totalOrders: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isSynced: true,
        );

    await isar.writeTxn(() async {
      await isar.isarCustomers.putAll([c('c1', 'KEYLA', 'MAITA'), c('c2', 'YOLIMAR', 'DIAZ')]);
      await isar.isarBankAccounts.put(IsarBankAccount.create(
        serverId: 'bank-nequi',
        name: 'Nequi',
        type: IsarBankAccountType.savings,
        isActive: true,
        isDefault: false,
        sortOrder: 0,
        organizationId: 'org',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
      ));
      await isar.isarInvoices.putAll([
        inv('i1', 'INV-001', customer: 'c1', date: DateTime(2026, 10, 10, 9), total: 6000),
        inv('i2', 'INV-002', customer: 'c2', date: DateTime(2026, 10, 10, 18),
            total: 3500, balance: 3500, status: IsarInvoiceStatus.pending,
            method: IsarPaymentMethod.credit, due: DateTime(2026, 10, 1)),
        inv('i3', 'INV-003', customer: 'c1', date: DateTime(2026, 10, 12, 15),
            total: 120000, balance: 20000, status: IsarInvoiceStatus.partiallyPaid,
            payments: '[{"amount":100000,"bankAccountId":"bank-nequi"}]'),
        inv('i4', 'INV-004', customer: 'c2', date: DateTime(2026, 10, 13),
            total: 9000, status: IsarInvoiceStatus.cancelled),
        inv('i5', 'INV-005', customer: 'c1', date: DateTime(2026, 10, 14),
            deletedAt: DateTime(2026, 10, 14)),
      ]);
    });
  });

  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
  });

  Future<List<String>> list({
    String? search,
    InvoiceStatus? status,
    PaymentMethod? method,
    String? customerId,
    String? bankAccountName,
    DateTime? start,
    DateTime? end,
    double? min,
    double? max,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    int page = 1,
    int limit = 10,
  }) async {
    final r = await repo.getInvoices(
      page: page,
      limit: limit,
      search: search,
      status: status,
      paymentMethod: method,
      customerId: customerId,
      bankAccountName: bankAccountName,
      startDate: start,
      endDate: end,
      minAmount: min,
      maxAmount: max,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    return r.getOrElse(() => throw 'falló').data.map((i) => i.id).toList();
  }

  test('orden por defecto: las más nuevas primero (DESC en mayúsculas)', () async {
    expect(await list(), ['i4', 'i3', 'i2', 'i1']);
    expect(await list(sortOrder: 'ASC'), ['i1', 'i2', 'i3', 'i4']);
  });

  test('solo carga la página pedida y cuenta el total', () async {
    final r = await repo.getInvoices(page: 2, limit: 3, sortOrder: 'DESC');
    final page = r.getOrElse(() => throw 'falló');
    expect(page.data.map((i) => i.id), ['i1']);
    expect(page.meta.totalItems, 4);
    expect(page.meta.totalPages, 2);
  });

  test('busca por número o por nombre del cliente', () async {
    expect(await list(search: 'INV-002'), ['i2']);
    expect(await list(search: 'keyla'), ['i3', 'i1']);
    expect(await list(search: 'nadie'), isEmpty);
  });

  test('filtros: estado, método, cliente, montos y fechas inclusivas', () async {
    expect(await list(status: InvoiceStatus.pending), ['i2']);
    expect(await list(method: PaymentMethod.credit), ['i2']);
    expect(await list(customerId: 'c2'), ['i4', 'i2']);
    expect(await list(min: 6000, max: 9000), ['i4', 'i1']);
    expect(
      await list(start: DateTime(2026, 10, 10, 9), end: DateTime(2026, 10, 10, 18)),
      ['i2', 'i1'],
    );
  });

  test('filtro por cuenta bancaria (nombre), como el servidor', () async {
    expect(await list(bankAccountName: 'nequi'), ['i3']);
    expect(await list(bankAccountName: 'Bancolombia'), isEmpty);
  });

  test('estadísticas con las definiciones del servidor', () async {
    final s = (await repo.getInvoiceStats()).getOrElse(() => throw 'falló');
    expect(s.total, 4);
    expect(s.paid, 1);
    expect(s.pending, 1);
    expect(s.partiallyPaid, 1);
    expect(s.cancelled, 1);
    expect(s.totalSales, 6000 + 3500 + 120000); // sin anuladas
    expect(s.pendingAmount, 3500 + 20000);
    expect(s.overdue, 1); // i2 vencida (pendiente con vencimiento pasado)
    expect(s.overdueAmount, 3500);
  });
}
