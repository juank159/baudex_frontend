import 'dart:convert';
// lib/features/inventory/data/repositories/inventory_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/entities/warehouse_with_stats.dart';
import '../../domain/entities/kardex_report.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../datasources/inventory_local_datasource.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_balance_model.dart';
import '../models/inventory_batch_model.dart';
import '../models/warehouse_model.dart';
import '../models/isar/isar_inventory_movement.dart';
import '../models/isar/isar_inventory_batch.dart';
import '../../../../features/products/data/models/isar/isar_product.dart';
import '../../../../app/data/local/local_first.dart';
import 'inventory_offline_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ==================== LECTURA LOCAL-FIRST ====================

  InventoryOfflineRepository get _localInventory =>
      Get.isRegistered<InventoryOfflineRepository>() ? Get.find<InventoryOfflineRepository>() : InventoryOfflineRepository();

  Future<bool> _batchesReady() => localCollectionReady(
      (IsarDatabase.instance.database as Isar).isarInventoryBatchs);

  Future<bool> _movementsReady() => localCollectionReady(
      (IsarDatabase.instance.database as Isar).isarInventoryMovements);

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getMovements(
    InventoryMovementQueryParams params,
  ) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<core.PaginatedResult<InventoryMovement>>(
      hasLocalData: () => _movementsReady(),
      read: () => _localInventory.getMovements(params),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteMovements = await remoteDataSource.getMovements(params);
        // Cache successful result
        await localDataSource.cacheMovements(params, remoteMovements);
        return Right(
          core.PaginatedResult(
            data:
                remoteMovements.data.map((model) => model.toEntity()).toList(),
            meta: remoteMovements.meta,
          ),
        );
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getMovements: ${e.message} - Usando cache...');
        return _getMovementsFromCache(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getMovements: ${e.message} - Usando cache...');
        return _getMovementsFromCache(params);
      } catch (e) {
        AppLogger.e(' Error inesperado en getMovements: $e - Usando cache...');
        return _getMovementsFromCache(params);
      }
    } else {
      // Sin conexión, intentar obtener desde cache
      return _getMovementsFromCache(params);
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> getMovementById(String id) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<InventoryMovement>(
      hasLocalData: () => _movementsReady(),
      read: () => _localInventory.getMovementById(id),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteMovement = await remoteDataSource.getMovementById(id);
        // Cache successful result
        await localDataSource.cacheMovement(remoteMovement);
        return Right(remoteMovement.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getMovementById: ${e.message} - Usando cache...');
        return _getMovementFromCache(id);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getMovementById: ${e.message} - Usando cache...');
        return _getMovementFromCache(id);
      } catch (e) {
        AppLogger.e(' Error inesperado en getMovementById: $e - Usando cache...');
        return _getMovementFromCache(id);
      }
    } else {
      // Sin conexión, ir directo al cache
      return _getMovementFromCache(id);
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, InventoryMovement>> createMovement(
    CreateInventoryMovementParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final request = CreateInventoryMovementRequest.fromParams(params);
        final movement = await remoteDataSource.createMovement(request);

        // Cache the new movement
        await localDataSource.cacheMovement(movement);

        // Clear movements cache to force refresh on next fetch
        await localDataSource.clearMovementsCache();

        return Right(movement.toEntity());
      } on ServerException catch (e) {
        // Errores de negocio (400, 409, 422) NO deben crear offline
        final code = e.statusCode ?? 0;
        if (code == 409 || code == 400 || code == 422) {
          AppLogger.w(' Error de negocio (HTTP $code) al crear movimiento: ${e.message}');
          return Left(ServerFailure(e.message));
        }
        AppLogger.w(' ServerException (HTTP $code) al crear movimiento: ${e.message} - Creando offline...');
        return _createMovementOffline(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException al crear movimiento: ${e.message} - Creando offline...');
        return _createMovementOffline(params);
      } catch (e) {
        AppLogger.e(' Error inesperado al crear movimiento: $e - Creando offline...');
        return _createMovementOffline(params);
      }
    } else {
      // Sin conexión, crear movimiento offline
      return _createMovementOffline(params);
    }
  }

  /// Crear movimiento offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, InventoryMovement>> _createMovementOffline(
    CreateInventoryMovementParams params,
  ) async {
    AppLogger.d(' InventoryRepository: Creating movement offline');
    try {
      final now = DateTime.now();
      final tempId = 'movement_offline_${now.millisecondsSinceEpoch}_${params.productId.hashCode}';

      // Note: productName, productSku, warehouseName, userId, userName will be filled when synced
      // params doesn't have unitPrice, only unitCost exists
      final tempMovement = InventoryMovement(
        id: tempId,
        productId: params.productId,
        productName: '',  // Will be filled from server when synced (required String)
        productSku: '',  // Will be filled from server when synced (required String)
        type: params.type,
        status: InventoryMovementStatus.pending,
        reason: params.reason,
        quantity: params.quantity,
        unitCost: params.unitCost,
        totalCost: params.unitCost * params.quantity,
        unitPrice: null,  // Only unitCost exists in params
        totalPrice: null,
        lotNumber: params.lotNumber,
        expiryDate: params.expiryDate,
        warehouseId: params.warehouseId,
        warehouseName: null,  // Will be filled from server when synced
        referenceId: params.referenceId,
        referenceType: params.referenceType,
        notes: params.notes,
        userId: null,  // Will be filled from server when synced
        userName: null,  // Will be filled from server when synced
        metadata: null,
        movementDate: params.movementDate ?? now,
        createdAt: now,
        updatedAt: now,
      );

      // Cache localmente
      await localDataSource.cacheMovement(InventoryMovementModel.fromEntity(tempMovement));

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'productId': params.productId,
            'type': params.type.backendValue,
            'reason': params.reason.name,
            'quantity': params.quantity,
            'unitCost': params.unitCost,
            'lotNumber': params.lotNumber,
            'expiryDate': params.expiryDate?.toIso8601String(),
            'warehouseId': params.warehouseId,
            'referenceId': params.referenceId,
            'referenceType': params.referenceType,
            'notes': params.notes,
            'movementDate': params.movementDate?.toIso8601String(),
          },
          priority: 1,
        );
        AppLogger.d(' InventoryRepository: Operación agregada a cola');
      } catch (e) {
        AppLogger.w(' Error agregando a cola: $e');
      }

      // ✅ Para movimientos INBOUND (ej: recepción de PO), crear batch local en ISAR
      // Esto es CRÍTICO para que FIFO funcione offline con el stock recién recibido
      if (params.type == InventoryMovementType.inbound) {
        try {
          await _createLocalBatchForInboundMovement(params, tempId, now);
        } catch (e) {
          AppLogger.w(' Error creando batch local para inbound: $e');
        }
      }

      AppLogger.i(' Movement created offline successfully');
      return Right(tempMovement);
    } catch (e) {
      AppLogger.e(' Error creating movement offline: $e');
      return Left(CacheFailure('Error al crear movimiento offline: $e'));
    }
  }

  /// Crear batch ISAR local cuando se recibe un movimiento inbound offline (ej: recepción de PO)
  Future<void> _createLocalBatchForInboundMovement(
    CreateInventoryMovementParams params,
    String movementTempId,
    DateTime now,
  ) async {
    final isar = IsarDatabase.instance.database;
    final qty = params.quantity;
    final unitCost = params.unitCost;

    // Obtener nombre y SKU del producto desde ISAR
    String productName = '';
    String productSku = '';
    try {
      final isarProduct = await isar.isarProducts
          .filter()
          .serverIdEqualTo(params.productId)
          .findFirst();
      if (isarProduct != null) {
        productName = isarProduct.name;
        productSku = isarProduct.sku;
      }
    } catch (e) {
      AppLogger.w(' No se pudo obtener producto para batch: $e');
    }

    // Generar batch number local
    final batchTempId = 'batch_offline_${now.millisecondsSinceEpoch}_${params.productId.hashCode}';
    final batchNumber = 'BATCH-OFFLINE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';

    final isarBatch = IsarInventoryBatch.create(
      serverId: batchTempId,
      productId: params.productId,
      productName: productName,
      productSku: productSku,
      batchNumber: batchNumber,
      originalQuantity: qty,
      currentQuantity: qty,
      consumedQuantity: 0,
      unitCost: unitCost,
      totalCost: unitCost * qty,
      entryDate: params.movementDate ?? now,
      expiryDate: params.expiryDate,
      status: IsarInventoryBatchStatus.active,
      purchaseOrderId: params.referenceType == 'purchase_order' ? params.referenceId : null,
      warehouseId: params.warehouseId,
      notes: params.notes,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await isar.writeTxn(() async {
      await isar.isarInventoryBatchs.putByServerId(isarBatch);
    });

    AppLogger.i(
      ' Batch ISAR creado offline: $batchNumber (${qty}x \$${unitCost}) para producto ${params.productId}',
    );

    // ✅ Actualizar stock del producto en ISAR
    try {
      final isarProduct = await isar.isarProducts
          .filter()
          .serverIdEqualTo(params.productId)
          .findFirst();
      if (isarProduct != null) {
        isarProduct.stock = isarProduct.stock + qty;
        isarProduct.updatedAt = now;
        await isar.writeTxn(() async {
          await isar.isarProducts.put(isarProduct);
        });
        AppLogger.d(' Stock actualizado: ${isarProduct.name} → ${isarProduct.stock}');
      }
    } catch (e) {
      AppLogger.w(' Error actualizando stock del producto: $e');
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> updateMovement(
    UpdateInventoryMovementParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final request = UpdateInventoryMovementRequest.fromParams(params);
        final movement = await remoteDataSource.updateMovement(
          params.id,
          request,
        );

        // Cache the updated movement
        await localDataSource.cacheMovement(movement);

        // Clear movements cache to force refresh on next fetch
        await localDataSource.clearMovementsCache();

        return Right(movement.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException al actualizar movimiento: ${e.message} - Actualizando offline...');
        return _updateMovementOffline(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException al actualizar movimiento: ${e.message} - Actualizando offline...');
        return _updateMovementOffline(params);
      } catch (e) {
        AppLogger.e(' Error inesperado al actualizar movimiento: $e - Actualizando offline...');
        return _updateMovementOffline(params);
      }
    } else {
      // Sin conexión, actualizar offline
      return _updateMovementOffline(params);
    }
  }

  /// Actualizar movimiento offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, InventoryMovement>> _updateMovementOffline(
    UpdateInventoryMovementParams params,
  ) async {
    AppLogger.d(' InventoryRepository: Updating movement offline: ${params.id}');
    try {
      // PASO 1: Actualizar en ISAR primero
      final isar = IsarDatabase.instance.database;
      final isarMovement = await isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(params.id)
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movimiento no encontrado en ISAR: ${params.id}'));
      }

      // Actualizar campos en ISAR
      if (params.quantity != null) isarMovement.quantity = params.quantity!;
      if (params.unitCost != null) {
        isarMovement.unitCost = params.unitCost!;
        isarMovement.totalCost = params.unitCost! * isarMovement.quantity;
      }
      // Note: params doesn't have unitPrice field
      if (params.lotNumber != null) isarMovement.lotNumber = params.lotNumber;
      if (params.expiryDate != null) isarMovement.expiryDate = params.expiryDate;
      if (params.warehouseId != null) isarMovement.warehouseId = params.warehouseId;
      if (params.notes != null) isarMovement.notes = params.notes;
      if (params.movementDate != null) isarMovement.movementDate = params.movementDate!;

      // Marcar como no sincronizado
      isarMovement.markAsUnsynced();

      // Guardar en ISAR
      await isar.writeTxn(() async {
        await isar.isarInventoryMovements.put(isarMovement);
      });
      AppLogger.i(' InventoryRepository: Movimiento actualizado en ISAR');

      // PASO 2: Actualizar en SecureStorage
      final cachedMovementModel = await localDataSource.getCachedMovementById(params.id);
      if (cachedMovementModel == null) {
        return Left(CacheFailure('Movimiento no encontrado en cache: ${params.id}'));
      }
      final cachedMovement = cachedMovementModel.toEntity();

      final updatedMovement = InventoryMovement(
        id: params.id,
        productId: cachedMovement.productId,
        productName: cachedMovement.productName,
        productSku: cachedMovement.productSku,
        type: cachedMovement.type,
        status: cachedMovement.status,
        reason: cachedMovement.reason,
        quantity: params.quantity ?? cachedMovement.quantity,
        unitCost: params.unitCost ?? cachedMovement.unitCost,
        totalCost: (params.unitCost ?? cachedMovement.unitCost) * (params.quantity ?? cachedMovement.quantity),
        unitPrice: cachedMovement.unitPrice,  // params doesn't have unitPrice
        totalPrice: cachedMovement.totalPrice,
        lotNumber: params.lotNumber ?? cachedMovement.lotNumber,
        expiryDate: params.expiryDate ?? cachedMovement.expiryDate,
        warehouseId: params.warehouseId ?? cachedMovement.warehouseId,
        warehouseName: cachedMovement.warehouseName,
        referenceId: cachedMovement.referenceId,
        referenceType: cachedMovement.referenceType,
        notes: params.notes ?? cachedMovement.notes,
        userId: cachedMovement.userId,
        userName: cachedMovement.userName,
        metadata: cachedMovement.metadata,
        movementDate: params.movementDate ?? cachedMovement.movementDate,
        createdAt: cachedMovement.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cacheMovement(InventoryMovementModel.fromEntity(updatedMovement));

      // Agregar a cola
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {
            'quantity': params.quantity,
            'unitCost': params.unitCost,
            'lotNumber': params.lotNumber,
            'expiryDate': params.expiryDate?.toIso8601String(),
            'warehouseId': params.warehouseId,
            'notes': params.notes,
            'movementDate': params.movementDate?.toIso8601String(),
          },
          priority: 1,
        );
        AppLogger.d(' Actualización agregada a cola');
      } catch (e) {
        AppLogger.w(' Error agregando a cola: $e');
      }

      AppLogger.i(' Movement updated offline successfully');
      return Right(updatedMovement);
    } catch (e) {
      AppLogger.e(' Error updating movement offline: $e');
      return Left(CacheFailure('Error al actualizar movimiento offline: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMovement(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteMovement(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarMovement = await isar.isarInventoryMovements
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarMovement != null) {
            isarMovement.softDelete();
            await isar.writeTxn(() async {
              await isar.isarInventoryMovements.put(isarMovement);
            });
            AppLogger.i(' Movement marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          AppLogger.w(' Error actualizando ISAR (no crítico): $e');
        }

        // Clear related caches
        await localDataSource.clearMovementsCache();

        return const Right(null);
      } on ServerException catch (e) {
        AppLogger.w(' ServerException al eliminar: ${e.message} - Fallback offline...');
        return _deleteMovementOffline(id);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException al eliminar: ${e.message} - Fallback offline...');
        return _deleteMovementOffline(id);
      } catch (e) {
        AppLogger.w(' Exception al eliminar: $e - Fallback offline...');
        return _deleteMovementOffline(id);
      }
    } else {
      // Sin conexión, eliminar offline
      return _deleteMovementOffline(id);
    }
  }

  Future<Either<Failure, void>> _deleteMovementOffline(String id) async {
    AppLogger.d(' InventoryRepository: Deleting movement offline: $id');
    try {
      // Soft delete en ISAR
      try {
        final isar = IsarDatabase.instance.database;
        final isarMovement = await isar.isarInventoryMovements
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarMovement != null) {
          isarMovement.softDelete();
          await isar.writeTxn(() async {
            await isar.isarInventoryMovements.put(isarMovement);
          });
          AppLogger.i(' Movement marcado como eliminado en ISAR (offline): $id');
        }
      } catch (e) {
        AppLogger.w(' Error actualizando ISAR (no crítico): $e');
      }

      // Clear related caches
      await localDataSource.clearMovementsCache();

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        AppLogger.d(' Eliminación agregada a cola');
      } catch (e) {
        AppLogger.w(' Error agregando a cola: $e');
      }

      AppLogger.i(' Movement deleted offline successfully');
      return const Right(null);
    } catch (e) {
      AppLogger.e(' Error deleting movement offline: $e');
      return Left(CacheFailure('Error al eliminar movimiento offline: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> confirmMovement(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final movement = await remoteDataSource.confirmMovement(id);

        // Cache the confirmed movement
        await localDataSource.cacheMovement(movement);

        // Clear caches to force refresh
        await localDataSource.clearMovementsCache();
        await localDataSource.clearBalancesCache();

        return Right(movement.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException al confirmar: ${e.message}');
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException al confirmar: ${e.message}');
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        AppLogger.e(' Error inesperado al confirmar: $e');
        return Left(UnknownFailure('Error al confirmar movimiento: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> cancelMovement(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final movement = await remoteDataSource.cancelMovement(id);

        // Cache the cancelled movement
        await localDataSource.cacheMovement(movement);

        // Clear movements cache to force refresh
        await localDataSource.clearMovementsCache();

        return Right(movement.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException al cancelar: ${e.message}');
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException al cancelar: ${e.message}');
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        AppLogger.e(' Error inesperado al cancelar: $e');
        return Left(UnknownFailure('Error al cancelar movimiento: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> searchMovements(
    SearchInventoryMovementsParams params,
  ) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryMovement>>(
      hasLocalData: () => _movementsReady(),
      read: () => _localInventory.searchMovements(params),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteMovements = await remoteDataSource.searchMovements(params);
        return Right(remoteMovements.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en search: ${e.message} - Usando cache...');
        return _searchMovementsFromCache(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en search: ${e.message} - Usando cache...');
        return _searchMovementsFromCache(params);
      } catch (e) {
        AppLogger.e(' Error inesperado en search: $e - Usando cache...');
        return _searchMovementsFromCache(params);
      }
    } else {
      // Sin conexión, buscar en cache
      return _searchMovementsFromCache(params);
    }
  }

  // ==================== BALANCE OPERATIONS ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> getBalances(
    InventoryBalanceQueryParams params,
  ) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<core.PaginatedResult<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getBalances(params),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getBalances(params);
        // Cache successful result
        await localDataSource.cacheBalances(params, remoteBalances);
        return Right(
          core.PaginatedResult(
            data: remoteBalances.data.map((model) => model.toEntity()).toList(),
            meta: remoteBalances.meta,
          ),
        );
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getBalances: ${e.message} - Usando cache...');
        return _getBalancesFromCache(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getBalances: ${e.message} - Usando cache...');
        return _getBalancesFromCache(params);
      } catch (e) {
        AppLogger.e(' Error inesperado en getBalances: $e - Usando cache...');
        return _getBalancesFromCache(params);
      }
    } else {
      // Sin conexión, obtener desde cache
      return _getBalancesFromCache(params);
    }
  }

  @override
  Future<Either<Failure, InventoryBalance>> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<InventoryBalance>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getBalanceByProduct(productId, warehouseId: warehouseId),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalance = await remoteDataSource.getBalanceByProduct(
          productId,
          warehouseId: warehouseId,
        );
        // Cache successful result
        await localDataSource.cacheBalance(remoteBalance);
        return Right(remoteBalance.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getBalanceByProduct: ${e.message} - Usando cache...');
        return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getBalanceByProduct: ${e.message} - Usando cache...');
        return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
      } catch (e) {
        AppLogger.e(' Error inesperado en getBalanceByProduct: $e - Usando cache...');
        return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
      }
    } else {
      // Sin conexión, obtener desde cache
      return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getLowStockProducts({
    String? warehouseId,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getLowStockProducts(warehouseId: warehouseId),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getLowStockProducts(
          warehouseId: warehouseId,
        );
        // Cache successful result
        await localDataSource.cacheLowStockProducts(
          remoteBalances,
          warehouseId: warehouseId,
        );
        return Right(remoteBalances.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getLowStockProducts: ${e.message} - Usando cache...');
        return _getLowStockProductsFromCache(warehouseId: warehouseId);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getLowStockProducts: ${e.message} - Usando cache...');
        return _getLowStockProductsFromCache(warehouseId: warehouseId);
      } catch (e) {
        AppLogger.e(' Error inesperado en getLowStockProducts: $e - Usando cache...');
        return _getLowStockProductsFromCache(warehouseId: warehouseId);
      }
    } else {
      // Sin conexión, obtener desde cache
      return _getLowStockProductsFromCache(warehouseId: warehouseId);
    }
  }

  @override
  Future<Either<Failure, List<FifoConsumption>>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para calcular consumo FIFO'),
      );
    }

    try {
      final remoteConsumptions = await remoteDataSource
          .calculateFifoConsumption(
            productId,
            quantity,
            warehouseId: warehouseId,
          );
      return Right(
        remoteConsumptions.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure('Error al calcular consumo FIFO: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, InventoryStats>> getInventoryStats(
    InventoryStatsParams params,
  ) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<InventoryStats>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getInventoryStats(params),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        AppLogger.d('REPOSITORY DEBUG: About to call remoteDataSource.getInventoryStats');
        AppLogger.d('REPOSITORY DEBUG: remoteDataSource type: ${remoteDataSource.runtimeType}');
        final remoteStats = await remoteDataSource.getInventoryStats(params);
        // Cache successful result
        await localDataSource.cacheStats(params, remoteStats);
        return Right(remoteStats.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getInventoryStats: ${e.message} - Usando cache...');
        return _getInventoryStatsFromCache(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getInventoryStats: ${e.message} - Usando cache...');
        return _getInventoryStatsFromCache(params);
      } catch (e) {
        AppLogger.e(' Error inesperado en getInventoryStats: $e - Usando cache...');
        return _getInventoryStatsFromCache(params);
      }
    } else {
      // Sin conexión, obtener desde cache
      return _getInventoryStatsFromCache(params);
    }
  }

  // ==================== NOT YET FULLY IMPLEMENTED ====================
  // These methods would need complete implementation based on business requirements

  @override
  Future<Either<Failure, List<InventoryBalance>>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getBalancesByProducts(productIds, warehouseId: warehouseId),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getBalancesByProducts(
          productIds,
          warehouseId: warehouseId,
        );
        return Right(remoteBalances.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure('Error al obtener balances: ${e.toString()}'));
      }
    } else {
      // Devolver lista vacía cuando no hay conexión
      return const Right(<InventoryBalance>[]);
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getOutOfStockProducts({
    String? warehouseId,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getOutOfStockProducts(warehouseId: warehouseId),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getOutOfStockProducts(
          warehouseId: warehouseId,
        );
        // Cache para uso offline
        await localDataSource.cacheOutOfStockProducts(
          remoteBalances.cast<InventoryBalanceModel>(),
          warehouseId: warehouseId,
        );
        return Right(remoteBalances.map((model) => model.toEntity()).toList());
      } catch (e) {
        // Fallback a cache en caso de error
        final cached = await localDataSource.getCachedOutOfStockProducts(warehouseId: warehouseId);
        if (cached.isNotEmpty) {
          return Right(cached.map((model) => model.toEntity()).toList());
        }
        return Left(ServerFailure('Error al obtener productos sin stock: ${e.toString()}'));
      }
    } else {
      final cached = await localDataSource.getCachedOutOfStockProducts(warehouseId: warehouseId);
      return Right(cached.map((model) => model.toEntity()).toList());
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getExpiredProducts({
    String? warehouseId,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getExpiredProducts(warehouseId: warehouseId),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getExpiredProducts(
          warehouseId: warehouseId,
        );
        await localDataSource.cacheExpiredProducts(
          remoteBalances.cast<InventoryBalanceModel>(),
          warehouseId: warehouseId,
        );
        return Right(remoteBalances.map((model) => model.toEntity()).toList());
      } catch (e) {
        final cached = await localDataSource.getCachedExpiredProducts(warehouseId: warehouseId);
        if (cached.isNotEmpty) {
          return Right(cached.map((model) => model.toEntity()).toList());
        }
        return Left(ServerFailure('Error al obtener productos vencidos: ${e.toString()}'));
      }
    } else {
      final cached = await localDataSource.getCachedExpiredProducts(warehouseId: warehouseId);
      return Right(cached.map((model) => model.toEntity()).toList());
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<List<InventoryBalance>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getNearExpiryProducts(warehouseId: warehouseId, daysThreshold: daysThreshold),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final remoteBalances = await remoteDataSource.getNearExpiryProducts(
          warehouseId: warehouseId,
          daysThreshold: daysThreshold,
        );
        await localDataSource.cacheNearExpiryProducts(
          remoteBalances.cast<InventoryBalanceModel>(),
          warehouseId: warehouseId,
        );
        return Right(remoteBalances.map((model) => model.toEntity()).toList());
      } catch (e) {
        final cached = await localDataSource.getCachedNearExpiryProducts(warehouseId: warehouseId);
        if (cached.isNotEmpty) {
          return Right(cached.map((model) => model.toEntity()).toList());
        }
        return Left(ServerFailure('Error al obtener productos próximos a vencer: ${e.toString()}'));
      }
    } else {
      final cached = await localDataSource.getCachedNearExpiryProducts(warehouseId: warehouseId);
      return Right(cached.map((model) => model.toEntity()).toList());
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> processOutboundMovementFifo(
    ProcessFifoMovementParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para procesar movimientos FIFO'),
      );
    }

    try {
      final request = {
        'productId': params.productId,
        'quantity': params.quantity,
        'reason': params.reason.name,
        'warehouseId': params.warehouseId,
        'referenceId': params.referenceId,
        'referenceType': params.referenceType,
        'notes': params.notes,
        'movementDate': params.movementDate?.toIso8601String(),
      };

      final movement = await remoteDataSource.processOutboundMovementFifo(
        request,
      );

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movement.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Error al procesar movimiento FIFO: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>>
  processBulkOutboundMovementFifo(
    List<ProcessFifoMovementParams> movementsList,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para procesar movimientos FIFO'),
      );
    }

    try {
      final requestsList =
          movementsList
              .map(
                (params) => {
                  'productId': params.productId,
                  'quantity': params.quantity,
                  'reason': params.reason.name,
                  'warehouseId': params.warehouseId,
                  'referenceId': params.referenceId,
                  'referenceType': params.referenceType,
                  'notes': params.notes,
                  'movementDate': params.movementDate?.toIso8601String(),
                },
              )
              .toList();

      final movements = await remoteDataSource.processBulkOutboundMovementFifo(
        requestsList,
      );

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movements.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al procesar movimientos FIFO masivos: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> createStockAdjustment(
    Map<String, dynamic> request,
  ) async {
    // Una clave para este ajuste, con o sin internet: el servidor nunca lo
    // aplica dos veces aunque la respuesta se pierda y se reintente.
    final keyed = {
      ...request,
      'idempotencyKey': request['idempotencyKey'] ??
          'adjustment_offline_${DateTime.now().microsecondsSinceEpoch}_${request['productId'].hashCode}',
    };
    if (!await networkInfo.isConnected) {
      return _localInventory.createStockAdjustment(keyed);
    }

    try {
      final movement = await remoteDataSource.createStockAdjustment(keyed);

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movement.toEntity());
    } catch (e) {
      if (_isConnectionProblem(e)) {
        networkInfo.markServerUnreachable();
        return _localInventory.createStockAdjustment(keyed);
      }
      return Left(
        ServerFailure('Error al crear ajuste de stock: ${_errorMessage(e)}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> createBulkStockAdjustments(
    List<CreateStockAdjustmentParams> adjustmentsList,
  ) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final keys = [
      for (var i = 0; i < adjustmentsList.length; i++)
        'adjustment_offline_${stamp}_${i}_${adjustmentsList[i].productId.hashCode}',
    ];
    if (!await networkInfo.isConnected) {
      return _localInventory.createBulkStockAdjustments(
        adjustmentsList,
        idempotencyKeys: keys,
      );
    }

    try {
      var index = 0;
      final requestsList =
          adjustmentsList
              .map(
                (params) => {
                  'idempotencyKey': keys[index++],
                  'productId': params.productId,
                  'adjustmentQuantity': params.adjustmentQuantity,
                  'reason': params.reason.name,
                  'warehouseId': params.warehouseId,
                  'notes': params.notes,
                  'movementDate': params.movementDate?.toIso8601String(),
                  'unitCost': params.unitCost ?? 0.0,
                },
              )
              .toList();

      final movements = await remoteDataSource.createBulkStockAdjustments(
        requestsList,
      );

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movements.map((model) => model.toEntity()).toList());
    } catch (e) {
      if (_isConnectionProblem(e)) {
        networkInfo.markServerUnreachable();
        return _localInventory.createBulkStockAdjustments(
          adjustmentsList,
          idempotencyKeys: keys,
        );
      }
      return Left(
        ServerFailure('Error al crear ajustes masivos: ${_errorMessage(e)}'),
      );
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> createTransfer(
    CreateInventoryTransferParams params,
  ) async {
    // Una clave por producto, la misma con o sin internet.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final keys = [
      for (var i = 0; i < params.items.length; i++)
        'transfer_offline_${stamp}_${i}_${params.items[i].productId.hashCode}',
    ];
    if (!await networkInfo.isConnected) {
      return _localInventory.createTransfer(params, idempotencyKeys: keys);
    }

    try {
      final request = {
        'idempotencyKeys': keys,
        'items':
            params.items
                .map(
                  (item) => {
                    'productId': item.productId,
                    'quantity': item.quantity,
                    'notes': item.notes,
                  },
                )
                .toList(),
        'fromWarehouseId': params.fromWarehouseId,
        'toWarehouseId': params.toWarehouseId,
        'notes': params.notes,
        'transferDate': params.transferDate?.toIso8601String(),
      };

      final movement = await remoteDataSource.createTransfer(request);

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movement.toEntity());
    } catch (e) {
      // Se cayó la conexión a mitad: lo que ya se aplicó no se repite
      // (misma clave), lo demás queda en cola.
      if (_isConnectionProblem(e)) {
        networkInfo.markServerUnreachable();
        return _localInventory.createTransfer(params, idempotencyKeys: keys);
      }
      return Left(
        ServerFailure('Error al crear transferencia: ${_errorMessage(e)}'),
      );
    }
  }

  bool _isConnectionProblem(Object e) {
    if (e is ConnectionException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('conexión') ||
        msg.contains('tiempo de espera');
  }

  String _errorMessage(Object e) =>
      e is ServerException ? e.message : e.toString();

  @override
  Future<Either<Failure, InventoryMovement>> confirmTransfer(
    String transferId,
  ) =>
      // El servidor aplica los traslados al crearlos (no tiene endpoint de
      // confirmación): no hay nada que confirmar, con o sin internet.
      _localInventory.confirmTransfer(transferId);

  @override
  Future<Either<Failure, Map<String, double>>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<Map<String, double>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getInventoryValuation(warehouseId: warehouseId, asOfDate: asOfDate),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final valuation = await remoteDataSource.getInventoryValuation(
          warehouseId: warehouseId,
          asOfDate: asOfDate,
        );
        return Right(valuation);
      } catch (e) {
        return _getInventoryValuationFromCache(warehouseId: warehouseId);
      }
    } else {
      return _getInventoryValuationFromCache(warehouseId: warehouseId);
    }
  }

  Future<Either<Failure, Map<String, double>>> _getInventoryValuationFromCache({String? warehouseId}) async {
    try {
      // Solo lotes con existencias (y de la bodega pedida): la base filtra.
      var query = (IsarDatabase.instance.database as Isar)
          .isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .currentQuantityGreaterThan(0);
      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }
      final batches = (await query.findAll()).map((b) => b.toEntity()).toList();
      if (batches.isEmpty) return const Right(<String, double>{});

      final valuation = <String, double>{};
      for (final batch in batches) {
        if (batch is InventoryBatch) {
          if (warehouseId != null && batch.warehouseId != warehouseId) continue;
          if (batch.currentQuantity <= 0) continue;
          final key = batch.productName;
          valuation[key] = (valuation[key] ?? 0) + (batch.currentQuantity * batch.unitCost);
        }
      }
      return Right(valuation);
    } catch (e) {
      return const Right(<String, double>{});
    }
  }

  @override
  Future<Either<Failure, KardexReport>> getKardexReport(
    KardexReportParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final kardexReportModel = await remoteDataSource.getKardexReport(params);
        return Right(kardexReportModel.toEntity());
      } catch (e) {
        return _getKardexReportFromCache(params);
      }
    } else {
      return _getKardexReportFromCache(params);
    }
  }

  Future<Either<Failure, KardexReport>> _getKardexReportFromCache(KardexReportParams params) async {
    try {
      // Obtener movimientos del producto en el rango de fechas
      final movementsResult = await localDataSource.getCachedMovements(
        InventoryMovementQueryParams(
          productId: params.productId,
          warehouseId: params.warehouseId,
          startDate: params.startDate,
          endDate: params.endDate,
          page: 1,
          limit: 10000,
        ),
      );

      // Lotes solo de este producto (antes se cargaban todos los del equipo).
      final productBatches = (await (IsarDatabase.instance.database as Isar)
              .isarInventoryBatchs
              .filter()
              .deletedAtIsNull()
              .and()
              .productIdEqualTo(params.productId)
              .findAll())
          .map((b) => b.toEntity())
          .toList();

      String productName = '';
      String productSku = '';
      if (productBatches.isNotEmpty) {
        productName = productBatches.first.productName;
        productSku = productBatches.first.productSku;
      }

      final movements = movementsResult?.data ?? [];
      // Ordenar por fecha
      movements.sort((a, b) => a.movementDate.compareTo(b.movementDate));

      double runningBalance = 0;
      double runningValue = 0;
      int totalEntries = 0;
      int totalExits = 0;
      double totalPurchases = 0;
      double totalSales = 0;

      final kardexMovements = <KardexMovement>[];
      for (final m in movements) {
        final entity = m.toEntity();
        final isEntry = entity.type == InventoryMovementType.inbound;
        final double entryQty = isEntry ? entity.quantity.toDouble() : 0.0;
        final double exitQty = isEntry ? 0.0 : entity.quantity.toDouble();
        runningBalance += (isEntry ? entity.quantity : -entity.quantity);
        final entryCost = entryQty * entity.unitCost;
        final exitCost = exitQty * entity.unitCost;
        runningValue = runningBalance * entity.unitCost;

        if (isEntry) {
          totalEntries++;
          totalPurchases += entryCost;
        } else {
          totalExits++;
          totalSales += exitCost;
        }

        kardexMovements.add(KardexMovement(
          date: entity.movementDate,
          movementNumber: entity.id,
          movementType: entity.type.name,
          description: entity.reason.name,
          entryQuantity: entryQty,
          exitQuantity: exitQty,
          balance: runningBalance.toDouble(),
          unitCost: entity.unitCost,
          entryCost: entryCost,
          exitCost: exitCost,
          balanceValue: runningValue,
          createdBy: m.userId ?? '',
          notes: entity.notes,
        ));
      }

      final avgCost = runningBalance > 0 ? runningValue / runningBalance : 0.0;

      return Right(KardexReport(
        product: KardexProduct(id: params.productId, name: productName, sku: productSku),
        period: KardexPeriod(startDate: params.startDate, endDate: params.endDate),
        initialBalance: const KardexBalance(quantity: 0, value: 0, averageCost: 0),
        movements: kardexMovements,
        finalBalance: KardexBalance(quantity: runningBalance, value: runningValue, averageCost: avgCost),
        summary: KardexSummary(
          totalEntries: totalEntries,
          totalExits: totalExits,
          totalPurchases: totalPurchases,
          totalSales: totalSales,
          averageUnitCost: avgCost,
          totalValue: runningValue,
        ),
      ));
    } catch (e) {
      return Right(_emptyKardexReport(params));
    }
  }

  KardexReport _emptyKardexReport(KardexReportParams params) {
    return KardexReport(
      product: KardexProduct(
        id: params.productId,
        name: '',
        sku: '',
      ),
      period: KardexPeriod(
        startDate: params.startDate,
        endDate: params.endDate,
      ),
      initialBalance: const KardexBalance(quantity: 0, value: 0, averageCost: 0),
      movements: const [],
      finalBalance: const KardexBalance(quantity: 0, value: 0, averageCost: 0),
      summary: const KardexSummary(
        totalEntries: 0,
        totalExits: 0,
        totalPurchases: 0,
        totalSales: 0,
        averageUnitCost: 0,
        totalValue: 0,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryAging({
    String? warehouseId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final aging = await remoteDataSource.getInventoryAging(
          warehouseId: warehouseId,
        );
        return Right(aging);
      } catch (e) {
        return _getInventoryAgingFromCache(warehouseId: warehouseId);
      }
    } else {
      return _getInventoryAgingFromCache(warehouseId: warehouseId);
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> _getInventoryAgingFromCache({String? warehouseId}) async {
    try {
      // Solo lotes con existencias (y de la bodega pedida): la base filtra.
      var query = (IsarDatabase.instance.database as Isar)
          .isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .currentQuantityGreaterThan(0);
      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }
      final batches = (await query.findAll()).map((b) => b.toEntity()).toList();
      if (batches.isEmpty) return const Right(<Map<String, dynamic>>[]);

      final now = DateTime.now();
      // Agrupar por producto
      final productAging = <String, Map<String, dynamic>>{};

      for (final batch in batches) {
        if (batch is InventoryBatch) {
          if (warehouseId != null && batch.warehouseId != warehouseId) continue;
          if (batch.currentQuantity <= 0) continue;

          final ageDays = now.difference(batch.entryDate).inDays;
          final key = batch.productId;
          final value = batch.currentQuantity * batch.unitCost;

          if (!productAging.containsKey(key)) {
            productAging[key] = {
              'productId': batch.productId,
              'productName': batch.productName,
              'productSku': batch.productSku,
              'totalQuantity': 0,
              'totalValue': 0.0,
              'averageAgeDays': 0.0,
              'oldestBatchDays': 0,
              'newestBatchDays': ageDays,
              'batches': <Map<String, dynamic>>[],
            };
          }

          final entry = productAging[key]!;
          entry['totalQuantity'] = (entry['totalQuantity'] as int) + batch.currentQuantity;
          entry['totalValue'] = (entry['totalValue'] as double) + value;
          if (ageDays > (entry['oldestBatchDays'] as int)) {
            entry['oldestBatchDays'] = ageDays;
          }
          if (ageDays < (entry['newestBatchDays'] as int)) {
            entry['newestBatchDays'] = ageDays;
          }
          (entry['batches'] as List).add({
            'batchNumber': batch.batchNumber,
            'quantity': batch.currentQuantity,
            'ageDays': ageDays,
            'value': value,
            'entryDate': batch.entryDate.toIso8601String(),
          });
        }
      }

      // Calcular promedio de antigüedad ponderado por cantidad
      for (final entry in productAging.values) {
        final batchList = entry['batches'] as List;
        final totalQty = entry['totalQuantity'] as int;
        if (totalQty > 0) {
          double weightedAge = 0;
          for (final b in batchList) {
            weightedAge += (b['ageDays'] as int) * (b['quantity'] as int);
          }
          entry['averageAgeDays'] = weightedAge / totalQty;
        }
      }

      final result = productAging.values.toList()
        ..sort((a, b) => (b['averageAgeDays'] as double).compareTo(a['averageAgeDays'] as double));

      return Right(result);
    } catch (e) {
      return const Right(<Map<String, dynamic>>[]);
    }
  }

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> getBatches(
    InventoryBatchQueryParams params,
  ) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<core.PaginatedResult<InventoryBatch>>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getBatches(params),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final batchMaps = await remoteDataSource.getBatches(
          productId: params.productId,
          warehouseId: params.warehouseId,
          status: params.status?.name,
          search: params.search,
          activeOnly: params.activeOnly,
          expiredOnly: params.expiredOnly,
          nearExpiryOnly: params.nearExpiryOnly,
          sortBy: params.sortBy,
          sortOrder: params.sortOrder,
          page: params.page,
          limit: params.limit,
        );

        final batches =
            batchMaps
                .map((map) => InventoryBatchModel.fromJson(map).toEntity())
                .toList();

        // Cache the batches
        try {
          await localDataSource.cacheBatches(
            batches.map((e) => InventoryBatchModel.fromEntity(e)).toList(),
          );
        } catch (e) {
          AppLogger.w(' Error caching batches: $e');
        }

        // Apply frontend sorting as fallback if backend doesn't sort
        _sortBatchesIfNeeded(batches, params.sortBy, params.sortOrder);

        // Apply frontend search as fallback if backend doesn't filter
        if (params.search != null && params.search!.isNotEmpty) {
          _filterBatchesBySearch(batches, params.search!);
        }

        // Apply frontend filters as fallback if backend doesn't filter
        _applySpecialFilters(batches, params);

        // Create pagination meta from response headers or calculate
        final meta = PaginationMeta(
          page: params.page,
          limit: params.limit,
          totalItems: batches.length,
          totalPages: (batches.length / params.limit).ceil(),
          hasNextPage: batches.length >= params.limit,
          hasPreviousPage: params.page > 1,
        );

        return Right(
          core.PaginatedResult<InventoryBatch>(data: batches, meta: meta),
        );
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getBatches: ${e.message} - Usando cache...');
        return _getBatchesFromCache(params);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getBatches: ${e.message} - Usando cache...');
        return _getBatchesFromCache(params);
      } catch (e) {
        AppLogger.e(' Error inesperado en getBatches: $e - Usando cache...');
        return _getBatchesFromCache(params);
      }
    } else {
      // Sin conexión, usar cache
      return _getBatchesFromCache(params);
    }
  }

  @override
  Future<Either<Failure, InventoryBatch>> getBatchById(String id) async {
    // local-first: lo del equipo al instante; el servidor actualiza en segundo plano.
    final local = await readLocalFirst<InventoryBatch>(
      hasLocalData: () => _batchesReady(),
      read: () => _localInventory.getBatchById(id),
    );
    if (local != null) return local;

    if (await networkInfo.isConnected) {
      try {
        final batchMap = await remoteDataSource.getBatchById(id);
        final batch = InventoryBatchModel.fromJson(batchMap).toEntity();

        // Cache the batch
        try {
          await localDataSource.cacheBatch(InventoryBatchModel.fromEntity(batch));
        } catch (e) {
          AppLogger.w(' Error caching batch: $e');
        }

        return Right(batch);
      } on ServerException catch (e) {
        AppLogger.w(' ServerException en getBatchById: ${e.message} - Usando cache...');
        return _getBatchFromCache(id);
      } on ConnectionException catch (e) {
        AppLogger.w(' ConnectionException en getBatchById: ${e.message} - Usando cache...');
        return _getBatchFromCache(id);
      } catch (e) {
        AppLogger.e(' Error inesperado en getBatchById: $e - Usando cache...');
        return _getBatchFromCache(id);
      }
    } else {
      // Sin conexión, usar cache
      return _getBatchFromCache(id);
    }
  }

  // Varios filtros y selectores de inventario piden las bodegas al mismo
  // tiempo al abrir la pantalla: comparten una sola petición en vez de ir
  // cada uno al servidor.
  static Future<Either<Failure, List<Warehouse>>>? _warehousesInFlight;

  @override
  Future<Either<Failure, List<Warehouse>>> getWarehouses() {
    return _warehousesInFlight ??=
        _fetchWarehouses().whenComplete(() => _warehousesInFlight = null);
  }

  Future<Either<Failure, List<Warehouse>>> _fetchWarehouses() async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModels = await _withPendingWarehouseChanges(
          await remoteDataSource.getWarehouses(),
        );
        final warehouses =
            warehouseModels.map((model) => model.toEntity()).toList();

        // Cache para uso offline
        await localDataSource.cacheWarehouses(warehouseModels);

        return Right(warehouses);
      } else {
        // Obtener desde cache local
        final cachedWarehouses = await localDataSource.getCachedWarehouses();
        if (cachedWarehouses.isNotEmpty) {
          return Right(cachedWarehouses.map((model) => model.toEntity()).toList());
        }
        return const Right(<Warehouse>[]);
      }
    } catch (e) {
      // En caso de error, intentar cache
      try {
        final cachedWarehouses = await localDataSource.getCachedWarehouses();
        if (cachedWarehouses.isNotEmpty) {
          return Right(cachedWarehouses.map((model) => model.toEntity()).toList());
        }
      } catch (_) {}
      return Left(ServerFailure('Error al obtener almacenes: ${e.toString()}'));
    }
  }

  // ==================== ALMACENES (con o sin internet) ====================
  //
  // Sin conexión se guardan en el equipo (id temporal `warehouse_offline_`)
  // y se encolan; el servidor los aplica al sincronizar. Mismas reglas que el
  // servidor: código único, no eliminar el principal ni uno con unidades.

  static const String _tempWarehousePrefix = 'warehouse_offline_';

  /// La lista del servidor + lo hecho sin conexión que aún no ha subido
  /// (si no, al refrescar con internet los almacenes nuevos desaparecían).
  Future<List<WarehouseModel>> _withPendingWarehouseChanges(
    List<WarehouseModel> server,
  ) async {
    try {
      final db = IsarDatabase.instance;
      final ops = [
        ...await db.getPendingSyncOperations(),
        ...await db.getFailedSyncOperations(),
      ].where((op) => op.entityType == 'Warehouse').toList();
      if (ops.isEmpty) return server;
      final cached = await localDataSource.getCachedWarehouses();
      final result = [...server];
      for (final op in ops) {
        final data = jsonDecode(op.payload) as Map<String, dynamic>;
        if (op.operationType == SyncOperationType.create) {
          final local = cached.where((w) => w.id == op.entityId).firstOrNull;
          if (local != null && !result.any((w) => w.id == local.id)) {
            result.add(local);
          }
        } else if (op.operationType == SyncOperationType.update) {
          final i = result.indexWhere((w) => w.id == op.entityId);
          if (i >= 0) {
            final w = result[i];
            result[i] = WarehouseModel(
              id: w.id,
              name: data['name'] as String? ?? w.name,
              code: data['code'] as String? ?? w.code,
              description: data['description'] as String? ?? w.description,
              address: data['address'] as String? ?? w.address,
              isActive: data['isActive'] as bool? ?? w.isActive,
              isMainWarehouse: w.isMainWarehouse,
              createdAt: w.createdAt,
              updatedAt: w.updatedAt,
            );
          }
        } else if (op.operationType == SyncOperationType.delete) {
          result.removeWhere((w) => w.id == op.entityId);
        }
      }
      return result;
    } catch (_) {
      return server;
    }
  }

  Future<String?> _duplicateWarehouseCode(String code, {String? exceptId}) async {
    final cached = await localDataSource.getCachedWarehouses();
    final clash = cached.where((w) =>
        w.id != exceptId && w.code.trim().toLowerCase() == code.trim().toLowerCase());
    return clash.isEmpty ? null : 'Ya existe un almacén con este código';
  }

  Future<Either<Failure, T>> _enqueueWarehouse<T>(
    String id,
    SyncOperationType type,
    Map<String, dynamic> data,
    Future<T> Function() applyLocally,
  ) async {
    try {
      await Get.find<SyncService>().addOperationForCurrentUser(
        entityType: 'Warehouse',
        entityId: id,
        operationType: type,
        data: data,
        priority: 1,
      );
    } catch (e) {
      return Left(CacheFailure(
        'No se pudo guardar el cambio del almacén para sincronizar. No se aplicó: $e',
      ));
    }
    return Right(await applyLocally());
  }

  Future<Either<Failure, Warehouse>> _createWarehouseOffline(
    CreateWarehouseParams params,
  ) async {
    final duplicate = await _duplicateWarehouseCode(params.code);
    if (duplicate != null) return Left(ServerFailure(duplicate));
    final now = DateTime.now();
    final model = WarehouseModel(
      id: '$_tempWarehousePrefix${now.microsecondsSinceEpoch}',
      name: params.name,
      code: params.code,
      description: params.description,
      address: params.address,
      isActive: params.isActive,
      createdAt: now,
      updatedAt: now,
    );
    return _enqueueWarehouse(model.id, SyncOperationType.create, params.toJson(), () async {
      final cached = await localDataSource.getCachedWarehouses();
      await localDataSource.cacheWarehouses([...cached, model]);
      return model.toEntity();
    });
  }

  Future<Either<Failure, Warehouse>> _updateWarehouseOffline(
    String id,
    UpdateWarehouseParams params,
  ) async {
    if (params.code != null) {
      final duplicate = await _duplicateWarehouseCode(params.code!, exceptId: id);
      if (duplicate != null) return Left(ServerFailure(duplicate));
    }
    final cached = await localDataSource.getCachedWarehouses();
    final current = cached.where((w) => w.id == id).firstOrNull;
    if (current == null) return Left(CacheFailure('Almacén no encontrado en el equipo'));
    final updated = WarehouseModel(
      id: current.id,
      name: params.name ?? current.name,
      code: params.code ?? current.code,
      description: params.description ?? current.description,
      address: params.address ?? current.address,
      isActive: params.isActive ?? current.isActive,
      isMainWarehouse: current.isMainWarehouse,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    return _enqueueWarehouse(id, SyncOperationType.update, params.toJson(), () async {
      await localDataSource.cacheWarehouses(
        [for (final w in cached) w.id == id ? updated : w],
      );
      return updated.toEntity();
    });
  }

  Future<Either<Failure, bool>> _deleteWarehouseOffline(String id) async {
    final cached = await localDataSource.getCachedWarehouses();
    final current = cached.where((w) => w.id == id).firstOrNull;
    if (current?.isMainWarehouse == true) {
      return Left(ServerFailure('No se puede eliminar el almacén principal'));
    }
    final units = (await IsarDatabase.instance.database.isarInventoryBatchs
            .filter()
            .deletedAtIsNull()
            .and()
            .warehouseIdEqualTo(id)
            .findAll())
        .fold<int>(0, (sum, b) => sum + b.currentQuantity);
    if (units > 0) {
      return Left(ServerFailure(
        'El almacén todavía tiene $units unidades. Trasládelas a otro almacén antes de eliminarlo.',
      ));
    }
    return _enqueueWarehouse(id, SyncOperationType.delete, {'id': id}, () async {
      await localDataSource.cacheWarehouses(cached.where((w) => w.id != id).toList());
      return true;
    });
  }

  @override
  Future<Either<Failure, Warehouse>> createWarehouse(
    CreateWarehouseParams params,
  ) async {
    if (!await networkInfo.isConnected) return _createWarehouseOffline(params);
    try {
      final warehouseModel = await remoteDataSource.createWarehouse(params);
      final cached = await localDataSource.getCachedWarehouses();
      await localDataSource.cacheWarehouses([...cached, warehouseModel]);
      return Right(warehouseModel.toEntity());
    } catch (e) {
      if (_isConnectionProblem(e)) return _createWarehouseOffline(params);
      return Left(ServerFailure('Error al crear almacén: ${_errorMessage(e)}'));
    }
  }

  @override
  Future<Either<Failure, Warehouse>> updateWarehouse(
    String id,
    UpdateWarehouseParams params,
  ) async {
    if (!await networkInfo.isConnected || id.startsWith(_tempWarehousePrefix)) {
      return _updateWarehouseOffline(id, params);
    }
    try {
      final warehouseModel = await remoteDataSource.updateWarehouse(id, params);
      final cached = await localDataSource.getCachedWarehouses();
      await localDataSource.cacheWarehouses(
        [for (final w in cached) w.id == id ? warehouseModel : w],
      );
      return Right(warehouseModel.toEntity());
    } catch (e) {
      if (_isConnectionProblem(e)) return _updateWarehouseOffline(id, params);
      return Left(ServerFailure('Error al actualizar almacén: ${_errorMessage(e)}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteWarehouse(String id) async {
    if (!await networkInfo.isConnected || id.startsWith(_tempWarehousePrefix)) {
      return _deleteWarehouseOffline(id);
    }
    try {
      final result = await remoteDataSource.deleteWarehouse(id);
      final cached = await localDataSource.getCachedWarehouses();
      await localDataSource.cacheWarehouses(cached.where((w) => w.id != id).toList());
      return Right(result);
    } catch (e) {
      if (_isConnectionProblem(e)) return _deleteWarehouseOffline(id);
      return Left(ServerFailure('Error al eliminar almacén: ${_errorMessage(e)}'));
    }
  }

  @override
  Future<Either<Failure, Warehouse>> getWarehouseById(String id) async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModel = await remoteDataSource.getWarehouseById(id);
        return Right(warehouseModel.toEntity());
      } else {
        // Buscar en cache
        final cached = await localDataSource.getCachedWarehouseById(id);
        if (cached != null) {
          return Right(cached.toEntity());
        }
        return Left(
          CacheFailure('Almacén no encontrado en cache local'),
        );
      }
    } catch (e) {
      // Intentar cache en caso de error
      try {
        final cached = await localDataSource.getCachedWarehouseById(id);
        if (cached != null) {
          return Right(cached.toEntity());
        }
      } catch (_) {}
      return Left(ServerFailure('Error al obtener almacén: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkWarehouseCodeExists(
    String code, {
    String? excludeId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final exists = await remoteDataSource.checkWarehouseCodeExists(
          code,
          excludeId: excludeId,
        );
        return Right(exists);
      } else {
        // Verificar en cache local
        final cachedWarehouses = await localDataSource.getCachedWarehouses();
        final exists = cachedWarehouses.any(
          (w) => w.code == code && (excludeId == null || w.id != excludeId),
        );
        return Right(exists);
      }
    } catch (e) {
      return Left(ServerFailure('Error al verificar código: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkWarehouseHasMovements(
    String warehouseId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final hasMovements = await remoteDataSource.checkWarehouseHasMovements(
          warehouseId,
        );
        return Right(hasMovements);
      } else {
        // Asumir que tiene movimientos cuando no hay conexión (más seguro)
        return const Right(true);
      }
    } catch (e) {
      return Left(
        ServerFailure('Error al verificar movimientos: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>>
  getWarehouseMovements(
    String warehouseId,
    InventoryMovementQueryParams params,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final result = await remoteDataSource.getWarehouseMovements(
          warehouseId,
          params,
        );

        final movements = result.data.map((model) => model.toEntity()).toList();

        return Right(
          core.PaginatedResult<InventoryMovement>(
            data: movements,
            meta: result.meta,
          ),
        );
      } else {
        // Try to get from local cache if available
        final cachedResult = await localDataSource.getCachedMovements(params);
        final filteredMovements =
            cachedResult?.data
                .where((model) => model.warehouseId == warehouseId)
                .map((model) => model.toEntity())
                .toList() ??
            <InventoryMovement>[];

        return Right(
          core.PaginatedResult<InventoryMovement>(
            data: filteredMovements,
            meta: null,
          ),
        );
      }
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al obtener movimientos del almacén: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getActiveWarehousesCount() async {
    try {
      if (await networkInfo.isConnected) {
        final count = await remoteDataSource.getActiveWarehousesCount();
        return Right(count);
      } else {
        // Contar desde cache
        final cachedWarehouses = await localDataSource.getCachedWarehouses();
        final activeCount = cachedWarehouses.where((w) => w.isActive).length;
        return Right(activeCount);
      }
    } catch (e) {
      return Left(ServerFailure('Error al contar almacenes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WarehouseStats>> getWarehouseStats(
    String warehouseId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final stats = await remoteDataSource.getWarehouseStats(warehouseId);
        return Right(stats);
      } else {
        // Devolver estadísticas vacías cuando no hay conexión
        return const Right(WarehouseStats(
          totalProducts: 0,
          totalValue: 0,
          totalQuantity: 0,
          lowStockProducts: 0,
          outOfStockProducts: 0,
        ));
      }
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al obtener estadísticas del almacén: ${e.toString()}',
        ),
      );
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Obtener movimientos desde cache local
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> _getMovementsFromCache(
    InventoryMovementQueryParams params,
  ) async {
    try {
      final cachedMovements = await localDataSource.getCachedMovements(params);
      if (cachedMovements != null) {
        return Right(
          core.PaginatedResult(
            data:
                cachedMovements.data.map((model) => model.toEntity()).toList(),
            meta: cachedMovements.meta,
          ),
        );
      }
      // Retornar lista vacía en vez de error cuando no hay cache
      return Right(
        core.PaginatedResult<InventoryMovement>(
          data: <InventoryMovement>[],
          meta: null,
        ),
      );
    } catch (_) {
      return Right(
        core.PaginatedResult<InventoryMovement>(
          data: <InventoryMovement>[],
          meta: null,
        ),
      );
    }
  }

  /// Obtener movimiento individual desde cache local
  Future<Either<Failure, InventoryMovement>> _getMovementFromCache(String id) async {
    try {
      final cachedMovement = await localDataSource.getCachedMovementById(id);
      if (cachedMovement != null) {
        return Right(cachedMovement.toEntity());
      }
      return const Left(CacheFailure('Datos no encontrados en cache'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener movimiento desde cache: $e'));
    }
  }

  /// Buscar movimientos desde cache local
  Future<Either<Failure, List<InventoryMovement>>> _searchMovementsFromCache(
    SearchInventoryMovementsParams params,
  ) async {
    try {
      final cachedMovements = await localDataSource.searchCachedMovements(params);
      return Right(cachedMovements.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<InventoryMovement>[]);
    }
  }

  /// Obtener balances desde cache local
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> _getBalancesFromCache(
    InventoryBalanceQueryParams params,
  ) async {
    try {
      final cachedBalances = await localDataSource.getCachedBalances(params);
      if (cachedBalances != null) {
        return Right(
          core.PaginatedResult(
            data: cachedBalances.data.map((model) => model.toEntity()).toList(),
            meta: cachedBalances.meta,
          ),
        );
      }
      // Retornar lista vacía en vez de error cuando no hay cache
      return Right(
        core.PaginatedResult<InventoryBalance>(
          data: <InventoryBalance>[],
          meta: null,
        ),
      );
    } catch (_) {
      return Right(
        core.PaginatedResult<InventoryBalance>(
          data: <InventoryBalance>[],
          meta: null,
        ),
      );
    }
  }

  /// Obtener balance por producto desde cache local
  Future<Either<Failure, InventoryBalance>> _getBalanceByProductFromCache(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      final cachedBalance = await localDataSource.getCachedBalanceByProduct(
        productId,
        warehouseId: warehouseId,
      );
      if (cachedBalance != null) {
        return Right(cachedBalance.toEntity());
      }
      return const Left(CacheFailure('Datos no encontrados en cache'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener balance desde cache: $e'));
    }
  }

  /// Obtener productos con bajo stock desde cache local
  Future<Either<Failure, List<InventoryBalance>>> _getLowStockProductsFromCache({
    String? warehouseId,
  }) async {
    try {
      final cachedBalances = await localDataSource.getCachedLowStockProducts(
        warehouseId: warehouseId,
      );
      return Right(cachedBalances.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<InventoryBalance>[]);
    }
  }

  /// Obtener estadísticas desde cache local
  Future<Either<Failure, InventoryStats>> _getInventoryStatsFromCache(
    InventoryStatsParams params,
  ) async {
    try {
      final cachedStats = await localDataSource.getCachedStats(params);
      if (cachedStats != null) {
        return Right(cachedStats.toEntity());
      }
      // Retornar stats vacías en vez de error cuando no hay cache
      return const Right(InventoryStats(
        totalProducts: 0,
        totalBatches: 0,
        totalMovements: 0,
        totalValue: 0,
        movementsByType: {},
      ));
    } catch (_) {
      return const Right(InventoryStats(
        totalProducts: 0,
        totalBatches: 0,
        totalMovements: 0,
        totalValue: 0,
        movementsByType: {},
      ));
    }
  }

  void _sortBatchesIfNeeded(
    List<InventoryBatch> batches,
    String sortBy,
    String sortOrder,
  ) {
    if (batches.isEmpty) return;

    batches.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'purchaseDate':
          comparison = a.entryDate.compareTo(b.entryDate);
          break;
        case 'expirationDate':
          // Handle null expiry dates - put them at the end
          if (a.expiryDate == null && b.expiryDate == null) {
            comparison = 0;
          } else if (a.expiryDate == null) {
            comparison = 1;
          } else if (b.expiryDate == null) {
            comparison = -1;
          } else {
            comparison = a.expiryDate!.compareTo(b.expiryDate!);
          }
          break;
        case 'currentQuantity':
          comparison = a.currentQuantity.compareTo(b.currentQuantity);
          break;
        case 'originalQuantity':
          comparison = a.originalQuantity.compareTo(b.originalQuantity);
          break;
        case 'unitCost':
          comparison = a.unitCost.compareTo(b.unitCost);
          break;
        case 'batchNumber':
          comparison = a.batchNumber.compareTo(b.batchNumber);
          break;
        default:
          comparison = a.entryDate.compareTo(b.entryDate);
      }

      // Apply sort order
      return sortOrder == 'asc' ? comparison : -comparison;
    });
  }

  void _filterBatchesBySearch(
    List<InventoryBatch> batches,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return;

    final query = searchQuery.toLowerCase();
    batches.removeWhere((batch) {
      final batchNumber = batch.batchNumber.toLowerCase();
      final supplierName = (batch.supplierName ?? '').toLowerCase();
      final purchaseOrderNumber =
          (batch.purchaseOrderNumber ?? '').toLowerCase();
      final notes = (batch.notes ?? '').toLowerCase();

      return !batchNumber.contains(query) &&
          !supplierName.contains(query) &&
          !purchaseOrderNumber.contains(query) &&
          !notes.contains(query);
    });

    AppLogger.d('SEARCH FALLBACK: Filtrado ${batches.length} lotes con query: "$searchQuery"');
  }

  void _applySpecialFilters(
    List<InventoryBatch> batches,
    InventoryBatchQueryParams params,
  ) {
    if (params.activeOnly == true) {
      batches.removeWhere((batch) => !batch.isActive);
      AppLogger.d('FILTER FALLBACK: Filtro Solo Activos aplicado - ${batches.length} lotes');
    }

    if (params.expiredOnly == true) {
      batches.removeWhere((batch) => !batch.isExpiredByDate);
      AppLogger.d('FILTER FALLBACK: Filtro Solo Vencidos aplicado - ${batches.length} lotes');
    }

    if (params.nearExpiryOnly == true) {
      batches.removeWhere((batch) => !batch.isNearExpiry);
      AppLogger.d('FILTER FALLBACK: Filtro Por Vencer aplicado - ${batches.length} lotes');
    }
  }

  /// Obtener batches desde cache (usado como fallback cuando falla el servidor)
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> _getBatchesFromCache(
    InventoryBatchQueryParams params,
  ) async {
    AppLogger.d(' Obteniendo batches desde cache local');
    try {
      final cachedBatchModels = await localDataSource.getCachedBatches();

      if (cachedBatchModels.isEmpty) {
        return Right(
          core.PaginatedResult<InventoryBatch>(data: <InventoryBatch>[], meta: null),
        );
      }

      // ISAR devuelve InventoryBatch (entities), SecureStorage devuelve InventoryBatchModel
      var batches = cachedBatchModels.map((item) {
        if (item is InventoryBatch) return item;
        if (item is InventoryBatchModel) return item.toEntity();
        throw CacheException('Tipo inesperado en cache de batches: ${item.runtimeType}');
      }).toList();

      // Apply filters
      if (params.productId != null) {
        batches = batches.where((b) => b.productId == params.productId).toList();
      }

      if (params.warehouseId != null) {
        batches = batches.where((b) => b.warehouseId == params.warehouseId).toList();
      }

      if (params.status != null) {
        batches = batches.where((b) => b.status == params.status).toList();
      }

      if (params.search != null && params.search!.isNotEmpty) {
        _filterBatchesBySearch(batches, params.search!);
      }

      _applySpecialFilters(batches, params);

      // Apply sorting
      _sortBatchesIfNeeded(batches, params.sortBy, params.sortOrder);

      // Apply pagination
      final totalItems = batches.length;
      final offset = (params.page - 1) * params.limit;
      final paginatedBatches = batches.skip(offset).take(params.limit).toList();

      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: (totalItems / params.limit).ceil(),
        hasNextPage: offset + params.limit < totalItems,
        hasPreviousPage: params.page > 1,
      );

      AppLogger.i(' Obtenidos ${paginatedBatches.length} batches desde cache');
      return Right(
        core.PaginatedResult<InventoryBatch>(data: paginatedBatches, meta: meta),
      );
    } catch (e) {
      AppLogger.e(' Error obteniendo batches desde cache: $e');
      return Right(
        core.PaginatedResult<InventoryBatch>(data: <InventoryBatch>[], meta: null),
      );
    }
  }

  /// Obtener batch por ID desde cache (usado como fallback cuando falla el servidor)
  Future<Either<Failure, InventoryBatch>> _getBatchFromCache(String id) async {
    AppLogger.d(' Obteniendo batch $id desde cache local');
    try {
      final cachedBatchModel = await localDataSource.getCachedBatch(id);

      if (cachedBatchModel == null) {
        return Left(CacheFailure('Batch $id no encontrado en cache'));
      }

      // ISAR devuelve InventoryBatch (entity), SecureStorage devuelve InventoryBatchModel
      final InventoryBatch batch;
      if (cachedBatchModel is InventoryBatch) {
        batch = cachedBatchModel;
      } else if (cachedBatchModel is InventoryBatchModel) {
        batch = cachedBatchModel.toEntity();
      } else {
        return Left(CacheFailure('Tipo inesperado en cache: ${cachedBatchModel.runtimeType}'));
      }
      AppLogger.i(' Batch obtenido desde cache');
      return Right(batch);
    } catch (e) {
      AppLogger.e(' Error obteniendo batch desde cache: $e');
      return Left(CacheFailure('Error obteniendo batch desde cache: $e'));
    }
  }

  /// Mapear ServerException a Failure específico
  Failure _mapServerExceptionToFailure(ServerException exception) {
    if (exception.statusCode != null) {
      return ServerFailure.fromStatusCode(
        exception.statusCode!,
        exception.message,
      );
    } else {
      return ServerFailure(exception.message);
    }
  }
}
