// lib/features/inventory/domain/usecases/get_warehouse_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/warehouse_with_stats.dart';
import '../repositories/inventory_repository.dart';

class GetWarehouseStatsUseCase {
  final InventoryRepository repository;

  GetWarehouseStatsUseCase(this.repository);

  Future<Either<Failure, WarehouseStats>> call(String warehouseId) async {
    return await repository.getWarehouseStats(warehouseId);
  }
}