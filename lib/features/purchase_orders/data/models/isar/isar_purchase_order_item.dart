// lib/features/purchase_orders/data/models/isar/isar_purchase_order_item.dart
import 'package:baudex_desktop/features/purchase_orders/domain/entities/purchase_order.dart';
import 'package:isar/isar.dart';

part 'isar_purchase_order_item.g.dart';

@collection
class IsarPurchaseOrderItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;

  @Index()
  String? purchaseOrderServerId; // FK to PurchaseOrder

  late String productId;
  late String productName;
  String? productCode;
  String? productDescription;
  late String unit;
  late int quantity;
  int? receivedQuantity;
  int? damagedQuantity;
  int? missingQuantity;
  late double unitPrice;
  late double discountPercentage;
  late double discountAmount;
  late double subtotal;
  late double taxPercentage;
  late double taxAmount;
  late double totalAmount;
  String? notes;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Constructor vacío requerido por Isar
  IsarPurchaseOrderItem();

  IsarPurchaseOrderItem.create({
    required this.itemId,
    this.purchaseOrderServerId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.productDescription,
    required this.unit,
    required this.quantity,
    this.receivedQuantity,
    this.damagedQuantity,
    this.missingQuantity,
    required this.unitPrice,
    required this.discountPercentage,
    required this.discountAmount,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static IsarPurchaseOrderItem fromEntity(PurchaseOrderItem entity) {
    return IsarPurchaseOrderItem.create(
      itemId: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productCode: entity.productCode,
      productDescription: entity.productDescription,
      unit: entity.unit,
      quantity: entity.quantity,
      receivedQuantity: entity.receivedQuantity,
      damagedQuantity: entity.damagedQuantity,
      missingQuantity: entity.missingQuantity,
      unitPrice: entity.unitPrice,
      discountPercentage: entity.discountPercentage,
      discountAmount: entity.discountAmount,
      subtotal: entity.subtotal,
      taxPercentage: entity.taxPercentage,
      taxAmount: entity.taxAmount,
      totalAmount: entity.totalAmount,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PurchaseOrderItem toEntity() {
    return PurchaseOrderItem(
      id: itemId,
      productId: productId,
      productName: productName,
      productCode: productCode,
      productDescription: productDescription,
      unit: unit,
      quantity: quantity,
      receivedQuantity: receivedQuantity,
      damagedQuantity: damagedQuantity,
      missingQuantity: missingQuantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'IsarPurchaseOrderItem{itemId: $itemId, productName: $productName, quantity: $quantity}';
  }
}
