// lib/features/inventory/domain/usecases/create_inventory_transfer_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class CreateInventoryTransferUseCase {
  final InventoryRepository repository;

  CreateInventoryTransferUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(
    CreateInventoryTransferParams params,
  ) async {
    return await repository.createTransfer(params);
  }
}