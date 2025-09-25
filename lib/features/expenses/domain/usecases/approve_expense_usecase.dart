// lib/features/expenses/domain/usecases/approve_expense_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class ApproveExpenseUseCase implements UseCase<Expense, ApproveExpenseParams> {
  final ExpenseRepository repository;

  ApproveExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(ApproveExpenseParams params) async {
    return await repository.approveExpense(id: params.id, notes: params.notes);
  }
}

class ApproveExpenseParams {
  final String id;
  final String? notes;

  ApproveExpenseParams({required this.id, this.notes});
}
