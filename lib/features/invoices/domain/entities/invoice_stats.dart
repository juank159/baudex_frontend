// lib/features/invoices/domain/entities/invoice_stats.dart
import 'package:equatable/equatable.dart';

class InvoiceStats extends Equatable {
  final int total;
  final int draft;
  final int pending;
  final int paid;
  final int overdue;
  final int cancelled;
  final int partiallyPaid;
  final double totalSales;
  final double pendingAmount;
  final double overdueAmount;

  const InvoiceStats({
    required this.total,
    required this.draft,
    required this.pending,
    required this.paid,
    required this.overdue,
    required this.cancelled,
    required this.partiallyPaid,
    required this.totalSales,
    required this.pendingAmount,
    required this.overdueAmount,
  });

  @override
  List<Object?> get props => [
    total,
    draft,
    pending,
    paid,
    overdue,
    cancelled,
    partiallyPaid,
    totalSales,
    pendingAmount,
    overdueAmount,
  ];

  // Getters útiles para porcentajes
  double get paidPercentage {
    if (total == 0) return 0;
    return (paid / total) * 100;
  }

  double get pendingPercentage {
    if (total == 0) return 0;
    return ((pending + partiallyPaid) / total) * 100;
  }

  double get overduePercentage {
    if (total == 0) return 0;
    return (overdue / total) * 100;
  }

  double get collectionRate {
    if (totalSales == 0) return 0;
    return ((totalSales - pendingAmount) / totalSales) * 100;
  }

  /// Monto total de facturas que requieren atención (pendientes + parcialmente pagadas)
  double get pendingAndPartialAmount {
    return pendingAmount + overdueAmount;
  }

  int get activeInvoices {
    return pending + overdue + partiallyPaid;
  }

  double get activeAmount {
    return pendingAmount + overdueAmount;
  }

  // Indicadores de salud financiera
  bool get hasOverdueIssues => overduePercentage > 20;
  bool get hasCollectionIssues => collectionRate < 80;
  bool get isHealthy => !hasOverdueIssues && !hasCollectionIssues;

  InvoiceStats copyWith({
    int? total,
    int? draft,
    int? pending,
    int? paid,
    int? overdue,
    int? cancelled,
    int? partiallyPaid,
    double? totalSales,
    double? pendingAmount,
    double? overdueAmount,
  }) {
    return InvoiceStats(
      total: total ?? this.total,
      draft: draft ?? this.draft,
      pending: pending ?? this.pending,
      paid: paid ?? this.paid,
      overdue: overdue ?? this.overdue,
      cancelled: cancelled ?? this.cancelled,
      partiallyPaid: partiallyPaid ?? this.partiallyPaid,
      totalSales: totalSales ?? this.totalSales,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      overdueAmount: overdueAmount ?? this.overdueAmount,
    );
  }

  factory InvoiceStats.empty() {
    return const InvoiceStats(
      total: 0,
      draft: 0,
      pending: 0,
      paid: 0,
      overdue: 0,
      cancelled: 0,
      partiallyPaid: 0,
      totalSales: 0,
      pendingAmount: 0,
      overdueAmount: 0,
    );
  }
}
