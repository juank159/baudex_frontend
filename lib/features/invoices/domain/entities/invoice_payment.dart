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
