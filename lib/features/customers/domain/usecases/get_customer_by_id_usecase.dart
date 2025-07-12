import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:dartz/dartz.dart';

class GetCustomerByIdParams {
  final String id;

  const GetCustomerByIdParams({required this.id});
}

class GetCustomerByIdUseCase
    implements UseCase<Customer, GetCustomerByIdParams> {
  final CustomerRepository repository;

  const GetCustomerByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Customer>> call(GetCustomerByIdParams params) async {
    return await repository.getCustomerById(params.id);
  }
}
