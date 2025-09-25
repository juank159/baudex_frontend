// lib/features/inventory/domain/usecases/get_inventory_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_stats.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryStatsUseCase
    implements UseCase<InventoryStats, InventoryStatsParams> {
  final InventoryRepository repository;

  GetInventoryStatsUseCase(this.repository);

  @override
  Future<Either<Failure, InventoryStats>> call(
    InventoryStatsParams params,
  ) async {
    return await repository.getInventoryStats(params);
  }
}