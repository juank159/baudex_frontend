// lib/features/inventory/data/repositories/inventory_offline_repository.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/entities/warehouse_with_stats.dart';
import '../../domain/entities/kardex_report.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/isar/isar_inventory_movement.dart';
import '../../../products/data/models/isar/isar_product.dart';

/// Implementación offline del repositorio de inventario usando ISAR
///
/// NOTA: Esta es una implementación básica que cubre las operaciones principales
/// de movimientos de inventario. Algunas operaciones avanzadas (FIFO, Kardex, etc.)
/// retornan valores por defecto o errores hasta que se implementen completamente.
class InventoryOfflineRepository implements InventoryRepository {
  final IsarDatabase _database;

  InventoryOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== MOVEMENTS ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getMovements(
    InventoryMovementQueryParams params,
  ) async {
    try {
      var query = _isar.isarInventoryMovements.filter().deletedAtIsNull();

      // Apply search filter
      if (params.search != null && params.search!.isNotEmpty) {
        query = query.and().group((q) => q
            .productNameContains(params.search!, caseSensitive: false)
            .or()
            .productSkuContains(params.search!, caseSensitive: false));
      }

      // Apply productId filter
      if (params.productId != null) {
        query = query.and().productIdEqualTo(params.productId!);
      }

      // Apply type filter
      if (params.type != null) {
        final isarType = _mapMovementType(params.type!);
        query = query.and().typeEqualTo(isarType);
      }

      // Apply status filter
      if (params.status != null) {
        final isarStatus = _mapMovementStatus(params.status!);
        query = query.and().statusEqualTo(isarStatus);
      }

      // Apply reason filter
      if (params.reason != null) {
        final isarReason = _mapMovementReason(params.reason!);
        query = query.and().reasonEqualTo(isarReason);
      }

      // Apply warehouseId filter
      if (params.warehouseId != null) {
        query = query.and().warehouseIdEqualTo(params.warehouseId!);
      }

      // Apply date filters
      if (params.startDate != null) {
        query = query.and().movementDateGreaterThan(params.startDate!);
      }

      if (params.endDate != null) {
        query = query.and().movementDateLessThan(params.endDate!);
      }

      // Fetch all filtered results
      var isarMovements = await query.findAll();

      // Get total count after filters
      final totalItems = isarMovements.length;

      // Sort in memory
      if (params.sortBy == 'movementDate') {
        isarMovements.sort((a, b) => params.sortOrder == 'desc'
            ? b.movementDate.compareTo(a.movementDate)
            : a.movementDate.compareTo(b.movementDate));
      } else if (params.sortBy == 'createdAt') {
        isarMovements.sort((a, b) => params.sortOrder == 'desc'
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
      } else {
        // Default sort by movementDate desc
        isarMovements.sort((a, b) => b.movementDate.compareTo(a.movementDate));
      }

      // Paginate in memory
      final offset = (params.page - 1) * params.limit;
      final paginatedMovements = isarMovements.skip(offset).take(params.limit).toList();

      // Convert to domain entities
      final movements = paginatedMovements.map((isar) => isar.toEntity()).toList();

      // Create pagination meta
      final totalPages = (totalItems / params.limit).ceil();
      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      // Create paginated result
      final result = core.PaginatedResult(
        data: movements,
        meta: meta,
      );

      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Error loading movements: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> getMovementById(String id) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movement not found'));
      }

      return Right(isarMovement.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> createMovement(
    CreateInventoryMovementParams params,
  ) async {
    try {
      final now = DateTime.now();
      final serverId = 'movement_${now.millisecondsSinceEpoch}_${params.productId.hashCode}';

      // Get product name and SKU from products collection
      final product = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(params.productId)
          .findFirst();

      final isarMovement = IsarInventoryMovement.create(
        serverId: serverId,
        productId: params.productId,
        productName: product?.name ?? 'Unknown Product',
        productSku: product?.sku ?? 'N/A',
        type: _mapMovementType(params.type),
        status: IsarInventoryMovementStatus.pending,
        reason: _mapMovementReason(params.reason),
        quantity: params.quantity,
        unitCost: params.unitCost,
        totalCost: params.quantity * params.unitCost,
        unitPrice: null,
        totalPrice: null,
        lotNumber: params.lotNumber,
        expiryDate: params.expiryDate,
        warehouseId: params.warehouseId,
        warehouseName: null, // TODO: Get warehouse name
        referenceId: params.referenceId,
        referenceType: params.referenceType,
        notes: params.notes,
        userId: 'offline', // TODO: Get from auth context
        userName: null,
        metadataJson: null,
        movementDate: params.movementDate ?? now,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.put(isarMovement);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'productId': params.productId,
            'type': params.type.name,
            'reason': params.reason.name,
            'quantity': params.quantity,
            'unitCost': params.unitCost,
            'warehouseId': params.warehouseId,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarMovement.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> updateMovement(
    UpdateInventoryMovementParams params,
  ) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(params.id)
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movement not found'));
      }

      // Update fields
      if (params.type != null) isarMovement.type = _mapMovementType(params.type!);
      if (params.reason != null) isarMovement.reason = _mapMovementReason(params.reason!);
      if (params.quantity != null) {
        isarMovement.quantity = params.quantity!;
        isarMovement.totalCost = params.quantity! * isarMovement.unitCost;
      }
      if (params.unitCost != null) {
        isarMovement.unitCost = params.unitCost!;
        isarMovement.totalCost = isarMovement.quantity * params.unitCost!;
      }
      if (params.lotNumber != null) isarMovement.lotNumber = params.lotNumber;
      if (params.expiryDate != null) isarMovement.expiryDate = params.expiryDate;
      if (params.warehouseId != null) isarMovement.warehouseId = params.warehouseId;
      if (params.referenceId != null) isarMovement.referenceId = params.referenceId;
      if (params.referenceType != null) isarMovement.referenceType = params.referenceType;
      if (params.notes != null) isarMovement.notes = params.notes;
      if (params.movementDate != null) isarMovement.movementDate = params.movementDate!;

      isarMovement.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.put(isarMovement);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarMovement.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMovement(String id) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movement not found'));
      }

      isarMovement.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.put(isarMovement);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'InventoryMovement',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> confirmMovement(String id) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movement not found'));
      }

      isarMovement.status = IsarInventoryMovementStatus.confirmed;
      isarMovement.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.put(isarMovement);
      });

      return Right(isarMovement.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error confirming movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> cancelMovement(String id) async {
    try {
      final isarMovement = await _isar.isarInventoryMovements
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarMovement == null) {
        return Left(CacheFailure('Movement not found'));
      }

      isarMovement.status = IsarInventoryMovementStatus.cancelled;
      isarMovement.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.put(isarMovement);
      });

      return Right(isarMovement.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error cancelling movement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> searchMovements(
    SearchInventoryMovementsParams params,
  ) async {
    try {
      var query = _isar.isarInventoryMovements
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .productNameContains(params.searchTerm, caseSensitive: false)
              .or()
              .productSkuContains(params.searchTerm, caseSensitive: false));

      if (params.type != null) {
        final isarType = _mapMovementType(params.type!);
        query = query.and().typeEqualTo(isarType);
      }

      if (params.warehouseId != null) {
        query = query.and().warehouseIdEqualTo(params.warehouseId!);
      }

      final isarMovements = await query.limit(params.limit).findAll();
      final movements = isarMovements.map((isar) => isar.toEntity()).toList();

      return Right(movements);
    } catch (e) {
      return Left(CacheFailure('Error searching movements: ${e.toString()}'));
    }
  }

  // ==================== BALANCES ====================
  // NOTE: Balance operations are not implemented in offline repository yet
  // They require complex calculations across movements

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> getBalances(
    InventoryBalanceQueryParams params,
  ) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, InventoryBalance>> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getLowStockProducts({
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getOutOfStockProducts({
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getExpiredProducts({
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    return Left(ServerFailure('Balance operations not supported offline'));
  }

  // ==================== FIFO OPERATIONS ====================
  // NOTE: FIFO operations are not implemented in offline repository yet

  @override
  Future<Either<Failure, List<FifoConsumption>>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  }) async {
    return Left(ServerFailure('FIFO operations not supported offline'));
  }

  @override
  Future<Either<Failure, InventoryMovement>> processOutboundMovementFifo(
    ProcessFifoMovementParams params,
  ) async {
    return Left(ServerFailure('FIFO operations not supported offline'));
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> processBulkOutboundMovementFifo(
    List<ProcessFifoMovementParams> movementsList,
  ) async {
    return Left(ServerFailure('FIFO operations not supported offline'));
  }

  // ==================== ADJUSTMENTS ====================

  @override
  Future<Either<Failure, InventoryMovement>> createStockAdjustment(
    Map<String, dynamic> request,
  ) async {
    return Left(ServerFailure('Stock adjustment not implemented offline'));
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> createBulkStockAdjustments(
    List<CreateStockAdjustmentParams> adjustmentsList,
  ) async {
    return Left(ServerFailure('Bulk adjustments not supported offline'));
  }

  // ==================== TRANSFERS ====================

  @override
  Future<Either<Failure, InventoryMovement>> createTransfer(
    CreateInventoryTransferParams params,
  ) async {
    return Left(ServerFailure('Transfer operations not supported offline'));
  }

  @override
  Future<Either<Failure, InventoryMovement>> confirmTransfer(String transferId) async {
    return Left(ServerFailure('Transfer operations not supported offline'));
  }

  // ==================== STATS ====================

  @override
  Future<Either<Failure, InventoryStats>> getInventoryStats(
    InventoryStatsParams params,
  ) async {
    return Left(ServerFailure('Stats operations not supported offline'));
  }

  @override
  Future<Either<Failure, Map<String, double>>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    return Left(ServerFailure('Valuation operations not supported offline'));
  }

  // ==================== BATCHES ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> getBatches(
    InventoryBatchQueryParams params,
  ) async {
    return Left(ServerFailure('Batch operations not supported offline'));
  }

  @override
  Future<Either<Failure, InventoryBatch>> getBatchById(String id) async {
    return Left(ServerFailure('Batch operations not supported offline'));
  }

  // ==================== REPORTS ====================

  @override
  Future<Either<Failure, KardexReport>> getKardexReport(
    KardexReportParams params,
  ) async {
    return Left(ServerFailure('Kardex reports not supported offline'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryAging({
    String? warehouseId,
  }) async {
    return Left(ServerFailure('Aging reports not supported offline'));
  }

  // ==================== WAREHOUSES ====================

  @override
  Future<Either<Failure, List<Warehouse>>> getWarehouses() async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, Warehouse>> createWarehouse(CreateWarehouseParams params) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, Warehouse>> updateWarehouse(String id, UpdateWarehouseParams params) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, bool>> deleteWarehouse(String id) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, Warehouse>> getWarehouseById(String id) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, bool>> checkWarehouseCodeExists(String code, {String? excludeId}) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, bool>> checkWarehouseHasMovements(String warehouseId) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getWarehouseMovements(
    String warehouseId,
    InventoryMovementQueryParams params,
  ) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, int>> getActiveWarehousesCount() async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  @override
  Future<Either<Failure, WarehouseStats>> getWarehouseStats(String warehouseId) async {
    return Left(ServerFailure('Warehouse operations not supported offline'));
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<InventoryMovement>>> getUnsyncedMovements() async {
    try {
      final isarMovements = await _isar.isarInventoryMovements
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final movements = isarMovements.map((isar) => isar.toEntity()).toList();
      return Right(movements);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced movements: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> markMovementsAsSynced(List<String> movementIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in movementIds) {
          final isarMovement = await _isar.isarInventoryMovements
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarMovement != null) {
            isarMovement.markAsSynced();
            await _isar.isarInventoryMovements.put(isarMovement);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking movements as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsertMovements(List<InventoryMovement> movements) async {
    try {
      final isarMovements = movements
          .map((movement) => IsarInventoryMovement.fromEntity(movement))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryMovements.putAll(isarMovements);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting movements: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarInventoryMovementType _mapMovementType(InventoryMovementType type) {
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

  IsarInventoryMovementStatus _mapMovementStatus(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return IsarInventoryMovementStatus.pending;
      case InventoryMovementStatus.confirmed:
        return IsarInventoryMovementStatus.confirmed;
      case InventoryMovementStatus.cancelled:
        return IsarInventoryMovementStatus.cancelled;
    }
  }

  IsarInventoryMovementReason _mapMovementReason(InventoryMovementReason reason) {
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
}
