// lib/features/expenses/data/models/expense_model.dart
import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.categoryId,
    required super.type,
    required super.paymentMethod,
    required super.status,
    required super.createdById,
    required super.createdAt,
    required super.updatedAt,
    super.vendor,
    super.invoiceNumber,
    super.reference,
    super.notes,
    super.attachments,
    super.tags,
    super.metadata,
    super.approvedById,
    super.approvedAt,
    super.rejectionReason,
    super.deletedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: _parseDouble(json['amount']) ?? 0.0,
      date: DateTime.parse(json['date'] as String),
      categoryId: json['categoryId'] as String,
      type: _parseExpenseType(json['type']),
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      status: _parseExpenseStatus(json['status']),
      createdById: json['createdById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      vendor: json['vendor'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type.name,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'vendor': vendor,
      'invoiceNumber': invoiceNumber,
      'reference': reference,
      'notes': notes,
      'attachments': attachments,
      'tags': tags,
      'metadata': metadata,
      'approvedById': approvedById,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static ExpenseType _parseExpenseType(dynamic type) {
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'operating':
          return ExpenseType.operating;
        case 'administrative':
          return ExpenseType.administrative;
        case 'sales':
          return ExpenseType.sales;
        case 'financial':
          return ExpenseType.financial;
        case 'extraordinary':
          return ExpenseType.extraordinary;
        default:
          return ExpenseType.operating;
      }
    }
    return ExpenseType.operating;
  }

  static PaymentMethod _parsePaymentMethod(dynamic method) {
    if (method is String) {
      switch (method.toLowerCase()) {
        case 'cash':
          return PaymentMethod.cash;
        case 'credit_card':
        case 'creditcard':
          return PaymentMethod.creditCard;
        case 'debit_card':
        case 'debitcard':
          return PaymentMethod.debitCard;
        case 'bank_transfer':
        case 'banktransfer':
          return PaymentMethod.bankTransfer;
        case 'check':
          return PaymentMethod.check;
        case 'other':
          return PaymentMethod.other;
        default:
          return PaymentMethod.cash;
      }
    }
    return PaymentMethod.cash;
  }

  static ExpenseStatus _parseExpenseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'draft':
          return ExpenseStatus.draft;
        case 'pending':
          return ExpenseStatus.pending;
        case 'approved':
          return ExpenseStatus.approved;
        case 'rejected':
          return ExpenseStatus.rejected;
        case 'paid':
          return ExpenseStatus.paid;
        default:
          return ExpenseStatus.draft;
      }
    }
    return ExpenseStatus.draft;
  }

  Expense toEntity() => Expense(
    id: id,
    description: description,
    amount: amount,
    date: date,
    categoryId: categoryId,
    type: type,
    paymentMethod: paymentMethod,
    status: status,
    createdById: createdById,
    createdAt: createdAt,
    updatedAt: updatedAt,
    vendor: vendor,
    invoiceNumber: invoiceNumber,
    reference: reference,
    notes: notes,
    attachments: attachments,
    tags: tags,
    metadata: metadata,
    approvedById: approvedById,
    approvedAt: approvedAt,
    rejectionReason: rejectionReason,
    deletedAt: deletedAt,
  );

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      description: expense.description,
      amount: expense.amount,
      date: expense.date,
      categoryId: expense.categoryId,
      type: expense.type,
      paymentMethod: expense.paymentMethod,
      status: expense.status,
      createdById: expense.createdById,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      vendor: expense.vendor,
      invoiceNumber: expense.invoiceNumber,
      reference: expense.reference,
      notes: expense.notes,
      attachments: expense.attachments,
      tags: expense.tags,
      metadata: expense.metadata,
      approvedById: expense.approvedById,
      approvedAt: expense.approvedAt,
      rejectionReason: expense.rejectionReason,
      deletedAt: expense.deletedAt,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}