// lib/features/products/data/models/register_product_waste_request_model.dart

class RegisterProductWasteRequestModel {
  final double quantity;
  final String reason;
  final String? warehouseId;

  const RegisterProductWasteRequestModel({
    required this.quantity,
    required this.reason,
    this.warehouseId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'quantity': quantity,
      'reason': reason,
    };
    if (warehouseId != null) {
      map['warehouseId'] = warehouseId;
    }
    return map;
  }
}
