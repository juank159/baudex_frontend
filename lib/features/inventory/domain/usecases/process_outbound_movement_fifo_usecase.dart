// lib/features/inventory/domain/usecases/process_outbound_movement_fifo_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class ProcessOutboundMovementFifoUseCase {
  final InventoryRepository repository;

  ProcessOutboundMovementFifoUseCase(this.repository);

  Future<Either<Failure, InventoryMovement>> call(
    ProcessFifoMovementParams params,
  ) async {
    return await repository.processOutboundMovementFifo(params);
  }
}