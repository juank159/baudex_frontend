// lib/features/credit_notes/data/models/credit_note_item_model.dart
import '../../domain/entities/credit_note_item.dart';
import '../../domain/repositories/credit_note_repository.dart';

/// Helper para parsear valores numéricos que pueden venir como String o num
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class CreditNoteItemModel extends CreditNoteItem {
  const CreditNoteItemModel({
    required super.id,
    required super.description,
    required super.quantity,
    required super.unitPrice,
    required super.discountPercentage,
    required super.discountAmount,
    required super.subtotal,
    super.unit,
    super.notes,
    required super.creditNoteId,
    super.productId,
    super.product,
    super.invoiceItemId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) {
    // Debug: Imprimir el JSON recibido para diagnosticar problemas
    print('🔍 CreditNoteItemModel.fromJson: ${json.keys.toList()}');

    // Manejar campos que podrían venir null del backend
    final id = json['id'];
    final creditNoteId = json['creditNoteId'];
    final description = json['description'];

    if (id == null || creditNoteId == null || description == null) {
      print('⚠️ Campos requeridos nulos - id: $id, creditNoteId: $creditNoteId, description: $description');
    }

    return CreditNoteItemModel(
      id: (id as String?) ?? '',
      description: (description as String?) ?? '',
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']),
      discountPercentage: _parseDouble(json['discountPercentage']),
      discountAmount: _parseDouble(json['discountAmount']),
      subtotal: _parseDouble(json['subtotal']),
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      creditNoteId: (creditNoteId as String?) ?? '',
      productId: json['productId'] as String?,
      product: null,
      invoiceItemId: json['invoiceItemId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'subtotal': subtotal,
      'unit': unit,
      'notes': notes,
      'creditNoteId': creditNoteId,
      'productId': productId,
      'invoiceItemId': invoiceItemId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CreditNoteItemModel.fromEntity(CreditNoteItem entity) {
    return CreditNoteItemModel(
      id: entity.id,
      description: entity.description,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      discountPercentage: entity.discountPercentage,
      discountAmount: entity.discountAmount,
      subtotal: entity.subtotal,
      unit: entity.unit,
      notes: entity.notes,
      creditNoteId: entity.creditNoteId,
      productId: entity.productId,
      product: entity.product,
      invoiceItemId: entity.invoiceItemId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

// Request model para crear item de nota de crédito
class CreateCreditNoteItemRequestModel {
  final String? productId;
  final String? invoiceItemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;
  final double? unitCost; // Para restauración de inventario FIFO

  const CreateCreditNoteItemRequestModel({
    this.productId,
    this.invoiceItemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.unitCost,
  });

  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'productId': productId,
      if (invoiceItemId != null) 'invoiceItemId': invoiceItemId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
      if (unitCost != null) 'unitCost': unitCost,
    };
  }

  factory CreateCreditNoteItemRequestModel.fromEntity(
    CreateCreditNoteItemParams params,
  ) {
    return CreateCreditNoteItemRequestModel(
      productId: params.productId,
      invoiceItemId: params.invoiceItemId,
      description: params.description,
      quantity: params.quantity,
      unitPrice: params.unitPrice,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      unit: params.unit,
      notes: params.notes,
      unitCost: params.unitCost,
    );
  }
}
