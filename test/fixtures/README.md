# Test Fixtures

This directory contains comprehensive test fixtures for all main modules in the Baudex application. These fixtures provide realistic, reusable test data for unit tests, integration tests, and widget tests.

## Overview

Test fixtures are pre-configured test data objects that can be used across different tests to ensure consistency and reduce code duplication. Each fixture file corresponds to a main module in the application.

## Available Fixtures

### 1. Products (`product_fixtures.dart`)
- **ProductFixtures**: Factory methods for creating product entities and related data
- **Methods**:
  - `createProductEntity()` - Single product with customizable fields
  - `createProductEntityList(count)` - List of products
  - `createProductPriceEntity()` - Product price entity
  - `createLowStockProduct()` - Product with stock <= minStock
  - `createOutOfStockProduct()` - Product with 0 stock
  - `createInactiveProduct()` - Inactive product
  - `createServiceProduct()` - Service type product
  - `createProductWithMultiplePrices()` - Product with cost, retail, wholesale prices
  - `createProductWithDiscount()` - Product with discount applied
  - `createTaxExemptProduct()` - Tax-exempt product
  - `createProductWithRetention()` - Product with tax retention

### 2. Categories (`category_fixtures.dart`)
- **CategoryFixtures**: Factory methods for creating category entities
- **Methods**:
  - `createCategoryEntity()` - Single category
  - `createCategoryEntityList(count)` - List of categories
  - `createInactiveCategory()` - Inactive category
  - `createParentCategoryWithChildren()` - Hierarchical category structure
  - `createChildCategory()` - Child category with parent
  - `createCategoryTree()` - Multi-level category hierarchy
  - `createUnsyncedCategory()` - Unsynced category for offline testing
  - `createCategoryWithManyProducts()` - Popular category
  - `createEmptyCategory()` - Category with no products

### 3. Customers (`customer_fixtures.dart`)
- **CustomerFixtures**: Factory methods for creating customer entities
- **Methods**:
  - `createCustomerEntity()` - Single customer
  - `createCustomerEntityList(count)` - List of customers
  - `createCorporateCustomer()` - Company customer with NIT
  - `createIndividualCustomer()` - Individual customer
  - `createInactiveCustomer()` - Inactive customer
  - `createSuspendedCustomer()` - Suspended customer
  - `createCustomerWithOverdueBalance()` - Customer with pending balance
  - `createCustomerAtCreditLimit()` - Customer at credit limit
  - `createCustomerOverCreditLimit()` - Customer over credit limit
  - `createVIPCustomer()` - High-value customer
  - `createNewCustomer()` - New customer with no history
  - `createCustomerWithRecentActivity()` - Active customer

### 4. Suppliers (`supplier_fixtures.dart`)
- **SupplierFixtures**: Factory methods for creating supplier entities
- **Methods**:
  - `createSupplierEntity()` - Single supplier
  - `createSupplierEntityList(count)` - List of suppliers
  - `createInactiveSupplier()` - Inactive supplier
  - `createBlockedSupplier()` - Blocked supplier
  - `createSupplierWithDiscount()` - Supplier with volume discount
  - `createSupplierWithExtendedTerms()` - Extended payment terms
  - `createSupplierWithHighCreditLimit()` - High credit limit
  - `createInternationalSupplier()` - International supplier with USD
  - `createMinimalSupplier()` - Minimal required fields
  - `createCompleteSupplier()` - All fields populated

### 5. Expenses (`expense_fixtures.dart`)
- **ExpenseFixtures**: Factory methods for creating expense entities
- **Methods**:
  - `createExpenseEntity()` - Single expense
  - `createExpenseEntityList(count)` - List of expenses
  - `createExpenseCategoryEntity()` - Expense category
  - `createDraftExpense()` - Draft expense
  - `createPendingExpense()` - Pending approval
  - `createApprovedExpense()` - Approved expense
  - `createPaidExpense()` - Paid expense
  - `createRejectedExpense()` - Rejected expense
  - `createHighValueExpense()` - Requires approval
  - `createOperatingExpense()` - Operating type
  - `createAdministrativeExpense()` - Administrative type
  - `createSalesExpense()` - Sales type
  - `createCategoryOverBudget()` - Over budget category
  - `createCategoryNearBudgetLimit()` - Near budget limit

### 6. Invoices (`invoice_fixtures.dart`)
- **InvoiceFixtures**: Factory methods for creating invoice entities
- **Methods**:
  - `createInvoiceEntity()` - Single invoice
  - `createInvoiceEntityList(count)` - List of invoices
  - `createInvoiceItemEntity()` - Invoice line item
  - `createInvoicePaymentEntity()` - Invoice payment
  - `createDraftInvoice()` - Draft invoice
  - `createPendingInvoice()` - Pending invoice
  - `createPaidInvoice()` - Fully paid invoice
  - `createPartiallyPaidInvoice()` - Partially paid
  - `createOverdueInvoice()` - Overdue invoice
  - `createCancelledInvoice()` - Cancelled invoice
  - `createInvoiceWithMultipleItems()` - Multiple line items
  - `createInvoiceWithMultiplePayments()` - Multiple payments
  - `createInvoiceWithDiscount()` - With discount applied
  - `createConfirmedInvoice()` - Ready for processing
  - `createInvoiceWithCreditNote()` - Partially credited
  - `createFullyCreditedInvoice()` - Fully credited

### 7. Purchase Orders (`purchase_order_fixtures.dart`)
- **PurchaseOrderFixtures**: Factory methods for creating purchase order entities
- **Methods**:
  - `createPurchaseOrderEntity()` - Single purchase order
  - `createPurchaseOrderEntityList(count)` - List of purchase orders
  - `createPurchaseOrderItemEntity()` - PO line item
  - `createDraftPurchaseOrder()` - Draft PO
  - `createPendingPurchaseOrder()` - Pending approval
  - `createApprovedPurchaseOrder()` - Approved PO
  - `createSentPurchaseOrder()` - Sent to supplier
  - `createPartiallyReceivedPurchaseOrder()` - Partially received
  - `createFullyReceivedPurchaseOrder()` - Fully received
  - `createCancelledPurchaseOrder()` - Cancelled PO
  - `createRejectedPurchaseOrder()` - Rejected PO
  - `createUrgentPurchaseOrder()` - Urgent priority
  - `createPurchaseOrderWithMultipleItems()` - Multiple items
  - `createPurchaseOrderWithDiscount()` - With discount
  - `createOverduePurchaseOrder()` - Past expected delivery
  - `createPurchaseOrderWithDamagedItems()` - Damaged items received
  - `createPurchaseOrderWithMissingItems()` - Missing items

### 8. Inventory (`inventory_fixtures.dart`)
- **InventoryFixtures**: Factory methods for creating inventory movement entities
- **Methods**:
  - `createInventoryMovementEntity()` - Single movement
  - `createInventoryMovementEntityList(count)` - List of movements
  - `createInboundMovement()` - Inbound (purchase)
  - `createOutboundMovement()` - Outbound (sale)
  - `createAdjustmentMovement()` - Stock adjustment
  - `createTransferMovement()` - Warehouse transfer
  - `createTransferInMovement()` - Transfer in
  - `createTransferOutMovement()` - Transfer out
  - `createPendingMovement()` - Pending confirmation
  - `createCancelledMovement()` - Cancelled movement
  - `createMovementWithLot()` - With lot tracking
  - `createMovementWithExpiry()` - With expiry date
  - `createExpiredMovement()` - Expired product
  - `createDamagedGoodsMovement()` - Damaged goods
  - `createLostGoodsMovement()` - Lost/missing goods
  - `createReturnMovement()` - Customer return

### 9. Credit Notes (`credit_note_fixtures.dart`)
- **CreditNoteFixtures**: Factory methods for creating credit note entities
- **Methods**:
  - `createCreditNoteEntity()` - Single credit note
  - `createCreditNoteEntityList(count)` - List of credit notes
  - `createCreditNoteItemEntity()` - Credit note line item
  - `createDraftCreditNote()` - Draft credit note
  - `createConfirmedCreditNote()` - Confirmed credit note
  - `createCancelledCreditNote()` - Cancelled credit note
  - `createFullCreditNote()` - Full invoice credit
  - `createPartialCreditNote()` - Partial invoice credit
  - `createCreditNoteForReturnedGoods()` - Product return
  - `createCreditNoteForDamagedGoods()` - Damaged products
  - `createCreditNoteForBillingError()` - Billing error
  - `createCreditNoteForPriceAdjustment()` - Price adjustment
  - `createCreditNoteWithInventoryRestored()` - Inventory restored
  - `createCreditNoteWithMultipleItems()` - Multiple items
  - `createCreditNoteForOrderCancellation()` - Order cancelled

### 10. Customer Credits (`customer_credit_fixtures.dart`)
- **CustomerCreditFixtures**: Factory methods for creating customer credit entities
- **Methods**:
  - `createCustomerCreditEntity()` - Single customer credit
  - `createCustomerCreditEntityList(count)` - List of credits
  - `createCreditPaymentEntity()` - Credit payment
  - `createPendingCredit()` - Pending credit
  - `createPartiallyPaidCredit()` - Partially paid
  - `createPaidCredit()` - Fully paid
  - `createCancelledCredit()` - Cancelled credit
  - `createOverdueCredit()` - Overdue credit
  - `createCreditWithMultiplePayments()` - Multiple payments
  - `createCreditDueSoon()` - Due within 7 days
  - `createCreditWithLongTerms()` - 90-day terms
  - `createHighValueCredit()` - High value credit
  - `createLowValueCredit()` - Low value credit
  - `createCreditWithBankTransfer()` - Bank transfer payment

## Usage Examples

### Basic Usage

```dart
import 'package:baudex_desktop/test/fixtures/test_fixtures.dart';

void main() {
  test('should create product successfully', () {
    // Use default values
    final product = ProductFixtures.createProductEntity();

    expect(product.name, 'Test Product');
    expect(product.stock, 100.0);
  });

  test('should handle low stock products', () {
    // Use specialized fixture
    final lowStockProduct = ProductFixtures.createLowStockProduct();

    expect(lowStockProduct.isLowStock, true);
  });

  test('should create custom product', () {
    // Customize fields
    final customProduct = ProductFixtures.createProductEntity(
      id: 'custom-001',
      name: 'Custom Product',
      stock: 50.0,
      minStock: 5.0,
    );

    expect(customProduct.id, 'custom-001');
    expect(customProduct.name, 'Custom Product');
  });
}
```

### Creating Lists

```dart
test('should handle multiple products', () {
  // Create a list of 10 products
  final products = ProductFixtures.createProductEntityList(10);

  expect(products.length, 10);
  expect(products[0].id, 'prod-001');
  expect(products[9].id, 'prod-010');
});
```

### Complex Scenarios

```dart
test('should create invoice with items and payments', () {
  final invoice = InvoiceFixtures.createInvoiceEntity(
    id: 'inv-test',
    items: InvoiceFixtures.createInvoiceItemEntityList(
      invoiceId: 'inv-test',
      count: 3,
    ),
    payments: [
      InvoiceFixtures.createInvoicePaymentEntity(
        invoiceId: 'inv-test',
        amount: 100000.0,
      ),
    ],
  );

  expect(invoice.items.length, 3);
  expect(invoice.payments.length, 1);
  expect(invoice.hasPayments, true);
});
```

### Batch Fixtures

```dart
test('should handle mixed status invoices', () {
  final invoices = InvoiceFixtures.createMixedStatusInvoices();

  expect(invoices.length, 6);
  expect(invoices[0].status, InvoiceStatus.draft);
  expect(invoices[2].status, InvoiceStatus.paid);
  expect(invoices[4].status, InvoiceStatus.overdue);
});
```

## Best Practices

1. **Use Default Values**: Start with default fixtures and customize only what's needed for your test
2. **Specialized Fixtures**: Use specialized fixtures (like `createLowStockProduct()`) for specific scenarios
3. **Batch Helpers**: Use batch creation helpers for tests requiring multiple related entities
4. **Consistency**: Fixtures ensure consistent test data across your test suite
5. **Isolation**: Each test should create its own fixtures to avoid test interdependence
6. **Customization**: Always prefer customizing existing fixtures over creating new ones

## Adding New Fixtures

When adding new fixtures:

1. Follow the existing naming convention: `create{EntityName}{Variant}()`
2. Provide sensible defaults for all required fields
3. Allow customization through optional parameters
4. Group related fixtures together
5. Add documentation comments
6. Export the new fixture class in `test_fixtures.dart`

## File Structure

```
test/fixtures/
├── README.md                         # This file
├── test_fixtures.dart                # Index file exporting all fixtures
├── product_fixtures.dart             # Product module fixtures
├── category_fixtures.dart            # Category module fixtures
├── customer_fixtures.dart            # Customer module fixtures
├── supplier_fixtures.dart            # Supplier module fixtures
├── expense_fixtures.dart             # Expense module fixtures
├── invoice_fixtures.dart             # Invoice module fixtures
├── purchase_order_fixtures.dart      # Purchase order module fixtures
├── inventory_fixtures.dart           # Inventory module fixtures
├── credit_note_fixtures.dart         # Credit note module fixtures
└── customer_credit_fixtures.dart     # Customer credit module fixtures
```

## Integration with Tests

These fixtures are designed to work seamlessly with:
- **Unit Tests**: Testing individual use cases and business logic
- **Widget Tests**: Testing UI components with realistic data
- **Integration Tests**: Testing complete user flows
- **Mock Data**: Creating mock responses for repository tests

## Maintenance

- Keep fixtures updated when domain entities change
- Remove deprecated fixtures when features are removed
- Add new specialized fixtures as new test scenarios emerge
- Document any breaking changes in fixture APIs
