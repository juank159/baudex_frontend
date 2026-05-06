// lib/features/invoices/data/models/invoice_item_model.dart

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
                ? ProductModel.fromJson(
                  json['product'] as Map<String, dynamic>,
                ).toEntity()
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
      if (product != null)
        'product': ProductModel.fromEntity(product!).toJson(),
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
  // ✅ NUEVOS CAMPOS PARA PRODUCTOS TEMPORALES
  final bool? isTemporary;
  final String? category;
  // Presentación de venta (Fase 3, opcional). Si viene, el backend
  // descuenta quantity × factor del stock vía FIFO.
  final String? presentationId;

  const CreateInvoiceItemRequestModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.productId,
    this.isTemporary,
    this.category,
    this.presentationId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
    };

    // Campos opcionales básicos
    if (unit != null) json['unit'] = unit;
    if (notes != null) json['notes'] = notes;

    // ✅ LÓGICA PARA PRODUCTOS TEMPORALES VS REGISTRADOS
    if (isTemporary == true) {
      // Para productos temporales
      json['isTemporary'] = true;
      if (category != null) json['category'] = category;
      // ❌ NO enviar productId para productos temporales
      print('📦 Enviando producto temporal: $description');
    } else if (productId != null) {
      // Para productos registrados
      json['productId'] = productId;
      // ❌ NO enviar isTemporary para productos registrados
      print('📦 Enviando producto registrado: $description (ID: $productId)');
    }

    // Presentación (Fase 3) — solo aplica a productos registrados
    if (presentationId != null && isTemporary != true) {
      json['presentationId'] = presentationId;
    }

    print('📋 JSON generado para item: $json');
    return json;
  }

  // ✅ MÉTODO fromEntity ACTUALIZADO - AQUÍ ESTÁ LA SOLUCIÓN PRINCIPAL
  // factory CreateInvoiceItemRequestModel.fromEntity(
  //   CreateInvoiceItemParams params,
  // ) {
  //   print('🔄 CreateInvoiceItemRequestModel.fromEntity: ${params.description}');
  //   print('   - productId: ${params.productId}');

  //   // ✅ DETECTAR SI ES UN PRODUCTO TEMPORAL
  //   bool isTemporary = false;
  //   String? category;

  //   if (params.productId != null) {
  //     // Verificar si el productId indica un producto temporal
  //     if (params.productId!.startsWith('temp_') ||
  //         params.productId!.startsWith('unregistered_')) {
  //       isTemporary = true;
  //       category = 'Sin categoría';
  //       print('✅ Detectado producto temporal por ID: ${params.productId}');
  //     }
  //   }

  //   return CreateInvoiceItemRequestModel(
  //     description: params.description,
  //     quantity: params.quantity,
  //     unitPrice: params.unitPrice,
  //     discountPercentage: params.discountPercentage,
  //     discountAmount: params.discountAmount,
  //     unit: params.unit,
  //     notes: params.notes,
  //     // ✅ SOLO enviar productId si NO es temporal
  //     productId: isTemporary ? null : params.productId,
  //     // ✅ SOLO enviar isTemporary si ES temporal
  //     isTemporary: isTemporary ? true : null,
  //     category: category,
  //   );
  // }

  // ✅ MÉTODO fromEntity CORREGIDO en invoice_item_model.dart (Frontend)
  factory CreateInvoiceItemRequestModel.fromEntity(
    CreateInvoiceItemParams params,
  ) {
    print('🔄 CreateInvoiceItemRequestModel.fromEntity: ${params.description}');
    print('   - productId: ${params.productId}');

    // ✅ DETECCIÓN MEJORADA DE PRODUCTOS TEMPORALES
    bool isTemporary = false;
    String? category;

    if (params.productId != null) {
      // Verificar si el productId indica un producto temporal
      if (params.productId!.startsWith('temp_') ||
          params.productId!.startsWith('unregistered_') ||
          params.productId!.contains('temp') ||
          params.productId!.contains('temporal')) {
        isTemporary = true;
        category = 'Sin categoría';
        print('✅ Detectado producto temporal por ID: ${params.productId}');
      }
    }

    // ✅ TAMBIÉN DETECTAR POR DESCRIPCIÓN
    if (params.description.toLowerCase().contains('sin registrar') ||
        params.description.toLowerCase().contains('temporal') ||
        params.description.toLowerCase().contains('temp')) {
      isTemporary = true;
      category = 'Sin categoría';
      print(
        '✅ Detectado producto temporal por descripción: ${params.description}',
      );
    }

    return CreateInvoiceItemRequestModel(
      description: params.description,
      quantity: params.quantity,
      unitPrice: params.unitPrice,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      unit: params.unit,
      notes: params.notes,
      // ✅ LÓGICA CORREGIDA:
      productId:
          isTemporary
              ? null
              : params.productId, // NO enviar productId si es temporal
      isTemporary:
          isTemporary ? true : null, // SOLO enviar isTemporary si es temporal
      category: category,
      // Presentación de venta (Fase 3): backend descontará quantity × factor
      presentationId: isTemporary ? null : params.presentationId,
    );
  }

  /// Validar que el item sea válido
  bool get isValid {
    final basicValidation =
        description.isNotEmpty &&
        quantity > 0 &&
        unitPrice >= 0 &&
        discountPercentage >= 0 &&
        discountPercentage <= 100 &&
        discountAmount >= 0;

    // ✅ VALIDACIÓN ADICIONAL: debe tener productId O ser temporal
    final hasProductReference = productId != null || isTemporary == true;

    return basicValidation && hasProductReference;
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
    bool? isTemporary,
    String? category,
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
      isTemporary: isTemporary ?? this.isTemporary,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'CreateInvoiceItemRequestModel(description: $description, quantity: $quantity, unitPrice: $unitPrice, isTemporary: $isTemporary, subtotal: ${estimatedSubtotal.toStringAsFixed(2)})';
  }
}
