// lib/features/expenses/domain/entities/expense.dart
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:equatable/equatable.dart';

enum ExpenseStatus {
  draft,
  pending,
  approved,
  rejected,
  paid;

  String get displayName {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Borrador';
      case ExpenseStatus.pending:
        return 'Pendiente';
      case ExpenseStatus.approved:
        return 'Aprobado';
      case ExpenseStatus.rejected:
        return 'Rechazado';
      case ExpenseStatus.paid:
        return 'Pagado';
    }
  }
}

enum ExpenseType {
  operating, // Gastos operativos
  administrative, // Gastos administrativos
  sales, // Gastos de ventas
  financial, // Gastos financieros
  extraordinary; // Gastos extraordinarios

  String get displayName {
    switch (this) {
      case ExpenseType.operating:
        return 'Operativo';
      case ExpenseType.administrative:
        return 'Administrativo';
      case ExpenseType.sales:
        return 'Ventas';
      case ExpenseType.financial:
        return 'Financiero';
      case ExpenseType.extraordinary:
        return 'Extraordinario';
    }
  }
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  check,
  other;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Otro';
    }
  }
}

class Expense extends Equatable {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final ExpenseStatus status;
  final ExpenseType type;
  final PaymentMethod paymentMethod;
  final String? vendor;
  final String? invoiceNumber;
  final String? reference;
  final String? notes;
  final List<String>? attachments;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final String? approvedById;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String categoryId;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    required this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachments,
    this.tags,
    this.metadata,
    this.approvedById,
    this.approvedAt,
    this.rejectionReason,
    required this.categoryId,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    date,
    status,
    type,
    paymentMethod,
    vendor,
    invoiceNumber,
    reference,
    notes,
    attachments,
    tags,
    metadata,
    approvedById,
    approvedAt,
    rejectionReason,
    categoryId,
    createdById,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  // Getters útiles
  bool get isApproved => status == ExpenseStatus.approved;
  bool get isPaid => status == ExpenseStatus.paid;
  bool get isPending => status == ExpenseStatus.pending;
  bool get isDraft => status == ExpenseStatus.draft;
  bool get isRejected => status == ExpenseStatus.rejected;
  bool get isActive => deletedAt == null;

  bool get requiresApproval =>
      amount > 500000; // Más de 500k COP requiere aprobación

  // Getters de estado para la UI
  bool get canBeEdited => isDraft || isPending;
  bool get canBeDeleted => isDraft;
  bool get canBeSubmitted => isDraft;
  bool get canBeApproved => isPending;
  bool get canBeRejected => isPending;
  bool get canBePaid => isApproved;

  // Getters de fechas (simulados ya que no están en la entidad actual)
  DateTime? get submittedAt =>
      isPending || isApproved || isRejected || isPaid ? createdAt : null;
  DateTime? get paidAt => isPaid ? updatedAt : null;
  DateTime? get rejectedAt => isRejected ? updatedAt : null;
  String? get approvedBy => isApproved ? 'Sistema' : null;

  String get formattedAmount {
    return AppFormatters.formatCurrency(amount);
  }

  int get daysOld {
    final diffTime = DateTime.now().difference(date);
    return diffTime.inDays;
  }

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    ExpenseStatus? status,
    ExpenseType? type,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? approvedById,
    DateTime? approvedAt,
    String? rejectionReason,
    String? categoryId,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendor: vendor ?? this.vendor,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      approvedById: approvedById ?? this.approvedById,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      categoryId: categoryId ?? this.categoryId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, description: $description, amount: $formattedAmount, status: ${status.displayName})';
}
