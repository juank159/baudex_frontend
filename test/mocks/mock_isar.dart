// test/mocks/mock_isar.dart
//
// Mock ISAR implementation for testing without native library dependency.
// This provides in-memory storage using Maps and Lists to simulate ISAR collections.

import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
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

/// Mock ISAR database for testing
class MockIsar {
  bool _isOpen = true;
  int _autoIncrementId = 1;

  // In-memory storage for all collections
  final Map<int, SyncOperation> _syncOperations = {};
  final Map<int, IsarCategory> _categories = {};
  final Map<int, IsarCustomer> _customers = {};
  final Map<int, IsarCustomerCredit> _customerCredits = {};
  final Map<int, IsarProduct> _products = {};
  final Map<int, IsarExpense> _expenses = {};
  final Map<int, IsarInvoice> _invoices = {};
  final Map<int, IsarCreditNote> _creditNotes = {};
  final Map<int, IsarNotification> _notifications = {};
  final Map<int, IsarBankAccount> _bankAccounts = {};
  final Map<int, IsarSupplier> _suppliers = {};
  final Map<int, IsarPurchaseOrder> _purchaseOrders = {};
  final Map<int, IsarPurchaseOrderItem> _purchaseOrderItems = {};
  final Map<int, IsarInventoryMovement> _inventoryMovements = {};

  // Collection accessors
  MockIsarCollection<SyncOperation> get syncOperations =>
      MockIsarCollection<SyncOperation>(this, _syncOperations);

  MockIsarCollection<IsarCategory> get isarCategorys =>
      MockIsarCollection<IsarCategory>(this, _categories);

  MockIsarCollection<IsarCustomer> get isarCustomers =>
      MockIsarCollection<IsarCustomer>(this, _customers);

  MockIsarCollection<IsarCustomerCredit> get isarCustomerCredits =>
      MockIsarCollection<IsarCustomerCredit>(this, _customerCredits);

  MockIsarCollection<IsarProduct> get isarProducts =>
      MockIsarCollection<IsarProduct>(this, _products);

  MockIsarCollection<IsarExpense> get isarExpenses =>
      MockIsarCollection<IsarExpense>(this, _expenses);

  MockIsarCollection<IsarInvoice> get isarInvoices =>
      MockIsarCollection<IsarInvoice>(this, _invoices);

  MockIsarCollection<IsarCreditNote> get isarCreditNotes =>
      MockIsarCollection<IsarCreditNote>(this, _creditNotes);

  MockIsarCollection<IsarNotification> get isarNotifications =>
      MockIsarCollection<IsarNotification>(this, _notifications);

  MockIsarCollection<IsarBankAccount> get isarBankAccounts =>
      MockIsarCollection<IsarBankAccount>(this, _bankAccounts);

  MockIsarCollection<IsarSupplier> get isarSuppliers =>
      MockIsarCollection<IsarSupplier>(this, _suppliers);

  MockIsarCollection<IsarPurchaseOrder> get isarPurchaseOrders =>
      MockIsarCollection<IsarPurchaseOrder>(this, _purchaseOrders);

  MockIsarCollection<IsarPurchaseOrderItem> get isarPurchaseOrderItems =>
      MockIsarCollection<IsarPurchaseOrderItem>(this, _purchaseOrderItems);

  MockIsarCollection<IsarInventoryMovement> get isarInventoryMovements =>
      MockIsarCollection<IsarInventoryMovement>(this, _inventoryMovements);

  bool get isOpen => _isOpen;

  int _getNextId() => _autoIncrementId++;

  /// Execute a write transaction
  Future<T> writeTxn<T>(Future<T> Function() callback) async {
    if (!_isOpen) throw Exception('Database is closed');
    return await callback();
  }

  /// Execute a read transaction (optional in tests, just execute directly)
  Future<T> txn<T>(Future<T> Function() callback) async {
    if (!_isOpen) throw Exception('Database is closed');
    return await callback();
  }

  /// Clear all collections
  Future<void> clear() async {
    _syncOperations.clear();
    _categories.clear();
    _customers.clear();
    _customerCredits.clear();
    _products.clear();
    _expenses.clear();
    _invoices.clear();
    _creditNotes.clear();
    _notifications.clear();
    _bankAccounts.clear();
    _suppliers.clear();
    _purchaseOrders.clear();
    _purchaseOrderItems.clear();
    _inventoryMovements.clear();
  }

  /// Close the database
  Future<void> close({bool deleteFromDisk = false}) async {
    _isOpen = false;
    if (deleteFromDisk) {
      await clear();
    }
  }
}

/// Mock ISAR collection
class MockIsarCollection<T> {
  final MockIsar _isar;
  final Map<int, T> _storage;

  MockIsarCollection(this._isar, this._storage);

  /// Put an object into the collection
  Future<int> put(T object) async {
    int id;

    // Isar.autoIncrement is the minimum int64 value (-9223372036854775808)
    // We need to check if ID is 0 OR Isar.autoIncrement and assign a new one
    const isarAutoIncrement = -9223372036854775808; // Isar.autoIncrement value

    // Get or assign ID based on object type
    if (object is SyncOperation) {
      if (object.id == 0 || object.id == isarAutoIncrement) {
        object.id = _isar._getNextId();
      }
      id = object.id;
    } else if (object is IsarCategory) {
      if (object.id == 0 || object.id == isarAutoIncrement) {
        object.id = _isar._getNextId();
      }
      id = object.id;
    } else if (object is IsarCustomer) {
      if (object.id == 0 || object.id == isarAutoIncrement) {
        object.id = _isar._getNextId();
      }
      id = object.id;
    } else if (object is IsarProduct) {
      if (object.id == 0 || object.id == isarAutoIncrement) {
        object.id = _isar._getNextId();
      }
      id = object.id;
    } else {
      // For other types, generate ID
      id = _isar._getNextId();
    }

    _storage[id] = object;
    return id;
  }

  /// Put all objects
  Future<List<int>> putAll(List<T> objects) async {
    final ids = <int>[];
    for (final obj in objects) {
      ids.add(await put(obj));
    }
    return ids;
  }

  /// Get object by ID
  Future<T?> get(int id) async {
    return _storage[id];
  }

  /// Get all objects
  Future<List<T>> getAll(List<int> ids) async {
    return ids.map((id) => _storage[id]).whereType<T>().toList();
  }

  /// Delete object by ID
  Future<bool> delete(int id) async {
    return _storage.remove(id) != null;
  }

  /// Delete all objects
  Future<int> deleteAll(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      if (_storage.remove(id) != null) count++;
    }
    return count;
  }

  /// Count all objects
  Future<int> count() async {
    return _storage.length;
  }

  /// Clear the collection
  Future<void> clear() async {
    _storage.clear();
  }

  /// Create a query builder (returns Where clause)
  MockQueryBuilder<T> where() {
    return MockQueryBuilder<T>(this, _storage.values.toList());
  }

  /// Create a filter
  MockFilterBuilder<T> filter() {
    return MockFilterBuilder<T>(this, _storage.values.toList());
  }
}

/// Mock query builder for where() queries
class MockQueryBuilder<T> {
  final MockIsarCollection<T> _collection;
  final List<T> _items;

  MockQueryBuilder(this._collection, this._items);

  Future<List<T>> findAll() async => _items;

  Future<T?> findFirst() async => _items.isEmpty ? null : _items.first;

  Future<int> count() async => _items.length;

  Future<bool> deleteAll() async {
    for (final item in _items) {
      if (item is SyncOperation) {
        _collection._storage.remove(item.id);
      } else if (item is IsarCategory) {
        _collection._storage.remove(item.id);
      } else if (item is IsarCustomer) {
        _collection._storage.remove(item.id);
      } else if (item is IsarProduct) {
        _collection._storage.remove(item.id);
      }
    }
    return true;
  }
}

/// Mock filter builder for complex queries
class MockFilterBuilder<T> {
  final MockIsarCollection<T> _collection;
  List<T> _items;
  List<T>? _orAccumulator; // For OR operations
  late final List<T> _originalItems; // Keep original items for OR reset
  List<T>? _groupContextItems; // Items at the start of a group (for OR within groups)
  bool _negateNext = false; // Track if next filter should be negated

  MockFilterBuilder(this._collection, this._items) {
    _originalItems = List.from(_items);
  }

  // SyncOperation filters (removed - now using dynamic version below)

  MockFilterBuilder<T> entityIdEqualTo(String entityId) {
    if (T == SyncOperation) {
      _items = _items.where((item) {
        return (item as SyncOperation).entityId == entityId;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> organizationIdEqualTo(String organizationId) {
    if (T == SyncOperation) {
      _items = _items.where((item) {
        return (item as SyncOperation).organizationId == organizationId;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> syncedAtLessThan(DateTime date) {
    if (T == SyncOperation) {
      _items = _items.where((item) {
        final syncedAt = (item as SyncOperation).syncedAt;
        return syncedAt != null && syncedAt.isBefore(date);
      }).toList();
    }
    return this;
  }

  // Product filters
  MockFilterBuilder<T> serverIdEqualTo(String serverId) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final matches = (item as IsarProduct).serverId == serverId;
        return _negateNext ? !matches : matches;
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        final matches = (item as IsarCategory).serverId == serverId;
        return _negateNext ? !matches : matches;
      }).toList();
    } else if (T == IsarCustomer) {
      _items = _items.where((item) {
        final matches = (item as IsarCustomer).serverId == serverId;
        return _negateNext ? !matches : matches;
      }).toList();
    }
    _negateNext = false; // Reset negation flag
    return this;
  }

  MockFilterBuilder<T> tenantIdEqualTo(String tenantId) {
    // Note: tenantId filtering is handled at repository level
    // For now, return all items (multitenancy handled elsewhere)
    return this;
  }

  MockFilterBuilder<T> deletedAtIsNull() {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).deletedAt == null;
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).deletedAt == null;
      }).toList();
    } else if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).deletedAt == null;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> deletedAtIsNotNull() {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).deletedAt != null;
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).deletedAt != null;
      }).toList();
    } else if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).deletedAt != null;
      }).toList();
    }
    return this;
  }

  // Additional Product filters
  MockFilterBuilder<T> skuEqualTo(String sku) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).sku == sku;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> barcodeEqualTo(String barcode) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).barcode == barcode;
      }).toList();
    }
    return this;
  }

  // Category filters
  MockFilterBuilder<T> slugEqualTo(String slug) {
    if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).slug == slug;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> parentIdEqualTo(String parentId) {
    if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).parentId == parentId;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> parentIdIsNull() {
    if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).parentId == null;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> parentIdIsNotNull() {
    if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).parentId != null;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> statusEqualTo(dynamic status) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).status == status;
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).status == status;
      }).toList();
    } else if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).status == status;
      }).toList();
    } else if (T == SyncOperation) {
      _items = _items.where((item) {
        return (item as SyncOperation).status == status;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> typeEqualTo(dynamic type) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).type == type;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> categoryIdEqualTo(String categoryId) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).categoryId == categoryId;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> isSyncedEqualTo(bool isSynced) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).isSynced == isSynced;
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        return (item as IsarCategory).isSynced == isSynced;
      }).toList();
    } else if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).isSynced == isSynced;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> createdByIdEqualTo(String createdById) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        return (item as IsarProduct).createdById == createdById;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> stockGreaterThan(double value) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final stock = (item as IsarProduct).stock;
        return stock != null && stock > value;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> nameContains(String value, {bool caseSensitive = true}) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final name = (item as IsarProduct).name;
        if (caseSensitive) {
          return name.contains(value);
        } else {
          return name.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        final name = (item as IsarCategory).name;
        if (caseSensitive) {
          return name.contains(value);
        } else {
          return name.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> skuContains(String value, {bool caseSensitive = true}) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final sku = (item as IsarProduct).sku;
        if (caseSensitive) {
          return sku.contains(value);
        } else {
          return sku.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> barcodeContains(String value, {bool caseSensitive = true}) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final barcode = (item as IsarProduct).barcode;
        if (barcode == null) return false;
        if (caseSensitive) {
          return barcode.contains(value);
        } else {
          return barcode.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> descriptionContains(String value, {bool caseSensitive = true}) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final description = (item as IsarProduct).description;
        if (description == null) return false;
        if (caseSensitive) {
          return description.contains(value);
        } else {
          return description.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    } else if (T == IsarCategory) {
      _items = _items.where((item) {
        final description = (item as IsarCategory).description;
        if (description == null) return false;
        if (caseSensitive) {
          return description.contains(value);
        } else {
          return description.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  // ==================== CUSTOMER FILTERS ====================

  MockFilterBuilder<T> firstNameContains(String value, {bool caseSensitive = true}) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        final firstName = (item as IsarCustomer).firstName;
        if (caseSensitive) {
          return firstName.contains(value);
        } else {
          return firstName.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> lastNameContains(String value, {bool caseSensitive = true}) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        final lastName = (item as IsarCustomer).lastName;
        if (caseSensitive) {
          return lastName.contains(value);
        } else {
          return lastName.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> emailContains(String value, {bool caseSensitive = true}) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        final email = (item as IsarCustomer).email;
        if (email == null) return false;
        if (caseSensitive) {
          return email.contains(value);
        } else {
          return email.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> emailEqualTo(String email) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).email == email;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> documentNumberContains(String value, {bool caseSensitive = true}) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        final documentNumber = (item as IsarCustomer).documentNumber;
        if (caseSensitive) {
          return documentNumber.contains(value);
        } else {
          return documentNumber.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> documentNumberEqualTo(String documentNumber) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).documentNumber == documentNumber;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> companyNameContains(String value, {bool caseSensitive = true}) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        final companyName = (item as IsarCustomer).companyName;
        if (companyName == null) return false;
        if (caseSensitive) {
          return companyName.contains(value);
        } else {
          return companyName.toLowerCase().contains(value.toLowerCase());
        }
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> documentTypeEqualTo(dynamic documentType) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).documentType == documentType;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> cityEqualTo(String city) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).city == city;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> stateEqualTo(String state) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).state == state;
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> currentBalanceGreaterThan(num value) {
    if (T == IsarCustomer) {
      _items = _items.where((item) {
        return (item as IsarCustomer).currentBalance > value.toDouble();
      }).toList();
    }
    return this;
  }

  MockFilterBuilder<T> sortByTotalPurchasesDesc() {
    if (T == IsarCustomer) {
      _items.sort((a, b) {
        final customerA = a as IsarCustomer;
        final customerB = b as IsarCustomer;
        return customerB.totalPurchases.compareTo(customerA.totalPurchases);
      });
    }
    return this;
  }

  MockFilterBuilder<T> limit(int count) {
    _items = _items.take(count).toList();
    return this;
  }

  MockFilterBuilder<T> stockEqualTo(double value) {
    if (T == IsarProduct) {
      _items = _items.where((item) {
        final stock = (item as IsarProduct).stock;
        return stock != null && stock == value;
      }).toList();
    }
    return this;
  }

  // Group and conditional methods
  MockFilterBuilder<T> and() {
    // AND operation is implicit in chaining, just return this
    return this;
  }

  MockFilterBuilder<T> or() {
    // Start OR mode: accumulate current results and prepare for next condition
    if (_orAccumulator == null) {
      _orAccumulator = List.from(_items);
    } else {
      // Merge current items with accumulator (union)
      final currentSet = _items.toSet();
      final accumulatorSet = _orAccumulator!.toSet();
      _orAccumulator = accumulatorSet.union(currentSet).toList();
    }
    // Reset items to group context items if in a group, otherwise original items
    _items = List.from(_groupContextItems ?? _originalItems);
    return this;
  }

  MockFilterBuilder<T> not() {
    // NOT operation - set flag to negate the next filter
    _negateNext = true;
    return this;
  }

  MockFilterBuilder<T> group(Function builder) {
    // Save items at the start of the group for OR operations
    _groupContextItems = List.from(_items);

    // Execute the builder (which may use OR operations)
    // Accept dynamic builder to work with dynamic types from production code
    final result = builder(this) as MockFilterBuilder<T>;

    // If OR accumulator was used, finalize it
    if (result._orAccumulator != null) {
      // Merge final items with accumulator
      final currentSet = result._items.toSet();
      final accumulatorSet = result._orAccumulator!.toSet();
      result._items = accumulatorSet.union(currentSet).toList();
      result._orAccumulator = null; // Clear accumulator
    }

    // Clear group context
    _groupContextItems = null;
    return result;
  }

  // Sorting methods
  MockFilterBuilder<T> sortByPriorityDesc() {
    if (T == SyncOperation) {
      _items.sort((a, b) {
        final opA = a as SyncOperation;
        final opB = b as SyncOperation;
        return opB.priority.compareTo(opA.priority);
      });
    }
    return this;
  }

  MockFilterBuilder<T> sortByCreatedAtDesc() {
    if (T == IsarProduct) {
      _items.sort((a, b) {
        final itemA = a as IsarProduct;
        final itemB = b as IsarProduct;
        return itemB.createdAt.compareTo(itemA.createdAt);
      });
    } else if (T == SyncOperation) {
      _items.sort((a, b) {
        final opA = a as SyncOperation;
        final opB = b as SyncOperation;
        return opB.createdAt.compareTo(opA.createdAt);
      });
    }
    return this;
  }

  MockFilterBuilder<T> thenByCreatedAt() {
    if (T == SyncOperation) {
      _items.sort((a, b) {
        final opA = a as SyncOperation;
        final opB = b as SyncOperation;

        // First by priority (desc)
        final priorityCompare = opB.priority.compareTo(opA.priority);
        if (priorityCompare != 0) return priorityCompare;

        // Then by createdAt (asc)
        return opA.createdAt.compareTo(opB.createdAt);
      });
    }
    return this;
  }

  // Category sorting methods
  MockFilterBuilder<T> sortBySortOrder() {
    if (T == IsarCategory) {
      _items.sort((a, b) {
        final catA = a as IsarCategory;
        final catB = b as IsarCategory;
        return catA.sortOrder.compareTo(catB.sortOrder);
      });
    }
    return this;
  }

  MockFilterBuilder<T> sortByName() {
    if (T == IsarCategory) {
      _items.sort((a, b) {
        final catA = a as IsarCategory;
        final catB = b as IsarCategory;
        return catA.name.toLowerCase().compareTo(catB.name.toLowerCase());
      });
    }
    return this;
  }

  Future<List<T>> findAll() async => _items;

  Future<T?> findFirst() async => _items.isEmpty ? null : _items.first;

  Future<int> count() async => _items.length;

  Future<int> deleteAll() async {
    int count = 0;
    for (final item in _items) {
      if (item is SyncOperation) {
        if (_collection._storage.remove(item.id) != null) count++;
      } else if (item is IsarCategory) {
        if (_collection._storage.remove(item.id) != null) count++;
      } else if (item is IsarCustomer) {
        if (_collection._storage.remove(item.id) != null) count++;
      } else if (item is IsarProduct) {
        if (_collection._storage.remove(item.id) != null) count++;
      }
    }
    return count;
  }
}

/// Mock IsarDatabase wrapper for testing
/// This wraps MockIsar and provides the same interface as IsarDatabase
/// Uses composition and provides all methods that IsarDatabase provides
class MockIsarDatabase {
  final MockIsar _mockIsar;

  MockIsarDatabase(this._mockIsar);

  /// Getter for the mock ISAR instance (returns Isar-compatible type)
  /// Since MockIsar implements similar interface, we can use it directly
  dynamic get database => _mockIsar;

  /// Get pending sync operations
  Future<List<SyncOperation>> getPendingSyncOperations() async {
    return await _mockIsar.syncOperations
        .filter()
        .statusEqualTo(SyncStatus.pending)
        .findAll();
  }

  /// Get pending sync operations by type
  Future<List<SyncOperation>> getPendingSyncOperationsByType(String entityType) async {
    final allPending = await getPendingSyncOperations();
    return allPending.where((op) => op.entityType == entityType).toList();
  }

  /// Add sync operation
  Future<void> addSyncOperation(SyncOperation operation) async {
    await _mockIsar.writeTxn(() async {
      await _mockIsar.syncOperations.put(operation);
    });
  }

  /// Mark sync operation as completed
  Future<void> markSyncOperationCompleted(int operationId) async {
    await _mockIsar.writeTxn(() async {
      final operation = await _mockIsar.syncOperations.get(operationId);
      if (operation != null) {
        operation.status = SyncStatus.completed;
        operation.syncedAt = DateTime.now();
        await _mockIsar.syncOperations.put(operation);
      }
    });
  }

  /// Mark sync operation as failed
  Future<void> markSyncOperationFailed(int operationId, String error) async {
    await _mockIsar.writeTxn(() async {
      final operation = await _mockIsar.syncOperations.get(operationId);
      if (operation != null) {
        operation.status = SyncStatus.failed;
        operation.error = error;
        operation.retryCount++;
        await _mockIsar.syncOperations.put(operation);
      }
    });
  }

  /// Delete sync operation
  Future<void> deleteSyncOperation(int operationId) async {
    await _mockIsar.writeTxn(() async {
      await _mockIsar.syncOperations.delete(operationId);
    });
  }

  /// Delete sync operations by entity ID
  Future<void> deleteSyncOperationsByEntityId(String entityId) async {
    await _mockIsar.writeTxn(() async {
      final operations = await _mockIsar.syncOperations
          .filter()
          .entityIdEqualTo(entityId)
          .findAll();

      final ids = operations.map((op) => op.id).toList();
      for (final id in ids) {
        await _mockIsar.syncOperations.delete(id);
      }
    });
  }

  /// Clean old sync operations
  Future<void> cleanOldSyncOperations() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    await _mockIsar.writeTxn(() async {
      final oldOperations = await _mockIsar.syncOperations
          .filter()
          .statusEqualTo(SyncStatus.completed)
          .syncedAtLessThan(sevenDaysAgo)
          .findAll();

      for (final op in oldOperations) {
        await _mockIsar.syncOperations.delete(op.id);
      }
    });
  }

  /// Get sync operations counts
  Future<Map<String, int>> getSyncOperationsCounts() async {
    final allOps = await _mockIsar.syncOperations.where().findAll();

    return {
      'pending': allOps.where((op) => op.status == SyncStatus.pending).length,
      'inProgress': allOps.where((op) => op.status == SyncStatus.inProgress).length,
      'completed': allOps.where((op) => op.status == SyncStatus.completed).length,
      'failed': allOps.where((op) => op.status == SyncStatus.failed).length,
    };
  }

  /// List all sync operations (for debugging)
  Future<void> listAllSyncOperations() async {
    final operations = await _mockIsar.syncOperations.where().findAll();
    print('Total sync operations: ${operations.length}');
    for (final op in operations) {
      print('  - ${op.entityType} ${op.operationType.name} (${op.status.name})');
    }
  }
}
