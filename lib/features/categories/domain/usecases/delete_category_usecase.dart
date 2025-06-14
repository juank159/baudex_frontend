// lib/features/categories/domain/usecases/delete_category_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryUseCase implements UseCase<Unit, DeleteCategoryParams> {
  final CategoryRepository repository;

  const DeleteCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteCategoryParams params) async {
    return await repository.deleteCategory(params.id);
  }
}

class DeleteCategoryParams {
  final String id;

  const DeleteCategoryParams({required this.id});
}
