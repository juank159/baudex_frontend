// lib/features/inventory/domain/usecases/confirm_inventory_transfer_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class ConfirmInventoryTransferUseCase {
  final InventoryRepository repository;

  ConfirmInventoryTransferUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(String transferId) async {
    return await repository.confirmTransfer(transferId);
  }
}