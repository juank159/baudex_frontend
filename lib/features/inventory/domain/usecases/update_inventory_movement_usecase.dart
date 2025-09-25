// lib/features/inventory/domain/usecases/update_inventory_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class UpdateInventoryMovementUseCase {
  final InventoryRepository repository;

  UpdateInventoryMovementUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(
    UpdateInventoryMovementParams params,
  ) async {
    return await repository.updateMovement(params);
  }
}