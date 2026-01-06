// test/fixtures/credit_note_fixtures.dart
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note_item.dart';
import 'customer_fixtures.dart';
import 'invoice_fixtures.dart';

/// Test fixtures for CreditNotes module
class CreditNoteFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single credit note entity with default test data
  static CreditNote createCreditNoteEntity({
    String id = 'cn-001',
    String number = 'CN-001',
    DateTime? date,
    CreditNoteType type = CreditNoteType.partial,
    CreditNoteReason reason = CreditNoteReason.returnedGoods,
    String? reasonDescription,
    CreditNoteStatus status = CreditNoteStatus.draft,
    double subtotal = 50000.0,
    double taxPercentage = 19.0,
    double taxAmount = 9500.0,
    double total = 59500.0,
    String? notes,
    bool restoreInventory = true,
    bool inventoryRestored = false,
    DateTime? inventoryRestoredAt,
    DateTime? appliedAt,
    String? appliedById,
    String invoiceId = 'inv-001',
    String customerId = 'cust-001',
    String createdById = 'user-001',
    List<CreditNoteItem>? items,
  }) {
    final cnDate = date ?? DateTime(2024, 1, 5);

    return CreditNote(
      id: id,
      number: number,
      date: cnDate,
      type: type,
      reason: reason,
      reasonDescription: reasonDescription,
      status: status,
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      total: total,
      notes: notes,
      restoreInventory: restoreInventory,
      inventoryRestored: inventoryRestored,
      inventoryRestoredAt: inventoryRestoredAt,
      appliedAt: appliedAt,
      appliedById: appliedById,
      invoiceId: invoiceId,
      invoice: InvoiceFixtures.createInvoiceEntity(id: invoiceId),
      customerId: customerId,
      customer: CustomerFixtures.createCustomerEntity(id: customerId),
      createdById: createdById,
      items: items ?? [createCreditNoteItemEntity(creditNoteId: id)],
      createdAt: cnDate,
      updatedAt: cnDate,
    );
  }

  /// Creates a list of credit note entities
  static List<CreditNote> createCreditNoteEntityList(int count) {
    return List.generate(count, (index) {
      final date = DateTime(2024, 1, 5).add(Duration(days: index));
      return createCreditNoteEntity(
        id: 'cn-${(index + 1).toString().padLeft(3, '0')}',
        number: 'CN-${(index + 1).toString().padLeft(3, '0')}',
        date: date,
        total: (index + 1) * 50000.0,
      );
    });
  }

  // ============================================================================
  // CREDIT NOTE ITEM FIXTURES
  // ============================================================================

  /// Creates a single credit note item entity
  static CreditNoteItem createCreditNoteItemEntity({
    String id = 'cn-item-001',
    String description = 'Test Product',
    double quantity = 1.0,
    double unitPrice = 50000.0,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double subtotal = 50000.0,
    String? unit = 'pcs',
    String? notes,
    String creditNoteId = 'cn-001',
    String? productId = 'prod-001',
    String? invoiceItemId = 'inv-item-001',
  }) {
    return CreditNoteItem(
      id: id,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      subtotal: subtotal,
      unit: unit,
      notes: notes,
      creditNoteId: creditNoteId,
      productId: productId,
      invoiceItemId: invoiceItemId,
      createdAt: DateTime(2024, 1, 5),
      updatedAt: DateTime(2024, 1, 5),
    );
  }

  /// Creates a list of credit note item entities
  static List<CreditNoteItem> createCreditNoteItemEntityList({
    required String creditNoteId,
    int count = 2,
  }) {
    return List.generate(count, (index) {
      return createCreditNoteItemEntity(
        id: 'cn-item-${(index + 1).toString().padLeft(3, '0')}',
        description: 'Product ${index + 1}',
        quantity: (index + 1).toDouble(),
        unitPrice: (index + 1) * 25000.0,
        subtotal: (index + 1) * (index + 1) * 25000.0,
        creditNoteId: creditNoteId,
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        invoiceItemId: 'inv-item-${(index + 1).toString().padLeft(3, '0')}',
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates a draft credit note
  static CreditNote createDraftCreditNote({
    String id = 'cn-draft',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'DRAFT-CN-001',
      status: CreditNoteStatus.draft,
    );
  }

  /// Creates a confirmed credit note
  static CreditNote createConfirmedCreditNote({
    String id = 'cn-confirmed',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-CONFIRMED',
      status: CreditNoteStatus.confirmed,
      appliedAt: DateTime(2024, 1, 6),
      appliedById: 'user-001',
    );
  }

  /// Creates a cancelled credit note
  static CreditNote createCancelledCreditNote({
    String id = 'cn-cancelled',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-CANCELLED',
      status: CreditNoteStatus.cancelled,
    );
  }

  /// Creates a full credit note (entire invoice)
  static CreditNote createFullCreditNote({
    String id = 'cn-full',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-FULL',
      type: CreditNoteType.full,
      subtotal: 100000.0,
      taxAmount: 19000.0,
      total: 119000.0,
      items: createCreditNoteItemEntityList(creditNoteId: id, count: 3),
    );
  }

  /// Creates a partial credit note
  static CreditNote createPartialCreditNote({
    String id = 'cn-partial',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-PARTIAL',
      type: CreditNoteType.partial,
      subtotal: 50000.0,
      taxAmount: 9500.0,
      total: 59500.0,
    );
  }

  /// Creates a credit note for returned goods
  static CreditNote createCreditNoteForReturnedGoods({
    String id = 'cn-returned',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-RETURNED',
      reason: CreditNoteReason.returnedGoods,
      reasonDescription: 'Customer returned products in good condition',
      restoreInventory: true,
    );
  }

  /// Creates a credit note for damaged goods
  static CreditNote createCreditNoteForDamagedGoods({
    String id = 'cn-damaged',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-DAMAGED',
      reason: CreditNoteReason.damagedGoods,
      reasonDescription: 'Products received damaged',
      restoreInventory: false,
    );
  }

  /// Creates a credit note for billing error
  static CreditNote createCreditNoteForBillingError({
    String id = 'cn-billing-error',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-BILLING-ERROR',
      reason: CreditNoteReason.billingError,
      reasonDescription: 'Incorrect amount billed',
      restoreInventory: false,
    );
  }

  /// Creates a credit note for price adjustment
  static CreditNote createCreditNoteForPriceAdjustment({
    String id = 'cn-price-adj',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-PRICE-ADJ',
      reason: CreditNoteReason.priceAdjustment,
      reasonDescription: 'Price difference adjustment',
      restoreInventory: false,
    );
  }

  /// Creates a credit note with inventory restored
  static CreditNote createCreditNoteWithInventoryRestored({
    String id = 'cn-inventory-restored',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-INV-RESTORED',
      status: CreditNoteStatus.confirmed,
      restoreInventory: true,
      inventoryRestored: true,
      inventoryRestoredAt: DateTime(2024, 1, 6),
    );
  }

  /// Creates a credit note without inventory restoration
  static CreditNote createCreditNoteWithoutInventoryRestoration({
    String id = 'cn-no-restore',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-NO-RESTORE',
      status: CreditNoteStatus.confirmed,
      restoreInventory: false,
      inventoryRestored: false,
    );
  }

  /// Creates a credit note with multiple items
  static CreditNote createCreditNoteWithMultipleItems({
    String id = 'cn-multi-items',
    int itemCount = 5,
  }) {
    final items = createCreditNoteItemEntityList(creditNoteId: id, count: itemCount);
    final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final taxAmount = subtotal * 0.19;
    final total = subtotal + taxAmount;

    return createCreditNoteEntity(
      id: id,
      number: 'CN-MULTI',
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
    );
  }

  /// Creates a credit note for order cancellation
  static CreditNote createCreditNoteForOrderCancellation({
    String id = 'cn-cancelled-order',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-ORDER-CANCEL',
      type: CreditNoteType.full,
      reason: CreditNoteReason.returnedGoods,
      reasonDescription: 'Customer cancelled entire order',
      restoreInventory: true,
    );
  }

  /// Creates a credit note for customer dissatisfaction
  static CreditNote createCreditNoteForDissatisfaction({
    String id = 'cn-dissatisfaction',
  }) {
    return createCreditNoteEntity(
      id: id,
      number: 'CN-DISSATISFIED',
      reason: CreditNoteReason.customerDissatisfaction,
      reasonDescription: 'Customer not satisfied with product quality',
      restoreInventory: true,
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of credit notes with different statuses
  static List<CreditNote> createMixedStatusCreditNotes() {
    return [
      createDraftCreditNote(id: 'cn-001'),
      createConfirmedCreditNote(id: 'cn-002'),
      createCancelledCreditNote(id: 'cn-003'),
    ];
  }

  /// Creates credit notes by type
  static List<CreditNote> createCreditNotesByType() {
    return [
      createFullCreditNote(id: 'cn-001'),
      createPartialCreditNote(id: 'cn-002'),
      createPartialCreditNote(id: 'cn-003'),
    ];
  }

  /// Creates credit notes by reason
  static List<CreditNote> createCreditNotesByReason() {
    return [
      createCreditNoteForReturnedGoods(id: 'cn-001'),
      createCreditNoteForDamagedGoods(id: 'cn-002'),
      createCreditNoteForBillingError(id: 'cn-003'),
      createCreditNoteForPriceAdjustment(id: 'cn-004'),
      createCreditNoteForOrderCancellation(id: 'cn-005'),
    ];
  }

  /// Creates credit notes with inventory restoration status
  static List<CreditNote> createCreditNotesByInventoryRestoration() {
    return [
      createCreditNoteWithInventoryRestored(id: 'cn-001'),
      createCreditNoteWithoutInventoryRestoration(id: 'cn-002'),
      createCreditNoteEntity(
        id: 'cn-003',
        status: CreditNoteStatus.draft,
        restoreInventory: true,
        inventoryRestored: false,
      ),
    ];
  }
}
