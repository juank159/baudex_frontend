// lib/features/inventory/domain/usecases/get_active_warehouses_count_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class GetActiveWarehousesCountUseCase {
  final InventoryRepository repository;

  GetActiveWarehousesCountUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    return await repository.getActiveWarehousesCount();
  }
}