// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_profitability_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryProfitabilityReportModel _$CategoryProfitabilityReportModelFromJson(
        Map<String, dynamic> json) =>
    CategoryProfitabilityReportModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryDescription: json['categoryDescription'] as String?,
      quantitySold: (json['quantitySold'] as num).toInt(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      grossProfit: (json['grossProfit'] as num).toDouble(),
      profitMargin: (json['profitMargin'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      productCount: (json['productCount'] as num).toInt(),
      averageProductPrice: (json['averageProductPrice'] as num).toDouble(),
      topSellingProductPrice:
          (json['topSellingProductPrice'] as num).toDouble(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      topSellingProducts: (json['topSellingProducts'] as List<dynamic>)
          .map((e) => TopSellingProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryProfitabilityReportModelToJson(
        CategoryProfitabilityReportModel instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'categoryDescription': instance.categoryDescription,
      'quantitySold': instance.quantitySold,
      'totalRevenue': instance.totalRevenue,
      'totalCost': instance.totalCost,
      'grossProfit': instance.grossProfit,
      'profitMargin': instance.profitMargin,
      'profitPercentage': instance.profitPercentage,
      'productCount': instance.productCount,
      'averageProductPrice': instance.averageProductPrice,
      'topSellingProductPrice': instance.topSellingProductPrice,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'topSellingProducts': instance.topSellingProducts,
    };

TopSellingProduct _$TopSellingProductFromJson(Map<String, dynamic> json) =>
    TopSellingProduct(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      revenue: (json['revenue'] as num).toDouble(),
    );

Map<String, dynamic> _$TopSellingProductToJson(TopSellingProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'revenue': instance.revenue,
    };
