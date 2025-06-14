// lib/features/products/domain/usecases/get_products_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/product.dart';
import '../entities/product_price.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase
    implements UseCase<PaginatedResult<Product>, GetProductsParams> {
  final ProductRepository repository;

  const GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Product>>> call(
    GetProductsParams params,
  ) async {
    return await repository.getProducts(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      type: params.type,
      categoryId: params.categoryId,
      createdById: params.createdById,
      inStock: params.inStock,
      lowStock: params.lowStock,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      priceType: params.priceType,
      includePrices: params.includePrices,
      includeCategory: params.includeCategory,
      includeCreatedBy: params.includeCreatedBy,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

class GetProductsParams extends Equatable {
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

  const GetProductsParams({
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
    this.includePrices = true,
    this.includeCategory = true,
    this.includeCreatedBy = false,
    this.sortBy = 'createdAt',
    this.sortOrder = 'DESC',
  });

  @override
  List<Object?> get props => [
    page,
    limit,
    search,
    status,
    type,
    categoryId,
    createdById,
    inStock,
    lowStock,
    minPrice,
    maxPrice,
    priceType,
    includePrices,
    includeCategory,
    includeCreatedBy,
    sortBy,
    sortOrder,
  ];

  GetProductsParams copyWith({
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
    return GetProductsParams(
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
