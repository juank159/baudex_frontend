// lib/features/suppliers/domain/usecases/get_supplier_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSupplierStatsUseCase implements UseCase<SupplierStats, NoParams> {
  final SupplierRepository repository;

  GetSupplierStatsUseCase(this.repository);

  @override
  Future<Either<Failure, SupplierStats>> call(NoParams params) async {
    return await repository.getSupplierStats();
  }
}