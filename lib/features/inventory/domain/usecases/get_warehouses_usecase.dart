// lib/features/inventory/domain/usecases/get_warehouses_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/warehouse.dart';
import '../repositories/inventory_repository.dart';

class GetWarehousesUseCase {
  final InventoryRepository repository;

  GetWarehousesUseCase(this.repository);

  Future<Either<Failure, List<Warehouse>>> call() async {
    return await repository.getWarehouses();
  }
}