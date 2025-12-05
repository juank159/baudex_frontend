// lib/features/credit_notes/data/models/credit_note_model.dart
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../invoices/data/models/invoice_model.dart';
import 'credit_note_item_model.dart';

/// Helper para parsear valores numéricos que pueden venir como String o num
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class CreditNoteModel extends CreditNote {
  const CreditNoteModel({
    required super.id,
    required super.number,
    required super.date,
    required super.type,
    required super.reason,
    super.reasonDescription,
    required super.status,
    required super.subtotal,
    required super.taxPercentage,
    required super.taxAmount,
    required super.total,
    super.notes,
    super.terms,
    super.metadata,
    super.restoreInventory,
    super.inventoryRestored,
    super.inventoryRestoredAt,
    super.appliedAt,
    super.appliedById,
    super.appliedBy,
    required super.invoiceId,
    super.invoice,
    required super.customerId,
    super.customer,
    required super.createdById,
    super.createdBy,
    required super.items,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) {
    // Debug: Imprimir el JSON recibido para diagnosticar problemas
    print('🔍 CreditNoteModel.fromJson: ${json.keys.toList()}');

    // Verificar campos requeridos
    final id = json['id'];
    final number = json['number'];
    final invoiceId = json['invoiceId'];
    final customerId = json['customerId'];
    final createdById = json['createdById'];

    if (id == null || number == null) {
      print('⚠️ Campos básicos nulos - id: $id, number: $number');
    }
    if (invoiceId == null || customerId == null || createdById == null) {
      print('⚠️ Campos de relación nulos - invoiceId: $invoiceId, customerId: $customerId, createdById: $createdById');
    }

    return CreditNoteModel(
      id: (id as String?) ?? '',
      number: (number as String?) ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      type: CreditNoteType.fromString((json['type'] as String?) ?? 'PARTIAL'),
      reason: CreditNoteReason.fromString((json['reason'] as String?) ?? 'OTHER'),
      reasonDescription: json['reasonDescription'] as String?,
      status: CreditNoteStatus.fromString((json['status'] as String?) ?? 'DRAFT'),
      subtotal: _parseDouble(json['subtotal']),
      taxPercentage: _parseDouble(json['taxPercentage'], 19.0),
      taxAmount: _parseDouble(json['taxAmount']),
      total: _parseDouble(json['total']),
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      restoreInventory: json['restoreInventory'] as bool? ?? true,
      inventoryRestored: json['inventoryRestored'] as bool? ?? false,
      inventoryRestoredAt: json['inventoryRestoredAt'] != null
          ? DateTime.parse(json['inventoryRestoredAt'] as String)
          : null,
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'] as String)
          : null,
      appliedById: json['appliedById'] as String?,
      appliedBy: json['appliedBy'] != null
          ? UserModel.fromJson(json['appliedBy'] as Map<String, dynamic>)
          : null,
      invoiceId: (invoiceId as String?) ?? '',
      invoice: json['invoice'] != null
          ? InvoiceModel.fromJson(json['invoice'] as Map<String, dynamic>)
          : null,
      customerId: (customerId as String?) ?? '',
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      createdById: (createdById as String?) ?? '',
      createdBy: json['createdBy'] != null
          ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CreditNoteItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'date': date.toIso8601String(),
      'type': type.value,
      'reason': reason.value,
      'reasonDescription': reasonDescription,
      'status': status.value,
      'subtotal': subtotal,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'total': total,
      'notes': notes,
      'terms': terms,
      'metadata': metadata,
      'restoreInventory': restoreInventory,
      'inventoryRestored': inventoryRestored,
      'inventoryRestoredAt': inventoryRestoredAt?.toIso8601String(),
      'appliedAt': appliedAt?.toIso8601String(),
      'appliedById': appliedById,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'createdById': createdById,
      'items': items.map((item) => CreditNoteItemModel.fromEntity(item).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory CreditNoteModel.fromEntity(CreditNote entity) {
    return CreditNoteModel(
      id: entity.id,
      number: entity.number,
      date: entity.date,
      type: entity.type,
      reason: entity.reason,
      reasonDescription: entity.reasonDescription,
      status: entity.status,
      subtotal: entity.subtotal,
      taxPercentage: entity.taxPercentage,
      taxAmount: entity.taxAmount,
      total: entity.total,
      notes: entity.notes,
      terms: entity.terms,
      metadata: entity.metadata,
      restoreInventory: entity.restoreInventory,
      inventoryRestored: entity.inventoryRestored,
      inventoryRestoredAt: entity.inventoryRestoredAt,
      appliedAt: entity.appliedAt,
      appliedById: entity.appliedById,
      appliedBy: entity.appliedBy,
      invoiceId: entity.invoiceId,
      invoice: entity.invoice,
      customerId: entity.customerId,
      customer: entity.customer,
      createdById: entity.createdById,
      createdBy: entity.createdBy,
      items: entity.items,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}

// Request model para crear nota de crédito
// NOTA: El backend no acepta date, taxPercentage, number ni metadata en creación
// Estos campos son calculados/asignados automáticamente por el backend
class CreateCreditNoteRequestModel {
  final String invoiceId;
  final String type;
  final String reason;
  final String? reasonDescription;
  final List<CreateCreditNoteItemRequestModel> items;
  final bool restoreInventory;
  final String? notes;
  final String? terms;

  const CreateCreditNoteRequestModel({
    required this.invoiceId,
    required this.type,
    required this.reason,
    this.reasonDescription,
    required this.items,
    this.restoreInventory = true,
    this.notes,
    this.terms,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'type': type,
      'reason': reason,
      if (reasonDescription != null) 'reasonDescription': reasonDescription,
      'items': items.map((item) => item.toJson()).toList(),
      'restoreInventory': restoreInventory,
      if (notes != null) 'notes': notes,
      if (terms != null) 'terms': terms,
    };
  }

  factory CreateCreditNoteRequestModel.fromEntity(CreateCreditNoteParams params) {
    return CreateCreditNoteRequestModel(
      invoiceId: params.invoiceId,
      type: params.type.value,
      reason: params.reason.value,
      reasonDescription: params.reasonDescription,
      items: params.items
          .map((item) => CreateCreditNoteItemRequestModel.fromEntity(item))
          .toList(),
      restoreInventory: params.restoreInventory,
      notes: params.notes,
      terms: params.terms,
    );
  }
}

// Request model para actualizar nota de crédito
// NOTA: El backend solo permite actualizar reason, reasonDescription, restoreInventory, notes, terms
// Solo se pueden actualizar notas de crédito en estado DRAFT
class UpdateCreditNoteRequestModel {
  final String? reason;
  final String? reasonDescription;
  final bool? restoreInventory;
  final String? notes;
  final String? terms;

  const UpdateCreditNoteRequestModel({
    this.reason,
    this.reasonDescription,
    this.restoreInventory,
    this.notes,
    this.terms,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (reason != null) json['reason'] = reason;
    if (reasonDescription != null) json['reasonDescription'] = reasonDescription;
    if (restoreInventory != null) json['restoreInventory'] = restoreInventory;
    if (notes != null) json['notes'] = notes;
    if (terms != null) json['terms'] = terms;
    return json;
  }

  factory UpdateCreditNoteRequestModel.fromEntity(UpdateCreditNoteParams params) {
    return UpdateCreditNoteRequestModel(
      reason: params.reason?.value,
      reasonDescription: params.reasonDescription,
      restoreInventory: params.restoreInventory,
      notes: params.notes,
      terms: params.terms,
    );
  }
}

// Response model para paginación
class CreditNotePaginatedResponseModel {
  final List<CreditNoteModel> data;
  final Map<String, dynamic> meta;

  const CreditNotePaginatedResponseModel({
    required this.data,
    required this.meta,
  });

  factory CreditNotePaginatedResponseModel.fromJson(Map<String, dynamic> json) {
    return CreditNotePaginatedResponseModel(
      data: (json['data'] as List<dynamic>)
          .map((item) => CreditNoteModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] as Map<String, dynamic>,
    );
  }
}

// ============================================================================
// MODELOS PARA CANTIDADES DISPONIBLES PARA NOTAS DE CRÉDITO
// ============================================================================

/// Información de un item de factura con sus cantidades disponibles para nota de crédito
class AvailableQuantityItemModel {
  final String invoiceItemId;
  final String? productId;
  final String description;
  final String unit;
  final double unitPrice;
  final double originalQuantity;
  final double creditedQuantity;
  final double draftQuantity;
  final double availableQuantity;
  final bool isFullyCredited;
  final bool hasDraft;
  final List<String> draftCreditNoteNumbers;

  const AvailableQuantityItemModel({
    required this.invoiceItemId,
    this.productId,
    required this.description,
    required this.unit,
    required this.unitPrice,
    required this.originalQuantity,
    required this.creditedQuantity,
    required this.draftQuantity,
    required this.availableQuantity,
    required this.isFullyCredited,
    required this.hasDraft,
    required this.draftCreditNoteNumbers,
  });

  factory AvailableQuantityItemModel.fromJson(Map<String, dynamic> json) {
    return AvailableQuantityItemModel(
      invoiceItemId: json['invoiceItemId'] as String,
      productId: json['productId'] as String?,
      description: json['description'] as String,
      unit: json['unit'] as String? ?? 'und',
      unitPrice: _parseDouble(json['unitPrice']),
      originalQuantity: _parseDouble(json['originalQuantity']),
      creditedQuantity: _parseDouble(json['creditedQuantity']),
      draftQuantity: _parseDouble(json['draftQuantity']),
      availableQuantity: _parseDouble(json['availableQuantity']),
      isFullyCredited: json['isFullyCredited'] as bool? ?? false,
      hasDraft: json['hasDraft'] as bool? ?? false,
      draftCreditNoteNumbers: (json['draftCreditNoteNumbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Información resumida de una nota de crédito en borrador
class DraftCreditNoteSummaryModel {
  final String id;
  final String number;
  final double total;
  final String type;
  final DateTime createdAt;

  const DraftCreditNoteSummaryModel({
    required this.id,
    required this.number,
    required this.total,
    required this.type,
    required this.createdAt,
  });

  factory DraftCreditNoteSummaryModel.fromJson(Map<String, dynamic> json) {
    return DraftCreditNoteSummaryModel(
      id: json['id'] as String,
      number: json['number'] as String,
      total: _parseDouble(json['total']),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Respuesta completa del endpoint de cantidades disponibles
class AvailableQuantitiesResponseModel {
  final String invoiceId;
  final String invoiceNumber;
  final double invoiceTotal;
  final double remainingCreditableAmount;
  final double totalCreditedAmount;
  final double totalDraftAmount;
  final List<AvailableQuantityItemModel> items;
  final List<DraftCreditNoteSummaryModel> draftCreditNotes;
  final bool canCreateFullCreditNote;
  final bool canCreatePartialCreditNote;
  final String? message;

  const AvailableQuantitiesResponseModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceTotal,
    required this.remainingCreditableAmount,
    required this.totalCreditedAmount,
    required this.totalDraftAmount,
    required this.items,
    required this.draftCreditNotes,
    required this.canCreateFullCreditNote,
    required this.canCreatePartialCreditNote,
    this.message,
  });

  factory AvailableQuantitiesResponseModel.fromJson(Map<String, dynamic> json) {
    return AvailableQuantitiesResponseModel(
      invoiceId: json['invoiceId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceTotal: _parseDouble(json['invoiceTotal']),
      remainingCreditableAmount: _parseDouble(json['remainingCreditableAmount']),
      totalCreditedAmount: _parseDouble(json['totalCreditedAmount']),
      totalDraftAmount: _parseDouble(json['totalDraftAmount']),
      items: (json['items'] as List<dynamic>)
          .map((item) => AvailableQuantityItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      draftCreditNotes: (json['draftCreditNotes'] as List<dynamic>?)
              ?.map((item) => DraftCreditNoteSummaryModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      canCreateFullCreditNote: json['canCreateFullCreditNote'] as bool? ?? false,
      canCreatePartialCreditNote: json['canCreatePartialCreditNote'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  /// Obtiene solo los items que tienen cantidad disponible para acreditar
  List<AvailableQuantityItemModel> get availableItems =>
      items.where((item) => item.availableQuantity > 0).toList();

  /// Verifica si hay items disponibles para crear nota de crédito
  bool get hasAvailableItems => availableItems.isNotEmpty;

  /// Verifica si hay notas de crédito en borrador pendientes
  bool get hasDraftCreditNotes => draftCreditNotes.isNotEmpty;
}
