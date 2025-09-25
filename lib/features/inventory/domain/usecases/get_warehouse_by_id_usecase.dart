// lib/features/inventory/domain/usecases/get_warehouse_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/warehouse.dart';
import '../repositories/inventory_repository.dart';

class GetWarehouseByIdUseCase {
  final InventoryRepository repository;

  GetWarehouseByIdUseCase(this.repository);

  Future<Either<Failure, Warehouse>> call(String id) async {
    return await repository.getWarehouseById(id);
  }
}