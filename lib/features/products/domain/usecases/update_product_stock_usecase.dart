// lib/features/products/domain/usecases/update_product_stock_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductStockUseCase
    implements UseCase<Product, UpdateProductStockParams> {
  final ProductRepository repository;

  const UpdateProductStockUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(UpdateProductStockParams params) async {
    return await repository.updateProductStock(
      id: params.id,
      quantity: params.quantity,
      operation: params.operation,
    );
  }
}

class UpdateProductStockParams extends Equatable {
  final String id;
  final double quantity;
  final String operation; // 'add' or 'subtract'

  const UpdateProductStockParams({
    required this.id,
    required this.quantity,
    this.operation = 'subtract',
  });

  @override
  List<Object> get props => [id, quantity, operation];
}
