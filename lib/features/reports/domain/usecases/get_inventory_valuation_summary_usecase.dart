// lib/features/reports/domain/usecases/get_inventory_valuation_summary_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_valuation_report.dart';
import '../repositories/reports_repository.dart';

class GetInventoryValuationSummaryUseCase
    implements UseCase<InventoryValuationSummary, InventoryValuationParams> {
  final ReportsRepository repository;

  GetInventoryValuationSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, InventoryValuationSummary>> call(
    InventoryValuationParams params,
  ) async {
    return await repository.getInventoryValuationSummary(params);
  }
}