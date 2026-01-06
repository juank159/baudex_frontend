// test/fixtures/purchase_order_fixtures.dart
import 'package:baudex_desktop/features/purchase_orders/domain/entities/purchase_order.dart';

class PurchaseOrderFixtures {
  // Create basic purchase order entity
  static PurchaseOrder createPurchaseOrderEntity({
    String id = 'po-001',
    String orderNumber = 'PO-2024-001',
    String supplierId = 'supplier-001',
    String supplierName = 'Test Supplier',
    PurchaseOrderStatus status = PurchaseOrderStatus.pending,
    PurchaseOrderPriority priority = PurchaseOrderPriority.medium,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    DateTime? deliveredDate,
    String currency = 'COP',
    double subtotal = 1000000.0,
    double taxAmount = 190000.0,
    double discountAmount = 0.0,
    double totalAmount = 1190000.0,
    List<PurchaseOrderItem>? items,
    String? notes,
    String? internalNotes,
    String? deliveryAddress,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    List<String>? attachments,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id,
      orderNumber: orderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      status: status,
      priority: priority,
      orderDate: orderDate ?? DateTime(2024, 1, 15),
      expectedDeliveryDate: expectedDeliveryDate ?? DateTime(2024, 1, 30),
      deliveredDate: deliveredDate,
      currency: currency,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      items: items ?? createPurchaseOrderItemList(2),
      notes: notes,
      internalNotes: internalNotes,
      deliveryAddress: deliveryAddress ?? '123 Main St, Bogota',
      contactPerson: contactPerson ?? 'John Doe',
      contactPhone: contactPhone ?? '+57 300 123 4567',
      contactEmail: contactEmail ?? 'john@supplier.com',
      attachments: attachments,
      createdBy: createdBy ?? 'user-001',
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt ?? DateTime(2024, 1, 15),
      updatedAt: updatedAt ?? DateTime(2024, 1, 15),
    );
  }

  // Create purchase order item
  static PurchaseOrderItem createPurchaseOrderItem({
    String id = 'item-001',
    String productId = 'prod-001',
    String productName = 'Test Product',
    String? productCode = 'SKU-001',
    String? productDescription = 'Test product description',
    String unit = 'unit',
    int quantity = 10,
    int? receivedQuantity,
    int? damagedQuantity,
    int? missingQuantity,
    double unitPrice = 100000.0,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double subtotal = 1000000.0,
    double taxPercentage = 19.0,
    double taxAmount = 190000.0,
    double totalAmount = 1190000.0,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderItem(
      id: id,
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
      createdAt: createdAt ?? DateTime(2024, 1, 15),
      updatedAt: updatedAt ?? DateTime(2024, 1, 15),
    );
  }

  // Create list of purchase order items
  static List<PurchaseOrderItem> createPurchaseOrderItemList(int count) {
    return List.generate(
      count,
      (index) => createPurchaseOrderItem(
        id: 'item-${(index + 1).toString().padLeft(3, '0')}',
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productCode: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
      ),
    );
  }

  // Create list of purchase orders
  static List<PurchaseOrder> createPurchaseOrderEntityList(int count) {
    return List.generate(
      count,
      (index) => createPurchaseOrderEntity(
        id: 'po-${(index + 1).toString().padLeft(3, '0')}',
        orderNumber: 'PO-2024-${(index + 1).toString().padLeft(3, '0')}',
        supplierId: 'supplier-${(index + 1).toString().padLeft(3, '0')}',
        supplierName: 'Supplier ${index + 1}',
      ),
    );
  }

  // Create draft purchase order
  static PurchaseOrder createDraftPurchaseOrder({String id = 'po-draft-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-DRAFT-001',
      status: PurchaseOrderStatus.draft,
      approvedBy: null,
      approvedAt: null,
    );
  }

  // Create pending purchase order
  static PurchaseOrder createPendingPurchaseOrder({String id = 'po-pending-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-PENDING-001',
      status: PurchaseOrderStatus.pending,
      approvedBy: null,
      approvedAt: null,
    );
  }

  // Create approved purchase order
  static PurchaseOrder createApprovedPurchaseOrder({String id = 'po-approved-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-APPROVED-001',
      status: PurchaseOrderStatus.approved,
      approvedBy: 'user-manager-001',
      approvedAt: DateTime(2024, 1, 16),
    );
  }

  // Create sent purchase order
  static PurchaseOrder createSentPurchaseOrder({String id = 'po-sent-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-SENT-001',
      status: PurchaseOrderStatus.sent,
      approvedBy: 'user-manager-001',
      approvedAt: DateTime(2024, 1, 16),
    );
  }

  // Create received purchase order
  static PurchaseOrder createReceivedPurchaseOrder({String id = 'po-received-001'}) {
    final items = createPurchaseOrderItemList(2).map((item) {
      return item.copyWith(receivedQuantity: item.quantity);
    }).toList();

    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-RECEIVED-001',
      status: PurchaseOrderStatus.received,
      items: items,
      deliveredDate: DateTime(2024, 1, 28),
      approvedBy: 'user-manager-001',
      approvedAt: DateTime(2024, 1, 16),
    );
  }

  // Create partially received purchase order
  static PurchaseOrder createPartiallyReceivedPurchaseOrder({String id = 'po-partial-001'}) {
    final items = createPurchaseOrderItemList(2);
    items[0] = items[0].copyWith(receivedQuantity: items[0].quantity);
    items[1] = items[1].copyWith(receivedQuantity: (items[1].quantity / 2).round());

    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-PARTIAL-001',
      status: PurchaseOrderStatus.partiallyReceived,
      items: items,
      approvedBy: 'user-manager-001',
      approvedAt: DateTime(2024, 1, 16),
    );
  }

  // Create cancelled purchase order
  static PurchaseOrder createCancelledPurchaseOrder({String id = 'po-cancelled-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-CANCELLED-001',
      status: PurchaseOrderStatus.cancelled,
    );
  }

  // Create rejected purchase order
  static PurchaseOrder createRejectedPurchaseOrder({String id = 'po-rejected-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-REJECTED-001',
      status: PurchaseOrderStatus.rejected,
    );
  }

  // Create overdue purchase order
  static PurchaseOrder createOverduePurchaseOrder({String id = 'po-overdue-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-OVERDUE-001',
      status: PurchaseOrderStatus.sent,
      expectedDeliveryDate: DateTime.now().subtract(const Duration(days: 5)),
      approvedBy: 'user-manager-001',
      approvedAt: DateTime.now().subtract(const Duration(days: 10)),
    );
  }

  // Create urgent purchase order
  static PurchaseOrder createUrgentPurchaseOrder({String id = 'po-urgent-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-URGENT-001',
      priority: PurchaseOrderPriority.urgent,
      expectedDeliveryDate: DateTime.now().add(const Duration(days: 2)),
    );
  }

  // Create high priority purchase order
  static PurchaseOrder createHighPriorityPurchaseOrder({String id = 'po-high-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-HIGH-001',
      priority: PurchaseOrderPriority.high,
    );
  }

  // Create low priority purchase order
  static PurchaseOrder createLowPriorityPurchaseOrder({String id = 'po-low-001'}) {
    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-LOW-001',
      priority: PurchaseOrderPriority.low,
    );
  }

  // Create purchase order with items that have damaged/missing quantities
  static PurchaseOrder createPurchaseOrderWithDamagedItems({String id = 'po-damaged-001'}) {
    final items = createPurchaseOrderItemList(2);
    items[0] = items[0].copyWith(
      receivedQuantity: 8,
      damagedQuantity: 2,
      missingQuantity: 0,
    );
    items[1] = items[1].copyWith(
      receivedQuantity: 7,
      damagedQuantity: 1,
      missingQuantity: 2,
    );

    return createPurchaseOrderEntity(
      id: id,
      orderNumber: 'PO-DAMAGED-001',
      status: PurchaseOrderStatus.partiallyReceived,
      items: items,
    );
  }

  // Create purchase order stats
  static PurchaseOrderStats createPurchaseOrderStats({
    int totalPurchaseOrders = 100,
    int pendingOrders = 20,
    int approvedOrders = 30,
    int sentOrders = 15,
    int partiallyReceivedOrders = 10,
    int receivedOrders = 20,
    int cancelledOrders = 5,
    int overdueOrders = 8,
    double totalValue = 50000000.0,
    double cancellationRate = 5.0,
    double averageOrderValue = 500000.0,
    double totalPending = 10000000.0,
    double totalReceived = 40000000.0,
    Map<String, int>? ordersBySupplier,
    Map<String, double>? valueBySupplier,
    Map<String, int>? ordersByMonth,
    List<PurchaseOrder>? topOrdersByValue,
    List<Map<String, dynamic>>? recentActivity,
    List<PurchaseOrder> orders = const [],
  }) {
    return PurchaseOrderStats(
      totalPurchaseOrders: totalPurchaseOrders,
      pendingOrders: pendingOrders,
      approvedOrders: approvedOrders,
      sentOrders: sentOrders,
      partiallyReceivedOrders: partiallyReceivedOrders,
      receivedOrders: receivedOrders,
      cancelledOrders: cancelledOrders,
      overdueOrders: overdueOrders,
      totalValue: totalValue,
      cancellationRate: cancellationRate,
      averageOrderValue: averageOrderValue,
      totalPending: totalPending,
      totalReceived: totalReceived,
      ordersBySupplier: ordersBySupplier ?? {'supplier-001': 50, 'supplier-002': 50},
      valueBySupplier: valueBySupplier ?? {'supplier-001': 25000000.0, 'supplier-002': 25000000.0},
      ordersByMonth: ordersByMonth ?? {'2024-01': 40, '2024-02': 35, '2024-03': 25},
      topOrdersByValue: topOrdersByValue ?? createPurchaseOrderEntityList(5),
      recentActivity: recentActivity ?? [],
      orders: orders,
    );
  }
}
