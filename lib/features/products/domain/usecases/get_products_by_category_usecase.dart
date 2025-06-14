// lib/features/products/domain/usecases/get_products_by_category_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsByCategoryUseCase
    implements UseCase<List<Product>, GetProductsByCategoryParams> {
  final ProductRepository repository;

  const GetProductsByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(
    GetProductsByCategoryParams params,
  ) async {
    return await repository.getProductsByCategory(params.categoryId);
  }
}

class GetProductsByCategoryParams extends Equatable {
  final String categoryId;

  const GetProductsByCategoryParams({required this.categoryId});

  @override
  List<Object> get props => [categoryId];
}
