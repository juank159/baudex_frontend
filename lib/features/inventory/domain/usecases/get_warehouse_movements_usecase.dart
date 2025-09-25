// lib/features/inventory/domain/usecases/get_warehouse_movements_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

// Import the query params class
export '../repositories/inventory_repository.dart' show InventoryMovementQueryParams;

class GetWarehouseMovementsUseCase {
  final InventoryRepository repository;

  GetWarehouseMovementsUseCase(this.repository);

  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> call(
    String warehouseId,
    InventoryMovementQueryParams params,
  ) {
    return repository.getWarehouseMovements(warehouseId, params);
  }
}