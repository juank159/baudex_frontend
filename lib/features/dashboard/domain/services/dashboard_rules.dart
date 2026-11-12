// lib/features/dashboard/domain/services/dashboard_rules.dart
import '../../../expenses/domain/entities/expense.dart' show ExpenseStatus;
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_payment.dart';

/// Convierte un instante a la hora del reloj del negocio (zona del tenant).
typedef BusinessClock = DateTime Function(DateTime instant);

/// Período del tablero en días calendario del negocio (ambos inclusive).
/// `null` en un extremo = sin límite por ese lado.
class BusinessPeriod {
  final DateTime? firstDay;
  final DateTime? lastDay;

  const BusinessPeriod._(this.firstDay, this.lastDay);

  /// Del rango que elige el usuario solo importa el día (año/mes/día); la
  /// hora se ignora. Es lo mismo que se le manda al servidor (`YYYY-MM-DD`).
  factory BusinessPeriod.fromRange(DateTime? start, DateTime? end) =>
      BusinessPeriod._(
        start == null ? null : DateTime(start.year, start.month, start.day),
        end == null ? null : DateTime(end.year, end.month, end.day),
      );

  /// [day] ya debe ser un día del negocio (ver [DashboardRules.businessDay]).
  bool contains(DateTime day) =>
      (firstDay == null || !day.isBefore(firstDay!)) &&
      (lastDay == null || !day.isAfter(lastDay!));
}

/// Línea de una factura, con lo necesario para calcular la utilidad.
class SaleLine {
  final String? productId;
  final double quantity;
  final double unitPrice;

  /// Factor de la presentación vendida (caja x12 → 12). `null` = unidad base.
  final double? presentationFactor;

  /// Costo guardado en la línea al facturar. `null` = no existe.
  final double? unitCost;
  final double? totalCost;

  const SaleLine({
    this.productId,
    required this.quantity,
    required this.unitPrice,
    this.presentationFactor,
    this.unitCost,
    this.totalCost,
  });

  double get revenue => unitPrice * quantity;
}

/// Factura reducida a lo que el tablero necesita.
class SaleRecord {
  final String id;
  final InvoiceStatus status;
  final DateTime date;
  final double total;
  final List<InvoicePayment> payments;
  final List<SaleLine> lines;

  const SaleRecord({
    required this.id,
    required this.status,
    required this.date,
    required this.total,
    this.payments = const [],
    this.lines = const [],
  });
}

/// Un pago que cuenta como dinero recibido en el período, con su factura y
/// el día del negocio en que entró.
class CollectedPayment {
  final SaleRecord invoice;
  final InvoicePayment payment;
  final DateTime day;

  /// La factura es de otra fecha: es un abono a una factura anterior.
  final bool onInvoiceOutsidePeriod;

  const CollectedPayment({
    required this.invoice,
    required this.payment,
    required this.day,
    required this.onInvoiceOutsidePeriod,
  });
}

/// Utilidad del período (definición 4).
class ProfitSummary {
  final double salesRevenue;
  final double costOfGoodsSold;
  final double expenses;
  final int salesCount;

  const ProfitSummary({
    required this.salesRevenue,
    required this.costOfGoodsSold,
    required this.expenses,
    required this.salesCount,
  });

  /// Puede ser negativa: una pérdida se muestra como pérdida.
  double get grossProfit => salesRevenue - costOfGoodsSold;
  double get netProfit => grossProfit - expenses;
  double get grossMarginPercentage =>
      salesRevenue > 0 ? (grossProfit / salesRevenue) * 100 : 0.0;
  double get netMarginPercentage =>
      salesRevenue > 0 ? (netProfit / salesRevenue) * 100 : 0.0;
  double get averageMarginPerSale =>
      salesCount > 0 ? grossProfit / salesCount : 0.0;
}

/// Definiciones únicas del tablero. Son las mismas del servidor
/// (`dashboard-query.builder.ts` y `profitability.service.ts`): la app sin
/// conexión debe dar las mismas cifras.
///
/// Funciones puras: no leen la base ni el reloj.
class DashboardRules {
  DashboardRules._();

  // ───────── Definición 5: día del negocio ─────────

  /// Día calendario del negocio al que pertenece [value].
  ///
  /// - Las fechas de factura y de gasto que vienen del servidor son solo
  ///   fecha (`2026-11-12`) y quedan guardadas a medianoche exacta: ese ya es
  ///   el día, no se convierte de zona (convertirlo lo correría al día
  ///   anterior en equipos con otra zona).
  /// - Cualquier otro valor es un instante (pagos, facturas hechas en el
  ///   equipo): su día es el del reloj del negocio, no UTC ni el del equipo.
  static DateTime businessDay(DateTime value, BusinessClock toBusinessTime) {
    final isDateOnly = value.hour == 0 &&
        value.minute == 0 &&
        value.second == 0 &&
        value.millisecond == 0 &&
        value.microsecond == 0;
    final d = isDateOnly ? value : toBusinessTime(value);
    return DateTime(d.year, d.month, d.day);
  }

  // ───────── Definición 1: cobrado ─────────

  /// Dinero recibido: no es saldo a favor aplicado (ese dinero ya entró
  /// cuando el cliente lo depositó) ni el ajuste de redondeo de Bre-B.
  static bool isRealMoney(InvoicePayment payment) =>
      payment.paymentMethod != PaymentMethod.clientBalance &&
      !payment.isBrebAdjustment;

  /// Los pagos de una factura anulada no cuentan como cobrado.
  static bool invoiceCountsForCollected(InvoiceStatus status) =>
      status != InvoiceStatus.cancelled;

  /// Pagos cobrados en el período: por FECHA DE PAGO (no la de la factura),
  /// de facturas no anuladas, sin saldo a favor ni ajuste Bre-B.
  ///
  /// [invoices] debe traer todas las facturas no borradas que puedan tener
  /// pagos en el período, sean o no del período.
  static List<CollectedPayment> collectedPayments({
    required Iterable<SaleRecord> invoices,
    required BusinessPeriod period,
    required BusinessClock toBusinessTime,
  }) {
    final result = <CollectedPayment>[];
    for (final invoice in invoices) {
      if (!invoiceCountsForCollected(invoice.status)) continue;
      final invoiceInPeriod =
          period.contains(businessDay(invoice.date, toBusinessTime));
      for (final payment in invoice.payments) {
        if (!isRealMoney(payment)) continue;
        final day = businessDay(payment.paymentDate, toBusinessTime);
        if (!period.contains(day)) continue;
        result.add(CollectedPayment(
          invoice: invoice,
          payment: payment,
          day: day,
          onInvoiceOutsidePeriod: !invoiceInPeriod,
        ));
      }
    }
    return result;
  }

  // ───────── Definición 2: facturado ─────────

  /// Una factura anulada o en borrador no es una venta.
  static bool isBilled(InvoiceStatus status) =>
      status != InvoiceStatus.cancelled && status != InvoiceStatus.draft;

  /// Facturas facturadas con fecha en el período.
  static List<SaleRecord> billedInvoices({
    required Iterable<SaleRecord> invoices,
    required BusinessPeriod period,
    required BusinessClock toBusinessTime,
  }) =>
      invoices
          .where((i) =>
              isBilled(i.status) &&
              period.contains(businessDay(i.date, toBusinessTime)))
          .toList();

  // ───────── Definición 3: gastos ─────────

  /// Solo gastos aprobados o pagados; ni pendientes, ni borradores, ni
  /// rechazados. Vale igual para el total y para la tendencia diaria.
  static bool expenseCounts(ExpenseStatus status) =>
      status == ExpenseStatus.approved || status == ExpenseStatus.paid;

  // ───────── Definición 4: utilidad ─────────

  /// Venta devengada: emitida y no acreditada por completo.
  static bool isAccruedSale(InvoiceStatus status) =>
      status != InvoiceStatus.draft &&
      status != InvoiceStatus.cancelled &&
      status != InvoiceStatus.credited;

  /// Costo de una línea: el guardado en la línea si existe; solo si no
  /// existe, el costo actual del producto ([currentUnitCost], por unidad
  /// base). Sin ninguno de los dos, 0 (igual que el servidor).
  static double lineCost(SaleLine line, {double? currentUnitCost}) {
    if (line.totalCost != null) return line.totalCost!;
    if (line.unitCost != null) return line.unitCost! * line.quantity;
    if (currentUnitCost == null) return 0.0;
    return currentUnitCost * line.quantity * (line.presentationFactor ?? 1);
  }

  /// Utilidad bruta = ventas devengadas del período (precio × cantidad de
  /// cada línea) − costo de esas mismas líneas. Neta = bruta − [expenses].
  static ProfitSummary profit({
    required Iterable<SaleRecord> invoices,
    required BusinessPeriod period,
    required BusinessClock toBusinessTime,
    required double expenses,
    Map<String, double> currentUnitCosts = const {},
  }) {
    double revenue = 0, cogs = 0;
    int count = 0;
    for (final invoice in invoices) {
      if (!isAccruedSale(invoice.status)) continue;
      if (!period.contains(businessDay(invoice.date, toBusinessTime))) continue;
      count++;
      for (final line in invoice.lines) {
        revenue += line.revenue;
        cogs += lineCost(line, currentUnitCost: currentUnitCosts[line.productId]);
      }
    }
    return ProfitSummary(
      salesRevenue: revenue,
      costOfGoodsSold: cogs,
      expenses: expenses,
      salesCount: count,
    );
  }

  // ───────── Servidor / local ─────────

  /// Con respuesta del servidor se muestran sus cifras completas (nunca "el
  /// mayor de los dos" ni una mezcla por campos). La única razón para dejar
  /// lo local es que haya cambios del equipo sin subir (facturas o abonos
  /// hechos sin conexión): el servidor aún no los conoce, así que no se le
  /// pregunta y queda el cálculo local, que sí los incluye. No se suman a las
  /// cifras del servidor porque un cambio pendiente puede ser un abono a una
  /// factura que el servidor ya tiene, y sumarlo por partes la contaría dos
  /// veces. Al terminar de subir, el tablero vuelve a pedir las del servidor.
  static bool shouldAskServer({required int pendingSyncOperations}) =>
      pendingSyncOperations <= 0;

  // ───────── Caché de rentabilidad ─────────

  /// Clave de la caché de rentabilidad: por organización y por rango, para
  /// que otra empresa en el mismo equipo no vea cifras ajenas.
  static String profitabilityCacheKey({
    required String organizationId,
    DateTime? start,
    DateTime? end,
  }) {
    String day(DateTime? d) => d == null
        ? 'null'
        : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
    final range = start == null && end == null ? 'all' : '${day(start)}_${day(end)}';
    return 'dashboard_profitability_${organizationId}_$range';
  }
}
