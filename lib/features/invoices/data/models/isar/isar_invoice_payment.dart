// lib/features/invoices/data/models/isar/isar_invoice_payment.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
// import 'package:isar/isar.dart';

// part 'isar_invoice_payment.g.dart';

// @collection
class IsarInvoicePayment {
  // Id id = Isar.autoIncrement;
  int id = 0;

  // @Index(unique: true)
  late String serverId;

  late double amount;

  // @Enumerated(EnumType.name)
  late IsarPaymentMethod paymentMethod;

  // @Index()
  DateTime? paymentDate;

  String? reference;
  String? notes;

  // Foreign Key
  // @Index()
  late String invoiceId;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarInvoicePayment();

  IsarInvoicePayment.create({
    required this.serverId,
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.reference,
    this.notes,
    required this.invoiceId,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarInvoicePayment fromEntity(InvoicePayment entity) {
    return IsarInvoicePayment.create(
      serverId: entity.id,
      amount: entity.amount,
      paymentMethod: _mapPaymentMethod(entity.paymentMethod),
      paymentDate: entity.paymentDate,
      reference: entity.reference,
      notes: entity.notes,
      invoiceId: entity.invoiceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  InvoicePayment toEntity() {
    return InvoicePayment(
      id: serverId,
      amount: amount,
      paymentMethod: _mapIsarPaymentMethod(paymentMethod),
      paymentDate: paymentDate ?? DateTime.now(),
      reference: reference,
      notes: notes,
      invoiceId: invoiceId,
      createdById: '', // Default value for backward compatibility
      organizationId: '', // Default value for backward compatibility
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helpers para mapeo de enums
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
      case PaymentMethod.clientBalance:
        return IsarPaymentMethod.clientBalance;
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
      case IsarPaymentMethod.clientBalance:
        return PaymentMethod.clientBalance;
      case IsarPaymentMethod.other:
        return PaymentMethod.other;
    }
  }

  // Métodos de utilidad
  bool get needsSync => !isSynced;
  bool get isProcessed => paymentDate != null;

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void processPayment() {
    paymentDate = DateTime.now();
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarInvoicePayment{serverId: $serverId, amount: $amount, method: $paymentMethod, invoiceId: $invoiceId, isSynced: $isSynced}';
  }
}
