// lib/features/inventory/data/models/inventory_batch_model.dart
import '../../domain/entities/inventory_batch.dart';

class InventoryBatchModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productSku;
  final String batchNumber;
  final int originalQuantity;
  final int currentQuantity;
  final double unitCost;
  final DateTime entryDate;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? warehouseName;
  final String? supplierId;
  final String? supplierName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryBatchModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    required this.batchNumber,
    required this.originalQuantity,
    required this.currentQuantity,
    required this.unitCost,
    required this.entryDate,
    this.expiryDate,
    this.warehouseId,
    this.warehouseName,
    this.supplierId,
    this.supplierName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    // Extract purchase order ID - format like "BATCH-202508-000005" based on batchNumber
    String? orderNumber;
    if (json['purchaseOrderId'] != null) {
      orderNumber = 'PO-${json['batchNumber']?.toString().split('-').last ?? json['purchaseOrderId']}';
    }
    
    return InventoryBatchModel(
      id: json['id'],
      productId: json['productId'],
      productName: json['product_name'] ?? json['product']?['name'],
      productSku: json['product_sku'] ?? json['product']?['sku'],
      batchNumber: json['batchNumber'],
      originalQuantity: double.parse(json['originalQuantity']?.toString() ?? '0').toInt(),
      currentQuantity: double.parse(json['currentQuantity']?.toString() ?? '0').toInt(),
      unitCost: double.parse(json['unitCost']?.toString() ?? '0.0'),
      entryDate: DateTime.parse(json['purchaseDate']),
      expiryDate: json['expirationDate'] != null ? DateTime.parse(json['expirationDate']) : null,
      warehouseId: json['warehouse_id'] ?? json['warehouse']?['id'],
      warehouseName: json['warehouse_name'] ?? json['warehouse']?['name'],
      supplierId: json['supplier_id'] ?? json['supplier']?['id'] ?? json['purchaseOrder']?['supplier']?['id'],
      supplierName: json['supplier_name'] ?? json['supplier']?['name'] ?? json['purchaseOrder']?['supplier']?['name'] ?? 'Proveedor Principal',
      purchaseOrderId: json['purchaseOrderId'],
      purchaseOrderNumber: json['purchase_order_number'] ?? json['purchaseOrder']?['orderNumber'] ?? orderNumber,
      notes: json['notes'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'batch_number': batchNumber,
      'original_quantity': originalQuantity,
      'current_quantity': currentQuantity,
      'unit_cost': unitCost,
      'entry_date': entryDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'purchase_order_id': purchaseOrderId,
      'purchase_order_number': purchaseOrderNumber,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryBatch toEntity() {
    return InventoryBatch(
      id: id,
      productId: productId,
      productName: productName ?? 'Producto Desconocido',
      productSku: productSku ?? 'N/A',
      batchNumber: batchNumber,
      originalQuantity: originalQuantity,
      currentQuantity: currentQuantity,
      consumedQuantity: originalQuantity - currentQuantity,
      unitCost: unitCost,
      totalCost: currentQuantity * unitCost,
      entryDate: entryDate,
      expiryDate: expiryDate,
      status: _mapStatus(status),
      purchaseOrderId: purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static InventoryBatchModel fromEntity(InventoryBatch entity) {
    return InventoryBatchModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      batchNumber: entity.batchNumber,
      originalQuantity: entity.originalQuantity,
      currentQuantity: entity.currentQuantity,
      unitCost: entity.unitCost,
      entryDate: entity.entryDate,
      expiryDate: entity.expiryDate,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      purchaseOrderId: entity.purchaseOrderId,
      purchaseOrderNumber: entity.purchaseOrderNumber,
      notes: entity.notes,
      status: entity.status.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static InventoryBatchStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return InventoryBatchStatus.active;
      case 'depleted':
        return InventoryBatchStatus.depleted;
      case 'expired':
        return InventoryBatchStatus.expired;
      case 'blocked':
        return InventoryBatchStatus.blocked;
      default:
        return InventoryBatchStatus.active;
    }
  }
}