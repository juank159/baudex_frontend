// test/fixtures/bank_account_fixtures.dart
import 'package:baudex_desktop/features/bank_accounts/domain/entities/bank_account.dart';
import 'package:baudex_desktop/features/bank_accounts/domain/entities/bank_account_transaction.dart';

/// Test fixtures for Bank Accounts module
class BankAccountFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single bank account entity with default test data
  static BankAccount createBankAccountEntity({
    String id = 'bank-001',
    String name = 'Caja Principal',
    BankAccountType type = BankAccountType.cash,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool isActive = true,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
    Map<String, dynamic>? metadata,
    String organizationId = 'org-001',
    String? createdById,
    String? updatedById,
  }) {
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
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      deletedAt: null,
    );
  }

  /// Creates a list of bank account entities
  static List<BankAccount> createBankAccountEntityList(int count) {
    return List.generate(count, (index) {
      return createBankAccountEntity(
        id: 'bank-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Account ${index + 1}',
        type: BankAccountType.values[index % BankAccountType.values.length],
        sortOrder: index,
        isDefault: index == 0,
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES - BY TYPE
  // ============================================================================

  /// Creates a cash account
  static BankAccount createCashAccount({
    String id = 'bank-cash',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Caja Principal',
      type: BankAccountType.cash,
      description: 'Cuenta de efectivo principal',
      isActive: true,
      isDefault: true,
      sortOrder: 0,
    );
  }

  /// Creates a savings account
  static BankAccount createSavingsAccount({
    String id = 'bank-savings',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Cuenta de Ahorros',
      type: BankAccountType.savings,
      bankName: 'Banco de Bogotá',
      accountNumber: '1234567890',
      holderName: 'Juan Perez',
      description: 'Cuenta de ahorros empresarial',
      isActive: true,
      sortOrder: 1,
    );
  }

  /// Creates a checking account
  static BankAccount createCheckingAccount({
    String id = 'bank-checking',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Cuenta Corriente',
      type: BankAccountType.checking,
      bankName: 'Bancolombia',
      accountNumber: '9876543210',
      holderName: 'Empresa S.A.S.',
      description: 'Cuenta corriente principal',
      isActive: true,
      sortOrder: 2,
    );
  }

  /// Creates a digital wallet account
  static BankAccount createDigitalWalletAccount({
    String id = 'bank-digital',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Nequi Empresarial',
      type: BankAccountType.digitalWallet,
      bankName: 'Nequi',
      accountNumber: '+573001234567',
      holderName: 'Juan Perez',
      description: 'Billetera digital empresarial',
      isActive: true,
      sortOrder: 3,
    );
  }

  /// Creates a credit card account
  static BankAccount createCreditCardAccount({
    String id = 'bank-credit',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Tarjeta de Crédito Visa',
      type: BankAccountType.creditCard,
      bankName: 'Banco Davivienda',
      accountNumber: '1234 5678 9012 3456',
      holderName: 'Juan Perez',
      description: 'Tarjeta de crédito empresarial',
      isActive: true,
      sortOrder: 4,
    );
  }

  /// Creates a debit card account
  static BankAccount createDebitCardAccount({
    String id = 'bank-debit',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Tarjeta Débito',
      type: BankAccountType.debitCard,
      bankName: 'Banco Popular',
      accountNumber: '6543 2109 8765 4321',
      holderName: 'Maria Garcia',
      description: 'Tarjeta de débito empresarial',
      isActive: true,
      sortOrder: 5,
    );
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES - BY STATUS
  // ============================================================================

  /// Creates an inactive bank account
  static BankAccount createInactiveBankAccount({
    String id = 'bank-inactive',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Cuenta Inactiva',
      type: BankAccountType.checking,
      isActive: false,
      description: 'Cuenta bancaria inactiva',
    );
  }

  /// Creates a default bank account
  static BankAccount createDefaultBankAccount({
    String id = 'bank-default',
  }) {
    return createBankAccountEntity(
      id: id,
      name: 'Cuenta Predeterminada',
      type: BankAccountType.cash,
      isDefault: true,
      isActive: true,
      sortOrder: 0,
    );
  }

  /// Creates a deleted bank account
  static BankAccount createDeletedBankAccount({
    String id = 'bank-deleted',
  }) {
    final account = createBankAccountEntity(
      id: id,
      name: 'Cuenta Eliminada',
      type: BankAccountType.other,
      isActive: false,
    );
    return account.copyWith(deletedAt: DateTime(2024, 1, 15));
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of bank accounts with different types
  static List<BankAccount> createMixedTypeBankAccounts() {
    return [
      createCashAccount(id: 'bank-001'),
      createSavingsAccount(id: 'bank-002'),
      createCheckingAccount(id: 'bank-003'),
      createDigitalWalletAccount(id: 'bank-004'),
      createCreditCardAccount(id: 'bank-005'),
    ];
  }

  /// Creates bank accounts with different active statuses
  static List<BankAccount> createMixedStatusBankAccounts() {
    return [
      createBankAccountEntity(id: 'bank-001', isActive: true),
      createBankAccountEntity(id: 'bank-002', isActive: true),
      createInactiveBankAccount(id: 'bank-003'),
      createBankAccountEntity(id: 'bank-004', isActive: true),
    ];
  }

  /// Creates bank accounts with different sort orders
  static List<BankAccount> createSortedBankAccounts() {
    return [
      createBankAccountEntity(id: 'bank-001', sortOrder: 0, isDefault: true),
      createBankAccountEntity(id: 'bank-002', sortOrder: 1),
      createBankAccountEntity(id: 'bank-003', sortOrder: 2),
      createBankAccountEntity(id: 'bank-004', sortOrder: 3),
    ];
  }

  // ============================================================================
  // TRANSACTION FIXTURES
  // ============================================================================

  /// Creates a transaction customer
  static TransactionCustomer createTransactionCustomer({
    String id = 'cust-001',
    String name = 'John Doe',
    String? email = 'john.doe@example.com',
    String? phone = '+573001234567',
  }) {
    return TransactionCustomer(
      id: id,
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Creates a transaction invoice
  static TransactionInvoice createTransactionInvoice({
    String id = 'inv-001',
    String invoiceNumber = 'INV-2024-001',
    double total = 1000000.0,
  }) {
    return TransactionInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      total: total,
    );
  }

  /// Creates a bank account transaction
  static BankAccountTransaction createBankAccountTransaction({
    String id = 'txn-001',
    DateTime? date,
    TransactionType type = TransactionType.invoicePayment,
    double amount = 500000.0,
    TransactionCustomer? customer,
    TransactionInvoice? invoice,
    String paymentMethod = 'cash',
    String description = 'Pago de factura',
    String? notes,
  }) {
    return BankAccountTransaction(
      id: id,
      date: date ?? DateTime(2024, 1, 1),
      type: type,
      amount: amount,
      customer: customer ?? createTransactionCustomer(),
      invoice: invoice ?? createTransactionInvoice(),
      paymentMethod: paymentMethod,
      description: description,
      notes: notes,
    );
  }

  /// Creates a list of transactions
  static List<BankAccountTransaction> createTransactionList(int count) {
    return List.generate(count, (index) {
      return createBankAccountTransaction(
        id: 'txn-${(index + 1).toString().padLeft(3, '0')}',
        date: DateTime(2024, 1, index + 1),
        amount: 100000.0 * (index + 1),
      );
    });
  }

  /// Creates transactions summary
  static TransactionsSummary createTransactionsSummary({
    double totalIncome = 5000000.0,
    int transactionCount = 10,
    DateTime? periodStart,
    DateTime? periodEnd,
    double averageTransaction = 500000.0,
  }) {
    return TransactionsSummary(
      totalIncome: totalIncome,
      transactionCount: transactionCount,
      periodStart: periodStart,
      periodEnd: periodEnd,
      averageTransaction: averageTransaction,
    );
  }

  /// Creates transactions pagination
  static TransactionsPagination createTransactionsPagination({
    int page = 1,
    int limit = 10,
    int total = 50,
    int totalPages = 5,
  }) {
    return TransactionsPagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  /// Creates transaction account info
  static TransactionAccountInfo createTransactionAccountInfo({
    String id = 'bank-001',
    String name = 'Caja Principal',
    String type = 'cash',
    double currentBalance = 10000000.0,
    String? bankName,
    String? accountNumber,
  }) {
    return TransactionAccountInfo(
      id: id,
      name: name,
      type: type,
      currentBalance: currentBalance,
      bankName: bankName,
      accountNumber: accountNumber,
    );
  }

  /// Creates bank account transactions response
  static BankAccountTransactionsResponse createBankAccountTransactionsResponse({
    TransactionAccountInfo? account,
    List<BankAccountTransaction>? transactions,
    TransactionsPagination? pagination,
    TransactionsSummary? summary,
  }) {
    return BankAccountTransactionsResponse(
      account: account ?? createTransactionAccountInfo(),
      transactions: transactions ?? createTransactionList(5),
      pagination: pagination ?? createTransactionsPagination(),
      summary: summary ?? createTransactionsSummary(),
    );
  }
}
