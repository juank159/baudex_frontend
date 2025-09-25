// lib/features/reports/data/models/category_profitability_report_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/profitability_report.dart';

part 'category_profitability_report_model.g.dart';

@JsonSerializable()
class CategoryProfitabilityReportModel {
  final String categoryId;
  final String categoryName;
  final String? categoryDescription;
  final int quantitySold;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final double profitPercentage;
  final int productCount;
  final double averageProductPrice;
  final double topSellingProductPrice;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<TopSellingProduct> topSellingProducts;

  const CategoryProfitabilityReportModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.profitPercentage,
    required this.productCount,
    required this.averageProductPrice,
    required this.topSellingProductPrice,
    required this.periodStart,
    required this.periodEnd,
    required this.topSellingProducts,
  });

  factory CategoryProfitabilityReportModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryProfitabilityReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryProfitabilityReportModelToJson(this);

  CategoryProfitabilityReport toDomain() {
    return CategoryProfitabilityReport(
      categoryId: categoryId,
      categoryName: categoryName,
      totalProducts: productCount,
      quantitySold: quantitySold,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      profitPercentage: profitPercentage,
      periodStart: periodStart,
      periodEnd: periodEnd,
      topProducts: topSellingProducts.map((p) => ProfitabilityReport(
        productId: p.productId,
        productName: p.productName,
        productSku: '',
        quantitySold: p.quantity,
        totalRevenue: p.revenue,
        totalCost: 0,
        grossProfit: p.revenue,
        profitMargin: 0,
        profitPercentage: 0,
        averageSellingPrice: 0,
        averageCostPrice: 0,
        periodStart: periodStart,
        periodEnd: periodEnd,
      )).toList(),
    );
  }
}

@JsonSerializable()
class TopSellingProduct {
  final String productId;
  final String productName;
  final int quantity;
  final double revenue;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) =>
      _$TopSellingProductFromJson(json);

  Map<String, dynamic> toJson() => _$TopSellingProductToJson(this);
}