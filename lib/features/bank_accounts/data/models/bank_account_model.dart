// lib/features/bank_accounts/data/models/bank_account_model.dart
import '../../domain/entities/bank_account.dart';

/// Modelo de datos para BankAccount
class BankAccountModel extends BankAccount {
  const BankAccountModel({
    required super.id,
    required super.name,
    required super.type,
    super.bankName,
    super.accountNumber,
    super.holderName,
    super.icon,
    required super.isActive,
    required super.isDefault,
    required super.sortOrder,
    super.description,
    super.metadata,
    required super.organizationId,
    super.createdById,
    super.updatedById,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Crear modelo desde JSON
  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: BankAccountType.fromString(json['type'] as String? ?? 'cash'),
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      holderName: json['holderName'] as String?,
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      organizationId: json['organizationId'] as String,
      createdById: json['createdById'] as String?,
      updatedById: json['updatedById'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? _parseDateTime(json['deletedAt'])
          : null,
    );
  }

  /// Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'holderName': holderName,
      'icon': icon,
      'isActive': isActive,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'description': description,
      'metadata': metadata,
      'organizationId': organizationId,
      'createdById': createdById,
      'updatedById': updatedById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Crear modelo desde entidad
  factory BankAccountModel.fromEntity(BankAccount entity) {
    return BankAccountModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      bankName: entity.bankName,
      accountNumber: entity.accountNumber,
      holderName: entity.holderName,
      icon: entity.icon,
      isActive: entity.isActive,
      isDefault: entity.isDefault,
      sortOrder: entity.sortOrder,
      description: entity.description,
      metadata: entity.metadata,
      organizationId: entity.organizationId,
      createdById: entity.createdById,
      updatedById: entity.updatedById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Convertir a entidad
  BankAccount toEntity() {
    return BankAccount(
      id: id,
      name: name,
      type: type,
      bankName: bankName,
      accountNumber: accountNumber,
      holderName: holderName,
      icon: icon,
      isActive: isActive,
      isDefault: isDefault,
      sortOrder: sortOrder,
      description: description,
      metadata: metadata,
      organizationId: organizationId,
      createdById: createdById,
      updatedById: updatedById,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Helper para parsear fechas
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}

/// Modelo para crear cuenta bancaria
class CreateBankAccountRequest {
  final String name;
  final String type;
  final String? bankName;
  final String? accountNumber;
  final String? holderName;
  final String? icon;
  final bool isActive;
  final bool isDefault;
  final int sortOrder;
  final String? description;

  CreateBankAccountRequest({
    required this.name,
    required this.type,
    this.bankName,
    this.accountNumber,
    this.holderName,
    this.icon,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      if (bankName != null) 'bankName': bankName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (holderName != null) 'holderName': holderName,
      if (icon != null) 'icon': icon,
      'isActive': isActive,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      if (description != null) 'description': description,
    };
  }
}

/// Modelo para actualizar cuenta bancaria
class UpdateBankAccountRequest {
  final String? name;
  final String? type;
  final String? bankName;
  final String? accountNumber;
  final String? holderName;
  final String? icon;
  final bool? isActive;
  final bool? isDefault;
  final int? sortOrder;
  final String? description;

  UpdateBankAccountRequest({
    this.name,
    this.type,
    this.bankName,
    this.accountNumber,
    this.holderName,
    this.icon,
    this.isActive,
    this.isDefault,
    this.sortOrder,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (name != null) json['name'] = name;
    if (type != null) json['type'] = type;
    if (bankName != null) json['bankName'] = bankName;
    if (accountNumber != null) json['accountNumber'] = accountNumber;
    if (holderName != null) json['holderName'] = holderName;
    if (icon != null) json['icon'] = icon;
    if (isActive != null) json['isActive'] = isActive;
    if (isDefault != null) json['isDefault'] = isDefault;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (description != null) json['description'] = description;
    return json;
  }
}
