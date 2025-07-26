// lib/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase implements UseCase<DashboardStats, GetDashboardStatsParams> {
  final DashboardRepository repository;

  GetDashboardStatsUseCase(this.repository);

  @override
  Future<Either<Failure, DashboardStats>> call(GetDashboardStatsParams params) async {
    return await repository.getDashboardStats(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetDashboardStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;

  GetDashboardStatsParams({
    this.startDate,
    this.endDate,
  });
}