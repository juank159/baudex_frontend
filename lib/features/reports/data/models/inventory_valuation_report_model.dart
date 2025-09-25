// lib/features/reports/data/models/inventory_valuation_report_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_valuation_report.dart';

part 'inventory_valuation_report_model.g.dart';

@JsonSerializable()
class InventoryValuationReportModel {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final String? warehouseId;
  final String? warehouseName;
  final DateTime asOfDate;
  final String valuationMethod;
  final double currentQuantity;
  final double unitCost;
  final double totalValue;
  final double averageCost;
  final DateTime? lastPurchaseDate;
  final double? lastPurchaseCost;
  final List<ValuationBatchDetailModel>? batches;

  const InventoryValuationReportModel({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    this.warehouseId,
    this.warehouseName,
    required this.asOfDate,
    required this.valuationMethod,
    required this.currentQuantity,
    required this.unitCost,
    required this.totalValue,
    required this.averageCost,
    this.lastPurchaseDate,
    this.lastPurchaseCost,
    this.batches,
  });

  factory InventoryValuationReportModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryValuationReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryValuationReportModelToJson(this);

  InventoryValuationReport toDomain() {
    return InventoryValuationReport(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      currentStock: currentQuantity.toInt(),
      averageCost: averageCost,
      fifoValue: totalValue,
      lifoValue: totalValue,
      weightedAverageValue: totalValue,
      currentMarketValue: totalValue,
      totalValue: totalValue,
      valuationDate: asOfDate,
      batchDetails: batches?.map((b) => b.toDomain()).toList() ?? [],
    );
  }
}


@JsonSerializable()
class ValuationBatchDetailModel {
  final String batchId;
  final String batchNumber;
  final double quantity;
  final double unitCost;
  final double totalValue;
  final DateTime purchaseDate;
  final DateTime? expirationDate;
  final String? supplierId;
  final String? supplierName;

  const ValuationBatchDetailModel({
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.purchaseDate,
    this.expirationDate,
    this.supplierId,
    this.supplierName,
  });

  factory ValuationBatchDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ValuationBatchDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ValuationBatchDetailModelToJson(this);

  InventoryValuationBatch toDomain() {
    return InventoryValuationBatch(
      batchId: batchId,
      batchNumber: batchNumber,
      quantity: quantity.toInt(),
      unitCost: unitCost,
      totalCost: totalValue,
      purchaseDate: purchaseDate,
      expiryDate: expirationDate,
      supplierId: supplierId,
      supplierName: supplierName,
    );
  }
}




