// lib/features/inventory/domain/usecases/cancel_inventory_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class CancelInventoryMovementUseCase {
  final InventoryRepository repository;

  CancelInventoryMovementUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(String id) async {
    return await repository.cancelMovement(id);
  }
}