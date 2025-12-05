// // lib/features/products/data/models/product_response_model.dart
// import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
// import 'package:baudex_desktop/features/categories/domain/repositories/category_repository.dart';
// import 'package:baudex_desktop/features/products/domain/entities/product_stats.dart';

// import 'product_model.dart';

// class ProductResponseModel {
//   final List<ProductModel> data;
//   final PaginationMetaModel meta;

//   const ProductResponseModel({required this.data, required this.meta});

//   factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
//     return ProductResponseModel(
//       data:
//           (json['data'] as List)
//               .map((item) => ProductModel.fromJson(item))
//               .toList(),
//       meta: PaginationMetaModel.fromJson(json['meta']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'data': data.map((item) => item.toJson()).toList(),
//       'meta': meta.toJson(),
//     };
//   }

//   // Conversión a entidad del dominio
//   PaginatedResult<ProductModel> toPaginatedResult() {
//     return PaginatedResult<ProductModel>(data: data, meta: meta.toEntity());
//   }
// }

// class PaginationMetaModel {
//   final int page;
//   final int limit;
//   final int totalItems;
//   final int totalPages;
//   final bool hasNextPage;
//   final bool hasPreviousPage;

//   const PaginationMetaModel({
//     required this.page,
//     required this.limit,
//     required this.totalItems,
//     required this.totalPages,
//     required this.hasNextPage,
//     required this.hasPreviousPage,
//   });

//   factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
//     return PaginationMetaModel(
//       page: json['page'] as int,
//       limit: json['limit'] as int,
//       totalItems: json['totalItems'] as int,
//       totalPages: json['totalPages'] as int,
//       hasNextPage: json['hasNextPage'] as bool,
//       hasPreviousPage: json['hasPreviousPage'] as bool,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'page': page,
//       'limit': limit,
//       'totalItems': totalItems,
//       'totalPages': totalPages,
//       'hasNextPage': hasNextPage,
//       'hasPreviousPage': hasPreviousPage,
//     };
//   }

//   PaginationMeta toEntity() {
//     return PaginationMeta(
//       page: page,
//       limit: limit,
//       totalItems: totalItems,
//       totalPages: totalPages,
//       hasNextPage: hasNextPage,
//       hasPreviousPage: hasPreviousPage,
//     );
//   }
// }

// class ProductStatsModel {
//   final int total;
//   final int active;
//   final int inactive;
//   final int outOfStock;
//   final int lowStock;
//   final double activePercentage;

//   const ProductStatsModel({
//     required this.total,
//     required this.active,
//     required this.inactive,
//     required this.outOfStock,
//     required this.lowStock,
//     required this.activePercentage,
//   });

//   factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
//     return ProductStatsModel(
//       total: json['total'] as int,
//       active: json['active'] as int,
//       inactive: json['inactive'] as int,
//       outOfStock: json['outOfStock'] as int,
//       lowStock: json['lowStock'] as int,
//       activePercentage: (json['activePercentage'] as num).toDouble(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'total': total,
//       'active': active,
//       'inactive': inactive,
//       'outOfStock': outOfStock,
//       'lowStock': lowStock,
//       'activePercentage': activePercentage,
//     };
//   }

//   ProductStats toEntity() {
//     return ProductStats(
//       total: total,
//       active: active,
//       inactive: inactive,
//       outOfStock: outOfStock,
//       lowStock: lowStock,
//       activePercentage: activePercentage,
//     );
//   }
// }

// lib/features/products/data/models/product_response_model.dart
import '../../../../app/core/models/pagination_meta.dart';
import 'product_model.dart';

class ProductResponseModel {
  final List<ProductModel> data;
  final PaginationMeta meta;

  const ProductResponseModel({required this.data, required this.meta});

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductResponseModel(
      data:
          (json['data'] as List)
              .map((item) => ProductModel.fromJson(item))
              .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  // Conversión a entidad del dominio
  PaginatedResult<ProductModel> toPaginatedResult() {
    return PaginatedResult<ProductModel>(data: data, meta: meta);
  }
}
