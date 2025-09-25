// lib/features/inventory/domain/usecases/get_expired_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetExpiredProductsUseCase {
  final InventoryRepository repository;

  GetExpiredProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryBalance>>> call({
    String? warehouseId,
  }) async {
    return await repository.getExpiredProducts(warehouseId: warehouseId);
  }
}