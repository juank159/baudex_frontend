// lib/features/reports/data/models/category_valuation_summary_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_valuation_report.dart';

part 'category_valuation_summary_model.g.dart';

@JsonSerializable()
class CategoryValuationSummaryModel {
  final String categoryId;
  final String categoryName;
  final String? categoryDescription;
  final double totalValue;
  final double totalCost;
  final double markupValue;
  final double markupPercentage;
  final int productCount;
  final int activeProductCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double averageUnitValue;
  final double maxProductValue;
  final double minProductValue;
  final DateTime asOfDate;
  final String valuationMethod;

  const CategoryValuationSummaryModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    required this.totalValue,
    required this.totalCost,
    required this.markupValue,
    required this.markupPercentage,
    required this.productCount,
    required this.activeProductCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.averageUnitValue,
    required this.maxProductValue,
    required this.minProductValue,
    required this.asOfDate,
    required this.valuationMethod,
  });

  factory CategoryValuationSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryValuationSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryValuationSummaryModelToJson(this);

  CategoryValuationSummary toDomain() {
    return CategoryValuationSummary(
      categoryId: categoryId,
      categoryName: categoryName,
      totalValue: totalValue,
      fifoValue: totalValue,
      lifoValue: totalValue,
      weightedAverageValue: totalValue,
      marketValue: totalValue,
      productCount: productCount,
      averageStockDays: 0,
    );
  }
}