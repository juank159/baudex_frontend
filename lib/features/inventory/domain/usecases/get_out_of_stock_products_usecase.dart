// lib/features/inventory/domain/usecases/get_out_of_stock_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetOutOfStockProductsUseCase {
  final InventoryRepository repository;

  GetOutOfStockProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryBalance>>> call({
    String? warehouseId,
  }) async {
    return await repository.getOutOfStockProducts(warehouseId: warehouseId);
  }
}