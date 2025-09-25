// lib/features/inventory/domain/usecases/create_bulk_stock_adjustments_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class CreateBulkStockAdjustmentsUseCase {
  final InventoryRepository repository;

  CreateBulkStockAdjustmentsUseCase(this.repository);

  Future<Either<Failure, List<InventoryMovement>>> call(
    List<CreateStockAdjustmentParams> adjustmentsList,
  ) async {
    return await repository.createBulkStockAdjustments(adjustmentsList);
  }
}