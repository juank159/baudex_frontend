// lib/features/products/domain/usecases/update_product_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase implements UseCase<Product, UpdateProductParams> {
  final ProductRepository repository;

  const UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(UpdateProductParams params) async {
    return await repository.updateProduct(
      id: params.id,
      name: params.name,
      description: params.description,
      sku: params.sku,
      barcode: params.barcode,
      type: params.type,
      status: params.status,
      stock: params.stock,
      minStock: params.minStock,
      unit: params.unit,
      weight: params.weight,
      length: params.length,
      width: params.width,
      height: params.height,
      images: params.images,
      metadata: params.metadata,
      categoryId: params.categoryId,
    );
  }
}

class UpdateProductParams extends Equatable {
  final String id;
  final String? name;
  final String? description;
  final String? sku;
  final String? barcode;
  final ProductType? type;
  final ProductStatus? status;
  final double? stock;
  final double? minStock;
  final String? unit;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final String? categoryId;

  const UpdateProductParams({
    required this.id,
    this.name,
    this.description,
    this.sku,
    this.barcode,
    this.type,
    this.status,
    this.stock,
    this.minStock,
    this.unit,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.images,
    this.metadata,
    this.categoryId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    sku,
    barcode,
    type,
    status,
    stock,
    minStock,
    unit,
    weight,
    length,
    width,
    height,
    images,
    metadata,
    categoryId,
  ];
}
