// lib/features/inventory/data/datasources/inventory_local_datasource_isar.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/isar/isar_inventory_batch.dart';
import '../models/isar/isar_inventory_batch_movement.dart';
import '../models/isar/isar_inventory_movement.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_batch_model.dart';
import '../models/inventory_balance_model.dart';
import '../models/inventory_stats_model.dart';
import '../models/warehouse_model.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_local_datasource.dart';

/// Implementación ISAR del datasource local de inventory
///
/// Almacenamiento persistente offline-first usando ISAR para:
/// - Inventory Movements (movimientos de inventario)
/// - Inventory Batches (lotes de inventario)
/// - Inventory Batch Movements (movimientos por lote)
class InventoryLocalDataSourceIsar implements InventoryLocalDataSource {
  final IsarDatabase _database;

  InventoryLocalDataSourceIsar(this._database);

  Isar get _isar => _database.database;

  // ==================== BATCH OPERATIONS ====================

  @override
  Future<void> cacheBatches(List<dynamic> batches) async {
    try {
      await _isar.writeTxn(() async {
        for (final batch in batches) {
          // Determinar si es un Model o Entity
          InventoryBatch batchEntity;

          if (batch is InventoryBatch) {
            batchEntity = batch;
          } else if (batch is InventoryBatchModel) {
            batchEntity = batch.toEntity();
          } else {
            AppLogger.w('ISAR: Tipo de batch ignorado: ${batch.runtimeType}');
            continue;
          }

          // Buscar existente por serverId
          IsarInventoryBatch? existing = await _isar.isarInventoryBatchs
              .filter()
              .serverIdEqualTo(batchEntity.id)
              .findFirst();

          IsarInventoryBatch isarBatch;

          if (existing != null) {
            // Actualizar existente
            isarBatch = IsarInventoryBatch.fromEntity(batchEntity);
            isarBatch.id = existing.id; // Mantener el ID de ISAR
            isarBatch.isSynced = true;
            isarBatch.lastSyncAt = DateTime.now();
          } else {
            // Crear nuevo
            isarBatch = IsarInventoryBatch.fromEntity(batchEntity);
            isarBatch.isSynced = true;
            isarBatch.lastSyncAt = DateTime.now();
          }

          await _isar.isarInventoryBatchs.put(isarBatch);
        }
      });

      AppLogger.i('ISAR: ${batches.length} batches cacheados exitosamente');
    } catch (e) {
      AppLogger.e('Error al cachear batches en ISAR: $e');
      throw CacheException('Error al cachear batches en ISAR: $e');
    }
  }

  @override
  Future<void> cacheBatch(dynamic batch) async {
    try {
      InventoryBatch batchEntity;

      if (batch is InventoryBatch) {
        batchEntity = batch;
      } else if (batch is InventoryBatchModel) {
        batchEntity = batch.toEntity();
      } else {
        throw CacheException('Invalid batch type: ${batch.runtimeType}');
      }

      await _isar.writeTxn(() async {
        // Buscar existente
        IsarInventoryBatch? existing = await _isar.isarInventoryBatchs
            .filter()
            .serverIdEqualTo(batchEntity.id)
            .findFirst();

        IsarInventoryBatch isarBatch;

        if (existing != null) {
          isarBatch = IsarInventoryBatch.fromEntity(batchEntity);
          isarBatch.id = existing.id;
          isarBatch.isSynced = true;
          isarBatch.lastSyncAt = DateTime.now();
        } else {
          isarBatch = IsarInventoryBatch.fromEntity(batchEntity);
          isarBatch.isSynced = true;
          isarBatch.lastSyncAt = DateTime.now();
        }

        await _isar.isarInventoryBatchs.put(isarBatch);
      });

      AppLogger.i('ISAR: Batch ${batchEntity.batchNumber} cacheado exitosamente');
    } catch (e) {
      AppLogger.e('Error al cachear batch en ISAR: $e');
      throw CacheException('Error al cachear batch en ISAR: $e');
    }
  }

  @override
  Future<List<dynamic>> getCachedBatches() async {
    try {
      final isarBatches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll();

      if (isarBatches.isEmpty) {
        AppLogger.d('ISAR: No hay batches en cache local');
        return [];
      }

      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${batches.length} batches obtenidos del cache local');
      return batches;
    } catch (e) {
      AppLogger.e('Error al obtener batches de ISAR: $e');
      throw CacheException('Error al obtener batches de ISAR: $e');
    }
  }

  @override
  Future<dynamic> getCachedBatch(String id) async {
    try {
      final isarBatch = await _isar.isarInventoryBatchs
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarBatch == null) {
        AppLogger.d('ISAR: Batch con ID $id no encontrado en cache');
        return null;
      }

      return isarBatch.toEntity();
    } catch (e) {
      AppLogger.e('Error al obtener batch de ISAR: $e');
      throw CacheException('Error al obtener batch de ISAR: $e');
    }
  }

  @override
  Future<List<dynamic>> getUnsyncedBatches() async {
    try {
      final isarBatches = await _isar.isarInventoryBatchs
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${batches.length} batches no sincronizados encontrados');
      return batches;
    } catch (e) {
      AppLogger.e('Error al obtener batches no sincronizados de ISAR: $e');
      throw CacheException('Error al obtener batches no sincronizados: $e');
    }
  }

  @override
  Future<void> markBatchAsSynced(String tempId, String serverId) async {
    try {
      await _isar.writeTxn(() async {
        // Buscar el batch temporal
        final tempBatch = await _isar.isarInventoryBatchs
            .filter()
            .serverIdEqualTo(tempId)
            .findFirst();

        if (tempBatch != null) {
          // Actualizar con el ID del servidor y marcar como sincronizado
          tempBatch.serverId = serverId;
          tempBatch.isSynced = true;
          tempBatch.updatedAt = DateTime.now();
          tempBatch.lastSyncAt = DateTime.now();

          await _isar.isarInventoryBatchs.put(tempBatch);
        }
      });

      AppLogger.i('ISAR: Batch marcado como sincronizado: $tempId -> $serverId');
    } catch (e) {
      AppLogger.e('Error al marcar batch como sincronizado: $e');
      throw CacheException('Error al marcar batch como sincronizado: $e');
    }
  }

  @override
  Future<List<dynamic>> getExpiredBatches() async {
    try {
      final now = DateTime.now();

      final isarBatches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .expiryDateIsNotNull()
          .and()
          .expiryDateLessThan(now)
          .findAll();

      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${batches.length} batches vencidos encontrados');
      return batches;
    } catch (e) {
      AppLogger.e('Error al obtener batches vencidos de ISAR: $e');
      throw CacheException('Error al obtener batches vencidos: $e');
    }
  }

  @override
  Future<List<dynamic>> getNearExpiryBatches({int daysThreshold = 30}) async {
    try {
      final now = DateTime.now();
      final threshold = now.add(Duration(days: daysThreshold));

      final isarBatches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .expiryDateIsNotNull()
          .and()
          .expiryDateGreaterThan(now)
          .and()
          .expiryDateLessThan(threshold)
          .findAll();

      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${batches.length} batches próximos a vencer encontrados');
      return batches;
    } catch (e) {
      AppLogger.e('Error al obtener batches próximos a vencer: $e');
      throw CacheException('Error al obtener batches próximos a vencer: $e');
    }
  }

  @override
  Future<List<dynamic>> searchCachedBatches(String searchTerm) async {
    try {
      final lowerSearch = searchTerm.toLowerCase();

      // ISAR no soporta búsquedas complejas, hacemos búsqueda en memoria
      final allBatches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .findAll();

      final filtered = allBatches.where((batch) {
        return batch.batchNumber.toLowerCase().contains(lowerSearch) ||
               batch.productName.toLowerCase().contains(lowerSearch) ||
               batch.productSku.toLowerCase().contains(lowerSearch);
      }).toList();

      final batches = filtered.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${batches.length} batches encontrados para "$searchTerm"');
      return batches;
    } catch (e) {
      AppLogger.e('Error al buscar batches en ISAR: $e');
      throw CacheException('Error al buscar batches: $e');
    }
  }

  // ==================== BATCH MOVEMENT OPERATIONS ====================

  @override
  Future<void> cacheBatchMovements(List<dynamic> movements) async {
    try {
      await _isar.writeTxn(() async {
        for (final movement in movements) {
          BatchMovement movementEntity;

          if (movement is BatchMovement) {
            movementEntity = movement;
          } else {
            throw CacheException('Invalid batch movement type: ${movement.runtimeType}');
          }

          // Buscar existente
          IsarInventoryBatchMovement? existing = await _isar.isarInventoryBatchMovements
              .filter()
              .serverIdEqualTo(movementEntity.id)
              .findFirst();

          IsarInventoryBatchMovement isarMovement;

          if (existing != null) {
            isarMovement = IsarInventoryBatchMovement.fromEntity(movementEntity);
            isarMovement.id = existing.id;
            isarMovement.isSynced = true;
            isarMovement.lastSyncAt = DateTime.now();
          } else {
            isarMovement = IsarInventoryBatchMovement.fromEntity(movementEntity);
            isarMovement.isSynced = true;
            isarMovement.lastSyncAt = DateTime.now();
          }

          await _isar.isarInventoryBatchMovements.put(isarMovement);
        }
      });

      AppLogger.i('ISAR: ${movements.length} batch movements cacheados');
    } catch (e) {
      AppLogger.e('Error al cachear batch movements en ISAR: $e');
      throw CacheException('Error al cachear batch movements: $e');
    }
  }

  @override
  Future<void> cacheBatchMovement(dynamic movement) async {
    try {
      BatchMovement movementEntity;

      if (movement is BatchMovement) {
        movementEntity = movement;
      } else {
        throw CacheException('Invalid batch movement type: ${movement.runtimeType}');
      }

      await _isar.writeTxn(() async {
        IsarInventoryBatchMovement? existing = await _isar.isarInventoryBatchMovements
            .filter()
            .serverIdEqualTo(movementEntity.id)
            .findFirst();

        IsarInventoryBatchMovement isarMovement;

        if (existing != null) {
          isarMovement = IsarInventoryBatchMovement.fromEntity(movementEntity);
          isarMovement.id = existing.id;
          isarMovement.isSynced = true;
          isarMovement.lastSyncAt = DateTime.now();
        } else {
          isarMovement = IsarInventoryBatchMovement.fromEntity(movementEntity);
          isarMovement.isSynced = true;
          isarMovement.lastSyncAt = DateTime.now();
        }

        await _isar.isarInventoryBatchMovements.put(isarMovement);
      });

      AppLogger.i('ISAR: Batch movement cacheado exitosamente');
    } catch (e) {
      AppLogger.e('Error al cachear batch movement: $e');
      throw CacheException('Error al cachear batch movement: $e');
    }
  }

  @override
  Future<List<dynamic>> getCachedBatchMovements(String batchId) async {
    try {
      final isarMovements = await _isar.isarInventoryBatchMovements
          .filter()
          .batchIdEqualTo(batchId)
          .and()
          .deletedAtIsNull()
          .sortByMovementDateDesc()
          .findAll();

      final movements = isarMovements.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${movements.length} batch movements obtenidos para batch $batchId');
      return movements;
    } catch (e) {
      AppLogger.e('Error al obtener batch movements de ISAR: $e');
      throw CacheException('Error al obtener batch movements: $e');
    }
  }

  @override
  Future<List<dynamic>> getUnsyncedBatchMovements() async {
    try {
      final isarMovements = await _isar.isarInventoryBatchMovements
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      final movements = isarMovements.map((isar) => isar.toEntity()).toList();

      AppLogger.d('ISAR: ${movements.length} batch movements no sincronizados');
      return movements;
    } catch (e) {
      AppLogger.e('Error al obtener batch movements no sincronizados: $e');
      throw CacheException('Error al obtener batch movements no sincronizados: $e');
    }
  }

  @override
  Future<void> markBatchMovementAsSynced(String tempId, String serverId) async {
    try {
      await _isar.writeTxn(() async {
        final tempMovement = await _isar.isarInventoryBatchMovements
            .filter()
            .serverIdEqualTo(tempId)
            .findFirst();

        if (tempMovement != null) {
          tempMovement.serverId = serverId;
          tempMovement.isSynced = true;
          tempMovement.updatedAt = DateTime.now();
          tempMovement.lastSyncAt = DateTime.now();

          await _isar.isarInventoryBatchMovements.put(tempMovement);
        }
      });

      AppLogger.i('ISAR: Batch movement marcado como sincronizado: $tempId -> $serverId');
    } catch (e) {
      AppLogger.e('Error al marcar batch movement como sincronizado: $e');
      throw CacheException('Error al marcar batch movement como sincronizado: $e');
    }
  }

  // ==================== MOVEMENT OPERATIONS (EXISTING) ====================
  // Adaptados para usar ISAR en lugar de SecureStorage

  @override
  Future<PaginatedResult<InventoryMovementModel>?> getCachedMovements(
    InventoryMovementQueryParams params,
  ) async {
    try {
      // Obtener todos los movements de ISAR
      var query = _isar.isarInventoryMovements.filter().deletedAtIsNull();

      // Aplicar filtros
      if (params.productId != null) {
        query = query.and().productIdEqualTo(params.productId!);
      }

      if (params.warehouseId != null) {
        query = query.and().warehouseIdEqualTo(params.warehouseId!);
      }

      if (params.type != null) {
        query = query.and().typeEqualTo(_mapMovementTypeToIsar(params.type!));
      }

      if (params.status != null) {
        query = query.and().statusEqualTo(_mapMovementStatusToIsar(params.status!));
      }

      // Obtener resultados
      var movements = await query.findAll();

      // Aplicar búsqueda en memoria (ISAR no soporta LIKE)
      if (params.search != null && params.search!.isNotEmpty) {
        final searchLower = params.search!.toLowerCase();
        movements = movements.where((m) {
          return m.productName?.toLowerCase().contains(searchLower) == true ||
                 m.productSku?.toLowerCase().contains(searchLower) == true ||
                 m.notes?.toLowerCase().contains(searchLower) == true;
        }).toList();
      }

      // Aplicar filtros de fecha en memoria
      if (params.startDate != null) {
        movements = movements.where((m) =>
          m.movementDate.isAfter(params.startDate!) ||
          m.movementDate.isAtSameMomentAs(params.startDate!)
        ).toList();
      }

      if (params.endDate != null) {
        movements = movements.where((m) =>
          m.movementDate.isBefore(params.endDate!) ||
          m.movementDate.isAtSameMomentAs(params.endDate!)
        ).toList();
      }

      // Ordenar
      movements.sort((a, b) => b.movementDate.compareTo(a.movementDate));

      // Calcular paginación
      final totalItems = movements.length;
      final totalPages = (totalItems / params.limit).ceil();
      final offset = (params.page - 1) * params.limit;

      // Aplicar paginación
      final paginatedMovements = movements.skip(offset).take(params.limit).toList();

      // Convertir a models
      final models = paginatedMovements.map((isar) => _isarMovementToModel(isar)).toList();

      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      AppLogger.d('ISAR: ${models.length} movements obtenidos (página ${params.page} de $totalPages)');
      return PaginatedResult(data: models, meta: meta);
    } catch (e) {
      AppLogger.e('Error al obtener movements de ISAR: $e');
      return null;
    }
  }

  @override
  Future<void> cacheMovements(
    InventoryMovementQueryParams params,
    PaginatedResult<InventoryMovementModel> movements,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final movement in movements.data) {
          IsarInventoryMovement? existing = await _isar.isarInventoryMovements
              .filter()
              .serverIdEqualTo(movement.id)
              .findFirst();

          IsarInventoryMovement isarMovement;

          if (existing != null) {
            existing.updateFromModel(movement);
            isarMovement = existing;
          } else {
            isarMovement = IsarInventoryMovement.fromModel(movement);
          }

          isarMovement.isSynced = true;
          isarMovement.lastSyncAt = DateTime.now();

          await _isar.isarInventoryMovements.put(isarMovement);
        }
      });

      AppLogger.i('ISAR: ${movements.data.length} movements cacheados');
    } catch (e) {
      AppLogger.e('Error al cachear movements en ISAR: $e');
      // Fallar silenciosamente
    }
  }

  @override
  Future<InventoryMovementModel?> getCachedMovementById(String id) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarMovement == null) {
        AppLogger.d('ISAR: Movement con ID $id no encontrado');
        return null;
      }

      return _isarMovementToModel(isarMovement);
    } catch (e) {
      AppLogger.e('Error al obtener movement de ISAR: $e');
      return null;
    }
  }

  @override
  Future<void> cacheMovement(InventoryMovementModel movement) async {
    try {
      await _isar.writeTxn(() async {
        IsarInventoryMovement? existing = await _isar.isarInventoryMovements
            .filter()
            .serverIdEqualTo(movement.id)
            .findFirst();

        IsarInventoryMovement isarMovement;

        if (existing != null) {
          existing.updateFromModel(movement);
          isarMovement = existing;
        } else {
          isarMovement = IsarInventoryMovement.fromModel(movement);
        }

        isarMovement.isSynced = true;
        isarMovement.lastSyncAt = DateTime.now();

        await _isar.isarInventoryMovements.put(isarMovement);
      });

      AppLogger.i('ISAR: Movement ${movement.id} cacheado exitosamente');
    } catch (e) {
      AppLogger.e('Error al cachear movement en ISAR: $e');
      // Fallar silenciosamente
    }
  }

  @override
  Future<List<InventoryMovementModel>> searchCachedMovements(
    SearchInventoryMovementsParams params,
  ) async {
    try {
      final searchLower = params.searchTerm.toLowerCase();

      final allMovements = await _isar.isarInventoryMovements
          .filter()
          .deletedAtIsNull()
          .findAll();

      final filtered = allMovements.where((movement) {
        return movement.productName?.toLowerCase().contains(searchLower) == true ||
               movement.productSku?.toLowerCase().contains(searchLower) == true ||
               movement.notes?.toLowerCase().contains(searchLower) == true;
      }).toList();

      // Limitar resultados
      final limited = filtered.take(params.limit ?? 20).toList();

      final models = limited.map((isar) => _isarMovementToModel(isar)).toList();

      AppLogger.d('ISAR: ${models.length} movements encontrados para "${params.searchTerm}"');
      return models;
    } catch (e) {
      AppLogger.e('Error al buscar movements en ISAR: $e');
      return [];
    }
  }

  // ==================== BALANCE OPERATIONS ====================
  // Calculados dinámicamente desde los batches en ISAR

  @override
  Future<PaginatedResult<InventoryBalanceModel>?> getCachedBalances(
    InventoryBalanceQueryParams params,
  ) async {
    // 1. Intentar calcular dinámicamente desde batches en ISAR
    try {
      final result = await _computeBalancesFromBatches(params);
      if (result != null) return result;
    } catch (e) {
      AppLogger.e('Error al calcular balances desde ISAR batches: $e');
    }

    // 2. Fallback: leer balances cacheados en SecureStorage
    try {
      final cacheKey = _generateBalancesCacheKey(params);
      final cachedData = await _secureStorage.read(key: cacheKey);
      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        final rawData = json['data'];
        if (rawData is List && rawData.isNotEmpty) {
          final data = rawData
              .whereType<Map<String, dynamic>>()
              .map((item) => InventoryBalanceModel.fromJson(item))
              .toList();
          final meta = json['meta'] is Map<String, dynamic>
              ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
              : PaginationMeta.empty();
          AppLogger.i('📦 Balances leídos desde SecureStorage fallback: ${data.length} items');
          return PaginatedResult(data: data, meta: meta);
        }
      }
    } catch (e) {
      AppLogger.e('Error leyendo balances de SecureStorage fallback: $e');
    }

    return null;
  }

  /// Calcula balances dinámicamente desde los batches almacenados en ISAR
  Future<PaginatedResult<InventoryBalanceModel>?> _computeBalancesFromBatches(
    InventoryBalanceQueryParams params,
  ) async {
    // Obtener todos los batches activos
    var batchQuery = _isar.isarInventoryBatchs.filter().deletedAtIsNull();

    if (params.warehouseId != null) {
      batchQuery = batchQuery.and().warehouseIdEqualTo(params.warehouseId!);
    }

    final batches = await batchQuery.findAll();

    if (batches.isEmpty) {
      AppLogger.d('ISAR: No hay batches en ISAR para calcular balances (warehouseId: ${params.warehouseId})');
      return null;
    }

    AppLogger.d('ISAR: Calculando balances desde ${batches.length} batches (warehouseId: ${params.warehouseId})');

    // Agrupar por producto para calcular balances
    final balanceMap = <String, _ProductBalanceAccumulator>{};

    for (final batch in batches) {
      final key = batch.productId;
      if (!balanceMap.containsKey(key)) {
        balanceMap[key] = _ProductBalanceAccumulator(
          productId: batch.productId,
          productName: batch.productName,
          productSku: batch.productSku,
          categoryName: '', // No disponible en batch
          warehouseId: batch.warehouseId,
        );
      }

      final acc = balanceMap[key]!;
      acc.totalQuantity += batch.currentQuantity;
      acc.totalCost += batch.currentQuantity * batch.unitCost;
    }

    // Identificar productos con batches expirados (para filtro expired)
    final now = DateTime.now();
    final expiredProductIds = <String>{};
    for (final batch in batches) {
      if (batch.expiryDate != null && batch.expiryDate!.isBefore(now)) {
        expiredProductIds.add(batch.productId);
      }
    }

    // Convertir a modelos
    var balancesList = balanceMap.values.map((acc) {
      final avgCost = acc.totalQuantity > 0 ? acc.totalCost / acc.totalQuantity : 0.0;
      return InventoryBalanceModel(
        productId: acc.productId,
        productName: acc.productName,
        productSku: acc.productSku,
        categoryName: acc.categoryName,
        totalQuantity: acc.totalQuantity,
        minStock: 10, // Default - no disponible en batch
        averageCost: avgCost,
        totalValue: acc.totalCost,
        isLowStock: acc.totalQuantity > 0 && acc.totalQuantity <= 10,
        isOutOfStock: acc.totalQuantity <= 0,
        warehouseId: acc.warehouseId,
      );
    }).toList();

    // Aplicar filtro de búsqueda
    if (params.search != null && params.search!.isNotEmpty) {
      final searchLower = params.search!.toLowerCase();
      balancesList = balancesList.where((b) =>
        b.productName.toLowerCase().contains(searchLower) ||
        b.productSku.toLowerCase().contains(searchLower)
      ).toList();
    }

    // Aplicar filtros de estado
    if (params.lowStock == true) {
      balancesList = balancesList.where((b) => b.isLowStock).toList();
    }

    if (params.outOfStock == true) {
      balancesList = balancesList.where((b) => b.isOutOfStock).toList();
    }

    if (params.expired == true) {
      balancesList = balancesList.where((b) => expiredProductIds.contains(b.productId)).toList();
    }

    // Aplicar ordenamiento
    switch (params.sortBy) {
      case 'productName':
        balancesList.sort((a, b) => params.sortOrder == 'asc'
            ? a.productName.compareTo(b.productName)
            : b.productName.compareTo(a.productName));
        break;
      case 'totalQuantity':
        balancesList.sort((a, b) => params.sortOrder == 'asc'
            ? a.totalQuantity.compareTo(b.totalQuantity)
            : b.totalQuantity.compareTo(a.totalQuantity));
        break;
      case 'totalValue':
        balancesList.sort((a, b) => params.sortOrder == 'asc'
            ? a.totalValue.compareTo(b.totalValue)
            : b.totalValue.compareTo(a.totalValue));
        break;
      default:
        balancesList.sort((a, b) => a.productName.compareTo(b.productName));
    }

    // Calcular paginación
    final totalItems = balancesList.length;
    final totalPages = totalItems > 0 ? (totalItems / params.limit).ceil() : 1;
    final offset = (params.page - 1) * params.limit;
    final paginatedList = balancesList.skip(offset).take(params.limit).toList();

    final meta = PaginationMeta(
      page: params.page,
      limit: params.limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: params.page < totalPages,
      hasPreviousPage: params.page > 1,
    );

    AppLogger.i('ISAR: Balances calculados desde ${batches.length} batches: ${paginatedList.length} items (${totalItems} total)');
    return PaginatedResult(data: paginatedList, meta: meta);
  }

  @override
  Future<void> cacheBalances(
    InventoryBalanceQueryParams params,
    PaginatedResult<InventoryBalanceModel> balances,
  ) async {
    // Guardar en SecureStorage como fallback para cuando no hay batches en ISAR
    try {
      final cacheKey = _generateBalancesCacheKey(params);
      final cacheData = {
        'data': balances.data.map((b) => b.toJson()).toList(),
        'meta': balances.meta.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (_) {
      // SecureStorage puede fallar en macOS (-34018), no es crítico
    }
  }

  /// Genera cache key compatible con el formato SecureStorage
  String _generateBalancesCacheKey(InventoryBalanceQueryParams params) {
    final keyParts = <String>[
      'inventory_balances_cache',
      'page_${params.page}',
      'limit_${params.limit}',
      'sort_${params.sortBy}_${params.sortOrder}',
    ];
    if (params.search != null && params.search!.isNotEmpty) {
      keyParts.add('search_${params.search!.toLowerCase().replaceAll(' ', '_')}');
    }
    if (params.categoryId != null) keyParts.add('category_${params.categoryId}');
    if (params.warehouseId != null) keyParts.add('warehouse_${params.warehouseId}');
    if (params.lowStock == true) keyParts.add('low_stock');
    if (params.outOfStock == true) keyParts.add('out_of_stock');
    if (params.nearExpiry == true) keyParts.add('near_expiry');
    if (params.expired == true) keyParts.add('expired');
    return keyParts.join('_');
  }

  @override
  Future<InventoryBalanceModel?> getCachedBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      var query = _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .productIdEqualTo(productId);

      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }

      final batches = await query.findAll();

      if (batches.isEmpty) {
        return null;
      }

      // Calcular balance agregado
      int totalQuantity = 0;
      double totalCost = 0;
      String productName = '';
      String productSku = '';

      for (final batch in batches) {
        totalQuantity += batch.currentQuantity;
        totalCost += batch.currentQuantity * batch.unitCost;
        productName = batch.productName;
        productSku = batch.productSku;
      }

      final avgCost = totalQuantity > 0 ? totalCost / totalQuantity : 0.0;

      return InventoryBalanceModel(
        productId: productId,
        productName: productName,
        productSku: productSku,
        categoryName: '',
        totalQuantity: totalQuantity,
        minStock: 10,
        averageCost: avgCost,
        totalValue: totalCost,
        isLowStock: totalQuantity < 10,
        isOutOfStock: totalQuantity <= 0,
        warehouseId: warehouseId,
      );
    } catch (e) {
      AppLogger.e('Error al obtener balance por producto: $e');
      return null;
    }
  }

  @override
  Future<void> cacheBalance(InventoryBalanceModel balance) async {
    // Los balances se calculan dinámicamente desde batches
    // No es necesario cachearlos por separado
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedLowStockProducts({
    String? warehouseId,
  }) async {
    try {
      final result = await getCachedBalances(
        InventoryBalanceQueryParams(
          warehouseId: warehouseId,
          lowStock: true,
          page: 1,
          limit: 100, // Traer todos los de stock bajo
        ),
      );

      return result?.data ?? [];
    } catch (e) {
      AppLogger.e('Error al obtener productos con stock bajo: $e');
      return [];
    }
  }

  @override
  Future<void> cacheLowStockProducts(
    List<InventoryBalanceModel> balances, {
    String? warehouseId,
  }) async {
    // Los balances se calculan dinámicamente desde batches
  }

  // ==================== STATS OPERATIONS ====================

  @override
  Future<InventoryStatsModel?> getCachedStats(
    InventoryStatsParams params,
  ) async {
    try {
      // Contar productos únicos desde batches
      final allBatches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .findAll();

      final uniqueProducts = allBatches.map((b) => b.productId).toSet();

      // Contar batches activos
      final activeBatches = allBatches.where((b) => b.currentQuantity > 0).length;

      // Contar movimientos
      var movementQuery = _isar.isarInventoryMovements.filter().deletedAtIsNull();
      if (params.warehouseId != null) {
        movementQuery = movementQuery.and().warehouseIdEqualTo(params.warehouseId!);
      }
      final movements = await movementQuery.findAll();

      // Calcular valor total del inventario
      double totalValue = 0;
      for (final batch in allBatches) {
        totalValue += batch.currentQuantity * batch.unitCost;
      }

      // Agrupar movimientos por tipo
      final movementsByType = <String, dynamic>{};
      int inboundCount = 0;
      int outboundCount = 0;
      int adjustmentCount = 0;
      int transferCount = 0;

      for (final movement in movements) {
        switch (movement.type) {
          case IsarInventoryMovementType.inbound:
            inboundCount++;
            break;
          case IsarInventoryMovementType.outbound:
            outboundCount++;
            break;
          case IsarInventoryMovementType.adjustment:
            adjustmentCount++;
            break;
          case IsarInventoryMovementType.transfer:
          case IsarInventoryMovementType.transferIn:
          case IsarInventoryMovementType.transferOut:
            transferCount++;
            break;
        }
      }

      // Movimientos de hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayMovements = movements.where((m) => m.movementDate.isAfter(startOfDay)).length;

      // Productos con stock bajo
      final lowStockProducts = await getCachedLowStockProducts(
        warehouseId: params.warehouseId,
      );

      // Batches expirados
      final now = DateTime.now();
      final expiredBatches = allBatches.where((b) =>
        b.expiryDate != null && b.expiryDate!.isBefore(now)
      ).length;

      movementsByType['inbound'] = inboundCount;
      movementsByType['outbound'] = outboundCount;
      movementsByType['adjustment'] = adjustmentCount;
      movementsByType['transfer'] = transferCount;
      movementsByType['today'] = todayMovements;
      movementsByType['lowStock'] = lowStockProducts.length;
      movementsByType['expired'] = expiredBatches;

      return InventoryStatsModel(
        totalProducts: uniqueProducts.length,
        totalBatches: activeBatches,
        totalMovements: movements.length,
        totalValue: totalValue,
        movementsByType: movementsByType,
      );
    } catch (e) {
      AppLogger.e('Error al calcular estadísticas desde ISAR: $e');
      return null;
    }
  }

  @override
  Future<void> cacheStats(
    InventoryStatsParams params,
    InventoryStatsModel stats,
  ) async {
    // Las estadísticas se calculan dinámicamente
    // No es necesario cachearlas por separado
  }

  // ==================== WAREHOUSE CACHE ====================
  // Warehouses use SecureStorage + in-memory fallback (no ISAR model)
  // SecureStorage puede fallar en macOS con error -34018, por eso usamos memory fallback

  static const String _warehousesCacheKey = 'inventory_warehouses_cache';
  static const _secureStorage = FlutterSecureStorage();
  // In-memory fallback para cuando SecureStorage falla
  static List<WarehouseModel>? _warehousesMemoryCache;

  /// Método estático para que FullSyncService pueda actualizar el cache en memoria
  /// sin necesitar una instancia del datasource.
  static void setWarehousesMemoryCache(List<WarehouseModel> warehouses) {
    _warehousesMemoryCache = List.from(warehouses);
    AppLogger.d('🏭 Warehouses actualizados en memory cache estático: ${warehouses.length}');
  }

  /// Getter estático para leer warehouses desde memory cache (usado por PO detail offline)
  static List<WarehouseModel>? getWarehousesMemoryCache() => _warehousesMemoryCache;

  @override
  Future<void> cacheWarehouses(List<WarehouseModel> warehouses) async {
    // Siempre guardar en memoria (nunca falla)
    _warehousesMemoryCache = List.from(warehouses);
    AppLogger.d('🏭 Warehouses cacheados en memoria: ${warehouses.length}');

    // Persistir en SharedPreferences (más confiable que SecureStorage en macOS)
    try {
      final cacheData = {
        'data': warehouses.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_warehousesCacheKey, jsonEncode(cacheData));
      AppLogger.d('🏭 Warehouses persistidos en SharedPreferences: ${warehouses.length}');
    } catch (e) {
      AppLogger.w('⚠️ SharedPreferences falló para warehouses (in-memory OK): $e');
    }
  }

  @override
  Future<List<WarehouseModel>> getCachedWarehouses() async {
    // 1. Memory cache (más rápido)
    if (_warehousesMemoryCache != null && _warehousesMemoryCache!.isNotEmpty) {
      AppLogger.d('🏭 Warehouses leídos de memory cache: ${_warehousesMemoryCache!.length}');
      return _warehousesMemoryCache!;
    }

    // 2. SharedPreferences (persiste entre sesiones, confiable en macOS)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_warehousesCacheKey);
      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        final rawData = json['data'];
        if (rawData is List && rawData.isNotEmpty) {
          final warehouses = rawData
              .whereType<Map<String, dynamic>>()
              .map((item) => WarehouseModel.fromJson(item))
              .toList();
          if (warehouses.isNotEmpty) {
            _warehousesMemoryCache = warehouses; // Actualizar memory cache
            AppLogger.d('🏭 Warehouses leídos de SharedPreferences: ${warehouses.length}');
            return warehouses;
          }
        }
      }
    } catch (e) {
      AppLogger.w('⚠️ Error leyendo warehouses de SharedPreferences: $e');
    }

    // 3. Fallback a SecureStorage legacy (por si hay datos guardados antes del cambio)
    try {
      final cachedData = await _secureStorage.read(key: _warehousesCacheKey);
      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        final rawData = json['data'];
        if (rawData is List && rawData.isNotEmpty) {
          final warehouses = rawData
              .whereType<Map<String, dynamic>>()
              .map((item) => WarehouseModel.fromJson(item))
              .toList();
          if (warehouses.isNotEmpty) {
            _warehousesMemoryCache = warehouses;
            AppLogger.d('🏭 Warehouses leídos de SecureStorage legacy: ${warehouses.length}');
            return warehouses;
          }
        }
      }
    } catch (e) {
      AppLogger.w('⚠️ SecureStorage legacy falló para warehouses: $e');
    }

    AppLogger.w('🏭 No hay warehouses en ningún cache');
    return [];
  }

  @override
  Future<WarehouseModel?> getCachedWarehouseById(String id) async {
    try {
      final warehouses = await getCachedWarehouses();
      for (final w in warehouses) {
        if (w.id == id) return w;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearWarehousesCache() async {
    _warehousesMemoryCache = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_warehousesCacheKey);
    } catch (e) {
      AppLogger.e('Error al limpiar cache de warehouses: $e');
    }
    try {
      await _secureStorage.delete(key: _warehousesCacheKey);
    } catch (_) {}
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
      await _secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      AppLogger.e('Error al cachear out of stock products: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedOutOfStockProducts({String? warehouseId}) async {
    try {
      // Compute from ISAR batches
      final result = await getCachedBalances(
        InventoryBalanceQueryParams(outOfStock: true, page: 1, limit: 100, warehouseId: warehouseId),
      );
      return result?.data ?? [];
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
      await _secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      AppLogger.e('Error al cachear expired products: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedExpiredProducts({String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_expired_${warehouseId ?? 'all'}';
      final cachedData = await _secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];
      final json = jsonDecode(cachedData);
      final rawData = json['data'];
      if (rawData is! List) return [];
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => InventoryBalanceModel.fromJson(item))
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
      await _secureStorage.write(key: cacheKey, value: jsonEncode(cacheData));
    } catch (e) {
      AppLogger.e('Error al cachear near expiry products: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getCachedNearExpiryProducts({String? warehouseId}) async {
    try {
      final cacheKey = 'inventory_near_expiry_${warehouseId ?? 'all'}';
      final cachedData = await _secureStorage.read(key: cacheKey);
      if (cachedData == null) return [];
      final json = jsonDecode(cachedData);
      final rawData = json['data'];
      if (rawData is! List) return [];
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => InventoryBalanceModel.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  @override
  Future<void> clearMovementsCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.clear();
      });
      AppLogger.d('ISAR: Cache de movements limpiado');
    } catch (e) {
      AppLogger.e('Error al limpiar cache de movements: $e');
    }
  }

  @override
  Future<void> clearBalancesCache() async {
    // Balances no se cachean en ISAR por ahora
    AppLogger.d('ISAR: Balances no se cachean localmente');
  }

  @override
  Future<void> clearStatsCache() async {
    // Stats no se cachean en ISAR por ahora
    AppLogger.d('ISAR: Stats no se cachean localmente');
  }

  @override
  Future<void> clearBatchesCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarInventoryBatchs.clear();
        await _isar.isarInventoryBatchMovements.clear();
      });
      AppLogger.d('ISAR: Cache de batches y batch movements limpiado');
    } catch (e) {
      AppLogger.e('Error al limpiar cache de batches: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    await clearMovementsCache();
    await clearBatchesCache();
    await clearBalancesCache();
    await clearStatsCache();
    await clearWarehousesCache();
  }

  @override
  Future<bool> isCacheValid(String cacheKey) async {
    // ISAR no usa cacheKeys con timestamps como SecureStorage
    // La validez se maneja por lastSyncAt en cada entidad
    return true;
  }

  // ==================== HELPER METHODS ====================

  /// Convertir IsarInventoryMovement a InventoryMovementModel
  InventoryMovementModel _isarMovementToModel(IsarInventoryMovement isar) {
    return InventoryMovementModel(
      id: isar.serverId,
      productId: isar.productId,
      productName: isar.productName,
      productSku: isar.productSku,
      quantity: isar.quantity.toString(),
      typeString: _mapIsarMovementTypeToString(isar.type),
      reasonString: _mapIsarMovementReasonToString(isar.reason),
      statusString: _mapIsarMovementStatusToString(isar.status),
      movementDate: isar.movementDate,
      movementNumber: isar.serverId, // Use serverId as movement number for offline
      notes: isar.notes,
      warehouseId: isar.warehouseId,
      warehouseName: isar.warehouseName,
      userId: isar.userId,
      userName: isar.userName,
      unitCost: isar.unitCost.toString(),
      totalCost: isar.totalCost.toString(),
      organizationId: 'offline', // Placeholder for offline movements
      metadata: isar.metadataJson != null ? jsonDecode(isar.metadataJson!) : null,
      createdAt: isar.createdAt,
      updatedAt: isar.updatedAt,
    );
  }

  // ==================== ENUM MAPPERS ====================

  /// Movement Type mappers
  IsarInventoryMovementType _mapMovementTypeToIsar(InventoryMovementType type) {
    switch (type) {
      case InventoryMovementType.inbound:
        return IsarInventoryMovementType.inbound;
      case InventoryMovementType.outbound:
        return IsarInventoryMovementType.outbound;
      case InventoryMovementType.adjustment:
        return IsarInventoryMovementType.adjustment;
      case InventoryMovementType.transfer:
        return IsarInventoryMovementType.transfer;
      case InventoryMovementType.transferIn:
        return IsarInventoryMovementType.transferIn;
      case InventoryMovementType.transferOut:
        return IsarInventoryMovementType.transferOut;
    }
  }

  String _mapIsarMovementTypeToString(IsarInventoryMovementType type) {
    switch (type) {
      case IsarInventoryMovementType.inbound:
        return 'inbound';
      case IsarInventoryMovementType.outbound:
        return 'outbound';
      case IsarInventoryMovementType.adjustment:
        return 'adjustment';
      case IsarInventoryMovementType.transfer:
        return 'transfer';
      case IsarInventoryMovementType.transferIn:
        return 'transferIn';
      case IsarInventoryMovementType.transferOut:
        return 'transferOut';
    }
  }

  /// Movement Status mappers
  IsarInventoryMovementStatus _mapMovementStatusToIsar(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return IsarInventoryMovementStatus.pending;
      case InventoryMovementStatus.confirmed:
        return IsarInventoryMovementStatus.confirmed;
      case InventoryMovementStatus.cancelled:
        return IsarInventoryMovementStatus.cancelled;
    }
  }

  String _mapIsarMovementStatusToString(IsarInventoryMovementStatus status) {
    switch (status) {
      case IsarInventoryMovementStatus.pending:
        return 'pending';
      case IsarInventoryMovementStatus.confirmed:
        return 'confirmed';
      case IsarInventoryMovementStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Movement Reason mappers
  IsarInventoryMovementReason _mapMovementReasonToIsar(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.purchase:
        return IsarInventoryMovementReason.purchase;
      case InventoryMovementReason.sale:
        return IsarInventoryMovementReason.sale;
      case InventoryMovementReason.adjustment:
        return IsarInventoryMovementReason.adjustment;
      case InventoryMovementReason.damage:
        return IsarInventoryMovementReason.damage;
      case InventoryMovementReason.loss:
        return IsarInventoryMovementReason.loss;
      case InventoryMovementReason.transfer:
        return IsarInventoryMovementReason.transfer;
      case InventoryMovementReason.return_:
        return IsarInventoryMovementReason.returnGoods;
      case InventoryMovementReason.expiration:
        return IsarInventoryMovementReason.expiration;
    }
  }

  String _mapIsarMovementReasonToString(IsarInventoryMovementReason reason) {
    switch (reason) {
      case IsarInventoryMovementReason.purchase:
        return 'purchase';
      case IsarInventoryMovementReason.sale:
        return 'sale';
      case IsarInventoryMovementReason.adjustment:
        return 'adjustment';
      case IsarInventoryMovementReason.damage:
        return 'damage';
      case IsarInventoryMovementReason.loss:
        return 'loss';
      case IsarInventoryMovementReason.transfer:
        return 'transfer';
      case IsarInventoryMovementReason.returnGoods:
        return 'return';
      case IsarInventoryMovementReason.expiration:
        return 'expiration';
    }
  }

  // ==================== ADDITIONAL HELPER METHODS ====================

  /// Verificar si hay datos offline de batches
  Future<bool> hasOfflineBatchData() async {
    try {
      final count = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .count();

      AppLogger.d('ISAR: $count batches disponibles offline');
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si hay datos offline de movements
  Future<bool> hasOfflineMovementData() async {
    try {
      final count = await _isar.isarInventoryMovements
          .filter()
          .deletedAtIsNull()
          .count();

      AppLogger.d('ISAR: $count movements disponibles offline');
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Obtener timestamp de última sincronización de batches
  Future<DateTime?> getLastBatchSyncTime() async {
    try {
      final batch = await _isar.isarInventoryBatchs
          .filter()
          .lastSyncAtIsNotNull()
          .sortByLastSyncAtDesc()
          .findFirst();

      return batch?.lastSyncAt;
    } catch (e) {
      return null;
    }
  }

  /// Obtener timestamp de última sincronización de movements
  Future<DateTime?> getLastMovementSyncTime() async {
    try {
      final movement = await _isar.isarInventoryMovements
          .filter()
          .lastSyncAtIsNotNull()
          .sortByLastSyncAtDesc()
          .findFirst();

      return movement?.lastSyncAt;
    } catch (e) {
      return null;
    }
  }
}

/// Helper class para acumular datos de balance por producto
class _ProductBalanceAccumulator {
  final String productId;
  final String productName;
  final String productSku;
  final String categoryName;
  final String? warehouseId;
  int totalQuantity = 0;
  double totalCost = 0;

  _ProductBalanceAccumulator({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.categoryName,
    this.warehouseId,
  });
}
