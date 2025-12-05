// lib/features/products/data/models/create_product_request_model.dart
import '../../domain/entities/product.dart';
import '../../domain/entities/tax_enums.dart';
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
  // Campos de facturación electrónica
  final String? taxCategory;
  final double? taxRate;
  final bool? isTaxable;
  final String? taxDescription;
  final String? retentionCategory;
  final double? retentionRate;
  final bool? hasRetention;

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
    // Campos de facturación electrónica
    this.taxCategory,
    this.taxRate,
    this.isTaxable,
    this.taxDescription,
    this.retentionCategory,
    this.retentionRate,
    this.hasRetention,
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
    // Campos de facturación electrónica
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
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
      // Campos de facturación electrónica
      taxCategory: taxCategory?.value,
      taxRate: taxRate,
      isTaxable: isTaxable,
      taxDescription: taxDescription,
      retentionCategory: retentionCategory?.value,
      retentionRate: retentionRate,
      hasRetention: hasRetention,
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
    if (prices != null) {
      json['prices'] = prices!.map((p) => p.toJson()).toList();
    }
    // Campos de facturación electrónica
    if (taxCategory != null) json['taxCategory'] = taxCategory;
    if (taxRate != null) json['taxRate'] = taxRate;
    if (isTaxable != null) json['isTaxable'] = isTaxable;
    if (taxDescription != null) json['taxDescription'] = taxDescription;
    if (retentionCategory != null)
      json['retentionCategory'] = retentionCategory;
    if (retentionRate != null) json['retentionRate'] = retentionRate;
    if (hasRetention != null) json['hasRetention'] = hasRetention;

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
    if (discountPercentage != null) {
      json['discountPercentage'] = discountPercentage;
    }
    if (discountAmount != null) json['discountAmount'] = discountAmount;
    if (minQuantity != null) json['minQuantity'] = minQuantity;
    if (notes != null) json['notes'] = notes;

    return json;
  }
}
