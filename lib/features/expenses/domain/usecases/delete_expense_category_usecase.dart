// lib/features/expenses/domain/usecases/delete_expense_category_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../repositories/expense_repository.dart';

class DeleteExpenseCategoryUseCase
    implements UseCase<void, DeleteExpenseCategoryParams> {
  final ExpenseRepository repository;

  DeleteExpenseCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteExpenseCategoryParams params,
  ) async {
    return await repository.deleteExpenseCategory(params.id);
  }
}

class DeleteExpenseCategoryParams {
  final String id;

  DeleteExpenseCategoryParams({required this.id});
}