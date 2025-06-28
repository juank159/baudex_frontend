// lib/features/invoices/data/models/update_invoice_request_model.dart
import '../../domain/repositories/invoice_repository.dart';
import 'invoice_item_model.dart';

/// Modelo de request para actualizar una factura existente
class UpdateInvoiceRequestModel {
  final String? number;
  final String? date;
  final String? dueDate;
  final String? paymentMethod;
  final String? status;
  final double? taxPercentage;
  final double? discountPercentage;
  final double? discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;
  final String? customerId;
  final List<CreateInvoiceItemRequestModel>? items;

  const UpdateInvoiceRequestModel({
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod,
    this.status,
    this.taxPercentage,
    this.discountPercentage,
    this.discountAmount,
    this.notes,
    this.terms,
    this.metadata,
    this.customerId,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Solo incluir campos que no sean null
    if (number != null) json['number'] = number;
    if (date != null) json['date'] = date;
    if (dueDate != null) json['dueDate'] = dueDate;
    if (paymentMethod != null) json['paymentMethod'] = paymentMethod;
    if (status != null) json['status'] = status;
    if (taxPercentage != null) json['taxPercentage'] = taxPercentage;
    if (discountPercentage != null)
      json['discountPercentage'] = discountPercentage;
    if (discountAmount != null) json['discountAmount'] = discountAmount;
    if (notes != null) json['notes'] = notes;
    if (terms != null) json['terms'] = terms;
    if (metadata != null) json['metadata'] = metadata;
    if (customerId != null) json['customerId'] = customerId;
    if (items != null)
      json['items'] = items!.map((item) => item.toJson()).toList();

    return json;
  }

  factory UpdateInvoiceRequestModel.fromParams({
    String? number,
    DateTime? date,
    DateTime? dueDate,
    String? paymentMethod,
    String? status,
    double? taxPercentage,
    double? discountPercentage,
    double? discountAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    List<CreateInvoiceItemParams>? items,
  }) {
    return UpdateInvoiceRequestModel(
      number: number,
      date: date?.toIso8601String(),
      dueDate: dueDate?.toIso8601String(),
      paymentMethod: paymentMethod,
      status: status,
      taxPercentage: taxPercentage,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      metadata: metadata,
      customerId: customerId,
      items:
          items
              ?.map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
              .toList(),
    );
  }

  /// Verificar si el request tiene algún campo para actualizar
  bool get hasUpdates {
    return number != null ||
        date != null ||
        dueDate != null ||
        paymentMethod != null ||
        status != null ||
        taxPercentage != null ||
        discountPercentage != null ||
        discountAmount != null ||
        notes != null ||
        terms != null ||
        metadata != null ||
        customerId != null ||
        items != null;
  }

  /// Validar que los campos sean válidos si están presentes
  bool get isValid {
    if (taxPercentage != null && taxPercentage! < 0) return false;
    if (discountPercentage != null && discountPercentage! < 0) return false;
    if (discountAmount != null && discountAmount! < 0) return false;
    if (items != null && items!.any((item) => !item.isValid)) return false;

    return true;
  }

  /// Crear una copia con nuevos valores
  UpdateInvoiceRequestModel copyWith({
    String? number,
    String? date,
    String? dueDate,
    String? paymentMethod,
    String? status,
    double? taxPercentage,
    double? discountPercentage,
    double? discountAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    List<CreateInvoiceItemRequestModel>? items,
  }) {
    return UpdateInvoiceRequestModel(
      number: number ?? this.number,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    final updates = <String>[];
    if (number != null) updates.add('number');
    if (date != null) updates.add('date');
    if (dueDate != null) updates.add('dueDate');
    if (paymentMethod != null) updates.add('paymentMethod');
    if (taxPercentage != null) updates.add('taxPercentage');
    if (discountPercentage != null) updates.add('discountPercentage');
    if (discountAmount != null) updates.add('discountAmount');
    if (notes != null) updates.add('notes');
    if (terms != null) updates.add('terms');
    if (metadata != null) updates.add('metadata');
    if (customerId != null) updates.add('customerId');
    if (items != null) updates.add('items(${items!.length})');

    return 'UpdateInvoiceRequestModel(updates: [${updates.join(', ')}])';
  }
}
