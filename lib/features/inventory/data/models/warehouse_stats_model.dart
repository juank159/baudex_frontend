// lib/features/inventory/data/models/warehouse_stats_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/warehouse_with_stats.dart';

part 'warehouse_stats_model.g.dart';

@JsonSerializable()
class WarehouseStatsModel extends WarehouseStats {
  const WarehouseStatsModel({
    required int totalProducts,
    required double totalValue,
    required double totalQuantity,
    required int lowStockProducts,
    required int outOfStockProducts,
  }) : super(
          totalProducts: totalProducts,
          totalValue: totalValue,
          totalQuantity: totalQuantity,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
        );

  factory WarehouseStatsModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseStatsModelToJson(this);
}