// lib/features/products/data/models/product_price_model.dart
import '../../domain/entities/product_price.dart';

class ProductPriceModel {
  final String id;
  final String type;
  final String? name;
  final double amount;
  final String currency;
  final String status;
  final DateTime? validFrom;
  final DateTime? validTo;
  final double discountPercentage;
  final double? discountAmount;
  final double minQuantity;
  final double? profitMargin;
  final String? notes;
  final String productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPriceModel({
    required this.id,
    required this.type,
    this.name,
    required this.amount,
    required this.currency,
    required this.status,
    this.validFrom,
    this.validTo,
    required this.discountPercentage,
    this.discountAmount,
    required this.minQuantity,
    this.profitMargin,
    this.notes,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      validFrom:
          json['validFrom'] != null
              ? DateTime.parse(json['validFrom'] as String)
              : null,
      validTo:
          json['validTo'] != null
              ? DateTime.parse(json['validTo'] as String)
              : null,
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      discountAmount:
          json['discountAmount'] != null
              ? (json['discountAmount'] as num).toDouble()
              : null,
      minQuantity: (json['minQuantity'] as num).toDouble(),
      profitMargin:
          json['profitMargin'] != null
              ? (json['profitMargin'] as num).toDouble()
              : null,
      notes: json['notes'] as String?,
      productId: json['productId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'amount': amount,
      'currency': currency,
      'status': status,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'minQuantity': minQuantity,
      'profitMargin': profitMargin,
      'notes': notes,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Conversión a entidad del dominio
  ProductPrice toEntity() {
    return ProductPrice(
      id: id,
      type: _mapStringToPriceType(type),
      name: name,
      amount: amount,
      currency: currency,
      status: _mapStringToPriceStatus(status),
      validFrom: validFrom,
      validTo: validTo,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      minQuantity: minQuantity,
      profitMargin: profitMargin,
      notes: notes,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Crear modelo desde entidad
  factory ProductPriceModel.fromEntity(ProductPrice price) {
    return ProductPriceModel(
      id: price.id,
      type: price.type.name,
      name: price.name,
      amount: price.amount,
      currency: price.currency,
      status: price.status.name,
      validFrom: price.validFrom,
      validTo: price.validTo,
      discountPercentage: price.discountPercentage,
      discountAmount: price.discountAmount,
      minQuantity: price.minQuantity,
      profitMargin: price.profitMargin,
      notes: price.notes,
      productId: price.productId,
      createdAt: price.createdAt,
      updatedAt: price.updatedAt,
    );
  }

  // Mappers privados
  PriceType _mapStringToPriceType(String type) {
    switch (type.toLowerCase()) {
      case 'price1':
        return PriceType.price1;
      case 'price2':
        return PriceType.price2;
      case 'price3':
        return PriceType.price3;
      case 'special':
        return PriceType.special;
      case 'cost':
        return PriceType.cost;
      default:
        return PriceType.price1;
    }
  }

  PriceStatus _mapStringToPriceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PriceStatus.active;
      case 'inactive':
        return PriceStatus.inactive;
      default:
        return PriceStatus.active;
    }
  }
}
