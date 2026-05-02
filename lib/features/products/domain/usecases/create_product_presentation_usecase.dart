// lib/features/products/domain/usecases/create_product_presentation_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_presentation.dart';
import '../repositories/product_presentation_repository.dart';

class CreateProductPresentationUseCase
    implements UseCase<ProductPresentation, CreateProductPresentationParams> {
  final ProductPresentationRepository repository;

  const CreateProductPresentationUseCase(this.repository);

  @override
  Future<Either<Failure, ProductPresentation>> call(
    CreateProductPresentationParams params,
  ) async {
    return await repository.createPresentation(
      productId: params.productId,
      name: params.name,
      factor: params.factor,
      price: params.price,
      currency: params.currency,
      barcode: params.barcode,
      sku: params.sku,
      isDefault: params.isDefault,
      isActive: params.isActive,
      sortOrder: params.sortOrder,
    );
  }
}

class CreateProductPresentationParams extends Equatable {
  final String productId;
  final String name;
  final double factor;
  final double price;
  final String? currency;
  final String? barcode;
  final String? sku;
  final bool? isDefault;
  final bool? isActive;
  final int? sortOrder;

  const CreateProductPresentationParams({
    required this.productId,
    required this.name,
    required this.factor,
    required this.price,
    this.currency,
    this.barcode,
    this.sku,
    this.isDefault,
    this.isActive,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [
        productId,
        name,
        factor,
        price,
        currency,
        barcode,
        sku,
        isDefault,
        isActive,
        sortOrder,
      ];
}
