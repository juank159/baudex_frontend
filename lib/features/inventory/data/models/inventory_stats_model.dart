// lib/features/inventory/data/models/inventory_stats_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_stats.dart';

part 'inventory_stats_model.g.dart';

@JsonSerializable()
class InventoryStatsModel {
  final int totalProducts;
  final int totalBatches;
  final int totalMovements;
  final double totalValue;
  final Map<String, dynamic> movementsByType;

  const InventoryStatsModel({
    required this.totalProducts,
    required this.totalBatches,
    required this.totalMovements,
    required this.totalValue,
    required this.movementsByType,
  });

  factory InventoryStatsModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryStatsModelToJson(this);

  // Convert to domain entity
  InventoryStats toEntity() {
    return InventoryStats(
      totalProducts: totalProducts,
      totalBatches: totalBatches,
      totalMovements: totalMovements,
      totalValue: totalValue,
      movementsByType: movementsByType,
    );
  }

  // Create from domain entity
  factory InventoryStatsModel.fromEntity(InventoryStats stats) {
    return InventoryStatsModel(
      totalProducts: stats.totalProducts,
      totalBatches: stats.totalBatches,
      totalMovements: stats.totalMovements,
      totalValue: stats.totalValue,
      movementsByType: stats.movementsByType,
    );
  }

  @override
  String toString() {
    return 'InventoryStatsModel{totalProducts: $totalProducts, totalBatches: $totalBatches, totalMovements: $totalMovements, totalValue: $totalValue, movementsByType: $movementsByType}';
  }
}

