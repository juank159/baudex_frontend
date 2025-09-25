// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kardex_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KardexReportModel _$KardexReportModelFromJson(Map<String, dynamic> json) =>
    KardexReportModel(
      product:
          KardexProductModel.fromJson(json['product'] as Map<String, dynamic>),
      period:
          KardexPeriodModel.fromJson(json['period'] as Map<String, dynamic>),
      initialBalance: KardexBalanceModel.fromJson(
          json['initialBalance'] as Map<String, dynamic>),
      movements: (json['movements'] as List<dynamic>)
          .map((e) => KardexMovementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      finalBalance: KardexBalanceModel.fromJson(
          json['finalBalance'] as Map<String, dynamic>),
      summary:
          KardexSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      batchDetails: (json['batchDetails'] as List<dynamic>?)
          ?.map(
              (e) => KardexBatchDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KardexReportModelToJson(KardexReportModel instance) =>
    <String, dynamic>{
      'product': instance.product,
      'period': instance.period,
      'initialBalance': instance.initialBalance,
      'movements': instance.movements,
      'finalBalance': instance.finalBalance,
      'summary': instance.summary,
      'batchDetails': instance.batchDetails,
    };

KardexProductModel _$KardexProductModelFromJson(Map<String, dynamic> json) =>
    KardexProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      categoryName: json['categoryName'] as String?,
    );

Map<String, dynamic> _$KardexProductModelToJson(KardexProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'categoryName': instance.categoryName,
    };

KardexPeriodModel _$KardexPeriodModelFromJson(Map<String, dynamic> json) =>
    KardexPeriodModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$KardexPeriodModelToJson(KardexPeriodModel instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };

KardexBalanceModel _$KardexBalanceModelFromJson(Map<String, dynamic> json) =>
    KardexBalanceModel(
      quantity: _parseDouble(json['quantity']),
      value: _parseDouble(json['value']),
      averageCost: _parseDouble(json['averageCost']),
    );

Map<String, dynamic> _$KardexBalanceModelToJson(KardexBalanceModel instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'value': instance.value,
      'averageCost': instance.averageCost,
    };

KardexMovementModel _$KardexMovementModelFromJson(Map<String, dynamic> json) =>
    KardexMovementModel(
      date: DateTime.parse(json['date'] as String),
      movementNumber: json['movementNumber'] as String,
      movementType: json['movementType'] as String,
      referenceType: json['referenceType'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      description: json['description'] as String,
      entryQuantity: _parseDouble(json['entryQuantity']),
      exitQuantity: _parseDouble(json['exitQuantity']),
      balance: _parseDouble(json['balance']),
      unitCost: _parseDouble(json['unitCost']),
      entryCost: _parseDouble(json['entryCost']),
      exitCost: _parseDouble(json['exitCost']),
      balanceValue: _parseDouble(json['balanceValue']),
      unitPrice: _parseDoubleNullable(json['unitPrice']),
      totalPrice: _parseDoubleNullable(json['totalPrice']),
      createdBy: json['createdBy'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$KardexMovementModelToJson(
        KardexMovementModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'movementNumber': instance.movementNumber,
      'movementType': instance.movementType,
      'referenceType': instance.referenceType,
      'referenceNumber': instance.referenceNumber,
      'description': instance.description,
      'entryQuantity': instance.entryQuantity,
      'exitQuantity': instance.exitQuantity,
      'balance': instance.balance,
      'unitCost': instance.unitCost,
      'entryCost': instance.entryCost,
      'exitCost': instance.exitCost,
      'balanceValue': instance.balanceValue,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
      'createdBy': instance.createdBy,
      'notes': instance.notes,
    };

KardexSummaryModel _$KardexSummaryModelFromJson(Map<String, dynamic> json) =>
    KardexSummaryModel(
      totalEntries: (json['totalEntries'] as num).toInt(),
      totalExits: (json['totalExits'] as num).toInt(),
      totalPurchases: _parseDouble(json['totalPurchases']),
      totalSales: _parseDouble(json['totalSales']),
      averageUnitCost: _parseDouble(json['averageUnitCost']),
      totalValue: _parseDouble(json['totalValue']),
    );

Map<String, dynamic> _$KardexSummaryModelToJson(KardexSummaryModel instance) =>
    <String, dynamic>{
      'totalEntries': instance.totalEntries,
      'totalExits': instance.totalExits,
      'totalPurchases': instance.totalPurchases,
      'totalSales': instance.totalSales,
      'averageUnitCost': instance.averageUnitCost,
      'totalValue': instance.totalValue,
    };

KardexBatchDetailModel _$KardexBatchDetailModelFromJson(
        Map<String, dynamic> json) =>
    KardexBatchDetailModel(
      batchNumber: json['batchNumber'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      quantity: _parseDouble(json['quantity']),
      unitCost: _parseDouble(json['unitCost']),
      totalValue: _parseDouble(json['totalValue']),
      daysInInventory: (json['daysInInventory'] as num).toInt(),
    );

Map<String, dynamic> _$KardexBatchDetailModelToJson(
        KardexBatchDetailModel instance) =>
    <String, dynamic>{
      'batchNumber': instance.batchNumber,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalValue': instance.totalValue,
      'daysInInventory': instance.daysInInventory,
    };
