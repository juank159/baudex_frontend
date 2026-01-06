// test/helpers/test_isar_helper.dart

// Import ISAR models (not schemas, as we're using mocks)
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/isar/isar_customer_credit.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/expenses/data/models/isar/isar_expense.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/credit_notes/data/models/isar/isar_credit_note.dart';
import 'package:baudex_desktop/features/notifications/data/models/isar/isar_notification.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/isar/isar_bank_account.dart';
import 'package:baudex_desktop/features/suppliers/data/models/isar/isar_supplier.dart';
import 'package:baudex_desktop/features/purchase_orders/data/models/isar/isar_purchase_order.dart';
import 'package:baudex_desktop/features/purchase_orders/data/models/isar/isar_purchase_order_item.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';

// Import MockIsar instead of real Isar
import '../mocks/mock_isar.dart';

/// Helper class for creating and managing mock ISAR instances for testing
/// WITHOUT requiring the native ISAR library.
///
/// This uses an in-memory Map-based mock instead of the real ISAR database,
/// allowing tests to run in any environment without native dependencies.
///
/// Usage:
/// ```dart
/// void main() {
///   late MockIsar isar;
///
///   setUp(() async {
///     isar = await TestIsarHelper.createInMemoryIsar();
///   });
///
///   tearDown(() async {
///     await TestIsarHelper.cleanAndClose(isar);
///   });
/// }
/// ```
class TestIsarHelper {
  /// Creates a mock in-memory ISAR instance with all collections
  ///
  /// This returns a MockIsar instance that simulates ISAR behavior
  /// using in-memory Maps, without requiring the native library.
  static Future<MockIsar> createInMemoryIsar() async {
    return MockIsar();
  }

  /// Seeds the database with test products
  static Future<void> seedProducts(
    MockIsar isar,
    int count, {
    bool synced = true,
  }) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < count; i++) {
        final product = IsarProduct.create(
          serverId: 'prod-test-$i',
          name: 'Test Product $i',
          description: 'Test description for product $i',
          sku: 'SKU-$i',
          barcode: 'BARCODE-$i',
          type: IsarProductType.product,
          status: IsarProductStatus.active,
          categoryId: 'cat-test-1',
          stock: 100.0 + i,
          minStock: 10.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: synced,
          lastSyncAt: synced ? DateTime.now() : null,
        );
        await isar.isarProducts.put(product);
      }
    });
  }

  /// Seeds the database with test categories
  static Future<void> seedCategories(
    MockIsar isar,
    int count, {
    bool synced = true,
  }) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < count; i++) {
        final category = IsarCategory.create(
          serverId: 'cat-test-$i',
          name: 'Test Category $i',
          slug: 'test-category-$i',
          description: 'Test description for category $i',
          status: IsarCategoryStatus.active,
          sortOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: synced,
          lastSyncAt: synced ? DateTime.now() : null,
        );
        await isar.isarCategorys.put(category);
      }
    });
  }

  /// Seeds the database with test customers
  static Future<void> seedCustomers(
    MockIsar isar,
    int count, {
    bool synced = true,
  }) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < count; i++) {
        final customer = IsarCustomer.create(
          serverId: 'cust-test-$i',
          firstName: 'John',
          lastName: 'Doe $i',
          email: 'customer$i@test.com',
          documentType: IsarDocumentType.cc,
          documentNumber: 'DOC-$i',
          phone: '+1234567890',
          address: 'Test Address $i',
          status: IsarCustomerStatus.active,
          creditLimit: 1000.0,
          currentBalance: 0.0,
          paymentTerms: 30,
          totalPurchases: 0.0,
          totalOrders: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: synced,
          lastSyncAt: synced ? DateTime.now() : null,
        );
        await isar.isarCustomers.put(customer);
      }
    });
  }

  /// Seeds the database with test sync operations
  static Future<void> seedSyncOperations(
    MockIsar isar,
    int count, {
    SyncStatus status = SyncStatus.pending,
    SyncOperationType operationType = SyncOperationType.create,
    String entityType = 'Product',
  }) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < count; i++) {
        final operation = SyncOperation.create(
          entityType: entityType,
          entityId: 'entity-$i',
          operationType: operationType,
          payload: '{"id": "entity-$i", "name": "Test $i"}',
          organizationId: 'org-test-1',
        );
        // Set status if different from default (pending)
        if (status != SyncStatus.pending) {
          operation.status = status;
        }
        await isar.syncOperations.put(operation);
      }
    });
  }

  /// Clears all collections in the database
  static Future<void> clearAll(MockIsar isar) async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }

  /// Closes the database and deletes it from disk
  static Future<void> cleanAndClose(MockIsar isar) async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
  }

  /// Gets statistics for all collections
  static Future<Map<String, int>> getStats(MockIsar isar) async {
    return {
      'syncOperations': await isar.syncOperations.count(),
      'categories': await isar.isarCategorys.count(),
      'customers': await isar.isarCustomers.count(),
      'customerCredits': await isar.isarCustomerCredits.count(),
      'products': await isar.isarProducts.count(),
      'expenses': await isar.isarExpenses.count(),
      'invoices': await isar.isarInvoices.count(),
      'creditNotes': await isar.isarCreditNotes.count(),
      'notifications': await isar.isarNotifications.count(),
      'bankAccounts': await isar.isarBankAccounts.count(),
      'suppliers': await isar.isarSuppliers.count(),
      'purchaseOrders': await isar.isarPurchaseOrders.count(),
      'purchaseOrderItems': await isar.isarPurchaseOrderItems.count(),
      'inventoryMovements': await isar.isarInventoryMovements.count(),
    };
  }

  /// Verifies database integrity by attempting to count all collections
  static Future<bool> verifyIntegrity(MockIsar isar) async {
    try {
      await isar.syncOperations.count();
      await isar.isarCategorys.count();
      await isar.isarCustomers.count();
      await isar.isarCustomerCredits.count();
      await isar.isarProducts.count();
      await isar.isarExpenses.count();
      await isar.isarInvoices.count();
      await isar.isarCreditNotes.count();
      await isar.isarNotifications.count();
      await isar.isarBankAccounts.count();
      await isar.isarSuppliers.count();
      await isar.isarPurchaseOrders.count();
      await isar.isarPurchaseOrderItems.count();
      await isar.isarInventoryMovements.count();
      return true;
    } catch (e) {
      return false;
    }
  }
}
