// test/fixtures/customer_credit_fixtures.dart
import 'package:baudex_desktop/features/customer_credits/domain/entities/customer_credit.dart';

/// Test fixtures for CustomerCredits module
class CustomerCreditFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single customer credit entity with default test data
  static CustomerCredit createCustomerCreditEntity({
    String id = 'credit-001',
    double originalAmount = 500000.0,
    double paidAmount = 0.0,
    double balanceDue = 500000.0,
    CreditStatus status = CreditStatus.pending,
    DateTime? dueDate,
    String? description = 'Test credit',
    String? notes,
    String customerId = 'cust-001',
    String? customerName = 'John Doe',
    String? invoiceId = 'inv-001',
    String? invoiceNumber = 'INV-001',
    String organizationId = 'org-001',
    String createdById = 'user-001',
    String? createdByName = 'Test User',
    List<CreditPayment>? payments,
  }) {
    final creditDueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

    return CustomerCredit(
      id: id,
      originalAmount: originalAmount,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      status: status,
      dueDate: creditDueDate,
      description: description,
      notes: notes,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      organizationId: organizationId,
      createdById: createdById,
      createdByName: createdByName,
      payments: payments,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of customer credit entities
  static List<CustomerCredit> createCustomerCreditEntityList(int count) {
    return List.generate(count, (index) {
      return createCustomerCreditEntity(
        id: 'credit-${(index + 1).toString().padLeft(3, '0')}',
        originalAmount: (index + 1) * 100000.0,
        balanceDue: (index + 1) * 100000.0,
        customerId: 'cust-${(index + 1).toString().padLeft(3, '0')}',
        customerName: 'Customer ${index + 1}',
        invoiceId: 'inv-${(index + 1).toString().padLeft(3, '0')}',
        invoiceNumber: 'INV-${(index + 1).toString().padLeft(3, '0')}',
      );
    });
  }

  // ============================================================================
  // CREDIT PAYMENT FIXTURES
  // ============================================================================

  /// Creates a single credit payment entity
  static CreditPayment createCreditPaymentEntity({
    String id = 'credit-pay-001',
    double amount = 100000.0,
    String paymentMethod = 'cash',
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String creditId = 'credit-001',
    String? bankAccountId,
    String? bankAccountName,
    String organizationId = 'org-001',
    String createdById = 'user-001',
    String? createdByName = 'Test User',
  }) {
    return CreditPayment(
      id: id,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate ?? DateTime(2024, 1, 5),
      reference: reference,
      notes: notes,
      creditId: creditId,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      organizationId: organizationId,
      createdById: createdById,
      createdByName: createdByName,
      createdAt: DateTime(2024, 1, 5),
      updatedAt: DateTime(2024, 1, 5),
    );
  }

  /// Creates a list of credit payment entities
  static List<CreditPayment> createCreditPaymentEntityList({
    required String creditId,
    int count = 2,
    double totalAmount = 500000.0,
  }) {
    final amountPerPayment = totalAmount / count;
    return List.generate(count, (index) {
      return createCreditPaymentEntity(
        id: 'credit-pay-${(index + 1).toString().padLeft(3, '0')}',
        amount: amountPerPayment,
        creditId: creditId,
        paymentDate: DateTime(2024, 1, 5).add(Duration(days: index * 7)),
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates a pending credit
  static CustomerCredit createPendingCredit({
    String id = 'credit-pending',
  }) {
    return createCustomerCreditEntity(
      id: id,
      status: CreditStatus.pending,
      description: 'Pending credit',
    );
  }

  /// Creates a partially paid credit
  static CustomerCredit createPartiallyPaidCredit({
    String id = 'credit-partial',
    double originalAmount = 500000.0,
    double paidAmount = 200000.0,
  }) {
    return createCustomerCreditEntity(
      id: id,
      originalAmount: originalAmount,
      paidAmount: paidAmount,
      balanceDue: originalAmount - paidAmount,
      status: CreditStatus.partiallyPaid,
      description: 'Partially paid credit',
      payments: [
        createCreditPaymentEntity(
          creditId: id,
          amount: paidAmount,
        ),
      ],
    );
  }

  /// Creates a fully paid credit
  static CustomerCredit createPaidCredit({
    String id = 'credit-paid',
    double amount = 500000.0,
  }) {
    return createCustomerCreditEntity(
      id: id,
      originalAmount: amount,
      paidAmount: amount,
      balanceDue: 0.0,
      status: CreditStatus.paid,
      description: 'Fully paid credit',
      payments: [
        createCreditPaymentEntity(
          creditId: id,
          amount: amount,
        ),
      ],
    );
  }

  /// Creates a cancelled credit
  static CustomerCredit createCancelledCredit({
    String id = 'credit-cancelled',
  }) {
    return createCustomerCreditEntity(
      id: id,
      status: CreditStatus.cancelled,
      description: 'Cancelled credit',
      notes: 'Credit cancelled by manager',
    );
  }

  /// Creates an overdue credit
  static CustomerCredit createOverdueCredit({
    String id = 'credit-overdue',
  }) {
    final dueDate = DateTime.now().subtract(const Duration(days: 30));
    return createCustomerCreditEntity(
      id: id,
      status: CreditStatus.overdue,
      dueDate: dueDate,
      description: 'Overdue credit',
    );
  }

  /// Creates a credit with multiple payments
  static CustomerCredit createCreditWithMultiplePayments({
    String id = 'credit-multi-pay',
    int paymentCount = 3,
  }) {
    final originalAmount = 900000.0;
    final payments = createCreditPaymentEntityList(
      creditId: id,
      count: paymentCount,
      totalAmount: originalAmount,
    );

    return createCustomerCreditEntity(
      id: id,
      originalAmount: originalAmount,
      paidAmount: originalAmount,
      balanceDue: 0.0,
      status: CreditStatus.paid,
      description: 'Credit with multiple payments',
      payments: payments,
    );
  }

  /// Creates a credit due soon (within 7 days)
  static CustomerCredit createCreditDueSoon({
    String id = 'credit-due-soon',
  }) {
    final dueDate = DateTime.now().add(const Duration(days: 5));
    return createCustomerCreditEntity(
      id: id,
      dueDate: dueDate,
      status: CreditStatus.pending,
      description: 'Credit due soon',
    );
  }

  /// Creates a credit with long payment terms
  static CustomerCredit createCreditWithLongTerms({
    String id = 'credit-long-terms',
  }) {
    final dueDate = DateTime.now().add(const Duration(days: 90));
    return createCustomerCreditEntity(
      id: id,
      dueDate: dueDate,
      status: CreditStatus.pending,
      description: 'Credit with 90-day terms',
    );
  }

  /// Creates a high-value credit
  static CustomerCredit createHighValueCredit({
    String id = 'credit-high-value',
    double amount = 5000000.0,
  }) {
    return createCustomerCreditEntity(
      id: id,
      originalAmount: amount,
      balanceDue: amount,
      status: CreditStatus.pending,
      description: 'High value credit',
    );
  }

  /// Creates a low-value credit
  static CustomerCredit createLowValueCredit({
    String id = 'credit-low-value',
    double amount = 50000.0,
  }) {
    return createCustomerCreditEntity(
      id: id,
      originalAmount: amount,
      balanceDue: amount,
      status: CreditStatus.pending,
      description: 'Low value credit',
    );
  }

  /// Creates a credit with bank transfer payment
  static CustomerCredit createCreditWithBankTransfer({
    String id = 'credit-bank-transfer',
  }) {
    return createCustomerCreditEntity(
      id: id,
      originalAmount: 500000.0,
      paidAmount: 500000.0,
      balanceDue: 0.0,
      status: CreditStatus.paid,
      description: 'Credit paid via bank transfer',
      payments: [
        createCreditPaymentEntity(
          creditId: id,
          amount: 500000.0,
          paymentMethod: 'bank_transfer',
          bankAccountId: 'bank-001',
          bankAccountName: 'Nequi',
          reference: 'TRANS-123456',
        ),
      ],
    );
  }

  /// Creates a credit payment with cash
  static CreditPayment createCashPayment({
    String id = 'credit-pay-cash',
    String creditId = 'credit-001',
  }) {
    return createCreditPaymentEntity(
      id: id,
      creditId: creditId,
      paymentMethod: 'cash',
      amount: 100000.0,
    );
  }

  /// Creates a credit payment with credit card
  static CreditPayment createCreditCardPayment({
    String id = 'credit-pay-card',
    String creditId = 'credit-001',
  }) {
    return createCreditPaymentEntity(
      id: id,
      creditId: creditId,
      paymentMethod: 'credit_card',
      amount: 200000.0,
      reference: 'CARD-****1234',
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of credits with different statuses
  static List<CustomerCredit> createMixedStatusCredits() {
    return [
      createPendingCredit(id: 'credit-001'),
      createPartiallyPaidCredit(id: 'credit-002'),
      createPaidCredit(id: 'credit-003'),
      createOverdueCredit(id: 'credit-004'),
      createCancelledCredit(id: 'credit-005'),
    ];
  }

  /// Creates credits with varying amounts
  static List<CustomerCredit> createCreditsWithVaryingAmounts() {
    return [
      createLowValueCredit(id: 'credit-001', amount: 50000.0),
      createCustomerCreditEntity(
        id: 'credit-002',
        originalAmount: 250000.0,
        balanceDue: 250000.0,
      ),
      createCustomerCreditEntity(
        id: 'credit-003',
        originalAmount: 1000000.0,
        balanceDue: 1000000.0,
      ),
      createHighValueCredit(id: 'credit-004', amount: 5000000.0),
    ];
  }

  /// Creates credits with different payment methods
  static List<CustomerCredit> createCreditsByPaymentMethod() {
    return [
      createCustomerCreditEntity(
        id: 'credit-001',
        status: CreditStatus.paid,
        paidAmount: 500000.0,
        balanceDue: 0.0,
        payments: [createCashPayment(id: 'pay-001', creditId: 'credit-001')],
      ),
      createCustomerCreditEntity(
        id: 'credit-002',
        status: CreditStatus.paid,
        paidAmount: 500000.0,
        balanceDue: 0.0,
        payments: [createCreditCardPayment(id: 'pay-002', creditId: 'credit-002')],
      ),
      createCreditWithBankTransfer(id: 'credit-003'),
    ];
  }

  /// Creates credits by due date proximity
  static List<CustomerCredit> createCreditsByDueDate() {
    return [
      createOverdueCredit(id: 'credit-001'),
      createCreditDueSoon(id: 'credit-002'),
      createCustomerCreditEntity(
        id: 'credit-003',
        dueDate: DateTime.now().add(const Duration(days: 20)),
      ),
      createCreditWithLongTerms(id: 'credit-004'),
    ];
  }
}
