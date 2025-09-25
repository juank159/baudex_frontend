// lib/features/inventory/data/models/inventory_movement_model.dart
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_movement.dart';

part 'inventory_movement_model.g.dart';

@JsonSerializable()
class InventoryMovementModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productSku;
  @JsonKey(name: 'type')
  final String typeString;
  @JsonKey(name: 'status')
  final String statusString;
  final String? reasonString;
  @JsonKey(fromJson: _convertToString)
  final String quantity; // El backend puede devolver string o int
  @JsonKey(fromJson: _convertToString)
  final String unitCost; // El backend devuelve como string: "12500.00"
  @JsonKey(fromJson: _convertToString)
  final String totalCost; // El backend devuelve como string: "12500.00"
  @JsonKey(fromJson: _convertToStringNullable)
  final String? unitPrice; // Campo del backend
  @JsonKey(fromJson: _convertToStringNullable)
  final String? totalPrice; // Campo del backend
  @JsonKey(fromJson: _convertToStringNullable)
  final String? stockAfter; // El backend puede devolver string o int
  @JsonKey(fromJson: _convertToStringNullable)
  final String? stockValueAfter; // El backend puede devolver string o int
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? warehouseName;
  final String? referenceId;
  final String? referenceType;
  final String? referenceNumber; // Campo del backend
  final String? notes;
  final String? userId;
  final String? userName;
  @JsonKey(name: 'createdById')
  final String? createdById; // Campo del backend
  final String movementNumber; // Campo del backend
  final DateTime movementDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String organizationId; // Campo del backend
  @JsonKey(fromJson: _metadataFromJson)
  final Map<String, dynamic>? metadata; // Campo del backend

  const InventoryMovementModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    required this.typeString,
    required this.statusString,
    this.reasonString,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.unitPrice,
    this.totalPrice,
    this.stockAfter,
    this.stockValueAfter,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.warehouseName,
    this.referenceId,
    this.referenceType,
    this.referenceNumber,
    this.notes,
    this.userId,
    this.userName,
    this.createdById,
    required this.movementNumber,
    required this.movementDate,
    required this.createdAt,
    required this.updatedAt,
    required this.organizationId,
    this.metadata,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryMovementModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryMovementModelToJson(this);

  // Convert to domain entity
  InventoryMovement toEntity({String? productNameOverride}) {
    return InventoryMovement(
      id: id,
      productId: productId,
      productName: productNameOverride ?? productName ?? 'Producto desconocido',
      productSku: productSku ?? '',
      type: _parseMovementType(typeString),
      status: _parseMovementStatus(statusString),
      reason: reasonString != null ? _parseMovementReason(reasonString!) : _parseMovementTypeAsReason(typeString),
      quantity: int.parse(quantity.replaceAll('-', '').split('.')[0]), // Parse "-1.00" to 1
      unitCost: double.parse(unitCost),
      totalCost: double.parse(totalCost),
      unitPrice: unitPrice != null ? double.parse(unitPrice!) : null,
      totalPrice: totalPrice != null ? double.parse(totalPrice!) : null,
      lotNumber: lotNumber,
      expiryDate: expiryDate,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      referenceId: referenceId,
      referenceType: referenceType,
      notes: notes,
      userId: userId ?? createdById,
      userName: userName,
      metadata: metadata,
      movementDate: movementDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create from domain entity
  factory InventoryMovementModel.fromEntity(InventoryMovement movement) {
    return InventoryMovementModel(
      id: movement.id,
      productId: movement.productId,
      productName: movement.productName,
      productSku: movement.productSku,
      typeString: _movementTypeToString(movement.type),
      statusString: _movementStatusToString(movement.status),
      reasonString: _movementReasonToString(movement.reason),
      quantity: movement.quantity.toString(),
      unitCost: movement.unitCost.toString(),
      totalCost: movement.totalCost.toString(),
      unitPrice: movement.unitPrice?.toString(),
      totalPrice: movement.totalPrice?.toString(),
      lotNumber: movement.lotNumber,
      expiryDate: movement.expiryDate,
      warehouseId: movement.warehouseId,
      warehouseName: movement.warehouseName,
      referenceId: movement.referenceId,
      referenceType: movement.referenceType,
      notes: movement.notes,
      userId: movement.userId,
      userName: movement.userName,
      metadata: movement.metadata,
      movementNumber: 'MOV-${DateTime.now().millisecondsSinceEpoch}',
      movementDate: movement.movementDate,
      createdAt: movement.createdAt,
      updatedAt: movement.updatedAt,
      organizationId: '', // Default value
    );
  }

  // Helper methods for enum conversion
  static InventoryMovementReason _parseMovementTypeAsReason(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'purchase':
        return InventoryMovementReason.purchase;
      case 'sale':
        return InventoryMovementReason.sale;
      case 'adjustment':
        return InventoryMovementReason.adjustment;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return InventoryMovementReason.transfer;
      default:
        return InventoryMovementReason.adjustment;
    }
  }

  static InventoryMovementType _parseMovementType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'inbound':
      case 'purchase':
        return InventoryMovementType.inbound;
      case 'outbound':
      case 'sale':
        return InventoryMovementType.outbound;
      case 'adjustment':
        return InventoryMovementType.adjustment;
      case 'transfer':
        return InventoryMovementType.transfer;
      case 'transfer_in':
        return InventoryMovementType.transferIn;
      case 'transfer_out':
        return InventoryMovementType.transferOut;
      default:
        return InventoryMovementType.adjustment;
    }
  }

  static String _movementTypeToString(InventoryMovementType type) {
    return type.backendValue;
  }

  static InventoryMovementStatus _parseMovementStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'pending':
        return InventoryMovementStatus.pending;
      case 'confirmed':
        return InventoryMovementStatus.confirmed;
      case 'cancelled':
        return InventoryMovementStatus.cancelled;
      default:
        return InventoryMovementStatus.pending;
    }
  }

  static String _movementStatusToString(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return 'pending';
      case InventoryMovementStatus.confirmed:
        return 'confirmed';
      case InventoryMovementStatus.cancelled:
        return 'cancelled';
    }
  }

  static InventoryMovementReason _parseMovementReason(String reasonString) {
    switch (reasonString.toLowerCase()) {
      case 'purchase':
        return InventoryMovementReason.purchase;
      case 'sale':
        return InventoryMovementReason.sale;
      case 'adjustment':
        return InventoryMovementReason.adjustment;
      case 'damage':
        return InventoryMovementReason.damage;
      case 'loss':
        return InventoryMovementReason.loss;
      case 'transfer':
        return InventoryMovementReason.transfer;
      case 'return':
        return InventoryMovementReason.return_;
      case 'expiration':
        return InventoryMovementReason.expiration;
      default:
        return InventoryMovementReason.adjustment;
    }
  }

  static String _movementReasonToString(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.purchase:
        return 'purchase';
      case InventoryMovementReason.sale:
        return 'sale';
      case InventoryMovementReason.adjustment:
        return 'adjustment';
      case InventoryMovementReason.damage:
        return 'damage';
      case InventoryMovementReason.loss:
        return 'loss';
      case InventoryMovementReason.transfer:
        return 'transfer';
      case InventoryMovementReason.return_:
        return 'return';
      case InventoryMovementReason.expiration:
        return 'expiration';
    }
  }

  // Helper methods for safe type conversion
  static String _convertToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  static String? _convertToStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  static Map<String, dynamic>? _metadataFromJson(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

@JsonSerializable()
class CreateInventoryMovementRequest {
  final String productId;
  final String type;
  final String reason;
  final int quantity;
  final double unitCost;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime? movementDate;

  const CreateInventoryMovementRequest({
    required this.productId,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.unitCost,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.movementDate,
  });

  factory CreateInventoryMovementRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateInventoryMovementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInventoryMovementRequestToJson(this);

  factory CreateInventoryMovementRequest.fromParams(
    CreateInventoryMovementParams params,
  ) {
    return CreateInventoryMovementRequest(
      productId: params.productId,
      type: InventoryMovementModel._movementTypeToString(params.type),
      reason: InventoryMovementModel._movementReasonToString(params.reason),
      quantity: params.quantity,
      unitCost: params.unitCost,
      lotNumber: params.lotNumber,
      expiryDate: params.expiryDate,
      warehouseId: params.warehouseId,
      referenceId: params.referenceId,
      referenceType: params.referenceType,
      notes: params.notes,
      movementDate: params.movementDate,
    );
  }
}

@JsonSerializable()
class UpdateInventoryMovementRequest {
  final String? type;
  final String? reason;
  final int? quantity;
  final double? unitCost;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime? movementDate;

  const UpdateInventoryMovementRequest({
    this.type,
    this.reason,
    this.quantity,
    this.unitCost,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.movementDate,
  });

  factory UpdateInventoryMovementRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateInventoryMovementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateInventoryMovementRequestToJson(this);

  factory UpdateInventoryMovementRequest.fromParams(
    UpdateInventoryMovementParams params,
  ) {
    return UpdateInventoryMovementRequest(
      type:
          params.type != null
              ? InventoryMovementModel._movementTypeToString(params.type!)
              : null,
      reason:
          params.reason != null
              ? InventoryMovementModel._movementReasonToString(params.reason!)
              : null,
      quantity: params.quantity,
      unitCost: params.unitCost,
      lotNumber: params.lotNumber,
      expiryDate: params.expiryDate,
      warehouseId: params.warehouseId,
      referenceId: params.referenceId,
      referenceType: params.referenceType,
      notes: params.notes,
      movementDate: params.movementDate,
    );
  }
}
