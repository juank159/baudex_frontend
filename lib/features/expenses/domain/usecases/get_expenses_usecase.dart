// lib/features/expenses/domain/usecases/get_expenses_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

import 'package:baudex_desktop/app/core/usecases/usecase.dart';

class GetExpensesUseCase
    implements UseCase<PaginatedResponse<Expense>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Expense>>> call(
    GetExpensesParams params,
  ) async {
    return await repository.getExpenses(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      type: params.type,
      categoryId: params.categoryId,
      startDate: params.startDate,
      endDate: params.endDate,
      orderBy: params.orderBy,
      orderDirection: params.orderDirection,
    );
  }
}

class GetExpensesParams {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? type;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? orderBy;
  final String? orderDirection;

  GetExpensesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.type,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.orderBy,
    this.orderDirection,
  });
}
