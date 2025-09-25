// lib/features/reports/domain/usecases/get_valuation_variances_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_valuation_report.dart';
import '../repositories/reports_repository.dart';

class GetValuationVariancesUseCase
    implements UseCase<PaginatedResult<InventoryValuationVariance>, ValuationVariancesParams> {
  final ReportsRepository repository;

  GetValuationVariancesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> call(
    ValuationVariancesParams params,
  ) async {
    return await repository.getValuationVariances(params);
  }
}