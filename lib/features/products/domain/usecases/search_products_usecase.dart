// lib/features/products/domain/usecases/search_products_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SearchProductsUseCase
    implements UseCase<List<Product>, SearchProductsParams> {
  final ProductRepository repository;

  const SearchProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(
    SearchProductsParams params,
  ) async {
    return await repository.searchProducts(
      params.searchTerm,
      limit: params.limit,
    );
  }
}

class SearchProductsParams extends Equatable {
  final String searchTerm;
  final int limit;

  const SearchProductsParams({required this.searchTerm, this.limit = 10});

  @override
  List<Object> get props => [searchTerm, limit];
}
