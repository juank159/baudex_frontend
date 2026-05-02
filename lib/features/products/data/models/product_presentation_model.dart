// lib/features/products/data/models/product_presentation_model.dart
import '../../domain/entities/product_presentation.dart';

class ProductPresentationModel {
  final String id;
  final String name;
  final double factor;
  final double price;
  final String currency;
  final String? barcode;
  final String? sku;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final String productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPresentationModel({
    required this.id,
    required this.name,
    required this.factor,
    required this.price,
    this.currency = 'COP',
    this.barcode,
    this.sku,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductPresentationModel.fromJson(Map<String, dynamic> json) {
    return ProductPresentationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      factor: _parseDouble(json['factor']),
      price: _parseDouble(json['price']),
      currency: json['currency'] as String? ?? 'COP',
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      productId: json['productId'] as String,
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
      'name': name,
      'factor': factor,
      'price': price,
      'currency': currency,
      'barcode': barcode,
      'sku': sku,
      'isDefault': isDefault,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProductPresentation toEntity() {
    return ProductPresentation(
      id: id,
      name: name,
      factor: factor,
      price: price,
      currency: currency,
      barcode: barcode,
      sku: sku,
      isDefault: isDefault,
      isActive: isActive,
      sortOrder: sortOrder,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProductPresentationModel.fromEntity(ProductPresentation entity) {
    return ProductPresentationModel(
      id: entity.id,
      name: entity.name,
      factor: entity.factor,
      price: entity.price,
      currency: entity.currency,
      barcode: entity.barcode,
      sku: entity.sku,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      productId: entity.productId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
