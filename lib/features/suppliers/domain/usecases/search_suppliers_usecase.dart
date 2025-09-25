// lib/features/suppliers/domain/usecases/search_suppliers_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class SearchSuppliersUseCase implements UseCase<List<Supplier>, SearchSuppliersParams> {
  final SupplierRepository repository;

  SearchSuppliersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Supplier>>> call(SearchSuppliersParams params) async {
    return await repository.searchSuppliers(
      params.searchTerm,
      limit: params.limit,
    );
  }
}

class SearchSuppliersParams {
  final String searchTerm;
  final int limit;

  SearchSuppliersParams({
    required this.searchTerm,
    this.limit = 10,
  });
}