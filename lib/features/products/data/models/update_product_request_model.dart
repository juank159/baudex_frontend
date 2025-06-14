// lib/features/products/data/models/update_product_request_model.dart
import '../../domain/entities/product.dart';

class UpdateProductRequestModel {
  final String? name;
  final String? description;
  final String? sku;
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
  final String? categoryId;

  const UpdateProductRequestModel({
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

  factory UpdateProductRequestModel.fromParams({
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
  }) {
    return UpdateProductRequestModel(
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
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (sku != null) json['sku'] = sku;
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
    if (categoryId != null) json['categoryId'] = categoryId;

    return json;
  }

  bool get hasUpdates {
    return name != null ||
        description != null ||
        sku != null ||
        barcode != null ||
        type != null ||
        status != null ||
        stock != null ||
        minStock != null ||
        unit != null ||
        weight != null ||
        length != null ||
        width != null ||
        height != null ||
        images != null ||
        metadata != null ||
        categoryId != null;
  }

  @override
  String toString() => 'UpdateProductRequestModel(hasUpdates: $hasUpdates)';
}
