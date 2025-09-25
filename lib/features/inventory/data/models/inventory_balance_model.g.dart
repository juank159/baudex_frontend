// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryBalanceModel _$InventoryBalanceModelFromJson(
        Map<String, dynamic> json) =>
    InventoryBalanceModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      categoryName: json['categoryName'] as String,
      totalQuantity: (json['totalQuantity'] as num).toInt(),
      minStock: (json['minStock'] as num).toInt(),
      averageCost: (json['averageCost'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      isLowStock: json['isLowStock'] as bool,
      isOutOfStock: json['isOutOfStock'] as bool,
      warehouseId: json['warehouseId'] as String?,
    );

Map<String, dynamic> _$InventoryBalanceModelToJson(
        InventoryBalanceModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'productSku': instance.productSku,
      'categoryName': instance.categoryName,
      'totalQuantity': instance.totalQuantity,
      'minStock': instance.minStock,
      'averageCost': instance.averageCost,
      'totalValue': instance.totalValue,
      'isLowStock': instance.isLowStock,
      'isOutOfStock': instance.isOutOfStock,
      'warehouseId': instance.warehouseId,
    };

InventoryLotModel _$InventoryLotModelFromJson(Map<String, dynamic> json) =>
    InventoryLotModel(
      lotNumber: json['lotNumber'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: (json['unitCost'] as num).toDouble(),
      entryDate: DateTime.parse(json['entryDate'] as String),
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
    );

Map<String, dynamic> _$InventoryLotModelToJson(InventoryLotModel instance) =>
    <String, dynamic>{
      'lotNumber': instance.lotNumber,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'entryDate': instance.entryDate.toIso8601String(),
      'expiryDate': instance.expiryDate?.toIso8601String(),
    };

FifoConsumptionModel _$FifoConsumptionModelFromJson(
        Map<String, dynamic> json) =>
    FifoConsumptionModel(
      lot: InventoryLotModel.fromJson(json['lot'] as Map<String, dynamic>),
      quantityConsumed: (json['quantityConsumed'] as num).toInt(),
      unitCost: (json['unitCost'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
    );

Map<String, dynamic> _$FifoConsumptionModelToJson(
        FifoConsumptionModel instance) =>
    <String, dynamic>{
      'lot': instance.lot,
      'quantityConsumed': instance.quantityConsumed,
      'unitCost': instance.unitCost,
      'totalCost': instance.totalCost,
    };
