// lib/features/products/domain/usecases/update_product_presentation_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_presentation.dart';
import '../repositories/product_presentation_repository.dart';

class UpdateProductPresentationUseCase
    implements UseCase<ProductPresentation, UpdateProductPresentationParams> {
  final ProductPresentationRepository repository;

  const UpdateProductPresentationUseCase(this.repository);

  @override
  Future<Either<Failure, ProductPresentation>> call(
    UpdateProductPresentationParams params,
  ) async {
    return await repository.updatePresentation(
      productId: params.productId,
      id: params.id,
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

class UpdateProductPresentationParams extends Equatable {
  final String productId;
  final String id;
  final String? name;
  final double? factor;
  final double? price;
  final String? currency;
  final String? barcode;
  final String? sku;
  final bool? isDefault;
  final bool? isActive;
  final int? sortOrder;

  const UpdateProductPresentationParams({
    required this.productId,
    required this.id,
    this.name,
    this.factor,
    this.price,
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
        id,
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
