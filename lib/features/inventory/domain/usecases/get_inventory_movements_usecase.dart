// lib/features/inventory/domain/usecases/get_inventory_movements_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryMovementsUseCase
    implements UseCase<core.PaginatedResult<InventoryMovement>, InventoryMovementQueryParams> {
  final InventoryRepository repository;

  GetInventoryMovementsUseCase(this.repository);

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>> call(
    InventoryMovementQueryParams params,
  ) async {
    return await repository.getMovements(params);
  }
}