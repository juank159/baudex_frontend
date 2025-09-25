// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryStatsModel _$InventoryStatsModelFromJson(Map<String, dynamic> json) =>
    InventoryStatsModel(
      totalProducts: (json['totalProducts'] as num).toInt(),
      totalBatches: (json['totalBatches'] as num).toInt(),
      totalMovements: (json['totalMovements'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      movementsByType: json['movementsByType'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$InventoryStatsModelToJson(
        InventoryStatsModel instance) =>
    <String, dynamic>{
      'totalProducts': instance.totalProducts,
      'totalBatches': instance.totalBatches,
      'totalMovements': instance.totalMovements,
      'totalValue': instance.totalValue,
      'movementsByType': instance.movementsByType,
    };
