// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_valuation_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryValuationSummaryModel _$CategoryValuationSummaryModelFromJson(
        Map<String, dynamic> json) =>
    CategoryValuationSummaryModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryDescription: json['categoryDescription'] as String?,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      markupValue: (json['markupValue'] as num).toDouble(),
      markupPercentage: (json['markupPercentage'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
      activeProductCount: (json['activeProductCount'] as num).toInt(),
      lowStockCount: (json['lowStockCount'] as num).toInt(),
      outOfStockCount: (json['outOfStockCount'] as num).toInt(),
      averageUnitValue: (json['averageUnitValue'] as num).toDouble(),
      maxProductValue: (json['maxProductValue'] as num).toDouble(),
      minProductValue: (json['minProductValue'] as num).toDouble(),
      asOfDate: DateTime.parse(json['asOfDate'] as String),
      valuationMethod: json['valuationMethod'] as String,
    );

Map<String, dynamic> _$CategoryValuationSummaryModelToJson(
        CategoryValuationSummaryModel instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'categoryDescription': instance.categoryDescription,
      'totalValue': instance.totalValue,
      'totalCost': instance.totalCost,
      'markupValue': instance.markupValue,
      'markupPercentage': instance.markupPercentage,
      'productCount': instance.productCount,
      'activeProductCount': instance.activeProductCount,
      'lowStockCount': instance.lowStockCount,
      'outOfStockCount': instance.outOfStockCount,
      'averageUnitValue': instance.averageUnitValue,
      'maxProductValue': instance.maxProductValue,
      'minProductValue': instance.minProductValue,
      'asOfDate': instance.asOfDate.toIso8601String(),
      'valuationMethod': instance.valuationMethod,
    };
