// lib/features/products/domain/usecases/delete_product_presentation_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/product_presentation_repository.dart';

class DeleteProductPresentationUseCase
    implements UseCase<Unit, DeleteProductPresentationParams> {
  final ProductPresentationRepository repository;

  const DeleteProductPresentationUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    DeleteProductPresentationParams params,
  ) async {
    return await repository.deletePresentation(params.productId, params.id);
  }
}

class DeleteProductPresentationParams extends Equatable {
  final String productId;
  final String id;

  const DeleteProductPresentationParams({
    required this.productId,
    required this.id,
  });

  @override
  List<Object> get props => [productId, id];
}
