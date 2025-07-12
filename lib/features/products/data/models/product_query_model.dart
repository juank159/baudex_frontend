// lib/features/products/data/models/product_query_model.dart
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductQueryModel {
  final int page;
  final int limit;
  final String? search;
  final ProductStatus? status;
  final ProductType? type;
  final String? categoryId;
  final String? createdById;
  final bool? inStock;
  final bool? lowStock;
  final double? minPrice;
  final double? maxPrice;
  final PriceType? priceType;
  final bool? includePrices;
  final bool? includeCategory;
  final bool? includeCreatedBy;
  final String? sortBy;
  final String? sortOrder;

  const ProductQueryModel({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.type,
    this.categoryId,
    this.createdById,
    this.inStock,
    this.lowStock,
    this.minPrice,
    this.maxPrice,
    this.priceType,
    this.includePrices,
    this.includeCategory,
    this.includeCreatedBy,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {'page': page, 'limit': limit};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }

    if (status != null) {
      params['status'] = status!.name;
    }

    if (type != null) {
      params['type'] = type!.name;
    }

    if (categoryId != null && categoryId!.isNotEmpty) {
      params['categoryId'] = categoryId;
    }

    if (createdById != null && createdById!.isNotEmpty) {
      params['createdById'] = createdById;
    }

    if (inStock != null) {
      params['inStock'] = inStock;
    }

    if (lowStock != null) {
      params['lowStock'] = lowStock;
    }

    if (minPrice != null) {
      params['minPrice'] = minPrice;
    }

    if (maxPrice != null) {
      params['maxPrice'] = maxPrice;
    }

    if (priceType != null) {
      params['priceType'] = priceType!.name;
    }

    if (includePrices != null) {
      params['includePrices'] = includePrices;
    }

    if (includeCategory != null) {
      params['includeCategory'] = includeCategory;
    }

    if (includeCreatedBy != null) {
      params['includeCreatedBy'] = includeCreatedBy;
    }

    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sortBy'] = sortBy;
    }

    if (sortOrder != null && sortOrder!.isNotEmpty) {
      params['sortOrder'] = sortOrder;
    }

    return params;
  }

  ProductQueryModel copyWith({
    int? page,
    int? limit,
    String? search,
    ProductStatus? status,
    ProductType? type,
    String? categoryId,
    String? createdById,
    bool? inStock,
    bool? lowStock,
    double? minPrice,
    double? maxPrice,
    PriceType? priceType,
    bool? includePrices,
    bool? includeCategory,
    bool? includeCreatedBy,
    String? sortBy,
    String? sortOrder,
  }) {
    return ProductQueryModel(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      createdById: createdById ?? this.createdById,
      inStock: inStock ?? this.inStock,
      lowStock: lowStock ?? this.lowStock,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      priceType: priceType ?? this.priceType,
      includePrices: includePrices ?? this.includePrices,
      includeCategory: includeCategory ?? this.includeCategory,
      includeCreatedBy: includeCreatedBy ?? this.includeCreatedBy,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
