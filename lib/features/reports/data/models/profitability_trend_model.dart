// lib/features/reports/data/models/profitability_trend_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/profitability_report.dart';

part 'profitability_trend_model.g.dart';

@JsonSerializable()
class ProfitabilityTrendModel {
  final DateTime period;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final int transactionCount;
  final int itemsSold;
  final double averageOrderValue;
  final String? productId;
  final String? productName;
  final String? categoryId;
  final String? categoryName;

  const ProfitabilityTrendModel({
    required this.period,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.transactionCount,
    required this.itemsSold,
    required this.averageOrderValue,
    this.productId,
    this.productName,
    this.categoryId,
    this.categoryName,
  });

  factory ProfitabilityTrendModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitabilityTrendModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitabilityTrendModelToJson(this);

  ProfitabilityTrend toDomain() {
    return ProfitabilityTrend(
      date: period,
      revenue: revenue,
      cost: cost,
      profit: profit,
      margin: margin,
      quantity: itemsSold,
    );
  }
}