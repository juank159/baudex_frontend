// lib/features/inventory/data/models/isar/isar_inventory_movement.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_movement_model.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

part 'isar_inventory_movement.g.dart';

@collection
class IsarInventoryMovement {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String productId;

  late String productName;
  late String productSku;

  @Enumerated(EnumType.name)
  late IsarInventoryMovementType type;

  @Index()
  @Enumerated(EnumType.name)
  late IsarInventoryMovementStatus status;

  @Enumerated(EnumType.name)
  late IsarInventoryMovementReason reason;

  late int quantity;
  late double unitCost;
  late double totalCost;

  double? unitPrice;
  double? totalPrice;

  String? lotNumber;
  DateTime? expiryDate;

  @Index()
  String? warehouseId;

  String? warehouseName;

  @Index()
  String? referenceId;

  String? referenceType;
  String? notes;

  String? userId;
  String? userName;

  // Metadata como JSON string
  String? metadataJson;

  @Index()
  late DateTime movementDate;

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
  IsarInventoryMovement();

  IsarInventoryMovement.create({
    required this.serverId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.type,
    required this.status,
    required this.reason,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.unitPrice,
    this.totalPrice,
    this.lotNumber,
    this.expiryDate,
    this.warehouseId,
    this.warehouseName,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.userId,
    this.userName,
    this.metadataJson,
    required this.movementDate,
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
  static IsarInventoryMovement fromEntity(InventoryMovement entity) {
    return IsarInventoryMovement.create(
      serverId: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      type: _mapInventoryMovementType(entity.type),
      status: _mapInventoryMovementStatus(entity.status),
      reason: _mapInventoryMovementReason(entity.reason),
      quantity: entity.quantity,
      unitCost: entity.unitCost,
      totalCost: entity.totalCost,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      lotNumber: entity.lotNumber,
      expiryDate: entity.expiryDate,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      referenceId: entity.referenceId,
      referenceType: entity.referenceType,
      notes: entity.notes,
      userId: entity.userId,
      userName: entity.userName,
      metadataJson: entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      movementDate: entity.movementDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: null,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  static IsarInventoryMovement fromModel(InventoryMovementModel model) {
    final entity = model.toEntity();
    return fromEntity(entity);
  }

  void updateFromModel(InventoryMovementModel model) {
    final entity = model.toEntity();
    serverId = entity.id;
    productId = entity.productId;
    productName = entity.productName;
    productSku = entity.productSku;
    type = _mapInventoryMovementType(entity.type);
    status = _mapInventoryMovementStatus(entity.status);
    reason = _mapInventoryMovementReason(entity.reason);
    quantity = entity.quantity;
    unitCost = entity.unitCost;
    totalCost = entity.totalCost;
    unitPrice = entity.unitPrice;
    totalPrice = entity.totalPrice;
    lotNumber = entity.lotNumber;
    expiryDate = entity.expiryDate;
    warehouseId = entity.warehouseId;
    warehouseName = entity.warehouseName;
    referenceId = entity.referenceId;
    referenceType = entity.referenceType;
    notes = entity.notes;
    userId = entity.userId;
    userName = entity.userName;
    metadataJson = entity.metadata != null ? _encodeMetadata(entity.metadata!) : null;
    movementDate = entity.movementDate;
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  InventoryMovement toEntity() {
    return InventoryMovement(
      id: serverId,
      productId: productId,
      productName: productName,
      productSku: productSku,
      type: _mapIsarInventoryMovementType(type),
      status: _mapIsarInventoryMovementStatus(status),
      reason: _mapIsarInventoryMovementReason(reason),
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      lotNumber: lotNumber,
      expiryDate: expiryDate,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      referenceId: referenceId,
      referenceType: referenceType,
      notes: notes,
      userId: userId,
      userName: userName,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      movementDate: movementDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarInventoryMovementType _mapInventoryMovementType(InventoryMovementType type) {
    switch (type) {
      case InventoryMovementType.inbound:
        return IsarInventoryMovementType.inbound;
      case InventoryMovementType.outbound:
        return IsarInventoryMovementType.outbound;
      case InventoryMovementType.adjustment:
        return IsarInventoryMovementType.adjustment;
      case InventoryMovementType.transfer:
        return IsarInventoryMovementType.transfer;
      case InventoryMovementType.transferIn:
        return IsarInventoryMovementType.transferIn;
      case InventoryMovementType.transferOut:
        return IsarInventoryMovementType.transferOut;
    }
  }

  static InventoryMovementType _mapIsarInventoryMovementType(IsarInventoryMovementType type) {
    switch (type) {
      case IsarInventoryMovementType.inbound:
        return InventoryMovementType.inbound;
      case IsarInventoryMovementType.outbound:
        return InventoryMovementType.outbound;
      case IsarInventoryMovementType.adjustment:
        return InventoryMovementType.adjustment;
      case IsarInventoryMovementType.transfer:
        return InventoryMovementType.transfer;
      case IsarInventoryMovementType.transferIn:
        return InventoryMovementType.transferIn;
      case IsarInventoryMovementType.transferOut:
        return InventoryMovementType.transferOut;
    }
  }

  static IsarInventoryMovementStatus _mapInventoryMovementStatus(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return IsarInventoryMovementStatus.pending;
      case InventoryMovementStatus.confirmed:
        return IsarInventoryMovementStatus.confirmed;
      case InventoryMovementStatus.cancelled:
        return IsarInventoryMovementStatus.cancelled;
    }
  }

  static InventoryMovementStatus _mapIsarInventoryMovementStatus(IsarInventoryMovementStatus status) {
    switch (status) {
      case IsarInventoryMovementStatus.pending:
        return InventoryMovementStatus.pending;
      case IsarInventoryMovementStatus.confirmed:
        return InventoryMovementStatus.confirmed;
      case IsarInventoryMovementStatus.cancelled:
        return InventoryMovementStatus.cancelled;
    }
  }

  static IsarInventoryMovementReason _mapInventoryMovementReason(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.purchase:
        return IsarInventoryMovementReason.purchase;
      case InventoryMovementReason.sale:
        return IsarInventoryMovementReason.sale;
      case InventoryMovementReason.adjustment:
        return IsarInventoryMovementReason.adjustment;
      case InventoryMovementReason.damage:
        return IsarInventoryMovementReason.damage;
      case InventoryMovementReason.loss:
        return IsarInventoryMovementReason.loss;
      case InventoryMovementReason.transfer:
        return IsarInventoryMovementReason.transfer;
      case InventoryMovementReason.return_:
        return IsarInventoryMovementReason.returnGoods;
      case InventoryMovementReason.expiration:
        return IsarInventoryMovementReason.expiration;
    }
  }

  static InventoryMovementReason _mapIsarInventoryMovementReason(IsarInventoryMovementReason reason) {
    switch (reason) {
      case IsarInventoryMovementReason.purchase:
        return InventoryMovementReason.purchase;
      case IsarInventoryMovementReason.sale:
        return InventoryMovementReason.sale;
      case IsarInventoryMovementReason.adjustment:
        return InventoryMovementReason.adjustment;
      case IsarInventoryMovementReason.damage:
        return InventoryMovementReason.damage;
      case IsarInventoryMovementReason.loss:
        return InventoryMovementReason.loss;
      case IsarInventoryMovementReason.transfer:
        return InventoryMovementReason.transfer;
      case IsarInventoryMovementReason.returnGoods:
        return InventoryMovementReason.return_;
      case IsarInventoryMovementReason.expiration:
        return InventoryMovementReason.expiration;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return '{}';
    try {
      return jsonEncode(metadata);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _decodeMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty || metadataJson == '{}') {
      return {};
    }
    try {
      final decoded = jsonDecode(metadataJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get needsSync => !isSynced;
  bool get isInbound => type == IsarInventoryMovementType.inbound || type == IsarInventoryMovementType.transferIn;
  bool get isOutbound => type == IsarInventoryMovementType.outbound || type == IsarInventoryMovementType.transferOut;
  bool get isPending => status == IsarInventoryMovementStatus.pending;
  bool get isConfirmed => status == IsarInventoryMovementStatus.confirmed;

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

  bool hasConflictWith(IsarInventoryMovement serverVersion) {
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
    return 'IsarInventoryMovement{serverId: $serverId, productName: $productName, type: $type, quantity: $quantity, version: $version, isSynced: $isSynced}';
  }
}
