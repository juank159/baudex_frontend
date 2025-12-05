// lib/features/invoices/presentation/models/invoice_form_models.dart

/// Modelo para manejar los datos del formulario de items de factura
class InvoiceItemFormData {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;
  final String? productId;
  final double taxPercentage; // ✅ IVA individual del item basado en el producto

  const InvoiceItemFormData({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.productId,
    this.taxPercentage = 0, // ✅ Por defecto 0 (NO_GRAVADO)
  });

  /// Calcular subtotal CON IVA (precio de venta al público)
  double get subtotal {
    final baseAmount = quantity * unitPrice; // El precio ya tiene IVA
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    return baseAmount - totalDiscount;
  }

  /// ✅ Calcular subtotal SIN IVA (base gravable)
  double get subtotalWithoutTax {
    if (taxPercentage <= 0) {
      // ✅ Si NO hay IVA (NO_GRAVADO), el precio ES la base
      final baseAmount = quantity * unitPrice;
      final percentageDiscount = (baseAmount * discountPercentage) / 100;
      final totalDiscount = percentageDiscount + discountAmount;
      return baseAmount - totalDiscount;
    }
    // ✅ Si hay IVA, extraer la base del precio
    final priceWithoutTax = unitPrice / (1 + (taxPercentage / 100));
    final baseAmount = quantity * priceWithoutTax;
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    return baseAmount - totalDiscount;
  }

  /// ✅ Calcular el monto del IVA para este item
  double get taxAmount {
    if (taxPercentage <= 0) return 0;
    return subtotalWithoutTax * (taxPercentage / 100);
  }

  /// ✅ Obtener precio unitario sin IVA
  double get unitPriceWithoutTax {
    if (taxPercentage <= 0) return unitPrice;
    return unitPrice / (1 + (taxPercentage / 100));
  }

  /// Validar que los datos sean válidos
  bool get isValid {
    return description.isNotEmpty &&
        quantity > 0 &&
        unitPrice >= 0 &&
        discountPercentage >= 0 &&
        discountPercentage <= 100 &&
        discountAmount >= 0;
  }

  /// Crear copia con nuevos valores
  InvoiceItemFormData copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    String? unit,
    String? notes,
    String? productId,
    double? taxPercentage,
  }) {
    return InvoiceItemFormData(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      productId: productId ?? this.productId,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }

  /// Crear desde entidad del dominio
  factory InvoiceItemFormData.fromEntity(dynamic item) {
    return InvoiceItemFormData(
      id: item.id ?? '',
      description: item.description ?? '',
      quantity: item.quantity?.toDouble() ?? 1.0,
      unitPrice: item.unitPrice?.toDouble() ?? 0.0,
      discountPercentage: item.discountPercentage?.toDouble() ?? 0.0,
      discountAmount: item.discountAmount?.toDouble() ?? 0.0,
      unit: item.unit,
      notes: item.notes,
      productId: item.productId,
      taxPercentage: item.taxPercentage?.toDouble() ?? 0.0,
    );
  }

  /// Crear item vacío
  factory InvoiceItemFormData.empty() {
    return const InvoiceItemFormData(
      id: '',
      description: '',
      quantity: 1,
      unitPrice: 0,
      unit: 'pcs',
    );
  }

  @override
  String toString() {
    return 'InvoiceItemFormData(description: $description, quantity: $quantity, unitPrice: $unitPrice, subtotal: ${subtotal.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItemFormData &&
        other.id == id &&
        other.description == description &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.discountPercentage == discountPercentage &&
        other.discountAmount == discountAmount &&
        other.unit == unit &&
        other.notes == notes &&
        other.productId == productId &&
        other.taxPercentage == taxPercentage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      description,
      quantity,
      unitPrice,
      discountPercentage,
      discountAmount,
      unit,
      notes,
      productId,
      taxPercentage,
    );
  }
}

/// Datos del formulario de factura para validaciones y estado
class InvoiceFormData {
  final String? number;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String paymentMethod;
  final String? customerId;
  final List<InvoiceItemFormData> items;
  final double taxPercentage;
  final double discountPercentage;
  final double discountAmount;
  final String? notes;
  final String? terms;

  const InvoiceFormData({
    this.number,
    required this.invoiceDate,
    required this.dueDate,
    required this.paymentMethod,
    this.customerId,
    required this.items,
    this.taxPercentage = 19,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.notes,
    this.terms,
  });

  /// ✅ Calcular subtotal SIN IVA de todos los items (base gravable)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotalWithoutTax);
  }

  /// Calcular descuento total
  double get totalDiscount {
    final percentageDiscount = (subtotal * discountPercentage) / 100;
    return percentageDiscount + discountAmount;
  }

  /// ✅ Calcular impuestos sumando el IVA de cada item
  double get taxAmount {
    // Calcular el IVA proporcional al descuento
    final baseSubtotal = items.fold(0.0, (sum, item) => sum + item.subtotalWithoutTax);
    if (baseSubtotal <= 0) return 0;

    final subtotalAfterDiscount = baseSubtotal - totalDiscount;
    final discountRatio = subtotalAfterDiscount / baseSubtotal;

    // Sumar el IVA de cada item, ajustado por el descuento
    return items.fold(0.0, (sum, item) => sum + (item.taxAmount * discountRatio));
  }

  /// ✅ Calcular IVA promedio ponderado (para mostrar)
  double get calculatedTaxPercentage {
    final subtotalAfterDiscount = subtotal - totalDiscount;
    if (subtotalAfterDiscount <= 0) return 0;
    return (taxAmount / subtotalAfterDiscount) * 100;
  }

  /// Calcular total final
  double get total {
    return subtotal - totalDiscount + taxAmount;
  }

  /// Validar que todos los datos sean válidos
  bool get isValid {
    return customerId?.isNotEmpty == true &&
        items.isNotEmpty &&
        items.every((item) => item.isValid) &&
        taxPercentage >= 0 &&
        discountPercentage >= 0 &&
        discountAmount >= 0;
  }

  /// Obtener lista de errores de validación
  List<String> get validationErrors {
    final errors = <String>[];

    if (customerId?.isEmpty ?? true) {
      errors.add('Debe seleccionar un cliente');
    }

    if (items.isEmpty) {
      errors.add('Debe agregar al menos un item');
    }

    for (int i = 0; i < items.length; i++) {
      if (!items[i].isValid) {
        errors.add('Item ${i + 1} tiene datos inválidos');
      }
    }

    if (taxPercentage < 0) {
      errors.add('El porcentaje de impuesto no puede ser negativo');
    }

    if (discountPercentage < 0 || discountPercentage > 100) {
      errors.add('El porcentaje de descuento debe estar entre 0 y 100');
    }

    if (discountAmount < 0) {
      errors.add('El monto de descuento no puede ser negativo');
    }

    return errors;
  }

  @override
  String toString() {
    return 'InvoiceFormData(items: ${items.length}, total: ${total.toStringAsFixed(2)}, isValid: $isValid)';
  }
}
