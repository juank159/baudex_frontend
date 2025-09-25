// lib/features/inventory/domain/usecases/delete_inventory_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class DeleteInventoryMovementUseCase {
  final InventoryRepository repository;

  DeleteInventoryMovementUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteMovement(id);
  }
}