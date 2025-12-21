// lib/features/bank_accounts/data/models/bank_account_transaction_model.dart
import '../../domain/entities/bank_account_transaction.dart';

/// Modelo para parsear TransactionCustomer desde JSON
class TransactionCustomerModel extends TransactionCustomer {
  const TransactionCustomerModel({
    required super.id,
    required super.name,
    super.email,
    super.phone,
  });

  factory TransactionCustomerModel.fromJson(Map<String, dynamic> json) {
    return TransactionCustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

/// Modelo para parsear TransactionInvoice desde JSON
class TransactionInvoiceModel extends TransactionInvoice {
  const TransactionInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.total,
  });

  factory TransactionInvoiceModel.fromJson(Map<String, dynamic> json) {
    return TransactionInvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'total': total,
    };
  }
}

/// Modelo para parsear BankAccountTransaction desde JSON
class BankAccountTransactionModel extends BankAccountTransaction {
  const BankAccountTransactionModel({
    required super.id,
    required super.date,
    required super.type,
    required super.amount,
    super.customer,
    super.invoice,
    required super.paymentMethod,
    required super.description,
    super.notes,
  });

  factory BankAccountTransactionModel.fromJson(Map<String, dynamic> json) {
    return BankAccountTransactionModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: _parseTransactionType(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      customer: json['customer'] != null
          ? TransactionCustomerModel.fromJson(
              json['customer'] as Map<String, dynamic>)
          : null,
      invoice: json['invoice'] != null
          ? TransactionInvoiceModel.fromJson(
              json['invoice'] as Map<String, dynamic>)
          : null,
      paymentMethod: json['paymentMethod'] as String,
      description: json['description'] as String,
      notes: json['notes'] as String?,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'invoice_payment':
        return TransactionType.invoicePayment;
      case 'credit_payment':
        return TransactionType.creditPayment;
      default:
        return TransactionType.invoicePayment;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type == TransactionType.invoicePayment
          ? 'invoice_payment'
          : 'credit_payment',
      'amount': amount,
      'customer': customer != null
          ? (customer as TransactionCustomerModel).toJson()
          : null,
      'invoice': invoice != null
          ? (invoice as TransactionInvoiceModel).toJson()
          : null,
      'paymentMethod': paymentMethod,
      'description': description,
      'notes': notes,
    };
  }
}

/// Modelo para parsear TransactionsSummary desde JSON
class TransactionsSummaryModel extends TransactionsSummary {
  const TransactionsSummaryModel({
    required super.totalIncome,
    required super.transactionCount,
    super.periodStart,
    super.periodEnd,
    required super.averageTransaction,
  });

  factory TransactionsSummaryModel.fromJson(Map<String, dynamic> json) {
    return TransactionsSummaryModel(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'] as String)
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.parse(json['periodEnd'] as String)
          : null,
      averageTransaction: (json['averageTransaction'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'transactionCount': transactionCount,
      'periodStart': periodStart?.toIso8601String(),
      'periodEnd': periodEnd?.toIso8601String(),
      'averageTransaction': averageTransaction,
    };
  }
}

/// Modelo para parsear TransactionsPagination desde JSON
class TransactionsPaginationModel extends TransactionsPagination {
  const TransactionsPaginationModel({
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
  });

  factory TransactionsPaginationModel.fromJson(Map<String, dynamic> json) {
    return TransactionsPaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

/// Modelo para parsear TransactionAccountInfo desde JSON
class TransactionAccountInfoModel extends TransactionAccountInfo {
  const TransactionAccountInfoModel({
    required super.id,
    required super.name,
    required super.type,
    required super.currentBalance,
    super.bankName,
    super.accountNumber,
  });

  factory TransactionAccountInfoModel.fromJson(Map<String, dynamic> json) {
    return TransactionAccountInfoModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currentBalance: (json['currentBalance'] as num).toDouble(),
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currentBalance': currentBalance,
      'bankName': bankName,
      'accountNumber': accountNumber,
    };
  }
}

/// Modelo para parsear BankAccountTransactionsResponse desde JSON
class BankAccountTransactionsResponseModel
    extends BankAccountTransactionsResponse {
  const BankAccountTransactionsResponseModel({
    required super.account,
    required super.transactions,
    required super.pagination,
    required super.summary,
  });

  factory BankAccountTransactionsResponseModel.fromJson(
      Map<String, dynamic> json) {
    return BankAccountTransactionsResponseModel(
      account: TransactionAccountInfoModel.fromJson(
          json['account'] as Map<String, dynamic>),
      transactions: (json['transactions'] as List)
          .map((t) => BankAccountTransactionModel.fromJson(
              t as Map<String, dynamic>))
          .toList(),
      pagination: TransactionsPaginationModel.fromJson(
          json['pagination'] as Map<String, dynamic>),
      summary: TransactionsSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account': (account as TransactionAccountInfoModel).toJson(),
      'transactions': transactions
          .map((t) => (t as BankAccountTransactionModel).toJson())
          .toList(),
      'pagination': (pagination as TransactionsPaginationModel).toJson(),
      'summary': (summary as TransactionsSummaryModel).toJson(),
    };
  }
}
