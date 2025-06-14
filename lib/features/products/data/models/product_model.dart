// lib/features/products/data/models/product_model.dart
import '../../domain/entities/product.dart';
import 'product_price_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final String type;
  final String status;
  final double stock;
  final double minStock;
  final String? unit;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final String categoryId;
  final String createdById;
  final List<ProductPriceModel>? prices;
  final ProductCategoryModel? category;
  final ProductCreatorModel? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.sku,
    this.barcode,
    required this.type,
    required this.status,
    required this.stock,
    required this.minStock,
    this.unit,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.images,
    this.metadata,
    required this.categoryId,
    required this.createdById,
    this.prices,
    this.category,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      stock: (json['stock'] as num).toDouble(),
      minStock: (json['minStock'] as num).toDouble(),
      unit: json['unit'] as String?,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      length:
          json['length'] != null ? (json['length'] as num).toDouble() : null,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      categoryId: json['categoryId'] as String,
      createdById: json['createdById'] as String,
      prices:
          json['prices'] != null
              ? (json['prices'] as List)
                  .map((price) => ProductPriceModel.fromJson(price))
                  .toList()
              : null,
      category:
          json['category'] != null
              ? ProductCategoryModel.fromJson(json['category'])
              : null,
      createdBy:
          json['createdBy'] != null
              ? ProductCreatorModel.fromJson(json['createdBy'])
              : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'type': type,
      'status': status,
      'stock': stock,
      'minStock': minStock,
      'unit': unit,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'images': images,
      'metadata': metadata,
      'categoryId': categoryId,
      'createdById': createdById,
      'prices': prices?.map((price) => price.toJson()).toList(),
      'category': category?.toJson(),
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Conversión a entidad del dominio
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      type: _mapStringToProductType(type),
      status: _mapStringToProductStatus(status),
      stock: stock,
      minStock: minStock,
      unit: unit,
      weight: weight,
      length: length,
      width: width,
      height: height,
      images: images,
      metadata: metadata,
      categoryId: categoryId,
      createdById: createdById,
      prices: prices?.map((price) => price.toEntity()).toList(),
      category: category?.toEntity(),
      createdBy: createdBy?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Crear modelo desde entidad
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      sku: product.sku,
      barcode: product.barcode,
      type: product.type.name,
      status: product.status.name,
      stock: product.stock,
      minStock: product.minStock,
      unit: product.unit,
      weight: product.weight,
      length: product.length,
      width: product.width,
      height: product.height,
      images: product.images,
      metadata: product.metadata,
      categoryId: product.categoryId,
      createdById: product.createdById,
      prices:
          product.prices
              ?.map((price) => ProductPriceModel.fromEntity(price))
              .toList(),
      category:
          product.category != null
              ? ProductCategoryModel.fromEntity(product.category!)
              : null,
      createdBy:
          product.createdBy != null
              ? ProductCreatorModel.fromEntity(product.createdBy!)
              : null,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  // Mappers privados
  ProductType _mapStringToProductType(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return ProductType.product;
      case 'service':
        return ProductType.service;
      default:
        return ProductType.product;
    }
  }

  ProductStatus _mapStringToProductStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ProductStatus.active;
      case 'inactive':
        return ProductStatus.inactive;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      default:
        return ProductStatus.active;
    }
  }
}

class ProductCategoryModel {
  final String id;
  final String name;
  final String slug;

  const ProductCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }

  ProductCategory toEntity() {
    return ProductCategory(id: id, name: name, slug: slug);
  }

  factory ProductCategoryModel.fromEntity(ProductCategory category) {
    return ProductCategoryModel(
      id: category.id,
      name: category.name,
      slug: category.slug,
    );
  }
}

class ProductCreatorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;

  const ProductCreatorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory ProductCreatorModel.fromJson(Map<String, dynamic> json) {
    return ProductCreatorModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
    };
  }

  ProductCreator toEntity() {
    return ProductCreator(
      id: id,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
    );
  }

  factory ProductCreatorModel.fromEntity(ProductCreator creator) {
    return ProductCreatorModel(
      id: creator.id,
      firstName: creator.firstName,
      lastName: creator.lastName,
      fullName: creator.fullName,
    );
  }
}
