// lib/features/inventory/data/models/isar/isar_inventory_batch.dart
import 'package:isar/isar.dart';
import '../../../domain/entities/inventory_batch.dart';

part 'isar_inventory_batch.g.dart';

@collection
class IsarInventoryBatch {
  Id id = Isar.autoIncrement; // Auto-increment ID para ISAR

  @Index(unique: true)
  late String serverId; // ID del servidor (UUID)

  @Index()
  late String productId;

  late String productName;
  late String productSku;

  @Index()
  late String batchNumber;

  late int originalQuantity;
  late int currentQuantity;
  late int consumedQuantity;

  late double unitCost;
  late double totalCost;

  late DateTime entryDate;
  DateTime? expiryDate;

  @Enumerated(EnumType.name)
  late IsarInventoryBatchStatus status;

  String? purchaseOrderId;
  String? purchaseOrderNumber;

  String? supplierId;
  String? supplierName;

  @Index()
  String? warehouseId;

  String? warehouseName;

  String? notes;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Campos de versionamiento para detección de conflictos
  late int version; // Versión del documento (incrementa con cada cambio)
  DateTime? lastModifiedAt; // Timestamp del último cambio
  String? lastModifiedBy; // Usuario que hizo el último cambio

  // Constructores
  IsarInventoryBatch();

  IsarInventoryBatch.create({
    required this.serverId,
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
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // ==================== MAPPERS ====================

  /// Crear IsarInventoryBatch desde entidad del dominio
  static IsarInventoryBatch fromEntity(InventoryBatch entity) {
    return IsarInventoryBatch.create(
      serverId: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      batchNumber: entity.batchNumber,
      originalQuantity: entity.originalQuantity,
      currentQuantity: entity.currentQuantity,
      consumedQuantity: entity.consumedQuantity,
      unitCost: entity.unitCost,
      totalCost: entity.totalCost,
      entryDate: entity.entryDate,
      expiryDate: entity.expiryDate,
      status: _mapBatchStatus(entity.status),
      purchaseOrderId: entity.purchaseOrderId,
      purchaseOrderNumber: entity.purchaseOrderNumber,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true, // Asumimos que viene del servidor sincronizado
      lastSyncAt: DateTime.now(),
    );
  }

  /// Convertir IsarInventoryBatch a entidad del dominio
  InventoryBatch toEntity() {
    return InventoryBatch(
      id: serverId,
      productId: productId,
      productName: productName,
      productSku: productSku,
      batchNumber: batchNumber,
      originalQuantity: originalQuantity,
      currentQuantity: currentQuantity,
      consumedQuantity: consumedQuantity,
      unitCost: unitCost,
      totalCost: totalCost,
      entryDate: entryDate,
      expiryDate: expiryDate,
      status: _mapIsarBatchStatus(status),
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

  // ==================== ENUM MAPPERS ====================

  /// Mapear InventoryBatchStatus a IsarInventoryBatchStatus
  static IsarInventoryBatchStatus _mapBatchStatus(InventoryBatchStatus status) {
    switch (status) {
      case InventoryBatchStatus.active:
        return IsarInventoryBatchStatus.active;
      case InventoryBatchStatus.depleted:
        return IsarInventoryBatchStatus.depleted;
      case InventoryBatchStatus.expired:
        return IsarInventoryBatchStatus.expired;
      case InventoryBatchStatus.blocked:
        return IsarInventoryBatchStatus.blocked;
    }
  }

  /// Mapear IsarInventoryBatchStatus a InventoryBatchStatus
  static InventoryBatchStatus _mapIsarBatchStatus(
    IsarInventoryBatchStatus status,
  ) {
    switch (status) {
      case IsarInventoryBatchStatus.active:
        return InventoryBatchStatus.active;
      case IsarInventoryBatchStatus.depleted:
        return InventoryBatchStatus.depleted;
      case IsarInventoryBatchStatus.expired:
        return InventoryBatchStatus.expired;
      case IsarInventoryBatchStatus.blocked:
        return InventoryBatchStatus.blocked;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Verifica si el lote está vencido
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Verifica si el lote está próximo a vencer (30 días)
  bool get isNearExpiry {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }

  /// Verifica si el lote tiene stock disponible
  bool get hasStock => currentQuantity > 0;

  /// Verifica si el lote está activo
  bool get isActive => status == IsarInventoryBatchStatus.active;

  /// Verifica si el lote está eliminado (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Verifica si el lote necesita sincronización
  bool get needsSync => !isSynced;

  /// Calcula el valor actual del lote
  double get currentValue => currentQuantity * unitCost;

  /// Calcula el porcentaje consumido
  double get consumptionPercentage {
    if (originalQuantity == 0) return 0.0;
    return (consumedQuantity / originalQuantity) * 100;
  }

  /// Días hasta la fecha de vencimiento
  int get daysUntilExpiry {
    if (expiryDate == null) return -1;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Días en inventario
  int get daysInStock => DateTime.now().difference(entryDate).inDays;

  // ==================== SYNC METHODS ====================

  /// Marcar como no sincronizado
  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  /// Marcar como sincronizado
  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  /// Soft delete
  void softDelete() {
    deletedAt = DateTime.now();
    updatedAt = DateTime.now();
    markAsUnsynced();
  }

  /// Restaurar después de soft delete
  void restore() {
    deletedAt = null;
    updatedAt = DateTime.now();
    markAsUnsynced();
  }

  /// Incrementar versión para control de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    lastModifiedBy = modifiedBy;
    markAsUnsynced();
  }

  /// Verificar si hay conflicto de versión con otro lote
  bool hasConflictWith(IsarInventoryBatch other) {
    return version != other.version;
  }

  /// Actualizar cantidad actual
  void updateQuantity(int newQuantity, {String? modifiedBy}) {
    currentQuantity = newQuantity;
    consumedQuantity = originalQuantity - currentQuantity;

    // Actualizar estado si se agotó
    if (currentQuantity == 0) {
      status = IsarInventoryBatchStatus.depleted;
    } else if (status == IsarInventoryBatchStatus.depleted) {
      // Si tenía stock agotado pero ahora tiene, reactivar
      status = IsarInventoryBatchStatus.active;
    }

    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Consumir cantidad del lote
  void consume(int quantity, {String? modifiedBy}) {
    if (quantity > currentQuantity) {
      throw Exception('No hay suficiente stock en el lote');
    }

    currentQuantity -= quantity;
    consumedQuantity += quantity;

    if (currentQuantity == 0) {
      status = IsarInventoryBatchStatus.depleted;
    }

    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Agregar cantidad al lote (devolución, ajuste positivo)
  void addQuantity(int quantity, {String? modifiedBy}) {
    currentQuantity += quantity;
    consumedQuantity = originalQuantity - currentQuantity;

    // Si estaba agotado, reactivar
    if (status == IsarInventoryBatchStatus.depleted && currentQuantity > 0) {
      status = IsarInventoryBatchStatus.active;
    }

    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Bloquear lote
  void block({String? reason, String? modifiedBy}) {
    status = IsarInventoryBatchStatus.blocked;
    if (reason != null) {
      notes = notes != null ? '$notes\nBloqueado: $reason' : 'Bloqueado: $reason';
    }
    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Desbloquear lote
  void unblock({String? modifiedBy}) {
    if (currentQuantity > 0) {
      status = IsarInventoryBatchStatus.active;
    } else {
      status = IsarInventoryBatchStatus.depleted;
    }
    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Marcar como vencido
  void markAsExpired({String? modifiedBy}) {
    status = IsarInventoryBatchStatus.expired;
    incrementVersion(modifiedBy: modifiedBy);
  }

  // ==================== VALIDATION ====================

  /// Validar que el lote sea válido
  bool isValid() {
    if (serverId.isEmpty) return false;
    if (productId.isEmpty) return false;
    if (batchNumber.isEmpty) return false;
    if (originalQuantity < 0) return false;
    if (currentQuantity < 0) return false;
    if (consumedQuantity < 0) return false;
    if (unitCost < 0) return false;
    if (totalCost < 0) return false;
    return true;
  }

  /// Obtener errores de validación
  List<String> getValidationErrors() {
    final List<String> errors = [];

    if (serverId.isEmpty) errors.add('ID de servidor requerido');
    if (productId.isEmpty) errors.add('ID de producto requerido');
    if (batchNumber.isEmpty) errors.add('Número de lote requerido');
    if (originalQuantity < 0) errors.add('Cantidad original no puede ser negativa');
    if (currentQuantity < 0) errors.add('Cantidad actual no puede ser negativa');
    if (consumedQuantity < 0) errors.add('Cantidad consumida no puede ser negativa');
    if (unitCost < 0) errors.add('Costo unitario no puede ser negativo');
    if (totalCost < 0) errors.add('Costo total no puede ser negativo');

    return errors;
  }

  @override
  String toString() {
    return 'IsarInventoryBatch{serverId: $serverId, productName: $productName, batchNumber: $batchNumber, currentQuantity: $currentQuantity, status: $status}';
  }
}

/// Enum para el estado del lote en ISAR
@Name('InventoryBatchStatus')
enum IsarInventoryBatchStatus {
  active,
  depleted,
  expired,
  blocked,
}
