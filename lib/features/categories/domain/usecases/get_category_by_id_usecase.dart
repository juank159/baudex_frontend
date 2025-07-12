// lib/features/categories/domain/usecases/get_category_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoryByIdUseCase
    implements UseCase<Category, GetCategoryByIdParams> {
  final CategoryRepository repository;

  const GetCategoryByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(GetCategoryByIdParams params) async {
    return await repository.getCategoryById(params.id);
  }
}

class GetCategoryByIdParams {
  final String id;

  const GetCategoryByIdParams({required this.id});
}
