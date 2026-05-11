// lib/features/bank_accounts/data/models/bank_account_movement_model.dart
import '../../domain/entities/bank_account_movement.dart';

/// Parser entre JSON del backend y el dominio.
class BankAccountMovementModel extends BankAccountMovement {
  const BankAccountMovementModel({
    required super.id,
    required super.bankAccountId,
    required super.type,
    required super.amount,
    required super.balanceAfter,
    required super.movementDate,
    super.description,
    super.referenceType,
    super.referenceId,
    super.counterpartyAccountId,
    super.counterpartyMovementId,
    super.metadata,
    required super.organizationId,
    super.createdById,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory BankAccountMovementModel.fromJson(Map<String, dynamic> json) {
    return BankAccountMovementModel(
      id: json['id'] as String,
      bankAccountId: json['bankAccountId'] as String,
      type: BankAccountMovementType.fromString(
        (json['type'] as String?) ?? 'adjustment',
      ),
      amount: _parseDouble(json['amount']),
      balanceAfter: _parseDouble(json['balanceAfter']),
      movementDate: _parseDate(json['movementDate']),
      description: json['description'] as String?,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      counterpartyAccountId: json['counterpartyAccountId'] as String?,
      counterpartyMovementId: json['counterpartyMovementId'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      organizationId: json['organizationId'] as String,
      createdById: json['createdById'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      deletedAt: json['deletedAt'] != null ? _parseDate(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankAccountId': bankAccountId,
      'type': type.value,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'movementDate': movementDate.toIso8601String(),
      'description': description,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'counterpartyAccountId': counterpartyAccountId,
      'counterpartyMovementId': counterpartyMovementId,
      'metadata': metadata,
      'organizationId': organizationId,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}
