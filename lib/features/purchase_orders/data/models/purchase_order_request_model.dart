// lib/features/purchase_orders/data/models/purchase_order_request_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/repositories/purchase_order_repository.dart';

part 'purchase_order_request_model.g.dart';

@JsonSerializable()
class CreatePurchaseOrderRequestModel {
  final String supplierId;
  final String? expectedDeliveryDate;
  final String? currency;
  final double? taxPercentage;
  final double? discountPercentage;
  final double? discountAmount;
  final double? shippingCost;
  final String? notes;
  final String? terms;
  final String? supplierReference;
  final Map<String, dynamic>? metadata;
  final List<CreatePurchaseOrderItemRequestModel> items;

  const CreatePurchaseOrderRequestModel({
    required this.supplierId,
    this.expectedDeliveryDate,
    this.currency,
    this.taxPercentage,
    this.discountPercentage,
    this.discountAmount,
    this.shippingCost,
    this.notes,
    this.terms,
    this.supplierReference,
    this.metadata,
    required this.items,
  });

  factory CreatePurchaseOrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreatePurchaseOrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$CreatePurchaseOrderRequestModelToJson(this);
    json['items'] = items.map((item) => item.toJson()).toList();
    return json;
  }

  factory CreatePurchaseOrderRequestModel.fromParams(CreatePurchaseOrderParams params) {
    return CreatePurchaseOrderRequestModel(
      supplierId: params.supplierId,
      expectedDeliveryDate: params.expectedDeliveryDate.toIso8601String(),
      currency: params.currency,
      items: params.items
          .map((item) => CreatePurchaseOrderItemRequestModel.fromParams(item))
          .toList(),
      notes: params.notes,
      metadata: {
        'priority': params.priority.name,
        'orderDate': params.orderDate.toIso8601String(),
        'internalNotes': params.internalNotes,
        'deliveryAddress': params.deliveryAddress,
        'contactPerson': params.contactPerson,
        'contactPhone': params.contactPhone,
        'contactEmail': params.contactEmail,
        'attachments': params.attachments,
      },
    );
  }
}

@JsonSerializable()
class CreatePurchaseOrderItemRequestModel {
  final String productId;
  final int lineNumber;
  final int quantity;
  final double unitCost;
  final String? expectedDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const CreatePurchaseOrderItemRequestModel({
    required this.productId,
    required this.lineNumber,
    required this.quantity,
    required this.unitCost,
    this.expectedDate,
    this.notes,
    this.metadata,
  });

  factory CreatePurchaseOrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreatePurchaseOrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePurchaseOrderItemRequestModelToJson(this);

  factory CreatePurchaseOrderItemRequestModel.fromParams(CreatePurchaseOrderItemParams params) {
    return CreatePurchaseOrderItemRequestModel(
      productId: params.productId,
      lineNumber: params.lineNumber ?? 1,
      quantity: params.quantity,
      unitCost: params.unitPrice,
      notes: params.notes,
      metadata: {
        'discountPercentage': params.discountPercentage,
        'taxPercentage': params.taxPercentage,
      },
    );
  }
}

@JsonSerializable()
class UpdatePurchaseOrderRequestModel {
  // Solo campos permitidos por el backend DTO
  final String? supplierId;
  final String? expectedDeliveryDate;
  final String? status;
  final String? currency;
  final double? taxPercentage;
  final double? discountPercentage;
  final double? discountAmount;
  final double? shippingCost;
  final String? notes;
  final String? terms;
  final String? supplierReference;
  final Map<String, dynamic>? metadata;
  final List<UpdatePurchaseOrderItemRequestModel>? items;

  const UpdatePurchaseOrderRequestModel({
    this.supplierId,
    this.expectedDeliveryDate,
    this.status,
    this.currency,
    this.taxPercentage,
    this.discountPercentage,
    this.discountAmount,
    this.shippingCost,
    this.notes,
    this.terms,
    this.supplierReference,
    this.metadata,
    this.items,
  });

  factory UpdatePurchaseOrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdatePurchaseOrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$UpdatePurchaseOrderRequestModelToJson(this);
    // Serializar items manualmente si existen
    if (items != null) {
      json['items'] = items!.map((item) => item.toJson()).toList();
    }
    // Remover campos null para evitar errores de validación
    json.removeWhere((key, value) => value == null);
    return json;
  }

  factory UpdatePurchaseOrderRequestModel.fromParams(UpdatePurchaseOrderParams params) {
    // Enviar campos que el backend DTO permite directamente
    return UpdatePurchaseOrderRequestModel(
      supplierId: params.supplierId, // Ahora permitido por el backend
      expectedDeliveryDate: params.expectedDeliveryDate?.toIso8601String(),
      status: params.status?.name,
      currency: params.currency,
      notes: params.notes,
      // Enviar items para actualizar productos
      items: params.items
          ?.map((item) => UpdatePurchaseOrderItemRequestModel.fromParams(item))
          .toList(),
      // Campos adicionales en metadata si el backend los permite
      metadata: {
        if (params.priority != null) 'priority': params.priority!.name,
        if (params.orderDate != null) 'orderDate': params.orderDate!.toIso8601String(),
        if (params.deliveredDate != null) 'deliveredDate': params.deliveredDate!.toIso8601String(),
        if (params.internalNotes != null) 'internalNotes': params.internalNotes,
        if (params.deliveryAddress != null) 'deliveryAddress': params.deliveryAddress,
        if (params.contactPerson != null) 'contactPerson': params.contactPerson,
        if (params.contactPhone != null) 'contactPhone': params.contactPhone,
        if (params.contactEmail != null) 'contactEmail': params.contactEmail,
        if (params.attachments != null) 'attachments': params.attachments,
      },
    );
  }
}

@JsonSerializable()
class UpdatePurchaseOrderItemRequestModel {
  final String? id;
  final String productId; // camelCase como espera el backend
  final int quantity;
  final int? receivedQuantity; // camelCase como espera el backend
  final double unitCost; // cambiar de unitPrice a unitCost
  final double discountPercentage; // camelCase como espera el backend
  final double taxPercentage; // camelCase como espera el backend
  final String? notes;

  const UpdatePurchaseOrderItemRequestModel({
    this.id,
    required this.productId,
    required this.quantity,
    this.receivedQuantity,
    required this.unitCost,
    required this.discountPercentage,
    required this.taxPercentage,
    this.notes,
  });

  factory UpdatePurchaseOrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdatePurchaseOrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePurchaseOrderItemRequestModelToJson(this);

  factory UpdatePurchaseOrderItemRequestModel.fromParams(UpdatePurchaseOrderItemParams params) {
    return UpdatePurchaseOrderItemRequestModel(
      id: params.id,
      productId: params.productId,
      quantity: params.quantity,
      receivedQuantity: params.receivedQuantity,
      unitCost: params.unitPrice, // mapear unitPrice a unitCost
      discountPercentage: params.discountPercentage,
      taxPercentage: params.taxPercentage,
      notes: params.notes,
    );
  }
}

@JsonSerializable()
class ReceivePurchaseOrderRequestModel {
  @JsonKey(name: 'receivedItems')
  final List<ReceivePurchaseOrderItemRequestModel> receivedItems;
  final String? receivedDate;
  final String? notes;

  const ReceivePurchaseOrderRequestModel({
    required this.receivedItems,
    this.receivedDate,
    this.notes,
  });

  factory ReceivePurchaseOrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ReceivePurchaseOrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReceivePurchaseOrderRequestModelToJson(this);

  factory ReceivePurchaseOrderRequestModel.fromParams(ReceivePurchaseOrderParams params) {
    return ReceivePurchaseOrderRequestModel(
      receivedItems: params.items
          .map((item) => ReceivePurchaseOrderItemRequestModel.fromParams(item))
          .toList(),
      receivedDate: params.receivedDate?.toIso8601String(),
      notes: params.notes,
    );
  }
}

@JsonSerializable()
class ReceivePurchaseOrderItemRequestModel {
  final String purchaseOrderItemId;
  final double receivedQuantity;
  final double? actualUnitCost;
  final String? supplierLotNumber;
  final String? expirationDate;
  final String? notes;

  const ReceivePurchaseOrderItemRequestModel({
    required this.purchaseOrderItemId,
    required this.receivedQuantity,
    this.actualUnitCost,
    this.supplierLotNumber,
    this.expirationDate,
    this.notes,
  });

  factory ReceivePurchaseOrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ReceivePurchaseOrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReceivePurchaseOrderItemRequestModelToJson(this);

  factory ReceivePurchaseOrderItemRequestModel.fromParams(ReceivePurchaseOrderItemParams params) {
    return ReceivePurchaseOrderItemRequestModel(
      purchaseOrderItemId: params.itemId,
      receivedQuantity: params.receivedQuantity.toDouble(),
      actualUnitCost: params.actualUnitCost,
      supplierLotNumber: params.supplierLotNumber,
      expirationDate: params.expirationDate,
      notes: params.notes,
    );
  }
}