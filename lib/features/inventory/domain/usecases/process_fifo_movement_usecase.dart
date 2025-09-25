// lib/features/inventory/domain/usecases/process_fifo_movement_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class ProcessFifoMovementUseCase
    implements UseCase<InventoryMovement, ProcessFifoMovementParams> {
  final InventoryRepository repository;

  ProcessFifoMovementUseCase(this.repository);

  @override
  Future<Either<Failure, InventoryMovement>> call(
    ProcessFifoMovementParams params,
  ) async {
    return await repository.processOutboundMovementFifo(params);
  }
}