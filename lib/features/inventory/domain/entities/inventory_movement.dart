// lib/features/inventory/domain/entities/inventory_movement.dart
import 'package:equatable/equatable.dart';

enum InventoryMovementType {
  inbound,
  outbound,
  adjustment,
  transfer,
  transferIn,
  transferOut;

  String get displayType {
    switch (this) {
      case InventoryMovementType.inbound:
        return 'Entrada';
      case InventoryMovementType.outbound:
        return 'Salida';
      case InventoryMovementType.adjustment:
        return 'Ajuste';
      case InventoryMovementType.transfer:
        return 'Transferencia';
      case InventoryMovementType.transferIn:
        return 'Transferencia Entrada';
      case InventoryMovementType.transferOut:
        return 'Transferencia Salida';
    }
  }
  
  String get backendValue {
    switch (this) {
      case InventoryMovementType.inbound:
        return 'purchase';
      case InventoryMovementType.outbound:
        return 'sale';
      case InventoryMovementType.adjustment:
        return 'adjustment';
      case InventoryMovementType.transfer:
        return 'transfer';
      case InventoryMovementType.transferIn:
        return 'transfer_in';
      case InventoryMovementType.transferOut:
        return 'transfer_out';
    }
  }
  
  static InventoryMovementType fromBackendValue(String value) {
    switch (value) {
      case 'purchase':
        return InventoryMovementType.inbound;
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
        return InventoryMovementType.transfer;
    }
  }
}

enum InventoryMovementStatus {
  pending,
  confirmed,
  cancelled;

  String get displayStatus {
    switch (this) {
      case InventoryMovementStatus.pending:
        return 'Pendiente';
      case InventoryMovementStatus.confirmed:
        return 'Confirmado';
      case InventoryMovementStatus.cancelled:
        return 'Cancelado';
    }
  }
}

enum InventoryMovementReason {
  purchase,
  sale,
  adjustment,
  damage,
  loss,
  transfer,
  return_,
  expiration;

  String get displayReason {
    switch (this) {
      case InventoryMovementReason.purchase:
        return 'Compra';
      case InventoryMovementReason.sale:
        return 'Venta';
      case InventoryMovementReason.adjustment:
        return 'Ajuste de inventario';
      case InventoryMovementReason.damage:
        return 'Mercancía dañada';
      case InventoryMovementReason.loss:
        return 'Pérdida';
      case InventoryMovementReason.transfer:
        return 'Transferencia';
      case InventoryMovementReason.return_:
        return 'Devolución';
      case InventoryMovementReason.expiration:
        return 'Vencimiento';
    }
  }
}

class InventoryMovement extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final InventoryMovementType type;
  final InventoryMovementStatus status;
  final InventoryMovementReason reason;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final double? unitPrice;
  final double? totalPrice;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? warehouseName;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? metadata;
  final DateTime movementDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.type,
    required this.status,
    required this.reason,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.unitPrice,
    this.totalPrice,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.warehouseName,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.userId,
    this.userName,
    this.metadata,
    required this.movementDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productSku,
        type,
        status,
        reason,
        quantity,
        unitCost,
        totalCost,
        unitPrice,
        totalPrice,
        lotNumber,
        expiryDate,
        warehouseId,
        warehouseName,
        referenceId,
        referenceType,
        notes,
        userId,
        userName,
        metadata,
        movementDate,
        createdAt,
        updatedAt,
      ];

  // Computed properties
  bool get isInbound => type == InventoryMovementType.inbound || type == InventoryMovementType.transferIn;
  bool get isOutbound => type == InventoryMovementType.outbound || type == InventoryMovementType.transferOut;
  bool get isAdjustment => type == InventoryMovementType.adjustment;
  bool get isTransfer => type == InventoryMovementType.transfer || type == InventoryMovementType.transferIn || type == InventoryMovementType.transferOut;

  bool get isPending => status == InventoryMovementStatus.pending;
  bool get isConfirmed => status == InventoryMovementStatus.confirmed;
  bool get isCancelled => status == InventoryMovementStatus.cancelled;

  bool get hasLot => lotNumber != null && lotNumber!.isNotEmpty;
  bool get hasExpiry => expiryDate != null;
  bool get isExpired => hasExpiry && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry => hasExpiry && 
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  bool get hasReference => referenceId != null && referenceId!.isNotEmpty;
  bool get hasWarehouse => warehouseId != null && warehouseId!.isNotEmpty;

  String get displayQuantity {
    if (isOutbound) {
      return '-$quantity';
    }
    return '+$quantity';
  }

  // Getters for widget compatibility
  String get displayMovementType => type.displayType;
  String get displayReason => reason.displayReason;
  String get displayStatus => status.displayStatus;

  InventoryMovement copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    InventoryMovementType? type,
    InventoryMovementStatus? status,
    InventoryMovementReason? reason,
    int? quantity,
    double? unitCost,
    double? totalCost,
    double? unitPrice,
    double? totalPrice,
    String? lotNumber,
    DateTime? expiryDate,
    String? warehouseId,
    String? warehouseName,
    String? referenceId,
    String? referenceType,
    String? notes,
    String? userId,
    String? userName,
    Map<String, dynamic>? metadata,
    DateTime? movementDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      lotNumber: lotNumber ?? this.lotNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      metadata: metadata ?? this.metadata,
      movementDate: movementDate ?? this.movementDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}