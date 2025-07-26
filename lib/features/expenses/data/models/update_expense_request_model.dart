// lib/features/expenses/data/models/update_expense_request_model.dart
import '../../domain/entities/expense.dart';

class UpdateExpenseRequestModel {
  final String? description;
  final double? amount;
  final String? date;
  final String? categoryId;
  final String? type;
  final String? paymentMethod;
  final String? vendor;
  final String? invoiceNumber;
  final String? reference;
  final String? notes;
  final List<String>? attachments;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  const UpdateExpenseRequestModel({
    this.description,
    this.amount,
    this.date,
    this.categoryId,
    this.type,
    this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachments,
    this.tags,
    this.metadata,
  });

  factory UpdateExpenseRequestModel.fromParams({
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    ExpenseType? type,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return UpdateExpenseRequestModel(
      description: description,
      amount: amount,
      date: date?.toIso8601String(),
      categoryId: categoryId,
      type: type?.name,
      paymentMethod: paymentMethod?.name,
      vendor: vendor,
      invoiceNumber: invoiceNumber,
      reference: reference,
      notes: notes,
      attachments: attachments,
      tags: tags,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (description?.isNotEmpty == true) data['description'] = description;
    if (amount != null) data['amount'] = amount;
    if (date?.isNotEmpty == true) data['date'] = date;
    if (categoryId?.isNotEmpty == true) data['categoryId'] = categoryId;
    if (type?.isNotEmpty == true) data['type'] = type;
    if (paymentMethod?.isNotEmpty == true) data['paymentMethod'] = paymentMethod;
    if (vendor?.isNotEmpty == true) data['vendor'] = vendor;
    if (invoiceNumber?.isNotEmpty == true) data['invoiceNumber'] = invoiceNumber;
    if (reference?.isNotEmpty == true) data['reference'] = reference;
    if (notes?.isNotEmpty == true) data['notes'] = notes;
    if (attachments?.isNotEmpty == true) data['attachments'] = attachments;
    if (tags?.isNotEmpty == true) data['tags'] = tags;
    if (metadata?.isNotEmpty == true) data['metadata'] = metadata;

    return data;
  }
}