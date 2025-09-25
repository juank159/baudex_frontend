// lib/features/purchase_orders/domain/repositories/purchase_order_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart';
import '../entities/purchase_order.dart';

class PurchaseOrderQueryParams {
  final int page;
  final int limit;
  final String? search;
  final PurchaseOrderStatus? status;
  final PurchaseOrderPriority? priority;
  final String? supplierId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? expectedDeliveryStartDate;
  final DateTime? expectedDeliveryEndDate;
  final String? createdBy;
  final String? approvedBy;
  final bool? isOverdue;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const PurchaseOrderQueryParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.priority,
    this.supplierId,
    this.startDate,
    this.endDate,
    this.expectedDeliveryStartDate,
    this.expectedDeliveryEndDate,
    this.createdBy,
    this.approvedBy,
    this.isOverdue,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'orderDate',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status!.name,
      if (priority != null) 'priority': priority!.name,
      if (supplierId != null) 'supplierId': supplierId,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (expectedDeliveryStartDate != null) 'expectedDeliveryStartDate': expectedDeliveryStartDate!.toIso8601String(),
      if (expectedDeliveryEndDate != null) 'expectedDeliveryEndDate': expectedDeliveryEndDate!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (isOverdue != null) 'isOverdue': isOverdue,
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  PurchaseOrderQueryParams copyWith({
    int? page,
    int? limit,
    String? search,
    PurchaseOrderStatus? status,
    PurchaseOrderPriority? priority,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? expectedDeliveryStartDate,
    DateTime? expectedDeliveryEndDate,
    String? createdBy,
    String? approvedBy,
    bool? isOverdue,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    String? sortOrder,
  }) {
    return PurchaseOrderQueryParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      supplierId: supplierId ?? this.supplierId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expectedDeliveryStartDate: expectedDeliveryStartDate ?? this.expectedDeliveryStartDate,
      expectedDeliveryEndDate: expectedDeliveryEndDate ?? this.expectedDeliveryEndDate,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      isOverdue: isOverdue ?? this.isOverdue,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class SearchPurchaseOrdersParams {
  final String searchTerm;
  final int limit;
  final List<PurchaseOrderStatus>? statuses;
  final String? supplierId;

  const SearchPurchaseOrdersParams({
    required this.searchTerm,
    this.limit = 20,
    this.statuses,
    this.supplierId,
  });

  Map<String, dynamic> toMap() {
    return {
      'searchTerm': searchTerm,
      'limit': limit,
      if (statuses != null) 'statuses': statuses!.map((s) => s.name).toList(),
      if (supplierId != null) 'supplierId': supplierId,
    };
  }
}

class CreatePurchaseOrderParams {
  final String supplierId;
  final PurchaseOrderPriority priority;
  final DateTime orderDate;
  final DateTime expectedDeliveryDate;
  final String currency;
  final List<CreatePurchaseOrderItemParams> items;
  final String? notes;
  final String? internalNotes;
  final String? deliveryAddress;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String> attachments;

  const CreatePurchaseOrderParams({
    required this.supplierId,
    required this.priority,
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.currency,
    required this.items,
    this.notes,
    this.internalNotes,
    this.deliveryAddress,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'priority': priority.name,
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate.toIso8601String(),
      'currency': currency,
      'items': items.map((item) => item.toMap()).toList(),
      if (notes != null) 'notes': notes,
      if (internalNotes != null) 'internalNotes': internalNotes,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
      'attachments': attachments,
    };
  }
}

class CreatePurchaseOrderItemParams {
  final String productId;
  final int? lineNumber;
  final int quantity;
  final double unitPrice;
  final double discountPercentage;
  final double taxPercentage;
  final String? notes;

  const CreatePurchaseOrderItemParams({
    required this.productId,
    this.lineNumber,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      if (lineNumber != null) 'lineNumber': lineNumber,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'taxPercentage': taxPercentage,
      if (notes != null) 'notes': notes,
    };
  }
}

class UpdatePurchaseOrderParams {
  final String id;
  final String? supplierId;
  final PurchaseOrderStatus? status;
  final PurchaseOrderPriority? priority;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveredDate;
  final String? currency;
  final List<UpdatePurchaseOrderItemParams>? items;
  final String? notes;
  final String? internalNotes;
  final String? deliveryAddress;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? attachments;

  const UpdatePurchaseOrderParams({
    required this.id,
    this.supplierId,
    this.status,
    this.priority,
    this.orderDate,
    this.expectedDeliveryDate,
    this.deliveredDate,
    this.currency,
    this.items,
    this.notes,
    this.internalNotes,
    this.deliveryAddress,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (supplierId != null) 'supplierId': supplierId,
      if (status != null) 'status': status!.name,
      if (priority != null) 'priority': priority!.name,
      if (orderDate != null) 'orderDate': orderDate!.toIso8601String(),
      if (expectedDeliveryDate != null) 'expectedDeliveryDate': expectedDeliveryDate!.toIso8601String(),
      if (deliveredDate != null) 'deliveredDate': deliveredDate!.toIso8601String(),
      if (currency != null) 'currency': currency,
      if (items != null) 'items': items!.map((item) => item.toMap()).toList(),
      if (notes != null) 'notes': notes,
      if (internalNotes != null) 'internalNotes': internalNotes,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (attachments != null) 'attachments': attachments,
    };
  }
}

class UpdatePurchaseOrderItemParams {
  final String? id;
  final String productId;
  final int quantity;
  final int? receivedQuantity;
  final double unitPrice;
  final double discountPercentage;
  final double taxPercentage;
  final String? notes;

  const UpdatePurchaseOrderItemParams({
    this.id,
    required this.productId,
    required this.quantity,
    this.receivedQuantity,
    required this.unitPrice,
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'quantity': quantity,
      if (receivedQuantity != null) 'receivedQuantity': receivedQuantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'taxPercentage': taxPercentage,
      if (notes != null) 'notes': notes,
    };
  }
}

class ReceivePurchaseOrderParams {
  final String id;
  final List<ReceivePurchaseOrderItemParams> items;
  final DateTime? receivedDate;
  final String? notes;
  final String? warehouseId;

  const ReceivePurchaseOrderParams({
    required this.id,
    required this.items,
    this.receivedDate,
    this.notes,
    this.warehouseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      if (receivedDate != null) 'receivedDate': receivedDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (warehouseId != null) 'warehouseId': warehouseId,
    };
  }
}

class ReceivePurchaseOrderItemParams {
  final String itemId;
  final int receivedQuantity;
  final int? damagedQuantity;
  final int? missingQuantity;
  final double? actualUnitCost;
  final String? supplierLotNumber;
  final String? expirationDate;
  final String? notes;

  const ReceivePurchaseOrderItemParams({
    required this.itemId,
    required this.receivedQuantity,
    this.damagedQuantity,
    this.missingQuantity,
    this.actualUnitCost,
    this.supplierLotNumber,
    this.expirationDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'purchaseOrderItemId': itemId,
      'receivedQuantity': receivedQuantity,
      if (damagedQuantity != null) 'damagedQuantity': damagedQuantity,
      if (missingQuantity != null) 'missingQuantity': missingQuantity,
      if (actualUnitCost != null) 'actualUnitCost': actualUnitCost,
      if (supplierLotNumber != null) 'supplierLotNumber': supplierLotNumber,
      if (expirationDate != null) 'expirationDate': expirationDate,
      if (notes != null) 'notes': notes,
    };
  }
}

abstract class PurchaseOrderRepository {
  // Consultas básicas
  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  );

  Future<Either<Failure, PurchaseOrder>> getPurchaseOrderById(String id);

  Future<Either<Failure, List<PurchaseOrder>>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  );

  Future<Either<Failure, PurchaseOrderStats>> getPurchaseOrderStats();

  // Operaciones CRUD
  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  );

  Future<Either<Failure, PurchaseOrder>> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  );

  Future<Either<Failure, void>> deletePurchaseOrder(String id);

  // Operaciones específicas del flujo
  Future<Either<Failure, PurchaseOrder>> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  );

  Future<Either<Failure, PurchaseOrder>> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  );

  Future<Either<Failure, PurchaseOrder>> sendPurchaseOrder(
    String id,
    String? sendNotes,
  );

  Future<Either<Failure, PurchaseOrder>> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  );

  Future<Either<Failure, PurchaseOrder>> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  );

  // Consultas específicas
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrdersBySupplier(
    String supplierId,
  );

  Future<Either<Failure, List<PurchaseOrder>>> getOverduePurchaseOrders();

  Future<Either<Failure, List<PurchaseOrder>>> getPendingApprovalPurchaseOrders();

  Future<Either<Failure, List<PurchaseOrder>>> getRecentPurchaseOrders(
    int limit,
  );

  // Reportes y estadísticas
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseOrderSummary(
    DateTime startDate,
    DateTime endDate,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByStatus();

  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersStatsbySupplier();

  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByMonth(
    int year,
  );
}