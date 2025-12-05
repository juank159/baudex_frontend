// lib/features/invoices/data/models/invoice_stats_model.dart
import '../../domain/entities/invoice_stats.dart';

class InvoiceStatsModel extends InvoiceStats {
  const InvoiceStatsModel({
    required super.total,
    required super.draft,
    required super.pending,
    required super.paid,
    required super.overdue,
    required super.cancelled,
    required super.partiallyPaid,
    required super.totalSales,
    required super.pendingAmount,
    required super.overdueAmount,
  });

  factory InvoiceStatsModel.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceStatsModel(
        total: _parseInt(json['total']) ?? 0,
        draft: _parseInt(json['draft']) ?? 0,
        pending: _parseInt(json['pending']) ?? 0,
        paid: _parseInt(json['paid']) ?? 0,
        overdue: _parseInt(json['overdue']) ?? 0,
        cancelled: _parseInt(json['cancelled']) ?? 0,
        partiallyPaid: _parseInt(json['partiallyPaid']) ?? 0,
        totalSales: _parseDouble(json['totalSales']) ?? 0.0,
        pendingAmount: _parseDouble(json['pendingAmount']) ?? 0.0,
        overdueAmount: _parseDouble(json['overdueAmount']) ?? 0.0,
      );
    } catch (e) {
      print('❌ Error parsing InvoiceStatsModel: $e');
      print('📄 JSON data: $json');

      // Retornar estadísticas vacías en caso de error
      return const InvoiceStatsModel(
        total: 0,
        draft: 0,
        pending: 0,
        paid: 0,
        overdue: 0,
        cancelled: 0,
        partiallyPaid: 0,
        totalSales: 0.0,
        pendingAmount: 0.0,
        overdueAmount: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'draft': draft,
      'pending': pending,
      'paid': paid,
      'overdue': overdue,
      'cancelled': cancelled,
      'partiallyPaid': partiallyPaid,
      'totalSales': totalSales,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
    };
  }

  factory InvoiceStatsModel.fromEntity(InvoiceStats stats) {
    return InvoiceStatsModel(
      total: stats.total,
      draft: stats.draft,
      pending: stats.pending,
      paid: stats.paid,
      overdue: stats.overdue,
      cancelled: stats.cancelled,
      partiallyPaid: stats.partiallyPaid,
      totalSales: stats.totalSales,
      pendingAmount: stats.pendingAmount,
      overdueAmount: stats.overdueAmount,
    );
  }

  // Método para validar que los datos sean consistentes
  bool get isValid {
    // Solo validar que los montos no sean negativos
    // No validar suma de estados porque puede haber facturas con estados
    // adicionales (credited, partially_credited) que no se cuentan aquí
    return totalSales >= 0 && pendingAmount >= 0 && overdueAmount >= 0;
  }

  // Helpers para parsing seguro
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Factory para crear estadísticas desde una lista de facturas (útil para cache)
  factory InvoiceStatsModel.fromInvoiceList(List<dynamic> invoices) {
    int total = 0;
    int draft = 0;
    int pending = 0;
    int paid = 0;
    int overdue = 0;
    int cancelled = 0;
    int partiallyPaid = 0;
    double totalSales = 0;
    double pendingAmount = 0;
    double overdueAmount = 0;

    final now = DateTime.now();

    for (final invoice in invoices) {
      total++;

      final status = invoice['status'] as String? ?? 'draft';
      final amount = _parseDouble(invoice['total']) ?? 0.0;
      final dueDate =
          invoice['dueDate'] != null
              ? DateTime.tryParse(invoice['dueDate'] as String)
              : null;
      final isOverdue = dueDate != null && dueDate.isBefore(now);

      totalSales += amount;

      switch (status) {
        case 'draft':
          draft++;
          break;
        case 'pending':
          if (isOverdue) {
            overdue++;
            overdueAmount += amount;
          } else {
            pending++;
            pendingAmount += amount;
          }
          break;
        case 'paid':
          paid++;
          break;
        case 'overdue':
          overdue++;
          overdueAmount += amount;
          break;
        case 'cancelled':
          cancelled++;
          break;
        case 'partially_paid':
          if (isOverdue) {
            overdue++;
            overdueAmount += amount;
          } else {
            partiallyPaid++;
            pendingAmount += amount;
          }
          break;
      }
    }

    return InvoiceStatsModel(
      total: total,
      draft: draft,
      pending: pending,
      paid: paid,
      overdue: overdue,
      cancelled: cancelled,
      partiallyPaid: partiallyPaid,
      totalSales: totalSales,
      pendingAmount: pendingAmount,
      overdueAmount: overdueAmount,
    );
  }

  /// Convierte el modelo a entidad de dominio
  InvoiceStats toEntity() {
    return InvoiceStats(
      total: total,
      draft: draft,
      pending: pending,
      paid: paid,
      overdue: overdue,
      cancelled: cancelled,
      partiallyPaid: partiallyPaid,
      totalSales: totalSales,
      pendingAmount: pendingAmount,
      overdueAmount: overdueAmount,
    );
  }

  @override
  String toString() {
    return 'InvoiceStatsModel(total: $total, draft: $draft, pending: $pending, paid: $paid, overdue: $overdue, cancelled: $cancelled, partiallyPaid: $partiallyPaid, totalSales: $totalSales, pendingAmount: $pendingAmount, overdueAmount: $overdueAmount)';
  }
}
