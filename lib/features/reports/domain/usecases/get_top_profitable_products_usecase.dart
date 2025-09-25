// lib/features/reports/domain/usecases/get_top_profitable_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/profitability_report.dart';
import '../repositories/reports_repository.dart';

class GetTopProfitableProductsUseCase
    implements UseCase<List<ProfitabilityReport>, TopProfitableProductsParams> {
  final ReportsRepository repository;

  GetTopProfitableProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> call(
    TopProfitableProductsParams params,
  ) async {
    return await repository.getTopProfitableProducts(params);
  }
}