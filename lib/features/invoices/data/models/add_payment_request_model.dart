// lib/features/invoices/data/models/add_payment_request_model.dart
import '../../domain/entities/invoice.dart';

/// Modelo de request para agregar un pago a una factura
class AddPaymentRequestModel {
  final double amount;
  final String paymentMethod;
  final String? paymentDate;
  final String? reference;
  final String? notes;

  const AddPaymentRequestModel({
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amount': amount,
      'paymentMethod': paymentMethod,
    };

    // Solo incluir campos opcionales si no son null
    if (paymentDate != null) json['paymentDate'] = paymentDate;
    if (reference != null) json['reference'] = reference;
    if (notes != null) json['notes'] = notes;

    return json;
  }

  factory AddPaymentRequestModel.fromParams({
    required double amount,
    required PaymentMethod paymentMethod,
    DateTime? paymentDate,
    String? reference,
    String? notes,
  }) {
    return AddPaymentRequestModel(
      amount: amount,
      paymentMethod: paymentMethod.value,
      paymentDate: paymentDate?.toIso8601String(),
      reference: reference,
      notes: notes,
    );
  }

  /// Validar que el pago sea válido
  bool get isValid {
    return amount > 0 &&
        paymentMethod.isNotEmpty &&
        _isValidPaymentMethod(paymentMethod);
  }

  /// Verificar si el método de pago es válido
  bool _isValidPaymentMethod(String method) {
    final validMethods = PaymentMethod.values.map((pm) => pm.value).toList();
    return validMethods.contains(method);
  }

  /// Obtener el enum de método de pago
  PaymentMethod get paymentMethodEnum {
    return PaymentMethod.fromString(paymentMethod);
  }

  /// Obtener fecha de pago como DateTime si está presente
  DateTime? get paymentDateTime {
    if (paymentDate == null) return null;
    return DateTime.tryParse(paymentDate!);
  }

  @override
  String toString() {
    return 'AddPaymentRequestModel(amount: ${amount.toStringAsFixed(2)}, paymentMethod: $paymentMethod${reference != null ? ', reference: $reference' : ''})';
  }
}

/// Modelo de request para múltiples pagos (si se necesita en el futuro)
class AddMultiplePaymentsRequestModel {
  final List<AddPaymentRequestModel> payments;

  const AddMultiplePaymentsRequestModel({required this.payments});

  Map<String, dynamic> toJson() {
    return {'payments': payments.map((payment) => payment.toJson()).toList()};
  }

  bool get isValid {
    return payments.isNotEmpty && payments.every((payment) => payment.isValid);
  }

  double get totalAmount {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }
}
