// lib/features/suppliers/data/repositories/supplier_offline_repository.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../models/isar/isar_supplier.dart';

/// Implementación offline del repositorio de proveedores usando ISAR
class SupplierOfflineRepository implements SupplierRepository {
  final IsarDatabase _database;

  SupplierOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<Supplier>>> getSuppliers({
    int page = 1,
    int limit = 10,
    String? search,
    SupplierStatus? status,
    DocumentType? documentType,
    String? currency,
    bool? hasEmail,
    bool? hasPhone,
    bool? hasCreditLimit,
    bool? hasDiscount,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      var query = _isar.isarSuppliers.filter().deletedAtIsNull();

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.and().group((q) => q
            .nameContains(search, caseSensitive: false)
            .or()
            .documentNumberContains(search, caseSensitive: false)
            .or()
            .emailContains(search, caseSensitive: false));
      }

      // Apply status filter
      if (status != null) {
        final isarStatus = _mapSupplierStatus(status);
        query = query.and().statusEqualTo(isarStatus);
      }

      // Apply document type filter
      if (documentType != null) {
        final isarDocType = _mapDocumentType(documentType);
        query = query.and().documentTypeEqualTo(isarDocType);
      }

      // Apply currency filter
      if (currency != null) {
        query = query.and().currencyEqualTo(currency);
      }

      // Apply hasEmail filter
      if (hasEmail == true) {
        query = query.and().emailIsNotNull();
      }

      // Apply hasPhone filter
      if (hasPhone == true) {
        query = query.and().phoneIsNotNull();
      }

      // Fetch all filtered results
      var isarSuppliers = await query.findAll();

      // Apply in-memory filters
      if (hasCreditLimit == true) {
        isarSuppliers = isarSuppliers.where((s) => s.creditLimit > 0).toList();
      }

      if (hasDiscount == true) {
        isarSuppliers = isarSuppliers.where((s) => s.discountPercentage > 0).toList();
      }

      // Get total count after filters
      final totalItems = isarSuppliers.length;

      // Sort in memory
      if (sortBy == 'name') {
        isarSuppliers.sort((a, b) => sortOrder == 'desc'
            ? b.name.compareTo(a.name)
            : a.name.compareTo(b.name));
      } else if (sortBy == 'createdAt') {
        isarSuppliers.sort((a, b) => sortOrder == 'desc'
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
      } else {
        // Default sort by name
        isarSuppliers.sort((a, b) => a.name.compareTo(b.name));
      }

      // Paginate in memory
      final offset = (page - 1) * limit;
      final paginatedSuppliers = isarSuppliers.skip(offset).take(limit).toList();

      // Convert to domain entities
      final suppliers = paginatedSuppliers.map((isar) => isar.toEntity()).toList();

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

      return Right(PaginatedResult(data: suppliers, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading suppliers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    try {
      final isarSupplier = await _isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Supplier not found'));
      }

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading supplier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String searchTerm, {
    int? limit,
  }) async {
    try {
      // `limit` null → sin tope (devuelve todos los matches).
      final baseQuery = _isar.isarSuppliers
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .nameContains(searchTerm, caseSensitive: false)
              .or()
              .documentNumberContains(searchTerm, caseSensitive: false)
              .or()
              .emailContains(searchTerm, caseSensitive: false));

      final isarSuppliers = limit == null
          ? await baseQuery.findAll()
          : await baseQuery.limit(limit).findAll();

      final suppliers = isarSuppliers.map((isar) => isar.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(CacheFailure('Error searching suppliers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> getActiveSuppliers() async {
    try {
      final isarSuppliers = await _isar.isarSuppliers
          .filter()
          .statusEqualTo(IsarSupplierStatus.active)
          .and()
          .deletedAtIsNull()
          .sortByName()
          .findAll();

      final suppliers = isarSuppliers.map((isar) => isar.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(CacheFailure('Error loading active suppliers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SupplierStats>> getSupplierStats() async {
    try {
      final allSuppliers = await _isar.isarSuppliers
          .filter()
          .deletedAtIsNull()
          .findAll();

      final total = allSuppliers.length;
      final active = allSuppliers.where((s) => s.status == IsarSupplierStatus.active).length;
      final inactive = allSuppliers.where((s) => s.status == IsarSupplierStatus.inactive).length;
      final withDiscount = allSuppliers.where((s) => s.discountPercentage > 0).length;
      final withCredit = allSuppliers.where((s) => s.creditLimit > 0).length;

      final totalCreditLimit = allSuppliers.fold<double>(0, (sum, s) => sum + s.creditLimit);
      final avgCreditLimit = total > 0 ? totalCreditLimit / total : 0.0;

      final totalPaymentTerms = allSuppliers.fold<int>(0, (sum, s) => sum + s.paymentTermsDays);
      final avgPaymentTerms = total > 0 ? totalPaymentTerms / total : 0.0;

      // Currency distribution
      final Map<String, int> currencyDist = {};
      for (final supplier in allSuppliers) {
        currencyDist[supplier.currency] = (currencyDist[supplier.currency] ?? 0) + 1;
      }

      // Top suppliers by credit
      final topByCredit = allSuppliers
          .where((s) => s.creditLimit > 0)
          .toList()
        ..sort((a, b) => b.creditLimit.compareTo(a.creditLimit));

      final topSuppliersByCredit = topByCredit.take(5).map((s) => {
            'id': s.serverId,
            'name': s.name,
            'creditLimit': s.creditLimit,
          }).toList();

      final stats = SupplierStats(
        totalSuppliers: total,
        activeSuppliers: active,
        inactiveSuppliers: inactive,
        totalCreditLimit: totalCreditLimit,
        averageCreditLimit: avgCreditLimit,
        averagePaymentTerms: avgPaymentTerms,
        suppliersWithDiscount: withDiscount,
        suppliersWithCredit: withCredit,
        currencyDistribution: currencyDist,
        topSuppliersByCredit: topSuppliersByCredit,
        totalPurchasesAmount: 0.0, // TODO: Calculate from purchase orders when implemented
        totalPurchaseOrders: 0, // TODO: Calculate from purchase orders when implemented
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error calculating supplier stats: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Supplier>> createSupplier({
    required String name,
    String? code,
    required DocumentType documentType,
    required String documentNumber,
    String? contactPerson,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    SupplierStatus? status,
    String? currency,
    int? paymentTermsDays,
    double? creditLimit,
    double? discountPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final serverId = 'supplier_${now.millisecondsSinceEpoch}_${name.hashCode}';

      final isarSupplier = IsarSupplier.create(
        serverId: serverId,
        name: name,
        code: code,
        documentType: _mapDocumentType(documentType),
        documentNumber: documentNumber,
        contactPerson: contactPerson,
        email: email,
        phone: phone,
        mobile: mobile,
        address: address,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
        website: website,
        status: _mapSupplierStatus(status ?? SupplierStatus.active),
        currency: currency ?? 'COP',
        paymentTermsDays: paymentTermsDays ?? 0,
        creditLimit: creditLimit ?? 0.0,
        discountPercentage: discountPercentage ?? 0.0,
        notes: notes,
        metadataJson: metadata != null ? _encodeMetadata(metadata) : null,
        organizationId: 'offline', // TODO: Get from auth context
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.put(isarSupplier);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'code': code,
            'documentType': documentType.name,
            'documentNumber': documentNumber,
            'contactPerson': contactPerson,
            'email': email,
            'phone': phone,
            'status': status?.name,
            'currency': currency,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating supplier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> updateSupplier({
    required String id,
    String? name,
    String? code,
    DocumentType? documentType,
    String? documentNumber,
    String? contactPerson,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    SupplierStatus? status,
    String? currency,
    int? paymentTermsDays,
    double? creditLimit,
    double? discountPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final isarSupplier = await _isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Supplier not found'));
      }

      // Update fields
      if (name != null) isarSupplier.name = name;
      if (code != null) isarSupplier.code = code;
      if (documentType != null) isarSupplier.documentType = _mapDocumentType(documentType);
      if (documentNumber != null) isarSupplier.documentNumber = documentNumber;
      if (contactPerson != null) isarSupplier.contactPerson = contactPerson;
      if (email != null) isarSupplier.email = email;
      if (phone != null) isarSupplier.phone = phone;
      if (mobile != null) isarSupplier.mobile = mobile;
      if (address != null) isarSupplier.address = address;
      if (city != null) isarSupplier.city = city;
      if (state != null) isarSupplier.state = state;
      if (country != null) isarSupplier.country = country;
      if (postalCode != null) isarSupplier.postalCode = postalCode;
      if (website != null) isarSupplier.website = website;
      if (status != null) isarSupplier.status = _mapSupplierStatus(status);
      if (currency != null) isarSupplier.currency = currency;
      if (paymentTermsDays != null) isarSupplier.paymentTermsDays = paymentTermsDays;
      if (creditLimit != null) isarSupplier.creditLimit = creditLimit;
      if (discountPercentage != null) isarSupplier.discountPercentage = discountPercentage;
      if (notes != null) isarSupplier.notes = notes;
      if (metadata != null) isarSupplier.metadataJson = _encodeMetadata(metadata);

      isarSupplier.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.put(isarSupplier);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating supplier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> updateSupplierStatus({
    required String id,
    required SupplierStatus status,
  }) async {
    return updateSupplier(id: id, status: status);
  }

  @override
  Future<Either<Failure, Unit>> deleteSupplier(String id) async {
    try {
      final isarSupplier = await _isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Supplier not found'));
      }

      isarSupplier.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.put(isarSupplier);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error deleting supplier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> restoreSupplier(String id) async {
    try {
      final isarSupplier = await _isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Supplier not found'));
      }

      isarSupplier.deletedAt = null;
      isarSupplier.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.put(isarSupplier);
      });

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restoring supplier: ${e.toString()}'));
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> validateDocument({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId,
  }) async {
    try {
      final isarDocType = _mapDocumentType(documentType);
      final existing = await _isar.isarSuppliers
          .filter()
          .documentTypeEqualTo(isarDocType)
          .and()
          .documentNumberEqualTo(documentNumber)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (excludeId != null) {
        final isAvailable = !existing.any((s) => s.serverId != excludeId);
        return Right(isAvailable);
      } else {
        return Right(existing.isEmpty);
      }
    } catch (e) {
      return Left(CacheFailure('Error validating document: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateCode({
    required String code,
    String? excludeId,
  }) async {
    try {
      final existing = await _isar.isarSuppliers
          .filter()
          .codeEqualTo(code)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (excludeId != null) {
        final isAvailable = !existing.any((s) => s.serverId != excludeId);
        return Right(isAvailable);
      } else {
        return Right(existing.isEmpty);
      }
    } catch (e) {
      return Left(CacheFailure('Error validating code: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateEmail({
    required String email,
    String? excludeId,
  }) async {
    try {
      final existing = await _isar.isarSuppliers
          .filter()
          .emailEqualTo(email)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (excludeId != null) {
        final isAvailable = !existing.any((s) => s.serverId != excludeId);
        return Right(isAvailable);
      } else {
        return Right(existing.isEmpty);
      }
    } catch (e) {
      return Left(CacheFailure('Error validating email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkDocumentUniqueness({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId,
  }) async {
    return validateDocument(
      documentType: documentType,
      documentNumber: documentNumber,
      excludeId: excludeId,
    );
  }

  // ==================== BUSINESS LOGIC OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> canReceivePurchaseOrders(String supplierId) async {
    try {
      final isarSupplier = await _isar.isarSuppliers
          .filter()
          .serverIdEqualTo(supplierId)
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Supplier not found'));
      }

      final canReceive = isarSupplier.isActive;
      return Right(canReceive);
    } catch (e) {
      return Left(CacheFailure('Error checking supplier status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPurchasesAmount(String supplierId) async {
    // TODO: Implement when purchase orders are available
    return const Right(0.0);
  }

  @override
  Future<Either<Failure, DateTime?>> getLastPurchaseDate(String supplierId) async {
    // TODO: Implement when purchase orders are available
    return const Right(null);
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Supplier>>> getCachedSuppliers() async {
    try {
      final isarSuppliers = await _isar.isarSuppliers
          .filter()
          .deletedAtIsNull()
          .sortByName()
          .findAll();

      final suppliers = isarSuppliers.map((isar) => isar.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(CacheFailure('Error loading cached suppliers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearSupplierCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.clear();
      });

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error clearing supplier cache: ${e.toString()}'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<Supplier>>> getUnsyncedSuppliers() async {
    try {
      final isarSuppliers = await _isar.isarSuppliers
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final suppliers = isarSuppliers.map((isar) => isar.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced suppliers: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> markSuppliersAsSynced(List<String> supplierIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in supplierIds) {
          final isarSupplier = await _isar.isarSuppliers
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarSupplier != null) {
            isarSupplier.markAsSynced();
            await _isar.isarSuppliers.put(isarSupplier);
          }
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error marking suppliers as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> bulkInsertSuppliers(List<Supplier> suppliers) async {
    try {
      final isarSuppliers = suppliers
          .map((supplier) => IsarSupplier.fromEntity(supplier))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarSuppliers.putAll(isarSuppliers);
      });

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting suppliers: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarDocumentType _mapDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.nit:
        return IsarDocumentType.nit;
      case DocumentType.cc:
        return IsarDocumentType.cc;
      case DocumentType.ce:
        return IsarDocumentType.ce;
      case DocumentType.passport:
        return IsarDocumentType.passport;
      case DocumentType.rut:
      case DocumentType.other:
        return IsarDocumentType.other;
    }
  }

  IsarSupplierStatus _mapSupplierStatus(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return IsarSupplierStatus.active;
      case SupplierStatus.inactive:
        return IsarSupplierStatus.inactive;
      case SupplierStatus.blocked:
        return IsarSupplierStatus.blocked;
    }
  }

  String _encodeMetadata(Map<String, dynamic> metadata) {
    try {
      return json.encode(metadata);
    } catch (e) {
      return '{}';
    }
  }
}
