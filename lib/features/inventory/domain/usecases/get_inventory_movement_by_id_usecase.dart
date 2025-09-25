// lib/features/inventory/domain/usecases/get_inventory_movement_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryMovementByIdUseCase {
  final InventoryRepository repository;

  GetInventoryMovementByIdUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(String id) async {
    return await repository.getMovementById(id);
  }
}