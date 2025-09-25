// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplierStatsModel _$SupplierStatsModelFromJson(Map<String, dynamic> json) =>
    SupplierStatsModel(
      totalSuppliers: (json['totalSuppliers'] as num).toInt(),
      activeSuppliers: (json['activeSuppliers'] as num).toInt(),
      inactiveSuppliers: (json['inactiveSuppliers'] as num).toInt(),
      totalCreditLimit: (json['totalCreditLimit'] as num).toDouble(),
      averageCreditLimit: (json['averageCreditLimit'] as num).toDouble(),
      averagePaymentTerms: (json['averagePaymentTerms'] as num).toDouble(),
      suppliersWithDiscount: (json['suppliersWithDiscount'] as num).toInt(),
      suppliersWithCredit: (json['suppliersWithCredit'] as num).toInt(),
      currencyDistribution:
          Map<String, int>.from(json['currencyDistribution'] as Map),
      topSuppliersByCredit: (json['topSuppliersByCredit'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      totalPurchasesAmount: (json['totalPurchasesAmount'] as num).toDouble(),
      totalPurchaseOrders: (json['totalPurchaseOrders'] as num).toInt(),
    );

Map<String, dynamic> _$SupplierStatsModelToJson(SupplierStatsModel instance) =>
    <String, dynamic>{
      'totalSuppliers': instance.totalSuppliers,
      'activeSuppliers': instance.activeSuppliers,
      'inactiveSuppliers': instance.inactiveSuppliers,
      'totalCreditLimit': instance.totalCreditLimit,
      'averageCreditLimit': instance.averageCreditLimit,
      'averagePaymentTerms': instance.averagePaymentTerms,
      'suppliersWithDiscount': instance.suppliersWithDiscount,
      'suppliersWithCredit': instance.suppliersWithCredit,
      'currencyDistribution': instance.currencyDistribution,
      'topSuppliersByCredit': instance.topSuppliersByCredit,
      'totalPurchasesAmount': instance.totalPurchasesAmount,
      'totalPurchaseOrders': instance.totalPurchaseOrders,
    };

SupplierStatsResponseModel _$SupplierStatsResponseModelFromJson(
        Map<String, dynamic> json) =>
    SupplierStatsResponseModel(
      success: json['success'] as bool,
      data: SupplierStatsModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SupplierStatsResponseModelToJson(
        SupplierStatsResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
    };
