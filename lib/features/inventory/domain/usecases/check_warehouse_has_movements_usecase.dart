// lib/features/inventory/domain/usecases/check_warehouse_has_movements_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class CheckWarehouseHasMovementsUseCase {
  final InventoryRepository repository;

  CheckWarehouseHasMovementsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String warehouseId) async {
    return await repository.checkWarehouseHasMovements(warehouseId);
  }
}