// lib/features/invoices/data/models/isar/isar_invoice.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
import 'package:isar/isar.dart';

part 'isar_invoice.g.dart';

@collection
class IsarInvoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index(unique: true)
  late String number;

  @Index()
  late DateTime date;

  @Index()
  late DateTime dueDate;

  @Index()
  @Enumerated(EnumType.name)
  late IsarInvoiceStatus status;

  @Enumerated(EnumType.name)
  late IsarPaymentMethod paymentMethod;

  // Cálculos financieros
  late double subtotal;
  late double taxPercentage;
  late double taxAmount;
  late double discountPercentage;
  late double discountAmount;
  late double total;
  late double paidAmount;
  late double balanceDue;

  String? notes;
  String? terms;
  String? metadataJson;

  // Items y Payments como JSON (para preservar datos offline)
  String? itemsJson;
  String? paymentsJson;

  // Foreign Keys
  @Index()
  late String customerId;

  String? createdById;

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
  IsarInvoice();

  IsarInvoice.create({
    required this.serverId,
    required this.number,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.total,
    required this.paidAmount,
    required this.balanceDue,
    this.notes,
    this.terms,
    this.metadataJson,
    this.itemsJson,
    this.paymentsJson,
    required this.customerId,
    this.createdById,
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
  static IsarInvoice fromEntity(Invoice entity) {
    return IsarInvoice.create(
      serverId: entity.id,
      number: entity.number,
      date: entity.date,
      dueDate: entity.dueDate,
      status: _mapInvoiceStatus(entity.status),
      paymentMethod: _mapPaymentMethod(entity.paymentMethod),
      subtotal: entity.subtotal,
      taxPercentage: entity.taxPercentage,
      taxAmount: entity.taxAmount,
      discountPercentage: entity.discountPercentage,
      discountAmount: entity.discountAmount,
      total: entity.total,
      paidAmount: entity.paidAmount,
      balanceDue: entity.balanceDue,
      notes: entity.notes,
      terms: entity.terms,
      metadataJson:
          entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      itemsJson: _encodeItems(entity.items),
      paymentsJson: encodePayments(entity.payments),
      customerId: entity.customerId,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create IsarInvoice from InvoiceModel (for caching server data)
  static IsarInvoice fromModel(dynamic model) {
    return IsarInvoice.create(
      serverId: model.id,
      number: model.number,
      date: model.date,
      dueDate: model.dueDate,
      status: _mapInvoiceStatus(model.status),
      paymentMethod: _mapPaymentMethod(model.paymentMethod),
      subtotal: model.subtotal,
      taxPercentage: model.taxPercentage,
      taxAmount: model.taxAmount,
      discountPercentage: model.discountPercentage,
      discountAmount: model.discountAmount,
      total: model.total,
      paidAmount: model.paidAmount,
      balanceDue: model.balanceDue,
      notes: model.notes,
      terms: model.terms,
      metadataJson:
          model.metadata != null ? _encodeMetadata(model.metadata!) : null,
      itemsJson: model.items != null ? _encodeItemsFromModel(model.items) : null,
      paymentsJson: model.payments != null ? _encodePaymentsFromModel(model.payments) : null,
      customerId: model.customerId,
      createdById: model.createdById,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Update existing IsarInvoice from InvoiceModel
  void updateFromModel(dynamic model) {
    serverId = model.id;
    number = model.number;
    date = model.date;
    dueDate = model.dueDate;
    status = _mapInvoiceStatus(model.status);
    paymentMethod = _mapPaymentMethod(model.paymentMethod);
    subtotal = model.subtotal;
    taxPercentage = model.taxPercentage;
    taxAmount = model.taxAmount;
    discountPercentage = model.discountPercentage;
    discountAmount = model.discountAmount;
    total = model.total;
    paidAmount = model.paidAmount;
    balanceDue = model.balanceDue;
    notes = model.notes;
    terms = model.terms;
    metadataJson = model.metadata != null ? _encodeMetadata(model.metadata!) : null;
    itemsJson = model.items != null ? _encodeItemsFromModel(model.items) : null;
    paymentsJson = model.payments != null ? _encodePaymentsFromModel(model.payments) : null;
    customerId = model.customerId;
    createdById = model.createdById;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    deletedAt = model.deletedAt;
    isSynced = true;
    lastSyncAt = DateTime.now();

    // Incrementar versión al actualizar desde servidor
    incrementVersion(modifiedBy: 'server');
  }

  Invoice toEntity() {
    return Invoice(
      id: serverId,
      number: number,
      date: date,
      dueDate: dueDate,
      status: _mapIsarInvoiceStatus(status),
      paymentMethod: _mapIsarPaymentMethod(paymentMethod),
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      total: total,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      notes: notes,
      terms: terms,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      customerId: customerId,
      createdById: createdById ?? '',
      items: _decodeItems(itemsJson),
      payments: decodePayments(paymentsJson),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarInvoiceStatus _mapInvoiceStatus(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return IsarInvoiceStatus.draft;
      case InvoiceStatus.pending:
        return IsarInvoiceStatus.pending;
      case InvoiceStatus.paid:
        return IsarInvoiceStatus.paid;
      case InvoiceStatus.overdue:
        return IsarInvoiceStatus.overdue;
      case InvoiceStatus.cancelled:
        return IsarInvoiceStatus.cancelled;
      case InvoiceStatus.partiallyPaid:
        return IsarInvoiceStatus.partiallyPaid;
      case InvoiceStatus.credited:
        return IsarInvoiceStatus.credited;
      case InvoiceStatus.partiallyCredited:
        return IsarInvoiceStatus.partiallyCredited;
    }
  }

  static InvoiceStatus _mapIsarInvoiceStatus(IsarInvoiceStatus status) {
    switch (status) {
      case IsarInvoiceStatus.draft:
        return InvoiceStatus.draft;
      case IsarInvoiceStatus.pending:
        return InvoiceStatus.pending;
      case IsarInvoiceStatus.paid:
        return InvoiceStatus.paid;
      case IsarInvoiceStatus.overdue:
        return InvoiceStatus.overdue;
      case IsarInvoiceStatus.cancelled:
        return InvoiceStatus.cancelled;
      case IsarInvoiceStatus.partiallyPaid:
        return InvoiceStatus.partiallyPaid;
      case IsarInvoiceStatus.credited:
        return InvoiceStatus.credited;
      case IsarInvoiceStatus.partiallyCredited:
        return InvoiceStatus.partiallyCredited;
    }
  }

  static IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.credit:
        return IsarPaymentMethod.credit;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.clientBalance:
        return IsarPaymentMethod.clientBalance;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
    }
  }

  static PaymentMethod _mapIsarPaymentMethod(IsarPaymentMethod method) {
    switch (method) {
      case IsarPaymentMethod.cash:
        return PaymentMethod.cash;
      case IsarPaymentMethod.credit:
        return PaymentMethod.credit;
      case IsarPaymentMethod.creditCard:
        return PaymentMethod.creditCard;
      case IsarPaymentMethod.debitCard:
        return PaymentMethod.debitCard;
      case IsarPaymentMethod.bankTransfer:
        return PaymentMethod.bankTransfer;
      case IsarPaymentMethod.check:
        return PaymentMethod.check;
      case IsarPaymentMethod.clientBalance:
        return PaymentMethod.clientBalance;
      case IsarPaymentMethod.other:
        return PaymentMethod.other;
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

  // Helpers para items
  static String _encodeItems(List<InvoiceItem>? items) {
    if (items == null || items.isEmpty) return '[]';
    try {
      final list = items.map((item) => {
        'id': item.id,
        'description': item.description,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'discountPercentage': item.discountPercentage,
        'discountAmount': item.discountAmount,
        'subtotal': item.subtotal,
        'unit': item.unit,
        'notes': item.notes,
        'invoiceId': item.invoiceId,
        'productId': item.productId,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      }).toList();
      return jsonEncode(list);
    } catch (e) {
      return '[]';
    }
  }

  static String? _encodeItemsFromModel(dynamic items) {
    if (items == null) return null;
    if (items is List) {
      try {
        final list = items.map((item) {
          if (item is Map) {
            return item;
          }
          // Si es un modelo, extraer sus propiedades
          return {
            'id': item.id,
            'description': item.description,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'discountPercentage': item.discountPercentage,
            'discountAmount': item.discountAmount,
            'subtotal': item.subtotal,
            'unit': item.unit,
            'notes': item.notes,
            'invoiceId': item.invoiceId,
            'productId': item.productId,
            'createdAt': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updatedAt': item.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          };
        }).toList();
        return jsonEncode(list);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<InvoiceItem> _decodeItems(String? itemsJson) {
    if (itemsJson == null || itemsJson.isEmpty || itemsJson == '[]') {
      return [];
    }
    try {
      final decoded = jsonDecode(itemsJson);
      if (decoded is List) {
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return InvoiceItem(
            id: map['id'] ?? '',
            description: map['description'] ?? '',
            quantity: (map['quantity'] ?? 0).toDouble(),
            unitPrice: (map['unitPrice'] ?? 0).toDouble(),
            discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
            discountAmount: (map['discountAmount'] ?? 0).toDouble(),
            subtotal: (map['subtotal'] ?? 0).toDouble(),
            unit: map['unit'],
            notes: map['notes'],
            invoiceId: map['invoiceId'] ?? '',
            productId: map['productId'],
            createdAt: map['createdAt'] != null
                ? DateTime.parse(map['createdAt'])
                : DateTime.now(),
            updatedAt: map['updatedAt'] != null
                ? DateTime.parse(map['updatedAt'])
                : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Helpers para payments
  static String encodePayments(List<InvoicePayment>? payments) {
    if (payments == null || payments.isEmpty) return '[]';
    try {
      final list = payments.map((payment) => {
        'id': payment.id,
        'amount': payment.amount,
        'paymentMethod': payment.paymentMethod.value,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'reference': payment.reference,
        'notes': payment.notes,
        'invoiceId': payment.invoiceId,
        'createdById': payment.createdById,
        'organizationId': payment.organizationId,
        'bankAccountId': payment.bankAccountId,
        'paymentCurrency': payment.paymentCurrency,
        'paymentCurrencyAmount': payment.paymentCurrencyAmount,
        'exchangeRate': payment.exchangeRate,
        'createdAt': payment.createdAt.toIso8601String(),
        'updatedAt': payment.updatedAt.toIso8601String(),
      }).toList();
      return jsonEncode(list);
    } catch (e) {
      return '[]';
    }
  }

  static String? _encodePaymentsFromModel(dynamic payments) {
    if (payments == null) return null;
    if (payments is List) {
      try {
        final list = payments.map((payment) {
          if (payment is Map) {
            return payment;
          }
          // Si es un modelo, extraer sus propiedades
          return {
            'id': payment.id,
            'amount': payment.amount,
            'paymentMethod': payment.paymentMethod?.value ?? payment.paymentMethod ?? 'cash',
            'paymentDate': payment.paymentDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'reference': payment.reference,
            'notes': payment.notes,
            'invoiceId': payment.invoiceId,
            'createdById': payment.createdById,
            'organizationId': payment.organizationId,
            'bankAccountId': payment.bankAccountId,
            'paymentCurrency': payment.paymentCurrency,
            'paymentCurrencyAmount': payment.paymentCurrencyAmount,
            'exchangeRate': payment.exchangeRate,
            'createdAt': payment.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updatedAt': payment.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          };
        }).toList();
        return jsonEncode(list);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<InvoicePayment> decodePayments(String? paymentsJson) {
    if (paymentsJson == null || paymentsJson.isEmpty || paymentsJson == '[]') {
      return [];
    }
    try {
      final decoded = jsonDecode(paymentsJson);
      if (decoded is List) {
        return decoded.map((payment) {
          final map = payment as Map<String, dynamic>;
          return InvoicePayment(
            id: map['id'] ?? '',
            amount: (map['amount'] ?? 0).toDouble(),
            paymentMethod: PaymentMethod.fromString(map['paymentMethod'] ?? 'cash'),
            paymentDate: map['paymentDate'] != null
                ? DateTime.parse(map['paymentDate'])
                : DateTime.now(),
            reference: map['reference'],
            notes: map['notes'],
            invoiceId: map['invoiceId'] ?? '',
            createdById: map['createdById'] ?? '',
            organizationId: map['organizationId'] ?? '',
            bankAccountId: map['bankAccountId'],
            paymentCurrency: map['paymentCurrency'],
            paymentCurrencyAmount: map['paymentCurrencyAmount'] != null
                ? (map['paymentCurrencyAmount'] as num).toDouble()
                : null,
            exchangeRate: map['exchangeRate'] != null
                ? (map['exchangeRate'] as num).toDouble()
                : null,
            createdAt: map['createdAt'] != null
                ? DateTime.parse(map['createdAt'])
                : DateTime.now(),
            updatedAt: map['updatedAt'] != null
                ? DateTime.parse(map['updatedAt'])
                : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isPaid => status == IsarInvoiceStatus.paid;
  bool get isDraft => status == IsarInvoiceStatus.draft;
  bool get isOverdue =>
      status == IsarInvoiceStatus.overdue ||
      (status == IsarInvoiceStatus.pending && DateTime.now().isAfter(dueDate));
  bool get needsSync => !isSynced;
  bool get hasBalance => balanceDue > 0;

  int get daysSinceDue {
    if (isPaid) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  double get paidPercentage {
    if (total == 0) return 0;
    return (paidAmount / total * 100).clamp(0, 100);
  }

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

  void updatePayment(double paymentAmount) {
    paidAmount += paymentAmount;
    balanceDue = (total - paidAmount).clamp(0, double.infinity);

    if (balanceDue <= 0) {
      status = IsarInvoiceStatus.paid;
    } else if (paidAmount > 0) {
      status = IsarInvoiceStatus.partiallyPaid;
    }

    markAsUnsynced();
  }

  void updateStatus(IsarInvoiceStatus newStatus) {
    status = newStatus;
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
  ///
  /// Returns true si:
  /// - Ambas versiones tienen el mismo version number PERO timestamps diferentes
  /// - Indica modificaciones concurrentes que necesitan resolución
  bool hasConflictWith(IsarInvoice serverVersion) {
    // Si las versiones son iguales pero timestamps diferentes → conflicto
    if (version == serverVersion.version &&
        lastModifiedAt != null &&
        serverVersion.lastModifiedAt != null &&
        lastModifiedAt != serverVersion.lastModifiedAt) {
      return true;
    }

    // Si versión local es mayor que servidor → conflicto (cambio no sincronizado)
    if (version > serverVersion.version) {
      return true;
    }

    return false;
  }

  @override
  String toString() {
    return 'IsarInvoice{serverId: $serverId, number: $number, total: $total, status: $status, version: $version, isSynced: $isSynced}';
  }
}
