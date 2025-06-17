// // lib/features/products/data/models/product_price_model.dart
// import '../../domain/entities/product_price.dart';

// class ProductPriceModel {
//   final String id;
//   final String type;
//   final String? name;
//   final double amount;
//   final String currency;
//   final String status;
//   final DateTime? validFrom;
//   final DateTime? validTo;
//   final double discountPercentage;
//   final double? discountAmount;
//   final double
//   minQuantity; // ✅ Mantenemos double para ser consistente con la entidad
//   final double? profitMargin;
//   final String? notes;
//   final String productId;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   const ProductPriceModel({
//     required this.id,
//     required this.type,
//     this.name,
//     required this.amount,
//     required this.currency,
//     required this.status,
//     this.validFrom,
//     this.validTo,
//     required this.discountPercentage,
//     this.discountAmount,
//     required this.minQuantity,
//     this.profitMargin,
//     this.notes,
//     required this.productId,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
//     return ProductPriceModel(
//       id: json['id'] as String,
//       type: json['type'] as String,
//       name: json['name'] as String?,
//       // ✅ SOLUCIÓN: Usar helper para parsear doubles de forma segura
//       amount: _parseDouble(json['amount']),
//       currency: json['currency'] as String,
//       status: json['status'] as String,
//       validFrom:
//           json['validFrom'] != null
//               ? DateTime.parse(json['validFrom'] as String)
//               : null,
//       validTo:
//           json['validTo'] != null
//               ? DateTime.parse(json['validTo'] as String)
//               : null,
//       discountPercentage: _parseDouble(json['discountPercentage']),
//       discountAmount:
//           json['discountAmount'] != null
//               ? _parseDouble(json['discountAmount'])
//               : null,
//       // ✅ SOLUCIÓN: Parsear minQuantity como double (consistente con entidad)
//       minQuantity: _parseDouble(json['minQuantity']),
//       profitMargin:
//           json['profitMargin'] != null
//               ? _parseDouble(json['profitMargin'])
//               : null,
//       notes: json['notes'] as String?,
//       productId: json['productId'] as String,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//     );
//   }

//   // ✅ FUNCIÓN HELPER: Parsear double de forma segura
//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       return double.tryParse(value) ?? 0.0;
//     }
//     return 0.0;
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'type': type,
//       'name': name,
//       'amount': amount,
//       'currency': currency,
//       'status': status,
//       'validFrom': validFrom?.toIso8601String(),
//       'validTo': validTo?.toIso8601String(),
//       'discountPercentage': discountPercentage,
//       'discountAmount': discountAmount,
//       'minQuantity': minQuantity,
//       'profitMargin': profitMargin,
//       'notes': notes,
//       'productId': productId,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   // Conversión a entidad del dominio
//   ProductPrice toEntity() {
//     return ProductPrice(
//       id: id,
//       type: _mapStringToPriceType(type),
//       name: name,
//       amount: amount,
//       currency: currency,
//       status: _mapStringToPriceStatus(status),
//       validFrom: validFrom,
//       validTo: validTo,
//       discountPercentage: discountPercentage,
//       discountAmount: discountAmount,
//       minQuantity: minQuantity, // ✅ Ahora ambos son double, no hay conflicto
//       profitMargin: profitMargin,
//       notes: notes,
//       productId: productId,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//     );
//   }

//   // Crear modelo desde entidad
//   factory ProductPriceModel.fromEntity(ProductPrice price) {
//     return ProductPriceModel(
//       id: price.id,
//       type: price.type.name,
//       name: price.name,
//       amount: price.amount,
//       currency: price.currency,
//       status: price.status.name,
//       validFrom: price.validFrom,
//       validTo: price.validTo,
//       discountPercentage: price.discountPercentage,
//       discountAmount: price.discountAmount,
//       minQuantity:
//           price.minQuantity, // ✅ Ahora ambos son double, no hay conflicto
//       profitMargin: price.profitMargin,
//       notes: price.notes,
//       productId: price.productId,
//       createdAt: price.createdAt,
//       updatedAt: price.updatedAt,
//     );
//   }

//   // Mappers privados
//   PriceType _mapStringToPriceType(String type) {
//     switch (type.toLowerCase()) {
//       case 'price1':
//         return PriceType.price1;
//       case 'price2':
//         return PriceType.price2;
//       case 'price3':
//         return PriceType.price3;
//       case 'special':
//         return PriceType.special;
//       case 'cost':
//         return PriceType.cost;
//       default:
//         return PriceType.price1;
//     }
//   }

//   PriceStatus _mapStringToPriceStatus(String status) {
//     switch (status.toLowerCase()) {
//       case 'active':
//         return PriceStatus.active;
//       case 'inactive':
//         return PriceStatus.inactive;
//       default:
//         return PriceStatus.active;
//     }
//   }
// }

// lib/features/products/data/models/product_price_model.dart
import '../../domain/entities/product_price.dart';

class ProductPriceModel {
  final String id;
  final String type;
  final String? name;
  final double amount;
  final String currency;
  final String status;
  final DateTime? validFrom;
  final DateTime? validTo;
  final double discountPercentage;
  final double? discountAmount;
  final double minQuantity;
  final double? profitMargin;
  final String? notes;
  final String productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPriceModel({
    required this.id,
    required this.type,
    this.name,
    required this.amount,
    required this.currency,
    required this.status,
    this.validFrom,
    this.validTo,
    required this.discountPercentage,
    this.discountAmount,
    required this.minQuantity,
    this.profitMargin,
    this.notes,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 ProductPriceModel.fromJson: Procesando precio ${json['id']}');

      return ProductPriceModel(
        id: json['id'] as String,
        type: json['type'] as String,
        // ✅ CORRECCIÓN: Manejo seguro de campos nullable
        name: json['name'] as String?,
        // ✅ CORRECCIÓN: Usar helper para parsear doubles de forma segura
        amount: _parseDouble(json['amount']),
        currency: json['currency'] as String,
        status: json['status'] as String,
        // ✅ CORRECCIÓN: Manejo seguro de fechas que pueden ser null
        validFrom:
            json['validFrom'] != null
                ? DateTime.parse(json['validFrom'] as String)
                : null,
        validTo:
            json['validTo'] != null
                ? DateTime.parse(json['validTo'] as String)
                : null,
        discountPercentage: _parseDouble(json['discountPercentage']),
        discountAmount:
            json['discountAmount'] != null
                ? _parseDouble(json['discountAmount'])
                : null,
        // ✅ CORRECCIÓN: Parsear minQuantity como double (consistente con entidad)
        minQuantity: _parseDouble(json['minQuantity']),
        profitMargin:
            json['profitMargin'] != null
                ? _parseDouble(json['profitMargin'])
                : null,
        notes: json['notes'] as String?,
        // ✅ CORRECCIÓN: Manejar productId que puede venir en el contexto
        productId: json['productId'] as String? ?? '',
        // ✅ CORRECCIÓN: Manejo seguro de fechas con fallback
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.now(),
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('❌ Error en ProductPriceModel.fromJson: $e');
      print('📋 JSON problemático: $json');
      print('🔍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ✅ FUNCIÓN HELPER: Parsear double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Manejar números con formato "3900.00" que vienen como string
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'amount': amount,
      'currency': currency,
      'status': status,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'minQuantity': minQuantity,
      'profitMargin': profitMargin,
      'notes': notes,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Conversión a entidad del dominio
  ProductPrice toEntity() {
    return ProductPrice(
      id: id,
      type: _mapStringToPriceType(type),
      name: name,
      amount: amount,
      currency: currency,
      status: _mapStringToPriceStatus(status),
      validFrom: validFrom,
      validTo: validTo,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      minQuantity: minQuantity, // ✅ Ahora ambos son double, no hay conflicto
      profitMargin: profitMargin,
      notes: notes,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Crear modelo desde entidad
  factory ProductPriceModel.fromEntity(ProductPrice price) {
    return ProductPriceModel(
      id: price.id,
      type: price.type.name,
      name: price.name,
      amount: price.amount,
      currency: price.currency,
      status: price.status.name,
      validFrom: price.validFrom,
      validTo: price.validTo,
      discountPercentage: price.discountPercentage,
      discountAmount: price.discountAmount,
      minQuantity:
          price.minQuantity, // ✅ Ahora ambos son double, no hay conflicto
      profitMargin: price.profitMargin,
      notes: price.notes,
      productId: price.productId,
      createdAt: price.createdAt,
      updatedAt: price.updatedAt,
    );
  }

  // Mappers privados
  PriceType _mapStringToPriceType(String type) {
    switch (type.toLowerCase()) {
      case 'price1':
        return PriceType.price1;
      case 'price2':
        return PriceType.price2;
      case 'price3':
        return PriceType.price3;
      case 'special':
        return PriceType.special;
      case 'cost':
        return PriceType.cost;
      default:
        return PriceType.price1;
    }
  }

  PriceStatus _mapStringToPriceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PriceStatus.active;
      case 'inactive':
        return PriceStatus.inactive;
      default:
        return PriceStatus.active;
    }
  }
}
