// lib/features/invoices/data/models/isar/isar_invoice.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
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
    required this.customerId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
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
      customerId: entity.customerId,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
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
      items: [], // Se cargarán por separado
      payments: [], // Se cargarán por separado
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
    }
  }

  static IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
      default:
        return IsarPaymentMethod.other;
    }
  }

  static PaymentMethod _mapIsarPaymentMethod(IsarPaymentMethod method) {
    switch (method) {
      case IsarPaymentMethod.cash:
        return PaymentMethod.cash;
      case IsarPaymentMethod.credit:
        return PaymentMethod.other; // Fallback since credit doesn't exist
      case IsarPaymentMethod.creditCard:
        return PaymentMethod.creditCard;
      case IsarPaymentMethod.debitCard:
        return PaymentMethod.debitCard;
      case IsarPaymentMethod.bankTransfer:
        return PaymentMethod.bankTransfer;
      case IsarPaymentMethod.check:
        return PaymentMethod.check;
      case IsarPaymentMethod.other:
        return PaymentMethod.other;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadataJson) {
    return {};
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

  @override
  String toString() {
    return 'IsarInvoice{serverId: $serverId, number: $number, total: $total, status: $status, isSynced: $isSynced}';
  }
}
