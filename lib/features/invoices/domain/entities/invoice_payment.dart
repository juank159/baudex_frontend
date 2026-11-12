// lib/features/invoices/domain/entities/invoice_payment.dart
import 'package:equatable/equatable.dart';
import 'invoice.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';

class InvoicePayment extends Equatable {
  final String id;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;

  // Relaciones
  final String invoiceId;
  final Invoice? invoice;
  final String createdById;
  final String organizationId;

  // Cuenta bancaria asociada (opcional)
  final String? bankAccountId;
  final BankAccount? bankAccount;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Multi-moneda: campos para pagos en moneda extranjera
  final String? paymentCurrency;       // null = moneda base de la org
  final double? paymentCurrencyAmount; // monto en la moneda del pago
  final double? exchangeRate;          // 1 moneda extranjera = X moneda base

  /// Canal por el que entró el pago cuando hay que distinguirlo del método
  /// (igual que `payments.channel` en el servidor): `breb` o
  /// `breb_adjustment`. Vacío en los demás pagos.
  final String? channel;

  /// Valor de [channel] del ajuste de redondeo de Bre-B: pesos que se dejaron
  /// de cobrar para cuadrar el monto único. No es dinero recibido.
  static const String brebAdjustmentChannel = 'breb_adjustment';

  const InvoicePayment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.reference,
    this.notes,
    required this.invoiceId,
    this.invoice,
    required this.createdById,
    required this.organizationId,
    this.bankAccountId,
    this.bankAccount,
    required this.createdAt,
    required this.updatedAt,
    this.paymentCurrency,
    this.paymentCurrencyAmount,
    this.exchangeRate,
    this.channel,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    paymentMethod,
    paymentDate,
    reference,
    notes,
    invoiceId,
    invoice,
    createdById,
    organizationId,
    bankAccountId,
    bankAccount,
    createdAt,
    updatedAt,
    paymentCurrency,
    paymentCurrencyAmount,
    exchangeRate,
    channel,
  ];

  /// Nombre para mostrar del método de pago con cuenta bancaria
  /// Prioriza mostrar el nombre del banco si existe (Nequi, Daviplata, Bancolombia, etc.)
  String get paymentMethodDisplayName {
    if (bankAccount != null && bankAccount!.name.isNotEmpty) {
      // Si tiene cuenta bancaria, mostrar el nombre del banco directamente
      return bankAccount!.name;
    }
    return paymentMethod.displayName;
  }

  /// Si el pago fue realizado en una moneda diferente a la base
  bool get isForeignCurrency => paymentCurrency != null;

  /// Ajuste de redondeo de Bre-B (no es dinero recibido).
  bool get isBrebAdjustment => channel == brebAdjustmentChannel;

  DateTime get effectivePaymentDate => paymentDate;

  /// Nombre completo para mostrar del método de pago con cuenta bancaria
  /// Formato: "Transferencia Bancaria - Nequi"
  String get displayName {
    if (bankAccount != null && bankAccount!.name.isNotEmpty) {
      return '${paymentMethod.displayName} - ${bankAccount!.name}';
    }
    return paymentMethod.displayName;
  }

  /// Nombre corto del método de pago (solo el banco si existe)
  String get shortDisplayName {
    if (bankAccount != null && bankAccount!.name.isNotEmpty) {
      return bankAccount!.name;
    }
    // Nombres cortos para métodos sin banco
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'T.Crédito';
      case PaymentMethod.debitCard:
        return 'T.Débito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.credit:
        return 'Crédito';
      case PaymentMethod.clientBalance:
        return 'Saldo a Favor';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  InvoicePayment copyWith({
    String? id,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String? invoiceId,
    Invoice? invoice,
    String? createdById,
    String? organizationId,
    String? bankAccountId,
    BankAccount? bankAccount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
    String? channel,
  }) {
    return InvoicePayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      invoiceId: invoiceId ?? this.invoiceId,
      invoice: invoice ?? this.invoice,
      createdById: createdById ?? this.createdById,
      organizationId: organizationId ?? this.organizationId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccount: bankAccount ?? this.bankAccount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentCurrency: paymentCurrency ?? this.paymentCurrency,
      paymentCurrencyAmount: paymentCurrencyAmount ?? this.paymentCurrencyAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      channel: channel ?? this.channel,
    );
  }

  factory InvoicePayment.empty({required String invoiceId}) {
    return InvoicePayment(
      id: '',
      amount: 0,
      paymentMethod: PaymentMethod.cash,
      paymentDate: DateTime.now(),
      invoiceId: invoiceId,
      createdById: '',
      organizationId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
