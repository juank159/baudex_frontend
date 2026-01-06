// lib/features/purchase_orders/data/models/isar/isar_purchase_order.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/entities/purchase_order.dart';
import 'package:isar/isar.dart';
import 'dart:convert';
import 'isar_purchase_order_item.dart';

part 'isar_purchase_order.g.dart';

@collection
class IsarPurchaseOrder {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  String? orderNumber;

  @Index()
  String? supplierId;

  String? supplierName;

  @Enumerated(EnumType.name)
  late IsarPurchaseOrderStatus status;

  @Enumerated(EnumType.name)
  late IsarPurchaseOrderPriority priority;

  @Index()
  DateTime? orderDate;

  DateTime? expectedDeliveryDate;
  DateTime? deliveredDate;

  String? currency;

  late double subtotal;
  late double taxAmount;
  late double discountAmount;
  late double totalAmount;

  // Items como relación (IsarLinks)
  final items = IsarLinks<IsarPurchaseOrderItem>();

  String? notes;
  String? internalNotes;
  String? deliveryAddress;
  String? contactPerson;
  String? contactPhone;
  String? contactEmail;

  // Attachments como JSON string
  String? attachmentsJson;

  String? createdBy;
  String? approvedBy;
  DateTime? approvedAt;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructores
  IsarPurchaseOrder();

  IsarPurchaseOrder.create({
    required this.serverId,
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
    this.notes,
    this.internalNotes,
    this.deliveryAddress,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.attachmentsJson,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // Mappers
  static IsarPurchaseOrder fromEntity(PurchaseOrder entity) {
    final isarPurchaseOrder = IsarPurchaseOrder.create(
      serverId: entity.id,
      orderNumber: entity.orderNumber,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      status: _mapPurchaseOrderStatus(entity.status),
      priority: _mapPurchaseOrderPriority(entity.priority),
      orderDate: entity.orderDate,
      expectedDeliveryDate: entity.expectedDeliveryDate,
      deliveredDate: entity.deliveredDate,
      currency: entity.currency,
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      totalAmount: entity.totalAmount,
      notes: entity.notes,
      internalNotes: entity.internalNotes,
      deliveryAddress: entity.deliveryAddress,
      contactPerson: entity.contactPerson,
      contactPhone: entity.contactPhone,
      contactEmail: entity.contactEmail,
      attachmentsJson: entity.attachments != null ? _encodeStringList(entity.attachments!) : null,
      createdBy: entity.createdBy,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      createdAt: entity.createdAt ?? DateTime.now(),
      updatedAt: entity.updatedAt ?? DateTime.now(),
      deletedAt: null,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );

    // NOTE: Items must be added via IsarLinks after saving the PurchaseOrder
    // They cannot be set in the constructor
    return isarPurchaseOrder;
  }

  static IsarPurchaseOrder fromModel(model) {
    return IsarPurchaseOrder.create(
      serverId: model.id,
      orderNumber: model.orderNumber,
      supplierId: model.supplierId,
      supplierName: model.supplierName,
      status: _mapPurchaseOrderStatusFromString(model.status ?? 'pending'),
      priority: _mapPurchaseOrderPriorityFromString(model.priority ?? 'medium'),
      orderDate: model.orderDate != null ? DateTime.parse(model.orderDate!) : null,
      expectedDeliveryDate: model.expectedDeliveryDate != null ? DateTime.parse(model.expectedDeliveryDate!) : null,
      deliveredDate: model.deliveredDate != null ? DateTime.parse(model.deliveredDate!) : null,
      currency: model.currency,
      subtotal: model.subtotal,
      taxAmount: model.taxAmount,
      discountAmount: model.discountAmount,
      totalAmount: model.totalAmount,
      notes: model.notes,
      internalNotes: model.internalNotes,
      deliveryAddress: model.deliveryAddress,
      contactPerson: model.contactPerson,
      contactPhone: model.contactPhone,
      contactEmail: model.contactEmail,
      attachmentsJson: model.attachments != null ? _encodeStringList(model.attachments!) : null,
      createdBy: model.createdBy,
      approvedBy: model.approvedBy,
      approvedAt: model.approvedAt != null && model.approvedAt!.isNotEmpty ? DateTime.parse(model.approvedAt!) : null,
      createdAt: model.createdAt != null && model.createdAt!.isNotEmpty ? DateTime.parse(model.createdAt!) : DateTime.now(),
      updatedAt: model.updatedAt != null && model.updatedAt!.isNotEmpty ? DateTime.parse(model.updatedAt!) : DateTime.now(),
      deletedAt: null,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  void updateFromModel(model) {
    serverId = model.id;
    orderNumber = model.orderNumber;
    supplierId = model.supplierId;
    supplierName = model.supplierName;
    status = IsarPurchaseOrder._mapPurchaseOrderStatusFromString(model.status ?? 'pending');
    priority = IsarPurchaseOrder._mapPurchaseOrderPriorityFromString(model.priority ?? 'medium');
    orderDate = model.orderDate != null ? DateTime.parse(model.orderDate!) : null;
    expectedDeliveryDate = model.expectedDeliveryDate != null ? DateTime.parse(model.expectedDeliveryDate!) : null;
    deliveredDate = model.deliveredDate != null ? DateTime.parse(model.deliveredDate!) : null;
    currency = model.currency;
    subtotal = model.subtotal;
    taxAmount = model.taxAmount;
    discountAmount = model.discountAmount;
    totalAmount = model.totalAmount;
    notes = model.notes;
    internalNotes = model.internalNotes;
    deliveryAddress = model.deliveryAddress;
    contactPerson = model.contactPerson;
    contactPhone = model.contactPhone;
    contactEmail = model.contactEmail;
    attachmentsJson = model.attachments != null ? _encodeStringList(model.attachments!) : null;
    createdBy = model.createdBy;
    approvedBy = model.approvedBy;
    approvedAt = model.approvedAt != null && model.approvedAt!.isNotEmpty ? DateTime.parse(model.approvedAt!) : null;
    createdAt = model.createdAt != null && model.createdAt!.isNotEmpty ? DateTime.parse(model.createdAt!) : DateTime.now();
    updatedAt = DateTime.now();
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  PurchaseOrder toEntity() {
    return PurchaseOrder(
      id: serverId,
      orderNumber: orderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      status: _mapIsarPurchaseOrderStatus(status),
      priority: _mapIsarPurchaseOrderPriority(priority),
      orderDate: orderDate,
      expectedDeliveryDate: expectedDeliveryDate,
      deliveredDate: deliveredDate,
      currency: currency,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      items: items.map((item) => item.toEntity()).toList(),
      notes: notes,
      internalNotes: internalNotes,
      deliveryAddress: deliveryAddress,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      attachments: attachmentsJson != null ? _decodeStringList(attachmentsJson!) : null,
      createdBy: createdBy,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarPurchaseOrderStatus _mapPurchaseOrderStatus(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return IsarPurchaseOrderStatus.draft;
      case PurchaseOrderStatus.pending:
        return IsarPurchaseOrderStatus.pending;
      case PurchaseOrderStatus.approved:
        return IsarPurchaseOrderStatus.approved;
      case PurchaseOrderStatus.rejected:
        return IsarPurchaseOrderStatus.rejected;
      case PurchaseOrderStatus.sent:
        return IsarPurchaseOrderStatus.sent;
      case PurchaseOrderStatus.partiallyReceived:
        return IsarPurchaseOrderStatus.partiallyReceived;
      case PurchaseOrderStatus.received:
        return IsarPurchaseOrderStatus.received;
      case PurchaseOrderStatus.cancelled:
        return IsarPurchaseOrderStatus.cancelled;
    }
  }

  static PurchaseOrderStatus _mapIsarPurchaseOrderStatus(IsarPurchaseOrderStatus status) {
    switch (status) {
      case IsarPurchaseOrderStatus.draft:
        return PurchaseOrderStatus.draft;
      case IsarPurchaseOrderStatus.pending:
        return PurchaseOrderStatus.pending;
      case IsarPurchaseOrderStatus.approved:
        return PurchaseOrderStatus.approved;
      case IsarPurchaseOrderStatus.rejected:
        return PurchaseOrderStatus.rejected;
      case IsarPurchaseOrderStatus.sent:
        return PurchaseOrderStatus.sent;
      case IsarPurchaseOrderStatus.partiallyReceived:
        return PurchaseOrderStatus.partiallyReceived;
      case IsarPurchaseOrderStatus.received:
        return PurchaseOrderStatus.received;
      case IsarPurchaseOrderStatus.cancelled:
        return PurchaseOrderStatus.cancelled;
    }
  }

  static IsarPurchaseOrderPriority _mapPurchaseOrderPriority(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return IsarPurchaseOrderPriority.low;
      case PurchaseOrderPriority.medium:
        return IsarPurchaseOrderPriority.medium;
      case PurchaseOrderPriority.high:
        return IsarPurchaseOrderPriority.high;
      case PurchaseOrderPriority.urgent:
        return IsarPurchaseOrderPriority.urgent;
    }
  }

  static PurchaseOrderPriority _mapIsarPurchaseOrderPriority(IsarPurchaseOrderPriority priority) {
    switch (priority) {
      case IsarPurchaseOrderPriority.low:
        return PurchaseOrderPriority.low;
      case IsarPurchaseOrderPriority.medium:
        return PurchaseOrderPriority.medium;
      case IsarPurchaseOrderPriority.high:
        return PurchaseOrderPriority.high;
      case IsarPurchaseOrderPriority.urgent:
        return PurchaseOrderPriority.urgent;
    }
  }

  // Helpers para mapeo desde strings (usado en fromModel)
  static IsarPurchaseOrderStatus _mapPurchaseOrderStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return IsarPurchaseOrderStatus.draft;
      case 'pending':
        return IsarPurchaseOrderStatus.pending;
      case 'approved':
        return IsarPurchaseOrderStatus.approved;
      case 'rejected':
        return IsarPurchaseOrderStatus.rejected;
      case 'sent':
        return IsarPurchaseOrderStatus.sent;
      case 'partially_received':
        return IsarPurchaseOrderStatus.partiallyReceived;
      case 'received':
        return IsarPurchaseOrderStatus.received;
      case 'cancelled':
        return IsarPurchaseOrderStatus.cancelled;
      default:
        return IsarPurchaseOrderStatus.draft;
    }
  }

  static IsarPurchaseOrderPriority _mapPurchaseOrderPriorityFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return IsarPurchaseOrderPriority.low;
      case 'medium':
        return IsarPurchaseOrderPriority.medium;
      case 'high':
        return IsarPurchaseOrderPriority.high;
      case 'urgent':
        return IsarPurchaseOrderPriority.urgent;
      default:
        return IsarPurchaseOrderPriority.medium;
    }
  }

  // Helpers para serialización
  static String _encodeStringList(List<String> list) {
    try {
      return json.encode(list);
    } catch (e) {
      return '[]';
    }
  }

  static List<String> _decodeStringList(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get needsSync => !isSynced;
  bool get isDraft => status == IsarPurchaseOrderStatus.draft;
  bool get isPending => status == IsarPurchaseOrderStatus.pending;
  bool get isApproved => status == IsarPurchaseOrderStatus.approved;
  bool get isReceived => status == IsarPurchaseOrderStatus.received;
  bool get isCancelled => status == IsarPurchaseOrderStatus.cancelled;

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }


  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  bool hasConflictWith(IsarPurchaseOrder serverVersion) {
    if (version == serverVersion.version &&
        lastModifiedAt != null &&
        serverVersion.lastModifiedAt != null &&
        lastModifiedAt != serverVersion.lastModifiedAt) {
      return true;
    }
    if (version > serverVersion.version) {
      return true;
    }
    return false;
  }
  @override
  String toString() {
    return 'IsarPurchaseOrder{serverId: $serverId, orderNumber: $orderNumber, status: $status, version: $version, isSynced: $isSynced}';
  }
}
