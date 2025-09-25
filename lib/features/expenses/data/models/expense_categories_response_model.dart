// lib/features/expenses/data/models/expense_categories_response_model.dart
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart' as core;
import '../../domain/repositories/expense_repository.dart';
import 'expense_category_model.dart';

class ExpenseCategoriesResponseModel {
  final List<ExpenseCategoryModel> data;
  final core.PaginationMeta? meta;

  const ExpenseCategoriesResponseModel({
    required this.data,
    this.meta,
  });

  factory ExpenseCategoriesResponseModel.fromJson(Map<String, dynamic> json) {
    // Si la respuesta es directamente un array
    if (json is List) {
      return ExpenseCategoriesResponseModel(
        data: (json as List<dynamic>)
            .map((item) => ExpenseCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        meta: null,
      );
    }

    // Si la respuesta tiene estructura con data y meta
    return ExpenseCategoriesResponseModel(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => ExpenseCategoryModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      meta: json['meta'] != null
          ? core.PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((category) => category.toJson()).toList(),
      if (meta != null) 'meta': meta!.toJson(),
    };
  }

  PaginatedResponse<ExpenseCategoryModel> toPaginatedResponse() {
    return PaginatedResponse<ExpenseCategoryModel>(
      data: data,
      meta: meta != null 
          ? PaginationMeta(
              page: meta!.page,
              limit: meta!.limit,
              total: meta!.totalItems,
              totalPages: meta!.totalPages,
              hasNext: meta!.hasNextPage,
              hasPrev: meta!.hasPreviousPage,
            )
          : PaginationMeta(
              page: 1,
              limit: data.length,
              total: data.length,
              totalPages: 1,
              hasNext: false,
              hasPrev: false,
            ),
    );
  }
}