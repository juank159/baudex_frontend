// lib/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryBalanceByProductUseCase {
  final InventoryRepository repository;

  GetInventoryBalanceByProductUseCase(this.repository);

  Future<Either<Failure, InventoryBalance>> call(
    String productId, {
    String? warehouseId,
  }) async {
    return await repository.getBalanceByProduct(
      productId,
      warehouseId: warehouseId,
    );
  }
}