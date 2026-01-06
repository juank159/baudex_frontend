// test/fixtures/purchase_order_model_fixtures.dart
import 'package:baudex_desktop/features/purchase_orders/data/models/purchase_order_model.dart';

/// Test fixtures for PurchaseOrder Models
class PurchaseOrderModelFixtures {
  // ============================================================================
  // MODEL FIXTURES (Data Layer)
  // ============================================================================

  /// Creates a single purchase order model with default test data
  static PurchaseOrderModel createPurchaseOrderModel({
    String id = 'po-001',
    String? orderNumber = 'PO-001',
    String? supplierId = 'supp-001',
    String? supplierName = 'Test Supplier',
    String status = 'draft',
    String priority = 'medium',
    String? orderDate,
    String? expectedDeliveryDate,
    String? deliveredDate,
    String currency = 'COP',
    double subtotal = 1000000.0,
    double taxAmount = 190000.0,
    double discountAmount = 0.0,
    double totalAmount = 1190000.0,
    List<PurchaseOrderItemModel>? items,
    String? notes,
    String? createdBy = 'user-001',
  }) {
    final poOrderDate = orderDate ?? '2024-01-01T00:00:00.000Z';
    final poExpectedDate = expectedDeliveryDate ?? '2024-01-08T00:00:00.000Z';

    return PurchaseOrderModel(
      id: id,
      orderNumber: orderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      status: status,
      priority: priority,
      orderDate: poOrderDate,
      expectedDeliveryDate: poExpectedDate,
      deliveredDate: deliveredDate,
      actualDeliveryDate: deliveredDate,
      supplierReference: null,
      terms: null,
      taxPercentage: null,
      discountPercentage: null,
      shippingCost: null,
      currency: currency,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      items: items ?? [createPurchaseOrderItemModel()],
      notes: notes,
      internalNotes: null,
      deliveryAddress: null,
      contactPerson: null,
      contactPhone: null,
      contactEmail: null,
      attachments: null,
      metadata: null,
      supplier: null,
      batches: null,
      createdBy: createdBy,
      approvedBy: null,
      approvedAt: null,
      createdAt: poOrderDate,
      updatedAt: poOrderDate,
    );
  }

  /// Creates a list of purchase order models
  static List<PurchaseOrderModel> createPurchaseOrderModelList(int count) {
    return List.generate(count, (index) {
      final date = DateTime(2024, 1, 1).add(Duration(days: index)).toIso8601String();
      return createPurchaseOrderModel(
        id: 'po-${(index + 1).toString().padLeft(3, '0')}',
        orderNumber: 'PO-${(index + 1).toString().padLeft(3, '0')}',
        orderDate: date,
        totalAmount: (index + 1) * 500000.0,
      );
    });
  }

  // ============================================================================
  // PURCHASE ORDER ITEM MODEL FIXTURES
  // ============================================================================

  /// Creates a single purchase order item model
  static PurchaseOrderItemModel createPurchaseOrderItemModel({
    String id = 'po-item-001',
    String productId = 'prod-001',
    String? notes,
    int quantity = 10,
    int receivedQuantity = 0,
    double unitCost = 100000.0,
    double totalCost = 1000000.0,
  }) {
    return PurchaseOrderItemModel(
      id: id,
      productId: productId,
      notes: notes,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      deletedAt: null,
      lineNumber: 1,
      quantity: quantity.toString(),
      unitCost: unitCost.toString(),
      totalCost: totalCost.toString(),
      receivedQuantity: receivedQuantity.toString(),
      damagedQuantity: '0',
      missingQuantity: '0',
      pendingQuantity: (quantity - receivedQuantity).toString(),
      expectedDate: null,
      lastReceivedDate: null,
      metadata: null,
      organizationId: null,
      purchaseOrderId: 'po-001',
      product: {
        'id': productId,
        'name': 'Test Product',
        'sku': 'SKU-001',
        'description': 'Test product description',
      },
    );
  }

  /// Creates a list of purchase order item models
  static List<PurchaseOrderItemModel> createPurchaseOrderItemModelList(int count) {
    return List.generate(count, (index) {
      final qty = (index + 1) * 5;
      final unitCost = (index + 1) * 20000.0;
      final totalCost = qty * unitCost;

      return createPurchaseOrderItemModel(
        id: 'po-item-${(index + 1).toString().padLeft(3, '0')}',
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        quantity: qty,
        unitCost: unitCost,
        totalCost: totalCost,
      );
    });
  }

  // ============================================================================
  // PURCHASE ORDER STATS MODEL FIXTURES
  // ============================================================================

  /// Creates purchase order stats model
  static PurchaseOrderStatsModel createPurchaseOrderStatsModel({
    int total = 100,
    Map<String, int>? byStatus,
    num totalValue = 50000000.0,
    num? averageOrderValue,
  }) {
    return PurchaseOrderStatsModel(
      total: total,
      byStatus: byStatus ?? {
        'draft': 10,
        'pending': 20,
        'approved': 15,
        'sent': 20,
        'partially_received': 10,
        'received': 20,
        'cancelled': 5,
      },
      totalValue: totalValue,
      averageOrderValue: averageOrderValue ?? (totalValue / total),
    );
  }

  // ============================================================================
  // SPECIAL CASE MODEL FIXTURES
  // ============================================================================

  /// Creates a draft purchase order model
  static PurchaseOrderModel createDraftPurchaseOrderModel({
    String id = 'po-draft',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'DRAFT-001',
      status: 'draft',
    );
  }

  /// Creates a pending purchase order model
  static PurchaseOrderModel createPendingPurchaseOrderModel({
    String id = 'po-pending',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-PENDING',
      status: 'pending',
    );
  }

  /// Creates an approved purchase order model
  static PurchaseOrderModel createApprovedPurchaseOrderModel({
    String id = 'po-approved',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-APPROVED',
      status: 'approved',
    );
  }

  /// Creates a sent purchase order model
  static PurchaseOrderModel createSentPurchaseOrderModel({
    String id = 'po-sent',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-SENT',
      status: 'sent',
    );
  }

  /// Creates a partially received purchase order model
  static PurchaseOrderModel createPartiallyReceivedPurchaseOrderModel({
    String id = 'po-partial',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-PARTIAL',
      status: 'partially_received',
      items: [
        createPurchaseOrderItemModel(
          id: 'po-item-001',
          quantity: 10,
          receivedQuantity: 6,
        ),
        createPurchaseOrderItemModel(
          id: 'po-item-002',
          productId: 'prod-002',
          quantity: 20,
          receivedQuantity: 0,
        ),
      ],
    );
  }

  /// Creates a fully received purchase order model
  static PurchaseOrderModel createFullyReceivedPurchaseOrderModel({
    String id = 'po-received',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-RECEIVED',
      status: 'received',
      deliveredDate: '2024-01-08T00:00:00.000Z',
      items: [
        createPurchaseOrderItemModel(
          id: 'po-item-001',
          quantity: 10,
          receivedQuantity: 10,
        ),
        createPurchaseOrderItemModel(
          id: 'po-item-002',
          productId: 'prod-002',
          quantity: 20,
          receivedQuantity: 20,
        ),
      ],
    );
  }

  /// Creates a cancelled purchase order model
  static PurchaseOrderModel createCancelledPurchaseOrderModel({
    String id = 'po-cancelled',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-CANCELLED',
      status: 'cancelled',
    );
  }

  /// Creates a rejected purchase order model
  static PurchaseOrderModel createRejectedPurchaseOrderModel({
    String id = 'po-rejected',
  }) {
    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-REJECTED',
      status: 'rejected',
    );
  }

  /// Creates a purchase order model with multiple items
  static PurchaseOrderModel createPurchaseOrderModelWithMultipleItems({
    String id = 'po-multi-items',
    int itemCount = 5,
  }) {
    final items = createPurchaseOrderItemModelList(itemCount);

    // Calculate totals
    double subtotal = 0.0;
    for (var item in items) {
      final cost = double.tryParse(item.totalCost ?? '0') ?? 0.0;
      subtotal += cost;
    }
    final taxAmount = subtotal * 0.19;
    final totalAmount = subtotal + taxAmount;

    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-MULTI',
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
    );
  }

  /// Creates an overdue purchase order model
  static PurchaseOrderModel createOverduePurchaseOrderModel({
    String id = 'po-overdue',
  }) {
    final orderDate = DateTime.now().subtract(const Duration(days: 30));
    final expectedDate = orderDate.add(const Duration(days: 7));

    return createPurchaseOrderModel(
      id: id,
      orderNumber: 'PO-OVERDUE',
      status: 'sent',
      orderDate: orderDate.toIso8601String(),
      expectedDeliveryDate: expectedDate.toIso8601String(),
    );
  }

  // ============================================================================
  // JSON RESPONSE FIXTURES
  // ============================================================================

  /// Creates a success response JSON map
  static Map<String, dynamic> createSuccessResponseJson({
    required PurchaseOrderModel purchaseOrder,
    String message = 'Purchase order retrieved successfully',
  }) {
    return {
      'success': true,
      'data': purchaseOrder.toJson(),
      'message': message,
    };
  }

  /// Creates a list response JSON map
  static Map<String, dynamic> createListResponseJson({
    required List<PurchaseOrderModel> purchaseOrders,
    int total = 100,
    String message = 'Purchase orders retrieved successfully',
  }) {
    return {
      'success': true,
      'data': {
        'data': purchaseOrders.map((po) => po.toJson()).toList(),
        'total': total,
      },
      'message': message,
    };
  }

  /// Creates a stats response JSON map
  static Map<String, dynamic> createStatsResponseJson({
    required PurchaseOrderStatsModel stats,
    String message = 'Purchase order stats retrieved successfully',
  }) {
    return {
      'success': true,
      'data': stats.toJson(),
      'message': message,
    };
  }

  /// Creates an error response JSON map
  static Map<String, dynamic> createErrorResponseJson({
    String error = 'Purchase order not found',
  }) {
    return {
      'success': false,
      'error': error,
      'message': error,
    };
  }
}
