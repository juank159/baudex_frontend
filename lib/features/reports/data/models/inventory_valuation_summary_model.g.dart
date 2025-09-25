// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_valuation_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryValuationSummaryModel _$InventoryValuationSummaryModelFromJson(
        Map<String, dynamic> json) =>
    InventoryValuationSummaryModel(
      asOfDate: DateTime.parse(json['asOfDate'] as String),
      valuationMethod: json['valuationMethod'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      totalMarkupValue: (json['totalMarkupValue'] as num).toDouble(),
      averageMarkupPercentage:
          (json['averageMarkupPercentage'] as num).toDouble(),
      totalProducts: (json['totalProducts'] as num).toInt(),
      totalCategories: (json['totalCategories'] as num).toInt(),
      lowStockProducts: (json['lowStockProducts'] as num).toInt(),
      overstockProducts: (json['overstockProducts'] as num).toInt(),
      expiringSoonProducts: (json['expiringSoonProducts'] as num).toInt(),
      expiringSoonValue: (json['expiringSoonValue'] as num).toDouble(),
      categorySummaries: (json['categorySummaries'] as List<dynamic>)
          .map((e) => CategorySummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      warehouseSummaries: (json['warehouseSummaries'] as List<dynamic>)
          .map((e) => WarehouseSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topValuedProducts: (json['topValuedProducts'] as List<dynamic>)
          .map((e) => TopValuedProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InventoryValuationSummaryModelToJson(
        InventoryValuationSummaryModel instance) =>
    <String, dynamic>{
      'asOfDate': instance.asOfDate.toIso8601String(),
      'valuationMethod': instance.valuationMethod,
      'totalValue': instance.totalValue,
      'totalCost': instance.totalCost,
      'totalMarkupValue': instance.totalMarkupValue,
      'averageMarkupPercentage': instance.averageMarkupPercentage,
      'totalProducts': instance.totalProducts,
      'totalCategories': instance.totalCategories,
      'lowStockProducts': instance.lowStockProducts,
      'overstockProducts': instance.overstockProducts,
      'expiringSoonProducts': instance.expiringSoonProducts,
      'expiringSoonValue': instance.expiringSoonValue,
      'categorySummaries': instance.categorySummaries,
      'warehouseSummaries': instance.warehouseSummaries,
      'topValuedProducts': instance.topValuedProducts,
    };

CategorySummaryModel _$CategorySummaryModelFromJson(
        Map<String, dynamic> json) =>
    CategorySummaryModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
    );

Map<String, dynamic> _$CategorySummaryModelToJson(
        CategorySummaryModel instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'totalValue': instance.totalValue,
      'productCount': instance.productCount,
    };

WarehouseSummaryModel _$WarehouseSummaryModelFromJson(
        Map<String, dynamic> json) =>
    WarehouseSummaryModel(
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
    );

Map<String, dynamic> _$WarehouseSummaryModelToJson(
        WarehouseSummaryModel instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'totalValue': instance.totalValue,
      'productCount': instance.productCount,
    };

TopValuedProductModel _$TopValuedProductModelFromJson(
        Map<String, dynamic> json) =>
    TopValuedProductModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      unitValue: (json['unitValue'] as num).toDouble(),
    );

Map<String, dynamic> _$TopValuedProductModelToJson(
        TopValuedProductModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'totalValue': instance.totalValue,
      'quantity': instance.quantity,
      'unitValue': instance.unitValue,
    };
