// lib/features/products/domain/entities/product_price.dart
import 'package:equatable/equatable.dart';

// enum PriceType { price1, price2, price3, special, cost }

enum PriceType { price1, price2, price3, special, cost }

enum PriceStatus { active, inactive }

class ProductPrice extends Equatable {
  final String id;
  final PriceType type;
  final String? name;
  final double amount;
  final String currency;
  final PriceStatus status;
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

  const ProductPrice({
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

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    amount,
    currency,
    status,
    validFrom,
    validTo,
    discountPercentage,
    discountAmount,
    minQuantity,
    profitMargin,
    notes,
    productId,
    createdAt,
    updatedAt,
  ];

  // Getters computados
  bool get isActive => status == PriceStatus.active;

  bool get isValidNow {
    final now = DateTime.now();
    final validFromDate = validFrom ?? DateTime(1970);
    final validToDate = validTo ?? DateTime(2099, 12, 31);
    return now.isAfter(validFromDate) && now.isBefore(validToDate);
  }

  double get finalAmount {
    if (discountAmount != null && discountAmount! > 0) {
      return (amount - discountAmount!).clamp(0.0, double.infinity);
    }
    if (discountPercentage > 0) {
      return amount * (1 - discountPercentage / 100);
    }
    return amount;
  }

  String get formattedAmount {
    // Implementar formateo de moneda según el currency
    // Por ahora formato simple
    return '\$${finalAmount.toStringAsFixed(2)}';
  }

  double calculateProfitMargin(double costPrice) {
    if (costPrice <= 0) return 0;
    return ((finalAmount - costPrice) / costPrice) * 100;
  }

  bool get hasDiscount {
    return (discountPercentage > 0) ||
        (discountAmount != null && discountAmount! > 0);
  }

  // Método para copyWith
  ProductPrice copyWith({
    String? id,
    PriceType? type,
    String? name,
    double? amount,
    String? currency,
    PriceStatus? status,
    DateTime? validFrom,
    DateTime? validTo,
    double? discountPercentage,
    double? discountAmount,
    double? minQuantity,
    double? profitMargin,
    String? notes,
    String? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      minQuantity: minQuantity ?? this.minQuantity,
      profitMargin: profitMargin ?? this.profitMargin,
      notes: notes ?? this.notes,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension PriceTypeExtension on PriceType {
  String get name {
    switch (this) {
      case PriceType.price1:
        return 'price1';
      case PriceType.price2:
        return 'price2';
      case PriceType.price3:
        return 'price3';
      case PriceType.special:
        return 'special';
      case PriceType.cost:
        return 'cost';
    }
  }

  String get displayName {
    switch (this) {
      case PriceType.price1:
        return 'Precio al Público';
      case PriceType.price2:
        return 'Precio Mayorista';
      case PriceType.price3:
        return 'Precio Distribuidor';
      case PriceType.special:
        return 'Precio Especial';
      case PriceType.cost:
        return 'Precio de Costo';
    }
  }
}
