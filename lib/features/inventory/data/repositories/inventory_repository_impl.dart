// lib/features/inventory/data/repositories/inventory_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
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
import '../models/inventory_batch_model.dart';
import '../models/isar/isar_inventory_movement.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getMovements(
    InventoryMovementQueryParams params,
  ) async {
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
        print('⚠️ ServerException en getMovements: ${e.message} - Usando cache...');
        return _getMovementsFromCache(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getMovements: ${e.message} - Usando cache...');
        return _getMovementsFromCache(params);
      } catch (e) {
        print('❌ Error inesperado en getMovements: $e - Usando cache...');
        return _getMovementsFromCache(params);
      }
    } else {
      // Sin conexión, intentar obtener desde cache
      return _getMovementsFromCache(params);
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> getMovementById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMovement = await remoteDataSource.getMovementById(id);
        // Cache successful result
        await localDataSource.cacheMovement(remoteMovement);
        return Right(remoteMovement.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException en getMovementById: ${e.message} - Usando cache...');
        return _getMovementFromCache(id);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getMovementById: ${e.message} - Usando cache...');
        return _getMovementFromCache(id);
      } catch (e) {
        print('❌ Error inesperado en getMovementById: $e - Usando cache...');
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
        print('⚠️ ServerException al crear movimiento: ${e.message} - Creando offline...');
        return _createMovementOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al crear movimiento: ${e.message} - Creando offline...');
        return _createMovementOffline(params);
      } catch (e) {
        print('❌ Error inesperado al crear movimiento: $e - Creando offline...');
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
    print('📱 InventoryRepository: Creating movement offline');
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
            'type': params.type.name,
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
        print('📤 InventoryRepository: Operación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Movement created offline successfully');
      return Right(tempMovement);
    } catch (e) {
      print('❌ Error creating movement offline: $e');
      return Left(CacheFailure('Error al crear movimiento offline: $e'));
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
        print('⚠️ ServerException al actualizar movimiento: ${e.message} - Actualizando offline...');
        return _updateMovementOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al actualizar movimiento: ${e.message} - Actualizando offline...');
        return _updateMovementOffline(params);
      } catch (e) {
        print('❌ Error inesperado al actualizar movimiento: $e - Actualizando offline...');
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
    print('📱 InventoryRepository: Updating movement offline: ${params.id}');
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
      print('✅ InventoryRepository: Movimiento actualizado en ISAR');

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
        print('📤 Actualización agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Movement updated offline successfully');
      return Right(updatedMovement);
    } catch (e) {
      print('❌ Error updating movement offline: $e');
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
            print('✅ Movement marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        // Clear related caches
        await localDataSource.clearMovementsCache();

        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ ServerException al eliminar: ${e.message} - Fallback offline...');
        return _deleteMovementOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al eliminar: ${e.message} - Fallback offline...');
        return _deleteMovementOffline(id);
      } catch (e) {
        print('⚠️ Exception al eliminar: $e - Fallback offline...');
        return _deleteMovementOffline(id);
      }
    } else {
      // Sin conexión, eliminar offline
      return _deleteMovementOffline(id);
    }
  }

  Future<Either<Failure, void>> _deleteMovementOffline(String id) async {
    print('📱 InventoryRepository: Deleting movement offline: $id');
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
          print('✅ Movement marcado como eliminado en ISAR (offline): $id');
        }
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
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
        print('📤 Eliminación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Movement deleted offline successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error deleting movement offline: $e');
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
        print('⚠️ ServerException al confirmar: ${e.message}');
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al confirmar: ${e.message}');
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        print('❌ Error inesperado al confirmar: $e');
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
        print('⚠️ ServerException al cancelar: ${e.message}');
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al cancelar: ${e.message}');
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        print('❌ Error inesperado al cancelar: $e');
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
    if (await networkInfo.isConnected) {
      try {
        final remoteMovements = await remoteDataSource.searchMovements(params);
        return Right(remoteMovements.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        print('⚠️ ServerException en search: ${e.message} - Usando cache...');
        return _searchMovementsFromCache(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en search: ${e.message} - Usando cache...');
        return _searchMovementsFromCache(params);
      } catch (e) {
        print('❌ Error inesperado en search: $e - Usando cache...');
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
        print('⚠️ ServerException en getBalances: ${e.message} - Usando cache...');
        return _getBalancesFromCache(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getBalances: ${e.message} - Usando cache...');
        return _getBalancesFromCache(params);
      } catch (e) {
        print('❌ Error inesperado en getBalances: $e - Usando cache...');
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
        print('⚠️ ServerException en getBalanceByProduct: ${e.message} - Usando cache...');
        return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getBalanceByProduct: ${e.message} - Usando cache...');
        return _getBalanceByProductFromCache(productId, warehouseId: warehouseId);
      } catch (e) {
        print('❌ Error inesperado en getBalanceByProduct: $e - Usando cache...');
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
        print('⚠️ ServerException en getLowStockProducts: ${e.message} - Usando cache...');
        return _getLowStockProductsFromCache(warehouseId: warehouseId);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getLowStockProducts: ${e.message} - Usando cache...');
        return _getLowStockProductsFromCache(warehouseId: warehouseId);
      } catch (e) {
        print('❌ Error inesperado en getLowStockProducts: $e - Usando cache...');
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
    if (await networkInfo.isConnected) {
      try {
        print(
          '🔍 REPOSITORY DEBUG: About to call remoteDataSource.getInventoryStats',
        );
        print(
          '🔍 REPOSITORY DEBUG: remoteDataSource type: ${remoteDataSource.runtimeType}',
        );
        final remoteStats = await remoteDataSource.getInventoryStats(params);
        // Cache successful result
        await localDataSource.cacheStats(params, remoteStats);
        return Right(remoteStats.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException en getInventoryStats: ${e.message} - Usando cache...');
        return _getInventoryStatsFromCache(params);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getInventoryStats: ${e.message} - Usando cache...');
        return _getInventoryStatsFromCache(params);
      } catch (e) {
        print('❌ Error inesperado en getInventoryStats: $e - Usando cache...');
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
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión'));
    }

    try {
      final remoteBalances = await remoteDataSource.getBalancesByProducts(
        productIds,
        warehouseId: warehouseId,
      );
      return Right(remoteBalances.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Error al obtener balances: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getOutOfStockProducts({
    String? warehouseId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión'));
    }

    try {
      final remoteBalances = await remoteDataSource.getOutOfStockProducts(
        warehouseId: warehouseId,
      );
      return Right(remoteBalances.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        ServerFailure('Error al obtener productos sin stock: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getExpiredProducts({
    String? warehouseId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión'));
    }

    try {
      final remoteBalances = await remoteDataSource.getExpiredProducts(
        warehouseId: warehouseId,
      );
      return Right(remoteBalances.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        ServerFailure('Error al obtener productos vencidos: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión'));
    }

    try {
      final remoteBalances = await remoteDataSource.getNearExpiryProducts(
        warehouseId: warehouseId,
        daysThreshold: daysThreshold,
      );
      return Right(remoteBalances.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al obtener productos próximos a vencer: ${e.toString()}',
        ),
      );
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
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión para crear ajustes'));
    }

    try {
      final movement = await remoteDataSource.createStockAdjustment(request);

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movement.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Error al crear ajuste de stock: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> createBulkStockAdjustments(
    List<CreateStockAdjustmentParams> adjustmentsList,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Se requiere conexión para crear ajustes'));
    }

    try {
      final requestsList =
          adjustmentsList
              .map(
                (params) => {
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
      return Left(
        ServerFailure('Error al crear ajustes masivos: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> createTransfer(
    CreateInventoryTransferParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para crear transferencias'),
      );
    }

    try {
      final request = {
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
      return Left(
        ServerFailure('Error al crear transferencia: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> confirmTransfer(
    String transferId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para confirmar transferencias'),
      );
    }

    try {
      final movement = await remoteDataSource.confirmTransfer(transferId);

      // Clear caches to force refresh
      await localDataSource.clearMovementsCache();
      await localDataSource.clearBalancesCache();

      return Right(movement.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Error al confirmar transferencia: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para obtener valoración'),
      );
    }

    try {
      final valuation = await remoteDataSource.getInventoryValuation(
        warehouseId: warehouseId,
        asOfDate: asOfDate,
      );
      return Right(valuation);
    } catch (e) {
      return Left(
        ServerFailure('Error al obtener valoración: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, KardexReport>> getKardexReport(
    KardexReportParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para generar reporte kardex'),
      );
    }

    try {
      final kardexReportModel = await remoteDataSource.getKardexReport(params);
      return Right(kardexReportModel.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Error al generar reporte kardex: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryAging({
    String? warehouseId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(
        NetworkFailure('Se requiere conexión para obtener antigüedad'),
      );
    }

    try {
      final aging = await remoteDataSource.getInventoryAging(
        warehouseId: warehouseId,
      );
      return Right(aging);
    } catch (e) {
      return Left(
        ServerFailure(
          'Error al obtener antigüedad de inventario: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> getBatches(
    InventoryBatchQueryParams params,
  ) async {
    try {
      if (await networkInfo.isConnected) {
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
      } else {
        return Left(NetworkFailure('Se requiere conexión para obtener lotes'));
      }
    } catch (e) {
      return Left(ServerFailure('Error al obtener lotes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryBatch>> getBatchById(String id) async {
    try {
      if (await networkInfo.isConnected) {
        final batchMap = await remoteDataSource.getBatchById(id);
        final batch = InventoryBatchModel.fromJson(batchMap).toEntity();
        return Right(batch);
      } else {
        return Left(NetworkFailure('Se requiere conexión para obtener lote'));
      }
    } catch (e) {
      return Left(ServerFailure('Error al obtener lote: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Warehouse>>> getWarehouses() async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModels = await remoteDataSource.getWarehouses();
        final warehouses =
            warehouseModels.map((model) => model.toEntity()).toList();

        // Cache en local storage si es necesario
        // await localDataSource.cacheWarehouses(warehouseModels);

        return Right(warehouses);
      } else {
        // Intentar obtener desde cache local si no hay conexión
        // final cachedWarehouses = await localDataSource.getCachedWarehouses();
        // if (cachedWarehouses.isNotEmpty) {
        //   return Right(cachedWarehouses.map((model) => model.toEntity()).toList());
        // }
        return Left(
          NetworkFailure('Se requiere conexión para obtener almacenes'),
        );
      }
    } catch (e) {
      return Left(ServerFailure('Error al obtener almacenes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Warehouse>> createWarehouse(
    CreateWarehouseParams params,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModel = await remoteDataSource.createWarehouse(params);
        return Right(warehouseModel.toEntity());
      } else {
        return Left(NetworkFailure('Se requiere conexión para crear almacén'));
      }
    } catch (e) {
      return Left(ServerFailure('Error al crear almacén: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Warehouse>> updateWarehouse(
    String id,
    UpdateWarehouseParams params,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModel = await remoteDataSource.updateWarehouse(
          id,
          params,
        );
        return Right(warehouseModel.toEntity());
      } else {
        return Left(
          NetworkFailure('Se requiere conexión para actualizar almacén'),
        );
      }
    } catch (e) {
      return Left(
        ServerFailure('Error al actualizar almacén: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteWarehouse(String id) async {
    try {
      if (await networkInfo.isConnected) {
        final result = await remoteDataSource.deleteWarehouse(id);
        return Right(result);
      } else {
        return Left(
          NetworkFailure('Se requiere conexión para eliminar almacén'),
        );
      }
    } catch (e) {
      return Left(ServerFailure('Error al eliminar almacén: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Warehouse>> getWarehouseById(String id) async {
    try {
      if (await networkInfo.isConnected) {
        final warehouseModel = await remoteDataSource.getWarehouseById(id);
        return Right(warehouseModel.toEntity());
      } else {
        return Left(
          NetworkFailure('Se requiere conexión para obtener almacén'),
        );
      }
    } catch (e) {
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
        return Left(
          NetworkFailure('Se requiere conexión para verificar código'),
        );
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
        return Left(
          NetworkFailure('Se requiere conexión para verificar movimientos'),
        );
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
        return Left(
          NetworkFailure('Se requiere conexión para contar almacenes'),
        );
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
        return Left(
          NetworkFailure(
            'Se requiere conexión para obtener estadísticas del almacén',
          ),
        );
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
      return const Left(CacheFailure('Datos no encontrados en cache'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener movimientos desde cache: $e'));
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
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al buscar movimientos desde cache: $e'));
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
      return const Left(CacheFailure('Datos no encontrados en cache'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener balances desde cache: $e'));
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
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener productos con bajo stock desde cache: $e'));
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
      return const Left(CacheFailure('Datos no encontrados en cache'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener estadísticas desde cache: $e'));
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

    print(
      '🔍 SEARCH FALLBACK: Filtrado ${batches.length} lotes con query: "$searchQuery"',
    );
  }

  void _applySpecialFilters(
    List<InventoryBatch> batches,
    InventoryBatchQueryParams params,
  ) {
    if (params.activeOnly == true) {
      batches.removeWhere((batch) => !batch.isActive);
      print(
        '🔍 FILTER FALLBACK: Filtro Solo Activos aplicado - ${batches.length} lotes',
      );
    }

    if (params.expiredOnly == true) {
      batches.removeWhere((batch) => !batch.isExpiredByDate);
      print(
        '🔍 FILTER FALLBACK: Filtro Solo Vencidos aplicado - ${batches.length} lotes',
      );
    }

    if (params.nearExpiryOnly == true) {
      batches.removeWhere((batch) => !batch.isNearExpiry);
      print(
        '🔍 FILTER FALLBACK: Filtro Por Vencer aplicado - ${batches.length} lotes',
      );
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
