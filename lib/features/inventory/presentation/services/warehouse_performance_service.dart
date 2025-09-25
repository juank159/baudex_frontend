// lib/features/inventory/presentation/services/warehouse_performance_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/warehouse.dart';

class WarehousePerformanceService {
  static const int _debounceMs = 300;
  static const int _batchSize = 50;
  static const int _heavyComputationThreshold = 1000;
  
  static Timer? _debounceTimer;
  static final Map<String, dynamic> _cache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // ==================== DEBOUNCED OPERATIONS ====================

  /// Debounce para búsquedas y filtros
  static void debounceOperation(
    String operationKey,
    VoidCallback operation, {
    Duration? delay,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      delay ?? const Duration(milliseconds: _debounceMs),
      operation,
    );
  }

  /// Cancelar operaciones pendientes
  static void cancelPendingOperations() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  // ==================== BATCH PROCESSING ====================

  /// Procesar almacenes en lotes para evitar bloqueos de UI
  static Future<List<Warehouse>> processBatchFiltering(
    List<Warehouse> warehouses,
    bool Function(Warehouse) filterFunction, {
    void Function(int processed, int total)? onProgress,
  }) async {
    if (warehouses.length < _heavyComputationThreshold) {
      // Para volúmenes pequeños, procesamiento directo
      return warehouses.where(filterFunction).toList();
    }

    // Para volúmenes grandes, procesamiento en lotes
    final List<Warehouse> filtered = [];
    final totalItems = warehouses.length;
    
    for (int i = 0; i < totalItems; i += _batchSize) {
      final endIndex = (i + _batchSize < totalItems) ? i + _batchSize : totalItems;
      final batch = warehouses.sublist(i, endIndex);
      
      // Procesar lote
      final batchFiltered = batch.where(filterFunction).toList();
      filtered.addAll(batchFiltered);
      
      // Reportar progreso
      onProgress?.call(endIndex, totalItems);
      
      // Yield control para evitar bloquear UI
      if (i + _batchSize < totalItems) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }
    
    return filtered;
  }

  // ==================== ASYNC FILTERING ====================

  /// Filtrado asíncrono para grandes volúmenes
  static Future<List<Warehouse>> asyncFilter(
    List<Warehouse> warehouses,
    Map<String, dynamic> filters,
  ) async {
    if (warehouses.length < _heavyComputationThreshold) {
      return _syncFilter(warehouses, filters);
    }

    // Para volúmenes grandes, usar compute (isolate)
    return await compute(_isolateFilter, {
      'warehouses': warehouses,
      'filters': filters,
    });
  }

  /// Filtrado síncrono para volúmenes pequeños
  static List<Warehouse> _syncFilter(
    List<Warehouse> warehouses,
    Map<String, dynamic> filters,
  ) {
    return warehouses.where((warehouse) {
      return _matchesFilters(warehouse, filters);
    }).toList();
  }

  /// Función para ejecutar en isolate
  static List<Warehouse> _isolateFilter(Map<String, dynamic> params) {
    final List<Warehouse> warehouses = params['warehouses'];
    final Map<String, dynamic> filters = params['filters'];
    
    return warehouses.where((warehouse) {
      return _matchesFilters(warehouse, filters);
    }).toList();
  }

  /// Verificar si un almacén coincide con los filtros
  static bool _matchesFilters(Warehouse warehouse, Map<String, dynamic> filters) {
    // Filtro de búsqueda
    final searchQuery = filters['searchQuery'] as String?;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final matchesSearch = warehouse.name.toLowerCase().contains(query) ||
                           warehouse.code.toLowerCase().contains(query) ||
                           (warehouse.description?.toLowerCase().contains(query) ?? false) ||
                           (warehouse.address?.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;
    }

    // Filtro de estado
    final selectedStatus = filters['selectedStatus'] as bool?;
    if (selectedStatus != null && warehouse.isActive != selectedStatus) {
      return false;
    }

    // Filtro de fecha
    final dateFrom = filters['dateFrom'] as DateTime?;
    final dateTo = filters['dateTo'] as DateTime?;
    if (dateFrom != null && dateTo != null && warehouse.createdAt != null) {
      if (warehouse.createdAt!.isBefore(dateFrom) || 
          warehouse.createdAt!.isAfter(dateTo.add(const Duration(days: 1)))) {
        return false;
      }
    }

    // Filtro de descripción
    final filterWithDescription = filters['filterWithDescription'] as bool? ?? false;
    if (filterWithDescription && 
        (warehouse.description == null || warehouse.description!.trim().isEmpty)) {
      return false;
    }

    // Filtro de dirección
    final filterWithAddress = filters['filterWithAddress'] as bool? ?? false;
    if (filterWithAddress && 
        (warehouse.address == null || warehouse.address!.trim().isEmpty)) {
      return false;
    }

    // Filtro de recientes
    final filterRecent = filters['filterRecent'] as bool? ?? false;
    if (filterRecent && warehouse.createdAt != null) {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      if (!warehouse.createdAt!.isAfter(thirtyDaysAgo)) {
        return false;
      }
    }

    return true;
  }

  // ==================== SORTING OPTIMIZATION ====================

  /// Ordenamiento optimizado para grandes volúmenes
  static Future<List<Warehouse>> asyncSort(
    List<Warehouse> warehouses,
    String sortBy,
    String sortOrder,
  ) async {
    if (warehouses.length < _heavyComputationThreshold) {
      return _syncSort(warehouses, sortBy, sortOrder);
    }

    // Para volúmenes grandes, usar compute
    return await compute(_isolateSort, {
      'warehouses': warehouses,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
  }

  /// Ordenamiento síncrono
  static List<Warehouse> _syncSort(
    List<Warehouse> warehouses,
    String sortBy,
    String sortOrder,
  ) {
    final List<Warehouse> sortedList = List.from(warehouses);
    
    sortedList.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'code':
          comparison = a.code.compareTo(b.code);
          break;
        case 'createdAt':
          if (a.createdAt != null && b.createdAt != null) {
            comparison = a.createdAt!.compareTo(b.createdAt!);
          } else {
            comparison = a.name.compareTo(b.name);
          }
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }

      return sortOrder == 'asc' ? comparison : -comparison;
    });

    return sortedList;
  }

  /// Función de ordenamiento para isolate
  static List<Warehouse> _isolateSort(Map<String, dynamic> params) {
    final List<Warehouse> warehouses = params['warehouses'];
    final String sortBy = params['sortBy'];
    final String sortOrder = params['sortOrder'];
    
    return _syncSort(warehouses, sortBy, sortOrder);
  }

  // ==================== CACHING ====================

  /// Cachear resultados de filtros frecuentes
  static void cacheFilterResults(String cacheKey, List<Warehouse> results) {
    _cache[cacheKey] = {
      'results': results,
      'timestamp': DateTime.now(),
    };
    _lastCacheUpdate = DateTime.now();
  }

  /// Obtener resultados cacheados
  static List<Warehouse>? getCachedResults(String cacheKey) {
    final cached = _cache[cacheKey];
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as DateTime;
    if (DateTime.now().difference(timestamp) > _cacheValidDuration) {
      _cache.remove(cacheKey);
      return null;
    }

    return cached['results'] as List<Warehouse>;
  }

  /// Limpiar cache
  static void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// Generar clave de cache
  static String generateCacheKey(Map<String, dynamic> filters, String sortBy, String sortOrder) {
    final searchQuery = filters['searchQuery'] ?? '';
    final selectedStatus = filters['selectedStatus']?.toString() ?? 'null';
    final dateFrom = filters['dateFrom']?.toString() ?? '';
    final dateTo = filters['dateTo']?.toString() ?? '';
    final filterWithDescription = filters['filterWithDescription']?.toString() ?? 'false';
    final filterWithAddress = filters['filterWithAddress']?.toString() ?? 'false';
    final filterRecent = filters['filterRecent']?.toString() ?? 'false';
    
    return 'filter_${searchQuery}_${selectedStatus}_${dateFrom}_${dateTo}_'
           '${filterWithDescription}_${filterWithAddress}_${filterRecent}_'
           '${sortBy}_$sortOrder'.hashCode.toString();
  }

  // ==================== PERFORMANCE MONITORING ====================

  /// Medir tiempo de ejecución
  static Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      print('⏱️ $operationName ejecutado en ${stopwatch.elapsedMilliseconds}ms');
      
      // Log warning si toma mucho tiempo
      if (stopwatch.elapsedMilliseconds > 1000) {
        print('⚠️ Operación lenta detectada: $operationName (${stopwatch.elapsedMilliseconds}ms)');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ $operationName falló después de ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // ==================== MEMORY OPTIMIZATION ====================

  /// Liberar memoria no utilizada
  static void releaseUnusedMemory() {
    // Limpiar cache viejo
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cache.forEach((key, value) {
      final timestamp = value['timestamp'] as DateTime;
      if (now.difference(timestamp) > _cacheValidDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    // Cancelar timers pendientes
    cancelPendingOperations();
  }

  // ==================== CLEANUP ====================

  /// Limpiar recursos
  static void dispose() {
    cancelPendingOperations();
    clearCache();
  }

  // ==================== UTILITY METHODS ====================

  /// Obtener estadísticas de performance
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'cacheSize': _cache.length,
      'lastCacheUpdate': _lastCacheUpdate?.toIso8601String(),
      'cacheValidDuration': _cacheValidDuration.inMinutes,
      'batchSize': _batchSize,
      'heavyComputationThreshold': _heavyComputationThreshold,
      'debounceMs': _debounceMs,
    };
  }

  /// Verificar si se debe usar procesamiento pesado
  static bool shouldUseHeavyProcessing(int itemCount) {
    return itemCount >= _heavyComputationThreshold;
  }
}