// lib/features/invoices/data/models/create_invoice_request_model.dart
import '../../domain/repositories/invoice_repository.dart';
import 'invoice_item_model.dart';

/// Modelo de request para crear una nueva factura
class CreateInvoiceRequestModel {
  final String customerId;
  final List<CreateInvoiceItemRequestModel> items;
  final String? number;
  final String? date;
  final String? dueDate;
  final String paymentMethod;
  final double taxPercentage;
  final double discountPercentage;
  final double discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  const CreateInvoiceRequestModel({
    required this.customerId,
    required this.items,
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod = 'cash',
    this.taxPercentage = 19,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.notes,
    this.terms,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'taxPercentage': taxPercentage,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
    };

    // Solo incluir campos opcionales si no son null
    if (number != null) json['number'] = number;
    if (date != null) json['date'] = date;
    if (dueDate != null) json['dueDate'] = dueDate;
    if (notes != null) json['notes'] = notes;
    if (terms != null) json['terms'] = terms;
    if (metadata != null) json['metadata'] = metadata;

    return json;
  }

  factory CreateInvoiceRequestModel.fromParams({
    required String customerId,
    required List<CreateInvoiceItemParams> items,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    String paymentMethod = 'cash',
    double taxPercentage = 19,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
  }) {
    return CreateInvoiceRequestModel(
      customerId: customerId,
      items:
          items
              .map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
              .toList(),
      number: number,
      date: date?.toIso8601String(),
      dueDate: dueDate?.toIso8601String(),
      paymentMethod: paymentMethod,
      taxPercentage: taxPercentage,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      metadata: metadata,
    );
  }

  /// Validar que el request sea válido
  bool get isValid {
    return customerId.isNotEmpty &&
        items.isNotEmpty &&
        items.every((item) => item.isValid) &&
        taxPercentage >= 0 &&
        discountPercentage >= 0 &&
        discountAmount >= 0;
  }

  /// Calcular el total estimado antes de enviar al servidor
  double get estimatedTotal {
    double subtotal = 0;
    for (final item in items) {
      subtotal += item.estimatedSubtotal;
    }

    final discountAmount =
        subtotal * (discountPercentage / 100) + this.discountAmount;
    final taxableAmount = subtotal - discountAmount;
    final taxAmount = taxableAmount * (taxPercentage / 100);

    return taxableAmount + taxAmount;
  }

  @override
  String toString() {
    return 'CreateInvoiceRequestModel(customerId: $customerId, items: ${items.length}, total estimated: ${estimatedTotal.toStringAsFixed(2)})';
  }
}
