import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:dartz/dartz.dart';

class SearchCustomersParams {
  final String searchTerm;
  final int limit;

  const SearchCustomersParams({required this.searchTerm, this.limit = 10});
}

class SearchCustomersUseCase
    implements UseCase<List<Customer>, SearchCustomersParams> {
  final CustomerRepository repository;

  const SearchCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(
    SearchCustomersParams params,
  ) async {
    return await repository.searchCustomers(
      params.searchTerm,
      limit: params.limit,
    );
  }
}
