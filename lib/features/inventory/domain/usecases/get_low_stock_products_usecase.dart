// lib/features/inventory/domain/usecases/get_low_stock_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetLowStockProductsParams {
  final String? warehouseId;

  const GetLowStockProductsParams({this.warehouseId});
}

class GetLowStockProductsUseCase
    implements UseCase<List<InventoryBalance>, GetLowStockProductsParams> {
  final InventoryRepository repository;

  GetLowStockProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<InventoryBalance>>> call(
    GetLowStockProductsParams params,
  ) async {
    return await repository.getLowStockProducts(
      warehouseId: params.warehouseId,
    );
  }
}