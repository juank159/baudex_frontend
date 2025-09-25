// lib/features/inventory/domain/usecases/get_near_expiry_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetNearExpiryProductsUseCase {
  final InventoryRepository repository;

  GetNearExpiryProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryBalance>>> call({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    return await repository.getNearExpiryProducts(
      warehouseId: warehouseId,
      daysThreshold: daysThreshold,
    );
  }
}