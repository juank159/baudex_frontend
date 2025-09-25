// lib/features/reports/data/models/inventory_valuation_summary_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_valuation_report.dart';

part 'inventory_valuation_summary_model.g.dart';

@JsonSerializable()
class InventoryValuationSummaryModel {
  final DateTime asOfDate;
  final String valuationMethod;
  final double totalValue;
  final double totalCost;
  final double totalMarkupValue;
  final double averageMarkupPercentage;
  final int totalProducts;
  final int totalCategories;
  final int lowStockProducts;
  final int overstockProducts;
  final int expiringSoonProducts;
  final double expiringSoonValue;
  final List<CategorySummaryModel> categorySummaries;
  final List<WarehouseSummaryModel> warehouseSummaries;
  final List<TopValuedProductModel> topValuedProducts;

  const InventoryValuationSummaryModel({
    required this.asOfDate,
    required this.valuationMethod,
    required this.totalValue,
    required this.totalCost,
    required this.totalMarkupValue,
    required this.averageMarkupPercentage,
    required this.totalProducts,
    required this.totalCategories,
    required this.lowStockProducts,
    required this.overstockProducts,
    required this.expiringSoonProducts,
    required this.expiringSoonValue,
    required this.categorySummaries,
    required this.warehouseSummaries,
    required this.topValuedProducts,
  });

  factory InventoryValuationSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryValuationSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryValuationSummaryModelToJson(this);

  InventoryValuationSummary toDomain() {
    return InventoryValuationSummary(
      totalInventoryValue: totalValue,
      totalFifoValue: totalValue,
      totalLifoValue: totalValue,
      totalWeightedAverageValue: totalValue,
      totalMarketValue: totalValue - totalMarkupValue,
      totalProducts: totalProducts,
      totalCategories: totalCategories,
      totalQuantity: 0,
      averageCostPerUnit: totalProducts > 0 ? totalCost / totalProducts : 0,
      averageStockDays: 0,
      valuationDate: asOfDate,
      valuationMethod: valuationMethod,
      categorySummaries: categorySummaries.map((cs) => cs.toDomain()).toList(),
      warehouseBreakdown: warehouseSummaries.map((ws) => ws.toDomain()).toList(),
    );
  }
}

@JsonSerializable()
class CategorySummaryModel {
  final String categoryId;
  final String categoryName;
  final double totalValue;
  final int productCount;

  const CategorySummaryModel({
    required this.categoryId,
    required this.categoryName,
    required this.totalValue,
    required this.productCount,
  });

  factory CategorySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategorySummaryModelToJson(this);

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

@JsonSerializable()
class WarehouseSummaryModel {
  final String warehouseId;
  final String warehouseName;
  final double totalValue;
  final int productCount;

  const WarehouseSummaryModel({
    required this.warehouseId,
    required this.warehouseName,
    required this.totalValue,
    required this.productCount,
  });

  factory WarehouseSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseSummaryModelToJson(this);

  WarehouseValuationBreakdown toDomain() {
    return WarehouseValuationBreakdown(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      productCount: productCount,
      totalQuantity: 0,
      totalValue: totalValue,
      averageUnitCost: 0,
      fifoValue: totalValue,
      lifoValue: totalValue,
      weightedAverageValue: totalValue,
      marketValue: totalValue,
      valuationVariance: 0,
      valuationVariancePercentage: 0,
      percentageOfTotalValue: 0,
    );
  }
}

@JsonSerializable()
class TopValuedProductModel {
  final String productId;
  final String productName;
  final double totalValue;
  final int quantity;
  final double unitValue;

  const TopValuedProductModel({
    required this.productId,
    required this.productName,
    required this.totalValue,
    required this.quantity,
    required this.unitValue,
  });

  factory TopValuedProductModel.fromJson(Map<String, dynamic> json) =>
      _$TopValuedProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopValuedProductModelToJson(this);

  TopValuedProduct toDomain() {
    return TopValuedProduct(
      productId: productId,
      productName: productName,
      productSku: '',
      totalValue: totalValue,
      quantity: quantity,
      unitCost: unitValue,
      ranking: 1,
      percentageOfTotalValue: 0,
      percentageOfCategoryValue: 0,
    );
  }
}