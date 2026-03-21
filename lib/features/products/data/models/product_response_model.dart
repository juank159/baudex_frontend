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
