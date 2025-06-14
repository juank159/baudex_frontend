// lib/features/categories/domain/usecases/search_categories_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class SearchCategoriesUseCase
    implements UseCase<List<Category>, SearchCategoriesParams> {
  final CategoryRepository repository;

  const SearchCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    SearchCategoriesParams params,
  ) async {
    return await repository.searchCategories(
      params.searchTerm,
      limit: params.limit,
    );
  }
}

class SearchCategoriesParams {
  final String searchTerm;
  final int limit;

  const SearchCategoriesParams({required this.searchTerm, this.limit = 10});
}
