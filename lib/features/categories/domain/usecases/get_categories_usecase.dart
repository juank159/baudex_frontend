// lib/features/categories/domain/usecases/get_categories_usecase.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase
    implements UseCase<PaginatedResult<Category>, GetCategoriesParams> {
  final CategoryRepository repository;

  const GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Category>>> call(
    GetCategoriesParams params,
  ) async {
    return await repository.getCategories(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      parentId: params.parentId,
      onlyParents: params.onlyParents,
      includeChildren: params.includeChildren,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

class GetCategoriesParams {
  final int page;
  final int limit;
  final String? search;
  final CategoryStatus? status;
  final String? parentId;
  final bool? onlyParents;
  final bool? includeChildren;
  final String? sortBy;
  final String? sortOrder;

  const GetCategoriesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.parentId,
    this.onlyParents,
    this.includeChildren,
    this.sortBy,
    this.sortOrder,
  });
}
