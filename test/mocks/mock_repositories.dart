// test/mocks/mock_repositories.dart
import 'package:mocktail/mocktail.dart';

// Product repository
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';

// Category repository
import 'package:baudex_desktop/features/categories/domain/repositories/category_repository.dart';

// Customer repository
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';

// Supplier repository
import 'package:baudex_desktop/features/suppliers/domain/repositories/supplier_repository.dart';

// Expense repository
import 'package:baudex_desktop/features/expenses/domain/repositories/expense_repository.dart';

// Invoice repository
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';

// Purchase Order repository
import 'package:baudex_desktop/features/purchase_orders/domain/repositories/purchase_order_repository.dart';

// Inventory repository
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';

// Credit Note repository
import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';

/// Mock repository classes using mocktail

class MockProductRepository extends Mock implements ProductRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockSupplierRepository extends Mock implements SupplierRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockInvoiceRepository extends Mock implements InvoiceRepository {}

class MockPurchaseOrderRepository extends Mock
    implements PurchaseOrderRepository {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockCreditNoteRepository extends Mock implements CreditNoteRepository {}
