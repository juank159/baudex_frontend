// // // lib/features/products/data/models/product_price_model.dart
// // import '../../domain/entities/product_price.dart';

// // class ProductPriceModel {
// //   final String id;
// //   final String type;
// //   final String? name;
// //   final double amount;
// //   final String currency;
// //   final String status;
// //   final DateTime? validFrom;
// //   final DateTime? validTo;
// //   final double discountPercentage;
// //   final double? discountAmount;
// //   final double
// //   minQuantity; // ✅ Mantenemos double para ser consistente con la entidad
// //   final double? profitMargin;
// //   final String? notes;
// //   final String productId;
// //   final DateTime createdAt;
// //   final DateTime updatedAt;

// //   const ProductPriceModel({
// //     required this.id,
// //     required this.type,
// //     this.name,
// //     required this.amount,
// //     required this.currency,
// //     required this.status,
// //     this.validFrom,
// //     this.validTo,
// //     required this.discountPercentage,
// //     this.discountAmount,
// //     required this.minQuantity,
// //     this.profitMargin,
// //     this.notes,
// //     required this.productId,
// //     required this.createdAt,
// //     required this.updatedAt,
// //   });

// //   factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
// //     return ProductPriceModel(
// //       id: json['id'] as String,
// //       type: json['type'] as String,
// //       name: json['name'] as String?,
// //       // ✅ SOLUCIÓN: Usar helper para parsear doubles de forma segura
// //       amount: _parseDouble(json['amount']),
// //       currency: json['currency'] as String,
// //       status: json['status'] as String,
// //       validFrom:
// //           json['validFrom'] != null
// //               ? DateTime.parse(json['validFrom'] as String)
// //               : null,
// //       validTo:
// //           json['validTo'] != null
// //               ? DateTime.parse(json['validTo'] as String)
// //               : null,
// //       discountPercentage: _parseDouble(json['discountPercentage']),
// //       discountAmount:
// //           json['discountAmount'] != null
// //               ? _parseDouble(json['discountAmount'])
// //               : null,
// //       // ✅ SOLUCIÓN: Parsear minQuantity como double (consistente con entidad)
// //       minQuantity: _parseDouble(json['minQuantity']),
// //       profitMargin:
// //           json['profitMargin'] != null
// //               ? _parseDouble(json['profitMargin'])
// //               : null,
// //       notes: json['notes'] as String?,
// //       productId: json['productId'] as String,
// //       createdAt: DateTime.parse(json['createdAt'] as String),
// //       updatedAt: DateTime.parse(json['updatedAt'] as String),
// //     );
// //   }

// //   // ✅ FUNCIÓN HELPER: Parsear double de forma segura
// //   static double _parseDouble(dynamic value) {
// //     if (value == null) return 0.0;
// //     if (value is double) return value;
// //     if (value is int) return value.toDouble();
// //     if (value is String) {
// //       return double.tryParse(value) ?? 0.0;
// //     }
// //     return 0.0;
// //   }

// //   Map<String, dynamic> toJson() {
// //     return {
// //       'id': id,
// //       'type': type,
// //       'name': name,
// //       'amount': amount,
// //       'currency': currency,
// //       'status': status,
// //       'validFrom': validFrom?.toIso8601String(),
// //       'validTo': validTo?.toIso8601String(),
// //       'discountPercentage': discountPercentage,
// //       'discountAmount': discountAmount,
// //       'minQuantity': minQuantity,
// //       'profitMargin': profitMargin,
// //       'notes': notes,
// //       'productId': productId,
// //       'createdAt': createdAt.toIso8601String(),
// //       'updatedAt': updatedAt.toIso8601String(),
// //     };
// //   }

// //   // Conversión a entidad del dominio
// //   ProductPrice toEntity() {
// //     return ProductPrice(
// //       id: id,
// //       type: _mapStringToPriceType(type),
// //       name: name,
// //       amount: amount,
// //       currency: currency,
// //       status: _mapStringToPriceStatus(status),
// //       validFrom: validFrom,
// //       validTo: validTo,
// //       discountPercentage: discountPercentage,
// //       discountAmount: discountAmount,
// //       minQuantity: minQuantity, // ✅ Ahora ambos son double, no hay conflicto
// //       profitMargin: profitMargin,
// //       notes: notes,
// //       productId: productId,
// //       createdAt: createdAt,
// //       updatedAt: updatedAt,
// //     );
// //   }

// //   // Crear modelo desde entidad
// //   factory ProductPriceModel.fromEntity(ProductPrice price) {
// //     return ProductPriceModel(
// //       id: price.id,
// //       type: price.type.name,
// //       name: price.name,
// //       amount: price.amount,
// //       currency: price.currency,
// //       status: price.status.name,
// //       validFrom: price.validFrom,
// //       validTo: price.validTo,
// //       discountPercentage: price.discountPercentage,
// //       discountAmount: price.discountAmount,
// //       minQuantity:
// //           price.minQuantity, // ✅ Ahora ambos son double, no hay conflicto
// //       profitMargin: price.profitMargin,
// //       notes: price.notes,
// //       productId: price.productId,
// //       createdAt: price.createdAt,
// //       updatedAt: price.updatedAt,
// //     );
// //   }

// //   // Mappers privados
// //   PriceType _mapStringToPriceType(String type) {
// //     switch (type.toLowerCase()) {
// //       case 'price1':
// //         return PriceType.price1;
// //       case 'price2':
// //         return PriceType.price2;
// //       case 'price3':
// //         return PriceType.price3;
// //       case 'special':
// //         return PriceType.special;
// //       case 'cost':
// //         return PriceType.cost;
// //       default:
// //         return PriceType.price1;
// //     }
// //   }

// //   PriceStatus _mapStringToPriceStatus(String status) {
// //     switch (status.toLowerCase()) {
// //       case 'active':
// //         return PriceStatus.active;
// //       case 'inactive':
// //         return PriceStatus.inactive;
// //       default:
// //         return PriceStatus.active;
// //     }
// //   }
// // }

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
//   final double minQuantity;
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
//     try {
//       print('🔍 ProductPriceModel.fromJson: Procesando precio ${json['id']}');

//       return ProductPriceModel(
//         id: json['id'] as String,
//         type: json['type'] as String,
//         // ✅ CORRECCIÓN: Manejo seguro de campos nullable
//         name: json['name'] as String?,
//         // ✅ CORRECCIÓN: Usar helper para parsear doubles de forma segura
//         amount: _parseDouble(json['amount']),
//         currency: json['currency'] as String,
//         status: json['status'] as String,
//         // ✅ CORRECCIÓN: Manejo seguro de fechas que pueden ser null
//         validFrom:
//             json['validFrom'] != null
//                 ? DateTime.parse(json['validFrom'] as String)
//                 : null,
//         validTo:
//             json['validTo'] != null
//                 ? DateTime.parse(json['validTo'] as String)
//                 : null,
//         discountPercentage: _parseDouble(json['discountPercentage']),
//         discountAmount:
//             json['discountAmount'] != null
//                 ? _parseDouble(json['discountAmount'])
//                 : null,
//         // ✅ CORRECCIÓN: Parsear minQuantity como double (consistente con entidad)
//         minQuantity: _parseDouble(json['minQuantity']),
//         profitMargin:
//             json['profitMargin'] != null
//                 ? _parseDouble(json['profitMargin'])
//                 : null,
//         notes: json['notes'] as String?,
//         // ✅ CORRECCIÓN: Manejar productId que puede venir en el contexto
//         productId: json['productId'] as String? ?? '',
//         // ✅ CORRECCIÓN: Manejo seguro de fechas con fallback
//         createdAt:
//             json['createdAt'] != null
//                 ? DateTime.parse(json['createdAt'] as String)
//                 : DateTime.now(),
//         updatedAt:
//             json['updatedAt'] != null
//                 ? DateTime.parse(json['updatedAt'] as String)
//                 : DateTime.now(),
//       );
//     } catch (e, stackTrace) {
//       print('❌ Error en ProductPriceModel.fromJson: $e');
//       print('📋 JSON problemático: $json');
//       print('🔍 StackTrace: $stackTrace');
//       rethrow;
//     }
//   }

//   // ✅ FUNCIÓN HELPER: Parsear double de forma segura
//   static double _parseDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       // Manejar números con formato "3900.00" que vienen como string
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
  final String type; // ✅ CORRECCIÓN: Cambié de PriceType a String
  final String? name;
  final double amount;
  final String currency;
  final String status; // ✅ CORRECCIÓN: Cambié de PriceStatus a String
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
        id: json['id'] as String? ?? '',
        // ✅ CORRECCIÓN CRÍTICA: Guardar type como string para evitar problemas con enum
        type: json['type'] as String? ?? 'price1',
        // ✅ CORRECCIÓN: Manejo seguro de campos nullable
        name: json['name'] as String?,
        // ✅ CORRECCIÓN: Usar helper para parsear doubles de forma segura
        amount: _parseDouble(json['amount']),
        currency: json['currency'] as String? ?? 'COP',
        status: json['status'] as String? ?? 'active',
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

      // ✅ AÑADIDO: Retornar objeto por defecto en caso de error crítico
      return ProductPriceModel(
        id:
            json['id'] as String? ??
            'error-${DateTime.now().millisecondsSinceEpoch}',
        type: 'price1',
        name: 'Error al cargar precio',
        amount: 0.0,
        currency: 'COP',
        status: 'inactive',
        validFrom: null,
        validTo: null,
        discountPercentage: 0.0,
        discountAmount: null,
        minQuantity: 1.0,
        profitMargin: null,
        notes: 'Error al procesar datos del precio',
        productId: json['productId'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
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

  // ✅ MÉTODO MEJORADO: Conversión a entidad del dominio
  ProductPrice toEntity() {
    try {
      return ProductPrice(
        id: id,
        type: _mapStringToPriceType(type), // Aquí sí convertir a enum
        name: name,
        amount: amount,
        currency: currency,
        status: _mapStringToPriceStatus(status), // Aquí sí convertir a enum
        validFrom: validFrom,
        validTo: validTo,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        minQuantity: minQuantity,
        profitMargin: profitMargin,
        notes: notes,
        productId: productId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('❌ Error al convertir ProductPriceModel a entidad: $e');

      // Retornar entidad por defecto en caso de error
      return ProductPrice(
        id: id,
        type: PriceType.price1,
        name: name,
        amount: amount,
        currency: currency,
        status: PriceStatus.active,
        validFrom: validFrom,
        validTo: validTo,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        minQuantity: minQuantity,
        profitMargin: profitMargin,
        notes: notes,
        productId: productId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }
  }

  // ✅ MÉTODO MEJORADO: Conversión desde entidad
  factory ProductPriceModel.fromEntity(ProductPrice price) {
    try {
      return ProductPriceModel(
        id: price.id,
        type: _mapPriceTypeToString(price.type), // ✅ Usar método helper
        name: price.name,
        amount: price.amount,
        currency: price.currency,
        status: _mapPriceStatusToString(price.status), // ✅ Usar método helper
        validFrom: price.validFrom,
        validTo: price.validTo,
        discountPercentage: price.discountPercentage,
        discountAmount: price.discountAmount,
        minQuantity: price.minQuantity,
        profitMargin: price.profitMargin,
        notes: price.notes,
        productId: price.productId,
        createdAt: price.createdAt,
        updatedAt: price.updatedAt,
      );
    } catch (e) {
      print('❌ Error al convertir ProductPrice a modelo: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS HELPER MEJORADOS ====================

  /// ✅ MÉTODO HELPER: Convertir string a PriceType enum
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
        print(
          '⚠️ Tipo de precio desconocido: $type, usando price1 por defecto',
        );
        return PriceType.price1;
    }
  }

  /// ✅ MÉTODO HELPER: Convertir string a PriceStatus enum
  PriceStatus _mapStringToPriceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PriceStatus.active;
      case 'inactive':
        return PriceStatus.inactive;
      default:
        print(
          '⚠️ Estado de precio desconocido: $status, usando active por defecto',
        );
        return PriceStatus.active;
    }
  }

  /// ✅ MÉTODO HELPER ESTÁTICO: Convertir PriceType enum a string
  static String _mapPriceTypeToString(PriceType type) {
    switch (type) {
      case PriceType.price1:
        return 'price1';
      case PriceType.price2:
        return 'price2';
      case PriceType.price3:
        return 'price3';
      case PriceType.special:
        return 'special';
      case PriceType.cost:
        return 'cost';
    }
  }

  /// ✅ MÉTODO HELPER ESTÁTICO: Convertir PriceStatus enum a string
  static String _mapPriceStatusToString(PriceStatus status) {
    switch (status) {
      case PriceStatus.active:
        return 'active';
      case PriceStatus.inactive:
        return 'inactive';
    }
  }

  // ==================== MÉTODOS ÚTILES ADICIONALES ====================

  /// ✅ MÉTODO HELPER: Verificar si el precio tiene descuento
  bool get hasDiscount {
    try {
      return (discountPercentage > 0) ||
          (discountAmount != null && discountAmount! > 0);
    } catch (e) {
      print('❌ Error al verificar descuento: $e');
      return false;
    }
  }

  /// ✅ MÉTODO HELPER: Calcular precio final con descuentos
  double get finalAmount {
    try {
      double finalPrice = amount;

      // Aplicar descuento por cantidad si existe
      if (discountAmount != null && discountAmount! > 0) {
        finalPrice = amount - discountAmount!;
      }
      // Si no hay descuento por cantidad, aplicar descuento por porcentaje
      else if (discountPercentage > 0) {
        finalPrice = amount * (1 - (discountPercentage / 100));
      }

      // Asegurar que el precio final no sea negativo
      return finalPrice < 0 ? 0.0 : finalPrice;
    } catch (e) {
      print('❌ Error al calcular precio final: $e');
      return amount;
    }
  }

  /// ✅ MÉTODO HELPER: Verificar si el precio está activo
  bool get isActive {
    try {
      if (status.toLowerCase() != 'active') return false;

      final now = DateTime.now();

      // Verificar fecha de inicio
      if (validFrom != null && now.isBefore(validFrom!)) return false;

      // Verificar fecha de fin
      if (validTo != null && now.isAfter(validTo!)) return false;

      return true;
    } catch (e) {
      print('❌ Error al verificar si el precio está activo: $e');
      return false;
    }
  }

  /// ✅ MÉTODO HELPER: Obtener nombre descriptivo del tipo de precio
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'price1':
        return 'Precio al Público';
      case 'price2':
        return 'Precio Mayorista';
      case 'price3':
        return 'Precio Distribuidor';
      case 'special':
        return 'Precio Especial';
      case 'cost':
        return 'Precio de Costo';
      default:
        return type.toUpperCase();
    }
  }

  /// ✅ MÉTODO HELPER: Formatear precio con moneda
  String get formattedAmount {
    try {
      return '${currency} ${finalAmount.toStringAsFixed(2)}';
    } catch (e) {
      print('❌ Error al formatear precio: $e');
      return '${currency} 0.00';
    }
  }

  /// ✅ MÉTODO HELPER: Crear copia con modificaciones
  ProductPriceModel copyWith({
    String? id,
    String? type,
    String? name,
    double? amount,
    String? currency,
    String? status,
    DateTime? validFrom,
    DateTime? validTo,
    double? discountPercentage,
    double? discountAmount,
    double? minQuantity,
    double? profitMargin,
    String? notes,
    String? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPriceModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      minQuantity: minQuantity ?? this.minQuantity,
      profitMargin: profitMargin ?? this.profitMargin,
      notes: notes ?? this.notes,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ MÉTODO HELPER: Comparar igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductPriceModel &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.status == status &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        amount.hashCode ^
        status.hashCode ^
        productId.hashCode;
  }

  /// ✅ MÉTODO HELPER: Representación en string para debug
  @override
  String toString() {
    return 'ProductPriceModel{id: $id, type: $type, amount: $amount, currency: $currency, status: $status, productId: $productId}';
  }
}
