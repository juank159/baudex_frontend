// lib/features/inventory/domain/usecases/search_inventory_movements_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class SearchInventoryMovementsUseCase {
  final InventoryRepository repository;

  SearchInventoryMovementsUseCase(this.repository);

  Future<Either<Failure, List<InventoryMovement>>> call(
    SearchInventoryMovementsParams params,
  ) async {
    return await repository.searchMovements(params);
  }
}