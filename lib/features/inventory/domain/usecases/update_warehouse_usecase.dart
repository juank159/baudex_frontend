// lib/features/inventory/domain/usecases/update_warehouse_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/warehouse.dart';
import '../repositories/inventory_repository.dart';

class UpdateWarehouseUseCase {
  final InventoryRepository repository;

  UpdateWarehouseUseCase(this.repository);

  Future<Either<Failure, Warehouse>> call(String id, UpdateWarehouseParams params) async {
    return await repository.updateWarehouse(id, params);
  }
}