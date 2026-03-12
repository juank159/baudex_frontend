// lib/app/core/services/idempotency_service.dart

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/local/isar_database.dart';
import '../../data/local/models/isar_idempotency_record.dart';

/// Servicio para gestionar idempotencia de operaciones
///
/// Evita que la misma operación se ejecute múltiples veces en el servidor,
/// usando claves de idempotencia únicas para trackear operaciones procesadas.
class IdempotencyService extends GetxService {
  /// Verifica si una operación ya fue procesada exitosamente
  ///
  /// Retorna `true` si la operación ya fue completada,
  /// `false` si aún no se ha procesado o falló.
  Future<bool> isOperationProcessed(String idempotencyKey) async {
    try {
      final isar = IsarDatabase.instance.database;
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record == null) {
        return false; // No existe registro, no fue procesada
      }

      if (record.isCompleted) {
        _logInfo('Operation already completed: $idempotencyKey');
        return true; // Ya fue procesada exitosamente
      }

      if (record.isProcessing) {
        _logWarning('Operation is currently processing: $idempotencyKey');
        return true; // Está en proceso, evitar duplicar
      }

      if (record.isExpired) {
        _logWarning('Operation record expired: $idempotencyKey');
        await _deleteRecord(record);
        return false; // Expiró, puede procesarse de nuevo
      }

      return false; // Pending o Failed, puede procesarse
    } catch (e) {
      _logError('Error checking operation: $e');
      return false; // En caso de error, permitir procesamiento
    }
  }

  /// Registra una nueva operación como pendiente
  ///
  /// Retorna la clave de idempotencia generada
  Future<String> registerOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    String? suffix,
    int expirationHours = 24,
  }) async {
    try {
      final record = IsarIdempotencyRecord.createPending(
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        suffix: suffix,
        expirationHours: expirationHours,
      );

      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarIdempotencyRecords.put(record);
      });

      _logInfo('Operation registered: ${record.idempotencyKey}');
      return record.idempotencyKey;
    } catch (e) {
      _logError('Error registering operation: $e');
      rethrow;
    }
  }

  /// Registra una operación con clave personalizada (para claves estables sin timestamp)
  ///
  /// Útil para prevenir duplicados cuando la clave debe ser estable entre ejecuciones
  Future<void> registerOperationWithKey({
    required String idempotencyKey,
    required String operationType,
    required String entityType,
    required String entityId,
    int expirationHours = 24,
  }) async {
    try {
      // Verificar si ya existe
      final isar = IsarDatabase.instance.database;
      final existing = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (existing != null) {
        _logInfo('Operation with key already exists: $idempotencyKey');
        return;
      }

      // Crear nuevo registro
      final now = DateTime.now();
      final record = IsarIdempotencyRecord.create(
        idempotencyKey: idempotencyKey,
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        status: IdempotencyStatus.pending,
        retryCount: 0,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(Duration(hours: expirationHours)),
      );

      await isar.writeTxn(() async {
        await isar.isarIdempotencyRecords.put(record);
      });

      _logInfo('Operation registered with custom key: $idempotencyKey');
    } catch (e) {
      _logError('Error registering operation with key: $e');
      rethrow;
    }
  }

  /// Marca una operación como en proceso
  Future<void> markAsProcessing(String idempotencyKey) async {
    try {
      final isar = IsarDatabase.instance.database;
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record == null) {
        _logWarning('Cannot mark as processing: record not found');
        return;
      }

      await isar.writeTxn(() async {
        record.markAsProcessing();
        await isar.isarIdempotencyRecords.put(record);
      });

      _logInfo('Operation marked as processing: $idempotencyKey');
    } catch (e) {
      _logError('Error marking as processing: $e');
    }
  }

  /// Marca una operación como completada exitosamente
  Future<void> markAsCompleted({
    required String idempotencyKey,
    String? responseData,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record == null) {
        _logWarning('Cannot mark as completed: record not found');
        return;
      }

      await isar.writeTxn(() async {
        record.markAsCompleted(responseData: responseData);
        await isar.isarIdempotencyRecords.put(record);
      });

      _logInfo('✅ Operation completed: $idempotencyKey');
    } catch (e) {
      _logError('Error marking as completed: $e');
    }
  }

  /// Marca una operación como fallida
  Future<void> markAsFailed({
    required String idempotencyKey,
    required String errorMessage,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record == null) {
        _logWarning('Cannot mark as failed: record not found');
        return;
      }

      await isar.writeTxn(() async {
        record.markAsFailed(errorMessage: errorMessage);
        await isar.isarIdempotencyRecords.put(record);
      });

      _logWarning('❌ Operation failed: $idempotencyKey (retry: ${record.retryCount}/10)');
    } catch (e) {
      _logError('Error marking as failed: $e');
    }
  }

  /// Obtiene operaciones pendientes de procesar
  Future<List<IsarIdempotencyRecord>> getPendingOperations({
    String? entityType,
    int limit = 100,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      var query = isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.pending);

      if (entityType != null) {
        query = query.entityTypeEqualTo(entityType);
      }

      final records = await query
          .sortByCreatedAt()
          .limit(limit)
          .findAll();

      return records;
    } catch (e) {
      _logError('Error getting pending operations: $e');
      return [];
    }
  }

  /// Obtiene operaciones fallidas que pueden reintentarse
  Future<List<IsarIdempotencyRecord>> getRetryableOperations({
    String? entityType,
    int limit = 50,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      var query = isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.failed);

      if (entityType != null) {
        query = query.entityTypeEqualTo(entityType);
      }

      final records = await query
          .sortByLastRetryAt()
          .limit(limit)
          .findAll();

      // Filtrar solo las que pueden reintentarse
      return records.where((r) => r.canRetry).toList();
    } catch (e) {
      _logError('Error getting retryable operations: $e');
      return [];
    }
  }

  /// Resetea una operación fallida para reintentar
  Future<void> resetForRetry(String idempotencyKey) async {
    try {
      final isar = IsarDatabase.instance.database;
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record == null || !record.canRetry) {
        _logWarning('Cannot retry operation: $idempotencyKey');
        return;
      }

      await isar.writeTxn(() async {
        record.resetForRetry();
        await isar.isarIdempotencyRecords.put(record);
      });

      _logInfo('Operation reset for retry: $idempotencyKey');
    } catch (e) {
      _logError('Error resetting for retry: $e');
    }
  }

  /// Limpia registros expirados o muy antiguos
  Future<int> cleanupExpiredRecords({int daysOld = 7}) async {
    try {
      final isar = IsarDatabase.instance.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // Obtener registros para limpiar
      final expiredRecords = await isar.isarIdempotencyRecords
          .filter()
          .group((q) => q
              .expiresAtIsNotNull()
              .and()
              .expiresAtLessThan(DateTime.now()))
          .or()
          .group((q) => q
              .statusEqualTo(IdempotencyStatus.completed)
              .and()
              .processedAtLessThan(cutoffDate))
          .findAll();

      // Eliminar en batch
      int deleted = 0;
      await isar.writeTxn(() async {
        for (final record in expiredRecords) {
          await isar.isarIdempotencyRecords.delete(record.id);
          deleted++;
        }
      });

      if (deleted > 0) {
        _logInfo('🧹 Cleaned up $deleted expired records');
      }

      return deleted;
    } catch (e) {
      _logError('Error cleaning up records: $e');
      return 0;
    }
  }

  /// Elimina un registro específico
  Future<void> _deleteRecord(IsarIdempotencyRecord record) async {
    try {
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarIdempotencyRecords.delete(record.id);
      });
    } catch (e) {
      _logError('Error deleting record: $e');
    }
  }

  /// Obtiene estadísticas de operaciones
  Future<Map<String, int>> getStatistics() async {
    try {
      final isar = IsarDatabase.instance.database;

      final pending = await isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.pending)
          .count();

      final processing = await isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.processing)
          .count();

      final completed = await isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.completed)
          .count();

      final failed = await isar.isarIdempotencyRecords
          .filter()
          .statusEqualTo(IdempotencyStatus.failed)
          .count();

      return {
        'pending': pending,
        'processing': processing,
        'completed': completed,
        'failed': failed,
        'total': pending + processing + completed + failed,
      };
    } catch (e) {
      _logError('Error getting statistics: $e');
      return {};
    }
  }

  // Logging helpers
  void _logInfo(String message) {
    // ignore: avoid_print
    print('[IdempotencyService] ℹ️  $message');
  }

  void _logWarning(String message) {
    // ignore: avoid_print
    print('[IdempotencyService] ⚠️  $message');
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('[IdempotencyService] ❌ $message');
  }
}
