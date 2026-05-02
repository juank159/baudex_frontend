// lib/features/products/domain/usecases/get_product_presentations_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_presentation.dart';
import '../repositories/product_presentation_repository.dart';

class GetProductPresentationsUseCase
    implements UseCase<List<ProductPresentation>, GetProductPresentationsParams> {
  final ProductPresentationRepository repository;

  const GetProductPresentationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductPresentation>>> call(
    GetProductPresentationsParams params,
  ) async {
    return await repository.getPresentations(params.productId);
  }
}

class GetProductPresentationsParams extends Equatable {
  final String productId;

  const GetProductPresentationsParams({required this.productId});

  @override
  List<Object> get props => [productId];
}
