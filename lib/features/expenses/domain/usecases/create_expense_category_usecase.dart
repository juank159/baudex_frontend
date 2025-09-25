// lib/features/expenses/domain/usecases/create_expense_category_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseCategoryUseCase
    implements UseCase<ExpenseCategory, CreateExpenseCategoryParams> {
  final ExpenseRepository repository;

  CreateExpenseCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, ExpenseCategory>> call(
    CreateExpenseCategoryParams params,
  ) async {
    return await repository.createExpenseCategory(
      name: params.name,
      description: params.description,
      color: params.color,
      monthlyBudget: params.monthlyBudget,
      sortOrder: params.sortOrder,
    );
  }
}

class CreateExpenseCategoryParams {
  final String name;
  final String? description;
  final String? color;
  final double? monthlyBudget;
  final int? sortOrder;

  CreateExpenseCategoryParams({
    required this.name,
    this.description,
    this.color,
    this.monthlyBudget,
    this.sortOrder,
  });
}
