// lib/features/products/domain/entities/product_presentation.dart
import 'package:equatable/equatable.dart';

class ProductPresentation extends Equatable {
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

  const ProductPresentation({
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

  @override
  List<Object?> get props => [
        id,
        name,
        factor,
        price,
        currency,
        barcode,
        sku,
        isDefault,
        isActive,
        sortOrder,
        productId,
        createdAt,
        updatedAt,
      ];

  ProductPresentation copyWith({
    String? id,
    String? name,
    double? factor,
    double? price,
    String? currency,
    String? barcode,
    String? sku,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    String? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPresentation(
      id: id ?? this.id,
      name: name ?? this.name,
      factor: factor ?? this.factor,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
