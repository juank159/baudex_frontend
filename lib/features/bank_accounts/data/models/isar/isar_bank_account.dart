// lib/features/bank_accounts/data/models/isar/isar_bank_account.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/bank_accounts/domain/entities/bank_account.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

part 'isar_bank_account.g.dart';

@collection
class IsarBankAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String name;

  @Enumerated(EnumType.name)
  late IsarBankAccountType type;

  String? bankName;
  String? accountNumber;
  String? holderName;
  String? icon;
  String? description;

  late bool isActive;
  late bool isDefault;
  late int sortOrder;

  /// Saldo actual de la cuenta. Se sincroniza desde el backend en cada
  /// PULL y se actualiza localmente cuando hay movements offline.
  /// Default 0 al inicializar para retrocompatibilidad con DB ya creada.
  late double currentBalance = 0;

  // Metadata como JSON string
  String? metadataJson;

  // Foreign Keys
  @Index()
  late String organizationId;

  String? createdById;
  String? updatedById;

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
  IsarBankAccount();

  IsarBankAccount.create({
    required this.serverId,
    required this.name,
    required this.type,
    this.bankName,
    this.accountNumber,
    this.holderName,
    this.icon,
    this.description,
    required this.isActive,
    required this.isDefault,
    required this.sortOrder,
    this.currentBalance = 0,
    this.metadataJson,
    required this.organizationId,
    this.createdById,
    this.updatedById,
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
  static IsarBankAccount fromEntity(BankAccount entity) {
    return IsarBankAccount.create(
      serverId: entity.id,
      name: entity.name,
      type: _mapBankAccountType(entity.type),
      bankName: entity.bankName,
      accountNumber: entity.accountNumber,
      holderName: entity.holderName,
      icon: entity.icon,
      description: entity.description,
      isActive: entity.isActive,
      isDefault: entity.isDefault,
      sortOrder: entity.sortOrder,
      currentBalance: entity.currentBalance,
      metadataJson: entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      organizationId: entity.organizationId,
      createdById: entity.createdById,
      updatedById: entity.updatedById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  BankAccount toEntity() {
    return BankAccount(
      id: serverId,
      name: name,
      type: _mapIsarBankAccountType(type),
      bankName: bankName,
      accountNumber: accountNumber,
      holderName: holderName,
      icon: icon,
      description: description,
      isActive: isActive,
      isDefault: isDefault,
      sortOrder: sortOrder,
      currentBalance: currentBalance,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      organizationId: organizationId,
      createdById: createdById,
      updatedById: updatedById,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarBankAccountType _mapBankAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return IsarBankAccountType.cash;
      case BankAccountType.savings:
        return IsarBankAccountType.savings;
      case BankAccountType.checking:
        return IsarBankAccountType.checking;
      case BankAccountType.digitalWallet:
        return IsarBankAccountType.digitalWallet;
      case BankAccountType.creditCard:
        return IsarBankAccountType.creditCard;
      case BankAccountType.debitCard:
        return IsarBankAccountType.debitCard;
      case BankAccountType.other:
        return IsarBankAccountType.other;
    }
  }

  static BankAccountType _mapIsarBankAccountType(IsarBankAccountType type) {
    switch (type) {
      case IsarBankAccountType.cash:
        return BankAccountType.cash;
      case IsarBankAccountType.savings:
        return BankAccountType.savings;
      case IsarBankAccountType.checking:
        return BankAccountType.checking;
      case IsarBankAccountType.digitalWallet:
        return BankAccountType.digitalWallet;
      case IsarBankAccountType.creditCard:
        return BankAccountType.creditCard;
      case IsarBankAccountType.debitCard:
        return BankAccountType.debitCard;
      case IsarBankAccountType.other:
        return BankAccountType.other;
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

  /// Actualiza los campos de esta instancia desde una entidad
  /// Mantiene el id interno de ISAR para evitar duplicados
  void updateFromEntity(BankAccount entity) {
    serverId = entity.id;
    name = entity.name;
    type = _mapBankAccountType(entity.type);
    bankName = entity.bankName;
    accountNumber = entity.accountNumber;
    holderName = entity.holderName;
    icon = entity.icon;
    description = entity.description;
    isActive = entity.isActive;
    isDefault = entity.isDefault;
    sortOrder = entity.sortOrder;
    currentBalance = entity.currentBalance;
    metadataJson = entity.metadata != null ? _encodeMetadata(entity.metadata!) : null;
    organizationId = entity.organizationId;
    createdById = entity.createdById;
    updatedById = entity.updatedById;
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
    deletedAt = entity.deletedAt;
    isSynced = true;
    lastSyncAt = DateTime.now();
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

  bool hasConflictWith(IsarBankAccount serverVersion) {
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
    return 'IsarBankAccount{serverId: $serverId, name: $name, type: $type, version: $version, isSynced: $isSynced}';
  }
}
