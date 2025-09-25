// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WarehouseStatsModel _$WarehouseStatsModelFromJson(Map<String, dynamic> json) =>
    WarehouseStatsModel(
      totalProducts: (json['totalProducts'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      totalQuantity: (json['totalQuantity'] as num).toDouble(),
      lowStockProducts: (json['lowStockProducts'] as num).toInt(),
      outOfStockProducts: (json['outOfStockProducts'] as num).toInt(),
    );

Map<String, dynamic> _$WarehouseStatsModelToJson(
        WarehouseStatsModel instance) =>
    <String, dynamic>{
      'totalProducts': instance.totalProducts,
      'totalValue': instance.totalValue,
      'totalQuantity': instance.totalQuantity,
      'lowStockProducts': instance.lowStockProducts,
      'outOfStockProducts': instance.outOfStockProducts,
    };
