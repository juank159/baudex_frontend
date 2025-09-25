// lib/features/inventory/domain/usecases/get_inventory_aging_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryAgingUseCase {
  final InventoryRepository repository;

  GetInventoryAgingUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    String? warehouseId,
  }) async {
    return await repository.getInventoryAging(warehouseId: warehouseId);
  }
}