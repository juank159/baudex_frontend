// lib/features/categories/domain/usecases/update_category_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase implements UseCase<Category, UpdateCategoryParams> {
  final CategoryRepository repository;

  const UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(UpdateCategoryParams params) async {
    return await repository.updateCategory(
      id: params.id,
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

class UpdateCategoryParams {
  final String id;
  final String? name;
  final String? description;
  final String? slug;
  final String? image;
  final CategoryStatus? status;
  final int? sortOrder;
  final String? parentId;

  const UpdateCategoryParams({
    required this.id,
    this.name,
    this.description,
    this.slug,
    this.image,
    this.status,
    this.sortOrder,
    this.parentId,
  });
}
