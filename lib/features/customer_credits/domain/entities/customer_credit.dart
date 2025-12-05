// lib/features/customer_credits/domain/entities/customer_credit.dart

import 'package:equatable/equatable.dart';

/// Estado del crédito
enum CreditStatus {
  pending('pending', 'Pendiente'),
  partiallyPaid('partially_paid', 'Parcialmente pagado'),
  paid('paid', 'Pagado'),
  cancelled('cancelled', 'Cancelado'),
  overdue('overdue', 'Vencido');

  final String value;
  final String displayName;

  const CreditStatus(this.value, this.displayName);

  static CreditStatus fromValue(String value) {
    return CreditStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CreditStatus.pending,
    );
  }
}

/// Entidad de Crédito de Cliente (Dominio)
class CustomerCredit extends Equatable {
  final String id;
  final double originalAmount;
  final double paidAmount;
  final double balanceDue;
  final CreditStatus status;
  final DateTime? dueDate;
  final String? description;
  final String? notes;
  final String customerId;
  final String? customerName;
  final String? invoiceId;
  final String? invoiceNumber;
  final String organizationId;
  final String createdById;
  final String? createdByName;
  final List<CreditPayment>? payments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CustomerCredit({
    required this.id,
    required this.originalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.status,
    this.dueDate,
    this.description,
    this.notes,
    required this.customerId,
    this.customerName,
    this.invoiceId,
    this.invoiceNumber,
    required this.organizationId,
    required this.createdById,
    this.createdByName,
    this.payments,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Porcentaje pagado
  double get paidPercentage {
    if (originalAmount <= 0) return 0;
    return (paidAmount / originalAmount) * 100;
  }

  /// Verifica si está vencido
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == CreditStatus.paid || status == CreditStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  /// Días hasta vencimiento (negativo si ya venció)
  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Verifica si se puede pagar
  bool get canReceivePayment {
    return status != CreditStatus.paid && status != CreditStatus.cancelled;
  }

  /// Verifica si se puede cancelar
  bool get canBeCancelled {
    return status != CreditStatus.paid && status != CreditStatus.cancelled;
  }

  @override
  List<Object?> get props => [
        id,
        originalAmount,
        paidAmount,
        balanceDue,
        status,
        dueDate,
        customerId,
        invoiceId,
      ];

  CustomerCredit copyWith({
    String? id,
    double? originalAmount,
    double? paidAmount,
    double? balanceDue,
    CreditStatus? status,
    DateTime? dueDate,
    String? description,
    String? notes,
    String? customerId,
    String? customerName,
    String? invoiceId,
    String? invoiceNumber,
    String? organizationId,
    String? createdById,
    String? createdByName,
    List<CreditPayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CustomerCredit(
      id: id ?? this.id,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      organizationId: organizationId ?? this.organizationId,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

/// Entidad de Pago a Crédito (Abono)
class CreditPayment extends Equatable {
  final String id;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;
  final String creditId;
  final String? bankAccountId;
  final String? bankAccountName;
  final String organizationId;
  final String createdById;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditPayment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.reference,
    this.notes,
    required this.creditId,
    this.bankAccountId,
    this.bankAccountName,
    required this.organizationId,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, amount, paymentMethod, paymentDate, creditId];

  CreditPayment copyWith({
    String? id,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String? creditId,
    String? bankAccountId,
    String? bankAccountName,
    String? organizationId,
    String? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      creditId: creditId ?? this.creditId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      organizationId: organizationId ?? this.organizationId,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Estadísticas de créditos
class CreditStats extends Equatable {
  final double totalPending;
  final double totalOverdue;
  final int countPending;
  final int countOverdue;
  final double totalPaid;

  const CreditStats({
    required this.totalPending,
    required this.totalOverdue,
    required this.countPending,
    required this.countOverdue,
    required this.totalPaid,
  });

  @override
  List<Object?> get props => [
        totalPending,
        totalOverdue,
        countPending,
        countOverdue,
        totalPaid,
      ];
}
