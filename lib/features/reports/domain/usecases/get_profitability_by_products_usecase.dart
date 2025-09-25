// lib/features/reports/domain/usecases/get_profitability_by_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/profitability_report.dart';
import '../repositories/reports_repository.dart';

class GetProfitabilityByProductsUseCase
    implements UseCase<PaginatedResult<ProfitabilityReport>, ProfitabilityReportParams> {
  final ReportsRepository repository;

  GetProfitabilityByProductsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<ProfitabilityReport>>> call(
    ProfitabilityReportParams params,
  ) async {
    return await repository.getProfitabilityByProducts(params);
  }
}