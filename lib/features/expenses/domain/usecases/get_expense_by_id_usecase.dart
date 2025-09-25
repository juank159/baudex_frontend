// lib/features/expenses/domain/usecases/get_expense_by_id_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenseByIdUseCase implements UseCase<Expense, GetExpenseByIdParams> {
  final ExpenseRepository repository;

  GetExpenseByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(GetExpenseByIdParams params) async {
    return await repository.getExpenseById(params.id);
  }
}

class GetExpenseByIdParams {
  final String id;

  GetExpenseByIdParams({required this.id});
}
