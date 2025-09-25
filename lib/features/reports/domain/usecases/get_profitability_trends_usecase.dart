// lib/features/reports/domain/usecases/get_profitability_trends_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/profitability_report.dart';
import '../repositories/reports_repository.dart';

class GetProfitabilityTrendsUseCase
    implements UseCase<List<ProfitabilityTrend>, ProfitabilityTrendsParams> {
  final ReportsRepository repository;

  GetProfitabilityTrendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> call(
    ProfitabilityTrendsParams params,
  ) async {
    return await repository.getProfitabilityTrends(params);
  }
}