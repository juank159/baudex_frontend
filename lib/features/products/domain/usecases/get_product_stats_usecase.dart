// lib/features/products/domain/usecases/get_product_stats_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_stats.dart';
import '../repositories/product_repository.dart';

class GetProductStatsUseCase implements UseCase<ProductStats, NoParams> {
  final ProductRepository repository;

  GetProductStatsUseCase(this.repository);

  @override
  Future<Either<Failure, ProductStats>> call(NoParams params) async {
    return await repository.getProductStats();
  }
}
