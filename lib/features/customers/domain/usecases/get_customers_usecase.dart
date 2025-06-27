import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/customer_repository.dart';
import '../../../../app/core/models/pagination_meta.dart';

class GetCustomersParams {
  final int page;
  final int limit;
  final String? search;
  final CustomerStatus? status;
  final DocumentType? documentType;
  final String? city;
  final String? state;
  final String? sortBy;
  final String? sortOrder;

  const GetCustomersParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.documentType,
    this.city,
    this.state,
    this.sortBy,
    this.sortOrder,
  });
}

class GetCustomersUseCase
    implements UseCase<PaginatedResult<Customer>, GetCustomersParams> {
  final CustomerRepository repository;

  const GetCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Customer>>> call(
    GetCustomersParams params,
  ) async {
    return await repository.getCustomers(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      documentType: params.documentType,
      city: params.city,
      state: params.state,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}
