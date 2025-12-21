// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePurchaseOrderRequestModel _$CreatePurchaseOrderRequestModelFromJson(
        Map<String, dynamic> json) =>
    CreatePurchaseOrderRequestModel(
      supplierId: json['supplierId'] as String,
      warehouseId: json['warehouseId'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      currency: json['currency'] as String?,
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble(),
      shippingCost: (json['shippingCost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      items: (json['items'] as List<dynamic>)
          .map((e) => CreatePurchaseOrderItemRequestModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreatePurchaseOrderRequestModelToJson(
        CreatePurchaseOrderRequestModel instance) =>
    <String, dynamic>{
      'supplierId': instance.supplierId,
      'warehouseId': instance.warehouseId,
      'expectedDeliveryDate': instance.expectedDeliveryDate,
      'currency': instance.currency,
      'taxPercentage': instance.taxPercentage,
      'shippingCost': instance.shippingCost,
      'notes': instance.notes,
      'metadata': instance.metadata,
      'items': instance.items,
    };

CreatePurchaseOrderItemRequestModel
    _$CreatePurchaseOrderItemRequestModelFromJson(Map<String, dynamic> json) =>
        CreatePurchaseOrderItemRequestModel(
          productId: json['productId'] as String,
          lineNumber: (json['lineNumber'] as num).toInt(),
          quantity: (json['quantity'] as num).toInt(),
          unitCost: (json['unitCost'] as num).toDouble(),
          expectedDate: json['expectedDate'] as String?,
          notes: json['notes'] as String?,
          metadata: json['metadata'] as Map<String, dynamic>?,
        );

Map<String, dynamic> _$CreatePurchaseOrderItemRequestModelToJson(
        CreatePurchaseOrderItemRequestModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'lineNumber': instance.lineNumber,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'expectedDate': instance.expectedDate,
      'notes': instance.notes,
      'metadata': instance.metadata,
    };

UpdatePurchaseOrderRequestModel _$UpdatePurchaseOrderRequestModelFromJson(
        Map<String, dynamic> json) =>
    UpdatePurchaseOrderRequestModel(
      supplierId: json['supplierId'] as String?,
      warehouseId: json['warehouseId'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      status: json['status'] as String?,
      currency: json['currency'] as String?,
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble(),
      shippingCost: (json['shippingCost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => UpdatePurchaseOrderItemRequestModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdatePurchaseOrderRequestModelToJson(
        UpdatePurchaseOrderRequestModel instance) =>
    <String, dynamic>{
      'supplierId': instance.supplierId,
      'warehouseId': instance.warehouseId,
      'expectedDeliveryDate': instance.expectedDeliveryDate,
      'status': instance.status,
      'currency': instance.currency,
      'taxPercentage': instance.taxPercentage,
      'shippingCost': instance.shippingCost,
      'notes': instance.notes,
      'metadata': instance.metadata,
      'items': instance.items,
    };

UpdatePurchaseOrderItemRequestModel
    _$UpdatePurchaseOrderItemRequestModelFromJson(Map<String, dynamic> json) =>
        UpdatePurchaseOrderItemRequestModel(
          id: json['id'] as String?,
          productId: json['productId'] as String,
          quantity: (json['quantity'] as num).toInt(),
          receivedQuantity: (json['receivedQuantity'] as num?)?.toInt(),
          unitCost: (json['unitCost'] as num).toDouble(),
          discountPercentage: (json['discountPercentage'] as num).toDouble(),
          taxPercentage: (json['taxPercentage'] as num).toDouble(),
          notes: json['notes'] as String?,
        );

Map<String, dynamic> _$UpdatePurchaseOrderItemRequestModelToJson(
        UpdatePurchaseOrderItemRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'receivedQuantity': instance.receivedQuantity,
      'unitCost': instance.unitCost,
      'discountPercentage': instance.discountPercentage,
      'taxPercentage': instance.taxPercentage,
      'notes': instance.notes,
    };

ReceivePurchaseOrderRequestModel _$ReceivePurchaseOrderRequestModelFromJson(
        Map<String, dynamic> json) =>
    ReceivePurchaseOrderRequestModel(
      receivedItems: (json['receivedItems'] as List<dynamic>)
          .map((e) => ReceivePurchaseOrderItemRequestModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      receivedDate: json['receivedDate'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ReceivePurchaseOrderRequestModelToJson(
        ReceivePurchaseOrderRequestModel instance) =>
    <String, dynamic>{
      'receivedItems': instance.receivedItems,
      'receivedDate': instance.receivedDate,
      'notes': instance.notes,
    };

ReceivePurchaseOrderItemRequestModel
    _$ReceivePurchaseOrderItemRequestModelFromJson(Map<String, dynamic> json) =>
        ReceivePurchaseOrderItemRequestModel(
          purchaseOrderItemId: json['purchaseOrderItemId'] as String,
          receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
          actualUnitCost: (json['actualUnitCost'] as num?)?.toDouble(),
          supplierLotNumber: json['supplierLotNumber'] as String?,
          expirationDate: json['expirationDate'] as String?,
          notes: json['notes'] as String?,
        );

Map<String, dynamic> _$ReceivePurchaseOrderItemRequestModelToJson(
        ReceivePurchaseOrderItemRequestModel instance) =>
    <String, dynamic>{
      'purchaseOrderItemId': instance.purchaseOrderItemId,
      'receivedQuantity': instance.receivedQuantity,
      'actualUnitCost': instance.actualUnitCost,
      'supplierLotNumber': instance.supplierLotNumber,
      'expirationDate': instance.expirationDate,
      'notes': instance.notes,
    };
