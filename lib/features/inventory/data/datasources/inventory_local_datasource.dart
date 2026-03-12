// lib/features/inventory/data/datasources/inventory_local_datasource.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_balance_model.dart';
import '../models/inventory_stats_model.dart';
import '../models/warehouse_model.dart';
import '../models/isar/isar_inventory_movement.dart';
import '../../domain/repositories/inventory_repository.dart';

abstract class InventoryLocalDataSource {
  // Movements cache
  Future<PaginatedResult<InventoryMovementModel>?> getCachedMovements(
    InventoryMovementQueryParams params,
  );

  Future<void> cacheMovements(
    InventoryMovementQueryParams params,
    PaginatedResult<InventoryMovementModel> movements,
  );

  Future<InventoryMovementModel?> getCachedMovementById(String id);

  Future<void> cacheMovement(InventoryMovementModel movement);

  Future<List<InventoryMovementModel>> searchCachedMovements(
    SearchInventoryMovementsParams params,
  );

  // Balances cache
  Future<PaginatedResult<InventoryBalanceModel>?> getCachedBalances(
    InventoryBalanceQueryParams params,
  );

  Future<void> cacheBalances(
    InventoryBalanceQueryParams params,
    PaginatedResult<InventoryBalanceModel> balances,
  );

  Future<InventoryBalanceModel?> getCachedBalanceByProduct(
    String productId, {
    String? warehouseId,
  });

  Future<void> cacheBalance(InventoryBalanceModel balance);

  Future<List<InventoryBalanceModel>> getCachedLowStockProducts({
    String? warehouseId,
  });

  Future<void> cacheLowStockProducts(
    List<InventoryBalanceModel> balances, {
    String? warehouseId,
  });

  // Stats cache
  Future<InventoryStatsModel?> getCachedStats(InventoryStatsParams params);

  Future<void> cacheStats(
    InventoryStatsParams params,
    InventoryStatsModel stats,
  );

  // Batch operations
  Future<void> cacheBatches(List<dynamic> batches);
  Future<void> cacheBatch(dynamic batch);
  Future<List<dynamic>> getCachedBatches();
  Future<dynamic> getCachedBatch(String id);
  Future<List<dynamic>> getUnsyncedBatches();
  Future<void> markBatchAsSynced(String tempId, String serverId);
  Future<List<dynamic>> getExpiredBatches();
  Future<List<dynamic>> getNearExpiryBatches({int daysThreshold = 30});
  Future<List<dynamic>> searchCachedBatches(String searchTerm);

  // Batch movement operations
  Future<void> cacheBatchMovements(List<dynamic> movements);
  Future<void> cacheBatchMovement(dynamic movement);
  Future<List<dynamic>> getCachedBatchMovements(String batchId);
  Future<List<dynamic>> getUnsyncedBatchMovements();
  Future<void> markBatchMovementAsSynced(String tempId, String serverId);

  // Warehouse cache
  Future<void> cacheWarehouses(List<WarehouseModel> warehouses);
  Future<List<WarehouseModel>> getCachedWarehouses();
  Future<WarehouseModel?> getCachedWarehouseById(String id);

  // Alert products cache (out of stock, expired, near expiry)
  Future<void> cacheOutOfStockProducts(List<InventoryBalanceModel> products, {String? warehouseId});
  Future<List<InventoryBalanceModel>> getCachedOutOfStockProducts({String? warehouseId});
  Future<void> cacheExpiredProducts(List<InventoryBalanceModel> products, {String? warehouseId});
  Future<List<InventoryBalanceModel>> getCachedExpiredProducts({String? warehouseId});
  Future<void> cacheNearExpiryProducts(List<InventoryBalanceModel> products, {String? warehouseId});
  Future<List<InventoryBalanceModel>> getCachedNearExpiryProducts({String? warehouseId});

  // Cache management
  Future<void> clearMovementsCache();
  Future<void> clearBalancesCache();
  Future<void> clearStatsCache();
  Future<void> clearBatchesCache();
  Future<void> clearWarehousesCache();
  Future<void> clearAllCache();
  Future<bool> isCacheValid(String cacheKey);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const Duration cacheValidityDuration = Duration(minutes: 15);

  InventoryLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<PaginatedResult<InventoryMovementModel>?> getCachedMovements(
    InventoryMovementQueryParams params,
  ) async {
    try {
      final cacheKey = _generateMovementsCacheKey(params);

      if (!await isCacheValid(cacheKey)) {
        return null;
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      final data =
          (json['data'] as List)
              .map((item) => InventoryMovementModel.fromJson(item))
              .toList();

      final meta =
          json['meta'] != null
              ? PaginationMeta.fromJson(json['meta'])
              : PaginationMeta.empty();

      return PaginatedResult(data: data, meta: meta);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheMovements(
    InventoryMovementQueryParams params,
    PaginatedResult<InventoryMovementModel> movements,
  ) async {
    try {
      final cacheKey = _generateMovementsCacheKey(params);
      final cacheData = {
        'data': movements.data.map((movement) => movement.toJson()).toList(),
        'meta': movements.meta.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<InventoryMovementModel?> getCachedMovementById(String id) async {
    try {
      final cacheKey = '${ApiConstants.inventoryMovementsCacheKey}_detail_$id';

      if (!await isCacheValid(cacheKey)) {
        return null;
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      return InventoryMovementModel.fromJson(json['data']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheMovement(InventoryMovementModel movement) async {
    try {
      // GUARDAR EN ISAR PRIMERO
      try {
        final isar = IsarDatabase.instance.database;
        await isar.writeTxn(() async {
          var isarMovement = await isar.isarInventoryMovements
              .filter()
              .serverIdEqualTo(movement.id)
              .findFirst();

          if (isarMovement != null) {
            isarMovement.updateFromModel(movement);
          } else {
            isarMovement = IsarInventoryMovement.fromModel(movement);
          }

          await isar.isarInventoryMovements.put(isarMovement);
        });
        print('✅ InventoryMovement guardado en ISAR: ${movement.id}');
      } catch (e) {
        print('⚠️ Error guardando en ISAR (continuando...): $e');
      }

      // GUARDAR EN SECURESTORAGE (código existente)
      final cacheKey =
          '${ApiConstants.inventoryMovementsCacheKey}_detail_${movement.id}';
      final cacheData = {
        'data': movement.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<List<InventoryMovementModel>> searchCachedMovements(
    SearchInventoryMovementsParams params,
  ) async {
    try {
      final cacheKey =
          '${ApiConstants.inventoryMovementsCacheKey}_search_${params.searchTerm.toLowerCase().replaceAll(' ', '_')}';

      if (!await isCacheValid(cacheKey)) {
        return [];
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => InventoryMovementModel.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PaginatedResult<InventoryBalanceModel>?> getCachedBalances(
    InventoryBalanceQueryParams params,
  ) async {
    try {
      final cacheKey = _generateBalancesCacheKey(params);

      if (!await isCacheValid(cacheKey)) {
        return null;
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      final data =
          (json['data'] as List)
              .map((item) => InventoryBalanceModel.fromJson(item))
              .toList();

      final meta =
          json['meta'] != null
              ? PaginationMeta.fromJson(json['meta'])
              : PaginationMeta.empty();

      return PaginatedResult(data: data, meta: meta);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheBalances(
    InventoryBalanceQueryParams params,
    PaginatedResult<InventoryBalanceModel> balances,
  ) async {
    try {
      final cacheKey = _generateBalancesCacheKey(params);
      final cacheData = {
        'data': balances.data.map((balance) => balance.toJson()).toList(),
        'meta': balances.meta.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<InventoryBalanceModel?> getCachedBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      final cacheKey =
          '${ApiConstants.inventoryBalancesCacheKey}_product_${productId}_${warehouseId ?? 'all'}';

      if (!await isCacheValid(cacheKey)) {
        return null;
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      return InventoryBalanceModel.fromJson(json['data']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheBalance(InventoryBalanceModel balance) async {
    try {
      final cacheKey =
          '${ApiConstants.inventoryBalancesCacheKey}_product_${balance.productId}_${balance.warehouseId ?? 'all'}';
      final cacheData = {
        'data': balance.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedLowStockProducts({
    String? warehouseId,
  }) async {
    try {
      final cacheKey =
          '${ApiConstants.inventoryBalancesCacheKey}_low_stock_${warehouseId ?? 'all'}';

      if (!await isCacheValid(cacheKey)) {
        return [];
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => InventoryBalanceModel.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheLowStockProducts(
    List<InventoryBalanceModel> balances, {
    String? warehouseId,
  }) async {
    try {
      final cacheKey =
          '${ApiConstants.inventoryBalancesCacheKey}_low_stock_${warehouseId ?? 'all'}';
      final cacheData = {
        'data': balances.map((balance) => balance.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<InventoryStatsModel?> getCachedStats(
    InventoryStatsParams params,
  ) async {
    try {
      final cacheKey = _generateStatsCacheKey(params);

      if (!await isCacheValid(cacheKey)) {
        return null;
      }

      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return null;

      final json = jsonDecode(cachedData);
      return InventoryStatsModel.fromJson(json['data']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheStats(
    InventoryStatsParams params,
    InventoryStatsModel stats,
  ) async {
    try {
      final cacheKey = _generateStatsCacheKey(params);
      final cacheData = {
        'data': stats.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente en caso de error de cache
    }
  }

  @override
  Future<void> clearMovementsCache() async {
    try {
      final allKeys = await secureStorage.readAll();
      final movementKeys =
          allKeys.keys
              .where(
                (key) =>
                    key.startsWith(ApiConstants.inventoryMovementsCacheKey),
              )
              .toList();

      for (final key in movementKeys) {
        await secureStorage.delete(key: key);
      }
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<void> clearBalancesCache() async {
    try {
      final allKeys = await secureStorage.readAll();
      final balanceKeys =
          allKeys.keys
              .where(
                (key) => key.startsWith(ApiConstants.inventoryBalancesCacheKey),
              )
              .toList();

      for (final key in balanceKeys) {
        await secureStorage.delete(key: key);
      }
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<void> clearStatsCache() async {
    try {
      final allKeys = await secureStorage.readAll();
      final statsKeys =
          allKeys.keys
              .where(
                (key) => key.startsWith(ApiConstants.inventoryStatsCacheKey),
              )
              .toList();

      for (final key in statsKeys) {
        await secureStorage.delete(key: key);
      }
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<void> clearBatchesCache() async {
    // TODO: Implementar cuando se use ISAR
  }

  @override
  Future<void> clearAllCache() async {
    await clearMovementsCache();
    await clearBalancesCache();
    await clearStatsCache();
    await clearBatchesCache();
    await clearWarehousesCache();
  }

  // ==================== WAREHOUSE CACHE ====================

  static const String _warehousesCacheKey = 'inventory_warehouses_cache';

  @override
  Future<void> cacheWarehouses(List<WarehouseModel> warehouses) async {
    try {
      final cacheData = {
        'data': warehouses.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await secureStorage.write(key: _warehousesCacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<List<WarehouseModel>> getCachedWarehouses() async {
    try {
      final cachedData = await secureStorage.read(key: _warehousesCacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => WarehouseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WarehouseModel?> getCachedWarehouseById(String id) async {
    try {
      final warehouses = await getCachedWarehouses();
      return warehouses.cast<WarehouseModel?>().firstWhere(
        (w) => w!.id == id,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearWarehousesCache() async {
    try {
      await secureStorage.delete(key: _warehousesCacheKey);
      // Also clear alert products cache
      final allKeys = await secureStorage.readAll();
      final alertKeys = allKeys.keys.where(
        (key) => key.startsWith('inventory_out_of_stock_') ||
                 key.startsWith('inventory_expired_') ||
                 key.startsWith('inventory_near_expiry_'),
      ).toList();
      for (final key in alertKeys) {
        await secureStorage.delete(key: key);
      }
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  // ==================== ALERT PRODUCTS CACHE ====================

  @override
  Future<void> cacheOutOfStockProducts(List<InventoryBalanceModel> products, {String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_out_of_stock_${warehouseId ?? 'all'}';
      final cacheData = {
        'data': products.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedOutOfStockProducts({String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_out_of_stock_${warehouseId ?? 'all'}';
      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => InventoryBalanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheExpiredProducts(List<InventoryBalanceModel> products, {String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_expired_${warehouseId ?? 'all'}';
      final cacheData = {
        'data': products.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedExpiredProducts({String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_expired_${warehouseId ?? 'all'}';
      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => InventoryBalanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheNearExpiryProducts(List<InventoryBalanceModel> products, {String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_near_expiry_${warehouseId ?? 'all'}';
      final cacheData = {
        'data': products.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      // Fallar silenciosamente
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedNearExpiryProducts({String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_near_expiry_${warehouseId ?? 'all'}';
      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];

      final json = jsonDecode(cachedData);
      return (json['data'] as List)
          .map((item) => InventoryBalanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== BATCH OPERATIONS ====================

  @override
  Future<void> cacheBatches(List<dynamic> batches) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<void> cacheBatch(dynamic batch) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<List<dynamic>> getCachedBatches() async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<dynamic> getCachedBatch(String id) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return null;
  }

  @override
  Future<List<dynamic>> getUnsyncedBatches() async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<void> markBatchAsSynced(String tempId, String serverId) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<List<dynamic>> getExpiredBatches() async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<List<dynamic>> getNearExpiryBatches({int daysThreshold = 30}) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<List<dynamic>> searchCachedBatches(String searchTerm) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  // ==================== BATCH MOVEMENT OPERATIONS ====================

  @override
  Future<void> cacheBatchMovements(List<dynamic> movements) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<void> cacheBatchMovement(dynamic movement) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<List<dynamic>> getCachedBatchMovements(String batchId) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<List<dynamic>> getUnsyncedBatchMovements() async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
    return [];
  }

  @override
  Future<void> markBatchMovementAsSynced(String tempId, String serverId) async {
    // TODO: Implementar con ISAR en InventoryLocalDataSourceIsar
  }

  @override
  Future<bool> isCacheValid(String cacheKey) async {
    try {
      final cachedData = await secureStorage.read(key: cacheKey);
      if (cachedData == null) return false;

      final json = jsonDecode(cachedData);
      final timestampStr = json['timestamp'] as String?;
      if (timestampStr == null) return false;

      final cacheTime = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference < cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  // Helper methods to generate cache keys
  String _generateMovementsCacheKey(InventoryMovementQueryParams params) {
    final keyParts = [
      ApiConstants.inventoryMovementsCacheKey,
      'page_${params.page}',
      'limit_${params.limit}',
      'sort_${params.sortBy}_${params.sortOrder}',
    ];

    if (params.search != null && params.search!.isNotEmpty) {
      keyParts.add(
        'search_${params.search!.toLowerCase().replaceAll(' ', '_')}',
      );
    }
    if (params.productId != null) keyParts.add('product_${params.productId}');
    if (params.type != null) keyParts.add('type_${params.type!.name}');
    if (params.status != null) keyParts.add('status_${params.status!.name}');
    if (params.reason != null) keyParts.add('reason_${params.reason!.name}');
    if (params.warehouseId != null)
      keyParts.add('warehouse_${params.warehouseId}');
    if (params.startDate != null)
      keyParts.add(
        'start_${params.startDate!.toIso8601String().split('T')[0]}',
      );
    if (params.endDate != null)
      keyParts.add('end_${params.endDate!.toIso8601String().split('T')[0]}');

    return keyParts.join('_');
  }

  String _generateBalancesCacheKey(InventoryBalanceQueryParams params) {
    final keyParts = [
      ApiConstants.inventoryBalancesCacheKey,
      'page_${params.page}',
      'limit_${params.limit}',
      'sort_${params.sortBy}_${params.sortOrder}',
    ];

    if (params.search != null && params.search!.isNotEmpty) {
      keyParts.add(
        'search_${params.search!.toLowerCase().replaceAll(' ', '_')}',
      );
    }
    if (params.categoryId != null)
      keyParts.add('category_${params.categoryId}');
    if (params.warehouseId != null)
      keyParts.add('warehouse_${params.warehouseId}');
    if (params.lowStock == true) keyParts.add('low_stock');
    if (params.outOfStock == true) keyParts.add('out_of_stock');
    if (params.nearExpiry == true) keyParts.add('near_expiry');
    if (params.expired == true) keyParts.add('expired');

    return keyParts.join('_');
  }

  String _generateStatsCacheKey(InventoryStatsParams params) {
    final keyParts = [ApiConstants.inventoryStatsCacheKey];

    if (params.startDate != null) {
      keyParts.add(
        'start_${params.startDate!.toIso8601String().split('T')[0]}',
      );
    }
    if (params.endDate != null) {
      keyParts.add('end_${params.endDate!.toIso8601String().split('T')[0]}');
    }
    if (params.warehouseId != null) {
      keyParts.add('warehouse_${params.warehouseId}');
    }
    if (params.categoryId != null) {
      keyParts.add('category_${params.categoryId}');
    }

    return keyParts.join('_');
  }
}
