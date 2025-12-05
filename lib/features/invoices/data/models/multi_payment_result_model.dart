// lib/features/invoices/data/models/multi_payment_result_model.dart
import 'invoice_model.dart';
import 'invoice_payment_model.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_payment.dart';

/// Modelo de resultado de pagos múltiples
class MultiPaymentResultModel {
  final InvoiceModel invoice;
  final List<InvoicePaymentModel> payments;
  final double remainingBalance;
  final bool creditCreated;

  const MultiPaymentResultModel({
    required this.invoice,
    required this.payments,
    required this.remainingBalance,
    required this.creditCreated,
  });

  factory MultiPaymentResultModel.fromJson(Map<String, dynamic> json) {
    return MultiPaymentResultModel(
      invoice: InvoiceModel.fromJson(json['invoice'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => InvoicePaymentModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      remainingBalance: (json['remainingBalance'] is num)
          ? (json['remainingBalance'] as num).toDouble()
          : double.tryParse(json['remainingBalance']?.toString() ?? '0') ?? 0,
      creditCreated: json['creditCreated'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice': invoice.toJson(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'remainingBalance': remainingBalance,
      'creditCreated': creditCreated,
    };
  }

  /// Convertir a entidades de dominio
  MultiPaymentResult toEntity() {
    return MultiPaymentResult(
      invoice: invoice.toEntity(),
      payments: payments.map((p) => p.toEntity()).toList(),
      remainingBalance: remainingBalance,
      creditCreated: creditCreated,
    );
  }

  /// Cantidad de pagos realizados
  int get paymentCount => payments.length;

  /// Total pagado
  double get totalPaid => payments.fold(0, (sum, p) => sum + p.amount);

  /// Verificar si la factura quedó pagada completamente
  bool get isFullyPaid => remainingBalance <= 0;
}

/// Entidad de dominio para el resultado de pagos múltiples
class MultiPaymentResult {
  final Invoice invoice;
  final List<InvoicePayment> payments;
  final double remainingBalance;
  final bool creditCreated;

  const MultiPaymentResult({
    required this.invoice,
    required this.payments,
    required this.remainingBalance,
    required this.creditCreated,
  });

  int get paymentCount => payments.length;

  double get totalPaid => payments.fold(0, (sum, p) => sum + p.amount);

  bool get isFullyPaid => remainingBalance <= 0;

  /// Resumen de métodos de pago usados
  String get paymentMethodsSummary {
    final methods = payments.map((p) => p.paymentMethod.displayName).toSet();
    return methods.join(', ');
  }
}
