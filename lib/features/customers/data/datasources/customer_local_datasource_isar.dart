// lib/features/customers/data/datasources/customer_local_datasource_isar.dart
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/customer_model.dart';
import '../models/customer_stats_model.dart';
import '../models/isar/isar_customer.dart';
import 'customer_local_datasource.dart';

/// Implementation of CustomerLocalDataSource using Isar database for offline-first persistence.
///
/// This implementation provides true offline-first capabilities with:
/// - Persistent storage that survives app restarts
/// - Tenant isolation through proper filtering
/// - Efficient querying with indexes
/// - Support for conflict detection and versioning
class CustomerLocalDataSourceIsar implements CustomerLocalDataSource {
  final Isar _isar;

  /// In-memory cache for customer stats (not persisted to avoid stale data)
  CustomerStatsModel? _cachedStats;

  CustomerLocalDataSourceIsar() : _isar = IsarDatabase.instance.database;

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    try {
      await _isar.writeTxn(() async {
        final isarCustomers = <IsarCustomer>[];

        for (final customer in customers) {
          var existingCustomer = await _isar.isarCustomers
              .filter()
              .serverIdEqualTo(customer.id)
              .findFirst();

          if (existingCustomer != null) {
            existingCustomer.updateFromModel(customer);
            isarCustomers.add(existingCustomer);
          } else {
            isarCustomers.add(IsarCustomer.fromModel(customer));
          }
        }

        await _isar.isarCustomers.putAllByServerId(isarCustomers);
      });
    } catch (e) {
      throw CacheException('Failed to cache customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCachedCustomers() async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByFirstName()
          .findAll();

      if (isarCustomers.isEmpty) {
        throw CacheException.notFound;
      }

      return isarCustomers.map((isarCustomer) {
        final entity = isarCustomer.toEntity();
        return CustomerModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached customers: $e');
    }
  }

  @override
  Future<void> cacheCustomerStats(CustomerStatsModel stats) async {
    _cachedStats = stats;
  }

  @override
  Future<CustomerStatsModel?> getCachedCustomerStats() async {
    return _cachedStats;
  }

  @override
  Future<void> cacheCustomer(CustomerModel customer) async {
    try {
      await _isar.writeTxn(() async {
        var existingCustomer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(customer.id)
            .findFirst();

        if (existingCustomer != null) {
          existingCustomer.updateFromModel(customer);
          await _isar.isarCustomers.put(existingCustomer);
        } else {
          final isarCustomer = IsarCustomer.fromModel(customer);
          await _isar.isarCustomers.put(isarCustomer);
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache customer: $e');
    }
  }

  @override
  Future<CustomerModel?> getCachedCustomer(String id) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return null;
      }

      final entity = isarCustomer.toEntity();
      return CustomerModel.fromEntity(entity);
    } catch (e) {
      throw CacheException('Failed to get cached customer: $e');
    }
  }

  @override
  Future<void> removeCachedCustomer(String id) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (customer != null) {
          customer.softDelete();
          await _isar.isarCustomers.put(customer);
        }
      });
    } catch (e) {
      throw CacheException('Failed to remove cached customer: $e');
    }
  }

  @override
  Future<void> clearCustomerCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarCustomers.clear();
      });
      _cachedStats = null;
    } catch (e) {
      throw CacheException('Failed to clear customer cache: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    return true;
  }

  @override
  Future<IsarCustomer?> getIsarCustomer(String id) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      return isarCustomer;
    } catch (e) {
      return null;
    }
  }

  /// Additional utility methods for ISAR-specific operations

  /// Get all customers that need synchronization
  Future<List<IsarCustomer>> getUnsyncedCustomers() async {
    try {
      return await _isar.isarCustomers
          .filter()
          .isSyncedEqualTo(false)
          .findAll();
    } catch (e) {
      throw CacheException('Failed to get unsynced customers: $e');
    }
  }

  /// Search customers by name or email
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();

      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .group((q) => q
              .firstNameContains(lowercaseQuery, caseSensitive: false)
              .or()
              .lastNameContains(lowercaseQuery, caseSensitive: false)
              .or()
              .emailContains(lowercaseQuery, caseSensitive: false))
          .findAll();

      return isarCustomers.map((isarCustomer) {
        final entity = isarCustomer.toEntity();
        return CustomerModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      throw CacheException('Failed to search customers: $e');
    }
  }

  /// Get active customers only
  Future<List<CustomerModel>> getActiveCustomers() async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .statusEqualTo(IsarCustomerStatus.active)
          .sortByFirstName()
          .findAll();

      return isarCustomers.map((isarCustomer) {
        final entity = isarCustomer.toEntity();
        return CustomerModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      throw CacheException('Failed to get active customers: $e');
    }
  }

  /// Get customer by document number
  Future<CustomerModel?> getCustomerByDocument(String documentNumber) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .documentNumberEqualTo(documentNumber)
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return null;
      }

      final entity = isarCustomer.toEntity();
      return CustomerModel.fromEntity(entity);
    } catch (e) {
      throw CacheException('Failed to get customer by document: $e');
    }
  }

  /// Implementación del contrato `CustomerLocalDataSource.getCachedCustomerByDocument`.
  /// Misma lógica que `getCustomerByDocument` pero null-safe (no lanza
  /// excepciones en cache miss — apropiado para fallback offline en el
  /// repository).
  @override
  Future<CustomerModel?> getCachedCustomerByDocument(
    String documentNumber,
  ) async {
    try {
      return await getCustomerByDocument(documentNumber);
    } catch (e) {
      print('⚠️ Error al buscar cliente por documento (Isar DS): $e');
      return null;
    }
  }

  /// Get customer by email
  Future<CustomerModel?> getCustomerByEmail(String email) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .emailEqualTo(email)
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return null;
      }

      final entity = isarCustomer.toEntity();
      return CustomerModel.fromEntity(entity);
    } catch (e) {
      throw CacheException('Failed to get customer by email: $e');
    }
  }

  /// Get total number of cached customers
  Future<int> getCustomerCount() async {
    try {
      return await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .count();
    } catch (e) {
      throw CacheException('Failed to get customer count: $e');
    }
  }

  /// Check if customer exists by server ID
  Future<bool> hasCustomer(String id) async {
    try {
      final count = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .count();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Mark customer as synced
  Future<void> markAsSynced(String id) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (customer != null) {
          customer.markAsSynced();
          await _isar.isarCustomers.put(customer);
        }
      });
    } catch (e) {
      throw CacheException('Failed to mark customer as synced: $e');
    }
  }

  /// Update customer balance
  Future<void> updateCustomerBalance(String id, double amount) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (customer != null) {
          customer.updateBalance(amount);
          await _isar.isarCustomers.put(customer);
        }
      });
    } catch (e) {
      throw CacheException('Failed to update customer balance: $e');
    }
  }

  /// Record a purchase for a customer
  Future<void> recordCustomerPurchase(String id, double amount) async {
    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (customer != null) {
          customer.recordPurchase(amount);
          await _isar.isarCustomers.put(customer);
        }
      });
    } catch (e) {
      throw CacheException('Failed to record customer purchase: $e');
    }
  }
}
