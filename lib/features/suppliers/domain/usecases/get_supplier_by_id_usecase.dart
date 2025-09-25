// lib/features/suppliers/domain/usecases/get_supplier_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSupplierByIdUseCase implements UseCase<Supplier, String> {
  final SupplierRepository repository;

  GetSupplierByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Supplier>> call(String id) async {
    return await repository.getSupplierById(id);
  }
}