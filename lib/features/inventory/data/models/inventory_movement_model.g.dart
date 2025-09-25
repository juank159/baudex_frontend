// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_movement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryMovementModel _$InventoryMovementModelFromJson(
        Map<String, dynamic> json) =>
    InventoryMovementModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String?,
      productSku: json['productSku'] as String?,
      typeString: json['type'] as String,
      statusString: json['status'] as String,
      reasonString: json['reasonString'] as String?,
      quantity: InventoryMovementModel._convertToString(json['quantity']),
      unitCost: InventoryMovementModel._convertToString(json['unitCost']),
      totalCost: InventoryMovementModel._convertToString(json['totalCost']),
      unitPrice:
          InventoryMovementModel._convertToStringNullable(json['unitPrice']),
      totalPrice:
          InventoryMovementModel._convertToStringNullable(json['totalPrice']),
      stockAfter:
          InventoryMovementModel._convertToStringNullable(json['stockAfter']),
      stockValueAfter: InventoryMovementModel._convertToStringNullable(
          json['stockValueAfter']),
      lotNumber: json['lotNumber'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      warehouseId: json['warehouseId'] as String?,
      warehouseName: json['warehouseName'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      createdById: json['createdById'] as String?,
      movementNumber: json['movementNumber'] as String,
      movementDate: DateTime.parse(json['movementDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      organizationId: json['organizationId'] as String,
      metadata: InventoryMovementModel._metadataFromJson(json['metadata']),
    );

Map<String, dynamic> _$InventoryMovementModelToJson(
        InventoryMovementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'productSku': instance.productSku,
      'type': instance.typeString,
      'status': instance.statusString,
      'reasonString': instance.reasonString,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalCost': instance.totalCost,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
      'stockAfter': instance.stockAfter,
      'stockValueAfter': instance.stockValueAfter,
      'lotNumber': instance.lotNumber,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'referenceId': instance.referenceId,
      'referenceType': instance.referenceType,
      'referenceNumber': instance.referenceNumber,
      'notes': instance.notes,
      'userId': instance.userId,
      'userName': instance.userName,
      'createdById': instance.createdById,
      'movementNumber': instance.movementNumber,
      'movementDate': instance.movementDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'organizationId': instance.organizationId,
      'metadata': instance.metadata,
    };

CreateInventoryMovementRequest _$CreateInventoryMovementRequestFromJson(
        Map<String, dynamic> json) =>
    CreateInventoryMovementRequest(
      productId: json['productId'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: (json['unitCost'] as num).toDouble(),
      lotNumber: json['lotNumber'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      warehouseId: json['warehouseId'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      notes: json['notes'] as String?,
      movementDate: json['movementDate'] == null
          ? null
          : DateTime.parse(json['movementDate'] as String),
    );

Map<String, dynamic> _$CreateInventoryMovementRequestToJson(
        CreateInventoryMovementRequest instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'type': instance.type,
      'reason': instance.reason,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'lotNumber': instance.lotNumber,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'warehouseId': instance.warehouseId,
      'referenceId': instance.referenceId,
      'referenceType': instance.referenceType,
      'notes': instance.notes,
      'movementDate': instance.movementDate?.toIso8601String(),
    };

UpdateInventoryMovementRequest _$UpdateInventoryMovementRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateInventoryMovementRequest(
      type: json['type'] as String?,
      reason: json['reason'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      lotNumber: json['lotNumber'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      warehouseId: json['warehouseId'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      notes: json['notes'] as String?,
      movementDate: json['movementDate'] == null
          ? null
          : DateTime.parse(json['movementDate'] as String),
    );

Map<String, dynamic> _$UpdateInventoryMovementRequestToJson(
        UpdateInventoryMovementRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'reason': instance.reason,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'lotNumber': instance.lotNumber,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'warehouseId': instance.warehouseId,
      'referenceId': instance.referenceId,
      'referenceType': instance.referenceType,
      'notes': instance.notes,
      'movementDate': instance.movementDate?.toIso8601String(),
    };
