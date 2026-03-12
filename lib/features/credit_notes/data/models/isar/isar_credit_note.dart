// lib/features/credit_notes/data/models/isar/isar_credit_note.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note_item.dart';
import 'package:isar/isar.dart';

part 'isar_credit_note.g.dart';

@collection
class IsarCreditNote {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index(unique: true)
  late String number;

  @Index()
  late DateTime date;

  @Index()
  @Enumerated(EnumType.name)
  late IsarCreditNoteType type;

  @Enumerated(EnumType.name)
  late IsarCreditNoteReason reason;

  String? reasonDescription;

  @Index()
  @Enumerated(EnumType.name)
  late IsarCreditNoteStatus status;

  // Totales calculados
  late double subtotal;
  late double taxPercentage;
  late double taxAmount;
  late double total;

  // Información adicional
  String? notes;
  String? terms;
  String? metadataJson;

  // Inventario
  late bool restoreInventory;
  late bool inventoryRestored;
  DateTime? inventoryRestoredAt;

  // Aplicación
  DateTime? appliedAt;
  String? appliedById;

  // Foreign Keys
  @Index()
  late String invoiceId;

  @Index()
  late String customerId;

  late String createdById;

  // Items (almacenados como JSON string embebido)
  String? itemsJson;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version; // Versión del documento (incrementa con cada cambio)
  DateTime? lastModifiedAt; // Timestamp del último cambio
  String? lastModifiedBy; // Usuario que hizo el último cambio

  // Constructores
  IsarCreditNote();

  IsarCreditNote.create({
    required this.serverId,
    required this.number,
    required this.date,
    required this.type,
    required this.reason,
    this.reasonDescription,
    required this.status,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.terms,
    this.metadataJson,
    required this.restoreInventory,
    required this.inventoryRestored,
    this.inventoryRestoredAt,
    this.appliedAt,
    this.appliedById,
    required this.invoiceId,
    required this.customerId,
    required this.createdById,
    this.itemsJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0, // ⭐ Inicializar versión en 0
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // Mappers
  static IsarCreditNote fromEntity(CreditNote entity) {
    return IsarCreditNote.create(
      serverId: entity.id,
      number: entity.number,
      date: entity.date,
      type: _mapCreditNoteType(entity.type),
      reason: _mapCreditNoteReason(entity.reason),
      reasonDescription: entity.reasonDescription,
      status: _mapCreditNoteStatus(entity.status),
      subtotal: entity.subtotal,
      taxPercentage: entity.taxPercentage,
      taxAmount: entity.taxAmount,
      total: entity.total,
      notes: entity.notes,
      terms: entity.terms,
      metadataJson: entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      restoreInventory: entity.restoreInventory,
      inventoryRestored: entity.inventoryRestored,
      inventoryRestoredAt: entity.inventoryRestoredAt,
      appliedAt: entity.appliedAt,
      appliedById: entity.appliedById,
      invoiceId: entity.invoiceId,
      customerId: entity.customerId,
      createdById: entity.createdById,
      itemsJson: _encodeItems(entity.items),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create IsarCreditNote from CreditNoteModel (for caching server data)
  static IsarCreditNote fromModel(dynamic model) {
    return IsarCreditNote.create(
      serverId: model.id,
      number: model.number,
      date: model.date,
      type: _mapCreditNoteType(model.type),
      reason: _mapCreditNoteReason(model.reason),
      reasonDescription: model.reasonDescription,
      status: _mapCreditNoteStatus(model.status),
      subtotal: model.subtotal,
      taxPercentage: model.taxPercentage,
      taxAmount: model.taxAmount,
      total: model.total,
      notes: model.notes,
      terms: model.terms,
      metadataJson: model.metadata != null ? _encodeMetadata(model.metadata!) : null,
      restoreInventory: model.restoreInventory,
      inventoryRestored: model.inventoryRestored,
      inventoryRestoredAt: model.inventoryRestoredAt,
      appliedAt: model.appliedAt,
      appliedById: model.appliedById,
      invoiceId: model.invoiceId,
      customerId: model.customerId,
      createdById: model.createdById,
      itemsJson: _encodeItems(model.items),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Update existing IsarCreditNote from CreditNoteModel
  void updateFromModel(dynamic model) {
    serverId = model.id;
    number = model.number;
    date = model.date;
    type = _mapCreditNoteType(model.type);
    reason = _mapCreditNoteReason(model.reason);
    reasonDescription = model.reasonDescription;
    status = _mapCreditNoteStatus(model.status);
    subtotal = model.subtotal;
    taxPercentage = model.taxPercentage;
    taxAmount = model.taxAmount;
    total = model.total;
    notes = model.notes;
    terms = model.terms;
    metadataJson = model.metadata != null ? _encodeMetadata(model.metadata!) : null;
    restoreInventory = model.restoreInventory;
    inventoryRestored = model.inventoryRestored;
    inventoryRestoredAt = model.inventoryRestoredAt;
    appliedAt = model.appliedAt;
    appliedById = model.appliedById;
    invoiceId = model.invoiceId;
    customerId = model.customerId;
    createdById = model.createdById;
    itemsJson = _encodeItems(model.items);
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    deletedAt = model.deletedAt;
    isSynced = true;
    lastSyncAt = DateTime.now();

    // ⭐ FASE 1: Incrementar versión al actualizar desde servidor
    incrementVersion(modifiedBy: 'server');
  }

  CreditNote toEntity() {
    return CreditNote(
      id: serverId,
      number: number,
      date: date,
      type: _mapIsarCreditNoteType(type),
      reason: _mapIsarCreditNoteReason(reason),
      reasonDescription: reasonDescription,
      status: _mapIsarCreditNoteStatus(status),
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      total: total,
      notes: notes,
      terms: terms,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      restoreInventory: restoreInventory,
      inventoryRestored: inventoryRestored,
      inventoryRestoredAt: inventoryRestoredAt,
      appliedAt: appliedAt,
      appliedById: appliedById,
      invoiceId: invoiceId,
      customerId: customerId,
      createdById: createdById,
      items: itemsJson != null ? _decodeItems(itemsJson!) : [],
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums - Type
  static IsarCreditNoteType _mapCreditNoteType(CreditNoteType type) {
    switch (type) {
      case CreditNoteType.full:
        return IsarCreditNoteType.full;
      case CreditNoteType.partial:
        return IsarCreditNoteType.partial;
    }
  }

  static CreditNoteType _mapIsarCreditNoteType(IsarCreditNoteType type) {
    switch (type) {
      case IsarCreditNoteType.full:
        return CreditNoteType.full;
      case IsarCreditNoteType.partial:
        return CreditNoteType.partial;
    }
  }

  // Helpers para mapeo de enums - Status
  static IsarCreditNoteStatus _mapCreditNoteStatus(CreditNoteStatus status) {
    switch (status) {
      case CreditNoteStatus.draft:
        return IsarCreditNoteStatus.draft;
      case CreditNoteStatus.confirmed:
        return IsarCreditNoteStatus.confirmed;
      case CreditNoteStatus.cancelled:
        return IsarCreditNoteStatus.cancelled;
    }
  }

  static CreditNoteStatus _mapIsarCreditNoteStatus(IsarCreditNoteStatus status) {
    switch (status) {
      case IsarCreditNoteStatus.draft:
        return CreditNoteStatus.draft;
      case IsarCreditNoteStatus.confirmed:
        return CreditNoteStatus.confirmed;
      case IsarCreditNoteStatus.cancelled:
        return CreditNoteStatus.cancelled;
    }
  }

  // Helpers para mapeo de enums - Reason
  static IsarCreditNoteReason _mapCreditNoteReason(CreditNoteReason reason) {
    switch (reason) {
      case CreditNoteReason.returnedGoods:
        return IsarCreditNoteReason.returnedGoods;
      case CreditNoteReason.damagedGoods:
        return IsarCreditNoteReason.damagedGoods;
      case CreditNoteReason.billingError:
        return IsarCreditNoteReason.billingError;
      case CreditNoteReason.priceAdjustment:
        return IsarCreditNoteReason.priceAdjustment;
      case CreditNoteReason.orderCancellation:
        return IsarCreditNoteReason.orderCancellation;
      case CreditNoteReason.customerDissatisfaction:
        return IsarCreditNoteReason.customerDissatisfaction;
      case CreditNoteReason.inventoryAdjustment:
        return IsarCreditNoteReason.inventoryAdjustment;
      case CreditNoteReason.discountGranted:
        return IsarCreditNoteReason.discountGranted;
      case CreditNoteReason.other:
        return IsarCreditNoteReason.other;
    }
  }

  static CreditNoteReason _mapIsarCreditNoteReason(IsarCreditNoteReason reason) {
    switch (reason) {
      case IsarCreditNoteReason.returnedGoods:
        return CreditNoteReason.returnedGoods;
      case IsarCreditNoteReason.damagedGoods:
        return CreditNoteReason.damagedGoods;
      case IsarCreditNoteReason.billingError:
        return CreditNoteReason.billingError;
      case IsarCreditNoteReason.priceAdjustment:
        return CreditNoteReason.priceAdjustment;
      case IsarCreditNoteReason.orderCancellation:
        return CreditNoteReason.orderCancellation;
      case IsarCreditNoteReason.customerDissatisfaction:
        return CreditNoteReason.customerDissatisfaction;
      case IsarCreditNoteReason.inventoryAdjustment:
        return CreditNoteReason.inventoryAdjustment;
      case IsarCreditNoteReason.discountGranted:
        return CreditNoteReason.discountGranted;
      case IsarCreditNoteReason.other:
        return CreditNoteReason.other;
    }
  }

  // Helpers para items (embebidos como JSON)
  static String _encodeItems(List<dynamic> items) {
    final itemsData = items.map((item) => {
      'id': item.id,
      'description': item.description,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'discountPercentage': item.discountPercentage,
      'discountAmount': item.discountAmount,
      'subtotal': item.subtotal,
      'unit': item.unit,
      'notes': item.notes,
      'creditNoteId': item.creditNoteId,
      'productId': item.productId,
      'invoiceItemId': item.invoiceItemId,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
    }).toList();

    return jsonEncode(itemsData);
  }

  static List<CreditNoteItem> _decodeItems(String itemsJson) {
    try {
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      return itemsList.map((itemData) {
        return CreditNoteItem(
          id: itemData['id'] as String,
          description: itemData['description'] as String,
          quantity: (itemData['quantity'] as num).toDouble(),
          unitPrice: (itemData['unitPrice'] as num).toDouble(),
          discountPercentage: (itemData['discountPercentage'] as num).toDouble(),
          discountAmount: (itemData['discountAmount'] as num).toDouble(),
          subtotal: (itemData['subtotal'] as num).toDouble(),
          unit: itemData['unit'] as String?,
          notes: itemData['notes'] as String?,
          creditNoteId: itemData['creditNoteId'] as String,
          productId: itemData['productId'] as String?,
          invoiceItemId: itemData['invoiceItemId'] as String?,
          createdAt: DateTime.parse(itemData['createdAt'] as String),
          updatedAt: DateTime.parse(itemData['updatedAt'] as String),
        );
      }).toList();
    } catch (e) {
      // Avoid print in production, use logger instead
      return [];
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
  bool get isDraft => status == IsarCreditNoteStatus.draft;
  bool get isConfirmed => status == IsarCreditNoteStatus.confirmed;
  bool get isCancelled => status == IsarCreditNoteStatus.cancelled;
  bool get needsSync => !isSynced;
  bool get canBeEdited => status == IsarCreditNoteStatus.draft;
  bool get isFullCredit => type == IsarCreditNoteType.full;
  bool get isPartialCredit => type == IsarCreditNoteType.partial;

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

  void updateStatus(IsarCreditNoteStatus newStatus) {
    status = newStatus;
    markAsUnsynced();
  }

  void confirm() {
    status = IsarCreditNoteStatus.confirmed;
    appliedAt = DateTime.now();
    markAsUnsynced();
  }

  void cancel() {
    status = IsarCreditNoteStatus.cancelled;
    markAsUnsynced();
  }

  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos

  /// Incrementa la versión del documento y marca timestamp de modificación
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  /// Detecta si hay conflicto con otra versión del mismo documento
  bool hasConflictWith(IsarCreditNote serverVersion) {
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
    return 'IsarCreditNote{serverId: $serverId, number: $number, total: $total, status: $status, version: $version, isSynced: $isSynced}';
  }
}
