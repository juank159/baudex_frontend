// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profitability_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfitabilityStatsModel _$ProfitabilityStatsModelFromJson(
        Map<String, dynamic> json) =>
    ProfitabilityStatsModel(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalCOGS: (json['totalCOGS'] as num).toDouble(),
      grossProfit: (json['grossProfit'] as num).toDouble(),
      grossMarginPercentage: (json['grossMarginPercentage'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
      netMarginPercentage: (json['netMarginPercentage'] as num).toDouble(),
      averageMarginPerSale: (json['averageMarginPerSale'] as num).toDouble(),
      topProfitableProducts: (json['topProfitableProducts'] as List<dynamic>)
          .map((e) =>
              ProductProfitabilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowProfitableProducts: (json['lowProfitableProducts'] as List<dynamic>)
          .map((e) =>
              ProductProfitabilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      marginsByCategory:
          (json['marginsByCategory'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      trend: ProfitabilityTrendModel.fromJson(
          json['trend'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfitabilityStatsModelToJson(
        ProfitabilityStatsModel instance) =>
    <String, dynamic>{
      'totalRevenue': instance.totalRevenue,
      'totalCOGS': instance.totalCOGS,
      'grossProfit': instance.grossProfit,
      'grossMarginPercentage': instance.grossMarginPercentage,
      'netProfit': instance.netProfit,
      'netMarginPercentage': instance.netMarginPercentage,
      'averageMarginPerSale': instance.averageMarginPerSale,
      'marginsByCategory': instance.marginsByCategory,
      'topProfitableProducts': instance.topProfitableProducts,
      'lowProfitableProducts': instance.lowProfitableProducts,
      'trend': instance.trend,
    };

ProductProfitabilityModel _$ProductProfitabilityModelFromJson(
        Map<String, dynamic> json) =>
    ProductProfitabilityModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String,
      categoryName: json['categoryName'] as String?,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalCOGS: (json['totalCOGS'] as num).toDouble(),
      grossProfit: (json['grossProfit'] as num).toDouble(),
      marginPercentage: (json['marginPercentage'] as num).toDouble(),
      unitsSold: (json['unitsSold'] as num).toInt(),
      averageSellingPrice: (json['averageSellingPrice'] as num).toDouble(),
      averageFifoCost: (json['averageFifoCost'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductProfitabilityModelToJson(
        ProductProfitabilityModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'sku': instance.sku,
      'categoryName': instance.categoryName,
      'totalRevenue': instance.totalRevenue,
      'totalCOGS': instance.totalCOGS,
      'grossProfit': instance.grossProfit,
      'marginPercentage': instance.marginPercentage,
      'unitsSold': instance.unitsSold,
      'averageSellingPrice': instance.averageSellingPrice,
      'averageFifoCost': instance.averageFifoCost,
    };

ProfitabilityTrendModel _$ProfitabilityTrendModelFromJson(
        Map<String, dynamic> json) =>
    ProfitabilityTrendModel(
      previousPeriodGrossMargin:
          (json['previousPeriodGrossMargin'] as num).toDouble(),
      currentPeriodGrossMargin:
          (json['currentPeriodGrossMargin'] as num).toDouble(),
      marginGrowth: (json['marginGrowth'] as num).toDouble(),
      isImproving: json['isImproving'] as bool,
      dailyMargins: (json['dailyMargins'] as List<dynamic>)
          .map((e) => DailyMarginPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProfitabilityTrendModelToJson(
        ProfitabilityTrendModel instance) =>
    <String, dynamic>{
      'previousPeriodGrossMargin': instance.previousPeriodGrossMargin,
      'currentPeriodGrossMargin': instance.currentPeriodGrossMargin,
      'marginGrowth': instance.marginGrowth,
      'isImproving': instance.isImproving,
      'dailyMargins': instance.dailyMargins,
    };

DailyMarginPointModel _$DailyMarginPointModelFromJson(
        Map<String, dynamic> json) =>
    DailyMarginPointModel(
      date: DateTime.parse(json['date'] as String),
      grossMarginPercentage: (json['grossMarginPercentage'] as num).toDouble(),
      dailyRevenue: (json['dailyRevenue'] as num).toDouble(),
      dailyCOGS: (json['dailyCOGS'] as num).toDouble(),
    );

Map<String, dynamic> _$DailyMarginPointModelToJson(
        DailyMarginPointModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'grossMarginPercentage': instance.grossMarginPercentage,
      'dailyRevenue': instance.dailyRevenue,
      'dailyCOGS': instance.dailyCOGS,
    };
