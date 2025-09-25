// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profitability_trend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfitabilityTrendModel _$ProfitabilityTrendModelFromJson(
        Map<String, dynamic> json) =>
    ProfitabilityTrendModel(
      period: DateTime.parse(json['period'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      margin: (json['margin'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      itemsSold: (json['itemsSold'] as num).toInt(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
    );

Map<String, dynamic> _$ProfitabilityTrendModelToJson(
        ProfitabilityTrendModel instance) =>
    <String, dynamic>{
      'period': instance.period.toIso8601String(),
      'revenue': instance.revenue,
      'cost': instance.cost,
      'profit': instance.profit,
      'margin': instance.margin,
      'transactionCount': instance.transactionCount,
      'itemsSold': instance.itemsSold,
      'averageOrderValue': instance.averageOrderValue,
      'productId': instance.productId,
      'productName': instance.productName,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
    };
