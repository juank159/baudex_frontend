// lib/features/categories/data/models/category_response_model.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';

import '../../domain/repositories/category_repository.dart';
import 'category_model.dart';

class CategoryResponseModel {
  final List<CategoryModel> data;
  final PaginationMetaModel meta;

  const CategoryResponseModel({required this.data, required this.meta});

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CategoryResponseModel(
      data:
          (json['data'] as List)
              .map(
                (item) => CategoryModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      meta: PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((category) => category.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  /// Convertir a PaginatedResult del domain
  PaginatedResult<CategoryModel> toPaginatedResult() {
    return PaginatedResult(data: data, meta: meta.toEntity());
  }
}

class PaginationMetaModel extends PaginationMeta {
  const PaginationMetaModel({
    required super.page,
    required super.limit,
    required super.totalItems,
    required super.totalPages,
    required super.hasNextPage,
    required super.hasPreviousPage,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalItems': totalItems,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  PaginationMeta toEntity() {
    return PaginationMeta(
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}
