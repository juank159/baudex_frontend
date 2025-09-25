// lib/features/inventory/domain/repositories/inventory_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../entities/inventory_movement.dart';
import '../entities/inventory_balance.dart';
import '../entities/inventory_batch.dart';
import '../entities/inventory_stats.dart';
import '../entities/warehouse.dart';
import '../entities/warehouse_with_stats.dart';
import '../entities/kardex_report.dart';
import 'package:equatable/equatable.dart';

abstract class InventoryRepository {
  // ==================== MOVEMENTS ====================
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getMovements(
    InventoryMovementQueryParams params,
  );

  Future<Either<Failure, InventoryMovement>> getMovementById(String id);

  Future<Either<Failure, InventoryMovement>> createMovement(
    CreateInventoryMovementParams params,
  );

  Future<Either<Failure, InventoryMovement>> updateMovement(
    UpdateInventoryMovementParams params,
  );

  Future<Either<Failure, void>> deleteMovement(String id);

  Future<Either<Failure, InventoryMovement>> confirmMovement(String id);

  Future<Either<Failure, InventoryMovement>> cancelMovement(String id);

  Future<Either<Failure, List<InventoryMovement>>> searchMovements(
    SearchInventoryMovementsParams params,
  );

  // ==================== BALANCES ====================
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> getBalances(
    InventoryBalanceQueryParams params,
  );

  Future<Either<Failure, InventoryBalance>> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  });

  Future<Either<Failure, List<InventoryBalance>>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  });

  Future<Either<Failure, List<InventoryBalance>>> getLowStockProducts({
    String? warehouseId,
  });

  Future<Either<Failure, List<InventoryBalance>>> getOutOfStockProducts({
    String? warehouseId,
  });

  Future<Either<Failure, List<InventoryBalance>>> getExpiredProducts({
    String? warehouseId,
  });

  Future<Either<Failure, List<InventoryBalance>>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  });

  // ==================== FIFO OPERATIONS ====================
  Future<Either<Failure, List<FifoConsumption>>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  });

  Future<Either<Failure, InventoryMovement>> processOutboundMovementFifo(
    ProcessFifoMovementParams params,
  );

  Future<Either<Failure, List<InventoryMovement>>> processBulkOutboundMovementFifo(
    List<ProcessFifoMovementParams> movementsList,
  );

  // ==================== ADJUSTMENTS ====================
  Future<Either<Failure, InventoryMovement>> createStockAdjustment(
    Map<String, dynamic> request,
  );

  Future<Either<Failure, List<InventoryMovement>>> createBulkStockAdjustments(
    List<CreateStockAdjustmentParams> adjustmentsList,
  );

  // ==================== TRANSFERS ====================
  Future<Either<Failure, InventoryMovement>> createTransfer(
    CreateInventoryTransferParams params,
  );

  Future<Either<Failure, InventoryMovement>> confirmTransfer(String transferId);

  // ==================== STATS ====================
  Future<Either<Failure, InventoryStats>> getInventoryStats(
    InventoryStatsParams params,
  );

  Future<Either<Failure, Map<String, double>>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  });

  // ==================== BATCHES ====================
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> getBatches(
    InventoryBatchQueryParams params,
  );

  Future<Either<Failure, InventoryBatch>> getBatchById(String id);

  // ==================== REPORTS ====================
  Future<Either<Failure, KardexReport>> getKardexReport(
    KardexReportParams params,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getInventoryAging({
    String? warehouseId,
  });

  // ==================== WAREHOUSES ====================
  Future<Either<Failure, List<Warehouse>>> getWarehouses();
  Future<Either<Failure, Warehouse>> createWarehouse(CreateWarehouseParams params);
  Future<Either<Failure, Warehouse>> updateWarehouse(String id, UpdateWarehouseParams params);
  Future<Either<Failure, bool>> deleteWarehouse(String id);
  Future<Either<Failure, Warehouse>> getWarehouseById(String id);
  Future<Either<Failure, bool>> checkWarehouseCodeExists(String code, {String? excludeId});
  Future<Either<Failure, bool>> checkWarehouseHasMovements(String warehouseId);
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> getWarehouseMovements(String warehouseId, InventoryMovementQueryParams params);
  Future<Either<Failure, int>> getActiveWarehousesCount();
  Future<Either<Failure, WarehouseStats>> getWarehouseStats(String warehouseId);
}

// ==================== PARAMETER CLASSES ====================

class InventoryMovementQueryParams {
  final int page;
  final int limit;
  final String? search;
  final String? productId;
  final InventoryMovementType? type;
  final InventoryMovementStatus? status;
  final InventoryMovementReason? reason;
  final String? warehouseId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? referenceId;
  final String? referenceType;
  final String sortBy;
  final String sortOrder;

  const InventoryMovementQueryParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.productId,
    this.type,
    this.status,
    this.reason,
    this.warehouseId,
    this.startDate,
    this.endDate,
    this.referenceId,
    this.referenceType,
    this.sortBy = 'movementDate',
    this.sortOrder = 'desc',
  });
}

class SearchInventoryMovementsParams {
  final String searchTerm;
  final int limit;
  final InventoryMovementType? type;
  final String? warehouseId;

  const SearchInventoryMovementsParams({
    required this.searchTerm,
    this.limit = 50,
    this.type,
    this.warehouseId,
  });
}

class CreateInventoryMovementParams {
  final String productId;
  final InventoryMovementType type;
  final InventoryMovementReason reason;
  final int quantity;
  final double unitCost;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime? movementDate;

  const CreateInventoryMovementParams({
    required this.productId,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.unitCost,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.movementDate,
  });
}

class UpdateInventoryMovementParams {
  final String id;
  final InventoryMovementType? type;
  final InventoryMovementReason? reason;
  final int? quantity;
  final double? unitCost;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? warehouseId;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime? movementDate;

  const UpdateInventoryMovementParams({
    required this.id,
    this.type,
    this.reason,
    this.quantity,
    this.unitCost,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.movementDate,
  });
}

class InventoryBalanceQueryParams {
  final int page;
  final int limit;
  final String? search;
  final String? categoryId;
  final String? warehouseId;
  final bool? lowStock;
  final bool? outOfStock;
  final bool? nearExpiry;
  final bool? expired;
  final String sortBy;
  final String sortOrder;

  const InventoryBalanceQueryParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.categoryId,
    this.warehouseId,
    this.lowStock,
    this.outOfStock,
    this.nearExpiry,
    this.expired,
    this.sortBy = 'productName',
    this.sortOrder = 'asc',
  });
}

class ProcessFifoMovementParams {
  final String productId;
  final int quantity;
  final InventoryMovementReason reason;
  final String? warehouseId;
  final String? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime? movementDate;

  const ProcessFifoMovementParams({
    required this.productId,
    required this.quantity,
    required this.reason,
    this.warehouseId,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.movementDate,
  });
}

class CreateStockAdjustmentParams {
  final String productId;
  final int adjustmentQuantity;
  final InventoryMovementReason reason;
  final String? warehouseId;
  final String? notes;
  final DateTime? movementDate;
  final double? unitCost;

  const CreateStockAdjustmentParams({
    required this.productId,
    required this.adjustmentQuantity,
    required this.reason,
    this.warehouseId,
    this.notes,
    this.movementDate,
    this.unitCost,
  });
}

class CreateInventoryTransferParams {
  final List<TransferItem> items;
  final String fromWarehouseId;
  final String toWarehouseId;
  final String? notes;
  final DateTime? transferDate;

  const CreateInventoryTransferParams({
    required this.items,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    this.notes,
    this.transferDate,
  });
}

class TransferItem {
  final String productId;
  final int quantity;
  final String? notes;

  const TransferItem({
    required this.productId,
    required this.quantity,
    this.notes,
  });
}

class InventoryStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? warehouseId;
  final String? categoryId;

  const InventoryStatsParams({
    this.startDate,
    this.endDate,
    this.warehouseId,
    this.categoryId,
  });
}

class KardexReportParams {
  final String productId;
  final DateTime startDate;
  final DateTime endDate;
  final String? warehouseId;

  const KardexReportParams({
    required this.productId,
    required this.startDate,
    required this.endDate,
    this.warehouseId,
  });
}

class InventoryBatchQueryParams {
  final String productId;
  final int page;
  final int limit;
  final String? search;
  final String? warehouseId;
  final InventoryBatchStatus? status;
  final bool? expiredOnly;
  final bool? nearExpiryOnly;
  final bool? activeOnly;
  final String sortBy;
  final String sortOrder;

  const InventoryBatchQueryParams({
    required this.productId,
    this.page = 1,
    this.limit = 20,
    this.search,
    this.warehouseId,
    this.status,
    this.expiredOnly,
    this.nearExpiryOnly,
    this.activeOnly,
    this.sortBy = 'purchaseDate',
    this.sortOrder = 'desc',
  });
}

// ==================== WAREHOUSE PARAMETER CLASSES ====================

class CreateWarehouseParams extends Equatable {
  final String name;
  final String code;
  final String? description;
  final String? address;
  final bool isActive;

  const CreateWarehouseParams({
    required this.name,
    required this.code,
    this.description,
    this.address,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, code, description, address, isActive];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'address': address,
      'isActive': isActive,
    };
  }
}

class UpdateWarehouseParams extends Equatable {
  final String? name;
  final String? code;
  final String? description;
  final String? address;
  final bool? isActive;

  const UpdateWarehouseParams({
    this.name,
    this.code,
    this.description,
    this.address,
    this.isActive,
  });

  @override
  List<Object?> get props => [name, code, description, address, isActive];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (code != null) data['code'] = code;
    if (description != null) data['description'] = description;
    if (address != null) data['address'] = address;
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }
}