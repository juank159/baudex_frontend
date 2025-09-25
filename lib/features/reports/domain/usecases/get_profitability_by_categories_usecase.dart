// lib/features/reports/domain/usecases/get_profitability_by_categories_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/profitability_report.dart';
import '../repositories/reports_repository.dart';

class GetProfitabilityByCategoriesUseCase
    implements UseCase<PaginatedResult<CategoryProfitabilityReport>, ProfitabilityReportParams> {
  final ReportsRepository repository;

  GetProfitabilityByCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> call(
    ProfitabilityReportParams params,
  ) async {
    return await repository.getProfitabilityByCategories(params);
  }
}