// lib/features/products/data/models/product_waste_response_model.dart

class ProductWasteResponseModel {
  final String movementId;
  final String movementNumber;
  final double quantity;
  final double totalCost;
  final String reason;

  const ProductWasteResponseModel({
    required this.movementId,
    required this.movementNumber,
    required this.quantity,
    required this.totalCost,
    required this.reason,
  });

  factory ProductWasteResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductWasteResponseModel(
      movementId: json['movementId'] as String? ?? '',
      movementNumber: json['movementNumber'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
