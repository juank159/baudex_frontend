// lib/features/credit_notes/domain/entities/credit_note_item.dart
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

class CreditNoteItem extends Equatable {
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
  final String creditNoteId;
  final String? productId;
  final Product? product;
  final String? invoiceItemId; // Referencia al item de factura original

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditNoteItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercentage,
    required this.discountAmount,
    required this.subtotal,
    this.unit,
    this.notes,
    required this.creditNoteId,
    this.productId,
    this.product,
    this.invoiceItemId,
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
        creditNoteId,
        productId,
        product,
        invoiceItemId,
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

  CreditNoteItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    double? subtotal,
    String? unit,
    String? notes,
    String? creditNoteId,
    String? productId,
    Product? product,
    String? invoiceItemId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditNoteItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      subtotal: subtotal ?? this.subtotal,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      creditNoteId: creditNoteId ?? this.creditNoteId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      invoiceItemId: invoiceItemId ?? this.invoiceItemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CreditNoteItem.empty() {
    return CreditNoteItem(
      id: '',
      description: '',
      quantity: 1,
      unitPrice: 0,
      discountPercentage: 0,
      discountAmount: 0,
      subtotal: 0,
      creditNoteId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory CreditNoteItem.fromProduct({
    required Product product,
    required String creditNoteId,
    double quantity = 1,
    double? customPrice,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
    String? invoiceItemId,
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

    return CreditNoteItem(
      id: '',
      description: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      unit: product.unit,
      notes: notes,
      creditNoteId: creditNoteId,
      productId: product.id,
      product: product,
      invoiceItemId: invoiceItemId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Método para recalcular subtotal
  CreditNoteItem recalculateSubtotal() {
    final baseAmount = quantity * unitPrice;
    final percentageDiscount = (baseAmount * discountPercentage) / 100;
    final totalDiscount = percentageDiscount + discountAmount;
    final newSubtotal = baseAmount - totalDiscount;

    return copyWith(subtotal: newSubtotal);
  }
}
