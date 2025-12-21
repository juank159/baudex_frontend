// lib/features/bank_accounts/domain/entities/bank_account_transaction.dart
import 'package:equatable/equatable.dart';

/// Información del cliente en una transacción
class TransactionCustomer extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  const TransactionCustomer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, email, phone];
}

/// Información de la factura en una transacción
class TransactionInvoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final double total;

  const TransactionInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.total,
  });

  @override
  List<Object?> get props => [id, invoiceNumber, total];
}

/// Tipo de transacción
enum TransactionType {
  invoicePayment,
  creditPayment;

  String get displayName {
    switch (this) {
      case TransactionType.invoicePayment:
        return 'Pago de Factura';
      case TransactionType.creditPayment:
        return 'Pago de Crédito';
    }
  }
}

/// Entidad de transacción de cuenta bancaria
class BankAccountTransaction extends Equatable {
  final String id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final TransactionCustomer? customer;
  final TransactionInvoice? invoice;
  final String paymentMethod;
  final String description;
  final String? notes;

  const BankAccountTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    this.customer,
    this.invoice,
    required this.paymentMethod,
    required this.description,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        type,
        amount,
        customer,
        invoice,
        paymentMethod,
        description,
        notes,
      ];
}

/// Resumen de transacciones de un período
class TransactionsSummary extends Equatable {
  final double totalIncome;
  final int transactionCount;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double averageTransaction;

  const TransactionsSummary({
    required this.totalIncome,
    required this.transactionCount,
    this.periodStart,
    this.periodEnd,
    required this.averageTransaction,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        transactionCount,
        periodStart,
        periodEnd,
        averageTransaction,
      ];
}

/// Paginación de transacciones
class TransactionsPagination extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const TransactionsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

/// Información de la cuenta en la respuesta de transacciones
class TransactionAccountInfo extends Equatable {
  final String id;
  final String name;
  final String type;
  final double currentBalance;
  final String? bankName;
  final String? accountNumber;

  const TransactionAccountInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.currentBalance,
    this.bankName,
    this.accountNumber,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        currentBalance,
        bankName,
        accountNumber,
      ];
}

/// Respuesta completa de transacciones de cuenta bancaria
class BankAccountTransactionsResponse extends Equatable {
  final TransactionAccountInfo account;
  final List<BankAccountTransaction> transactions;
  final TransactionsPagination pagination;
  final TransactionsSummary summary;

  const BankAccountTransactionsResponse({
    required this.account,
    required this.transactions,
    required this.pagination,
    required this.summary,
  });

  @override
  List<Object?> get props => [account, transactions, pagination, summary];
}
