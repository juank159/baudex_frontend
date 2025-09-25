// lib/features/reports/data/models/inventory_valuation_variance_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_valuation_report.dart';

part 'inventory_valuation_variance_model.g.dart';

@JsonSerializable()
class InventoryValuationVarianceModel {
  final String productId;
  final String productName;
  final String? productSku;
  final String categoryId;
  final String categoryName;
  final String warehouseId;
  final String warehouseName;
  final double bookValue;
  final double marketValue;
  final double varianceAmount;
  final double variancePercentage;
  final String varianceType;
  final int currentQuantity;
  final double unitBookValue;
  final double unitMarketValue;
  final DateTime lastCostUpdate;
  final DateTime lastPriceUpdate;
  final DateTime asOfDate;
  final String? notes;

  const InventoryValuationVarianceModel({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.categoryId,
    required this.categoryName,
    required this.warehouseId,
    required this.warehouseName,
    required this.bookValue,
    required this.marketValue,
    required this.varianceAmount,
    required this.variancePercentage,
    required this.varianceType,
    required this.currentQuantity,
    required this.unitBookValue,
    required this.unitMarketValue,
    required this.lastCostUpdate,
    required this.lastPriceUpdate,
    required this.asOfDate,
    this.notes,
  });

  factory InventoryValuationVarianceModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryValuationVarianceModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryValuationVarianceModelToJson(this);

  InventoryValuationVariance toDomain() {
    return InventoryValuationVariance(
      productId: productId,
      productName: productName,
      productSku: productSku ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      bookValue: bookValue,
      marketValue: marketValue,
      variance: varianceAmount,
      variancePercentage: variancePercentage,
      varianceType: varianceType,
      reason: notes ?? 'Variación en valuación',
      analysisDate: asOfDate,
      recommendedAdjustment: varianceAmount,
    );
  }
}