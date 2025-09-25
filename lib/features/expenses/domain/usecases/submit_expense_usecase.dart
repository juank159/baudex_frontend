// lib/features/expenses/domain/usecases/submit_expense_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class SubmitExpenseUseCase implements UseCase<Expense, SubmitExpenseParams> {
  final ExpenseRepository repository;

  SubmitExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(SubmitExpenseParams params) async {
    return await repository.submitExpense(params.id);
  }
}

class SubmitExpenseParams {
  final String id;

  SubmitExpenseParams({required this.id});
}
