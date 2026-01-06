// lib/features/customer_credits/data/models/isar/isar_customer_credit.dart

import 'package:isar/isar.dart';

part 'isar_customer_credit.g.dart';

/// Modelo ISAR para CustomerCredit
/// Permite almacenamiento offline con sincronización bidireccional
@collection
class IsarCustomerCredit {
  Id id = Isar.autoIncrement; // ID local autogenerado

  /// ID del servidor (puede ser temporal si se creó offline)
  @Index(unique: true, replace: true)
  String serverId;

  /// Campos principales del crédito
  double originalAmount;
  double paidAmount;
  double balanceDue;

  @Enumerated(EnumType.name)
  IsarCreditStatus status;

  DateTime? dueDate;
  String? description;
  String? notes;

  /// Relaciones
  String customerId;
  String? customerName;
  String? invoiceId;
  String? invoiceNumber;

  /// Organización y creación
  String organizationId;
  String createdById;
  String? createdByName;

  /// Timestamps
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  /// Campos de sincronización
  bool isSynced;
  DateTime? lastSyncAt;

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  /// Metadatos serializados como JSON (para payments y datos adicionales)
  String? metadataJson;

  IsarCustomerCredit({
    this.id = Isar.autoIncrement,
    required this.serverId,
    required this.originalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.status,
    this.dueDate,
    this.description,
    this.notes,
    required this.customerId,
    this.customerName,
    this.invoiceId,
    this.invoiceNumber,
    required this.organizationId,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isSynced = false,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
    this.metadataJson,
  });

  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  bool hasConflictWith(IsarCustomerCredit serverVersion) {
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
}

/// Estado del crédito para ISAR
enum IsarCreditStatus {
  pending,
  partiallyPaid,
  paid,
  cancelled,
  overdue,
}
