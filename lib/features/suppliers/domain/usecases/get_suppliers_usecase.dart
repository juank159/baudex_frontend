// lib/features/suppliers/domain/usecases/get_suppliers_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

// Re-exportar SupplierQueryParams desde repository
export '../repositories/supplier_repository.dart' show SupplierQueryParams;

class GetSuppliersUseCase implements UseCase<PaginatedResult<Supplier>, SupplierQueryParams> {
  final SupplierRepository repository;

  GetSuppliersUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Supplier>>> call(SupplierQueryParams params) async {
    return await repository.getSuppliers(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      documentType: params.documentType,
      currency: params.currency,
      hasEmail: params.hasEmail,
      hasPhone: params.hasPhone,
      hasCreditLimit: params.hasCreditLimit,
      hasDiscount: params.hasDiscount,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}