// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_valuation_breakdown_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryValuationBreakdownModel _$CategoryValuationBreakdownModelFromJson(
        Map<String, dynamic> json) =>
    CategoryValuationBreakdownModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryDescription: json['categoryDescription'] as String?,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      markupValue: (json['markupValue'] as num).toDouble(),
      markupPercentage: (json['markupPercentage'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
      totalQuantity: (json['totalQuantity'] as num).toInt(),
      averageUnitValue: (json['averageUnitValue'] as num).toDouble(),
      asOfDate: DateTime.parse(json['asOfDate'] as String),
      valuationMethod: json['valuationMethod'] as String,
      productBreakdown: (json['productBreakdown'] as List<dynamic>)
          .map((e) =>
              ProductValuationDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      warehouseBreakdown: (json['warehouseBreakdown'] as List<dynamic>)
          .map((e) => WarehouseValuationBreakdownModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      valuationTrend: json['valuationTrend'] == null
          ? null
          : ValuationTrendModel.fromJson(
              json['valuationTrend'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CategoryValuationBreakdownModelToJson(
        CategoryValuationBreakdownModel instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'categoryDescription': instance.categoryDescription,
      'totalValue': instance.totalValue,
      'totalCost': instance.totalCost,
      'markupValue': instance.markupValue,
      'markupPercentage': instance.markupPercentage,
      'productCount': instance.productCount,
      'totalQuantity': instance.totalQuantity,
      'averageUnitValue': instance.averageUnitValue,
      'asOfDate': instance.asOfDate.toIso8601String(),
      'valuationMethod': instance.valuationMethod,
      'productBreakdown': instance.productBreakdown,
      'warehouseBreakdown': instance.warehouseBreakdown,
      'valuationTrend': instance.valuationTrend,
    };

ProductValuationDetailModel _$ProductValuationDetailModelFromJson(
        Map<String, dynamic> json) =>
    ProductValuationDetailModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      unitValue: (json['unitValue'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductValuationDetailModelToJson(
        ProductValuationDetailModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'totalValue': instance.totalValue,
      'quantity': instance.quantity,
      'unitValue': instance.unitValue,
    };

WarehouseValuationBreakdownModel _$WarehouseValuationBreakdownModelFromJson(
        Map<String, dynamic> json) =>
    WarehouseValuationBreakdownModel(
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
      totalQuantity: (json['totalQuantity'] as num).toInt(),
    );

Map<String, dynamic> _$WarehouseValuationBreakdownModelToJson(
        WarehouseValuationBreakdownModel instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'totalValue': instance.totalValue,
      'productCount': instance.productCount,
      'totalQuantity': instance.totalQuantity,
    };

ValuationTrendModel _$ValuationTrendModelFromJson(Map<String, dynamic> json) =>
    ValuationTrendModel(
      period: DateTime.parse(json['period'] as String),
      value: (json['value'] as num).toDouble(),
      changeFromPrevious: (json['changeFromPrevious'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
    );

Map<String, dynamic> _$ValuationTrendModelToJson(
        ValuationTrendModel instance) =>
    <String, dynamic>{
      'period': instance.period.toIso8601String(),
      'value': instance.value,
      'changeFromPrevious': instance.changeFromPrevious,
      'changePercentage': instance.changePercentage,
    };
