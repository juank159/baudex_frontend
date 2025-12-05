// lib/features/credit_notes/domain/entities/credit_note.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../invoices/domain/entities/invoice.dart';
import 'credit_note_item.dart';

enum CreditNoteType {
  full('full', 'Completa'),
  partial('partial', 'Parcial');

  const CreditNoteType(this.value, this.displayName);
  final String value;
  final String displayName;

  static CreditNoteType fromString(String value) {
    return CreditNoteType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CreditNoteType.partial,
    );
  }
}

enum CreditNoteReason {
  returnedGoods('returned_goods', 'Devolución de Mercancía', Icons.keyboard_return),
  damagedGoods('damaged_goods', 'Mercancía Dañada', Icons.broken_image),
  billingError('billing_error', 'Error de Facturación', Icons.error_outline),
  priceAdjustment('price_adjustment', 'Ajuste de Precio', Icons.price_change),
  orderCancellation('order_cancellation', 'Cancelación de Pedido', Icons.cancel),
  customerDissatisfaction('customer_dissatisfaction', 'Insatisfacción del Cliente', Icons.sentiment_dissatisfied),
  inventoryAdjustment('inventory_adjustment', 'Ajuste de Inventario', Icons.inventory),
  discountGranted('discount_granted', 'Descuento Otorgado', Icons.discount),
  other('other', 'Otro', Icons.more_horiz);

  const CreditNoteReason(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final IconData icon;

  static CreditNoteReason fromString(String value) {
    return CreditNoteReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => CreditNoteReason.other,
    );
  }
}

enum CreditNoteStatus {
  draft('draft', 'Borrador', Colors.grey),
  confirmed('confirmed', 'Confirmada', Colors.green),
  cancelled('cancelled', 'Cancelada', Colors.red);

  const CreditNoteStatus(this.value, this.displayName, this.color);
  final String value;
  final String displayName;
  final Color color;

  static CreditNoteStatus fromString(String value) {
    return CreditNoteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CreditNoteStatus.draft,
    );
  }
}

class CreditNote extends Equatable {
  final String id;
  final String number;
  final DateTime date;
  final CreditNoteType type;
  final CreditNoteReason reason;
  final String? reasonDescription; // Descripción adicional de la razón
  final CreditNoteStatus status;

  // Totales calculados
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double total;

  // Información adicional
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  // Inventario
  final bool restoreInventory; // ¿Restaurar inventario al confirmar?
  final bool inventoryRestored; // ¿Se ha restaurado el inventario?
  final DateTime? inventoryRestoredAt;

  // Aplicación
  final DateTime? appliedAt; // Cuándo se aplicó el crédito
  final String? appliedById;
  final User? appliedBy;

  // Relaciones
  final String invoiceId;
  final Invoice? invoice;
  final String customerId;
  final Customer? customer;
  final String createdById;
  final User? createdBy;
  final List<CreditNoteItem> items;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CreditNote({
    required this.id,
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
    this.metadata,
    this.restoreInventory = true,
    this.inventoryRestored = false,
    this.inventoryRestoredAt,
    this.appliedAt,
    this.appliedById,
    this.appliedBy,
    required this.invoiceId,
    this.invoice,
    required this.customerId,
    this.customer,
    required this.createdById,
    this.createdBy,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        number,
        date,
        type,
        reason,
        reasonDescription,
        status,
        subtotal,
        taxPercentage,
        taxAmount,
        total,
        notes,
        terms,
        metadata,
        restoreInventory,
        inventoryRestored,
        inventoryRestoredAt,
        appliedAt,
        appliedById,
        appliedBy,
        invoiceId,
        invoice,
        customerId,
        customer,
        createdById,
        createdBy,
        items,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  // Getters útiles
  bool get isDraft => status == CreditNoteStatus.draft;
  bool get isConfirmed => status == CreditNoteStatus.confirmed;
  bool get isCancelled => status == CreditNoteStatus.cancelled;

  bool get canBeEdited => status == CreditNoteStatus.draft;
  bool get canBeConfirmed => status == CreditNoteStatus.draft;
  bool get canBeCancelled => status == CreditNoteStatus.draft;
  bool get canBeDeleted => status == CreditNoteStatus.draft;

  String get statusDisplayName => status.displayName;
  String get typeDisplayName => type.displayName;
  String get reasonDisplayName => reason.displayName;
  Color get statusColor => status.color;
  IconData get reasonIcon => reason.icon;

  bool get isFullCredit => type == CreditNoteType.full;
  bool get isPartialCredit => type == CreditNoteType.partial;

  // Customer info helpers
  String get customerName {
    if (customer != null) {
      if (customer!.companyName?.isNotEmpty == true) {
        return customer!.companyName!;
      }
      return '${customer!.firstName} ${customer!.lastName}';
    }
    return 'Cliente no encontrado';
  }

  String? get customerEmail => customer?.email;
  String? get customerPhone => customer?.phone;

  // Invoice info helpers
  String get invoiceNumber => invoice?.number ?? 'N/A';
  double get invoiceTotal => invoice?.total ?? 0.0;

  CreditNote copyWith({
    String? id,
    String? number,
    DateTime? date,
    CreditNoteType? type,
    CreditNoteReason? reason,
    String? reasonDescription,
    CreditNoteStatus? status,
    double? subtotal,
    double? taxPercentage,
    double? taxAmount,
    double? total,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    bool? restoreInventory,
    bool? inventoryRestored,
    DateTime? inventoryRestoredAt,
    DateTime? appliedAt,
    String? appliedById,
    User? appliedBy,
    String? invoiceId,
    Invoice? invoice,
    String? customerId,
    Customer? customer,
    String? createdById,
    User? createdBy,
    List<CreditNoteItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CreditNote(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      reasonDescription: reasonDescription ?? this.reasonDescription,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      restoreInventory: restoreInventory ?? this.restoreInventory,
      inventoryRestored: inventoryRestored ?? this.inventoryRestored,
      inventoryRestoredAt: inventoryRestoredAt ?? this.inventoryRestoredAt,
      appliedAt: appliedAt ?? this.appliedAt,
      appliedById: appliedById ?? this.appliedById,
      appliedBy: appliedBy ?? this.appliedBy,
      invoiceId: invoiceId ?? this.invoiceId,
      invoice: invoice ?? this.invoice,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory CreditNote.empty() {
    return CreditNote(
      id: '',
      number: '',
      date: DateTime.now(),
      type: CreditNoteType.partial,
      reason: CreditNoteReason.other,
      status: CreditNoteStatus.draft,
      subtotal: 0,
      taxPercentage: 19,
      taxAmount: 0,
      total: 0,
      invoiceId: '',
      customerId: '',
      createdById: '',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Total calculado de items
  double get totalItemsSubtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Verificar si la nota de crédito tiene items
  bool get hasItems {
    return items.isNotEmpty;
  }

  // Obtener items ordenados
  List<CreditNoteItem> get sortedItems {
    final sortedList = List<CreditNoteItem>.from(items);
    sortedList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sortedList;
  }
}

// ============================================================================
// ENTIDADES PARA CANTIDADES DISPONIBLES PARA NOTAS DE CRÉDITO
// ============================================================================

/// Información de un item de factura con sus cantidades disponibles para nota de crédito
class AvailableQuantityItem extends Equatable {
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

  const AvailableQuantityItem({
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

  @override
  List<Object?> get props => [
        invoiceItemId,
        productId,
        description,
        unit,
        unitPrice,
        originalQuantity,
        creditedQuantity,
        draftQuantity,
        availableQuantity,
        isFullyCredited,
        hasDraft,
        draftCreditNoteNumbers,
      ];

  /// Indica si hay cantidad disponible para acreditar
  bool get hasAvailableQuantity => availableQuantity > 0;

  /// Porcentaje de la cantidad original que ya fue acreditada
  double get creditedPercentage =>
      originalQuantity > 0 ? (creditedQuantity / originalQuantity) * 100 : 0;

  /// Porcentaje de la cantidad original que está en borrador
  double get draftPercentage =>
      originalQuantity > 0 ? (draftQuantity / originalQuantity) * 100 : 0;
}

/// Información resumida de una nota de crédito en borrador
class DraftCreditNoteSummary extends Equatable {
  final String id;
  final String number;
  final double total;
  final String type;
  final DateTime createdAt;

  const DraftCreditNoteSummary({
    required this.id,
    required this.number,
    required this.total,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, number, total, type, createdAt];
}

/// Respuesta completa de cantidades disponibles para crear notas de crédito
class AvailableQuantitiesResponse extends Equatable {
  final String invoiceId;
  final String invoiceNumber;
  final double invoiceTotal;
  final double remainingCreditableAmount;
  final double totalCreditedAmount;
  final double totalDraftAmount;
  final List<AvailableQuantityItem> items;
  final List<DraftCreditNoteSummary> draftCreditNotes;
  final bool canCreateFullCreditNote;
  final bool canCreatePartialCreditNote;
  final String? message;

  const AvailableQuantitiesResponse({
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

  @override
  List<Object?> get props => [
        invoiceId,
        invoiceNumber,
        invoiceTotal,
        remainingCreditableAmount,
        totalCreditedAmount,
        totalDraftAmount,
        items,
        draftCreditNotes,
        canCreateFullCreditNote,
        canCreatePartialCreditNote,
        message,
      ];

  /// Obtiene solo los items que tienen cantidad disponible para acreditar
  List<AvailableQuantityItem> get availableItems =>
      items.where((item) => item.availableQuantity > 0).toList();

  /// Verifica si hay items disponibles para crear nota de crédito
  bool get hasAvailableItems => availableItems.isNotEmpty;

  /// Verifica si hay notas de crédito en borrador pendientes
  bool get hasDraftCreditNotes => draftCreditNotes.isNotEmpty;

  /// Porcentaje del total facturado que ya fue acreditado
  double get creditedPercentage =>
      invoiceTotal > 0 ? (totalCreditedAmount / invoiceTotal) * 100 : 0;

  /// Porcentaje del total facturado que está en borrador
  double get draftPercentage =>
      invoiceTotal > 0 ? (totalDraftAmount / invoiceTotal) * 100 : 0;
}
