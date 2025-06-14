// lib/features/products/domain/usecases/delete_product_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/product_repository.dart';

class DeleteProductUseCase implements UseCase<Unit, DeleteProductParams> {
  final ProductRepository repository;

  const DeleteProductUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteProductParams params) async {
    return await repository.deleteProduct(params.id);
  }
}

class DeleteProductParams extends Equatable {
  final String id;

  const DeleteProductParams({required this.id});

  @override
  List<Object> get props => [id];
}
