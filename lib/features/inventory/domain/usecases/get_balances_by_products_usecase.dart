// lib/features/inventory/domain/usecases/get_balances_by_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetBalancesByProductsUseCase {
  final InventoryRepository repository;

  GetBalancesByProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryBalance>>> call(
    List<String> productIds, {
    String? warehouseId,
  }) async {
    return await repository.getBalancesByProducts(
      productIds,
      warehouseId: warehouseId,
    );
  }
}