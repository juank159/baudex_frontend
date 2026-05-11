// lib/features/products/data/models/create_product_presentation_request_model.dart
class CreateProductPresentationRequestModel {
  final String name;
  final double factor;
  final double price;
  final String? currency;
  final String? barcode;
  final String? sku;
  final bool? isDefault;
  final bool? isActive;
  final int? sortOrder;

  const CreateProductPresentationRequestModel({
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

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'factor': factor,
      'price': price,
    };
    if (currency != null) map['currency'] = currency;
    if (barcode != null) map['barcode'] = barcode;
    if (sku != null) map['sku'] = sku;
    if (isDefault != null) map['isDefault'] = isDefault;
    if (isActive != null) map['isActive'] = isActive;
    if (sortOrder != null) map['sortOrder'] = sortOrder;
    return map;
  }
}
