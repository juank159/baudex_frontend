// lib/features/reports/data/models/category_valuation_breakdown_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_valuation_report.dart';

part 'category_valuation_breakdown_model.g.dart';

@JsonSerializable()
class CategoryValuationBreakdownModel {
  final String categoryId;
  final String categoryName;
  final String? categoryDescription;
  final double totalValue;
  final double totalCost;
  final double markupValue;
  final double markupPercentage;
  final int productCount;
  final int totalQuantity;
  final double averageUnitValue;
  final DateTime asOfDate;
  final String valuationMethod;
  final List<ProductValuationDetailModel> productBreakdown;
  final List<WarehouseValuationBreakdownModel> warehouseBreakdown;
  final ValuationTrendModel? valuationTrend;

  const CategoryValuationBreakdownModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    required this.totalValue,
    required this.totalCost,
    required this.markupValue,
    required this.markupPercentage,
    required this.productCount,
    required this.totalQuantity,
    required this.averageUnitValue,
    required this.asOfDate,
    required this.valuationMethod,
    required this.productBreakdown,
    required this.warehouseBreakdown,
    this.valuationTrend,
  });

  factory CategoryValuationBreakdownModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryValuationBreakdownModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryValuationBreakdownModelToJson(this);

  CategoryValuationBreakdown toDomain() {
    return CategoryValuationBreakdown(
      categoryId: categoryId,
      categoryName: categoryName,
      productCount: productCount,
      totalQuantity: totalQuantity,
      totalValue: totalValue,
      averageUnitCost: totalValue / totalQuantity,
      fifoValue: totalValue,
      lifoValue: totalValue,
      weightedAverageValue: totalValue,
      marketValue: totalValue,
      valuationVariance: 0,
      valuationVariancePercentage: 0,
      percentageOfTotalValue: 100,
      topProducts: [],
    );
  }
}

@JsonSerializable()
class ProductValuationDetailModel {
  final String productId;
  final String productName;
  final double totalValue;
  final int quantity;
  final double unitValue;

  const ProductValuationDetailModel({
    required this.productId,
    required this.productName,
    required this.totalValue,
    required this.quantity,
    required this.unitValue,
  });

  factory ProductValuationDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProductValuationDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductValuationDetailModelToJson(this);

  TopValuedProduct toDomain() {
    return TopValuedProduct(
      productId: productId,
      productName: productName,
      productSku: '',
      totalValue: totalValue,
      quantity: quantity.toInt(),
      unitCost: unitValue,
      ranking: 1,
      percentageOfTotalValue: 0,
      percentageOfCategoryValue: 0,
    );
  }
}

@JsonSerializable()
class WarehouseValuationBreakdownModel {
  final String warehouseId;
  final String warehouseName;
  final double totalValue;
  final int productCount;
  final int totalQuantity;

  const WarehouseValuationBreakdownModel({
    required this.warehouseId,
    required this.warehouseName,
    required this.totalValue,
    required this.productCount,
    required this.totalQuantity,
  });

  factory WarehouseValuationBreakdownModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseValuationBreakdownModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseValuationBreakdownModelToJson(this);

  WarehouseValuationBreakdown toDomain() {
    return WarehouseValuationBreakdown(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      productCount: productCount,
      totalQuantity: totalQuantity,
      totalValue: totalValue,
      averageUnitCost: totalValue / totalQuantity,
      fifoValue: totalValue,
      lifoValue: totalValue,
      weightedAverageValue: totalValue,
      marketValue: totalValue,
      valuationVariance: 0,
      valuationVariancePercentage: 0,
      percentageOfTotalValue: 100,
      topProducts: [],
    );
  }
}

@JsonSerializable()
class ValuationTrendModel {
  final DateTime period;
  final double value;
  final double changeFromPrevious;
  final double changePercentage;

  const ValuationTrendModel({
    required this.period,
    required this.value,
    required this.changeFromPrevious,
    required this.changePercentage,
  });

  factory ValuationTrendModel.fromJson(Map<String, dynamic> json) =>
      _$ValuationTrendModelFromJson(json);

  Map<String, dynamic> toJson() => _$ValuationTrendModelToJson(this);

  CategoryValuationSummary toDomain() {
    return CategoryValuationSummary(
      categoryId: 'trend',
      categoryName: 'Trend Analysis',
      totalValue: value,
      fifoValue: value,
      lifoValue: value,
      weightedAverageValue: value,
      marketValue: value,
      productCount: 0,
      averageStockDays: 0,
    );
  }
}