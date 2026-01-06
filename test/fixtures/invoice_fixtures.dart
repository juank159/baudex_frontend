// test/fixtures/invoice_fixtures.dart
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
import 'customer_fixtures.dart';
import 'product_fixtures.dart';

/// Test fixtures for Invoices module
class InvoiceFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single invoice entity with default test data
  static Invoice createInvoiceEntity({
    String id = 'inv-001',
    String number = 'INV-001',
    DateTime? date,
    DateTime? dueDate,
    InvoiceStatus status = InvoiceStatus.pending,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double subtotal = 100000.0,
    double taxPercentage = 19.0,
    double taxAmount = 19000.0,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double total = 119000.0,
    double paidAmount = 0.0,
    double balanceDue = 119000.0,
    double creditedAmount = 0.0,
    String? notes,
    String customerId = 'cust-001',
    String createdById = 'user-001',
    List<InvoiceItem>? items,
    List<InvoicePayment>? payments,
  }) {
    final invoiceDate = date ?? DateTime(2024, 1, 1);
    final invoiceDueDate = dueDate ?? invoiceDate.add(const Duration(days: 30));

    return Invoice(
      id: id,
      number: number,
      date: invoiceDate,
      dueDate: invoiceDueDate,
      status: status,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      total: total,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      creditedAmount: creditedAmount,
      notes: notes,
      customerId: customerId,
      customer: CustomerFixtures.createCustomerEntity(id: customerId),
      createdById: createdById,
      items: items ?? [createInvoiceItemEntity(invoiceId: id)],
      payments: payments ?? [],
      createdAt: invoiceDate,
      updatedAt: invoiceDate,
    );
  }

  /// Creates a list of invoice entities
  static List<Invoice> createInvoiceEntityList(int count) {
    return List.generate(count, (index) {
      final date = DateTime(2024, 1, 1).add(Duration(days: index));
      return createInvoiceEntity(
        id: 'inv-${(index + 1).toString().padLeft(3, '0')}',
        number: 'INV-${(index + 1).toString().padLeft(3, '0')}',
        date: date,
        dueDate: date.add(const Duration(days: 30)),
        total: (index + 1) * 100000.0,
        balanceDue: (index + 1) * 100000.0,
      );
    });
  }

  // ============================================================================
  // INVOICE ITEM FIXTURES
  // ============================================================================

  /// Creates a single invoice item entity
  static InvoiceItem createInvoiceItemEntity({
    String id = 'inv-item-001',
    String description = 'Test Product',
    double quantity = 1.0,
    double unitPrice = 100000.0,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double subtotal = 100000.0,
    String? unit = 'pcs',
    String? notes,
    String invoiceId = 'inv-001',
    String? productId = 'prod-001',
  }) {
    return InvoiceItem(
      id: id,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      unit: unit,
      notes: notes,
      invoiceId: invoiceId,
      productId: productId,
      product: productId != null
          ? ProductFixtures.createProductEntity(id: productId, name: description)
          : null,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of invoice item entities
  static List<InvoiceItem> createInvoiceItemEntityList({
    required String invoiceId,
    int count = 3,
  }) {
    return List.generate(count, (index) {
      return createInvoiceItemEntity(
        id: 'inv-item-${(index + 1).toString().padLeft(3, '0')}',
        description: 'Product ${index + 1}',
        quantity: (index + 1).toDouble(),
        unitPrice: (index + 1) * 50000.0,
        subtotal: (index + 1) * (index + 1) * 50000.0,
        invoiceId: invoiceId,
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
      );
    });
  }

  // ============================================================================
  // INVOICE PAYMENT FIXTURES
  // ============================================================================

  /// Creates a single invoice payment entity
  static InvoicePayment createInvoicePaymentEntity({
    String id = 'pay-001',
    double amount = 119000.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String invoiceId = 'inv-001',
    String createdById = 'user-001',
    String organizationId = 'org-001',
  }) {
    return InvoicePayment(
      id: id,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate ?? DateTime(2024, 1, 1),
      reference: reference,
      notes: notes,
      invoiceId: invoiceId,
      createdById: createdById,
      organizationId: organizationId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of invoice payment entities
  static List<InvoicePayment> createInvoicePaymentEntityList({
    required String invoiceId,
    int count = 2,
    double totalAmount = 119000.0,
  }) {
    final amountPerPayment = totalAmount / count;
    return List.generate(count, (index) {
      return createInvoicePaymentEntity(
        id: 'pay-${(index + 1).toString().padLeft(3, '0')}',
        amount: amountPerPayment,
        invoiceId: invoiceId,
        paymentDate: DateTime(2024, 1, 1).add(Duration(days: index)),
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates a draft invoice
  static Invoice createDraftInvoice({
    String id = 'inv-draft',
  }) {
    return createInvoiceEntity(
      id: id,
      number: 'DRAFT-001',
      status: InvoiceStatus.draft,
    );
  }

  /// Creates a pending invoice
  static Invoice createPendingInvoice({
    String id = 'inv-pending',
  }) {
    return createInvoiceEntity(
      id: id,
      number: 'INV-PENDING',
      status: InvoiceStatus.pending,
    );
  }

  /// Creates a paid invoice
  static Invoice createPaidInvoice({
    String id = 'inv-paid',
  }) {
    final total = 119000.0;
    return createInvoiceEntity(
      id: id,
      number: 'INV-PAID',
      status: InvoiceStatus.paid,
      total: total,
      paidAmount: total,
      balanceDue: 0.0,
      payments: [
        createInvoicePaymentEntity(
          invoiceId: id,
          amount: total,
        ),
      ],
    );
  }

  /// Creates a partially paid invoice
  static Invoice createPartiallyPaidInvoice({
    String id = 'inv-partial',
  }) {
    final total = 119000.0;
    final paidAmount = 50000.0;
    return createInvoiceEntity(
      id: id,
      number: 'INV-PARTIAL',
      status: InvoiceStatus.partiallyPaid,
      total: total,
      paidAmount: paidAmount,
      balanceDue: total - paidAmount,
      payments: [
        createInvoicePaymentEntity(
          invoiceId: id,
          amount: paidAmount,
        ),
      ],
    );
  }

  /// Creates an overdue invoice
  static Invoice createOverdueInvoice({
    String id = 'inv-overdue',
  }) {
    final date = DateTime.now().subtract(const Duration(days: 60));
    final dueDate = date.add(const Duration(days: 30));
    return createInvoiceEntity(
      id: id,
      number: 'INV-OVERDUE',
      status: InvoiceStatus.overdue,
      date: date,
      dueDate: dueDate,
    );
  }

  /// Creates a cancelled invoice
  static Invoice createCancelledInvoice({
    String id = 'inv-cancelled',
  }) {
    return createInvoiceEntity(
      id: id,
      number: 'INV-CANCELLED',
      status: InvoiceStatus.cancelled,
    );
  }

  /// Creates an invoice with multiple items
  static Invoice createInvoiceWithMultipleItems({
    String id = 'inv-multi-items',
    int itemCount = 5,
  }) {
    final items = createInvoiceItemEntityList(invoiceId: id, count: itemCount);
    final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final taxAmount = subtotal * 0.19;
    final total = subtotal + taxAmount;

    return createInvoiceEntity(
      id: id,
      number: 'INV-MULTI',
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      balanceDue: total,
    );
  }

  /// Creates an invoice with multiple payments
  static Invoice createInvoiceWithMultiplePayments({
    String id = 'inv-multi-payments',
    int paymentCount = 3,
  }) {
    final total = 300000.0;
    final payments = createInvoicePaymentEntityList(
      invoiceId: id,
      count: paymentCount,
      totalAmount: total,
    );

    return createInvoiceEntity(
      id: id,
      number: 'INV-MULTI-PAY',
      status: InvoiceStatus.paid,
      total: total,
      paidAmount: total,
      balanceDue: 0.0,
      payments: payments,
    );
  }

  /// Creates an invoice with discount
  static Invoice createInvoiceWithDiscount({
    String id = 'inv-discount',
    double discountPercentage = 10.0,
  }) {
    final subtotal = 100000.0;
    final discountAmount = subtotal * (discountPercentage / 100);
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * 0.19;
    final total = afterDiscount + taxAmount;

    return createInvoiceEntity(
      id: id,
      number: 'INV-DISCOUNT',
      subtotal: subtotal,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      total: total,
      balanceDue: total,
    );
  }

  /// Creates a confirmed invoice (ready for processing)
  static Invoice createConfirmedInvoice({
    String id = 'inv-confirmed',
  }) {
    return createInvoiceEntity(
      id: id,
      number: 'INV-CONFIRMED',
      status: InvoiceStatus.pending,
      items: createInvoiceItemEntityList(invoiceId: id, count: 2),
    );
  }

  /// Creates an invoice with credit note applied
  static Invoice createInvoiceWithCreditNote({
    String id = 'inv-credited',
    double creditedAmount = 50000.0,
  }) {
    final total = 119000.0;
    return createInvoiceEntity(
      id: id,
      number: 'INV-CREDITED',
      status: InvoiceStatus.partiallyCredited,
      total: total,
      creditedAmount: creditedAmount,
      balanceDue: total - creditedAmount,
    );
  }

  /// Creates a fully credited invoice
  static Invoice createFullyCreditedInvoice({
    String id = 'inv-fully-credited',
  }) {
    final total = 119000.0;
    return createInvoiceEntity(
      id: id,
      number: 'INV-FULLY-CREDITED',
      status: InvoiceStatus.credited,
      total: total,
      creditedAmount: total,
      balanceDue: 0.0,
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of invoices with different statuses
  static List<Invoice> createMixedStatusInvoices() {
    return [
      createDraftInvoice(id: 'inv-001'),
      createPendingInvoice(id: 'inv-002'),
      createPaidInvoice(id: 'inv-003'),
      createPartiallyPaidInvoice(id: 'inv-004'),
      createOverdueInvoice(id: 'inv-005'),
      createCancelledInvoice(id: 'inv-006'),
    ];
  }

  /// Creates invoices with different payment methods
  static List<Invoice> createInvoicesByPaymentMethod() {
    return [
      createInvoiceEntity(
        id: 'inv-001',
        paymentMethod: PaymentMethod.cash,
      ),
      createInvoiceEntity(
        id: 'inv-002',
        paymentMethod: PaymentMethod.creditCard,
      ),
      createInvoiceEntity(
        id: 'inv-003',
        paymentMethod: PaymentMethod.bankTransfer,
      ),
      createInvoiceEntity(
        id: 'inv-004',
        paymentMethod: PaymentMethod.credit,
      ),
    ];
  }
}
