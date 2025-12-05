// lib/features/expenses/domain/usecases/get_expense_categories_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

class GetExpenseCategoriesUseCase
    implements
        UseCase<
          PaginatedResponse<ExpenseCategory>,
          GetExpenseCategoriesParams
        > {
  final ExpenseRepository repository;

  GetExpenseCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> call(
    GetExpenseCategoriesParams params,
  ) async {
    if (params.withStats) {
      return await repository.getExpenseCategoriesWithStats(
        page: params.page,
        limit: params.limit,
        search: params.search,
        status: params.status,
        orderBy: params.orderBy,
        orderDirection: params.orderDirection,
      );
    } else {
      return await repository.getExpenseCategories(
        page: params.page,
        limit: params.limit,
        search: params.search,
        status: params.status,
        orderBy: params.orderBy,
        orderDirection: params.orderDirection,
      );
    }
  }
}

class GetExpenseCategoriesParams {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? orderBy;
  final String? orderDirection;
  final bool withStats;

  GetExpenseCategoriesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.orderBy,
    this.orderDirection,
    this.withStats = false,
  });
}
