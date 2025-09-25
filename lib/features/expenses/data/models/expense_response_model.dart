// lib/features/expenses/data/models/expense_response_model.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart' as core;
import '../../domain/repositories/expense_repository.dart';

import 'expense_model.dart';

class ExpenseResponseModel {
  final bool success;
  final String message;
  final ExpenseModel? data;
  final List<ExpenseModel>? expenses;
  final core.PaginationMeta? meta;

  const ExpenseResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.expenses,
    this.meta,
  });

  factory ExpenseResponseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? ExpenseModel.fromJson(json['data']) : null,
      expenses:
          json['data'] is List
              ? (json['data'] as List)
                  .map((expense) => ExpenseModel.fromJson(expense))
                  .toList()
              : null,
      meta: json['meta'] != null ? core.PaginationMeta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'expenses': expenses?.map((e) => e.toJson()).toList(),
      'meta': meta?.toJson(),
    };
  }
}

class ExpensesListResponseModel {
  final bool success;
  final String message;
  final List<ExpenseModel> data;
  final core.PaginationMeta meta;

  const ExpensesListResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory ExpensesListResponseModel.fromJson(Map<String, dynamic> json) {
    return ExpensesListResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data:
          (json['data'] as List? ?? [])
              .map((expense) => ExpenseModel.fromJson(expense))
              .toList(),
      meta: core.PaginationMeta.fromJson(json['meta'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  PaginatedResponse<ExpenseModel> toPaginatedResponse() {
    return PaginatedResponse<ExpenseModel>(
      data: data,
      meta: PaginationMeta(
        page: meta.page,
        limit: meta.limit,
        total: meta.totalItems,
        totalPages: meta.totalPages,
        hasNext: meta.hasNextPage,
        hasPrev: meta.hasPreviousPage,
      ),
    );
  }
}