// lib/features/inventory/data/models/inventory_balance_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_balance.dart';

part 'inventory_balance_model.g.dart';

@JsonSerializable()
class InventoryBalanceModel {
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
  
  // Optional field for compatibility
  final String? warehouseId;

  const InventoryBalanceModel({
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
  });

  factory InventoryBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryBalanceModelToJson(this);

  // Convert to domain entity
  InventoryBalance toEntity() {
    return InventoryBalance(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryName: categoryName,
      totalQuantity: totalQuantity,
      minStock: minStock,
      averageCost: averageCost,
      totalValue: totalValue,
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      warehouseId: warehouseId,
      lastUpdated: DateTime.now(),
    );
  }

  // Create from domain entity
  factory InventoryBalanceModel.fromEntity(InventoryBalance balance) {
    return InventoryBalanceModel(
      productId: balance.productId,
      productName: balance.productName,
      productSku: balance.productSku,
      categoryName: balance.categoryName,
      totalQuantity: balance.totalQuantity,
      minStock: balance.minStock,
      averageCost: balance.averageCost,
      totalValue: balance.totalValue,
      isLowStock: balance.isLowStock,
      isOutOfStock: balance.isOutOfStock,
      warehouseId: balance.warehouseId,
    );
  }

  @override
  String toString() {
    return 'InventoryBalanceModel{productId: $productId, productName: $productName, totalQuantity: $totalQuantity, totalValue: $totalValue}';
  }
}

// Simplified models for compatibility
@JsonSerializable()
class InventoryLotModel {
  final String lotNumber;
  final int quantity;
  final double unitCost;
  final DateTime entryDate;
  final DateTime? expiryDate;

  const InventoryLotModel({
    required this.lotNumber,
    required this.quantity,
    required this.unitCost,
    required this.entryDate,
    this.expiryDate,
  });

  factory InventoryLotModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryLotModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryLotModelToJson(this);

  InventoryLot toEntity() {
    return InventoryLot(
      lotNumber: lotNumber,
      quantity: quantity,
      unitCost: unitCost,
      entryDate: entryDate,
      expiryDate: expiryDate,
    );
  }
}

@JsonSerializable()
class FifoConsumptionModel {
  final InventoryLotModel lot;
  final int quantityConsumed;
  final double unitCost;
  final double totalCost;

  const FifoConsumptionModel({
    required this.lot,
    required this.quantityConsumed,
    required this.unitCost,
    required this.totalCost,
  });

  factory FifoConsumptionModel.fromJson(Map<String, dynamic> json) =>
      _$FifoConsumptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$FifoConsumptionModelToJson(this);

  FifoConsumption toEntity() {
    return FifoConsumption(
      lot: lot.toEntity(),
      quantityConsumed: quantityConsumed,
      unitCost: unitCost,
      totalCost: totalCost,
    );
  }
}