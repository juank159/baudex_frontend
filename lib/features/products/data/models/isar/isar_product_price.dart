// lib/features/products/data/models/isar/isar_product_price.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:isar/isar.dart';

part 'isar_product_price.g.dart';

@embedded
class IsarProductPrice {
  late String serverId; // ID del servidor

  @Enumerated(EnumType.name)
  late IsarPriceType type;

  String? name;
  late double amount;
  late String currency;

  @Enumerated(EnumType.name)
  late IsarPriceStatus status;

  DateTime? validFrom;
  DateTime? validTo;

  late double discountPercentage;
  double? discountAmount;
  late double minQuantity;
  double? profitMargin;

  String? notes;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Constructores
  IsarProductPrice();

  IsarProductPrice.create({
    required this.serverId,
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
    required this.createdAt,
    required this.updatedAt,
  });

  // Mappers
  static IsarProductPrice fromEntity(ProductPrice entity) {
    return IsarProductPrice.create(
      serverId: entity.id,
      type: _mapPriceType(entity.type),
      name: entity.name,
      amount: entity.amount,
      currency: entity.currency,
      status: _mapPriceStatus(entity.status),
      validFrom: entity.validFrom,
      validTo: entity.validTo,
      discountPercentage: entity.discountPercentage,
      discountAmount: entity.discountAmount,
      minQuantity: entity.minQuantity,
      profitMargin: entity.profitMargin,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ProductPrice toEntity() {
    return ProductPrice(
      id: serverId,
      type: _mapIsarPriceType(type),
      name: name,
      amount: amount,
      currency: currency,
      status: _mapIsarPriceStatus(status),
      validFrom: validFrom,
      validTo: validTo,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      minQuantity: minQuantity,
      profitMargin: profitMargin,
      notes: notes,
      productId: '', // Se asignará desde el producto padre
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarPriceType _mapPriceType(PriceType type) {
    switch (type) {
      case PriceType.price1:
        return IsarPriceType.price1;
      case PriceType.price2:
        return IsarPriceType.price2;
      case PriceType.price3:
        return IsarPriceType.price3;
      case PriceType.special:
        return IsarPriceType.special;
      case PriceType.cost:
        return IsarPriceType.cost;
    }
  }

  static PriceType _mapIsarPriceType(IsarPriceType type) {
    switch (type) {
      case IsarPriceType.price1:
        return PriceType.price1;
      case IsarPriceType.price2:
        return PriceType.price2;
      case IsarPriceType.price3:
        return PriceType.price3;
      case IsarPriceType.special:
        return PriceType.special;
      case IsarPriceType.cost:
        return PriceType.cost;
    }
  }

  static IsarPriceStatus _mapPriceStatus(PriceStatus status) {
    switch (status) {
      case PriceStatus.active:
        return IsarPriceStatus.active;
      case PriceStatus.inactive:
        return IsarPriceStatus.inactive;
    }
  }

  static PriceStatus _mapIsarPriceStatus(IsarPriceStatus status) {
    switch (status) {
      case IsarPriceStatus.active:
        return PriceStatus.active;
      case IsarPriceStatus.inactive:
        return PriceStatus.inactive;
    }
  }

  // Métodos de utilidad
  bool get isActive => status == IsarPriceStatus.active;
  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return isActive;
  }

  double get finalAmount {
    if (discountAmount != null && discountAmount! > 0) {
      return (amount - discountAmount!).clamp(0, double.infinity);
    }
    if (discountPercentage > 0) {
      return amount * (1 - discountPercentage / 100);
    }
    return amount;
  }

  @override
  String toString() {
    return 'IsarProductPrice{serverId: $serverId, type: $type, amount: $amount, currency: $currency}';
  }
}
