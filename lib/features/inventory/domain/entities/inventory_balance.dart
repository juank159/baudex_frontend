// lib/features/inventory/domain/entities/inventory_balance.dart
import 'package:equatable/equatable.dart';

class InventoryBalance extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final String categoryName;
  final int totalQuantity;
  final int minStock;
  final double averageCost;
  final double totalValue;
  final bool isLowStock;
  final bool isOutOfStock;
  
  // Optional fields for compatibility
  final String? warehouseId;
  final List<InventoryLot> fifoLots;
  final int availableQuantity;
  final int reservedQuantity;
  final int expiredQuantity;
  final int nearExpiryQuantity;
  final DateTime lastUpdated;

  const InventoryBalance({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.categoryName,
    required this.totalQuantity,
    required this.minStock,
    required this.averageCost,
    required this.totalValue,
    required this.isLowStock,
    required this.isOutOfStock,
    this.warehouseId,
    this.fifoLots = const [],
    int? availableQuantity,
    this.reservedQuantity = 0,
    this.expiredQuantity = 0,
    this.nearExpiryQuantity = 0,
    required this.lastUpdated,
  }) : availableQuantity = availableQuantity ?? totalQuantity;

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        categoryName,
        totalQuantity,
        minStock,
        averageCost,
        totalValue,
        isLowStock,
        isOutOfStock,
        warehouseId,
        fifoLots,
        availableQuantity,
        reservedQuantity,
        expiredQuantity,
        nearExpiryQuantity,
        lastUpdated,
      ];

  // Computed properties
  bool get hasStock => totalQuantity > 0;
  bool get isOverStock => minStock > 0 && totalQuantity > (minStock * 2);
  bool get hasExpiredLots => expiredQuantity > 0;
  bool get hasNearExpiryLots => nearExpiryQuantity > 0;
  
  String get stockStatus {
    if (isOutOfStock) return 'Sin stock';
    if (isLowStock) return 'Stock bajo';
    if (isOverStock) return 'Sobre stock';
    return 'Stock normal';
  }

  double get stockLevel {
    if (minStock <= 0) return 1.0;
    return (totalQuantity / minStock).clamp(0.0, 2.0);
  }

  InventoryBalance copyWith({
    String? productId,
    String? productName,
    String? productSku,
    String? categoryName,
    int? totalQuantity,
    int? minStock,
    double? averageCost,
    double? totalValue,
    bool? isLowStock,
    bool? isOutOfStock,
    String? warehouseId,
    List<InventoryLot>? fifoLots,
    int? availableQuantity,
    int? reservedQuantity,
    int? expiredQuantity,
    int? nearExpiryQuantity,
    DateTime? lastUpdated,
  }) {
    return InventoryBalance(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      categoryName: categoryName ?? this.categoryName,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      minStock: minStock ?? this.minStock,
      averageCost: averageCost ?? this.averageCost,
      totalValue: totalValue ?? this.totalValue,
      isLowStock: isLowStock ?? this.isLowStock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      warehouseId: warehouseId ?? this.warehouseId,
      fifoLots: fifoLots ?? this.fifoLots,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      expiredQuantity: expiredQuantity ?? this.expiredQuantity,
      nearExpiryQuantity: nearExpiryQuantity ?? this.nearExpiryQuantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Simplified lot class for compatibility
class InventoryLot extends Equatable {
  final String lotNumber;
  final int quantity;
  final double unitCost;
  final DateTime entryDate;
  final DateTime? expiryDate;

  const InventoryLot({
    required this.lotNumber,
    required this.quantity,
    required this.unitCost,
    required this.entryDate,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
        lotNumber,
        quantity,
        unitCost,
        entryDate,
        expiryDate,
      ];

  bool get hasExpiry => expiryDate != null;
  bool get isExpired => hasExpiry && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry => hasExpiry && 
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  double get totalValue => quantity * unitCost;
}

class FifoConsumption extends Equatable {
  final InventoryLot lot;
  final int quantityConsumed;
  final double unitCost;
  final double totalCost;

  const FifoConsumption({
    required this.lot,
    required this.quantityConsumed,
    required this.unitCost,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [lot, quantityConsumed, unitCost, totalCost];
}