// // lib/features/products/domain/entities/product.dart
// import 'package:equatable/equatable.dart';
// import 'product_price.dart';

// enum ProductStatus { active, inactive, outOfStock }

// enum ProductType { product, service }

// class Product extends Equatable {
//   final String id;
//   final String name;
//   final String? description;
//   final String sku;
//   final String? barcode;
//   final ProductType type;
//   final ProductStatus status;
//   final double stock;
//   final double minStock;
//   final String? unit;
//   final double? weight;
//   final double? length;
//   final double? width;
//   final double? height;
//   final List<String>? images;
//   final Map<String, dynamic>? metadata;
//   final String categoryId;
//   final String createdById;
//   final List<ProductPrice>? prices;
//   final ProductCategory? category;
//   final ProductCreator? createdBy;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   const Product({
//     required this.id,
//     required this.name,
//     this.description,
//     required this.sku,
//     this.barcode,
//     required this.type,
//     required this.status,
//     required this.stock,
//     required this.minStock,
//     this.unit,
//     this.weight,
//     this.length,
//     this.width,
//     this.height,
//     this.images,
//     this.metadata,
//     required this.categoryId,
//     required this.createdById,
//     this.prices,
//     this.category,
//     this.createdBy,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   @override
//   List<Object?> get props => [
//     id,
//     name,
//     description,
//     sku,
//     barcode,
//     type,
//     status,
//     stock,
//     minStock,
//     unit,
//     weight,
//     length,
//     width,
//     height,
//     images,
//     metadata,
//     categoryId,
//     createdById,
//     prices,
//     category,
//     createdBy,
//     createdAt,
//     updatedAt,
//   ];

//   // Getters computados
//   bool get isActive => status == ProductStatus.active;
//   bool get isInStock => stock > 0 && status != ProductStatus.outOfStock;
//   bool get isLowStock => stock <= minStock;
//   String? get primaryImage => images?.isNotEmpty == true ? images!.first : null;

//   // Métodos de utilidad
//   ProductPrice? getPriceByType(PriceType priceType) {
//     return prices
//         ?.where((price) => price.type == priceType && price.isActive)
//         .firstOrNull;
//   }

//   ProductPrice? get defaultPrice {
//     return getPriceByType(PriceType.price1) ??
//         prices?.where((price) => price.isActive).firstOrNull;
//   }

//   double? get costPrice {
//     return getPriceByType(PriceType.cost)?.finalAmount;
//   }

//   double? get sellingPrice {
//     return defaultPrice?.finalAmount;
//   }

//   bool hasValidPrice() {
//     return prices?.any((price) => price.isActive) == true;
//   }

//   bool canBeSold() {
//     return isActive && isInStock && hasValidPrice();
//   }

//   // Método para copyWith
//   Product copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? sku,
//     String? barcode,
//     ProductType? type,
//     ProductStatus? status,
//     double? stock,
//     double? minStock,
//     String? unit,
//     double? weight,
//     double? length,
//     double? width,
//     double? height,
//     List<String>? images,
//     Map<String, dynamic>? metadata,
//     String? categoryId,
//     String? createdById,
//     List<ProductPrice>? prices,
//     ProductCategory? category,
//     ProductCreator? createdBy,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return Product(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       sku: sku ?? this.sku,
//       barcode: barcode ?? this.barcode,
//       type: type ?? this.type,
//       status: status ?? this.status,
//       stock: stock ?? this.stock,
//       minStock: minStock ?? this.minStock,
//       unit: unit ?? this.unit,
//       weight: weight ?? this.weight,
//       length: length ?? this.length,
//       width: width ?? this.width,
//       height: height ?? this.height,
//       images: images ?? this.images,
//       metadata: metadata ?? this.metadata,
//       categoryId: categoryId ?? this.categoryId,
//       createdById: createdById ?? this.createdById,
//       prices: prices ?? this.prices,
//       category: category ?? this.category,
//       createdBy: createdBy ?? this.createdBy,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }

// // Entidades relacionadas
// class ProductCategory extends Equatable {
//   final String id;
//   final String name;
//   final String slug;

//   const ProductCategory({
//     required this.id,
//     required this.name,
//     required this.slug,
//   });

//   @override
//   List<Object> get props => [id, name, slug];
// }

// class ProductCreator extends Equatable {
//   final String id;
//   final String firstName;
//   final String lastName;
//   final String fullName;

//   const ProductCreator({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.fullName,
//   });

//   @override
//   List<Object> get props => [id, firstName, lastName, fullName];
// }

// lib/features/products/domain/entities/product.dart - CORRECCIÓN FINAL
import 'package:equatable/equatable.dart';
import 'product_price.dart';

enum ProductStatus { active, inactive, outOfStock }

enum ProductType { product, service }

class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final ProductType type;
  final ProductStatus status;
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
  final List<ProductPrice>? prices;
  final ProductCategory? category;
  final ProductCreator? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
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
    createdById,
    prices,
    category,
    createdBy,
    createdAt,
    updatedAt,
  ];

  // ✅ GETTERS CORREGIDOS - SOLUCIÓN FINAL
  bool get isActive => status == ProductStatus.active;
  bool get isInStock => stock > 0 && status != ProductStatus.outOfStock;

  // ✅ LÓGICA FINAL: Solo stock <= minStock (cada producto usa su propio minStock)
  bool get isLowStock => stock <= minStock;

  String? get primaryImage => images?.isNotEmpty == true ? images!.first : null;

  // Métodos de utilidad
  ProductPrice? getPriceByType(PriceType priceType) {
    return prices
        ?.where((price) => price.type == priceType && price.isActive)
        .firstOrNull;
  }

  ProductPrice? get defaultPrice {
    return getPriceByType(PriceType.price1) ??
        prices?.where((price) => price.isActive).firstOrNull;
  }

  double? get costPrice {
    return getPriceByType(PriceType.cost)?.finalAmount;
  }

  double? get sellingPrice {
    return defaultPrice?.finalAmount;
  }

  bool hasValidPrice() {
    return prices?.any((price) => price.isActive) == true;
  }

  bool canBeSold() {
    return isActive && isInStock && hasValidPrice();
  }

  // Método para copyWith
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    ProductType? type,
    ProductStatus? status,
    double? stock,
    double? minStock,
    String? unit,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? images,
    Map<String, dynamic>? metadata,
    String? categoryId,
    String? createdById,
    List<ProductPrice>? prices,
    ProductCategory? category,
    ProductCreator? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      type: type ?? this.type,
      status: status ?? this.status,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
      categoryId: categoryId ?? this.categoryId,
      createdById: createdById ?? this.createdById,
      prices: prices ?? this.prices,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ MÉTODO DE DEBUG PARA VERIFICAR CÁLCULOS
  void debugStock() {
    print('📊 DEBUG Stock para $name:');
    print('   - Stock actual: $stock');
    print('   - Stock mínimo: $minStock');
    print('   - Stock <= MinStock: ${stock <= minStock}');
    print('   - isLowStock: $isLowStock');
    print('   - Status: $status');
    print('   - isActive: $isActive');
    print('   - isInStock: $isInStock');
  }
}

// Entidades relacionadas
class ProductCategory extends Equatable {
  final String id;
  final String name;
  final String slug;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object> get props => [id, name, slug];
}

class ProductCreator extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;

  const ProductCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  @override
  List<Object> get props => [id, firstName, lastName, fullName];
}
