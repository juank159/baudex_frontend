// lib/features/customer_credits/data/models/customer_credit_model.dart

import '../../domain/entities/customer_credit.dart';

/// Modelo de CustomerCredit para capa de datos
class CustomerCreditModel extends CustomerCredit {
  const CustomerCreditModel({
    required super.id,
    required super.originalAmount,
    required super.paidAmount,
    required super.balanceDue,
    required super.status,
    super.dueDate,
    super.description,
    super.notes,
    required super.customerId,
    super.customerName,
    super.invoiceId,
    super.invoiceNumber,
    required super.organizationId,
    required super.createdById,
    super.createdByName,
    super.payments,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CustomerCreditModel.fromJson(Map<String, dynamic> json) {
    // Parsear pagos si existen
    List<CreditPayment>? payments;
    if (json['payments'] != null) {
      payments = (json['payments'] as List)
          .map((p) => CreditPaymentModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // Extraer customerId de manera segura
    String customerId = '';
    if (json['customerId'] != null) {
      customerId = json['customerId'].toString();
    } else if (json['customer_id'] != null) {
      customerId = json['customer_id'].toString();
    }

    // Extraer organizationId de manera segura
    String organizationId = '';
    if (json['organizationId'] != null) {
      organizationId = json['organizationId'].toString();
    } else if (json['organization_id'] != null) {
      organizationId = json['organization_id'].toString();
    }

    // Extraer createdById de manera segura
    String createdById = '';
    if (json['createdById'] != null) {
      createdById = json['createdById'].toString();
    } else if (json['created_by_id'] != null) {
      createdById = json['created_by_id'].toString();
    }

    return CustomerCreditModel(
      id: json['id']?.toString() ?? '',
      originalAmount: _parseDouble(json['originalAmount']),
      paidAmount: _parseDouble(json['paidAmount']),
      balanceDue: _parseDouble(json['balanceDue']),
      status: CreditStatus.fromValue(json['status']?.toString() ?? 'pending'),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      description: json['description']?.toString(),
      notes: json['notes']?.toString(),
      customerId: customerId,
      customerName: json['customer']?['firstName'] != null
          ? '${json['customer']['firstName']} ${json['customer']['lastName'] ?? ''}'.trim()
          : null,
      invoiceId: json['invoiceId']?.toString() ?? json['invoice_id']?.toString(),
      invoiceNumber: json['invoice']?['number']?.toString(),
      organizationId: organizationId,
      createdById: createdById,
      createdByName: json['createdBy']?['firstName'] != null
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : null,
      payments: payments,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      deletedAt: json['deletedAt'] != null || json['deleted_at'] != null
          ? DateTime.tryParse((json['deletedAt'] ?? json['deleted_at']).toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalAmount': originalAmount,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      'status': status.value,
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
      'notes': notes,
      'customerId': customerId,
      'invoiceId': invoiceId,
      'organizationId': organizationId,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Modelo de CreditPayment para capa de datos
class CreditPaymentModel extends CreditPayment {
  const CreditPaymentModel({
    required super.id,
    required super.amount,
    required super.paymentMethod,
    required super.paymentDate,
    super.reference,
    super.notes,
    required super.creditId,
    super.bankAccountId,
    super.bankAccountName,
    required super.organizationId,
    required super.createdById,
    super.createdByName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CreditPaymentModel.fromJson(Map<String, dynamic> json) {
    // Extraer paymentMethod de manera segura
    String paymentMethod = '';
    if (json['paymentMethod'] != null) {
      paymentMethod = json['paymentMethod'].toString();
    } else if (json['payment_method'] != null) {
      paymentMethod = json['payment_method'].toString();
    }

    // Extraer creditId de manera segura
    String creditId = '';
    if (json['creditId'] != null) {
      creditId = json['creditId'].toString();
    } else if (json['credit_id'] != null) {
      creditId = json['credit_id'].toString();
    }

    // Extraer organizationId de manera segura
    String organizationId = '';
    if (json['organizationId'] != null) {
      organizationId = json['organizationId'].toString();
    } else if (json['organization_id'] != null) {
      organizationId = json['organization_id'].toString();
    }

    // Extraer createdById de manera segura
    String createdById = '';
    if (json['createdById'] != null) {
      createdById = json['createdById'].toString();
    } else if (json['created_by_id'] != null) {
      createdById = json['created_by_id'].toString();
    }

    return CreditPaymentModel(
      id: json['id']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      paymentMethod: paymentMethod,
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? json['payment_date']?.toString() ?? '') ?? DateTime.now(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      creditId: creditId,
      bankAccountId: json['bankAccountId']?.toString() ?? json['bank_account_id']?.toString(),
      bankAccountName: json['bankAccount']?['name']?.toString(),
      organizationId: organizationId,
      createdById: createdById,
      createdByName: json['createdBy']?['firstName'] != null
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'reference': reference,
      'notes': notes,
      'creditId': creditId,
      'bankAccountId': bankAccountId,
      'organizationId': organizationId,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Modelo de estadísticas de créditos
class CreditStatsModel extends CreditStats {
  const CreditStatsModel({
    required super.totalPending,
    required super.totalOverdue,
    required super.countPending,
    required super.countOverdue,
    required super.totalPaid,
  });

  factory CreditStatsModel.fromJson(Map<String, dynamic> json) {
    return CreditStatsModel(
      // Soportar tanto camelCase como snake_case del backend
      totalPending: _parseDouble(json['totalPending'] ?? json['total_pending']),
      totalOverdue: _parseDouble(json['totalOverdue'] ?? json['total_overdue']),
      countPending: _parseInt(json['countPending'] ?? json['count_pending']),
      countOverdue: _parseInt(json['countOverdue'] ?? json['count_overdue']),
      totalPaid: _parseDouble(json['totalPaid'] ?? json['total_paid']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// DTO para crear un crédito
class CreateCustomerCreditDto {
  final String customerId;
  final double originalAmount;
  final String? dueDate;
  final String? description;
  final String? notes;
  final String? invoiceId;
  /// [DEPRECATED] Ahora el saldo se aplica automáticamente
  final bool? useClientBalance;
  /// Si es true, NO aplica automáticamente el saldo a favor (default: false = aplica auto)
  final bool? skipAutoBalance;

  const CreateCustomerCreditDto({
    required this.customerId,
    required this.originalAmount,
    this.dueDate,
    this.description,
    this.notes,
    this.invoiceId,
    this.useClientBalance,
    this.skipAutoBalance,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'originalAmount': originalAmount,
      if (dueDate != null) 'dueDate': dueDate,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (useClientBalance != null) 'useClientBalance': useClientBalance,
      if (skipAutoBalance != null) 'skipAutoBalance': skipAutoBalance,
    };
  }
}

/// DTO para agregar un pago a un crédito
class AddCreditPaymentDto {
  final double amount;
  final String paymentMethod;
  final String? paymentDate;
  final String? reference;
  final String? notes;
  final String? bankAccountId;

  const AddCreditPaymentDto({
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.reference,
    this.notes,
    this.bankAccountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (paymentDate != null) 'paymentDate': paymentDate,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (bankAccountId != null) 'bankAccountId': bankAccountId,
    };
  }
}

/// Query params para filtrar créditos
class CustomerCreditQueryParams {
  final String? customerId;
  final String? status;
  final bool? overdueOnly;
  final bool? includeCancelled;
  final String? startDate;
  final String? endDate;

  const CustomerCreditQueryParams({
    this.customerId,
    this.status,
    this.overdueOnly,
    this.includeCancelled,
    this.startDate,
    this.endDate,
  });

  Map<String, String> toQueryMap() {
    final map = <String, String>{};
    if (customerId != null) map['customerId'] = customerId!;
    if (status != null) map['status'] = status!;
    if (overdueOnly != null) map['overdueOnly'] = overdueOnly.toString();
    if (includeCancelled != null) map['includeCancelled'] = includeCancelled.toString();
    if (startDate != null) map['startDate'] = startDate!;
    if (endDate != null) map['endDate'] = endDate!;
    return map;
  }
}

// ==================== CLIENT BALANCE MODELS ====================

/// Tipo de transacción de saldo a favor
enum BalanceTransactionType {
  deposit('deposit'),
  usage('usage'),
  refund('refund'),
  adjustment('adjustment');

  final String value;
  const BalanceTransactionType(this.value);

  static BalanceTransactionType fromValue(String value) {
    return BalanceTransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BalanceTransactionType.deposit,
    );
  }

  String get displayName {
    switch (this) {
      case BalanceTransactionType.deposit:
        return 'Depósito';
      case BalanceTransactionType.usage:
        return 'Uso';
      case BalanceTransactionType.refund:
        return 'Reembolso';
      case BalanceTransactionType.adjustment:
        return 'Ajuste';
    }
  }
}

/// Tipo de transacción de crédito
enum CreditTransactionType {
  charge('charge'),
  debtIncrease('debt_increase'),
  payment('payment'),
  balanceUsed('balance_used'),
  balanceGenerated('balance_generated');

  final String value;
  const CreditTransactionType(this.value);

  static CreditTransactionType fromValue(String value) {
    return CreditTransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CreditTransactionType.charge,
    );
  }

  String get displayName {
    switch (this) {
      case CreditTransactionType.charge:
        return 'Cargo';
      case CreditTransactionType.debtIncrease:
        return 'Aumento de deuda';
      case CreditTransactionType.payment:
        return 'Pago';
      case CreditTransactionType.balanceUsed:
        return 'Saldo a favor usado';
      case CreditTransactionType.balanceGenerated:
        return 'Saldo a favor generado';
    }
  }
}

/// Modelo de transacción de saldo a favor
class ClientBalanceTransactionModel {
  final String id;
  final BalanceTransactionType type;
  final double amount;
  final String description;
  final double balanceAfter;
  final String? paymentMethod;
  final String? relatedCreditId;
  final String clientBalanceId;
  final String organizationId;
  final String createdById;
  final String? createdByName;
  final DateTime createdAt;

  const ClientBalanceTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    this.paymentMethod,
    this.relatedCreditId,
    required this.clientBalanceId,
    required this.organizationId,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
  });

  factory ClientBalanceTransactionModel.fromJson(Map<String, dynamic> json) {
    // Extraer clientBalanceId de manera segura
    String clientBalanceId = '';
    if (json['clientBalanceId'] != null) {
      clientBalanceId = json['clientBalanceId'].toString();
    } else if (json['client_balance_id'] != null) {
      clientBalanceId = json['client_balance_id'].toString();
    }

    // Extraer organizationId de manera segura
    String organizationId = '';
    if (json['organizationId'] != null) {
      organizationId = json['organizationId'].toString();
    } else if (json['organization_id'] != null) {
      organizationId = json['organization_id'].toString();
    }

    // Extraer createdById de manera segura
    String createdById = '';
    if (json['createdById'] != null) {
      createdById = json['createdById'].toString();
    } else if (json['created_by_id'] != null) {
      createdById = json['created_by_id'].toString();
    }

    return ClientBalanceTransactionModel(
      id: json['id']?.toString() ?? '',
      type: BalanceTransactionType.fromValue(json['type']?.toString() ?? 'deposit'),
      amount: _parseDouble(json['amount']),
      description: json['description']?.toString() ?? '',
      balanceAfter: _parseDouble(json['balanceAfter'] ?? json['balance_after']),
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
      relatedCreditId: json['relatedCreditId']?.toString() ?? json['related_credit_id']?.toString(),
      clientBalanceId: clientBalanceId,
      organizationId: organizationId,
      createdById: createdById,
      createdByName: json['createdBy']?['firstName'] != null
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Modelo de saldo a favor del cliente
class ClientBalanceModel {
  final String id;
  final double balance;
  final String customerId;
  final String? customerName;
  final String organizationId;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ClientBalanceTransactionModel>? transactions;

  const ClientBalanceModel({
    required this.id,
    required this.balance,
    required this.customerId,
    this.customerName,
    required this.organizationId,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.transactions,
  });

  factory ClientBalanceModel.fromJson(Map<String, dynamic> json) {
    List<ClientBalanceTransactionModel>? transactions;
    if (json['transactions'] != null) {
      transactions = (json['transactions'] as List)
          .map((t) => ClientBalanceTransactionModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    // Extraer customerId de manera segura
    String customerId = '';
    if (json['customerId'] != null) {
      customerId = json['customerId'].toString();
    } else if (json['customer_id'] != null) {
      customerId = json['customer_id'].toString();
    }

    // Extraer organizationId de manera segura
    String organizationId = '';
    if (json['organizationId'] != null) {
      organizationId = json['organizationId'].toString();
    } else if (json['organization_id'] != null) {
      organizationId = json['organization_id'].toString();
    }

    // Extraer createdById de manera segura
    String createdById = '';
    if (json['createdById'] != null) {
      createdById = json['createdById'].toString();
    } else if (json['created_by_id'] != null) {
      createdById = json['created_by_id'].toString();
    }

    return ClientBalanceModel(
      id: json['id']?.toString() ?? '',
      balance: _parseDouble(json['balance']),
      customerId: customerId,
      customerName: json['customer']?['firstName'] != null
          ? '${json['customer']['firstName']} ${json['customer']['lastName'] ?? ''}'.trim()
          : null,
      organizationId: organizationId,
      createdById: createdById,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      transactions: transactions,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Modelo de transacción de crédito (historial)
class CreditTransactionModel {
  final String id;
  final CreditTransactionType type;
  final double amount;
  final String? description;
  final double balanceAfter;
  final String? paymentMethod;
  final String? bankAccountId;
  final String? bankAccountName;
  final String creditId;
  final String organizationId;
  final String createdById;
  final String? createdByName;
  final DateTime createdAt;

  const CreditTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.balanceAfter,
    this.paymentMethod,
    this.bankAccountId,
    this.bankAccountName,
    required this.creditId,
    required this.organizationId,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    // Extraer creditId de manera segura
    String creditId = '';
    if (json['creditId'] != null) {
      creditId = json['creditId'].toString();
    } else if (json['credit_id'] != null) {
      creditId = json['credit_id'].toString();
    }

    // Extraer organizationId de manera segura
    String organizationId = '';
    if (json['organizationId'] != null) {
      organizationId = json['organizationId'].toString();
    } else if (json['organization_id'] != null) {
      organizationId = json['organization_id'].toString();
    }

    // Extraer createdById de manera segura
    String createdById = '';
    if (json['createdById'] != null) {
      createdById = json['createdById'].toString();
    } else if (json['created_by_id'] != null) {
      createdById = json['created_by_id'].toString();
    }

    // Extraer nombre de cuenta bancaria
    String? bankAccountName;
    if (json['bankAccount'] != null && json['bankAccount']['name'] != null) {
      bankAccountName = json['bankAccount']['name'].toString();
    } else if (json['bank_account'] != null && json['bank_account']['name'] != null) {
      bankAccountName = json['bank_account']['name'].toString();
    } else if (json['bankAccountName'] != null) {
      bankAccountName = json['bankAccountName'].toString();
    } else if (json['bank_account_name'] != null) {
      bankAccountName = json['bank_account_name'].toString();
    }

    return CreditTransactionModel(
      id: json['id']?.toString() ?? '',
      type: CreditTransactionType.fromValue(json['type']?.toString() ?? 'charge'),
      amount: _parseDouble(json['amount']),
      description: json['description']?.toString(),
      balanceAfter: _parseDouble(json['balanceAfter'] ?? json['balance_after']),
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
      bankAccountId: json['bankAccountId']?.toString() ?? json['bank_account_id']?.toString(),
      bankAccountName: bankAccountName,
      creditId: creditId,
      organizationId: organizationId,
      createdById: createdById,
      createdByName: json['createdBy']?['firstName'] != null
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ==================== CLIENT BALANCE DTOs ====================

/// DTO para depositar saldo
class DepositBalanceDto {
  final String customerId;
  final double amount;
  final String description;
  final String? relatedCreditId;

  const DepositBalanceDto({
    required this.customerId,
    required this.amount,
    required this.description,
    this.relatedCreditId,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'amount': amount,
      'description': description,
      if (relatedCreditId != null) 'relatedCreditId': relatedCreditId,
    };
  }
}

/// DTO para usar saldo
class UseBalanceDto {
  final String clientId;
  final double amount;
  final String description;
  final String? relatedCreditId;

  const UseBalanceDto({
    required this.clientId,
    required this.amount,
    required this.description,
    this.relatedCreditId,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'amount': amount,
      'description': description,
      if (relatedCreditId != null) 'relatedCreditId': relatedCreditId,
    };
  }
}

/// DTO para reembolsar saldo
class RefundBalanceDto {
  final String clientId;
  final double amount;
  final String description;
  final String paymentMethod;

  const RefundBalanceDto({
    required this.clientId,
    required this.amount,
    required this.description,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
    };
  }
}

/// DTO para ajustar saldo
class AdjustBalanceDto {
  final String clientId;
  final double amount;
  final String description;

  const AdjustBalanceDto({
    required this.clientId,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'amount': amount,
      'description': description,
    };
  }
}

/// DTO para agregar monto a un crédito
class AddAmountToCreditDto {
  final double amount;
  final String description;

  const AddAmountToCreditDto({
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
    };
  }
}

/// DTO para aplicar saldo a favor a un crédito
class ApplyBalanceToCreditDto {
  final double? amount;

  const ApplyBalanceToCreditDto({
    this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      if (amount != null) 'amount': amount,
    };
  }
}

// ==================== CUSTOMER CREDIT SUMMARY MODEL ====================

/// Modelo que agrupa todos los créditos de un cliente
/// Para mostrar una sola card por cliente en el listado
class CustomerCreditSummary {
  final String customerId;
  final String customerName;
  final List<CustomerCreditModel> credits;
  final double totalOriginalAmount;
  final double totalPaidAmount;
  final double totalBalanceDue;
  final int totalCredits;
  final int pendingCredits;
  final int paidCredits;
  final int overdueCredits;
  final DateTime? lastActivityDate;
  final CustomerCreditModel? pendingDirectCredit; // Crédito directo pendiente (sin factura)

  const CustomerCreditSummary({
    required this.customerId,
    required this.customerName,
    required this.credits,
    required this.totalOriginalAmount,
    required this.totalPaidAmount,
    required this.totalBalanceDue,
    required this.totalCredits,
    required this.pendingCredits,
    required this.paidCredits,
    required this.overdueCredits,
    this.lastActivityDate,
    this.pendingDirectCredit,
  });

  /// Crea un CustomerCreditSummary a partir de una lista de créditos del mismo cliente
  factory CustomerCreditSummary.fromCredits(List<CustomerCreditModel> credits) {
    if (credits.isEmpty) {
      throw ArgumentError('Credits list cannot be empty');
    }

    final firstCredit = credits.first;

    double totalOriginal = 0;
    double totalPaid = 0;
    double totalDue = 0;
    int pending = 0;
    int paid = 0;
    int overdue = 0;
    DateTime? lastActivity;
    CustomerCreditModel? pendingDirect;

    for (final credit in credits) {
      totalOriginal += credit.originalAmount;
      totalPaid += credit.paidAmount;
      totalDue += credit.balanceDue;

      // Contar por estado
      switch (credit.status) {
        case CreditStatus.pending:
        case CreditStatus.partiallyPaid:
          pending++;
          break;
        case CreditStatus.paid:
          paid++;
          break;
        case CreditStatus.overdue:
          overdue++;
          break;
        case CreditStatus.cancelled:
          break;
      }

      // Buscar crédito directo pendiente (sin factura)
      if (credit.invoiceId == null &&
          credit.canReceivePayment &&
          pendingDirect == null) {
        pendingDirect = credit;
      }

      // Determinar última actividad
      if (lastActivity == null || credit.updatedAt.isAfter(lastActivity)) {
        lastActivity = credit.updatedAt;
      }
    }

    return CustomerCreditSummary(
      customerId: firstCredit.customerId,
      customerName: firstCredit.customerName ?? 'Cliente',
      credits: credits,
      totalOriginalAmount: totalOriginal,
      totalPaidAmount: totalPaid,
      totalBalanceDue: totalDue,
      totalCredits: credits.length,
      pendingCredits: pending,
      paidCredits: paid,
      overdueCredits: overdue,
      lastActivityDate: lastActivity,
      pendingDirectCredit: pendingDirect,
    );
  }

  /// Progreso de pago general (0.0 a 1.0)
  double get paymentProgress {
    if (totalOriginalAmount <= 0) return 0.0;
    return (totalPaidAmount / totalOriginalAmount).clamp(0.0, 1.0);
  }

  /// Verifica si tiene créditos vencidos
  bool get hasOverdueCredits => overdueCredits > 0;

  /// Verifica si tiene créditos pendientes
  bool get hasPendingCredits => pendingCredits > 0 || overdueCredits > 0;

  /// Verifica si puede recibir pagos
  bool get canReceivePayments => totalBalanceDue > 0;

  /// Verifica si tiene un crédito directo pendiente al cual agregar
  bool get hasPendingDirectCredit => pendingDirectCredit != null;

  /// Iniciales del cliente
  String get customerInitials {
    final parts = customerName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';
  }

  /// Créditos pendientes activos (para mostrar en detalle)
  List<CustomerCreditModel> get activeCredits =>
      credits.where((c) => c.canReceivePayment).toList();

  /// Créditos de facturas
  List<CustomerCreditModel> get invoiceCredits =>
      credits.where((c) => c.invoiceId != null).toList();

  /// Créditos directos
  List<CustomerCreditModel> get directCredits =>
      credits.where((c) => c.invoiceId == null).toList();
}

// ==================== CUSTOMER ACCOUNT MODEL ====================

/// Modelo de cuenta corriente del cliente
/// Consolida deudas por facturas, créditos directos y saldo a favor
class CustomerAccountModel {
  final CustomerAccountCustomer customer;
  final CustomerAccountSummary summary;
  final List<CustomerCreditModel> invoiceCredits;
  final List<CustomerCreditModel> directCredits;
  final CustomerAccountBalance clientBalance;

  const CustomerAccountModel({
    required this.customer,
    required this.summary,
    required this.invoiceCredits,
    required this.directCredits,
    required this.clientBalance,
  });

  factory CustomerAccountModel.fromJson(Map<String, dynamic> json) {
    return CustomerAccountModel(
      customer: CustomerAccountCustomer.fromJson(json['customer'] ?? {}),
      summary: CustomerAccountSummary.fromJson(json['summary'] ?? {}),
      invoiceCredits: (json['invoiceCredits'] as List? ?? [])
          .map((c) => CustomerCreditModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      directCredits: (json['directCredits'] as List? ?? [])
          .map((c) => CustomerCreditModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      clientBalance: CustomerAccountBalance.fromJson(json['clientBalance'] ?? {}),
    );
  }

  /// Total de créditos pendientes (facturas + directos)
  int get totalCreditsCount => invoiceCredits.length + directCredits.length;

  /// Verifica si el cliente tiene deudas
  bool get hasDebt => summary.totalDebt > 0;

  /// Verifica si el cliente tiene saldo a favor
  bool get hasBalance => clientBalance.balance > 0;
}

/// Información del cliente en la cuenta corriente
class CustomerAccountCustomer {
  final String id;
  final String name;
  final double currentBalance;

  const CustomerAccountCustomer({
    required this.id,
    required this.name,
    required this.currentBalance,
  });

  factory CustomerAccountCustomer.fromJson(Map<String, dynamic> json) {
    return CustomerAccountCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      currentBalance: _parseDouble(json['currentBalance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Resumen de la cuenta corriente
class CustomerAccountSummary {
  final double totalDebt;
  final double invoiceDebt;
  final double directCreditDebt;
  final double availableBalance;
  final double netBalance;

  const CustomerAccountSummary({
    required this.totalDebt,
    required this.invoiceDebt,
    required this.directCreditDebt,
    required this.availableBalance,
    required this.netBalance,
  });

  factory CustomerAccountSummary.fromJson(Map<String, dynamic> json) {
    return CustomerAccountSummary(
      totalDebt: _parseDouble(json['totalDebt']),
      invoiceDebt: _parseDouble(json['invoiceDebt']),
      directCreditDebt: _parseDouble(json['directCreditDebt']),
      availableBalance: _parseDouble(json['availableBalance']),
      netBalance: _parseDouble(json['netBalance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Información del saldo a favor en la cuenta corriente
class CustomerAccountBalance {
  final double balance;
  final DateTime? lastTransaction;

  const CustomerAccountBalance({
    required this.balance,
    this.lastTransaction,
  });

  factory CustomerAccountBalance.fromJson(Map<String, dynamic> json) {
    return CustomerAccountBalance(
      balance: _parseDouble(json['balance']),
      lastTransaction: json['lastTransaction'] != null
          ? DateTime.tryParse(json['lastTransaction'].toString())
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
