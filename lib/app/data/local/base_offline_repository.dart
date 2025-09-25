// lib/app/data/local/base_offline_repository.dart
import 'package:isar/isar.dart';

/// Interfaz base para entidades que soportan sincronización offline
abstract class SyncableEntity {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime? get deletedAt;
  bool get isSynced;
  DateTime? get lastSyncAt;
}

/// Resultado de operaciones de sincronización
class SyncResult<T> {
  final bool success;
  final List<T> syncedItems;
  final List<String> errors;
  final int totalProcessed;

  const SyncResult({
    required this.success,
    required this.syncedItems,
    required this.errors,
    required this.totalProcessed,
  });

  bool get hasErrors => errors.isNotEmpty;
  
  SyncResult<T> copyWith({
    bool? success,
    List<T>? syncedItems,
    List<String>? errors,
    int? totalProcessed,
  }) {
    return SyncResult<T>(
      success: success ?? this.success,
      syncedItems: syncedItems ?? this.syncedItems,
      errors: errors ?? this.errors,
      totalProcessed: totalProcessed ?? this.totalProcessed,
    );
  }
}

/// Política de resolución de conflictos durante la sincronización
enum ConflictResolutionPolicy {
  /// El registro más reciente gana (basado en updatedAt)
  latestWins,
  /// El registro local gana siempre
  localWins,
  /// El registro remoto gana siempre
  remoteWins,
  /// Requiere intervención manual
  manual,
}

/// Información sobre un conflicto detectado
class SyncConflict<T> {
  final String entityId;
  final T localEntity;
  final T remoteEntity;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final ConflictResolutionPolicy suggestedResolution;

  const SyncConflict({
    required this.entityId,
    required this.localEntity,
    required this.remoteEntity,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.suggestedResolution,
  });
}

/// Interfaz base para repositorios offline
abstract class BaseOfflineRepository<T extends SyncableEntity, TModel> {
  /// Obtener la colección ISAR correspondiente
  IsarCollection<TModel> get collection;

  /// Mapear de entidad de dominio a modelo ISAR
  TModel toIsarModel(T entity);

  /// Mapear de modelo ISAR a entidad de dominio
  T fromIsarModel(TModel model);

  /// Obtener todos los registros no sincronizados
  Future<List<T>> getUnsyncedEntities();

  /// Obtener registros eliminados que no han sido sincronizados
  Future<List<T>> getUnsyncedDeleted();

  /// Marcar registros como sincronizados
  Future<void> markAsSynced(List<String> ids);

  /// Marcar registro como no sincronizado (para cambios locales)
  Future<void> markAsUnsynced(String id);

  /// Guardar entidad localmente (marca como no sincronizada)
  Future<void> saveLocally(T entity);

  /// Guardar múltiples entidades localmente
  Future<void> saveAllLocally(List<T> entities);

  /// Eliminar entidad localmente (soft delete)
  Future<void> deleteLocally(String id);

  /// Sincronizar entidades no sincronizadas con el servidor
  Future<SyncResult<T>> syncToServer(List<T> entities);

  /// Aplicar cambios del servidor localmente
  Future<SyncResult<T>> syncFromServer(List<T> serverEntities);

  /// Resolver conflictos de sincronización
  Future<T> resolveConflict(
    SyncConflict<T> conflict,
    ConflictResolutionPolicy policy,
  );

  /// Detectar conflictos entre entidades locales y del servidor
  Future<List<SyncConflict<T>>> detectConflicts(List<T> serverEntities);

  /// Obtener estadísticas de sincronización
  Future<SyncStats> getSyncStats();
}

/// Estadísticas de sincronización
class SyncStats {
  final int totalEntities;
  final int syncedEntities;
  final int unsyncedEntities;
  final int pendingDeletes;
  final DateTime? lastSyncAt;
  final Map<String, int> errorsByType;

  const SyncStats({
    required this.totalEntities,
    required this.syncedEntities,
    required this.unsyncedEntities,
    required this.pendingDeletes,
    this.lastSyncAt,
    this.errorsByType = const {},
  });

  double get syncProgress {
    if (totalEntities == 0) return 1.0;
    return syncedEntities / totalEntities;
  }

  bool get isFullySynced => unsyncedEntities == 0 && pendingDeletes == 0;
}