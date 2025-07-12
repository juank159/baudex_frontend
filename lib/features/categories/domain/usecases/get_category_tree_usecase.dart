// lib/features/categories/domain/usecases/get_category_tree_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category_tree.dart';
import '../repositories/category_repository.dart';

class GetCategoryTreeUseCase implements UseCase<List<CategoryTree>, NoParams> {
  final CategoryRepository repository;

  const GetCategoryTreeUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryTree>>> call(NoParams params) async {
    return await repository.getCategoryTree();
  }
}
