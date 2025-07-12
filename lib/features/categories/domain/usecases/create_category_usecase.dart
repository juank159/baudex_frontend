// lib/features/categories/domain/usecases/create_category_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class CreateCategoryUseCase implements UseCase<Category, CreateCategoryParams> {
  final CategoryRepository repository;

  const CreateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(CreateCategoryParams params) async {
    return await repository.createCategory(
      name: params.name,
      description: params.description,
      slug: params.slug,
      image: params.image,
      status: params.status,
      sortOrder: params.sortOrder,
      parentId: params.parentId,
    );
  }
}

class CreateCategoryParams {
  final String name;
  final String? description;
  final String slug;
  final String? image;
  final CategoryStatus? status;
  final int? sortOrder;
  final String? parentId;

  const CreateCategoryParams({
    required this.name,
    this.description,
    required this.slug,
    this.image,
    this.status,
    this.sortOrder,
    this.parentId,
  });
}
