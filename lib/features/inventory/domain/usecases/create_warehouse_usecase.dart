// lib/features/inventory/domain/usecases/create_warehouse_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/warehouse.dart';
import '../repositories/inventory_repository.dart';

class CreateWarehouseUseCase {
  final InventoryRepository repository;

  CreateWarehouseUseCase(this.repository);

  Future<Either<Failure, Warehouse>> call(CreateWarehouseParams params) async {
    return await repository.createWarehouse(params);
  }
}