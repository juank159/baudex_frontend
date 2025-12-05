// lib/features/expenses/data/models/isar/isar_expense.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/expenses/domain/entities/expense.dart';
import 'package:isar/isar.dart';

part 'isar_expense.g.dart';

@collection
class IsarExpense {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String description;

  late double amount;

  @Index()
  late DateTime date;

  @Index()
  @Enumerated(EnumType.name)
  late IsarExpenseStatus status;

  @Enumerated(EnumType.name)
  late IsarExpenseType type;

  @Enumerated(EnumType.name)
  late IsarPaymentMethod paymentMethod;

  String? vendor;
  String? invoiceNumber;
  String? reference;
  String? notes;

  // Listas como JSON strings
  String? attachmentsJson; // List<String> serializado
  String? tagsJson; // List<String> serializado
  String? metadataJson; // Map<String, dynamic> serializado

  // Aprobación
  String? approvedById;
  DateTime? approvedAt;
  String? rejectionReason;

  // Foreign Keys
  @Index()
  late String categoryId;

  String? createdById;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarExpense();

  IsarExpense.create({
    required this.serverId,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    required this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachmentsJson,
    this.tagsJson,
    this.metadataJson,
    this.approvedById,
    this.approvedAt,
    this.rejectionReason,
    required this.categoryId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarExpense fromEntity(Expense entity) {
    return IsarExpense.create(
      serverId: entity.id,
      description: entity.description,
      amount: entity.amount,
      date: entity.date,
      status: _mapExpenseStatus(entity.status),
      type: _mapExpenseType(entity.type),
      paymentMethod: _mapPaymentMethod(entity.paymentMethod),
      vendor: entity.vendor,
      invoiceNumber: entity.invoiceNumber,
      reference: entity.reference,
      notes: entity.notes,
      attachmentsJson:
          entity.attachments?.isNotEmpty == true
              ? _encodeStringList(entity.attachments!)
              : null,
      tagsJson:
          entity.tags?.isNotEmpty == true
              ? _encodeStringList(entity.tags!)
              : null,
      metadataJson:
          entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      approvedById: entity.approvedById,
      approvedAt: entity.approvedAt,
      rejectionReason: entity.rejectionReason,
      categoryId: entity.categoryId,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  Expense toEntity() {
    return Expense(
      id: serverId,
      description: description,
      amount: amount,
      date: date,
      status: _mapIsarExpenseStatus(status),
      type: _mapIsarExpenseType(type),
      paymentMethod: _mapIsarPaymentMethod(paymentMethod),
      vendor: vendor,
      invoiceNumber: invoiceNumber,
      reference: reference,
      notes: notes,
      attachments:
          attachmentsJson != null ? _decodeStringList(attachmentsJson!) : null,
      tags: tagsJson != null ? _decodeStringList(tagsJson!) : null,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      approvedById: approvedById,
      approvedAt: approvedAt,
      rejectionReason: rejectionReason,
      categoryId: categoryId,
      createdById: createdById ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarExpenseStatus _mapExpenseStatus(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return IsarExpenseStatus.draft;
      case ExpenseStatus.pending:
        return IsarExpenseStatus.pending;
      case ExpenseStatus.approved:
        return IsarExpenseStatus.approved;
      case ExpenseStatus.rejected:
        return IsarExpenseStatus.rejected;
      case ExpenseStatus.paid:
        return IsarExpenseStatus.paid;
    }
  }

  static ExpenseStatus _mapIsarExpenseStatus(IsarExpenseStatus status) {
    switch (status) {
      case IsarExpenseStatus.draft:
        return ExpenseStatus.draft;
      case IsarExpenseStatus.pending:
        return ExpenseStatus.pending;
      case IsarExpenseStatus.approved:
        return ExpenseStatus.approved;
      case IsarExpenseStatus.rejected:
        return ExpenseStatus.rejected;
      case IsarExpenseStatus.paid:
        return ExpenseStatus.paid;
    }
  }

  static IsarExpenseType _mapExpenseType(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return IsarExpenseType.operating;
      case ExpenseType.administrative:
        return IsarExpenseType.administrative;
      case ExpenseType.sales:
        return IsarExpenseType.sales;
      case ExpenseType.financial:
        return IsarExpenseType.financial;
      case ExpenseType.extraordinary:
        return IsarExpenseType.extraordinary;
    }
  }

  static ExpenseType _mapIsarExpenseType(IsarExpenseType type) {
    switch (type) {
      case IsarExpenseType.operating:
        return ExpenseType.operating;
      case IsarExpenseType.administrative:
        return ExpenseType.administrative;
      case IsarExpenseType.sales:
        return ExpenseType.sales;
      case IsarExpenseType.financial:
        return ExpenseType.financial;
      case IsarExpenseType.extraordinary:
        return ExpenseType.extraordinary;
    }
  }

  static IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      // case PaymentMethod.credit:
      //   return IsarPaymentMethod.credit;
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
    }
  }

  static PaymentMethod _mapIsarPaymentMethod(IsarPaymentMethod method) {
    switch (method) {
      case IsarPaymentMethod.cash:
        return PaymentMethod.cash;
      case IsarPaymentMethod.credit:
        return PaymentMethod.other; // Fallback since credit doesn't exist in expenses
      case IsarPaymentMethod.creditCard:
        return PaymentMethod.creditCard;
      case IsarPaymentMethod.debitCard:
        return PaymentMethod.debitCard;
      case IsarPaymentMethod.bankTransfer:
        return PaymentMethod.bankTransfer;
      case IsarPaymentMethod.check:
        return PaymentMethod.check;
      case IsarPaymentMethod.clientBalance:
        return PaymentMethod.other; // Fallback since clientBalance doesn't apply to expenses
      case IsarPaymentMethod.other:
        return PaymentMethod.other;
    }
  }

  // Helpers para serialización
  static String _encodeStringList(List<String> list) {
    return list.join('|'); // Separador simple
  }

  static List<String> _decodeStringList(String json) {
    return json.split('|').where((s) => s.isNotEmpty).toList();
  }

  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadataJson) {
    return {};
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isApproved => status == IsarExpenseStatus.approved;
  bool get isPaid => status == IsarExpenseStatus.paid;
  bool get isRejected => status == IsarExpenseStatus.rejected;
  bool get isPending => status == IsarExpenseStatus.pending;
  bool get isDraft => status == IsarExpenseStatus.draft;
  bool get needsSync => !isSynced;
  bool get hasAttachments =>
      attachmentsJson != null && attachmentsJson!.isNotEmpty;
  bool get hasTags => tagsJson != null && tagsJson!.isNotEmpty;

  List<String> get attachmentsList =>
      attachmentsJson != null ? _decodeStringList(attachmentsJson!) : [];

  List<String> get tagsList =>
      tagsJson != null ? _decodeStringList(tagsJson!) : [];

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

  void approve(String approvedByUserId) {
    status = IsarExpenseStatus.approved;
    approvedById = approvedByUserId;
    approvedAt = DateTime.now();
    rejectionReason = null;
    markAsUnsynced();
  }

  void reject(String reason) {
    status = IsarExpenseStatus.rejected;
    rejectionReason = reason;
    approvedById = null;
    approvedAt = null;
    markAsUnsynced();
  }

  void markAsPaid() {
    status = IsarExpenseStatus.paid;
    markAsUnsynced();
  }

  void addAttachment(String attachmentUrl) {
    final currentAttachments = attachmentsList;
    currentAttachments.add(attachmentUrl);
    attachmentsJson = _encodeStringList(currentAttachments);
    markAsUnsynced();
  }

  void addTag(String tag) {
    final currentTags = tagsList;
    if (!currentTags.contains(tag)) {
      currentTags.add(tag);
      tagsJson = _encodeStringList(currentTags);
      markAsUnsynced();
    }
  }

  @override
  String toString() {
    return 'IsarExpense{serverId: $serverId, description: $description, amount: $amount, status: $status, isSynced: $isSynced}';
  }
}
