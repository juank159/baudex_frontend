// lib/features/inventory/domain/usecases/get_inventory_valuation_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryValuationUseCase {
  final InventoryRepository repository;

  GetInventoryValuationUseCase(this.repository);

  Future<Either<Failure, Map<String, double>>> call({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    return await repository.getInventoryValuation(
      warehouseId: warehouseId,
      asOfDate: asOfDate,
    );
  }
}