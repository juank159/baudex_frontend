// lib/features/inventory/domain/usecases/confirm_inventory_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class ConfirmInventoryMovementUseCase {
  final InventoryRepository repository;

  ConfirmInventoryMovementUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(String id) async {
    return await repository.confirmMovement(id);
  }
}