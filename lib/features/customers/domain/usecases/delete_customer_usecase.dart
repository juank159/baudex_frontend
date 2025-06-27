import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteCustomerParams {
  final String id;

  const DeleteCustomerParams({required this.id});
}

class DeleteCustomerUseCase implements UseCase<Unit, DeleteCustomerParams> {
  final CustomerRepository repository;

  const DeleteCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteCustomerParams params) async {
    return await repository.deleteCustomer(params.id);
  }
}
