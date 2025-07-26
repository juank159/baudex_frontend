// lib/features/expenses/domain/usecases/update_expense_category_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseCategoryUseCase
    implements UseCase<ExpenseCategory, UpdateExpenseCategoryParams> {
  final ExpenseRepository repository;

  UpdateExpenseCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, ExpenseCategory>> call(
    UpdateExpenseCategoryParams params,
  ) async {
    return await repository.updateExpenseCategory(
      id: params.id,
      name: params.name,
      description: params.description,
      color: params.color,
      monthlyBudget: params.monthlyBudget,
      sortOrder: params.sortOrder,
      status: params.status,
    );
  }
}

class UpdateExpenseCategoryParams {
  final String id;
  final String? name;
  final String? description;
  final String? color;
  final double? monthlyBudget;
  final int? sortOrder;
  final ExpenseCategoryStatus? status;

  UpdateExpenseCategoryParams({
    required this.id,
    this.name,
    this.description,
    this.color,
    this.monthlyBudget,
    this.sortOrder,
    this.status,
  });
}