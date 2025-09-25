// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseOrderModel _$PurchaseOrderModelFromJson(Map<String, dynamic> json) =>
    PurchaseOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String?,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      status: json['status'] as String?,
      priority: json['priority'] as String?,
      orderDate: json['orderDate'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      deliveredDate: json['deliveredDate'] as String?,
      actualDeliveryDate: json['actualDeliveryDate'] as String?,
      supplierReference: json['supplierReference'] as String?,
      terms: json['terms'] as String?,
      taxPercentage: json['taxPercentage'] as String?,
      discountPercentage: json['discountPercentage'] as String?,
      shippingCost: json['shippingCost'] as String?,
      currency: json['currency'] as String?,
      subtotal: PurchaseOrderModel._parseDouble(json['subtotal']),
      taxAmount: PurchaseOrderModel._parseDouble(json['taxAmount']),
      discountAmount: PurchaseOrderModel._parseDouble(json['discountAmount']),
      totalAmount: PurchaseOrderModel._parseDouble(json['total']),
      items: (json['items'] as List<dynamic>?)
          ?.map(
              (e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      internalNotes: json['internalNotes'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      supplier: json['supplier'] as Map<String, dynamic>?,
      batches: json['batches'] as List<dynamic>?,
      createdBy: PurchaseOrderModel._parseCreatedBy(json['createdBy']),
      approvedBy: PurchaseOrderModel._parseApprovedBy(json['approvedBy']),
      approvedAt: json['approvedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$PurchaseOrderModelToJson(PurchaseOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'status': instance.status,
      'priority': instance.priority,
      'orderDate': instance.orderDate,
      'expectedDeliveryDate': instance.expectedDeliveryDate,
      'deliveredDate': instance.deliveredDate,
      'actualDeliveryDate': instance.actualDeliveryDate,
      'supplierReference': instance.supplierReference,
      'terms': instance.terms,
      'taxPercentage': instance.taxPercentage,
      'discountPercentage': instance.discountPercentage,
      'shippingCost': instance.shippingCost,
      'currency': instance.currency,
      'subtotal': instance.subtotal,
      'taxAmount': instance.taxAmount,
      'discountAmount': instance.discountAmount,
      'total': instance.totalAmount,
      'items': instance.items,
      'notes': instance.notes,
      'internalNotes': instance.internalNotes,
      'deliveryAddress': instance.deliveryAddress,
      'contactPerson': instance.contactPerson,
      'contactPhone': instance.contactPhone,
      'contactEmail': instance.contactEmail,
      'attachments': instance.attachments,
      'metadata': instance.metadata,
      'supplier': instance.supplier,
      'batches': instance.batches,
      'createdBy': instance.createdBy,
      'approvedBy': instance.approvedBy,
      'approvedAt': instance.approvedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

PurchaseOrderItemModel _$PurchaseOrderItemModelFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderItemModel(
      id: json['id'] as String?,
      productId: json['productId'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
      lineNumber: (json['lineNumber'] as num?)?.toInt(),
      quantity: json['quantity'] as String?,
      unitCost: json['unitCost'] as String?,
      totalCost: _parseStringFromDynamic(json['totalCost']),
      receivedQuantity: json['receivedQuantity'] as String?,
      damagedQuantity: json['damagedQuantity'] as String?,
      missingQuantity: json['missingQuantity'] as String?,
      pendingQuantity: json['pendingQuantity'] as String?,
      expectedDate: json['expectedDate'] as String?,
      lastReceivedDate: json['lastReceivedDate'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      organizationId: json['organizationId'] as String?,
      purchaseOrderId: json['purchaseOrderId'] as String?,
      product: json['product'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PurchaseOrderItemModelToJson(
        PurchaseOrderItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'deletedAt': instance.deletedAt,
      'lineNumber': instance.lineNumber,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalCost': instance.totalCost,
      'receivedQuantity': instance.receivedQuantity,
      'damagedQuantity': instance.damagedQuantity,
      'missingQuantity': instance.missingQuantity,
      'pendingQuantity': instance.pendingQuantity,
      'expectedDate': instance.expectedDate,
      'lastReceivedDate': instance.lastReceivedDate,
      'metadata': instance.metadata,
      'organizationId': instance.organizationId,
      'purchaseOrderId': instance.purchaseOrderId,
      'product': instance.product,
    };

PurchaseOrderStatsModel _$PurchaseOrderStatsModelFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderStatsModel(
      total: (json['total'] as num).toInt(),
      byStatus: Map<String, int>.from(json['byStatus'] as Map),
      totalValue: json['totalValue'] as num,
      averageOrderValue: json['averageOrderValue'] as num?,
    );

Map<String, dynamic> _$PurchaseOrderStatsModelToJson(
        PurchaseOrderStatsModel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'byStatus': instance.byStatus,
      'totalValue': instance.totalValue,
      'averageOrderValue': instance.averageOrderValue,
    };
