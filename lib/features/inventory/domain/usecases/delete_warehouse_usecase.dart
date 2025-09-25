// lib/features/inventory/domain/usecases/delete_warehouse_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class DeleteWarehouseUseCase {
  final InventoryRepository repository;

  DeleteWarehouseUseCase(this.repository);

  Future<Either<Failure, bool>> call(String id) async {
    return await repository.deleteWarehouse(id);
  }
}