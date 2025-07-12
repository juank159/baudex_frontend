// lib/features/products/domain/usecases/get_product_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByIdUseCase implements UseCase<Product, GetProductByIdParams> {
  final ProductRepository repository;

  const GetProductByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(GetProductByIdParams params) async {
    return await repository.getProductById(params.id);
  }
}

class GetProductByIdParams extends Equatable {
  final String id;

  const GetProductByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}
