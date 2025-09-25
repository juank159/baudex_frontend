// lib/features/inventory/domain/usecases/create_inventory_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class CreateInventoryMovementUseCase
    implements UseCase<InventoryMovement, CreateInventoryMovementParams> {
  final InventoryRepository repository;

  CreateInventoryMovementUseCase(this.repository);

  @override
  Future<Either<Failure, InventoryMovement>> call(
    CreateInventoryMovementParams params,
  ) async {
    return await repository.createMovement(params);
  }
}