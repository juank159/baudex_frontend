// lib/features/dashboard/domain/usecases/get_recent_activity_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/recent_activity.dart';
import '../repositories/dashboard_repository.dart';

class GetRecentActivityUseCase implements UseCase<List<RecentActivity>, GetRecentActivityParams> {
  final DashboardRepository repository;

  GetRecentActivityUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecentActivity>>> call(GetRecentActivityParams params) async {
    return await repository.getRecentActivity(
      limit: params.limit,
      types: params.types,
    );
  }
}

class GetRecentActivityParams {
  final int limit;
  final List<ActivityType>? types;

  GetRecentActivityParams({
    this.limit = 20,
    this.types,
  });
}