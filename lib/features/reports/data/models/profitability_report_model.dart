// lib/features/reports/data/models/profitability_report_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/profitability_report.dart';

part 'profitability_report_model.g.dart';

@JsonSerializable()
class ProfitabilityReportModel {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final String? warehouseId;
  final String? warehouseName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double grossMarginPercentage;
  final int unitsSold;
  final double averageSellingPrice;
  final double averageCost;
  final double rotationRate;
  final List<ProfitabilityDetailModel>? details;

  const ProfitabilityReportModel({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    this.warehouseId,
    this.warehouseName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.grossMarginPercentage,
    required this.unitsSold,
    required this.averageSellingPrice,
    required this.averageCost,
    required this.rotationRate,
    this.details,
  });

  factory ProfitabilityReportModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitabilityReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitabilityReportModelToJson(this);

  ProfitabilityReport toDomain() {
    return ProfitabilityReport(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      quantitySold: unitsSold,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: grossMarginPercentage,
      profitPercentage: grossMarginPercentage,
      averageSellingPrice: averageSellingPrice,
      averageCostPrice: averageCost,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}

@JsonSerializable()
class ProfitabilityDetailModel {
  final DateTime date;
  final String invoiceId;
  final String invoiceNumber;
  final double quantity;
  final double unitPrice;
  final double unitCost;
  final double lineRevenue;
  final double lineCost;
  final double lineProfit;
  final String? customerId;
  final String? customerName;

  const ProfitabilityDetailModel({
    required this.date,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.lineRevenue,
    required this.lineCost,
    required this.lineProfit,
    this.customerId,
    this.customerName,
  });

  factory ProfitabilityDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitabilityDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitabilityDetailModelToJson(this);

  ProfitabilityDetail toDomain() {
    return ProfitabilityDetail(
      id: invoiceId,
      date: date,
      transactionType: 'sale',
      quantity: quantity.toInt(),
      unitPrice: unitPrice,
      unitCost: unitCost,
      revenue: lineRevenue,
      cost: lineCost,
      profit: lineProfit,
      margin: lineProfit / lineRevenue * 100,
      invoiceId: invoiceId,
      customerId: customerId,
      customerName: customerName,
    );
  }
}

