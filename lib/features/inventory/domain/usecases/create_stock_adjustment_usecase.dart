// lib/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class CreateStockAdjustmentUseCase {
  final InventoryRepository repository;

  CreateStockAdjustmentUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(
    Map<String, dynamic> request,
  ) async {
    return await repository.createStockAdjustment(request);
  }
}