// lib/features/inventory/domain/usecases/process_bulk_outbound_movement_fifo_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class ProcessBulkOutboundMovementFifoUseCase {
  final InventoryRepository repository;

  ProcessBulkOutboundMovementFifoUseCase(this.repository);

  Future<Either<Failure, List<InventoryMovement>>> call(
    List<ProcessFifoMovementParams> movementsList,
  ) async {
    return await repository.processBulkOutboundMovementFifo(movementsList);
  }
}