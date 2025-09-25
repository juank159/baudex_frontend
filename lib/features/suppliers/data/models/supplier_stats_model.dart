// lib/features/suppliers/data/models/supplier_stats_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/supplier.dart';

part 'supplier_stats_model.g.dart';

@JsonSerializable()
class SupplierStatsModel extends SupplierStats {
  const SupplierStatsModel({
    required super.totalSuppliers,
    required super.activeSuppliers,
    required super.inactiveSuppliers,
    required super.totalCreditLimit,
    required super.averageCreditLimit,
    required super.averagePaymentTerms,
    required super.suppliersWithDiscount,
    required super.suppliersWithCredit,
    required super.currencyDistribution,
    required super.topSuppliersByCredit,
    required super.totalPurchasesAmount,
    required super.totalPurchaseOrders,
  });

  factory SupplierStatsModel.fromJson(Map<String, dynamic> json) =>
      _$SupplierStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SupplierStatsModelToJson(this);

  // Convertir de entidad a model y viceversa
  factory SupplierStatsModel.fromEntity(SupplierStats stats) {
    return SupplierStatsModel(
      totalSuppliers: stats.totalSuppliers,
      activeSuppliers: stats.activeSuppliers,
      inactiveSuppliers: stats.inactiveSuppliers,
      totalCreditLimit: stats.totalCreditLimit,
      averageCreditLimit: stats.averageCreditLimit,
      averagePaymentTerms: stats.averagePaymentTerms,
      suppliersWithDiscount: stats.suppliersWithDiscount,
      suppliersWithCredit: stats.suppliersWithCredit,
      currencyDistribution: stats.currencyDistribution,
      topSuppliersByCredit: stats.topSuppliersByCredit,
      totalPurchasesAmount: stats.totalPurchasesAmount,
      totalPurchaseOrders: stats.totalPurchaseOrders,
    );
  }

  SupplierStats toEntity() {
    return SupplierStats(
      totalSuppliers: totalSuppliers,
      activeSuppliers: activeSuppliers,
      inactiveSuppliers: inactiveSuppliers,
      totalCreditLimit: totalCreditLimit,
      averageCreditLimit: averageCreditLimit,
      averagePaymentTerms: averagePaymentTerms,
      suppliersWithDiscount: suppliersWithDiscount,
      suppliersWithCredit: suppliersWithCredit,
      currencyDistribution: currencyDistribution,
      topSuppliersByCredit: topSuppliersByCredit,
      totalPurchasesAmount: totalPurchasesAmount,
      totalPurchaseOrders: totalPurchaseOrders,
    );
  }
}

@JsonSerializable()
class SupplierStatsResponseModel {
  final bool success;
  final SupplierStatsModel data;
  final String? message;
  final DateTime timestamp;

  const SupplierStatsResponseModel({
    required this.success,
    required this.data,
    this.message,
    required this.timestamp,
  });

  factory SupplierStatsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SupplierStatsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SupplierStatsResponseModelToJson(this);
}