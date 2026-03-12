// lib/features/inventory/data/models/isar/isar_inventory_batch_movement.dart
import 'package:isar/isar.dart';
import '../../../domain/entities/inventory_batch.dart';

part 'isar_inventory_batch_movement.g.dart';

@collection
class IsarInventoryBatchMovement {
  Id id = Isar.autoIncrement; // Auto-increment ID para ISAR

  @Index(unique: true)
  late String serverId; // ID del servidor (UUID)

  @Index()
  late String batchId; // ID del lote relacionado

  @Index()
  late String movementId; // ID del movimiento de inventario general

  late int quantity; // Cantidad del movimiento

  late double unitCost; // Costo unitario en el momento del movimiento
  late double totalCost; // Costo total (quantity * unitCost)

  late String movementType; // Tipo: 'inbound', 'outbound', 'adjustment', etc.

  late DateTime movementDate; // Fecha del movimiento

  String? referenceId; // ID de referencia (orden de compra, venta, etc.)
  String? referenceType; // Tipo de referencia ('purchase_order', 'sale', etc.)

  String? notes; // Notas adicionales

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Campos de versionamiento
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructores
  IsarInventoryBatchMovement();

  IsarInventoryBatchMovement.create({
    required this.serverId,
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

  /// Crear IsarInventoryBatchMovement desde entidad del dominio
  static IsarInventoryBatchMovement fromEntity(BatchMovement entity) {
    return IsarInventoryBatchMovement.create(
      serverId: entity.id,
      batchId: entity.batchId,
      movementId: entity.movementId,
      quantity: entity.quantity,
      unitCost: entity.unitCost,
      totalCost: entity.totalCost,
      movementType: entity.movementType,
      movementDate: entity.movementDate,
      referenceId: entity.referenceId,
      referenceType: entity.referenceType,
      notes: entity.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true, // Asumimos que viene del servidor sincronizado
      lastSyncAt: DateTime.now(),
    );
  }

  /// Convertir IsarInventoryBatchMovement a entidad del dominio
  BatchMovement toEntity() {
    return BatchMovement(
      id: serverId,
      batchId: batchId,
      movementId: movementId,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      movementType: movementType,
      movementDate: movementDate,
      referenceId: referenceId,
      referenceType: referenceType,
      notes: notes,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Verifica si es un movimiento de entrada
  bool get isInbound => movementType == 'inbound';

  /// Verifica si es un movimiento de salida
  bool get isOutbound => movementType == 'outbound';

  /// Verifica si es un ajuste
  bool get isAdjustment => movementType == 'adjustment';

  /// Verifica si tiene referencia
  bool get hasReference => referenceId != null && referenceId!.isNotEmpty;

  /// Verifica si está eliminado (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Verifica si necesita sincronización
  bool get needsSync => !isSynced;

  /// Obtiene la representación de la cantidad con signo
  String get displayQuantity {
    if (isInbound) return '+$quantity';
    if (isOutbound) return '-$quantity';
    return '$quantity';
  }

  /// Obtiene la descripción del tipo de movimiento
  String get movementTypeDescription {
    switch (movementType) {
      case 'inbound':
        return 'Entrada';
      case 'outbound':
        return 'Salida';
      case 'adjustment':
        return 'Ajuste';
      case 'transfer':
        return 'Transferencia';
      case 'return':
        return 'Devolución';
      default:
        return movementType;
    }
  }

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

  /// Verificar si hay conflicto de versión con otro movimiento
  bool hasConflictWith(IsarInventoryBatchMovement other) {
    return version != other.version;
  }

  // ==================== VALIDATION ====================

  /// Validar que el movimiento sea válido
  bool isValid() {
    if (serverId.isEmpty) return false;
    if (batchId.isEmpty) return false;
    if (movementId.isEmpty) return false;
    if (quantity <= 0) return false;
    if (unitCost < 0) return false;
    if (totalCost < 0) return false;
    if (movementType.isEmpty) return false;
    return true;
  }

  /// Obtener errores de validación
  List<String> getValidationErrors() {
    final List<String> errors = [];

    if (serverId.isEmpty) errors.add('ID de servidor requerido');
    if (batchId.isEmpty) errors.add('ID de lote requerido');
    if (movementId.isEmpty) errors.add('ID de movimiento requerido');
    if (quantity <= 0) errors.add('Cantidad debe ser mayor a cero');
    if (unitCost < 0) errors.add('Costo unitario no puede ser negativo');
    if (totalCost < 0) errors.add('Costo total no puede ser negativo');
    if (movementType.isEmpty) errors.add('Tipo de movimiento requerido');

    return errors;
  }

  // ==================== QUERY HELPERS ====================

  /// Verifica si el movimiento pertenece a un lote específico
  bool belongsToBatch(String batchId) {
    return this.batchId == batchId;
  }

  /// Verifica si el movimiento pertenece a un movimiento general específico
  bool belongsToMovement(String movementId) {
    return this.movementId == movementId;
  }

  /// Verifica si el movimiento fue creado en un rango de fechas
  bool isWithinDateRange(DateTime start, DateTime end) {
    return movementDate.isAfter(start) && movementDate.isBefore(end);
  }

  /// Verifica si el movimiento fue creado después de una fecha
  bool isAfter(DateTime date) {
    return movementDate.isAfter(date);
  }

  /// Verifica si el movimiento fue creado antes de una fecha
  bool isBefore(DateTime date) {
    return movementDate.isBefore(date);
  }

  // ==================== CALCULATION HELPERS ====================

  /// Calcula el impacto en el stock (positivo para entradas, negativo para salidas)
  int get stockImpact {
    if (isInbound) return quantity;
    if (isOutbound) return -quantity;
    return 0; // Para ajustes, depende del contexto
  }

  /// Calcula el impacto en el valor del inventario
  double get valueImpact {
    if (isInbound) return totalCost;
    if (isOutbound) return -totalCost;
    return 0;
  }

  /// Verifica si el movimiento representa una ganancia o pérdida
  bool get isGain => stockImpact > 0;

  bool get isLoss => stockImpact < 0;

  // ==================== METADATA ====================

  /// Actualizar notas
  void updateNotes(String newNotes, {String? modifiedBy}) {
    notes = newNotes;
    incrementVersion(modifiedBy: modifiedBy);
  }

  /// Agregar nota adicional
  void appendNote(String additionalNote, {String? modifiedBy}) {
    if (notes == null || notes!.isEmpty) {
      notes = additionalNote;
    } else {
      notes = '$notes\n$additionalNote';
    }
    incrementVersion(modifiedBy: modifiedBy);
  }

  @override
  String toString() {
    return 'IsarInventoryBatchMovement{serverId: $serverId, batchId: $batchId, movementType: $movementType, quantity: $quantity, movementDate: $movementDate}';
  }
}
