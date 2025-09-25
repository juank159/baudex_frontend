// lib/features/invoices/data/models/isar/isar_invoice_item.dart
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
// import 'package:isar/isar.dart';

// part 'isar_invoice_item.g.dart';

// @collection
class IsarInvoiceItem {
  // Id id = Isar.autoIncrement;
  int id = 0;

  // @Index(unique: true)
  late String serverId;

  late String description;
  late double quantity;
  late double unitPrice;
  late double discountPercentage;
  late double discountAmount;
  late double subtotal;

  String? unit;
  String? notes;

  // Foreign Keys
  // @Index()
  late String invoiceId;

  // @Index()
  String? productId; // Opcional - puede ser producto no registrado

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarInvoiceItem();

  IsarInvoiceItem.create({
    required this.serverId,
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
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarInvoiceItem fromEntity(InvoiceItem entity) {
    return IsarInvoiceItem.create(
      serverId: entity.id,
      description: entity.description,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      discountPercentage: entity.discountPercentage,
      discountAmount: entity.discountAmount,
      subtotal: entity.subtotal,
      unit: entity.unit,
      notes: entity.notes,
      invoiceId: entity.invoiceId,
      productId: entity.productId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  InvoiceItem toEntity() {
    return InvoiceItem(
      id: serverId,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      unit: unit,
      notes: notes,
      invoiceId: invoiceId,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Métodos de utilidad
  bool get needsSync => !isSynced;
  bool get hasProduct => productId != null && productId!.isNotEmpty;
  bool get hasDiscount => discountAmount > 0 || discountPercentage > 0;

  double get lineTotal {
    double total = quantity * unitPrice;

    if (discountAmount > 0) {
      total -= discountAmount;
    } else if (discountPercentage > 0) {
      total *= (1 - discountPercentage / 100);
    }

    return total.clamp(0, double.infinity);
  }

  double get totalDiscount {
    if (discountAmount > 0) return discountAmount;
    if (discountPercentage > 0) {
      return (quantity * unitPrice) * (discountPercentage / 100);
    }
    return 0;
  }

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void updateQuantity(double newQuantity) {
    quantity = newQuantity;
    subtotal = lineTotal;
    markAsUnsynced();
  }

  void updatePrice(double newPrice) {
    unitPrice = newPrice;
    subtotal = lineTotal;
    markAsUnsynced();
  }

  void applyDiscount({double? percentage, double? amount}) {
    if (amount != null) {
      discountAmount = amount;
      discountPercentage = 0;
    } else if (percentage != null) {
      discountPercentage = percentage;
      discountAmount = 0;
    }

    subtotal = lineTotal;
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarInvoiceItem{serverId: $serverId, description: $description, quantity: $quantity, unitPrice: $unitPrice, isSynced: $isSynced}';
  }
}
