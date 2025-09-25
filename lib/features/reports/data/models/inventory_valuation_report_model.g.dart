// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_valuation_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryValuationReportModel _$InventoryValuationReportModelFromJson(
        Map<String, dynamic> json) =>
    InventoryValuationReportModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      warehouseId: json['warehouseId'] as String?,
      warehouseName: json['warehouseName'] as String?,
      asOfDate: DateTime.parse(json['asOfDate'] as String),
      valuationMethod: json['valuationMethod'] as String,
      currentQuantity: (json['currentQuantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      lastPurchaseDate: json['lastPurchaseDate'] == null
          ? null
          : DateTime.parse(json['lastPurchaseDate'] as String),
      lastPurchaseCost: (json['lastPurchaseCost'] as num?)?.toDouble(),
      batches: (json['batches'] as List<dynamic>?)
          ?.map((e) =>
              ValuationBatchDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InventoryValuationReportModelToJson(
        InventoryValuationReportModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'productSku': instance.productSku,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'asOfDate': instance.asOfDate.toIso8601String(),
      'valuationMethod': instance.valuationMethod,
      'currentQuantity': instance.currentQuantity,
      'unitCost': instance.unitCost,
      'totalValue': instance.totalValue,
      'averageCost': instance.averageCost,
      'lastPurchaseDate': instance.lastPurchaseDate?.toIso8601String(),
      'lastPurchaseCost': instance.lastPurchaseCost,
      'batches': instance.batches,
    };

ValuationBatchDetailModel _$ValuationBatchDetailModelFromJson(
        Map<String, dynamic> json) =>
    ValuationBatchDetailModel(
      batchId: json['batchId'] as String,
      batchNumber: json['batchNumber'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
    );

Map<String, dynamic> _$ValuationBatchDetailModelToJson(
        ValuationBatchDetailModel instance) =>
    <String, dynamic>{
      'batchId': instance.batchId,
      'batchNumber': instance.batchNumber,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalValue': instance.totalValue,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
    };
