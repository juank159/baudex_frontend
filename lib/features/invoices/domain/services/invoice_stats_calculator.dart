// lib/features/invoices/domain/services/invoice_stats_calculator.dart
// Servicio de cálculo de estadísticas de facturas
// Principio DRY - Centraliza toda la lógica de cálculo de estadísticas
// para garantizar consistencia en toda la aplicación

import '../entities/invoice.dart';

/// Resultado del cálculo de estadísticas de facturas
class InvoiceStatsResult {
  // Contadores
  final int total;
  final int paid;
  final int pending;
  final int overdue;
  final int partiallyPaid;
  final int draft;
  final int cancelled;

  // Montos
  final double totalSales;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;

  const InvoiceStatsResult({
    required this.total,
    required this.paid,
    required this.pending,
    required this.overdue,
    required this.partiallyPaid,
    required this.draft,
    required this.cancelled,
    required this.totalSales,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
  });

  /// Factory para resultado vacío
  factory InvoiceStatsResult.empty() => const InvoiceStatsResult(
    total: 0,
    paid: 0,
    pending: 0,
    overdue: 0,
    partiallyPaid: 0,
    draft: 0,
    cancelled: 0,
    totalSales: 0,
    paidAmount: 0,
    pendingAmount: 0,
    overdueAmount: 0,
  );

  // Getters de porcentajes
  double get paidPercentage => total > 0 ? (paid / total) * 100 : 0;
  double get pendingPercentage => total > 0 ? (pending / total) * 100 : 0;
  double get overduePercentage => total > 0 ? (overdue / total) * 100 : 0;
  double get collectionRate => totalSales > 0 ? (paidAmount / totalSales) * 100 : 100;

  // Indicadores de salud
  bool get hasOverdueIssues => overduePercentage > 20;
  bool get hasCollectionIssues => collectionRate < 80;
  bool get isHealthy => !hasOverdueIssues && !hasCollectionIssues;

  /// Convierte a Map para compatibilidad con código existente
  Map<String, int> toStatsMap() => {
    'total': total,
    'paid': paid,
    'pending': pending,
    'overdue': overdue,
    'partiallyPaid': partiallyPaid,
    'draft': draft,
    'cancelled': cancelled,
  };

  /// Convierte montos a Map para compatibilidad
  Map<String, double> toAmountsMap() => {
    'totalSales': totalSales,
    'paidAmount': paidAmount,
    'pendingAmount': pendingAmount,
    'overdueAmount': overdueAmount,
  };

  @override
  String toString() => 'InvoiceStatsResult('
      'total: $total, paid: $paid, pending: $pending, '
      'overdue: $overdue, partiallyPaid: $partiallyPaid)';
}

/// Calculador centralizado de estadísticas de facturas
///
/// Este servicio implementa la lógica de negocio para calcular estadísticas
/// de manera consistente en toda la aplicación. Usa la propiedad `isOverdue`
/// de la entidad Invoice para garantizar consistencia.
///
/// Uso:
/// ```dart
/// final stats = InvoiceStatsCalculator.calculate(invoices);
/// final filteredStats = InvoiceStatsCalculator.calculateForPeriod(
///   invoices,
///   startDate: DateTime(2024, 1, 1),
///   endDate: DateTime(2024, 12, 31),
/// );
/// ```
class InvoiceStatsCalculator {
  /// Calcula estadísticas a partir de una lista de facturas
  ///
  /// Reglas de negocio:
  /// - **Pagada**: status == paid O balanceDue <= 0
  /// - **Pendiente**: (status == pending O partiallyPaid) Y NO isOverdue Y balanceDue > 0
  /// - **Vencida**: Usa invoice.isOverdue (lógica centralizada en la entidad)
  /// - **Pago Parcial**: status == partiallyPaid Y NO isOverdue
  /// - **Borrador**: status == draft
  /// - **Cancelada**: status == cancelled
  static InvoiceStatsResult calculate(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return InvoiceStatsResult.empty();
    }

    int paidCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;
    int partiallyPaidCount = 0;
    int draftCount = 0;
    int cancelledCount = 0;

    double totalSales = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    double overdueAmount = 0;

    for (final invoice in invoices) {
      // Sumar al total de ventas (excepto borradores y canceladas)
      if (invoice.status != InvoiceStatus.draft &&
          invoice.status != InvoiceStatus.cancelled) {
        totalSales += invoice.total;
      }

      // Clasificar por estado usando la lógica de isOverdue de la entidad
      if (invoice.status == InvoiceStatus.draft) {
        draftCount++;
      } else if (invoice.status == InvoiceStatus.cancelled) {
        cancelledCount++;
      } else if (invoice.status == InvoiceStatus.paid || invoice.balanceDue <= 0) {
        // Pagada: status paid O saldo en cero
        paidCount++;
        paidAmount += invoice.total;
      } else if (invoice.isOverdue) {
        // Vencida: usa la lógica centralizada de la entidad
        overdueCount++;
        overdueAmount += invoice.balanceDue;
      } else if (invoice.status == InvoiceStatus.partiallyPaid) {
        // Pago parcial (no vencido)
        partiallyPaidCount++;
        final amountPaid = invoice.total - invoice.balanceDue;
        paidAmount += amountPaid;
        pendingAmount += invoice.balanceDue;
      } else {
        // Pendiente (no vencido)
        pendingCount++;
        pendingAmount += invoice.balanceDue;
      }
    }

    return InvoiceStatsResult(
      total: invoices.length,
      paid: paidCount,
      pending: pendingCount,
      overdue: overdueCount,
      partiallyPaid: partiallyPaidCount,
      draft: draftCount,
      cancelled: cancelledCount,
      totalSales: totalSales,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      overdueAmount: overdueAmount,
    );
  }

  /// Calcula estadísticas filtrando por período de fechas
  ///
  /// [invoices] Lista de facturas a procesar
  /// [startDate] Fecha de inicio del período (inclusive)
  /// [endDate] Fecha de fin del período (inclusive)
  /// [useInvoiceDate] Si es true, usa la fecha de la factura; si no, usa createdAt
  static InvoiceStatsResult calculateForPeriod(
    List<Invoice> invoices, {
    required DateTime startDate,
    required DateTime endDate,
    bool useInvoiceDate = true,
  }) {
    // Normalizar fechas a inicio/fin del día
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Filtrar facturas por período
    final filteredInvoices = invoices.where((invoice) {
      final date = useInvoiceDate ? invoice.date : invoice.createdAt;
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    return calculate(filteredInvoices);
  }

  /// Obtiene solo las facturas vencidas de una lista
  static List<Invoice> getOverdueInvoices(List<Invoice> invoices) {
    return invoices.where((invoice) => invoice.isOverdue).toList();
  }

  /// Obtiene facturas que vencen pronto (dentro de N días)
  static List<Invoice> getDueSoonInvoices(List<Invoice> invoices, {int days = 3}) {
    return invoices.where((invoice) {
      if (invoice.isOverdue || invoice.isPaid) return false;
      return invoice.daysUntilDue > 0 && invoice.daysUntilDue <= days;
    }).toList();
  }

  /// Obtiene facturas pendientes (no vencidas, no pagadas)
  static List<Invoice> getPendingInvoices(List<Invoice> invoices) {
    return invoices.where((invoice) {
      return !invoice.isOverdue &&
             !invoice.isPaid &&
             invoice.status != InvoiceStatus.draft &&
             invoice.status != InvoiceStatus.cancelled &&
             invoice.balanceDue > 0;
    }).toList();
  }
}
