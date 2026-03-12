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

  factory SupplierStatsModel.fromJson(Map<String, dynamic> json) {
    // Manejar formato del API real (total/active/inactive/blocked/topSuppliers)
    // y formato local cacheado (totalSuppliers/activeSuppliers/etc.)
    return SupplierStatsModel(
      totalSuppliers: ((json['totalSuppliers'] ?? json['total'] ?? 0) as num).toInt(),
      activeSuppliers: ((json['activeSuppliers'] ?? json['active'] ?? 0) as num).toInt(),
      inactiveSuppliers: ((json['inactiveSuppliers'] ?? json['inactive'] ?? 0) as num).toInt(),
      totalCreditLimit: ((json['totalCreditLimit'] ?? 0) as num).toDouble(),
      averageCreditLimit: ((json['averageCreditLimit'] ?? 0) as num).toDouble(),
      averagePaymentTerms: ((json['averagePaymentTerms'] ?? 0) as num).toDouble(),
      suppliersWithDiscount: ((json['suppliersWithDiscount'] ?? 0) as num).toInt(),
      suppliersWithCredit: ((json['suppliersWithCredit'] ?? 0) as num).toInt(),
      currencyDistribution: json['currencyDistribution'] != null
          ? Map<String, int>.from(json['currencyDistribution'] as Map)
          : const {},
      topSuppliersByCredit: json['topSuppliersByCredit'] != null
          ? (json['topSuppliersByCredit'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : (json['topSuppliers'] as List<dynamic>?)
              ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ?? const [],
      totalPurchasesAmount: ((json['totalPurchasesAmount'] ?? 0) as num).toDouble(),
      totalPurchaseOrders: ((json['totalPurchaseOrders'] ?? 0) as num).toInt(),
    );
  }

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