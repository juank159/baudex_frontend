// lib/features/categories/domain/usecases/get_category_stats_usecase.dart
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/category_repository.dart';

class GetCategoryStatsUseCase implements UseCase<CategoryStats, NoParams> {
  final CategoryRepository repository;

  const GetCategoryStatsUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryStats>> call(NoParams params) async {
    return await repository.getCategoryStats();
  }
}
