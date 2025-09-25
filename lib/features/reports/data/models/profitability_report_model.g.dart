// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profitability_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfitabilityReportModel _$ProfitabilityReportModelFromJson(
        Map<String, dynamic> json) =>
    ProfitabilityReportModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      warehouseId: json['warehouseId'] as String?,
      warehouseName: json['warehouseName'] as String?,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      grossProfit: (json['grossProfit'] as num).toDouble(),
      grossMarginPercentage: (json['grossMarginPercentage'] as num).toDouble(),
      unitsSold: (json['unitsSold'] as num).toInt(),
      averageSellingPrice: (json['averageSellingPrice'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      rotationRate: (json['rotationRate'] as num).toDouble(),
      details: (json['details'] as List<dynamic>?)
          ?.map((e) =>
              ProfitabilityDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProfitabilityReportModelToJson(
        ProfitabilityReportModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'productSku': instance.productSku,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'totalRevenue': instance.totalRevenue,
      'totalCost': instance.totalCost,
      'grossProfit': instance.grossProfit,
      'grossMarginPercentage': instance.grossMarginPercentage,
      'unitsSold': instance.unitsSold,
      'averageSellingPrice': instance.averageSellingPrice,
      'averageCost': instance.averageCost,
      'rotationRate': instance.rotationRate,
      'details': instance.details,
    };

ProfitabilityDetailModel _$ProfitabilityDetailModelFromJson(
        Map<String, dynamic> json) =>
    ProfitabilityDetailModel(
      date: DateTime.parse(json['date'] as String),
      invoiceId: json['invoiceId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      lineRevenue: (json['lineRevenue'] as num).toDouble(),
      lineCost: (json['lineCost'] as num).toDouble(),
      lineProfit: (json['lineProfit'] as num).toDouble(),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
    );

Map<String, dynamic> _$ProfitabilityDetailModelToJson(
        ProfitabilityDetailModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'invoiceId': instance.invoiceId,
      'invoiceNumber': instance.invoiceNumber,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'unitCost': instance.unitCost,
      'lineRevenue': instance.lineRevenue,
      'lineCost': instance.lineCost,
      'lineProfit': instance.lineProfit,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
    };
