// lib/app/data/local/repositories_registry.dart
import '../../../features/products/data/repositories/product_offline_repository.dart';
import '../../../features/customers/data/repositories/customer_offline_repository.dart';
import '../../../features/categories/data/repositories/category_offline_repository.dart';
import '../../../features/invoices/data/repositories/invoice_offline_repository.dart';
import '../../../features/dashboard/data/repositories/notification_offline_repository.dart';
import '../../../features/inventory/data/repositories/inventory_offline_repository.dart';
// ⭐ FASE 1 - Repositorios adicionales para implementación offline-first completa
import '../../../features/suppliers/data/repositories/supplier_offline_repository.dart';
import '../../../features/expenses/data/repositories/expense_offline_repository.dart';
import '../../../features/bank_accounts/data/repositories/bank_account_offline_repository.dart';
import '../../../features/purchase_orders/data/repositories/purchase_order_offline_repository.dart';
import '../../../features/credit_notes/data/repositories/credit_note_offline_repository.dart';
import '../../../features/customer_credits/data/repositories/customer_credit_offline_repository.dart';

/// Estadísticas de sincronización por repositorio
class RepositorySyncStats {
  final int totalCount;
  final int unsyncedCount;
  final int unsyncedDeletedCount;
  final DateTime? lastSyncAt;

  const RepositorySyncStats({
    required this.totalCount,
    required this.unsyncedCount,
    required this.unsyncedDeletedCount,
    this.lastSyncAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'unsyncedCount': unsyncedCount,
      'unsyncedDeletedCount': unsyncedDeletedCount,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }
}

/// Registry for all offline repositories
/// Provides centralized access to offline repositories across all features
///
/// Note: Sync operations are handled by SyncService via the sync queue,
/// not by individual repositories. This registry provides utility methods
/// for querying repository status.
class RepositoriesRegistry {
  // Singleton instance
  static final RepositoriesRegistry _instance = RepositoriesRegistry._internal();
  static RepositoriesRegistry get instance => _instance;

  factory RepositoriesRegistry({
    ProductOfflineRepository? products,
    CustomerOfflineRepository? customers,
    CategoryOfflineRepository? categories,
    InvoiceOfflineRepository? invoices,
    NotificationOfflineRepository? notifications,
    InventoryOfflineRepository? inventory,
    // ⭐ FASE 1 - Repositorios adicionales
    SupplierOfflineRepository? suppliers,
    ExpenseOfflineRepository? expenses,
    BankAccountOfflineRepository? bankAccounts,
    PurchaseOrderOfflineRepository? purchaseOrders,
    CreditNoteOfflineRepository? creditNotes,
    CustomerCreditOfflineRepository? customerCredits,
  }) {
    // Si se proporcionan repositorios, actualizar la instancia singleton
    if (products != null) _instance._products = products;
    if (customers != null) _instance._customers = customers;
    if (categories != null) _instance._categories = categories;
    if (invoices != null) _instance._invoices = invoices;
    if (notifications != null) _instance._notifications = notifications;
    if (inventory != null) _instance._inventory = inventory;
    // ⭐ FASE 1 - Repositorios adicionales
    if (suppliers != null) _instance._suppliers = suppliers;
    if (expenses != null) _instance._expenses = expenses;
    if (bankAccounts != null) _instance._bankAccounts = bankAccounts;
    if (purchaseOrders != null) _instance._purchaseOrders = purchaseOrders;
    if (creditNotes != null) _instance._creditNotes = creditNotes;
    if (customerCredits != null) _instance._customerCredits = customerCredits;
    return _instance;
  }

  RepositoriesRegistry._internal();

  // Repositorios offline (privados para permitir actualización)
  ProductOfflineRepository? _products;
  CustomerOfflineRepository? _customers;
  CategoryOfflineRepository? _categories;
  InvoiceOfflineRepository? _invoices;
  NotificationOfflineRepository? _notifications;
  InventoryOfflineRepository? _inventory;
  // ⭐ FASE 1 - Repositorios adicionales
  SupplierOfflineRepository? _suppliers;
  ExpenseOfflineRepository? _expenses;
  BankAccountOfflineRepository? _bankAccounts;
  PurchaseOrderOfflineRepository? _purchaseOrders;
  CreditNoteOfflineRepository? _creditNotes;
  CustomerCreditOfflineRepository? _customerCredits;

  // Getters públicos
  ProductOfflineRepository? get products => _products;
  CustomerOfflineRepository? get customers => _customers;
  CategoryOfflineRepository? get categories => _categories;
  InvoiceOfflineRepository? get invoices => _invoices;
  NotificationOfflineRepository? get notifications => _notifications;
  InventoryOfflineRepository? get inventory => _inventory;
  // ⭐ FASE 1 - Getters adicionales
  SupplierOfflineRepository? get suppliers => _suppliers;
  ExpenseOfflineRepository? get expenses => _expenses;
  BankAccountOfflineRepository? get bankAccounts => _bankAccounts;
  PurchaseOrderOfflineRepository? get purchaseOrders => _purchaseOrders;
  CreditNoteOfflineRepository? get creditNotes => _creditNotes;
  CustomerCreditOfflineRepository? get customerCredits => _customerCredits;

  // ==================== SYNC STATISTICS ====================

  /// Obtener total de entidades sin sincronizar en todos los repositorios
  ///
  /// Note: The actual sync tracking is done by SyncService via the sync queue.
  /// This method returns 0 as sync status should be queried from SyncService.
  Future<int> getTotalUnsyncedCount() async {
    // Sync tracking is handled by SyncService
    // This is a stub method for compatibility
    return 0;
  }

  /// Obtener estadísticas de sincronización por repositorio
  ///
  /// Note: Returns empty stats. Actual sync status is tracked by SyncService.
  Future<Map<String, RepositorySyncStats>> getAllSyncStats() async {
    final Map<String, RepositorySyncStats> stats = {};

    for (final repoName in registeredRepositories) {
      stats[repoName] = const RepositorySyncStats(
        totalCount: 0,
        unsyncedCount: 0,
        unsyncedDeletedCount: 0,
      );
    }

    return stats;
  }

  /// Obtener lista de repositorios que necesitan sincronización
  ///
  /// Note: Returns empty list. Sync needs are determined by SyncService queue.
  Future<List<String>> getRepositoriesNeedingSync() async {
    // Sync tracking is handled by SyncService
    return [];
  }

  // ==================== UTILITY METHODS ====================

  /// Verificar si el registry está configurado correctamente
  bool get isConfigured {
    return _products != null ||
        _customers != null ||
        _categories != null ||
        _invoices != null ||
        _notifications != null ||
        _inventory != null ||
        _suppliers != null ||
        _expenses != null ||
        _bankAccounts != null ||
        _purchaseOrders != null ||
        _creditNotes != null ||
        _customerCredits != null;
  }

  /// Obtener lista de repositorios registrados
  List<String> get registeredRepositories {
    final List<String> registered = [];
    if (_products != null) registered.add('products');
    if (_customers != null) registered.add('customers');
    if (_categories != null) registered.add('categories');
    if (_invoices != null) registered.add('invoices');
    if (_notifications != null) registered.add('notifications');
    if (_inventory != null) registered.add('inventory');
    // ⭐ FASE 1 - Repositorios adicionales
    if (_suppliers != null) registered.add('suppliers');
    if (_expenses != null) registered.add('expenses');
    if (_bankAccounts != null) registered.add('bankAccounts');
    if (_purchaseOrders != null) registered.add('purchaseOrders');
    if (_creditNotes != null) registered.add('creditNotes');
    if (_customerCredits != null) registered.add('customerCredits');
    return registered;
  }

  /// Información de debug
  void printDebugInfo() {
    print('📊 RepositoriesRegistry Debug Info:');
    print('   Registrados: ${registeredRepositories.join(', ')}');
    print('   Configurado: $isConfigured');
  }
}
