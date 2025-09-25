// lib/features/purchase_orders/domain/entities/purchase_order.dart
import 'package:equatable/equatable.dart';

enum PurchaseOrderStatus {
  draft,
  pending,
  approved,
  rejected,
  sent,
  partiallyReceived,
  received,
  cancelled;

  String get displayStatus {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Borrador';
      case PurchaseOrderStatus.pending:
        return 'Pendiente';
      case PurchaseOrderStatus.approved:
        return 'Aprobada';
      case PurchaseOrderStatus.rejected:
        return 'Rechazada';
      case PurchaseOrderStatus.sent:
        return 'Enviada';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Parcialmente Recibida';
      case PurchaseOrderStatus.received:
        return 'Recibida';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }
}

enum PurchaseOrderPriority {
  low,
  medium,
  high,
  urgent;

  String get displayPriority {
    switch (this) {
      case PurchaseOrderPriority.low:
        return 'Baja';
      case PurchaseOrderPriority.medium:
        return 'Media';
      case PurchaseOrderPriority.high:
        return 'Alta';
      case PurchaseOrderPriority.urgent:
        return 'Urgente';
    }
  }
}

class PurchaseOrder extends Equatable {
  final String id;
  final String? orderNumber;
  final String? supplierId;
  final String? supplierName;
  final PurchaseOrderStatus status;
  final PurchaseOrderPriority priority;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveredDate;
  final String? currency;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final List<PurchaseOrderItem> items;
  final String? notes;
  final String? internalNotes;
  final String? deliveryAddress;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? attachments;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PurchaseOrder({
    required this.id,
    this.orderNumber,
    this.supplierId,
    this.supplierName,
    required this.status,
    required this.priority,
    this.orderDate,
    this.expectedDeliveryDate,
    this.deliveredDate,
    this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.items,
    this.notes,
    this.internalNotes,
    this.deliveryAddress,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.attachments,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        supplierId,
        supplierName,
        status,
        priority,
        orderDate,
        expectedDeliveryDate,
        deliveredDate,
        currency,
        subtotal,
        taxAmount,
        discountAmount,
        totalAmount,
        items,
        notes,
        internalNotes,
        deliveryAddress,
        contactPerson,
        contactPhone,
        contactEmail,
        attachments,
        createdBy,
        approvedBy,
        approvedAt,
        createdAt,
        updatedAt,
      ];

  // Computed properties
  bool get isDraft => status == PurchaseOrderStatus.draft;
  bool get isPending => status == PurchaseOrderStatus.pending;
  bool get isApproved => status == PurchaseOrderStatus.approved;
  bool get isRejected => status == PurchaseOrderStatus.rejected;
  bool get isSent => status == PurchaseOrderStatus.sent;
  bool get isPartiallyReceived => status == PurchaseOrderStatus.partiallyReceived;
  bool get isReceived => status == PurchaseOrderStatus.received;
  bool get isCancelled => status == PurchaseOrderStatus.cancelled;

  // Verificar si está completamente recibida basado en cantidades reales
  bool get isFullyReceived {
    if (items.isEmpty) return false;
    return items.every((item) => 
      item.receivedQuantity != null && item.receivedQuantity! >= item.quantity
    );
  }

  bool get canEdit => isDraft || isPending || isRejected;
  bool get canSubmitForReview => isDraft;
  bool get canApprove => isPending;
  bool get canSend => isApproved;
  bool get canReceive => (isApproved || isSent || isPartiallyReceived) && !isFullyReceived;
  bool get canCancel => isDraft || isPending || isApproved;

  bool get isOverdue =>
      expectedDeliveryDate?.isBefore(DateTime.now()) == true && !isReceived && !isPartiallyReceived && !isCancelled;

  bool get hasDeliveryInfo =>
      deliveryAddress != null ||
      contactPerson != null ||
      contactPhone != null ||
      contactEmail != null;

  bool get hasAttachments => attachments?.isNotEmpty == true;

  int get itemsCount => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get averageItemPrice =>
      items.isEmpty ? 0.0 : subtotal / totalQuantity;

  String get displayNumber => orderNumber ?? 'Sin número';

  String? get supplierContactInfo {
    final parts = <String>[];
    if (contactPerson != null && contactPerson!.isNotEmpty) {
      parts.add(contactPerson!);
    }
    if (contactPhone != null && contactPhone!.isNotEmpty) {
      parts.add(contactPhone!);
    }
    if (contactEmail != null && contactEmail!.isNotEmpty) {
      parts.add(contactEmail!);
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String get displayStatus {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return 'Borrador';
      case PurchaseOrderStatus.pending:
        return 'Pendiente';
      case PurchaseOrderStatus.approved:
        return 'Aprobada';
      case PurchaseOrderStatus.rejected:
        return 'Rechazada';
      case PurchaseOrderStatus.sent:
        return 'Enviada';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Parcialmente Recibida';
      case PurchaseOrderStatus.received:
        return 'Recibida';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  String get displayPriority {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return 'Baja';
      case PurchaseOrderPriority.medium:
        return 'Media';
      case PurchaseOrderPriority.high:
        return 'Alta';
      case PurchaseOrderPriority.urgent:
        return 'Urgente';
    }
  }

  // Copy with method
  PurchaseOrder copyWith({
    String? id,
    String? orderNumber,
    String? supplierId,
    String? supplierName,
    PurchaseOrderStatus? status,
    PurchaseOrderPriority? priority,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    DateTime? deliveredDate,
    String? currency,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
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
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      currency: currency ?? this.currency,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PurchaseOrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productCode;
  final String? productDescription;
  final String unit;
  final int quantity;
  final int? receivedQuantity;
  final int? damagedQuantity;
  final int? missingQuantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseOrderItem({
    required this.id,
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

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productCode,
        productDescription,
        unit,
        quantity,
        receivedQuantity,
        damagedQuantity,
        missingQuantity,
        unitPrice,
        discountPercentage,
        discountAmount,
        subtotal,
        taxPercentage,
        taxAmount,
        totalAmount,
        notes,
        createdAt,
        updatedAt,
      ];

  // Computed properties
  bool get hasDiscount => discountPercentage > 0 || discountAmount > 0;
  bool get hasTax => taxPercentage > 0 || taxAmount > 0;
  bool get isFullyReceived => receivedQuantity != null && receivedQuantity! >= quantity;
  bool get isPartiallyReceived => receivedQuantity != null && receivedQuantity! > 0 && receivedQuantity! < quantity;
  bool get isPendingDelivery => receivedQuantity == null || receivedQuantity! == 0;

  int get pendingQuantity => quantity - (receivedQuantity ?? 0);
  double get receivedPercentage => receivedQuantity == null ? 0.0 : (receivedQuantity! / quantity * 100);
  
  // Propiedades calculadas para dañados y faltantes
  int get actualDamagedQuantity => damagedQuantity ?? 0;
  int get actualMissingQuantity => missingQuantity ?? 0;
  bool get hasDamagedItems => actualDamagedQuantity > 0;
  bool get hasMissingItems => actualMissingQuantity > 0;

  String get displayName => productCode != null ? '$productCode - $productName' : productName;
  String get displayQuantity => '$quantity $unit';
  String get displayReceived => receivedQuantity != null ? '${receivedQuantity!} / $quantity $unit' : '0 / $quantity $unit';

  // Copy with method
  PurchaseOrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productCode,
    String? productDescription,
    String? unit,
    int? quantity,
    int? receivedQuantity,
    int? damagedQuantity,
    int? missingQuantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    double? subtotal,
    double? taxPercentage,
    double? taxAmount,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productDescription: productDescription ?? this.productDescription,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      damagedQuantity: damagedQuantity ?? this.damagedQuantity,
      missingQuantity: missingQuantity ?? this.missingQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      subtotal: subtotal ?? this.subtotal,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Statistics entity
class PurchaseOrderStats extends Equatable {
  final int totalPurchaseOrders;
  final int pendingOrders;
  final int approvedOrders;
  final int sentOrders;
  final int partiallyReceivedOrders;
  final int receivedOrders;
  final int cancelledOrders;
  final int overdueOrders;
  final double totalValue;
  final double cancellationRate;
  final double averageOrderValue;
  final double totalPending;
  final double totalReceived;
  final Map<String, int> ordersBySupplier;
  final Map<String, double> valueBySupplier;
  final Map<String, int> ordersByMonth;
  final List<PurchaseOrder> topOrdersByValue;
  final List<Map<String, dynamic>> recentActivity;
  
  // Lista de órdenes para cálculos dinámicos
  final List<PurchaseOrder> orders;

  const PurchaseOrderStats({
    required this.totalPurchaseOrders,
    required this.pendingOrders,
    required this.approvedOrders,
    required this.sentOrders,
    required this.partiallyReceivedOrders,
    required this.receivedOrders,
    required this.cancelledOrders,
    required this.overdueOrders,
    required this.totalValue,
    required this.cancellationRate,
    required this.averageOrderValue,
    required this.totalPending,
    required this.totalReceived,
    required this.ordersBySupplier,
    required this.valueBySupplier,
    required this.ordersByMonth,
    required this.topOrdersByValue,
    required this.recentActivity,
    this.orders = const [],
  });

  @override
  List<Object?> get props => [
        totalPurchaseOrders,
        pendingOrders,
        approvedOrders,
        sentOrders,
        partiallyReceivedOrders,
        receivedOrders,
        cancelledOrders,
        overdueOrders,
        totalValue,
        cancellationRate,
        averageOrderValue,
        totalPending,
        totalReceived,
        ordersBySupplier,
        valueBySupplier,
        ordersByMonth,
        topOrdersByValue,
        recentActivity,
        orders,
      ];

  // Computed properties
  double get completionRate => totalPurchaseOrders > 0 ? (receivedOrders / totalPurchaseOrders * 100) : 0.0;
  double get pendingRate => totalPurchaseOrders > 0 ? (pendingOrders / totalPurchaseOrders * 100) : 0.0;
  double get overdueRate => totalPurchaseOrders > 0 ? (overdueOrders / totalPurchaseOrders * 100) : 0.0;

  // Aliases for widget compatibility
  int get totalOrders => totalPurchaseOrders;
  
  // Cálculo dinámico de proveedores únicos
  int get activeSuppliers {
    if (orders.isEmpty) return ordersBySupplier.length; // Fallback al valor hardcoded si no hay órdenes
    final uniqueSuppliers = <String>{};
    for (final order in orders) {
      if (order.supplierName?.isNotEmpty == true) {
        uniqueSuppliers.add(order.supplierName!);
      }
    }
    return uniqueSuppliers.length;
  }
  
  double get averageDeliveryDays => 30.0; // Placeholder value
  double get onTimeDeliveryRate => 0.85; // Placeholder value
  int get pendingUrgentOrders => pendingOrders; // Placeholder - should filter by priority
  double get approvalRate => totalPurchaseOrders > 0 ? (approvedOrders / totalPurchaseOrders) : 0.0;
  
  // Priority-based getters calculados dinámicamente
  int get urgentOrders {
    if (orders.isEmpty) return (totalPurchaseOrders * 0.1).round(); // Fallback
    return orders.where((order) => order.priority == PurchaseOrderPriority.urgent).length;
  }
  
  int get highPriorityOrders {
    if (orders.isEmpty) return (totalPurchaseOrders * 0.2).round(); // Fallback
    return orders.where((order) => order.priority == PurchaseOrderPriority.high).length;
  }
  
  int get mediumPriorityOrders {
    if (orders.isEmpty) return (totalPurchaseOrders * 0.5).round(); // Fallback
    return orders.where((order) => order.priority == PurchaseOrderPriority.medium).length;
  }
  
  int get lowPriorityOrders {
    if (orders.isEmpty) return (totalPurchaseOrders * 0.2).round(); // Fallback
    return orders.where((order) => order.priority == PurchaseOrderPriority.low).length;
  }
}