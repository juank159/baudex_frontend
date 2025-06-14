// lib/features/products/data/models/create_product_request_model.dart
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class CreateProductRequestModel {
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final String? type;
  final String? status;
  final double? stock;
  final double? minStock;
  final String? unit;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final String categoryId;
  final List<CreateProductPriceRequestModel>? prices;

  const CreateProductRequestModel({
    required this.name,
    this.description,
    required this.sku,
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
    required this.categoryId,
    this.prices,
  });

  factory CreateProductRequestModel.fromParams({
    required String name,
    String? description,
    required String sku,
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
    required String categoryId,
    List<CreateProductPriceParams>? prices,
  }) {
    return CreateProductRequestModel(
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      type: type?.name,
      status: status?.name,
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
      prices:
          prices
              ?.map((p) => CreateProductPriceRequestModel.fromParams(p))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
    };

    if (description != null) json['description'] = description;
    if (barcode != null) json['barcode'] = barcode;
    if (type != null) json['type'] = type;
    if (status != null) json['status'] = status;
    if (stock != null) json['stock'] = stock;
    if (minStock != null) json['minStock'] = minStock;
    if (unit != null) json['unit'] = unit;
    if (weight != null) json['weight'] = weight;
    if (length != null) json['length'] = length;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (images != null) json['images'] = images;
    if (metadata != null) json['metadata'] = metadata;
    if (prices != null)
      json['prices'] = prices!.map((p) => p.toJson()).toList();

    return json;
  }

  @override
  String toString() => 'CreateProductRequestModel(name: $name, sku: $sku)';
}

class CreateProductPriceRequestModel {
  final String type;
  final String? name;
  final double amount;
  final String? currency;
  final double? discountPercentage;
  final double? discountAmount;
  final double? minQuantity;
  final String? notes;

  const CreateProductPriceRequestModel({
    required this.type,
    this.name,
    required this.amount,
    this.currency,
    this.discountPercentage,
    this.discountAmount,
    this.minQuantity,
    this.notes,
  });

  factory CreateProductPriceRequestModel.fromParams(
    CreateProductPriceParams params,
  ) {
    return CreateProductPriceRequestModel(
      type: params.type.name,
      name: params.name,
      amount: params.amount,
      currency: params.currency,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      minQuantity: params.minQuantity,
      notes: params.notes,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type, 'amount': amount};

    if (name != null) json['name'] = name;
    if (currency != null) json['currency'] = currency;
    if (discountPercentage != null)
      json['discountPercentage'] = discountPercentage;
    if (discountAmount != null) json['discountAmount'] = discountAmount;
    if (minQuantity != null) json['minQuantity'] = minQuantity;
    if (notes != null) json['notes'] = notes;

    return json;
  }
}
