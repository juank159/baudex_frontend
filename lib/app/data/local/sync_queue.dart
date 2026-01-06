import 'package:isar/isar.dart';

part 'sync_queue.g.dart';

/// Tipos de operaciones de sincronización
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Estados de una operación de sincronización
enum SyncStatus {
  pending,    // Pendiente de sincronizar
  inProgress, // Sincronizando actualmente
  completed,  // Sincronizada exitosamente
  failed,     // Falló la sincronización
}

/// Modelo Isar para la cola de sincronización
/// Almacena operaciones pendientes (crear/editar/eliminar) que se ejecutarán
/// cuando haya conectividad
@Collection()
class SyncOperation {
  /// ID autoincrementable de Isar
  Id id = Isar.autoIncrement;

  /// Tipo de entidad (ej: 'Category', 'Product', 'Customer', 'Invoice')
  @Index()
  late String entityType;

  /// ID de la entidad (puede ser temporal local o ID del servidor)
  @Index()
  late String entityId;

  /// Tipo de operación (crear, actualizar, eliminar)
  @Enumerated(EnumType.name)
  late SyncOperationType operationType;

  /// Estado actual de la operación
  @Enumerated(EnumType.name)
  late SyncStatus status;

  /// Payload en JSON de la entidad completa
  /// Para crear/actualizar: contiene todos los campos
  /// Para eliminar: puede contener solo el ID
  late String payload;

  /// Fecha y hora de creación de la operación
  @Index()
  late DateTime createdAt;

  /// Fecha y hora de sincronización exitosa
  DateTime? syncedAt;

  /// Mensaje de error si la sincronización falló
  String? error;

  /// Número de intentos de sincronización
  int retryCount = 0;

  /// ID de la organización (multitenancy)
  @Index()
  late String organizationId;

  /// Prioridad (mayor número = mayor prioridad)
  /// Útil para sincronizar facturas antes que productos, por ejemplo
  @Index()
  int priority = 0;

  /// Getter helper: operación está pendiente
  @ignore
  bool get isPending => status == SyncStatus.pending;

  /// Getter helper: operación está en progreso
  @ignore
  bool get isInProgress => status == SyncStatus.inProgress;

  /// Getter helper: operación completada
  @ignore
  bool get isCompleted => status == SyncStatus.completed;

  /// Getter helper: operación falló
  @ignore
  bool get isFailed => status == SyncStatus.failed;

  /// Getter helper: puede reintentar (si falló y no excede límite de reintentos)
  @ignore
  bool get canRetry => isFailed && retryCount < 5;

  /// Constructor vacío requerido por Isar
  SyncOperation();

  /// Constructor con nombre para crear operaciones de forma fácil
  SyncOperation.create({
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.organizationId,
    this.priority = 0,
  }) {
    status = SyncStatus.pending;
    createdAt = DateTime.now();
    retryCount = 0;
  }

  @override
  String toString() {
    return 'SyncOperation{id: $id, type: $entityType, operation: $operationType, status: $status, entityId: $entityId, retries: $retryCount}';
  }
}
