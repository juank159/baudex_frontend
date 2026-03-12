// lib/app/core/services/conflict_resolution_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

/// Estrategia de resolución de conflictos
enum ConflictStrategy {
  /// El servidor siempre gana (default para datos críticos)
  serverWins,

  /// El cliente siempre gana (para datos que el usuario está editando activamente)
  clientWins,

  /// Usar timestamps para decidir (última actualización gana)
  lastWriteWins,

  /// Merge inteligente de campos (combinar cambios no conflictivos)
  smartMerge,
}

/// Resultado de la resolución de conflictos
class ConflictResolutionResult {
  final bool resolved;
  final Map<String, dynamic>? mergedData;
  final String? error;
  final ConflictStrategy strategyUsed;

  const ConflictResolutionResult({
    required this.resolved,
    this.mergedData,
    this.error,
    required this.strategyUsed,
  });

  factory ConflictResolutionResult.success(
    Map<String, dynamic> data,
    ConflictStrategy strategy,
  ) {
    return ConflictResolutionResult(
      resolved: true,
      mergedData: data,
      strategyUsed: strategy,
    );
  }

  factory ConflictResolutionResult.failure(String error) {
    return ConflictResolutionResult(
      resolved: false,
      error: error,
      strategyUsed: ConflictStrategy.serverWins,
    );
  }
}

/// Servicio para resolución automática de conflictos de sincronización
class ConflictResolutionService extends GetxService {
  /// Estrategias por defecto para cada tipo de entidad
  final Map<String, ConflictStrategy> _entityStrategies = {
    'Product': ConflictStrategy.lastWriteWins,
    'Customer': ConflictStrategy.lastWriteWins,
    'Invoice': ConflictStrategy.serverWins, // Invoices son críticas, servidor gana
    'Expense': ConflictStrategy.lastWriteWins,
    'Category': ConflictStrategy.serverWins,
    'Supplier': ConflictStrategy.lastWriteWins,
    'BankAccount': ConflictStrategy.serverWins,
    'PurchaseOrder': ConflictStrategy.lastWriteWins,
    'InventoryMovement': ConflictStrategy.serverWins, // Inventario es crítico
    'CreditNote': ConflictStrategy.serverWins,
    'CustomerCredit': ConflictStrategy.serverWins,
    'organization': ConflictStrategy.serverWins,
  };

  /// Campos que NO se deben mergear (solo tomar uno u otro)
  final Set<String> _nonMergeableFields = {
    'id',
    'serverId',
    'createdAt',
    'createdById',
    'organizationId',
    'version',
  };

  /// Campos que siempre deben venir del servidor
  final Set<String> _serverOnlyFields = {
    'id',
    'serverId',
    'createdAt',
    'version',
  };

  /// Resuelve un conflicto entre datos locales y del servidor
  ConflictResolutionResult resolveConflict({
    required String entityType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    ConflictStrategy? overrideStrategy,
  }) {
    try {
      final strategy = overrideStrategy ?? _entityStrategies[entityType] ?? ConflictStrategy.serverWins;

      AppLogger.d('Resolviendo conflicto para $entityType con estrategia: $strategy', tag: 'CONFLICT');

      switch (strategy) {
        case ConflictStrategy.serverWins:
          return ConflictResolutionResult.success(serverData, strategy);

        case ConflictStrategy.clientWins:
          // Mantener datos del cliente pero actualizar campos del servidor
          final merged = Map<String, dynamic>.from(localData);
          for (final field in _serverOnlyFields) {
            if (serverData.containsKey(field)) {
              merged[field] = serverData[field];
            }
          }
          return ConflictResolutionResult.success(merged, strategy);

        case ConflictStrategy.lastWriteWins:
          return _resolveByTimestamp(localData, serverData, strategy);

        case ConflictStrategy.smartMerge:
          return _smartMerge(localData, serverData, strategy);
      }
    } catch (e) {
      AppLogger.e('Error resolviendo conflicto: $e', tag: 'CONFLICT');
      return ConflictResolutionResult.failure(e.toString());
    }
  }

  /// Resuelve por timestamp (última actualización gana)
  ConflictResolutionResult _resolveByTimestamp(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictStrategy strategy,
  ) {
    try {
      final localUpdatedAt = _parseDateTime(localData['updatedAt']);
      final serverUpdatedAt = _parseDateTime(serverData['updatedAt']);

      if (localUpdatedAt == null || serverUpdatedAt == null) {
        // Si no hay timestamps, servidor gana
        AppLogger.w('Timestamps no disponibles, usando datos del servidor', tag: 'CONFLICT');
        return ConflictResolutionResult.success(serverData, strategy);
      }

      if (localUpdatedAt.isAfter(serverUpdatedAt)) {
        AppLogger.d('Local es más reciente, usando datos locales', tag: 'CONFLICT');
        // Local gana pero actualizamos campos del servidor
        final merged = Map<String, dynamic>.from(localData);
        for (final field in _serverOnlyFields) {
          if (serverData.containsKey(field)) {
            merged[field] = serverData[field];
          }
        }
        return ConflictResolutionResult.success(merged, strategy);
      } else {
        AppLogger.d('Servidor es más reciente, usando datos del servidor', tag: 'CONFLICT');
        return ConflictResolutionResult.success(serverData, strategy);
      }
    } catch (e) {
      AppLogger.e('Error comparando timestamps: $e', tag: 'CONFLICT');
      return ConflictResolutionResult.success(serverData, strategy);
    }
  }

  /// Merge inteligente de campos
  ConflictResolutionResult _smartMerge(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictStrategy strategy,
  ) {
    try {
      final merged = <String, dynamic>{};

      // Obtener todos los campos únicos
      final allFields = {...localData.keys, ...serverData.keys};

      for (final field in allFields) {
        final localValue = localData[field];
        final serverValue = serverData[field];

        if (_serverOnlyFields.contains(field)) {
          // Campos del servidor tienen prioridad
          merged[field] = serverValue ?? localValue;
        } else if (_nonMergeableFields.contains(field)) {
          // Campos no mergeables: usar servidor si existe
          merged[field] = serverValue ?? localValue;
        } else if (localValue == serverValue) {
          // Sin conflicto
          merged[field] = localValue;
        } else if (localValue == null) {
          // Solo servidor tiene valor
          merged[field] = serverValue;
        } else if (serverValue == null) {
          // Solo local tiene valor
          merged[field] = localValue;
        } else {
          // Conflicto real: decidir por timestamp de campo o usar servidor
          // Por defecto usamos el valor más reciente basado en updatedAt
          final localUpdatedAt = _parseDateTime(localData['updatedAt']);
          final serverUpdatedAt = _parseDateTime(serverData['updatedAt']);

          if (localUpdatedAt != null && serverUpdatedAt != null && localUpdatedAt.isAfter(serverUpdatedAt)) {
            merged[field] = localValue;
          } else {
            merged[field] = serverValue;
          }
        }
      }

      AppLogger.d('Smart merge completado con ${merged.length} campos', tag: 'CONFLICT');
      return ConflictResolutionResult.success(merged, strategy);
    } catch (e) {
      AppLogger.e('Error en smart merge: $e', tag: 'CONFLICT');
      return ConflictResolutionResult.success(serverData, strategy);
    }
  }

  /// Parse DateTime de diferentes formatos
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Configura la estrategia para un tipo de entidad
  void setStrategy(String entityType, ConflictStrategy strategy) {
    _entityStrategies[entityType] = strategy;
  }

  /// Obtiene la estrategia actual para un tipo de entidad
  ConflictStrategy getStrategy(String entityType) {
    return _entityStrategies[entityType] ?? ConflictStrategy.serverWins;
  }

  /// Crea un log de conflicto para debugging
  void logConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required ConflictResolutionResult result,
  }) {
    AppLogger.i('''
╔══════════════════════════════════════════════════════════════╗
║                    CONFLICTO RESUELTO                         ║
╠══════════════════════════════════════════════════════════════╣
║ Entidad: $entityType ($entityId)
║ Estrategia: ${result.strategyUsed}
║ Resuelto: ${result.resolved}
║ Local updatedAt: ${localData['updatedAt']}
║ Server updatedAt: ${serverData['updatedAt']}
╚══════════════════════════════════════════════════════════════╝
''', tag: 'CONFLICT');
  }
}
