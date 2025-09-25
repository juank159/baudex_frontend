// lib/features/inventory/domain/usecases/check_warehouse_code_exists_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class CheckWarehouseCodeExistsUseCase {
  final InventoryRepository repository;

  CheckWarehouseCodeExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String code, {String? excludeId}) async {
    return await repository.checkWarehouseCodeExists(code, excludeId: excludeId);
  }
}