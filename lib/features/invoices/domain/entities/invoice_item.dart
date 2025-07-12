// lib/features/invoices/domain/entities/invoice_item.dart
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

class InvoiceItem extends Equatable {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final double subtotal;
  final String? unit;
  final String? notes;

  // Relaciones
  final String invoiceId;
  final String? productId;
  final Product? product;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercentage,
    required this.discountAmount,
    required this.subtotal,
    this.unit,
    this.notes,
    required this.invoiceId,
    this.productId,
    this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    quantity,
    unitPrice,
    discountPercentage,
    discountAmount,
    subtotal,
    unit,
    notes,
    invoiceId,
    productId,
    product,
    createdAt,
    updatedAt,
  ];

  // Getters útiles
  double get finalUnitPrice {
    if (quantity <= 0) return unitPrice;
    return unitPrice - (discountAmount / quantity);
  }

  double get totalDiscount {
    double percentageDiscount =
        (unitPrice * quantity * discountPercentage) / 100;
    return percentageDiscount + discountAmount;
  }

  double get baseAmount {
    return quantity * unitPrice;
  }

  double get finalSubtotal {
    return baseAmount - totalDiscount;
  }

  String get displayUnit => unit ?? 'pcs';

  // Product info helpers
  String? get productName => product?.name;
  String? get productSku => product?.sku;
  String? get productBarcode => product?.barcode;

  InvoiceItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    double? subtotal,
    String? unit,
    String? notes,
    String? invoiceId,
    String? productId,
    Product? product,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      subtotal: subtotal ?? this.subtotal,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InvoiceItem.empty() {
    return InvoiceItem(
      id: '',
      description: '',
      quantity: 1,
      unitPrice: 0,
      discountPercentage: 0,
      discountAmount: 0,
      subtotal: 0,
      invoiceId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory InvoiceItem.fromProduct({
    required Product product,
    required String invoiceId,
    double quantity = 1,
    double? customPrice,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
  }) {
    final unitPrice =
        customPrice ??
        (product.prices?.isNotEmpty == true
            ? product.prices!.first.amount
            : 0.0);

    final baseAmount = quantity * unitPrice;
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    final subtotal = baseAmount - totalDiscount;

    return InvoiceItem(
      id: '',
      description: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      unit: product.unit,
      notes: notes,
      invoiceId: invoiceId,
      productId: product.id,
      product: product,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Método para recalcular subtotal
  InvoiceItem recalculateSubtotal() {
    final baseAmount = quantity * unitPrice;
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    final newSubtotal = baseAmount - totalDiscount;

    return copyWith(subtotal: newSubtotal);
  }
}
