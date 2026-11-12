import 'package:baudex_desktop/features/dashboard/domain/services/dashboard_rules.dart';
import 'package:baudex_desktop/features/expenses/domain/entities/expense.dart'
    show ExpenseStatus;
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reloj del negocio para las pruebas: Bogotá (UTC-5, sin horario de verano).
DateTime bogota(DateTime instant) =>
    instant.toUtc().subtract(const Duration(hours: 5));

InvoicePayment pay(
  double amount,
  DateTime date, {
  PaymentMethod method = PaymentMethod.cash,
  String? channel,
}) =>
    InvoicePayment(
      id: 'p',
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

SaleRecord sale(
  String id,
  DateTime date, {
  InvoiceStatus status = InvoiceStatus.paid,
  double total = 0,
  List<InvoicePayment> payments = const [],
  List<SaleLine> lines = const [],
}) =>
    SaleRecord(
      id: id,
      status: status,
      date: date,
      total: total,
      payments: payments,
      lines: lines,
    );

void main() {
  final nov12 = BusinessPeriod.fromRange(
      DateTime(2026, 11, 12), DateTime(2026, 11, 12, 23, 59, 59));

  double collected(Iterable<SaleRecord> invoices, [BusinessPeriod? period]) =>
      DashboardRules.collectedPayments(
        invoices: invoices,
        period: period ?? nov12,
        toBusinessTime: bogota,
      ).fold(0.0, (sum, c) => sum + c.payment.amount);

  group('día del negocio (definición 5)', () {
    test('un instante se ubica en el día de la zona del negocio, no en UTC', () {
      // 13-nov 03:00 UTC = 12-nov 22:00 en Bogotá.
      final day = DashboardRules.businessDay(
          DateTime.utc(2026, 11, 13, 3), bogota);
      expect(day, DateTime(2026, 11, 12));
    });

    test('una fecha sin hora (factura o gasto del servidor) conserva su día', () {
      expect(DashboardRules.businessDay(DateTime(2026, 11, 12), bogota),
          DateTime(2026, 11, 12));
      expect(DashboardRules.businessDay(DateTime.utc(2026, 11, 12), bogota),
          DateTime(2026, 11, 12));
    });

    test('el período incluye el primer y el último día completos', () {
      expect(nov12.contains(DateTime(2026, 11, 12)), isTrue);
      expect(nov12.contains(DateTime(2026, 11, 11)), isFalse);
      expect(nov12.contains(DateTime(2026, 11, 13)), isFalse);
    });
  });

  group('cobrado (definición 1)', () {
    test('cuenta por fecha de pago, no por fecha de factura', () {
      final invoices = [
        // Factura de ayer pagada hoy: es cobrado de hoy.
        sale('vieja', DateTime(2026, 11, 11),
            payments: [pay(100000, DateTime.utc(2026, 11, 12, 15))]),
        // Factura de hoy pagada mañana: no es cobrado de hoy.
        sale('hoy', DateTime(2026, 11, 12),
            payments: [pay(7000, DateTime.utc(2026, 11, 13, 15))]),
      ];
      expect(collected(invoices), 100000);

      final ayer = BusinessPeriod.fromRange(
          DateTime(2026, 11, 11), DateTime(2026, 11, 11, 23, 59, 59));
      expect(collected(invoices, ayer), 0);
    });

    test('marca los abonos a facturas de otra fecha', () {
      final result = DashboardRules.collectedPayments(
        invoices: [
          sale('vieja', DateTime(2026, 11, 1),
              payments: [pay(100, DateTime.utc(2026, 11, 12, 15))]),
          sale('hoy', DateTime(2026, 11, 12),
              payments: [pay(200, DateTime.utc(2026, 11, 12, 15))]),
        ],
        period: nov12,
        toBusinessTime: bogota,
      );
      expect(result.where((c) => c.onInvoiceOutsidePeriod).single.payment.amount,
          100);
    });

    test('no cuenta saldo a favor, ajuste de Bre-B ni facturas anuladas', () {
      final at = DateTime.utc(2026, 11, 12, 15);
      final invoices = [
        sale('ok', DateTime(2026, 11, 12), payments: [
          pay(12000, at, method: PaymentMethod.bankTransfer, channel: 'breb'),
          pay(5000, at, method: PaymentMethod.clientBalance),
          pay(3, at,
              method: PaymentMethod.other,
              channel: InvoicePayment.brebAdjustmentChannel),
          // "Otro" sin canal sí es dinero recibido.
          pay(40, at, method: PaymentMethod.other),
        ]),
        sale('anulada', DateTime(2026, 11, 12),
            status: InvoiceStatus.cancelled, payments: [pay(9000, at)]),
      ];
      expect(collected(invoices), 12040);
    });

    test('un pago de las 10 p. m. cuenta en ese día del negocio', () {
      final invoices = [
        sale('a', DateTime(2026, 11, 12),
            payments: [pay(500, DateTime.utc(2026, 11, 13, 3))]),
      ];
      expect(collected(invoices), 500);
    });
  });

  test('facturado (definición 2): sin anuladas ni borradores', () {
    final d = DateTime(2026, 11, 12);
    final billed = DashboardRules.billedInvoices(
      invoices: [
        sale('pagada', d, total: 1),
        sale('credito', d, status: InvoiceStatus.pending, total: 2),
        sale('parcial', d, status: InvoiceStatus.partiallyPaid, total: 4),
        sale('anulada', d, status: InvoiceStatus.cancelled, total: 8),
        sale('borrador', d, status: InvoiceStatus.draft, total: 16),
        sale('otro-dia', DateTime(2026, 11, 11), total: 32),
      ],
      period: nov12,
      toBusinessTime: bogota,
    );
    expect(billed.map((i) => i.id), ['pagada', 'credito', 'parcial']);
  });

  test('gastos (definición 3): solo aprobados o pagados', () {
    expect(
      ExpenseStatus.values.where(DashboardRules.expenseCounts),
      unorderedEquals([ExpenseStatus.approved, ExpenseStatus.paid]),
    );
  });

  group('utilidad (definición 4)', () {
    test('costo de la línea: el guardado; si no existe, el actual del producto', () {
      const stored = SaleLine(
          productId: 'p', quantity: 2, unitPrice: 100, totalCost: 150);
      const storedUnit =
          SaleLine(productId: 'p', quantity: 2, unitPrice: 100, unitCost: 60);
      const missing = SaleLine(productId: 'p', quantity: 2, unitPrice: 100);
      const box = SaleLine(
          productId: 'p', quantity: 2, unitPrice: 100, presentationFactor: 12);
      const zero =
          SaleLine(productId: 'p', quantity: 2, unitPrice: 100, totalCost: 0);

      expect(DashboardRules.lineCost(stored, currentUnitCost: 999), 150);
      expect(DashboardRules.lineCost(storedUnit, currentUnitCost: 999), 120);
      expect(DashboardRules.lineCost(missing, currentUnitCost: 40), 80);
      expect(DashboardRules.lineCost(box, currentUnitCost: 40), 960);
      expect(DashboardRules.lineCost(missing), 0);
      // Un costo guardado en 0 existe: no se reemplaza por el actual.
      expect(DashboardRules.lineCost(zero, currentUnitCost: 999), 0);
    });

    test('ventas devengadas contra su costo; la pérdida queda negativa', () {
      final d = DateTime(2026, 11, 12);
      const line = SaleLine(
          productId: 'p', quantity: 1, unitPrice: 1000, totalCost: 1300);
      final profit = DashboardRules.profit(
        invoices: [
          // Venta a crédito sin cobrar: cuenta (devengada).
          sale('credito', d, status: InvoiceStatus.pending, lines: [line]),
          sale('pagada', d, lines: [line]),
          sale('borrador', d, status: InvoiceStatus.draft, lines: [line]),
          sale('anulada', d, status: InvoiceStatus.cancelled, lines: [line]),
          sale('acreditada', d, status: InvoiceStatus.credited, lines: [line]),
          sale('otro-dia', DateTime(2026, 11, 11), lines: [line]),
        ],
        period: nov12,
        toBusinessTime: bogota,
        expenses: 100,
      );
      expect(profit.salesRevenue, 2000);
      expect(profit.costOfGoodsSold, 2600);
      expect(profit.grossProfit, -600);
      expect(profit.netProfit, -700);
      expect(profit.grossMarginPercentage, -30);
      expect(profit.salesCount, 2);
    });
  });

  test('servidor/local: solo se consulta al servidor sin cambios por subir', () {
    expect(DashboardRules.shouldAskServer(pendingSyncOperations: 0), isTrue);
    expect(DashboardRules.shouldAskServer(pendingSyncOperations: 3), isFalse);
  });

  test('la clave de caché de rentabilidad separa por organización y rango', () {
    final a = DashboardRules.profitabilityCacheKey(
        organizationId: 'org-a',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30, 23, 59, 59));
    final b = DashboardRules.profitabilityCacheKey(
        organizationId: 'org-b',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30, 23, 59, 59));
    expect(a, 'dashboard_profitability_org-a_2026-11-01_2026-11-30');
    expect(a, isNot(b));
    expect(
        DashboardRules.profitabilityCacheKey(organizationId: 'org-a'),
        'dashboard_profitability_org-a_all');
  });
}
