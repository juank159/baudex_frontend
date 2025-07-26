// lib/features/expenses/domain/usecases/get_expense_stats_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import '../entities/expense_stats.dart';
import '../repositories/expense_repository.dart';

class GetExpenseStatsUseCase
    implements UseCase<ExpenseStats, GetExpenseStatsParams> {
  final ExpenseRepository repository;

  GetExpenseStatsUseCase(this.repository);

  @override
  Future<Either<Failure, ExpenseStats>> call(
    GetExpenseStatsParams params,
  ) async {
    return await repository.getExpenseStats(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetExpenseStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;

  GetExpenseStatsParams({this.startDate, this.endDate});
}
