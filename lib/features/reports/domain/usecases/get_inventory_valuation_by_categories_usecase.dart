// lib/features/reports/domain/usecases/get_inventory_valuation_by_categories_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_valuation_report.dart';
import '../repositories/reports_repository.dart';

class GetInventoryValuationByCategoriesUseCase
    implements UseCase<PaginatedResult<CategoryValuationBreakdown>, InventoryValuationParams> {
  final ReportsRepository repository;

  GetInventoryValuationByCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> call(
    InventoryValuationParams params,
  ) async {
    return await repository.getInventoryValuationByCategories(params);
  }
}