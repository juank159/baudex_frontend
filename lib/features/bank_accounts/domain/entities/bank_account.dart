// lib/features/bank_accounts/domain/entities/bank_account.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de cuenta bancaria
enum BankAccountType {
  cash('cash', 'Efectivo', Icons.money),
  savings('savings', 'Cuenta de Ahorros', Icons.savings),
  checking('checking', 'Cuenta Corriente', Icons.account_balance),
  digitalWallet('digital_wallet', 'Billetera Digital', Icons.phone_android),
  creditCard('credit_card', 'Tarjeta de Crédito', Icons.credit_card),
  debitCard('debit_card', 'Tarjeta de Débito', Icons.payment),
  other('other', 'Otro', Icons.more_horiz);

  const BankAccountType(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final IconData icon;

  static BankAccountType fromString(String value) {
    return BankAccountType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BankAccountType.other,
    );
  }
}

/// Entidad de cuenta bancaria
class BankAccount extends Equatable {
  final String id;
  final String name;
  final BankAccountType type;
  final String? bankName;
  final String? accountNumber;
  final String? holderName;
  final String? icon;
  final bool isActive;
  final bool isDefault;
  final int sortOrder;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String organizationId;
  final String? createdById;
  final String? updatedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BankAccount({
    required this.id,
    required this.name,
    required this.type,
    this.bankName,
    this.accountNumber,
    this.holderName,
    this.icon,
    required this.isActive,
    required this.isDefault,
    required this.sortOrder,
    this.description,
    this.metadata,
    required this.organizationId,
    this.createdById,
    this.updatedById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        bankName,
        accountNumber,
        holderName,
        icon,
        isActive,
        isDefault,
        sortOrder,
        description,
        metadata,
        organizationId,
        createdById,
        updatedById,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  /// Nombre para mostrar con banco
  String get displayName {
    if (bankName != null && bankName!.isNotEmpty) {
      return '$name ($bankName)';
    }
    return name;
  }

  /// Número de cuenta oculto
  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.isEmpty) return '';
    if (accountNumber!.length <= 4) return accountNumber!;
    return '****${accountNumber!.substring(accountNumber!.length - 4)}';
  }

  /// Icono del tipo de cuenta
  IconData get typeIcon => type.icon;

  /// Nombre del tipo de cuenta
  String get typeDisplayName => type.displayName;

  /// Crear copia con cambios
  BankAccount copyWith({
    String? id,
    String? name,
    BankAccountType? type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    String? description,
    Map<String, dynamic>? metadata,
    String? organizationId,
    String? createdById,
    String? updatedById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      holderName: holderName ?? this.holderName,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      organizationId: organizationId ?? this.organizationId,
      createdById: createdById ?? this.createdById,
      updatedById: updatedById ?? this.updatedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Crear entidad vacía
  factory BankAccount.empty() {
    return BankAccount(
      id: '',
      name: '',
      type: BankAccountType.cash,
      isActive: true,
      isDefault: false,
      sortOrder: 0,
      organizationId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
