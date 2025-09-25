// lib/features/expenses/domain/repositories/expense_repository.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/expense.dart';
import '../entities/expense_category.dart';
import '../entities/expense_stats.dart';

abstract class ExpenseRepository {
  // Expense operations
  Future<Either<Failure, PaginatedResponse<Expense>>> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    String? orderDirection,
  });

  Future<Either<Failure, Expense>> getExpenseById(String id);

  Future<Either<Failure, Expense>> createExpense({
    required String description,
    required double amount,
    required DateTime date,
    required String categoryId,
    required ExpenseType type,
    required PaymentMethod paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    ExpenseStatus? status,
  });

  Future<Either<Failure, Expense>> updateExpense({
    required String id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    ExpenseType? type,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, void>> deleteExpense(String id);

  Future<Either<Failure, Expense>> submitExpense(String id);

  Future<Either<Failure, Expense>> approveExpense({
    required String id,
    String? notes,
  });

  Future<Either<Failure, Expense>> rejectExpense({
    required String id,
    required String reason,
  });

  Future<Either<Failure, Expense>> markAsPaid(String id);

  Future<Either<Failure, List<Expense>>> searchExpenses(String query);

  Future<Either<Failure, ExpenseStats>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Expense Category operations
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>>
  getExpenseCategories({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  });

  Future<Either<Failure, ExpenseCategory>> getExpenseCategoryById(String id);

  Future<Either<Failure, ExpenseCategory>> createExpenseCategory({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  });

  Future<Either<Failure, ExpenseCategory>> updateExpenseCategory({
    required String id,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  });

  Future<Either<Failure, void>> deleteExpenseCategory(String id);

  Future<Either<Failure, List<ExpenseCategory>>> searchExpenseCategories(
    String query,
  );
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.data,
    required this.meta,
  });
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });
}
