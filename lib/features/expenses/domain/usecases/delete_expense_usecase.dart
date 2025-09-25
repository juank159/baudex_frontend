// lib/features/expenses/domain/usecases/delete_expense_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase implements UseCase<void, DeleteExpenseParams> {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteExpenseParams params) async {
    return await repository.deleteExpense(params.id);
  }
}

class DeleteExpenseParams {
  final String id;

  DeleteExpenseParams({required this.id});
}
