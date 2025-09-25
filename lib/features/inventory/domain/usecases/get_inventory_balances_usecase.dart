// lib/features/inventory/domain/usecases/get_inventory_balances_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryBalancesUseCase
    implements UseCase<core.PaginatedResult<InventoryBalance>, InventoryBalanceQueryParams> {
  final InventoryRepository repository;

  GetInventoryBalancesUseCase(this.repository);

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBalance>>> call(
    InventoryBalanceQueryParams params,
  ) async {
    return await repository.getBalances(params);
  }
}