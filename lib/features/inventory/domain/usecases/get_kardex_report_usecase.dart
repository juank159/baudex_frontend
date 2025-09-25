// lib/features/inventory/domain/usecases/get_kardex_report_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/kardex_report.dart';
import '../repositories/inventory_repository.dart';

class GetKardexReportUseCase {
  final InventoryRepository repository;

  GetKardexReportUseCase(this.repository);

  Future<Either<Failure, KardexReport>> call(
    KardexReportParams params,
  ) async {
    return await repository.getKardexReport(params);
  }
}