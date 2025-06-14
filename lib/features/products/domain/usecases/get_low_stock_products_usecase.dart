// lib/features/products/domain/usecases/get_low_stock_products_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetLowStockProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  const GetLowStockProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getLowStockProducts();
  }
}
