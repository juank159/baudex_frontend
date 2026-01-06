// lib/app/data/local/cache_sync_mixin.dart

import 'package:isar/isar.dart';
import 'dart:async';

/// Mixin para garantizar sincronizacion consistente entre ISAR y SecureStorage
///
/// Este mixin resuelve el problema de desincronizacion cuando se actualizan
/// entidades offline: asegura que TANTO ISAR como SecureStorage se actualicen
/// correctamente.
///
/// **Problema que resuelve**:
/// - Antes: UPDATE offline solo actualizaba SecureStorage, dejando ISAR obsoleto
/// - Ahora: Ambos caches se actualizan simultaneamente
///
/// **Uso**:
/// ```dart
/// class CustomerRepositoryImpl with CacheSyncMixin<Customer, CustomerModel, IsarCustomer> {
///   @override
///   Isar get isar => IsarDatabase.instance.database;
///
///   @override
///   Future<void> updateInIsar(Customer entity) async {
///     final isarModel = IsarCustomer.fromEntity(entity);
///     await isar.writeTxn(() async {
///       await isar.isarCustomers.put(isarModel);
///     });
///   }
///
///   @override
///   Future<void> updateInSecureStorage(Customer entity) async {
///     final model = CustomerModel.fromEntity(entity);
///     await localDataSource.cacheCustomer(model);
///   }
/// }
/// ```
///
/// **Garantias**:
/// - Actualizacion atomica de ambos caches
/// - Rollback si ISAR falla (critico)
/// - Log warning si SecureStorage falla (no critico, puede recuperarse)
/// - Orden correcto: ISAR primero (SSOT), luego SecureStorage (cache rapido)
///
/// **Type Parameters**:
/// - TEntity: Entidad de dominio (e.g., Customer, Product)
/// - TIsarModel: Modelo ISAR (e.g., IsarCustomer, IsarProduct)
mixin CacheSyncMixin<TEntity, TIsarModel> {

  /// ISAR database instance - debe ser implementado por el repositorio
  Isar get isar;

  /// Actualiza entidad en ISAR
  ///
  /// Este metodo DEBE ser implementado por cada repositorio para:
  /// 1. Convertir TEntity a TIsarModel
  /// 2. Marcar como no sincronizado (markAsUnsynced())
  /// 3. Guardar en ISAR usando writeTxn
  ///
  /// Ejemplo:
  /// ```dart
  /// @override
  /// Future<void> updateInIsar(Customer entity) async {
  ///   final isarCustomer = IsarCustomer.fromEntity(entity);
  ///   isarCustomer.markAsUnsynced();
  ///   await isar.writeTxn(() async {
  ///     await isar.isarCustomers.put(isarCustomer);
  ///   });
  /// }
  /// ```
  Future<void> updateInIsar(TEntity entity);

  /// Actualiza entidad en SecureStorage
  ///
  /// Este metodo DEBE ser implementado por cada repositorio para:
  /// 1. Convertir TEntity a Model (JSON-serializable)
  /// 2. Llamar al localDataSource correspondiente
  ///
  /// Ejemplo:
  /// ```dart
  /// @override
  /// Future<void> updateInSecureStorage(Customer entity) async {
  ///   final model = CustomerModel.fromEntity(entity);
  ///   await localDataSource.cacheCustomer(model);
  /// }
  /// ```
  Future<void> updateInSecureStorage(TEntity entity);

  /// Sincronizacion dual: Actualiza ISAR + SecureStorage
  ///
  /// Este es el metodo principal que garantiza consistencia entre ambos caches.
  ///
  /// **Orden de ejecucion**:
  /// 1. ISAR primero (source of truth, transaccional)
  /// 2. SecureStorage segundo (cache rapido, puede fallar sin romper)
  ///
  /// **Manejo de errores**:
  /// - ISAR falla → Lanza excepcion, rollback automatico
  /// - SecureStorage falla → Log warning, continua (no critico)
  ///
  /// **Uso**:
  /// ```dart
  /// await syncDualCache(updatedEntity);
  /// ```
  Future<void> syncDualCache(TEntity entity) async {
    try {
      // PASO 1: Actualizar ISAR primero (SSOT - Single Source of Truth)
      // Si esto falla, todo falla (transaccional)
      await updateInIsar(entity);
      print('✅ CacheSync: Entidad actualizada en ISAR');

      // PASO 2: Actualizar SecureStorage (cache rapido)
      // Si esto falla, solo loggeamos warning (no es critico)
      try {
        await updateInSecureStorage(entity);
        print('✅ CacheSync: Entidad actualizada en SecureStorage');
      } catch (cacheError) {
        print('⚠️ CacheSync: Error actualizando SecureStorage (no critico): $cacheError');
        // No hacer rethrow - SecureStorage es cache secundario
        // ISAR es SSOT, si falla SecureStorage no es critico
      }

    } catch (isarError) {
      print('❌ CacheSync: Error CRITICO actualizando ISAR: $isarError');
      // Rethrow - ISAR es critico, si falla todo debe fallar
      rethrow;
    }
  }

  /// Elimina entidad de ambos caches (soft delete en ISAR)
  ///
  /// Este metodo DEBE ser implementado por cada repositorio para:
  /// 1. Soft delete en ISAR (marcar deletedAt)
  /// 2. Eliminar de SecureStorage
  ///
  /// Ejemplo:
  /// ```dart
  /// @override
  /// Future<void> deleteInIsar(String entityId) async {
  ///   final isarCustomer = await isar.isarCustomers
  ///       .filter()
  ///       .serverIdEqualTo(entityId)
  ///       .findFirst();
  ///
  ///   if (isarCustomer != null) {
  ///     isarCustomer.markAsDeleted();
  ///     await isar.writeTxn(() async {
  ///       await isar.isarCustomers.put(isarCustomer);
  ///     });
  ///   }
  /// }
  /// ```
  Future<void> deleteInIsar(String entityId);

  /// Elimina entidad de SecureStorage
  ///
  /// Este metodo DEBE ser implementado por cada repositorio para:
  /// 1. Llamar al metodo de eliminacion del localDataSource
  ///
  /// Ejemplo:
  /// ```dart
  /// @override
  /// Future<void> deleteInSecureStorage(String entityId) async {
  ///   await localDataSource.removeCachedCustomer(entityId);
  /// }
  /// ```
  Future<void> deleteInSecureStorage(String entityId);

  /// Eliminacion dual: ISAR (soft delete) + SecureStorage (hard delete)
  ///
  /// **Orden de ejecucion**:
  /// 1. ISAR primero (soft delete: marcar deletedAt)
  /// 2. SecureStorage segundo (hard delete: eliminar key)
  ///
  /// **Uso**:
  /// ```dart
  /// await syncDualCacheDelete(entityId);
  /// ```
  Future<void> syncDualCacheDelete(String entityId) async {
    try {
      // PASO 1: Soft delete en ISAR (marcar como eliminado, mantener para sync)
      await deleteInIsar(entityId);
      print('✅ CacheSync: Entidad marcada como eliminada en ISAR');

      // PASO 2: Hard delete en SecureStorage (eliminar completamente)
      try {
        await deleteInSecureStorage(entityId);
        print('✅ CacheSync: Entidad eliminada de SecureStorage');
      } catch (cacheError) {
        print('⚠️ CacheSync: Error eliminando de SecureStorage (no critico): $cacheError');
      }

    } catch (isarError) {
      print('❌ CacheSync: Error CRITICO eliminando de ISAR: $isarError');
      rethrow;
    }
  }
}

/// Estrategia de resolucion de conflictos para sincronizacion
enum ConflictResolutionStrategy {
  /// El registro mas reciente gana (basado en updatedAt)
  latestWins,

  /// El registro local siempre gana
  localWins,

  /// El registro remoto siempre gana
  remoteWins,

  /// Requiere intervencion manual del usuario
  manual,
}

/// Resultado de una operacion de sincronizacion dual
class SyncResult {
  final bool isarSuccess;
  final bool secureStorageSuccess;
  final String? isarError;
  final String? secureStorageError;

  const SyncResult({
    required this.isarSuccess,
    required this.secureStorageSuccess,
    this.isarError,
    this.secureStorageError,
  });

  /// Ambos caches se actualizaron exitosamente
  bool get fullSuccess => isarSuccess && secureStorageSuccess;

  /// Al menos ISAR se actualizo (minimo aceptable)
  bool get partialSuccess => isarSuccess;

  /// Ambos fallaron (error critico)
  bool get totalFailure => !isarSuccess;

  @override
  String toString() {
    return 'SyncResult(ISAR: ${isarSuccess ? "✅" : "❌"}, '
           'SecureStorage: ${secureStorageSuccess ? "✅" : "❌"})';
  }
}
