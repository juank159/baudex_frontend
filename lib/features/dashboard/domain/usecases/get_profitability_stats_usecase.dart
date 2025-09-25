// lib/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetProfitabilityStatsUseCase implements UseCase<ProfitabilityStats, GetProfitabilityStatsParams> {
  final DashboardRepository repository;

  GetProfitabilityStatsUseCase(this.repository);

  @override
  Future<Either<Failure, ProfitabilityStats>> call(GetProfitabilityStatsParams params) async {
    return await repository.getProfitabilityStats(
      startDate: params.startDate,
      endDate: params.endDate,
      warehouseId: params.warehouseId,
      categoryId: params.categoryId,
    );
  }
}

class GetProfitabilityStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? warehouseId;
  final String? categoryId;

  GetProfitabilityStatsParams({
    this.startDate,
    this.endDate,
    this.warehouseId,
    this.categoryId,
  });
}