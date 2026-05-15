// lib/features/suppliers/data/repositories/supplier_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_remote_datasource.dart';
import '../datasources/supplier_local_datasource.dart';
import '../models/create_supplier_request_model.dart';
import '../models/update_supplier_request_model.dart';
import '../models/supplier_model.dart';
import '../models/isar/isar_supplier.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;
  final SupplierLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SupplierRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
    final params = SupplierQueryParams(
      page: page,
      limit: limit,
      search: search,
      status: status,
      documentType: documentType,
      currency: currency,
      hasEmail: hasEmail,
      hasPhone: hasPhone,
      hasCreditLimit: hasCreditLimit,
      hasDiscount: hasDiscount,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    if (await networkInfo.isConnected) {
      try {
        final remoteResult = await remoteDataSource.getSuppliers(params);

        // Cachear los resultados
        await localDataSource.cacheSuppliers(remoteResult.data);

        // Convertir models a entities
        final suppliers = remoteResult.data.map((model) => model.toEntity()).toList();

        return Right(PaginatedResult<Supplier>(
          data: suppliers,
          meta: remoteResult.meta,
        ));
      } catch (e) {
        print('⚠️ Error del servidor en getSuppliers: $e - intentando cache local...');
        return _getSuppliersFromCache(params);
      }
    } else {
      return _getSuppliersFromCache(params);
    }
  }

  Future<Either<Failure, PaginatedResult<Supplier>>> _getSuppliersFromCache(
    SupplierQueryParams params,
  ) async {
    try {
      final localResult = await localDataSource.getSuppliers(params);
      final suppliers = localResult.data.map((model) => model.toEntity()).toList();
      return Right(PaginatedResult<Supplier>(
        data: suppliers,
        meta: localResult.meta,
      ));
    } catch (_) {
      return Right(PaginatedResult<Supplier>(
        data: <Supplier>[],
        meta: PaginationMeta(
          page: params.page,
          limit: params.limit,
          totalItems: 0,
          totalPages: 0,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModel = await remoteDataSource.getSupplierById(id);

        // Cachear el resultado
        await localDataSource.cacheSupplier(supplierModel);

        return Right(supplierModel.toEntity());
      } catch (e) {
        print('⚠️ Error del servidor en getSupplierById: $e - intentando cache local...');
        return _getSupplierByIdFromCache(id);
      }
    } else {
      return _getSupplierByIdFromCache(id);
    }
  }

  Future<Either<Failure, Supplier>> _getSupplierByIdFromCache(String id) async {
    try {
      final supplierModel = await localDataSource.getSupplierById(id);
      if (supplierModel != null) {
        return Right(supplierModel.toEntity());
      }
    } catch (_) {}
    return Left(CacheFailure('Proveedor no encontrado en cache'));
  }

  @override
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String searchTerm, {
    int? limit,
  }) async {
    // Si no se especifica `limit` aplicamos un cap defensivo alto al
    // hablar con el server para no traer una página enorme. La rama de
    // cache local respeta el `null` y devuelve todo.
    final remoteLimit = limit ?? 100;
    if (await networkInfo.isConnected) {
      try {
        final supplierModels = await remoteDataSource.searchSuppliers(
          searchTerm,
          limit: remoteLimit,
        );

        // Cachear los resultados
        for (final supplier in supplierModels) {
          await localDataSource.cacheSupplier(supplier);
        }

        final suppliers = supplierModels.map((model) => model.toEntity()).toList();
        return Right(suppliers);
      } catch (e) {
        print('⚠️ Error del servidor en searchSuppliers: $e - intentando cache local...');
        return _searchSuppliersFromCache(searchTerm, limit: limit);
      }
    } else {
      return _searchSuppliersFromCache(searchTerm, limit: limit);
    }
  }

  /// Búsqueda en cache local. `limit` null → sin tope.
  Future<Either<Failure, List<Supplier>>> _searchSuppliersFromCache(
    String searchTerm, {
    int? limit,
  }) async {
    try {
      // El localDataSource exige `int`. Si caller pasa null, usamos
      // un techo razonable para evitar trabajar con un array enorme
      // por accidente; el caller que quiera TODO debe ir directo al
      // `SupplierOfflineRepository` que respeta null nativo.
      final supplierModels = await localDataSource.searchSuppliers(
        searchTerm,
        limit: limit ?? 1000,
      );
      final suppliers = supplierModels.map((model) => model.toEntity()).toList();
      if (suppliers.isNotEmpty) {
        print('✅ ${suppliers.length} proveedores encontrados en cache local');
      }
      return Right(suppliers);
    } catch (_) {
      return const Right(<Supplier>[]);
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> getActiveSuppliers() async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModels = await remoteDataSource.getActiveSuppliers();

        // Cachear los resultados
        for (final supplier in supplierModels) {
          await localDataSource.cacheSupplier(supplier);
        }

        final suppliers = supplierModels.map((model) => model.toEntity()).toList();
        return Right(suppliers);
      } catch (e) {
        print('⚠️ Error del servidor en getActiveSuppliers: $e - intentando cache local...');
        return _getActiveSuppliersFromCache();
      }
    } else {
      return _getActiveSuppliersFromCache();
    }
  }

  Future<Either<Failure, List<Supplier>>> _getActiveSuppliersFromCache() async {
    try {
      final supplierModels = await localDataSource.getActiveSuppliers();
      final suppliers = supplierModels.map((model) => model.toEntity()).toList();
      if (suppliers.isNotEmpty) {
        print('✅ ${suppliers.length} proveedores activos encontrados en cache local');
      }
      return Right(suppliers);
    } catch (_) {
      return const Right(<Supplier>[]);
    }
  }

  @override
  Future<Either<Failure, SupplierStats>> getSupplierStats() async {
    if (await networkInfo.isConnected) {
      try {
        final statsModel = await remoteDataSource.getSupplierStats();

        // Cachear las estadísticas
        await localDataSource.cacheSupplierStats(statsModel);

        return Right(statsModel.toEntity());
      } catch (e) {
        print('⚠️ Error del servidor en getSupplierStats: $e - intentando cache local...');
        return _getSupplierStatsFromCache();
      }
    } else {
      return _getSupplierStatsFromCache();
    }
  }

  Future<Either<Failure, SupplierStats>> _getSupplierStatsFromCache() async {
    try {
      final statsModel = await localDataSource.getCachedSupplierStats();
      if (statsModel != null) {
        print('✅ Estadísticas de proveedores obtenidas desde cache local');
        return Right(statsModel.toEntity());
      }
    } catch (_) {}
    // Retornar stats vacías en vez de error
    return const Right(SupplierStats(
      totalSuppliers: 0,
      activeSuppliers: 0,
      inactiveSuppliers: 0,
      totalCreditLimit: 0.0,
      averageCreditLimit: 0.0,
      averagePaymentTerms: 0.0,
      suppliersWithDiscount: 0,
      suppliersWithCredit: 0,
      currencyDistribution: {},
      topSuppliersByCredit: [],
      totalPurchasesAmount: 0.0,
      totalPurchaseOrders: 0,
    ));
  }

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
    if (await networkInfo.isConnected) {
      try {
        final request = CreateSupplierRequestModel(
          name: name,
          code: code,
          documentType: documentType.name,
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
          status: status?.name,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );

        final supplierModel = await remoteDataSource.createSupplier(request);

        // Cachear el nuevo proveedor
        await localDataSource.cacheSupplier(supplierModel);

        return Right(supplierModel.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [SUPPLIER_REPO] ServerException: ${e.message} - Fallback offline...');
        return _createSupplierOffline(
          name: name,
          code: code,
          documentType: documentType,
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
          status: status,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );
      } catch (e) {
        print('⚠️ [SUPPLIER_REPO] Exception: $e - Fallback offline...');
        return _createSupplierOffline(
          name: name,
          code: code,
          documentType: documentType,
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
          status: status,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );
      }
    } else {
      // Sin conexión, crear proveedor offline
      return _createSupplierOffline(
        name: name,
        code: code,
        documentType: documentType,
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
        status: status,
        currency: currency,
        paymentTermsDays: paymentTermsDays,
        creditLimit: creditLimit,
        discountPercentage: discountPercentage,
        notes: notes,
        metadata: metadata,
      );
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
    if (await networkInfo.isConnected) {
      try {
        final request = UpdateSupplierRequestModel(
          name: name,
          code: code,
          documentType: documentType?.name,
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
          status: status?.name,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );

        final supplierModel = await remoteDataSource.updateSupplier(id, request);

        // Actualizar cache
        await localDataSource.cacheSupplier(supplierModel);

        return Right(supplierModel.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [SUPPLIER_REPO] ServerException: ${e.message} - Fallback offline...');
        return _updateSupplierOffline(
          id: id,
          name: name,
          code: code,
          documentType: documentType,
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
          status: status,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );
      } catch (e) {
        print('⚠️ [SUPPLIER_REPO] Exception: $e - Fallback offline...');
        return _updateSupplierOffline(
          id: id,
          name: name,
          code: code,
          documentType: documentType,
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
          status: status,
          currency: currency,
          paymentTermsDays: paymentTermsDays,
          creditLimit: creditLimit,
          discountPercentage: discountPercentage,
          notes: notes,
          metadata: metadata,
        );
      }
    } else {
      // Sin conexión, actualizar offline
      return _updateSupplierOffline(
        id: id,
        name: name,
        code: code,
        documentType: documentType,
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
        status: status,
        currency: currency,
        paymentTermsDays: paymentTermsDays,
        creditLimit: creditLimit,
        discountPercentage: discountPercentage,
        notes: notes,
        metadata: metadata,
      );
    }
  }

  @override
  Future<Either<Failure, Supplier>> updateSupplierStatus({
    required String id,
    required SupplierStatus status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModel = await remoteDataSource.updateSupplierStatus(
          id,
          status.name,
        );
        
        // Actualizar cache
        await localDataSource.cacheSupplier(supplierModel);
        
        return Right(supplierModel.toEntity());
      } on ServerException catch (e) {
        return _updateSupplierStatusOffline(id, status);
      } catch (e) {
        return _updateSupplierStatusOffline(id, status);
      }
    } else {
      return _updateSupplierStatusOffline(id, status);
    }
  }

  Future<Either<Failure, Supplier>> _updateSupplierStatusOffline(
    String id,
    SupplierStatus status,
  ) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarSupplier = await isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(ServerFailure('Proveedor no encontrado localmente'));
      }

      isarSupplier.status = _mapSupplierStatusToIsar(status);
      isarSupplier.markAsUnsynced();
      await isar.writeTxn(() => isar.isarSuppliers.put(isarSupplier));

      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'Supplier',
        entityId: id,
        operationType: SyncOperationType.update,
        data: {'id': id, 'action': 'updateStatus', 'status': status.name},
        priority: 2,
      );

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(ServerFailure('Error actualizando estado offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSupplier(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarSupplier = await isar.isarSuppliers
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarSupplier != null) {
            isarSupplier.softDelete();
            await isar.writeTxn(() async {
              await isar.isarSuppliers.put(isarSupplier);
            });
            print('✅ Supplier marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        // Remover del cache
        await localDataSource.removeCachedSupplier(id);

        return const Right(unit);
      } on ServerException catch (e) {
        print('⚠️ [SUPPLIER_REPO] ServerException: ${e.message} - Fallback offline...');
        return _deleteSupplierOffline(id);
      } catch (e) {
        print('⚠️ [SUPPLIER_REPO] Exception: $e - Fallback offline...');
        return _deleteSupplierOffline(id);
      }
    } else {
      // Sin conexión, eliminar offline
      return _deleteSupplierOffline(id);
    }
  }

  @override
  Future<Either<Failure, Supplier>> restoreSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModel = await remoteDataSource.restoreSupplier(id);

        // Actualizar cache
        await localDataSource.cacheSupplier(supplierModel);

        // Actualizar ISAR
        try {
          final isar = IsarDatabase.instance.database;
          final isarSupplier = await isar.isarSuppliers
              .filter()
              .serverIdEqualTo(id)
              .findFirst();
          if (isarSupplier != null) {
            isarSupplier.deletedAt = null;
            isarSupplier.markAsSynced();
            await isar.writeTxn(() => isar.isarSuppliers.put(isarSupplier));
          }
        } catch (_) {}

        return Right(supplierModel.toEntity());
      } on ServerException catch (e) {
        return _restoreSupplierOffline(id);
      } catch (e) {
        return _restoreSupplierOffline(id);
      }
    } else {
      return _restoreSupplierOffline(id);
    }
  }

  @override
  Future<Either<Failure, bool>> validateDocument({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isValid = await remoteDataSource.validateDocument(
          documentType.name,
          documentNumber,
          excludeId: excludeId,
        );
        return Right(isValid);
      } on ServerException catch (e) {
        return _validateDocumentOffline(documentType, documentNumber, excludeId);
      } catch (e) {
        return _validateDocumentOffline(documentType, documentNumber, excludeId);
      }
    } else {
      return _validateDocumentOffline(documentType, documentNumber, excludeId);
    }
  }

  @override
  Future<Either<Failure, bool>> validateCode({
    required String code,
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isValid = await remoteDataSource.validateCode(code, excludeId: excludeId);
        return Right(isValid);
      } on ServerException catch (e) {
        return _validateCodeOffline(code, excludeId);
      } catch (e) {
        return _validateCodeOffline(code, excludeId);
      }
    } else {
      return _validateCodeOffline(code, excludeId);
    }
  }

  @override
  Future<Either<Failure, bool>> validateEmail({
    required String email,
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isValid = await remoteDataSource.validateEmail(email, excludeId: excludeId);
        return Right(isValid);
      } on ServerException catch (e) {
        return _validateEmailOffline(email, excludeId);
      } catch (e) {
        return _validateEmailOffline(email, excludeId);
      }
    } else {
      return _validateEmailOffline(email, excludeId);
    }
  }

  @override
  Future<Either<Failure, bool>> checkDocumentUniqueness({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isUnique = await remoteDataSource.checkDocumentUniqueness(
          documentType.name,
          documentNumber,
          excludeId: excludeId,
        );
        return Right(isUnique);
      } on ServerException catch (e) {
        return _validateDocumentOffline(documentType, documentNumber, excludeId);
      } catch (e) {
        return _validateDocumentOffline(documentType, documentNumber, excludeId);
      }
    } else {
      return _validateDocumentOffline(documentType, documentNumber, excludeId);
    }
  }

  @override
  Future<Either<Failure, bool>> canReceivePurchaseOrders(String supplierId) async {
    // Lógica de negocio: un proveedor puede recibir órdenes si está activo
    try {
      final supplierResult = await getSupplierById(supplierId);
      return supplierResult.fold(
        (failure) => Left(failure),
        (supplier) => Right(supplier.isActive),
      );
    } catch (e) {
      return Left(ServerFailure('Error verificando estado del proveedor: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPurchasesAmount(String supplierId) async {
    // Esta funcionalidad requiere integración con el módulo de compras
    // Por ahora retornamos 0, se implementará cuando tengamos el módulo de compras
    return const Right(0.0);
  }

  @override
  Future<Either<Failure, DateTime?>> getLastPurchaseDate(String supplierId) async {
    // Esta funcionalidad requiere integración con el módulo de compras
    // Por ahora retornamos null, se implementará cuando tengamos el módulo de compras
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Supplier>>> getCachedSuppliers() async {
    try {
      final supplierModels = await localDataSource.getCachedSuppliers();
      final suppliers = supplierModels.map((model) => model.toEntity()).toList();
      return Right(suppliers);
    } catch (_) {
      return const Right(<Supplier>[]);
    }
  }

  @override
  Future<Either<Failure, Unit>> clearSupplierCache() async {
    try {
      await localDataSource.clearSuppliersCache();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error limpiando cache: $e'));
    }
  }

  // ==================== PRIVATE OFFLINE METHODS ====================

  /// Crear proveedor offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, Supplier>> _createSupplierOffline({
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
    print('📱 SupplierRepository: Creating supplier offline: $name');
    try {
      final now = DateTime.now();
      final tempId = 'supplier_offline_${now.millisecondsSinceEpoch}_${name.hashCode}';

      // Obtener organizationId del usuario autenticado
      String organizationId;
      try {
        final authController = Get.find<AuthController>();
        organizationId = authController.currentUser?.organizationId ?? '';
        if (organizationId.isEmpty) {
          throw Exception('No hay usuario autenticado o organizationId no disponible');
        }
      } catch (e) {
        print('❌ Error obteniendo organizationId: $e');
        return Left(CacheFailure('Error al obtener organizationId del usuario: $e'));
      }

      final tempSupplier = Supplier(
        id: tempId,
        name: name,
        code: code,
        documentType: documentType,
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
        status: status ?? SupplierStatus.active,
        currency: currency ?? 'COP',
        paymentTermsDays: paymentTermsDays ?? 30,
        creditLimit: creditLimit ?? 0.0,
        discountPercentage: discountPercentage ?? 0.0,
        notes: notes,
        metadata: metadata,
        organizationId: organizationId,
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en ISAR
      try {
        final isar = IsarDatabase.instance.database;
        final isarSupplier = IsarSupplier.fromEntity(tempSupplier);
        isarSupplier.markAsUnsynced();

        await isar.writeTxn(() async {
          await isar.isarSuppliers.put(isarSupplier);
        });
        print('✅ SupplierRepository: Supplier saved to ISAR');
      } catch (e) {
        print('❌ Error saving to ISAR: $e');
        return Left(CacheFailure('Error al guardar en ISAR: $e'));
      }

      // Cache en SecureStorage
      await localDataSource.cacheSupplier(SupplierModel.fromEntity(tempSupplier));

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'code': code,
            'documentType': documentType.name,
            'documentNumber': documentNumber,
            'contactPerson': contactPerson,
            'email': email,
            'phone': phone,
            'mobile': mobile,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'postalCode': postalCode,
            'website': website,
            'status': status?.name,
            'currency': currency,
            'paymentTermsDays': paymentTermsDays,
            'creditLimit': creditLimit,
            'discountPercentage': discountPercentage,
            'notes': notes,
            'metadata': metadata,
          },
          priority: 1,
        );
        print('📤 SupplierRepository: Operación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Supplier created offline successfully');
      return Right(tempSupplier);
    } catch (e) {
      print('❌ Error creating supplier offline: $e');
      return Left(CacheFailure('Error al crear proveedor offline: $e'));
    }
  }

  /// Actualizar proveedor offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, Supplier>> _updateSupplierOffline({
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
    print('📱 SupplierRepository: Updating supplier offline: $id');
    try {
      // PASO 1: Actualizar en ISAR primero
      final isar = IsarDatabase.instance.database;
      final isarSupplier = await isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(CacheFailure('Proveedor no encontrado en ISAR: $id'));
      }

      // Actualizar campos en ISAR
      if (name != null) isarSupplier.name = name;
      if (code != null) isarSupplier.code = code;
      if (documentType != null) {
        isarSupplier.documentType = _mapDocumentTypeToIsar(documentType);
      }
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
      if (status != null) {
        isarSupplier.status = _mapSupplierStatusToIsar(status);
      }
      if (currency != null) isarSupplier.currency = currency;
      if (paymentTermsDays != null) isarSupplier.paymentTermsDays = paymentTermsDays;
      if (creditLimit != null) isarSupplier.creditLimit = creditLimit;
      if (discountPercentage != null) isarSupplier.discountPercentage = discountPercentage;
      if (notes != null) isarSupplier.notes = notes;

      // Marcar como no sincronizado
      isarSupplier.markAsUnsynced();

      // Guardar en ISAR
      await isar.writeTxn(() async {
        await isar.isarSuppliers.put(isarSupplier);
      });
      print('✅ SupplierRepository: Supplier updated in ISAR');

      // PASO 2: Actualizar en SecureStorage
      final cachedSupplierModel = await localDataSource.getSupplierById(id);
      if (cachedSupplierModel == null) {
        return Left(CacheFailure('Proveedor no encontrado en cache: $id'));
      }
      final cachedSupplier = cachedSupplierModel.toEntity();

      final updatedSupplier = Supplier(
        id: id,
        name: name ?? cachedSupplier.name,
        code: code ?? cachedSupplier.code,
        documentType: documentType ?? cachedSupplier.documentType,
        documentNumber: documentNumber ?? cachedSupplier.documentNumber,
        contactPerson: contactPerson ?? cachedSupplier.contactPerson,
        email: email ?? cachedSupplier.email,
        phone: phone ?? cachedSupplier.phone,
        mobile: mobile ?? cachedSupplier.mobile,
        address: address ?? cachedSupplier.address,
        city: city ?? cachedSupplier.city,
        state: state ?? cachedSupplier.state,
        country: country ?? cachedSupplier.country,
        postalCode: postalCode ?? cachedSupplier.postalCode,
        website: website ?? cachedSupplier.website,
        status: status ?? cachedSupplier.status,
        currency: currency ?? cachedSupplier.currency,
        paymentTermsDays: paymentTermsDays ?? cachedSupplier.paymentTermsDays,
        creditLimit: creditLimit ?? cachedSupplier.creditLimit,
        discountPercentage: discountPercentage ?? cachedSupplier.discountPercentage,
        notes: notes ?? cachedSupplier.notes,
        metadata: metadata ?? cachedSupplier.metadata,
        organizationId: cachedSupplier.organizationId,
        createdAt: cachedSupplier.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cacheSupplier(SupplierModel.fromEntity(updatedSupplier));

      // Agregar a cola
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'name': name,
            'code': code,
            'documentType': documentType?.name,
            'documentNumber': documentNumber,
            'contactPerson': contactPerson,
            'email': email,
            'phone': phone,
            'mobile': mobile,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'postalCode': postalCode,
            'website': website,
            'status': status?.name,
            'currency': currency,
            'paymentTermsDays': paymentTermsDays,
            'creditLimit': creditLimit,
            'discountPercentage': discountPercentage,
            'notes': notes,
            'metadata': metadata,
          },
          priority: 1,
        );
        print('📤 Actualización agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Supplier updated offline successfully');
      return Right(updatedSupplier);
    } catch (e) {
      print('❌ Error updating supplier offline: $e');
      return Left(CacheFailure('Error al actualizar proveedor offline: $e'));
    }
  }

  /// Eliminar proveedor offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, Unit>> _deleteSupplierOffline(String id) async {
    print('📱 SupplierRepository: Deleting supplier offline: $id');
    try {
      // Soft delete en ISAR
      try {
        final isar = IsarDatabase.instance.database;
        final isarSupplier = await isar.isarSuppliers
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarSupplier != null) {
          isarSupplier.softDelete();
          await isar.writeTxn(() async {
            await isar.isarSuppliers.put(isarSupplier);
          });
          print('✅ Supplier marcado como eliminado en ISAR (offline): $id');
        }
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
      }

      // Remover del cache
      await localDataSource.removeCachedSupplier(id);

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 Eliminación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Supplier deleted offline successfully');
      return const Right(unit);
    } catch (e) {
      print('❌ Error deleting supplier offline: $e');
      return Left(CacheFailure('Error al eliminar proveedor offline: $e'));
    }
  }

  /// Restaurar proveedor offline (reverse softDelete en ISAR + sync queue)
  Future<Either<Failure, Supplier>> _restoreSupplierOffline(String id) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarSupplier = await isar.isarSuppliers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarSupplier == null) {
        return Left(ServerFailure('Proveedor no encontrado localmente'));
      }

      isarSupplier.deletedAt = null;
      isarSupplier.markAsUnsynced();
      await isar.writeTxn(() => isar.isarSuppliers.put(isarSupplier));

      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'Supplier',
        entityId: id,
        operationType: SyncOperationType.update,
        data: {'id': id, 'action': 'restore'},
        priority: 2,
      );

      return Right(isarSupplier.toEntity());
    } catch (e) {
      return Left(ServerFailure('Error restaurando proveedor offline: $e'));
    }
  }

  /// Validar documento contra datos locales en ISAR
  Future<Either<Failure, bool>> _validateDocumentOffline(
    DocumentType documentType,
    String documentNumber,
    String? excludeId,
  ) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarDocType = _mapDocumentTypeToIsar(documentType);
      var query = isar.isarSuppliers
          .filter()
          .documentTypeEqualTo(isarDocType)
          .documentNumberEqualTo(documentNumber)
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.not().serverIdEqualTo(excludeId);
      }

      final match = await query.findFirst();
      // true = válido (no existe duplicado)
      return Right(match == null);
    } catch (_) {
      // En caso de error, permitir la operación (el servidor validará al sincronizar)
      return const Right(true);
    }
  }

  /// Validar código contra datos locales en ISAR
  Future<Either<Failure, bool>> _validateCodeOffline(String code, String? excludeId) async {
    try {
      final isar = IsarDatabase.instance.database;
      var query = isar.isarSuppliers
          .filter()
          .codeEqualTo(code)
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.not().serverIdEqualTo(excludeId);
      }

      final match = await query.findFirst();
      return Right(match == null);
    } catch (_) {
      return const Right(true);
    }
  }

  /// Validar email contra datos locales en ISAR
  Future<Either<Failure, bool>> _validateEmailOffline(String email, String? excludeId) async {
    try {
      final isar = IsarDatabase.instance.database;
      var query = isar.isarSuppliers
          .filter()
          .emailEqualTo(email)
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.not().serverIdEqualTo(excludeId);
      }

      final match = await query.findFirst();
      return Right(match == null);
    } catch (_) {
      return const Right(true);
    }
  }

  // ==================== HELPER METHODS ====================

  /// Mapear DocumentType a IsarDocumentType
  IsarDocumentType _mapDocumentTypeToIsar(DocumentType type) {
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

  /// Mapear SupplierStatus a IsarSupplierStatus
  IsarSupplierStatus _mapSupplierStatusToIsar(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return IsarSupplierStatus.active;
      case SupplierStatus.inactive:
        return IsarSupplierStatus.inactive;
      case SupplierStatus.blocked:
        return IsarSupplierStatus.blocked;
    }
  }
}