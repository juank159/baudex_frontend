// lib/features/customers/data/repositories/customer_offline_repository.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../domain/entities/customer.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/customer_stats.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/isar/isar_customer.dart';

/// Implementación offline del repositorio de clientes usando ISAR
class CustomerOfflineRepository implements CustomerRepository {
  final dynamic _database;

  CustomerOfflineRepository({dynamic database})
      : _database = database ?? IsarDatabase.instance;

  dynamic get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<Customer>>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    CustomerStatus? status,
    DocumentType? documentType,
    String? city,
    String? state,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      var query = _isar.isarCustomers.filter().deletedAtIsNull();

      // Apply filters
      if (search != null && search.isNotEmpty) {
        query = query.and().group((q) => q
            .firstNameContains(search, caseSensitive: false)
            .or()
            .lastNameContains(search, caseSensitive: false)
            .or()
            .emailContains(search, caseSensitive: false)
            .or()
            .documentNumberContains(search, caseSensitive: false)
            .or()
            .companyNameContains(search, caseSensitive: false));
      }

      if (status != null) {
        final isarStatus = _mapCustomerStatus(status);
        query = query.and().statusEqualTo(isarStatus);
      }

      if (documentType != null) {
        final isarDocType = _mapDocumentType(documentType);
        query = query.and().documentTypeEqualTo(isarDocType);
      }

      if (city != null && city.isNotEmpty) {
        query = query.and().cityEqualTo(city);
      }

      if (state != null && state.isNotEmpty) {
        query = query.and().stateEqualTo(state);
      }

      // Get all results (ISAR sorting/pagination no funciona bien, hacerlo en Dart)
      final allResults = await query.findAll() as List<IsarCustomer>;
      final totalItems = allResults.length;

      // Ordenar en Dart
      allResults.sort((a, b) {
        int comparison = 0;
        if (sortBy == 'name') {
          comparison = a.firstName.compareTo(b.firstName);
        } else if (sortBy == 'email') {
          comparison = (a.email ?? '').compareTo(b.email ?? '');
        } else if (sortBy == 'createdAt') {
          comparison = a.createdAt.compareTo(b.createdAt);
        } else if (sortBy == 'totalPurchases') {
          comparison = a.totalPurchases.compareTo(b.totalPurchases);
        } else {
          comparison = a.firstName.compareTo(b.firstName);
        }
        return sortOrder == 'desc' ? -comparison : comparison;
      });

      // Paginar manualmente
      final offset = (page - 1) * limit;
      final start = offset.clamp(0, allResults.length);
      final end = (start + limit).clamp(0, allResults.length);
      final isarCustomers = allResults.sublist(start, end);

      // Convert to domain entities
      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();

      // Create pagination meta
      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: customers, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer?>> getDefaultCustomer(String customerId) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .findFirst();

      return Right(isarCustomer?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading default customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerByDocument(
    DocumentType documentType,
    String documentNumber,
  ) async {
    try {
      final isarDocType = _mapDocumentType(documentType);
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .documentTypeEqualTo(isarDocType)
          .and()
          .documentNumberEqualTo(documentNumber)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading customer by document: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerByEmail(String email) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .emailEqualTo(email)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading customer by email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(
    String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .firstNameContains(searchTerm, caseSensitive: false)
              .or()
              .lastNameContains(searchTerm, caseSensitive: false)
              .or()
              .emailContains(searchTerm, caseSensitive: false)
              .or()
              .documentNumberContains(searchTerm, caseSensitive: false)
              .or()
              .companyNameContains(searchTerm, caseSensitive: false))
          .limit(limit)
          .findAll() as List<IsarCustomer>;

      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error searching customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerStats>> getCustomerStats() async {
    try {
      final allCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomer>;

      final total = allCustomers.length;
      final active = allCustomers.where((c) => c.status == IsarCustomerStatus.active).length;
      final inactive = allCustomers.where((c) => c.status == IsarCustomerStatus.inactive).length;
      final suspended = allCustomers.where((c) => c.status == IsarCustomerStatus.suspended).length;

      final totalCreditLimit = allCustomers.fold<double>(0, (sum, c) => sum + c.creditLimit);
      final totalBalance = allCustomers.fold<double>(0, (sum, c) => sum + c.currentBalance);
      final activePercentage = total > 0 ? (active / total) * 100 : 0.0;
      final customersWithOverdue = allCustomers.where((c) => c.currentBalance > 0).length;

      // Calculate average purchase amount
      final customersWithPurchases = allCustomers.where((c) => c.totalOrders > 0).toList();
      final averagePurchaseAmount = customersWithPurchases.isNotEmpty
          ? customersWithPurchases.fold<double>(0, (sum, c) => sum + c.totalPurchases) / customersWithPurchases.length
          : 0.0;

      final stats = CustomerStats(
        total: total,
        active: active,
        inactive: inactive,
        suspended: suspended,
        totalCreditLimit: totalCreditLimit,
        totalBalance: totalBalance,
        activePercentage: activePercentage,
        customersWithOverdue: customersWithOverdue,
        averagePurchaseAmount: averagePurchaseAmount,
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error calculating customer stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getCustomersWithOverdueInvoices() async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .and()
          .currentBalanceGreaterThan(0)
          .findAll() as List<IsarCustomer>;

      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error loading customers with overdue invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getTopCustomers({int limit = 10}) async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByTotalPurchasesDesc()
          .limit(limit)
          .findAll() as List<IsarCustomer>;

      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error loading top customers: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Customer>> createCustomer({
    required String firstName,
    required String lastName,
    String? companyName,
    required String email,
    String? phone,
    String? mobile,
    required DocumentType documentType,
    required String documentNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    CustomerStatus? status,
    double? creditLimit,
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final serverId = 'customer_${now.millisecondsSinceEpoch}_${email.hashCode}';

      final isarCustomer = IsarCustomer.create(
        serverId: serverId,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        email: email,
        phone: phone,
        mobile: mobile,
        documentType: _mapDocumentType(documentType),
        documentNumber: documentNumber,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        status: _mapCustomerStatus(status ?? CustomerStatus.active),
        creditLimit: creditLimit ?? 0,
        currentBalance: 0,
        paymentTerms: paymentTerms ?? 0,
        birthDate: birthDate,
        notes: notes,
        metadataJson: metadata != null ? jsonEncode(metadata) : null,
        totalPurchases: 0,
        totalOrders: 0,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'documentType': documentType.name,
            'documentNumber': documentNumber,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer({
    required String id,
    String? firstName,
    String? lastName,
    String? companyName,
    String? email,
    String? phone,
    String? mobile,
    DocumentType? documentType,
    String? documentNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    CustomerStatus? status,
    double? creditLimit,
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      // Update fields
      if (firstName != null) isarCustomer.firstName = firstName;
      if (lastName != null) isarCustomer.lastName = lastName;
      if (companyName != null) isarCustomer.companyName = companyName;
      if (email != null) isarCustomer.email = email;
      if (phone != null) isarCustomer.phone = phone;
      if (mobile != null) isarCustomer.mobile = mobile;
      if (documentType != null) isarCustomer.documentType = _mapDocumentType(documentType);
      if (documentNumber != null) isarCustomer.documentNumber = documentNumber;
      if (address != null) isarCustomer.address = address;
      if (city != null) isarCustomer.city = city;
      if (state != null) isarCustomer.state = state;
      if (zipCode != null) isarCustomer.zipCode = zipCode;
      if (country != null) isarCustomer.country = country;
      if (status != null) isarCustomer.status = _mapCustomerStatus(status);
      if (creditLimit != null) isarCustomer.creditLimit = creditLimit;
      if (paymentTerms != null) isarCustomer.paymentTerms = paymentTerms;
      if (birthDate != null) isarCustomer.birthDate = birthDate;
      if (notes != null) isarCustomer.notes = notes;
      if (metadata != null) isarCustomer.metadataJson = jsonEncode(metadata);

      isarCustomer.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomerStatus({
    required String id,
    required CustomerStatus status,
  }) async {
    return updateCustomer(id: id, status: status);
  }

  @override
  Future<Either<Failure, Customer>> updateCustomerBalance({
    required String id,
    required double amount,
    required String operation,
  }) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      if (operation == 'add') {
        isarCustomer.updateBalance(amount);
      } else if (operation == 'subtract') {
        isarCustomer.updateBalance(-amount);
      }

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating customer balance: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomer(String id) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      isarCustomer.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error deleting customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Customer>> restoreCustomer(String id) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      isarCustomer.deletedAt = null;
      isarCustomer.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restoring customer: ${e.toString()}'));
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> isEmailAvailable(
    String email, {
    String? excludeId,
  }) async {
    try {
      var query = _isar.isarCustomers
          .filter()
          .emailEqualTo(email)
          .and()
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.and().not().serverIdEqualTo(excludeId);
      }

      final count = await query.count();
      return Right(count == 0);
    } catch (e) {
      return Left(CacheFailure('Error checking email availability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isDocumentAvailable(
    DocumentType documentType,
    String documentNumber, {
    String? excludeId,
  }) async {
    try {
      final isarDocType = _mapDocumentType(documentType);
      var query = _isar.isarCustomers
          .filter()
          .documentTypeEqualTo(isarDocType)
          .and()
          .documentNumberEqualTo(documentNumber)
          .and()
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.and().not().serverIdEqualTo(excludeId);
      }

      final count = await query.count();
      return Right(count == 0);
    } catch (e) {
      return Left(CacheFailure('Error checking document availability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> canMakePurchase({
    required String customerId,
    required double amount,
  }) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return Right({
          'canPurchase': false,
          'reason': 'Customer not found',
          'availableCredit': 0.0,
          'currentBalance': 0.0,
          'creditLimit': 0.0,
        });
      }

      if (isarCustomer.status != IsarCustomerStatus.active) {
        return Right({
          'canPurchase': false,
          'reason': 'Customer is not active',
          'availableCredit': 0.0,
          'currentBalance': isarCustomer.currentBalance,
          'creditLimit': isarCustomer.creditLimit,
        });
      }

      final availableCredit = isarCustomer.creditLimit - isarCustomer.currentBalance;
      final canPurchase = availableCredit >= amount;

      return Right({
        'canPurchase': canPurchase,
        'reason': canPurchase ? 'Approved' : 'Insufficient credit',
        'availableCredit': availableCredit,
        'currentBalance': isarCustomer.currentBalance,
        'creditLimit': isarCustomer.creditLimit,
        'requiredAmount': amount,
        'deficit': canPurchase ? 0.0 : (amount - availableCredit),
      });
    } catch (e) {
      return Left(CacheFailure('Error checking purchase capability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerFinancialSummary(
    String customerId,
  ) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      final availableCredit = isarCustomer.creditLimit - isarCustomer.currentBalance;

      return Right({
        'customerId': customerId,
        'currentBalance': isarCustomer.currentBalance,
        'creditLimit': isarCustomer.creditLimit,
        'availableCredit': availableCredit,
        'totalPurchases': isarCustomer.totalPurchases,
        'totalOrders': isarCustomer.totalOrders,
        'lastPurchaseAt': isarCustomer.lastPurchaseAt?.toIso8601String(),
        'paymentTerms': isarCustomer.paymentTerms,
        'overdueAmount': isarCustomer.currentBalance,
        'status': isarCustomer.status.toString().split('.').last,
        'riskLevel': _calculateRiskLevel(isarCustomer),
      });
    } catch (e) {
      return Left(CacheFailure('Error getting financial summary: ${e.toString()}'));
    }
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Customer>>> getCachedCustomers() async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomer>;

      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error loading cached customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCustomerCache() async {
    // For offline implementation, we don't clear the cache
    // The cache IS the primary storage
    return const Right(unit);
  }

  // ==================== HELPER METHODS ====================

  IsarDocumentType _mapDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.cc:
        return IsarDocumentType.cc;
      case DocumentType.nit:
        return IsarDocumentType.nit;
      case DocumentType.ce:
        return IsarDocumentType.ce;
      case DocumentType.passport:
        return IsarDocumentType.passport;
      case DocumentType.other:
        return IsarDocumentType.other;
    }
  }

  IsarCustomerStatus _mapCustomerStatus(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return IsarCustomerStatus.active;
      case CustomerStatus.inactive:
        return IsarCustomerStatus.inactive;
      case CustomerStatus.suspended:
        return IsarCustomerStatus.suspended;
    }
  }

  String _calculateRiskLevel(IsarCustomer customer) {
    if (customer.creditLimit == 0) return 'none';
    final balanceRatio = customer.currentBalance / customer.creditLimit;
    if (balanceRatio > 0.9) return 'high';
    if (balanceRatio > 0.7) return 'medium';
    return 'low';
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<Customer>>> getUnsyncedCustomers() async {
    try {
      final isarCustomers = await _isar.isarCustomers
          .filter()
          .isSyncedEqualTo(false)
          .findAll() as List<IsarCustomer>;

      final customers = isarCustomers.map((isar) => isar.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced customers: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> markCustomersAsSynced(List<String> customerIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in customerIds) {
          final isarCustomer = await _isar.isarCustomers
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarCustomer != null) {
            isarCustomer.markAsSynced();
            await _isar.isarCustomers.put(isarCustomer);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking customers as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsertCustomers(List<Customer> customers) async {
    try {
      final isarCustomers = customers
          .map((customer) => IsarCustomer.fromEntity(customer))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.putAll(isarCustomers);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting customers: ${e.toString()}'));
    }
  }

  // ==================== ADDITIONAL OPERATIONS ====================

  Future<Either<Failure, void>> recordPurchase({
    required String customerId,
    required double amount,
  }) async {
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      isarCustomer.recordPurchase(amount);

      await _isar.writeTxn(() async {
        await _isar.isarCustomers.put(isarCustomer);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error recording purchase: ${e.toString()}'));
    }
  }
}
