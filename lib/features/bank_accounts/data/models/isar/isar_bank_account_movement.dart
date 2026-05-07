// lib/features/bank_accounts/data/models/isar/isar_bank_account_movement.dart
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../../app/data/local/enums/isar_enums.dart';
import '../../../domain/entities/bank_account_movement.dart';

part 'isar_bank_account_movement.g.dart';

/// Persistencia local de los movements de cuenta bancaria.
///
/// Replica la entidad backend para que el historial sea visible offline,
/// la pantalla de movimientos funcione sin red, y los movements creados
/// offline (depósito/retiro/transferencia) se sincronicen al volver.
@collection
class IsarBankAccountMovement {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  @Index()
  late String bankAccountId;

  @Enumerated(EnumType.name)
  late IsarBankAccountMovementType type;

  late double amount;
  late double balanceAfter;

  @Index()
  late DateTime movementDate;

  String? description;
  String? referenceType;
  String? referenceId;
  String? counterpartyAccountId;
  String? counterpartyMovementId;

  String? metadataJson;

  @Index()
  late String organizationId;

  String? createdById;

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Sync flags
  late bool isSynced;
  DateTime? lastSyncAt;

  IsarBankAccountMovement();

  IsarBankAccountMovement.create({
    required this.serverId,
    required this.bankAccountId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.movementDate,
    this.description,
    this.referenceType,
    this.referenceId,
    this.counterpartyAccountId,
    this.counterpartyMovementId,
    this.metadataJson,
    required this.organizationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  static IsarBankAccountMovement fromEntity(BankAccountMovement entity) {
    return IsarBankAccountMovement.create(
      serverId: entity.id,
      bankAccountId: entity.bankAccountId,
      type: _mapType(entity.type),
      amount: entity.amount,
      balanceAfter: entity.balanceAfter,
      movementDate: entity.movementDate,
      description: entity.description,
      referenceType: entity.referenceType,
      referenceId: entity.referenceId,
      counterpartyAccountId: entity.counterpartyAccountId,
      counterpartyMovementId: entity.counterpartyMovementId,
      metadataJson:
          entity.metadata != null ? jsonEncode(entity.metadata) : null,
      organizationId: entity.organizationId,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  BankAccountMovement toEntity() {
    Map<String, dynamic>? meta;
    if (metadataJson != null && metadataJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(metadataJson!);
        if (decoded is Map<String, dynamic>) meta = decoded;
      } catch (_) {}
    }
    return BankAccountMovement(
      id: serverId,
      bankAccountId: bankAccountId,
      type: _mapIsarType(type),
      amount: amount,
      balanceAfter: balanceAfter,
      movementDate: movementDate,
      description: description,
      referenceType: referenceType,
      referenceId: referenceId,
      counterpartyAccountId: counterpartyAccountId,
      counterpartyMovementId: counterpartyMovementId,
      metadata: meta,
      organizationId: organizationId,
      createdById: createdById,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  static IsarBankAccountMovementType _mapType(BankAccountMovementType t) {
    switch (t) {
      case BankAccountMovementType.initialBalance:
        return IsarBankAccountMovementType.initialBalance;
      case BankAccountMovementType.deposit:
        return IsarBankAccountMovementType.deposit;
      case BankAccountMovementType.withdrawal:
        return IsarBankAccountMovementType.withdrawal;
      case BankAccountMovementType.invoicePayment:
        return IsarBankAccountMovementType.invoicePayment;
      case BankAccountMovementType.creditPayment:
        return IsarBankAccountMovementType.creditPayment;
      case BankAccountMovementType.expensePayment:
        return IsarBankAccountMovementType.expensePayment;
      case BankAccountMovementType.transferOut:
        return IsarBankAccountMovementType.transferOut;
      case BankAccountMovementType.transferIn:
        return IsarBankAccountMovementType.transferIn;
      case BankAccountMovementType.adjustment:
        return IsarBankAccountMovementType.adjustment;
      case BankAccountMovementType.refund:
        return IsarBankAccountMovementType.refund;
    }
  }

  static BankAccountMovementType _mapIsarType(IsarBankAccountMovementType t) {
    switch (t) {
      case IsarBankAccountMovementType.initialBalance:
        return BankAccountMovementType.initialBalance;
      case IsarBankAccountMovementType.deposit:
        return BankAccountMovementType.deposit;
      case IsarBankAccountMovementType.withdrawal:
        return BankAccountMovementType.withdrawal;
      case IsarBankAccountMovementType.invoicePayment:
        return BankAccountMovementType.invoicePayment;
      case IsarBankAccountMovementType.creditPayment:
        return BankAccountMovementType.creditPayment;
      case IsarBankAccountMovementType.expensePayment:
        return BankAccountMovementType.expensePayment;
      case IsarBankAccountMovementType.transferOut:
        return BankAccountMovementType.transferOut;
      case IsarBankAccountMovementType.transferIn:
        return BankAccountMovementType.transferIn;
      case IsarBankAccountMovementType.adjustment:
        return BankAccountMovementType.adjustment;
      case IsarBankAccountMovementType.refund:
        return BankAccountMovementType.refund;
    }
  }
}
