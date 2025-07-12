import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:dartz/dartz.dart';

import '../entities/customer_stats.dart';

class GetCustomerStatsUseCase implements UseCase<CustomerStats, NoParams> {
  final CustomerRepository repository;

  const GetCustomerStatsUseCase(this.repository);

  @override
  Future<Either<Failure, CustomerStats>> call(NoParams params) async {
    return await repository.getCustomerStats();
  }
}
