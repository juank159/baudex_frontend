import 'dart:convert';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/dashboard/data/datasources/dashboard_local_datasource_isar.dart';
import 'package:baudex_desktop/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:baudex_desktop/features/expenses/data/models/isar/isar_expense.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_item_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_payment_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../../fixtures/product_fixtures.dart';
import '../../../helpers/test_isar.dart';

/// El tablero sin conexión (Isar) con las mismas definiciones del servidor.
///
/// "Hoy" es el 12-nov-2026 a las 3 p. m. en un negocio en Bogotá (UTC-5).
void main() {
  late Isar isar;
  late DashboardLocalDataSourceIsar ds;

  DateTime bogota(DateTime instant) =>
      instant.toUtc().subtract(const Duration(hours: 5));

  final nov10 = DateTime(2026, 11, 10);
  final nov12 = DateTime(2026, 11, 12);
  final endNov12 = DateTime(2026, 11, 12, 23, 59, 59);
  // 3 p. m. del 12-nov en Bogotá.
  final nov12Afternoon = DateTime.utc(2026, 11, 12, 20);
  // 10 p. m. del 12-nov en Bogotá: en UTC ya es 13-nov.
  final nov12Night = DateTime.utc(2026, 11, 13, 3);

  InvoicePayment pay(
    double amount,
    DateTime date, {
    PaymentMethod method = PaymentMethod.cash,
    String? channel,
  }) =>
      InvoicePayment(
        id: 'pay-${date.microsecondsSinceEpoch}-$amount',
        amount: amount,
        paymentMethod: method,
        paymentDate: date,
        invoiceId: 'i',
        createdById: 'u',
        organizationId: 'o',
        createdAt: date,
        updatedAt: date,
        channel: channel,
      );

  String line(String productId, double qty, double price, {double? totalCost}) =>
      jsonEncode({
        'productId': productId,
        'quantity': qty,
        'unitPrice': price,
        if (totalCost != null) 'totalCost': totalCost,
      });

  IsarInvoice inv(
    String id, {
    required DateTime date,
    required double total,
    IsarInvoiceStatus status = IsarInvoiceStatus.paid,
    double? paid,
    List<InvoicePayment>? payments,
    List<String> lines = const [],
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      IsarInvoice.create(
        serverId: id,
        number: id,
        date: date,
        dueDate: date.add(const Duration(days: 30)),
        status: status,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: total,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: total,
        paidAmount:
            paid ?? (payments ?? []).fold(0.0, (sum, p) => sum + p.amount),
        balanceDue: 0,
        itemsJson: '[${lines.join(',')}]',
        paymentsJson:
            payments == null ? null : IsarInvoice.encodePayments(payments),
        customerId: 'c1',
        createdAt: date,
        updatedAt: updatedAt ?? date,
        deletedAt: deletedAt,
        isSynced: true,
      );

  IsarExpense exp(String id, double amount, IsarExpenseStatus status,
          {DateTime? date}) =>
      IsarExpense.create(
        serverId: id,
        description: id,
        amount: amount,
        date: date ?? nov12,
        status: status,
        type: IsarExpenseType.operating,
        paymentMethod: IsarPaymentMethod.cash,
        categoryId: 'cat',
        createdAt: date ?? nov12,
        updatedAt: date ?? nov12,
        isSynced: true,
      );

  IsarProduct product(String id, double cost) =>
      IsarProduct.fromEntity(ProductFixtures.createProductEntity(
        id: id,
        sku: id,
        prices: [
          ProductFixtures.createProductPriceEntity(
              id: 'cost-$id',
              type: PriceType.cost,
              amount: cost,
              productId: id),
        ],
      ));

  Future<void> seed({
    List<IsarInvoice> invoices = const [],
    List<IsarExpense> expenses = const [],
    List<IsarProduct> products = const [],
  }) =>
      isar.writeTxn(() async {
        await isar.isarInvoices.putAll(invoices);
        await isar.isarExpenses.putAll(expenses);
        await isar.isarProducts.putAll(products);
      });

  Future<DashboardStatsModel> stats({DateTime? start, DateTime? end}) async =>
      (await ds.getCachedDashboardStats(
          startDate: start ?? nov12, endDate: end ?? endNov12))!;

  setUp(() async {
    isar = await openTestIsar();
    ds = DashboardLocalDataSourceIsar(
      database: TestIsarDatabase(isar),
      businessClock: bogota,
      now: () => DateTime(2026, 11, 12, 15),
    );
  });

  tearDown(() => closeTestIsar(isar));

  group('cobrado', () {
    test('es por fecha de pago: el abono de hoy a una factura vieja cuenta hoy',
        () async {
      await seed(invoices: [
        // Factura del 10, con un abono el 10 y otro el 12. Se volvió a
        // modificar el 14 (antes eso escondía el abono del 12).
        inv('vieja',
            date: nov10,
            total: 100000,
            status: IsarInvoiceStatus.partiallyPaid,
            payments: [
              pay(50000, DateTime.utc(2026, 11, 10, 15)),
              pay(30000, nov12Afternoon),
            ],
            updatedAt: DateTime.utc(2026, 11, 14, 15)),
        // Factura de hoy a crédito: facturada, no cobrada.
        inv('credito',
            date: nov12, total: 40000, status: IsarInvoiceStatus.pending),
      ]);

      final hoy = await stats();
      expect(hoy.totalCollected, 30000);
      expect(hoy.totalBilled, 40000);
      expect(hoy.incomeTypeBreakdown.paymentsOnOldInvoices, 30000);
      expect(hoy.incomeTypeBreakdown.newInvoices, 40000);
      expect(hoy.incomeTypeBreakdown.invoices, 70000);

      final el10 = await stats(
          start: nov10, end: DateTime(2026, 11, 10, 23, 59, 59));
      expect(el10.totalCollected, 50000);
      expect(el10.totalBilled, 100000);
    });

    test('no cuenta saldo a favor, ajuste Bre-B, anuladas ni borradas',
        () async {
      await seed(invoices: [
        inv('breb', date: nov12, total: 17003, payments: [
          pay(12000, nov12Afternoon,
              method: PaymentMethod.bankTransfer, channel: 'breb'),
          pay(5000, nov12Afternoon, method: PaymentMethod.clientBalance),
          pay(3, nov12Afternoon,
              method: PaymentMethod.other,
              channel: InvoicePayment.brebAdjustmentChannel),
        ]),
        inv('anulada',
            date: nov12,
            total: 9000,
            status: IsarInvoiceStatus.cancelled,
            payments: [pay(9000, nov12Afternoon)]),
        inv('borrada',
            date: nov12,
            total: 1000,
            payments: [pay(1000, nov12Afternoon)],
            deletedAt: nov12Afternoon),
      ]);

      final s = await stats();
      expect(s.totalCollected, 12000);
      expect(s.sales.totalAmount, 12000);
      // El desglose por método suma exactamente lo cobrado; Bre-B aparte.
      expect(s.paymentMethodsBreakdown.map((m) => m.method), ['Bre-B']);
      expect(s.paymentMethodsBreakdown.single.totalAmount, 12000);
    });

    test('factura sin detalle de pagos: lo pagado cuenta en su fecha', () async {
      await seed(invoices: [inv('sin-detalle', date: nov12, total: 8000, paid: 8000)]);
      expect((await stats()).totalCollected, 8000);
    });
  });

  test('facturado: sin anuladas, borradores ni borradas', () async {
    await seed(invoices: [
      inv('pagada', date: nov12, total: 20000, payments: [pay(20000, nov12Afternoon)]),
      inv('credito', date: nov12, total: 40000, status: IsarInvoiceStatus.pending),
      inv('anulada', date: nov12, total: 9000, status: IsarInvoiceStatus.cancelled),
      inv('borrador', date: nov12, total: 7000, status: IsarInvoiceStatus.draft),
      inv('borrada', date: nov12, total: 1000, deletedAt: nov12Afternoon),
    ]);

    final s = await stats();
    expect(s.totalBilled, 60000);
    expect(s.invoices.totalInvoices, 2);
    expect(s.invoices.paidInvoices, 1);
    expect(s.invoices.pendingInvoices, 1);
  });

  test('gastos: solo aprobados o pagados, en el total, la tendencia y por categoría',
      () async {
    await seed(expenses: [
      exp('aprobado', 1000, IsarExpenseStatus.approved),
      exp('pagado', 2000, IsarExpenseStatus.paid),
      exp('pendiente', 4000, IsarExpenseStatus.pending),
      exp('borrador', 8000, IsarExpenseStatus.draft),
      exp('rechazado', 16000, IsarExpenseStatus.rejected),
      exp('otro-dia', 32000, IsarExpenseStatus.paid, date: nov10),
    ]);

    final s = await stats();
    expect(s.expenses.totalAmount, 3000);
    expect(s.expenses.todayExpenses, 3000);
    expect(s.trend.single.expenses, 3000);
    expect(s.expenses.expensesByCategory, {'cat': 3000.0});
    expect(
      await ds.getOfflineExpensesByCategory(startDate: nov12, endDate: endNov12),
      {'cat': 3000.0},
    );
  });

  group('utilidad', () {
    test('ventas devengadas contra el costo guardado en la línea; la pérdida se ve',
        () async {
      await seed(
        products: [product('p1', 1000), product('p2', 15000)],
        invoices: [
          // A crédito, sin cobrar: cuenta. Su línea guardó un costo de 50.000
          // (el costo actual de p1, 1.000, no se usa).
          inv('credito',
              date: nov12,
              total: 40000,
              status: IsarInvoiceStatus.pending,
              lines: [line('p1', 2, 20000, totalCost: 50000)]),
          // Sin costo en la línea: se usa el costo actual de p2.
          inv('pagada',
              date: nov12,
              total: 20000,
              payments: [pay(20000, nov12Afternoon)],
              lines: [line('p2', 1, 20000)]),
          inv('anulada',
              date: nov12,
              total: 9000,
              status: IsarInvoiceStatus.cancelled,
              lines: [line('p2', 1, 9000)]),
          inv('acreditada',
              date: nov12,
              total: 5000,
              status: IsarInvoiceStatus.credited,
              lines: [line('p2', 1, 5000)]),
        ],
        expenses: [exp('pagado', 3000, IsarExpenseStatus.paid)],
      );

      final p = (await stats()).profitability;
      expect(p.totalRevenue, 60000);
      expect(p.totalCOGS, 65000);
      expect(p.grossProfit, -5000);
      expect(p.netProfit, -8000);
      expect(p.grossMarginPercentage, lessThan(0));

      // La rentabilidad sin conexión usa la misma definición.
      final offline = (await ds.getOfflineProfitabilityStats(
          startDate: nov12, endDate: endNov12))!;
      expect(offline.grossProfit, -5000);
      expect(offline.netProfit, -8000);
    });
  });

  group('día del negocio', () {
    test('la tendencia ubica un pago de las 10 p. m. en ese día, no en el siguiente (UTC)',
        () async {
      await seed(invoices: [
        inv('noche', date: nov12, total: 500, payments: [pay(500, nov12Night)]),
      ]);

      final s = await stats(
          start: nov12, end: DateTime(2026, 11, 13, 23, 59, 59));
      expect(s.trend.map((t) => t.date),
          [DateTime(2026, 11, 12), DateTime(2026, 11, 13)]);
      expect(s.trend[0].revenue, 500);
      expect(s.trend[0].billed, 500);
      expect(s.trend[1].revenue, 0);

      // Y en el período "solo 13-nov" ese pago no aparece.
      final el13 = await stats(
          start: DateTime(2026, 11, 13),
          end: DateTime(2026, 11, 13, 23, 59, 59));
      expect(el13.totalCollected, 0);
    });

    test('ventas de hoy incluye las facturas con fecha a medianoche', () async {
      await seed(invoices: [
        // Como llega del servidor: solo fecha → medianoche exacta.
        inv('medianoche',
            date: nov12,
            total: 6000,
            payments: [pay(6000, DateTime(2026, 11, 12))]),
      ]);

      final s = await stats();
      expect(s.sales.todaySales, 6000);
      expect(s.invoices.todayInvoices, 1);
    });
  });

  test('el canal y el costo de la línea sobreviven al guardado en el equipo',
      () {
    final payments = IsarInvoice.decodePayments(IsarInvoice.encodePayments([
      pay(3, nov12Afternoon,
          method: PaymentMethod.other,
          channel: InvoicePayment.brebAdjustmentChannel),
      pay(10, nov12Afternoon),
    ]));
    expect(payments.first.isBrebAdjustment, isTrue);
    expect(payments.last.channel, isNull);

    final items = IsarInvoice.decodeItemsPublic(
        '[${line('p1', 2, 100, totalCost: 150)},${line('p1', 1, 100)}]');
    expect(items.first.totalCost, 150);
    expect(items.last.totalCost, isNull);

    // Y se leen de lo que manda el servidor.
    final fromServer = InvoicePaymentModel.fromJson({
      'id': 'p',
      'amount': 3,
      'paymentMethod': 'other',
      'paymentDate': '2026-11-12T20:00:00.000Z',
      'channel': 'breb_adjustment',
    });
    expect(fromServer.toEntity().isBrebAdjustment, isTrue);
    final item = InvoiceItemModel.fromJson({
      'id': 'l',
      'quantity': 2,
      'unitPrice': '100.00',
      'unitCost': '75.0000',
      'totalCost': '150.00',
    });
    expect(item.unitCost, 75);
    expect(item.totalCost, 150);
  });
}
