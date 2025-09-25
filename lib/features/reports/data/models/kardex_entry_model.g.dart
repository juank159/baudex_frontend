// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kardex_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KardexEntryModel _$KardexEntryModelFromJson(Map<String, dynamic> json) =>
    KardexEntryModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      date: DateTime.parse(json['date'] as String),
      movementType: json['movementType'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: (json['unitCost'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      balance: (json['balance'] as num).toInt(),
      referenceId: json['referenceId'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$KardexEntryModelToJson(KardexEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'date': instance.date.toIso8601String(),
      'movementType': instance.movementType,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalCost': instance.totalCost,
      'balance': instance.balance,
      'referenceId': instance.referenceId,
      'notes': instance.notes,
    };
