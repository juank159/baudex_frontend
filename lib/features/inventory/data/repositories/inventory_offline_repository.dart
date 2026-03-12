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
import '../models/isar/isar_inventory_batch.dart';
import '../models/isar/isar_inventory_batch_movement.dart';
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

  /// Calcular balance de inventario para un producto basado en sus lotes
  Future<InventoryBalance?> _calculateProductBalance(
    String productId, {
    String? warehouseId,
  }) async {
    // Obtener producto
    final product = await _isar.isarProducts
        .filter()
        .serverIdEqualTo(productId)
        .findFirst();

    if (product == null) return null;

    // Obtener lotes del producto
    var batchQuery = _isar.isarInventoryBatchs
        .filter()
        .deletedAtIsNull()
        .and()
        .productIdEqualTo(productId);

    if (warehouseId != null) {
      batchQuery = batchQuery.and().warehouseIdEqualTo(warehouseId);
    }

    final batches = await batchQuery.findAll();

    // Calcular totales
    int totalQuantity = 0;
    int availableQuantity = 0;
    int expiredQuantity = 0;
    int nearExpiryQuantity = 0;
    double totalValue = 0;
    double totalCost = 0;
    final now = DateTime.now();
    final nearExpiryThreshold = now.add(const Duration(days: 30));

    final fifoLots = <InventoryLot>[];

    for (final batch in batches) {
      totalQuantity += batch.currentQuantity;
      totalCost += batch.currentQuantity * batch.unitCost;

      // Verificar estado del lote
      if (batch.status == IsarInventoryBatchStatus.active) {
        if (batch.expiryDate != null && batch.expiryDate!.isBefore(now)) {
          expiredQuantity += batch.currentQuantity;
        } else if (batch.expiryDate != null && batch.expiryDate!.isBefore(nearExpiryThreshold)) {
          nearExpiryQuantity += batch.currentQuantity;
          availableQuantity += batch.currentQuantity;
        } else {
          availableQuantity += batch.currentQuantity;
        }
      } else if (batch.status == IsarInventoryBatchStatus.expired) {
        expiredQuantity += batch.currentQuantity;
      }

      // Agregar lote a lista FIFO si tiene stock
      if (batch.currentQuantity > 0 && batch.status == IsarInventoryBatchStatus.active) {
        fifoLots.add(InventoryLot(
          lotNumber: batch.batchNumber,
          quantity: batch.currentQuantity,
          unitCost: batch.unitCost,
          entryDate: batch.entryDate,
          expiryDate: batch.expiryDate,
        ));
      }
    }

    // Ordenar lotes FIFO por fecha de entrada
    fifoLots.sort((a, b) => a.entryDate.compareTo(b.entryDate));

    // Calcular costo promedio
    final averageCost = totalQuantity > 0 ? totalCost / totalQuantity : 0.0;
    totalValue = totalCost;

    // Obtener stock mínimo del producto
    final minStock = (product.minStock ?? 0).toInt();

    return InventoryBalance(
      productId: productId,
      productName: product.name,
      productSku: product.sku,
      categoryName: '', // Se podría obtener de la categoría
      totalQuantity: totalQuantity,
      minStock: minStock,
      averageCost: averageCost,
      totalValue: totalValue,
      isLowStock: minStock > 0 && totalQuantity <= minStock && totalQuantity > 0,
      isOutOfStock: totalQuantity <= 0,
      warehouseId: warehouseId,
      fifoLots: fifoLots,
      availableQuantity: availableQuantity,
      reservedQuantity: 0,
      expiredQuantity: expiredQuantity,
      nearExpiryQuantity: nearExpiryQuantity,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> getBalances(
    InventoryBalanceQueryParams params,
  ) async {
    try {
      // Obtener todos los productos
      var productQuery = _isar.isarProducts.filter().deletedAtIsNull();

      if (params.search != null && params.search!.isNotEmpty) {
        productQuery = productQuery.and().group((q) => q
            .nameContains(params.search!, caseSensitive: false)
            .or()
            .skuContains(params.search!, caseSensitive: false));
      }

      if (params.categoryId != null) {
        productQuery = productQuery.and().categoryIdEqualTo(params.categoryId!);
      }

      final products = await productQuery.findAll();

      // Calcular balance para cada producto
      final balances = <InventoryBalance>[];

      for (final product in products) {
        final balance = await _calculateProductBalance(
          product.serverId,
          warehouseId: params.warehouseId,
        );

        if (balance != null) {
          // Aplicar filtros adicionales
          if (params.lowStock == true && !balance.isLowStock) continue;
          if (params.outOfStock == true && !balance.isOutOfStock) continue;
          if (params.nearExpiry == true && balance.nearExpiryQuantity <= 0) continue;
          if (params.expired == true && balance.expiredQuantity <= 0) continue;

          balances.add(balance);
        }
      }

      // Ordenar
      if (params.sortBy == 'productName') {
        balances.sort((a, b) => params.sortOrder == 'desc'
            ? b.productName.compareTo(a.productName)
            : a.productName.compareTo(b.productName));
      } else if (params.sortBy == 'totalQuantity') {
        balances.sort((a, b) => params.sortOrder == 'desc'
            ? b.totalQuantity.compareTo(a.totalQuantity)
            : a.totalQuantity.compareTo(b.totalQuantity));
      } else if (params.sortBy == 'totalValue') {
        balances.sort((a, b) => params.sortOrder == 'desc'
            ? b.totalValue.compareTo(a.totalValue)
            : a.totalValue.compareTo(b.totalValue));
      }

      // Paginar
      final totalItems = balances.length;
      final offset = (params.page - 1) * params.limit;
      final paginatedBalances = balances.skip(offset).take(params.limit).toList();

      final totalPages = (totalItems / params.limit).ceil();
      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      return Right(core.PaginatedResult(
        data: paginatedBalances,
        meta: meta,
      ));
    } catch (e) {
      return Left(CacheFailure('Error loading balances offline: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryBalance>> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      final balance = await _calculateProductBalance(productId, warehouseId: warehouseId);

      if (balance == null) {
        return Left(CacheFailure('Producto no encontrado'));
      }

      return Right(balance);
    } catch (e) {
      return Left(CacheFailure('Error loading product balance: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  }) async {
    try {
      final balances = <InventoryBalance>[];

      for (final productId in productIds) {
        final balance = await _calculateProductBalance(productId, warehouseId: warehouseId);
        if (balance != null) {
          balances.add(balance);
        }
      }

      return Right(balances);
    } catch (e) {
      return Left(CacheFailure('Error loading products balances: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getLowStockProducts({
    String? warehouseId,
  }) async {
    try {
      final result = await getBalances(InventoryBalanceQueryParams(
        warehouseId: warehouseId,
        lowStock: true,
        limit: 1000,
      ));

      return result.fold(
        (failure) => Left(failure),
        (paginated) => Right(paginated.data),
      );
    } catch (e) {
      return Left(CacheFailure('Error loading low stock products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getOutOfStockProducts({
    String? warehouseId,
  }) async {
    try {
      final result = await getBalances(InventoryBalanceQueryParams(
        warehouseId: warehouseId,
        outOfStock: true,
        limit: 1000,
      ));

      return result.fold(
        (failure) => Left(failure),
        (paginated) => Right(paginated.data),
      );
    } catch (e) {
      return Left(CacheFailure('Error loading out of stock products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getExpiredProducts({
    String? warehouseId,
  }) async {
    try {
      final result = await getBalances(InventoryBalanceQueryParams(
        warehouseId: warehouseId,
        expired: true,
        limit: 1000,
      ));

      return result.fold(
        (failure) => Left(failure),
        (paginated) => Right(paginated.data),
      );
    } catch (e) {
      return Left(CacheFailure('Error loading expired products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBalance>>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    try {
      final result = await getBalances(InventoryBalanceQueryParams(
        warehouseId: warehouseId,
        nearExpiry: true,
        limit: 1000,
      ));

      return result.fold(
        (failure) => Left(failure),
        (paginated) => Right(paginated.data),
      );
    } catch (e) {
      return Left(CacheFailure('Error loading near expiry products: ${e.toString()}'));
    }
  }

  // ==================== FIFO OPERATIONS ====================

  @override
  Future<Either<Failure, List<FifoConsumption>>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  }) async {
    try {
      // Obtener lotes activos ordenados por fecha de entrada (FIFO - más antiguo primero)
      var query = _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .productIdEqualTo(productId)
          .and()
          .statusEqualTo(IsarInventoryBatchStatus.active)
          .and()
          .currentQuantityGreaterThan(0);

      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }

      // Ordenar por fecha de entrada (más antiguo primero para FIFO)
      final batches = await query.findAll();
      batches.sort((a, b) => a.entryDate.compareTo(b.entryDate));

      // Calcular consumo FIFO
      final consumptions = <FifoConsumption>[];
      var remainingQuantity = quantity;

      for (final batch in batches) {
        if (remainingQuantity <= 0) break;

        // Cantidad a consumir de este lote
        final toConsume = remainingQuantity > batch.currentQuantity
            ? batch.currentQuantity
            : remainingQuantity;

        // Crear registro de consumo
        final lot = InventoryLot(
          lotNumber: batch.batchNumber,
          quantity: batch.currentQuantity,
          unitCost: batch.unitCost,
          entryDate: batch.entryDate,
          expiryDate: batch.expiryDate,
        );

        consumptions.add(FifoConsumption(
          lot: lot,
          quantityConsumed: toConsume,
          unitCost: batch.unitCost,
          totalCost: toConsume * batch.unitCost,
        ));

        remainingQuantity -= toConsume;
      }

      // Verificar si hay stock suficiente
      if (remainingQuantity > 0) {
        return Left(ValidationFailure([
          'Stock insuficiente. Faltan $remainingQuantity unidades para completar la operación FIFO.',
        ]));
      }

      return Right(consumptions);
    } catch (e) {
      return Left(CacheFailure('Error calculando consumo FIFO: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryMovement>> processOutboundMovementFifo(
    ProcessFifoMovementParams params,
  ) async {
    try {
      // 1. Calcular qué lotes se van a consumir
      final consumptionResult = await calculateFifoConsumption(
        params.productId,
        params.quantity,
        warehouseId: params.warehouseId,
      );

      return consumptionResult.fold(
        (failure) => Left(failure),
        (consumptions) async {
          final now = DateTime.now();
          final movementId = 'mov_fifo_${now.millisecondsSinceEpoch}_${params.productId.hashCode}';

          // Obtener información del producto
          final product = await _isar.isarProducts
              .filter()
              .serverIdEqualTo(params.productId)
              .findFirst();

          // Calcular costo total ponderado
          double totalCost = 0;
          for (final consumption in consumptions) {
            totalCost += consumption.totalCost;
          }
          final weightedUnitCost = params.quantity > 0 ? totalCost / params.quantity : 0.0;

          // 2. Crear el movimiento principal
          final isarMovement = IsarInventoryMovement.create(
            serverId: movementId,
            productId: params.productId,
            productName: product?.name ?? 'Unknown Product',
            productSku: product?.sku ?? 'N/A',
            type: IsarInventoryMovementType.outbound,
            status: IsarInventoryMovementStatus.confirmed,
            reason: _mapMovementReason(params.reason),
            quantity: params.quantity,
            unitCost: weightedUnitCost,
            totalCost: totalCost,
            unitPrice: null,
            totalPrice: null,
            lotNumber: null,
            expiryDate: null,
            warehouseId: params.warehouseId,
            warehouseName: null,
            referenceId: params.referenceId,
            referenceType: params.referenceType,
            notes: params.notes ?? 'Movimiento FIFO offline',
            userId: 'offline',
            userName: null,
            metadataJson: null,
            movementDate: params.movementDate ?? now,
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
            isSynced: false,
            lastSyncAt: null,
          );

          // 3. Actualizar lotes y crear movimientos de lote
          final batchMovements = <IsarInventoryBatchMovement>[];
          final updatedBatches = <IsarInventoryBatch>[];

          for (final consumption in consumptions) {
            // Buscar el lote correspondiente
            final batch = await _isar.isarInventoryBatchs
                .filter()
                .deletedAtIsNull()
                .and()
                .productIdEqualTo(params.productId)
                .and()
                .batchNumberEqualTo(consumption.lot.lotNumber)
                .findFirst();

            if (batch != null) {
              // Actualizar cantidad del lote
              batch.consume(consumption.quantityConsumed, modifiedBy: 'offline_fifo');
              updatedBatches.add(batch);

              // Crear movimiento de lote
              final batchMovementId = 'bm_${now.millisecondsSinceEpoch}_${batch.serverId.hashCode}';
              final batchMovement = IsarInventoryBatchMovement.create(
                serverId: batchMovementId,
                batchId: batch.serverId,
                movementId: movementId,
                quantity: consumption.quantityConsumed,
                unitCost: consumption.unitCost,
                totalCost: consumption.totalCost,
                movementType: 'outbound',
                movementDate: params.movementDate ?? now,
                referenceId: params.referenceId,
                referenceType: params.referenceType,
                notes: 'Consumo FIFO: ${consumption.quantityConsumed} unidades del lote ${batch.batchNumber}',
                createdAt: now,
                updatedAt: now,
                isSynced: false,
              );
              batchMovements.add(batchMovement);
            }
          }

          // 4. Guardar todo en una transacción
          await _isar.writeTxn(() async {
            await _isar.isarInventoryMovements.put(isarMovement);
            await _isar.isarInventoryBatchs.putAll(updatedBatches);
            await _isar.isarInventoryBatchMovements.putAll(batchMovements);
          });

          // 5. Agregar a cola de sincronización
          try {
            final syncService = Get.find<SyncService>();

            // Agregar movimiento principal
            await syncService.addOperationForCurrentUser(
              entityType: 'inventory_movement_fifo',
              entityId: movementId,
              operationType: SyncOperationType.create,
              data: {
                'productId': params.productId,
                'type': 'outbound',
                'reason': params.reason.name,
                'quantity': params.quantity,
                'unitCost': weightedUnitCost,
                'totalCost': totalCost,
                'warehouseId': params.warehouseId,
                'referenceId': params.referenceId,
                'referenceType': params.referenceType,
                'notes': params.notes,
                'movementDate': params.movementDate?.toIso8601String() ?? now.toIso8601String(),
              },
            );
          } catch (e) {
            print('ERROR: No se pudo agregar movimiento FIFO a cola de sync: $e');
          }

          return Right(isarMovement.toEntity());
        },
      );
    } catch (e) {
      return Left(CacheFailure('Error procesando movimiento FIFO: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryMovement>>> processBulkOutboundMovementFifo(
    List<ProcessFifoMovementParams> movementsList,
  ) async {
    try {
      final results = <InventoryMovement>[];

      for (final params in movementsList) {
        final result = await processOutboundMovementFifo(params);

        final movement = result.fold(
          (failure) => throw Exception(failure.message),
          (movement) => movement,
        );

        results.add(movement);
      }

      return Right(results);
    } catch (e) {
      return Left(CacheFailure('Error procesando movimientos FIFO en lote: ${e.toString()}'));
    }
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
    try {
      // Contar productos únicos con lotes
      var batchQuery = _isar.isarInventoryBatchs.filter().deletedAtIsNull();

      if (params.warehouseId != null) {
        batchQuery = batchQuery.and().warehouseIdEqualTo(params.warehouseId!);
      }

      final batches = await batchQuery.findAll();
      final uniqueProductIds = batches.map((b) => b.productId).toSet();
      final totalProducts = uniqueProductIds.length;
      final totalBatches = batches.length;

      // Calcular valor total del inventario
      double totalValue = 0;
      int lowStockCount = 0;
      int expiredCount = 0;
      final now = DateTime.now();

      for (final batch in batches) {
        totalValue += batch.currentQuantity * batch.unitCost;

        if (batch.status == IsarInventoryBatchStatus.expired ||
            (batch.expiryDate != null && batch.expiryDate!.isBefore(now))) {
          expiredCount++;
        }
      }

      // Contar productos con stock bajo
      for (final productId in uniqueProductIds) {
        final product = await _isar.isarProducts
            .filter()
            .serverIdEqualTo(productId)
            .findFirst();

        if (product != null && product.minStock != null && product.minStock! > 0) {
          final productBatches = batches.where((b) => b.productId == productId);
          final totalStock = productBatches.fold<int>(
            0,
            (sum, batch) => sum + batch.currentQuantity,
          );

          if (totalStock <= product.minStock! && totalStock > 0) {
            lowStockCount++;
          }
        }
      }

      // Obtener movimientos
      var movementQuery = _isar.isarInventoryMovements.filter().deletedAtIsNull();

      if (params.warehouseId != null) {
        movementQuery = movementQuery.and().warehouseIdEqualTo(params.warehouseId!);
      }

      if (params.startDate != null) {
        movementQuery = movementQuery.and().movementDateGreaterThan(params.startDate!);
      }

      if (params.endDate != null) {
        movementQuery = movementQuery.and().movementDateLessThan(params.endDate!);
      }

      final movements = await movementQuery.findAll();
      final totalMovements = movements.length;

      // Contar movimientos por tipo
      int inboundCount = 0;
      int outboundCount = 0;
      int adjustmentCount = 0;
      int transferCount = 0;

      // Movimientos de hoy
      final startOfDay = DateTime(now.year, now.month, now.day);
      int movementsToday = 0;

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

        if (movement.movementDate.isAfter(startOfDay)) {
          movementsToday++;
        }
      }

      return Right(InventoryStats(
        totalProducts: totalProducts,
        totalBatches: totalBatches,
        totalMovements: totalMovements,
        totalValue: totalValue,
        movementsByType: {
          'inbound': inboundCount,
          'outbound': outboundCount,
          'adjustment': adjustmentCount,
          'transfer': transferCount,
          'today': movementsToday,
          'lowStock': lowStockCount,
          'expired': expiredCount,
        },
      ));
    } catch (e) {
      return Left(CacheFailure('Error loading inventory stats offline: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    try {
      var batchQuery = _isar.isarInventoryBatchs.filter().deletedAtIsNull();

      if (warehouseId != null) {
        batchQuery = batchQuery.and().warehouseIdEqualTo(warehouseId);
      }

      // Si hay fecha, filtrar por lotes creados antes de esa fecha
      if (asOfDate != null) {
        batchQuery = batchQuery.and().entryDateLessThan(asOfDate);
      }

      final batches = await batchQuery.findAll();

      // Agrupar valoración por producto
      final valuationByProduct = <String, double>{};
      double totalValuation = 0;

      for (final batch in batches) {
        final value = batch.currentQuantity * batch.unitCost;
        valuationByProduct[batch.productId] =
            (valuationByProduct[batch.productId] ?? 0) + value;
        totalValuation += value;
      }

      // Calcular por categorías si es posible
      final valuationByCategory = <String, double>{};
      for (final productId in valuationByProduct.keys) {
        final product = await _isar.isarProducts
            .filter()
            .serverIdEqualTo(productId)
            .findFirst();

        if (product != null && product.categoryId != null) {
          valuationByCategory[product.categoryId!] =
              (valuationByCategory[product.categoryId!] ?? 0) +
                  valuationByProduct[productId]!;
        }
      }

      return Right({
        'totalValue': totalValuation,
        'productCount': valuationByProduct.length.toDouble(),
        'batchCount': batches.length.toDouble(),
        ...valuationByCategory,
      });
    } catch (e) {
      return Left(CacheFailure('Error calculating inventory valuation offline: ${e.toString()}'));
    }
  }

  // ==================== BATCHES ====================

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> getBatches(
    InventoryBatchQueryParams params,
  ) async {
    try {
      // Importar IsarInventoryBatch
      var query = _isar.isarInventoryBatchs.filter().deletedAtIsNull();

      // Apply search filter
      if (params.search != null && params.search!.isNotEmpty) {
        query = query.and().group((q) => q
            .batchNumberContains(params.search!, caseSensitive: false)
            .or()
            .productNameContains(params.search!, caseSensitive: false)
            .or()
            .productSkuContains(params.search!, caseSensitive: false));
      }

      // Apply productId filter
      if (params.productId != null) {
        query = query.and().productIdEqualTo(params.productId!);
      }

      // Apply warehouseId filter
      if (params.warehouseId != null) {
        query = query.and().warehouseIdEqualTo(params.warehouseId!);
      }

      // Apply status filter
      if (params.status != null) {
        final isarStatus = _mapBatchStatus(params.status!);
        query = query.and().statusEqualTo(isarStatus);
      }

      // Fetch all filtered results
      var isarBatches = await query.findAll();

      // Apply expiry filters in memory
      if (params.nearExpiryOnly == true) {
        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 30));
        isarBatches = isarBatches.where((batch) {
          if (batch.expiryDate == null) return false;
          return batch.expiryDate!.isAfter(now) && batch.expiryDate!.isBefore(threshold);
        }).toList();
      }

      if (params.expiredOnly == true) {
        final now = DateTime.now();
        isarBatches = isarBatches.where((batch) {
          if (batch.expiryDate == null) return false;
          return batch.expiryDate!.isBefore(now);
        }).toList();
      }

      // Get total count after filters
      final totalItems = isarBatches.length;

      // Sort in memory
      if (params.sortBy == 'expiryDate') {
        isarBatches.sort((a, b) {
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return params.sortOrder == 'desc'
              ? b.expiryDate!.compareTo(a.expiryDate!)
              : a.expiryDate!.compareTo(b.expiryDate!);
        });
      } else if (params.sortBy == 'entryDate') {
        isarBatches.sort((a, b) => params.sortOrder == 'desc'
            ? b.entryDate.compareTo(a.entryDate)
            : a.entryDate.compareTo(b.entryDate));
      } else {
        // Default sort by createdAt desc
        isarBatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Paginate in memory
      final offset = (params.page - 1) * params.limit;
      final paginatedBatches = isarBatches.skip(offset).take(params.limit).toList();

      // Convert to domain entities
      final batches = paginatedBatches.map((isar) => isar.toEntity()).toList();

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
        data: batches,
        meta: meta,
      );

      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Error loading batches: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InventoryBatch>> getBatchById(String id) async {
    try {
      final isarBatch = await _isar.isarInventoryBatchs
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarBatch == null) {
        return Left(CacheFailure('Batch not found'));
      }

      return Right(isarBatch.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading batch: ${e.toString()}'));
    }
  }

  /// Get expired batches
  Future<Either<Failure, List<InventoryBatch>>> getExpiredBatches({
    String? warehouseId,
  }) async {
    try {
      final now = DateTime.now();
      var query = _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .expiryDateIsNotNull()
          .and()
          .expiryDateLessThan(now);

      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }

      final isarBatches = await query.findAll();
      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      return Right(batches);
    } catch (e) {
      return Left(CacheFailure('Error loading expired batches: ${e.toString()}'));
    }
  }

  /// Get near expiry batches
  Future<Either<Failure, List<InventoryBatch>>> getNearExpiryBatches({
    String? warehouseId,
    int daysThreshold = 30,
  }) async {
    try {
      final now = DateTime.now();
      final threshold = now.add(Duration(days: daysThreshold));

      var query = _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .expiryDateIsNotNull()
          .and()
          .expiryDateGreaterThan(now)
          .and()
          .expiryDateLessThan(threshold);

      if (warehouseId != null) {
        query = query.and().warehouseIdEqualTo(warehouseId);
      }

      final isarBatches = await query.findAll();
      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      return Right(batches);
    } catch (e) {
      return Left(CacheFailure('Error loading near expiry batches: ${e.toString()}'));
    }
  }

  /// Get batches by product
  Future<Either<Failure, List<InventoryBatch>>> getBatchesByProduct(
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

      final isarBatches = await query.findAll();
      final batches = isarBatches.map((isar) => isar.toEntity()).toList();

      return Right(batches);
    } catch (e) {
      return Left(CacheFailure('Error loading batches by product: ${e.toString()}'));
    }
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

  /// Get unsynced batches
  Future<Either<Failure, List<InventoryBatch>>> getUnsyncedBatches() async {
    try {
      final isarBatches = await _isar.isarInventoryBatchs
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final batches = isarBatches.map((isar) => isar.toEntity()).toList();
      return Right(batches);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced batches: ${e.toString()}'));
    }
  }

  /// Mark batches as synced
  Future<Either<Failure, void>> markBatchesAsSynced(List<String> batchIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in batchIds) {
          final isarBatch = await _isar.isarInventoryBatchs
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarBatch != null) {
            isarBatch.markAsSynced();
            await _isar.isarInventoryBatchs.put(isarBatch);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking batches as synced: ${e.toString()}'));
    }
  }

  /// Bulk insert batches
  Future<Either<Failure, void>> bulkInsertBatches(List<InventoryBatch> batches) async {
    try {
      final isarBatches = batches
          .map((batch) => IsarInventoryBatch.fromEntity(batch))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarInventoryBatchs.putAll(isarBatches);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting batches: ${e.toString()}'));
    }
  }

  /// Get unsynced batch movements
  Future<Either<Failure, List<BatchMovement>>> getUnsyncedBatchMovements() async {
    try {
      final isarMovements = await _isar.isarInventoryBatchMovements
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final movements = isarMovements.map((isar) => isar.toEntity()).toList();
      return Right(movements);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced batch movements: ${e.toString()}'));
    }
  }

  /// Mark batch movements as synced
  Future<Either<Failure, void>> markBatchMovementsAsSynced(List<String> movementIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in movementIds) {
          final isarMovement = await _isar.isarInventoryBatchMovements
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarMovement != null) {
            isarMovement.markAsSynced();
            await _isar.isarInventoryBatchMovements.put(isarMovement);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking batch movements as synced: ${e.toString()}'));
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

  IsarInventoryBatchStatus _mapBatchStatus(InventoryBatchStatus status) {
    switch (status) {
      case InventoryBatchStatus.active:
        return IsarInventoryBatchStatus.active;
      case InventoryBatchStatus.depleted:
        return IsarInventoryBatchStatus.depleted;
      case InventoryBatchStatus.expired:
        return IsarInventoryBatchStatus.expired;
      case InventoryBatchStatus.blocked:
        return IsarInventoryBatchStatus.blocked;
    }
  }
}
