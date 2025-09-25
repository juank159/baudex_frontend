// lib/features/inventory/domain/entities/inventory_batch.dart
import 'package:equatable/equatable.dart';

enum InventoryBatchStatus {
  active,
  depleted,
  expired,
  blocked;

  String get displayStatus {
    switch (this) {
      case InventoryBatchStatus.active:
        return 'Activo';
      case InventoryBatchStatus.depleted:
        return 'Agotado';
      case InventoryBatchStatus.expired:
        return 'Vencido';
      case InventoryBatchStatus.blocked:
        return 'Bloqueado';
    }
  }
}

class InventoryBatch extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final String batchNumber;
  final int originalQuantity;
  final int currentQuantity;
  final int consumedQuantity;
  final double unitCost;
  final double totalCost;
  final DateTime entryDate;
  final DateTime? expiryDate;
  final InventoryBatchStatus status;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? supplierId;
  final String? supplierName;
  final String? warehouseId;
  final String? warehouseName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.batchNumber,
    required this.originalQuantity,
    required this.currentQuantity,
    required this.consumedQuantity,
    required this.unitCost,
    required this.totalCost,
    required this.entryDate,
    this.expiryDate,
    required this.status,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.supplierId,
    this.supplierName,
    this.warehouseId,
    this.warehouseName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productSku,
        batchNumber,
        originalQuantity,
        currentQuantity,
        consumedQuantity,
        unitCost,
        totalCost,
        entryDate,
        expiryDate,
        status,
        purchaseOrderId,
        purchaseOrderNumber,
        supplierId,
        supplierName,
        warehouseId,
        warehouseName,
        notes,
        createdAt,
        updatedAt,
      ];

  // Computed properties
  bool get isActive => status == InventoryBatchStatus.active;
  bool get isConsumed => status == InventoryBatchStatus.depleted;
  bool get isExpired => status == InventoryBatchStatus.expired;
  bool get isDamaged => status == InventoryBatchStatus.blocked;

  bool get hasStock => currentQuantity > 0;
  bool get hasExpiry => expiryDate != null;
  bool get hasReference => purchaseOrderId != null && purchaseOrderId!.isNotEmpty;
  bool get hasSupplier => supplierId != null && supplierId!.isNotEmpty;
  bool get hasWarehouse => warehouseId != null && warehouseId!.isNotEmpty;

  bool get isExpiredByDate => hasExpiry && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry => hasExpiry && 
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  double get currentValue => currentQuantity * unitCost;
  double get consumedValue => consumedQuantity * unitCost;
  
  // Valor a mostrar: para lotes agotados usa el valor original, para activos usa el valor actual
  double get displayValue => isConsumed ? totalCost : currentValue;
  
  int get remainingQuantity => originalQuantity - consumedQuantity;
  double get consumptionPercentage => 
      originalQuantity > 0 ? (consumedQuantity / originalQuantity) * 100 : 0.0;

  int get daysUntilExpiry => hasExpiry 
      ? expiryDate!.difference(DateTime.now()).inDays 
      : -1;

  int get daysInStock => DateTime.now().difference(entryDate).inDays;

  String get displayStatus => status.displayStatus;

  String get statusColor {
    switch (status) {
      case InventoryBatchStatus.active:
        if (isExpiredByDate) return 'red';
        if (isNearExpiry) return 'orange';
        return 'green';
      case InventoryBatchStatus.depleted:
        return 'grey';
      case InventoryBatchStatus.expired:
        return 'red';
      case InventoryBatchStatus.blocked:
        return 'red';
    }
  }

  InventoryBatch copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? batchNumber,
    int? originalQuantity,
    int? currentQuantity,
    int? consumedQuantity,
    double? unitCost,
    double? totalCost,
    DateTime? entryDate,
    DateTime? expiryDate,
    InventoryBatchStatus? status,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? supplierId,
    String? supplierName,
    String? warehouseId,
    String? warehouseName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryBatch(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      batchNumber: batchNumber ?? this.batchNumber,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      consumedQuantity: consumedQuantity ?? this.consumedQuantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      entryDate: entryDate ?? this.entryDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BatchMovement extends Equatable {
  final String id;
  final String batchId;
  final String movementId;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final String movementType;
  final DateTime movementDate;
  final String? referenceId;
  final String? referenceType;
  final String? notes;

  const BatchMovement({
    required this.id,
    required this.batchId,
    required this.movementId,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.movementType,
    required this.movementDate,
    this.referenceId,
    this.referenceType,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        batchId,
        movementId,
        quantity,
        unitCost,
        totalCost,
        movementType,
        movementDate,
        referenceId,
        referenceType,
        notes,
      ];

  bool get isInbound => movementType == 'inbound';
  bool get isOutbound => movementType == 'outbound';
  bool get hasReference => referenceId != null && referenceId!.isNotEmpty;

  String get displayQuantity {
    if (isInbound) return '+$quantity';
    if (isOutbound) return '-$quantity';
    return '$quantity';
  }

  BatchMovement copyWith({
    String? id,
    String? batchId,
    String? movementId,
    int? quantity,
    double? unitCost,
    double? totalCost,
    String? movementType,
    DateTime? movementDate,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) {
    return BatchMovement(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      movementId: movementId ?? this.movementId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      movementType: movementType ?? this.movementType,
      movementDate: movementDate ?? this.movementDate,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      notes: notes ?? this.notes,
    );
  }
}