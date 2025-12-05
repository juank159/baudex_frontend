// lib/features/invoices/data/models/add_payment_request_model.dart
import '../../domain/entities/invoice.dart';

/// Modelo de request para agregar un pago a una factura
class AddPaymentRequestModel {
  final double amount;
  final String paymentMethod;
  final String? bankAccountId;
  final String? paymentDate;
  final String? reference;
  final String? notes;

  const AddPaymentRequestModel({
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
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
    if (bankAccountId != null) json['bankAccountId'] = bankAccountId;
    if (paymentDate != null) json['paymentDate'] = paymentDate;
    if (reference != null) json['reference'] = reference;
    if (notes != null) json['notes'] = notes;

    return json;
  }

  factory AddPaymentRequestModel.fromParams({
    required double amount,
    required PaymentMethod paymentMethod,
    String? bankAccountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
  }) {
    return AddPaymentRequestModel(
      amount: amount,
      paymentMethod: paymentMethod.value,
      bankAccountId: bankAccountId,
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
    return 'AddPaymentRequestModel(amount: ${amount.toStringAsFixed(2)}, paymentMethod: $paymentMethod${bankAccountId != null ? ', bankAccountId: $bankAccountId' : ''}${reference != null ? ', reference: $reference' : ''})';
  }
}

/// Item de pago dentro de una solicitud de pagos múltiples
class PaymentItemModel {
  final double amount;
  final String paymentMethod;
  final String? bankAccountId;
  final String? reference;
  final String? notes;

  const PaymentItemModel({
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amount': amount,
      'paymentMethod': paymentMethod,
    };

    if (bankAccountId != null) json['bankAccountId'] = bankAccountId;
    if (reference != null) json['reference'] = reference;
    if (notes != null) json['notes'] = notes;

    return json;
  }

  factory PaymentItemModel.fromParams({
    required double amount,
    required PaymentMethod paymentMethod,
    String? bankAccountId,
    String? reference,
    String? notes,
  }) {
    return PaymentItemModel(
      amount: amount,
      paymentMethod: paymentMethod.value,
      bankAccountId: bankAccountId,
      reference: reference,
      notes: notes,
    );
  }

  bool get isValid {
    return amount > 0 && paymentMethod.isNotEmpty;
  }

  PaymentMethod get paymentMethodEnum {
    return PaymentMethod.fromString(paymentMethod);
  }
}

/// Modelo de request para múltiples pagos a una factura
/// Permite pagos parciales con diferentes métodos (Ej: $100,000 Nequi + $200,000 Efectivo)
class AddMultiplePaymentsRequestModel {
  final List<PaymentItemModel> payments;
  final String? paymentDate;
  final bool createCreditForRemaining;
  final String? generalNotes;

  const AddMultiplePaymentsRequestModel({
    required this.payments,
    this.paymentDate,
    this.createCreditForRemaining = false,
    this.generalNotes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };

    if (paymentDate != null) json['paymentDate'] = paymentDate;
    if (createCreditForRemaining) json['createCreditForRemaining'] = true;
    if (generalNotes != null) json['generalNotes'] = generalNotes;

    return json;
  }

  factory AddMultiplePaymentsRequestModel.fromParams({
    required List<PaymentItemModel> payments,
    DateTime? paymentDate,
    bool createCreditForRemaining = false,
    String? generalNotes,
  }) {
    return AddMultiplePaymentsRequestModel(
      payments: payments,
      paymentDate: paymentDate?.toIso8601String(),
      createCreditForRemaining: createCreditForRemaining,
      generalNotes: generalNotes,
    );
  }

  bool get isValid {
    return payments.isNotEmpty && payments.every((payment) => payment.isValid);
  }

  double get totalAmount {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  int get paymentCount => payments.length;

  /// Obtener resumen de métodos de pago usados
  String get paymentMethodsSummary {
    final methods = payments.map((p) => p.paymentMethodEnum.displayName).toSet();
    return methods.join(', ');
  }
}
