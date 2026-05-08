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
  final String? paidFrom;
  final String? bankAccountId;

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
    this.paidFrom,
    this.bankAccountId,
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
    ExpensePaidFrom? paidFrom,
    String? bankAccountId,
  }) {
    return CreateExpenseRequestModel(
      description: description,
      amount: amount,
      // IMPORTANTE: enviar YYYY-MM-DD usando los componentes de la fecha
      // tal como los ve el usuario (la fecha ya viene en TZ del tenant vía
      // TenantDateTimeService). Si usáramos toIso8601String(), un TZDateTime
      // se serializa en UTC y un gasto creado a las 19:44 de Bogotá quedaría
      // con `date = 2026-04-22` en el servidor (día siguiente en UTC), y no
      // aparecería al filtrar por "HOY" en la lista.
      date: _ymd(date),
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
      paidFrom: paidFrom?.value,
      bankAccountId: bankAccountId,
    );
  }

  /// Formatea una fecha como 'YYYY-MM-DD' usando sus componentes locales.
  /// Para un TZDateTime ya en la TZ del tenant, esto preserva el día
  /// correcto. Para un DateTime local cualquiera, también funciona.
  static String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
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
    if (paidFrom?.isNotEmpty == true) data['paidFrom'] = paidFrom;
    if (bankAccountId?.isNotEmpty == true) data['bankAccountId'] = bankAccountId;

    return data;
  }
}