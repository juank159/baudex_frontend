// lib/features/invoices/domain/entities/invoice_payment.dart
import 'package:equatable/equatable.dart';
import 'invoice.dart';

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
    createdAt,
    updatedAt,
  ];

  String get paymentMethodDisplayName => paymentMethod.displayName;

  DateTime get effectivePaymentDate => paymentDate;

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
