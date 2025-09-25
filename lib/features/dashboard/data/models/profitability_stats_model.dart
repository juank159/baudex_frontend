// lib/features/dashboard/data/models/profitability_stats_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/dashboard_stats.dart';

part 'profitability_stats_model.g.dart';

@JsonSerializable()
class ProfitabilityStatsModel extends ProfitabilityStats {
  @override
  final List<ProductProfitabilityModel> topProfitableProducts;
  
  @override
  final List<ProductProfitabilityModel> lowProfitableProducts;
  
  @override
  final ProfitabilityTrendModel trend;

  const ProfitabilityStatsModel({
    required super.totalRevenue,
    required super.totalCOGS,
    required super.grossProfit,
    required super.grossMarginPercentage,
    required super.netProfit,
    required super.netMarginPercentage,
    required super.averageMarginPerSale,
    required this.topProfitableProducts,
    required this.lowProfitableProducts,
    required super.marginsByCategory,
    required this.trend,
  }) : super(
          topProfitableProducts: topProfitableProducts,
          lowProfitableProducts: lowProfitableProducts,
          trend: trend,
        );

  factory ProfitabilityStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitabilityStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitabilityStatsModelToJson(this);

  factory ProfitabilityStatsModel.fromEntity(ProfitabilityStats entity) {
    return ProfitabilityStatsModel(
      totalRevenue: entity.totalRevenue,
      totalCOGS: entity.totalCOGS,
      grossProfit: entity.grossProfit,
      grossMarginPercentage: entity.grossMarginPercentage,
      netProfit: entity.netProfit,
      netMarginPercentage: entity.netMarginPercentage,
      averageMarginPerSale: entity.averageMarginPerSale,
      topProfitableProducts: entity.topProfitableProducts
          .map((e) => ProductProfitabilityModel(
                productId: e.productId,
                productName: e.productName,
                sku: e.sku,
                categoryName: e.categoryName,
                totalRevenue: e.totalRevenue,
                totalCOGS: e.totalCOGS,
                grossProfit: e.grossProfit,
                marginPercentage: e.marginPercentage,
                unitsSold: e.unitsSold,
                averageSellingPrice: e.averageSellingPrice,
                averageFifoCost: e.averageFifoCost,
              ))
          .toList(),
      lowProfitableProducts: entity.lowProfitableProducts
          .map((e) => ProductProfitabilityModel(
                productId: e.productId,
                productName: e.productName,
                sku: e.sku,
                categoryName: e.categoryName,
                totalRevenue: e.totalRevenue,
                totalCOGS: e.totalCOGS,
                grossProfit: e.grossProfit,
                marginPercentage: e.marginPercentage,
                unitsSold: e.unitsSold,
                averageSellingPrice: e.averageSellingPrice,
                averageFifoCost: e.averageFifoCost,
              ))
          .toList(),
      marginsByCategory: entity.marginsByCategory,
      trend: ProfitabilityTrendModel(
        previousPeriodGrossMargin: entity.trend.previousPeriodGrossMargin,
        currentPeriodGrossMargin: entity.trend.currentPeriodGrossMargin,
        marginGrowth: entity.trend.marginGrowth,
        isImproving: entity.trend.isImproving,
        dailyMargins: entity.trend.dailyMargins
            .map((e) => DailyMarginPointModel(
                  date: e.date,
                  grossMarginPercentage: e.grossMarginPercentage,
                  dailyRevenue: e.dailyRevenue,
                  dailyCOGS: e.dailyCOGS,
                ))
            .toList(),
      ),
    );
  }

  ProfitabilityStats toEntity() {
    return ProfitabilityStats(
      totalRevenue: totalRevenue,
      totalCOGS: totalCOGS,
      grossProfit: grossProfit,
      grossMarginPercentage: grossMarginPercentage,
      netProfit: netProfit,
      netMarginPercentage: netMarginPercentage,
      averageMarginPerSale: averageMarginPerSale,
      topProfitableProducts: topProfitableProducts
          .map((e) => ProductProfitability(
                productId: e.productId,
                productName: e.productName,
                sku: e.sku,
                categoryName: e.categoryName,
                totalRevenue: e.totalRevenue,
                totalCOGS: e.totalCOGS,
                grossProfit: e.grossProfit,
                marginPercentage: e.marginPercentage,
                unitsSold: e.unitsSold,
                averageSellingPrice: e.averageSellingPrice,
                averageFifoCost: e.averageFifoCost,
              ))
          .toList(),
      lowProfitableProducts: lowProfitableProducts
          .map((e) => ProductProfitability(
                productId: e.productId,
                productName: e.productName,
                sku: e.sku,
                categoryName: e.categoryName,
                totalRevenue: e.totalRevenue,
                totalCOGS: e.totalCOGS,
                grossProfit: e.grossProfit,
                marginPercentage: e.marginPercentage,
                unitsSold: e.unitsSold,
                averageSellingPrice: e.averageSellingPrice,
                averageFifoCost: e.averageFifoCost,
              ))
          .toList(),
      marginsByCategory: marginsByCategory,
      trend: ProfitabilityTrend(
        previousPeriodGrossMargin: trend.previousPeriodGrossMargin,
        currentPeriodGrossMargin: trend.currentPeriodGrossMargin,
        marginGrowth: trend.marginGrowth,
        isImproving: trend.isImproving,
        dailyMargins: trend.dailyMargins
            .map((e) => DailyMarginPoint(
                  date: e.date,
                  grossMarginPercentage: e.grossMarginPercentage,
                  dailyRevenue: e.dailyRevenue,
                  dailyCOGS: e.dailyCOGS,
                ))
            .toList(),
      ),
    );
  }
}

@JsonSerializable()
class ProductProfitabilityModel extends ProductProfitability {
  const ProductProfitabilityModel({
    required super.productId,
    required super.productName,
    required super.sku,
    super.categoryName,
    required super.totalRevenue,
    required super.totalCOGS,
    required super.grossProfit,
    required super.marginPercentage,
    required super.unitsSold,
    required super.averageSellingPrice,
    required super.averageFifoCost,
  });

  factory ProductProfitabilityModel.fromJson(Map<String, dynamic> json) =>
      _$ProductProfitabilityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductProfitabilityModelToJson(this);
}

@JsonSerializable()
class ProfitabilityTrendModel extends ProfitabilityTrend {
  @override
  final List<DailyMarginPointModel> dailyMargins;

  const ProfitabilityTrendModel({
    required super.previousPeriodGrossMargin,
    required super.currentPeriodGrossMargin,
    required super.marginGrowth,
    required super.isImproving,
    required this.dailyMargins,
  }) : super(
          dailyMargins: dailyMargins,
        );

  factory ProfitabilityTrendModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitabilityTrendModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitabilityTrendModelToJson(this);
}

@JsonSerializable()
class DailyMarginPointModel extends DailyMarginPoint {
  const DailyMarginPointModel({
    required super.date,
    required super.grossMarginPercentage,
    required super.dailyRevenue,
    required super.dailyCOGS,
  });

  factory DailyMarginPointModel.fromJson(Map<String, dynamic> json) =>
      _$DailyMarginPointModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyMarginPointModelToJson(this);
}