// lib/features/suppliers/domain/usecases/delete_supplier_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/supplier_repository.dart';

class DeleteSupplierUseCase implements UseCase<Unit, String> {
  final SupplierRepository repository;

  DeleteSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id) async {
    return await repository.deleteSupplier(id);
  }
}