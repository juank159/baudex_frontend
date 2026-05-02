// lib/features/products/data/models/update_product_presentation_request_model.dart
class UpdateProductPresentationRequestModel {
  final String? name;
  final double? factor;
  final double? price;
  final String? currency;
  final String? barcode;
  final String? sku;
  final bool? isDefault;
  final bool? isActive;
  final int? sortOrder;

  const UpdateProductPresentationRequestModel({
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

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (factor != null) map['factor'] = factor;
    if (price != null) map['price'] = price;
    if (currency != null) map['currency'] = currency;
    if (barcode != null) map['barcode'] = barcode;
    if (sku != null) map['sku'] = sku;
    if (isDefault != null) map['isDefault'] = isDefault;
    if (isActive != null) map['isActive'] = isActive;
    if (sortOrder != null) map['sortOrder'] = sortOrder;
    return map;
  }
}
