// lib/features/expenses/data/models/create_expense_request_model.dart
import '../../domain/entities/expense.dart';

class CreateExpenseRequestModel {
  final String description;
  final double amount;
  final String date;
  final String categoryId;
  final String type;
  final String paymentMethod;
  final String? vendor;
  final String? invoiceNumber;
  final String? reference;
  final String? notes;
  final List<String>? attachments;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final String? status;

  const CreateExpenseRequestModel({
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    required this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachments,
    this.tags,
    this.metadata,
    this.status,
  });

  factory CreateExpenseRequestModel.fromParams({
    required String description,
    required double amount,
    required DateTime date,
    required String categoryId,
    required ExpenseType type,
    required PaymentMethod paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    ExpenseStatus? status,
  }) {
    return CreateExpenseRequestModel(
      description: description,
      amount: amount,
      date: date.toIso8601String(),
      categoryId: categoryId,
      type: type.name,
      paymentMethod: paymentMethod.name,
      vendor: vendor,
      invoiceNumber: invoiceNumber,
      reference: reference,
      notes: notes,
      attachments: attachments,
      tags: tags,
      metadata: metadata,
      status: status?.name,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'description': description,
      'amount': amount,
      'date': date,
      'categoryId': categoryId,
      'type': type,
      'paymentMethod': paymentMethod,
    };

    if (vendor?.isNotEmpty == true) data['vendor'] = vendor;
    if (invoiceNumber?.isNotEmpty == true) data['invoiceNumber'] = invoiceNumber;
    if (reference?.isNotEmpty == true) data['reference'] = reference;
    if (notes?.isNotEmpty == true) data['notes'] = notes;
    if (attachments?.isNotEmpty == true) data['attachments'] = attachments;
    if (tags?.isNotEmpty == true) data['tags'] = tags;
    if (metadata?.isNotEmpty == true) data['metadata'] = metadata;
    if (status?.isNotEmpty == true) data['status'] = status;

    return data;
  }
}