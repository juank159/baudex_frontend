// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_valuation_variance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryValuationVarianceModel _$InventoryValuationVarianceModelFromJson(
        Map<String, dynamic> json) =>
    InventoryValuationVarianceModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String?,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String,
      bookValue: (json['bookValue'] as num).toDouble(),
      marketValue: (json['marketValue'] as num).toDouble(),
      varianceAmount: (json['varianceAmount'] as num).toDouble(),
      variancePercentage: (json['variancePercentage'] as num).toDouble(),
      varianceType: json['varianceType'] as String,
      currentQuantity: (json['currentQuantity'] as num).toInt(),
      unitBookValue: (json['unitBookValue'] as num).toDouble(),
      unitMarketValue: (json['unitMarketValue'] as num).toDouble(),
      lastCostUpdate: DateTime.parse(json['lastCostUpdate'] as String),
      lastPriceUpdate: DateTime.parse(json['lastPriceUpdate'] as String),
      asOfDate: DateTime.parse(json['asOfDate'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$InventoryValuationVarianceModelToJson(
        InventoryValuationVarianceModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'productSku': instance.productSku,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'bookValue': instance.bookValue,
      'marketValue': instance.marketValue,
      'varianceAmount': instance.varianceAmount,
      'variancePercentage': instance.variancePercentage,
      'varianceType': instance.varianceType,
      'currentQuantity': instance.currentQuantity,
      'unitBookValue': instance.unitBookValue,
      'unitMarketValue': instance.unitMarketValue,
      'lastCostUpdate': instance.lastCostUpdate.toIso8601String(),
      'lastPriceUpdate': instance.lastPriceUpdate.toIso8601String(),
      'asOfDate': instance.asOfDate.toIso8601String(),
      'notes': instance.notes,
    };
