// // lib/features/invoices/data/models/invoice_item_model.dart
// import 'package:baudex_desktop/features/products/domain/entities/product.dart';

// import '../../domain/entities/invoice_item.dart';
// import '../../domain/repositories/invoice_repository.dart';
// import '../../../products/data/models/product_model.dart';

// class InvoiceItemModel extends InvoiceItem {
//   const InvoiceItemModel({
//     required super.id,
//     required super.description,
//     required super.quantity,
//     required super.unitPrice,
//     required super.discountPercentage,
//     required super.discountAmount,
//     required super.subtotal,
//     super.unit,
//     super.notes,
//     required super.invoiceId,
//     super.productId,
//     super.product,
//     required super.createdAt,
//     required super.updatedAt,
//   });

//   factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
//     return InvoiceItemModel(
//       id: json['id'] as String,
//       description: json['description'] as String,
//       quantity: (json['quantity'] as num).toDouble(),
//       unitPrice: (json['unitPrice'] as num).toDouble(),
//       discountPercentage: (json['discountPercentage'] as num).toDouble(),
//       discountAmount: (json['discountAmount'] as num).toDouble(),
//       subtotal: (json['subtotal'] as num).toDouble(),
//       unit: json['unit'] as String?,
//       notes: json['notes'] as String?,
//       invoiceId: json['invoiceId'] as String,
//       productId: json['productId'] as String?,
//       product:
//           json['product'] != null
//               ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
//                   as Product
//               : null,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'description': description,
//       'quantity': quantity,
//       'unitPrice': unitPrice,
//       'discountPercentage': discountPercentage,
//       'discountAmount': discountAmount,
//       'subtotal': subtotal,
//       if (unit != null) 'unit': unit,
//       if (notes != null) 'notes': notes,
//       'invoiceId': invoiceId,
//       if (productId != null) 'productId': productId,
//       if (product != null) 'product': (product as ProductModel).toJson(),
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   factory InvoiceItemModel.fromEntity(InvoiceItem item) {
//     return InvoiceItemModel(
//       id: item.id,
//       description: item.description,
//       quantity: item.quantity,
//       unitPrice: item.unitPrice,
//       discountPercentage: item.discountPercentage,
//       discountAmount: item.discountAmount,
//       subtotal: item.subtotal,
//       unit: item.unit,
//       notes: item.notes,
//       invoiceId: item.invoiceId,
//       productId: item.productId,
//       product: item.product,
//       createdAt: item.createdAt,
//       updatedAt: item.updatedAt,
//     );
//   }
// }

// // ==================== CREATE INVOICE ITEM REQUEST MODEL ====================

// class CreateInvoiceItemRequestModel {
//   final String description;
//   final double quantity;
//   final double unitPrice;
//   final double discountPercentage;
//   final double discountAmount;
//   final String? unit;
//   final String? notes;
//   final String? productId;

//   const CreateInvoiceItemRequestModel({
//     required this.description,
//     required this.quantity,
//     required this.unitPrice,
//     this.discountPercentage = 0,
//     this.discountAmount = 0,
//     this.unit,
//     this.notes,
//     this.productId,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'description': description,
//       'quantity': quantity,
//       'unitPrice': unitPrice,
//       'discountPercentage': discountPercentage,
//       'discountAmount': discountAmount,
//       if (unit != null) 'unit': unit,
//       if (notes != null) 'notes': notes,
//       if (productId != null) 'productId': productId,
//     };
//   }

//   factory CreateInvoiceItemRequestModel.fromEntity(
//     CreateInvoiceItemParams params,
//   ) {
//     return CreateInvoiceItemRequestModel(
//       description: params.description,
//       quantity: params.quantity,
//       unitPrice: params.unitPrice,
//       discountPercentage: params.discountPercentage,
//       discountAmount: params.discountAmount,
//       unit: params.unit,
//       notes: params.notes,
//       productId: params.productId,
//     );
//   }

//   /// Validar que el item sea válido
//   bool get isValid {
//     return description.isNotEmpty &&
//         quantity > 0 &&
//         unitPrice >= 0 &&
//         discountPercentage >= 0 &&
//         discountPercentage <= 100 &&
//         discountAmount >= 0;
//   }

//   /// Calcular el subtotal estimado
//   double get estimatedSubtotal {
//     final baseAmount = quantity * unitPrice;
//     final percentageDiscount = (baseAmount * discountPercentage) / 100;
//     final totalDiscount = percentageDiscount + discountAmount;
//     return baseAmount - totalDiscount;
//   }

//   /// Crear una copia con nuevos valores
//   CreateInvoiceItemRequestModel copyWith({
//     String? description,
//     double? quantity,
//     double? unitPrice,
//     double? discountPercentage,
//     double? discountAmount,
//     String? unit,
//     String? notes,
//     String? productId,
//   }) {
//     return CreateInvoiceItemRequestModel(
//       description: description ?? this.description,
//       quantity: quantity ?? this.quantity,
//       unitPrice: unitPrice ?? this.unitPrice,
//       discountPercentage: discountPercentage ?? this.discountPercentage,
//       discountAmount: discountAmount ?? this.discountAmount,
//       unit: unit ?? this.unit,
//       notes: notes ?? this.notes,
//       productId: productId ?? this.productId,
//     );
//   }

//   @override
//   String toString() {
//     return 'CreateInvoiceItemRequestModel(description: $description, quantity: $quantity, unitPrice: $unitPrice, subtotal: ${estimatedSubtotal.toStringAsFixed(2)})';
//   }
// }

// lib/features/invoices/data/models/invoice_item_model.dart
import 'package:baudex_desktop/features/products/domain/entities/product.dart';

import '../../domain/entities/invoice_item.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../../products/data/models/product_model.dart';

class InvoiceItemModel extends InvoiceItem {
  const InvoiceItemModel({
    required super.id,
    required super.description,
    required super.quantity,
    required super.unitPrice,
    required super.discountPercentage,
    required super.discountAmount,
    required super.subtotal,
    super.unit,
    super.notes,
    required super.invoiceId,
    super.productId,
    super.product,
    required super.createdAt,
    required super.updatedAt,
  });

  /// ✅ MÉTODO HELPER ROBUSTO PARA CONVERTIR CUALQUIER VALOR A DOUBLE
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;

    // Si ya es un número, convertir directamente
    if (value is num) return value.toDouble();

    // Si es string, limpiar y convertir
    if (value is String) {
      // Remover espacios en blanco
      String cleanedValue = value.trim();

      // Si está vacío después de limpiar, retornar 0
      if (cleanedValue.isEmpty) return 0.0;

      // Remover ceros innecesarios al inicio (ej: "0195000.00" -> "195000.00")
      cleanedValue = cleanedValue.replaceFirst(RegExp(r'^0+(?=\d)'), '');

      // Si quedó vacío, significa que era solo "0" o "00", etc.
      if (cleanedValue.isEmpty) return 0.0;

      // Intentar parsear
      final parsed = double.tryParse(cleanedValue);
      if (parsed != null) return parsed;

      // Si no se pudo parsear, intentar como int y luego convertir
      final parsedInt = int.tryParse(cleanedValue);
      if (parsedInt != null) return parsedInt.toDouble();
    }

    // Si todo falla, retornar 0
    print(
      '⚠️ No se pudo convertir a double en InvoiceItem: $value (${value.runtimeType})',
    );
    return 0.0;
  }

  /// ✅ MÉTODO HELPER PARA FECHAS
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Error parsing date in InvoiceItem: $value - $e');
        return DateTime.now();
      }
    }

    if (value is DateTime) return value;

    return DateTime.now();
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    print('🔍 InvoiceItemModel.fromJson: Procesando item ${json['id']}');

    try {
      return InvoiceItemModel(
        id: json['id']?.toString() ?? '',
        description: json['description']?.toString() ?? '',

        // ✅ USAR EL MÉTODO HELPER ROBUSTO PARA TODOS LOS CAMPOS NUMÉRICOS
        quantity: _parseToDouble(json['quantity']),
        unitPrice: _parseToDouble(json['unitPrice']),
        discountPercentage: _parseToDouble(json['discountPercentage']),
        discountAmount: _parseToDouble(json['discountAmount']),
        subtotal: _parseToDouble(json['subtotal']),

        // Campos opcionales
        unit: json['unit']?.toString(),
        notes: json['notes']?.toString(),

        // IDs y relaciones
        invoiceId: json['invoiceId']?.toString() ?? '',
        productId: json['productId']?.toString(),
        product:
            json['product'] != null
                ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
                    as Product
                : null,

        // Timestamps
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('❌ Error en InvoiceItemModel.fromJson: $e');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'subtotal': subtotal,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
      'invoiceId': invoiceId,
      if (productId != null) 'productId': productId,
      if (product != null) 'product': (product as ProductModel).toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceItemModel.fromEntity(InvoiceItem item) {
    return InvoiceItemModel(
      id: item.id,
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountPercentage: item.discountPercentage,
      discountAmount: item.discountAmount,
      subtotal: item.subtotal,
      unit: item.unit,
      notes: item.notes,
      invoiceId: item.invoiceId,
      productId: item.productId,
      product: item.product,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }
}

// ==================== CREATE INVOICE ITEM REQUEST MODEL ====================

class CreateInvoiceItemRequestModel {
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;
  final String? productId;

  const CreateInvoiceItemRequestModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
      if (productId != null) 'productId': productId,
    };
  }

  factory CreateInvoiceItemRequestModel.fromEntity(
    CreateInvoiceItemParams params,
  ) {
    return CreateInvoiceItemRequestModel(
      description: params.description,
      quantity: params.quantity,
      unitPrice: params.unitPrice,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      unit: params.unit,
      notes: params.notes,
      productId: params.productId,
    );
  }

  /// Validar que el item sea válido
  bool get isValid {
    return description.isNotEmpty &&
        quantity > 0 &&
        unitPrice >= 0 &&
        discountPercentage >= 0 &&
        discountPercentage <= 100 &&
        discountAmount >= 0;
  }

  /// Calcular el subtotal estimado
  double get estimatedSubtotal {
    final baseAmount = quantity * unitPrice;
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    return baseAmount - totalDiscount;
  }

  /// Crear una copia con nuevos valores
  CreateInvoiceItemRequestModel copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    String? unit,
    String? notes,
    String? productId,
  }) {
    return CreateInvoiceItemRequestModel(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      productId: productId ?? this.productId,
    );
  }

  @override
  String toString() {
    return 'CreateInvoiceItemRequestModel(description: $description, quantity: $quantity, unitPrice: $unitPrice, subtotal: ${estimatedSubtotal.toStringAsFixed(2)})';
  }
}
