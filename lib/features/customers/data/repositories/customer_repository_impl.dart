// lib/features/customers/data/repositories/customer_repository_impl.dart
import 'package:baudex_desktop/features/customers/data/models/customer_query_model.dart';
import 'package:baudex_desktop/features/customers/data/models/update_customer_request_model.dart';
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_stats.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../datasources/customer_local_datasource.dart';
import '../models/isar/isar_customer.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/customer_model.dart';

import '../models/create_customer_request_model.dart';

/// Implementación del repositorio de clientes con sincronización dual cache
class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final dynamic database;

  const CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.database,
  });

  // Helper getter for ISAR access
  dynamic get isar => database.database;

  // ==================== CACHE OPERATIONS ====================

  Future<void> updateInIsar(Customer entity) async {
    final isarCustomer = await isar.isarCustomers
        .filter()
        .serverIdEqualTo(entity.id)
        .findFirst();

    if (isarCustomer == null) {
      // Si no existe, crear nuevo
      final newIsarCustomer = IsarCustomer.fromEntity(entity);
      newIsarCustomer.markAsUnsynced();
      await isar.writeTxn(() async {
        await isar.isarCustomers.put(newIsarCustomer);
      });
    } else {
      // Actualizar existente
      isarCustomer.firstName = entity.firstName;
      isarCustomer.lastName = entity.lastName;
      isarCustomer.companyName = entity.companyName;
      isarCustomer.email = entity.email;
      isarCustomer.phone = entity.phone;
      isarCustomer.mobile = entity.mobile;
      isarCustomer.address = entity.address;
      isarCustomer.city = entity.city;
      isarCustomer.state = entity.state;
      isarCustomer.zipCode = entity.zipCode;
      isarCustomer.country = entity.country;
      isarCustomer.creditLimit = entity.creditLimit;
      isarCustomer.paymentTerms = entity.paymentTerms;
      isarCustomer.birthDate = entity.birthDate;
      isarCustomer.notes = entity.notes;
      isarCustomer.markAsUnsynced();

      await isar.writeTxn(() async {
        await isar.isarCustomers.put(isarCustomer);
      });
    }
  }

  @override
  Future<void> updateInSecureStorage(Customer entity) async {
    final model = CustomerModel.fromEntity(entity);
    await localDataSource.cacheCustomer(model);
  }

  @override
  Future<void> deleteInIsar(String entityId) async {
    final isarCustomer = await isar.isarCustomers
        .filter()
        .serverIdEqualTo(entityId)
        .findFirst();

    if (isarCustomer != null) {
      isarCustomer.softDelete();
      await isar.writeTxn(() async {
        await isar.isarCustomers.put(isarCustomer);
      });
    }
  }

  @override
  Future<void> deleteInSecureStorage(String entityId) async {
    await localDataSource.removeCachedCustomer(entityId);
  }

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
    print('🔍 [CUSTOMER_REPO] getCustomers llamado - page=$page, limit=$limit, search=$search');

    final isConnected = await networkInfo.isConnected;
    print('🔍 [CUSTOMER_REPO] Network connected: $isConnected');

    if (isConnected) {
      print('🌐 [CUSTOMER_REPO] ONLINE - Llamando remoteDataSource...');
      try {
        final query = CustomerQueryModel(
          page: page,
          limit: limit,
          search: search,
          status: status?.name,
          documentType: documentType?.name,
          city: city,
          state: state,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );

        final response = await remoteDataSource.getCustomers(query);

        // Cache resultados en ISAR y SecureStorage para uso offline
        if (_shouldCacheResult(page, search, status, documentType)) {
          try {
            // Cachear en SecureStorage
            await localDataSource.cacheCustomers(response.data);

            // También cachear en ISAR para acceso offline
            print('💾 [CUSTOMER_REPO] Cacheando ${response.data.length} clientes en ISAR...');
            for (final customerModel in response.data) {
              final customer = customerModel.toEntity();
              await updateInIsar(customer);
            }
            print('✅ [CUSTOMER_REPO] ${response.data.length} clientes cacheados en ISAR');
          } catch (e) {
            print('⚠️ Error al cachear clientes: $e');
          }
        }

        final paginatedResult = response.toPaginatedResult();

        return Right(
          PaginatedResult<Customer>(
            data:
                paginatedResult.data.map((model) => model.toEntity()).toList(),
            meta: paginatedResult.meta,
          ),
        );
      } on ServerException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ServerException: ${e.message} - Intentando cache...');
        return _getCustomersFromCache();
      } on ConnectionException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ConnectionException: ${e.message} - Intentando cache...');
        return _getCustomersFromCache();
      } on CacheException catch (e) {
        print('⚠️ [CUSTOMER_REPO] CacheException: ${e.message} - Intentando cache...');
        return _getCustomersFromCache();
      } catch (e) {
        print('⚠️ [CUSTOMER_REPO] Exception: $e - Intentando cache como fallback...');
        return _getCustomersFromCache();
      }
    } else {
      print('📴 [CUSTOMER_REPO] OFFLINE - Cargando desde cache...');
      return _getCustomersFromCache();
    }
  }

  @override
  Future<Either<Failure, Customer?>> getDefaultCustomer(
    String customerId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        print('🔍 [DEFAULT CUSTOMER] Buscando cliente final: $customerId');

        final response = await remoteDataSource.getCustomerById(customerId);

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
          print('⚠️ Error al cachear cliente final: $e');
        }

        print(
          '✅ [DEFAULT CUSTOMER] Cliente encontrado: ${response.firstName} ${response.lastName}',
        );
        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('❌ [DEFAULT CUSTOMER] Error del servidor: ${e.message}');

        // Intentar desde cache como fallback
        final cacheResult = await _getCustomerFromCache(customerId);
        return cacheResult.fold(
          (failure) => const Right(null), // Retornar null en lugar de error
          (customer) => Right(customer),
        );
      } on ConnectionException catch (e) {
        print('❌ [DEFAULT CUSTOMER] Error de conexión: ${e.message}');
        return const Right(null);
      } catch (e) {
        print('💥 [DEFAULT CUSTOMER] Error inesperado: $e');
        return const Right(null);
      }
    } else {
      // Sin conexión, intentar desde cache
      final cacheResult = await _getCustomerFromCache(customerId);
      return cacheResult.fold(
        (failure) => const Right(null),
        (customer) => Right(customer),
      );
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCustomerById(id);

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
          print('⚠️ Error al cachear cliente individual: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        final cacheResult = await _getCustomerFromCache(id);
        return cacheResult.fold(
          (failure) => Left(_mapServerExceptionToFailure(e)),
          (customer) => Right(customer),
        );
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return _getCustomerFromCache(id);
      }
    } else {
      return _getCustomerFromCache(id);
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerByDocument(
    DocumentType documentType,
    String documentNumber,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCustomerByDocument(
          documentType.name,
          documentNumber,
        );

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
          print('⚠️ Error al cachear cliente por documento: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener cliente por documento: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerByEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCustomerByEmail(email);

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
          print('⚠️ Error al cachear cliente por email: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener cliente por email: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(
    String searchTerm, {
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.searchCustomers(
          searchTerm,
          limit,
        );
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado en búsqueda: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, CustomerStats>> getCustomerStats() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCustomerStats();

        try {
          await localDataSource.cacheCustomerStats(response);
        } catch (e) {
          print('⚠️ Error al cachear estadísticas: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener estadísticas: $e'),
        );
      }
    } else {
      return _getCustomerStatsFromCache();
    }
  }

  @override
  Future<Either<Failure, List<Customer>>>
  getCustomersWithOverdueInvoices() async {
    if (await networkInfo.isConnected) {
      try {
        final response =
            await remoteDataSource.getCustomersWithOverdueInvoices();
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener clientes con facturas vencidas: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getTopCustomers({
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getTopCustomers(limit);
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener top clientes: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
    if (await networkInfo.isConnected) {
      try {
        final request = CreateCustomerRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );

        final response = await remoteDataSource.createCustomer(request);

        try {
          await localDataSource.cacheCustomer(response);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de crear: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al crear cliente: ${e.message} - Creando offline...');
        return _createCustomerOffline(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al crear cliente: ${e.message} - Creando offline...');
        return _createCustomerOffline(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      } catch (e, stackTrace) {
        print('❌ Error inesperado al crear cliente: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando crear offline como fallback...');
        return _createCustomerOffline(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      }
    } else {
      // Sin conexión, crear cliente offline para sincronizar después
      return _createCustomerOffline(
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        email: email,
        phone: phone,
        mobile: mobile,
        documentType: documentType,
        documentNumber: documentNumber,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        status: status,
        creditLimit: creditLimit,
        paymentTerms: paymentTerms,
        birthDate: birthDate,
        notes: notes,
        metadata: metadata,
      );
    }
  }

  Future<Either<Failure, Customer>> _createCustomerOffline({
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
    print('📱 CustomerRepository: Creating customer offline: $firstName $lastName');
    try {
      // Generar un ID temporal único para el cliente offline
      final now = DateTime.now();
      final tempId = 'customer_offline_${now.millisecondsSinceEpoch}_${firstName.hashCode}';

      // Crear cliente con ID temporal
      final tempCustomer = Customer(
        id: tempId,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        email: email,
        phone: phone,
        mobile: mobile,
        documentType: documentType,
        documentNumber: documentNumber,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        status: status ?? CustomerStatus.active,
        creditLimit: creditLimit ?? 0.0,
        currentBalance: 0.0,
        paymentTerms: paymentTerms ?? 0,
        birthDate: birthDate,
        notes: notes,
        metadata: metadata ?? {},
        lastPurchaseAt: null,
        totalPurchases: 0.0,
        totalOrders: 0,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      // Guardar en ISAR
      await updateInIsar(tempCustomer);

      // Cache the customer
      try {
        final customerModel = CustomerModel.fromEntity(tempCustomer);
        await localDataSource.cacheCustomer(customerModel);
      } catch (e) {
        print('⚠️ Error caching customer (non-critical): $e');
      }

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'customer',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'firstName': firstName,
            'lastName': lastName,
            'companyName': companyName,
            'email': email,
            'phone': phone,
            'mobile': mobile,
            'documentType': documentType.name,
            'documentNumber': documentNumber,
            'address': address,
            'city': city,
            'state': state,
            'zipCode': zipCode,
            'country': country,
            'status': status?.name,
            'creditLimit': creditLimit,
            'paymentTerms': paymentTerms,
            'birthDate': birthDate?.toIso8601String(),
            'notes': notes,
            'metadata': metadata,
          },
          priority: 1, // Alta prioridad para creación
        );
        print('📤 CustomerRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ CustomerRepository: Error agregando a cola de sync: $e');
      }

      print('✅ CustomerRepository: Customer created offline successfully');
      return Right(tempCustomer);
    } catch (e) {
      print('❌ CustomerRepository: Error creating customer offline: $e');
      return Left(CacheFailure('Error al crear cliente offline: $e'));
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
    if (await networkInfo.isConnected) {
      try {
        final request = UpdateCustomerRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );

        if (!request.hasUpdates) {
          return Left(ValidationFailure(['No hay cambios para actualizar']));
        }

        final response = await remoteDataSource.updateCustomer(id, request);

        try {
          await localDataSource.cacheCustomer(response);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de modificar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ServerException en update: ${e.message} - Fallback offline...');
        return _updateCustomerOffline(
          id: id,
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      } on ConnectionException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ConnectionException en update: ${e.message} - Fallback offline...');
        return _updateCustomerOffline(
          id: id,
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      } catch (e) {
        print('⚠️ [CUSTOMER_REPO] Exception en update: $e - Fallback offline...');
        return _updateCustomerOffline(
          id: id,
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );
      }
    } else {
      // Sin conexión, actualizar en modo offline
      print('📴 [CUSTOMER_REPO] OFFLINE - Actualizando cliente offline...');
      return _updateCustomerOffline(
        id: id,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        email: email,
        phone: phone,
        mobile: mobile,
        documentType: documentType,
        documentNumber: documentNumber,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        status: status,
        creditLimit: creditLimit,
        paymentTerms: paymentTerms,
        birthDate: birthDate,
        notes: notes,
        metadata: metadata,
      );
    }
  }

  /// Actualiza un cliente en modo offline
  /// Guarda en ISAR + SecureStorage y agrega a cola de sincronización
  Future<Either<Failure, Customer>> _updateCustomerOffline({
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
    print('💾 CustomerRepository: Actualizando cliente offline: $id');
    try {
      // Obtener cliente actual de SecureStorage
      final cachedCustomerModel = await localDataSource.getCachedCustomer(id);
      if (cachedCustomerModel == null) {
        return Left(CacheFailure('Cliente no encontrado en cache: $id'));
      }
      final cachedCustomer = cachedCustomerModel.toEntity();

      // Crear entidad actualizada con los cambios
      final updatedCustomer = Customer(
        id: id,
        firstName: firstName ?? cachedCustomer.firstName,
        lastName: lastName ?? cachedCustomer.lastName,
        companyName: companyName ?? cachedCustomer.companyName,
        email: email ?? cachedCustomer.email,
        phone: phone ?? cachedCustomer.phone,
        mobile: mobile ?? cachedCustomer.mobile,
        documentType: documentType ?? cachedCustomer.documentType,
        documentNumber: documentNumber ?? cachedCustomer.documentNumber,
        address: address ?? cachedCustomer.address,
        city: city ?? cachedCustomer.city,
        state: state ?? cachedCustomer.state,
        zipCode: zipCode ?? cachedCustomer.zipCode,
        country: country ?? cachedCustomer.country,
        status: status ?? cachedCustomer.status,
        creditLimit: creditLimit ?? cachedCustomer.creditLimit,
        currentBalance: cachedCustomer.currentBalance,
        paymentTerms: paymentTerms ?? cachedCustomer.paymentTerms,
        birthDate: birthDate ?? cachedCustomer.birthDate,
        notes: notes ?? cachedCustomer.notes,
        metadata: metadata ?? cachedCustomer.metadata,
        lastPurchaseAt: cachedCustomer.lastPurchaseAt,
        totalPurchases: cachedCustomer.totalPurchases,
        totalOrders: cachedCustomer.totalOrders,
        createdAt: cachedCustomer.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCustomer.deletedAt,
      );

      // Guardar en ISAR
      await updateInIsar(updatedCustomer);

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        final request = UpdateCustomerRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          companyName: companyName,
          email: email,
          phone: phone,
          mobile: mobile,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          status: status,
          creditLimit: creditLimit,
          paymentTerms: paymentTerms,
          birthDate: birthDate,
          notes: notes,
          metadata: metadata,
        );

        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.update,
          data: request.toJson(),
          priority: 1,
        );
        print('📤 CustomerRepository: UPDATE agregado a cola de sincronización');
      } catch (e) {
        print('⚠️ CustomerRepository: Error agregando UPDATE a cola: $e');
      }

      print('✅ CustomerRepository: Cliente actualizado offline exitosamente');
      return Right(updatedCustomer);
    } catch (e) {
      print('❌ Error actualizando cliente offline: $e');
      return Left(CacheFailure('Error al actualizar cliente offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomerStatus({
    required String id,
    required CustomerStatus status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateCustomerStatus(
          id,
          status.name,
        );

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
          print('⚠️ Error al actualizar cache después de cambiar estado: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al actualizar estado: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomerBalance({
    required String id,
    required double amount,
    required String operation,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Try online first
        final customer = await remoteDataSource.getCustomerById(id);

        // Calculate new balance
        double newBalance = customer.currentBalance;
        if (operation == 'add') {
          newBalance += amount;
        } else if (operation == 'subtract') {
          newBalance -= amount;
        }

        // Update customer with new balance
        final request = UpdateCustomerRequestModel(currentBalance: newBalance);
        final updatedCustomer = await remoteDataSource.updateCustomer(id, request);

        // Cache the updated customer
        await localDataSource.cacheCustomer(updatedCustomer);
        await updateInIsar(updatedCustomer.toEntity());

        return Right(updatedCustomer.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ServerException updating balance: ${e.message} - Fallback offline...');
        return _updateCustomerBalanceOffline(id, amount, operation);
      } on ConnectionException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ConnectionException updating balance: ${e.message} - Fallback offline...');
        return _updateCustomerBalanceOffline(id, amount, operation);
      } catch (e) {
        print('⚠️ [CUSTOMER_REPO] Exception updating balance: $e - Fallback offline...');
        return _updateCustomerBalanceOffline(id, amount, operation);
      }
    } else {
      // Offline mode
      print('📴 [CUSTOMER_REPO] OFFLINE - Updating balance offline...');
      return _updateCustomerBalanceOffline(id, amount, operation);
    }
  }

  /// Updates customer balance in offline mode
  Future<Either<Failure, Customer>> _updateCustomerBalanceOffline(
    String id,
    double amount,
    String operation,
  ) async {
    print('💾 CustomerRepository: Updating balance offline: $id, amount: $amount, op: $operation');
    try {
      // Get customer from ISAR
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return const Left(CacheFailure('Customer not found in local database'));
      }

      // Calculate new balance
      double newBalance = isarCustomer.currentBalance;
      if (operation == 'add') {
        newBalance += amount;
      } else if (operation == 'subtract') {
        newBalance -= amount;
      }

      // Update balance in ISAR
      isarCustomer.currentBalance = newBalance;
      isarCustomer.isSynced = false;
      isarCustomer.updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.isarCustomers.put(isarCustomer);
      });

      print('✅ Balance updated in ISAR (offline): $id, new balance: $newBalance');

      // Update cache
      final updatedEntity = isarCustomer.toEntity();
      final updatedModel = CustomerModel.fromEntity(updatedEntity);

      try {
        await localDataSource.cacheCustomer(updatedModel);
      } catch (e) {
        print('⚠️ Error updating cache (non-critical): $e');
      }

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'id': id,
            'currentBalance': newBalance,
          },
          priority: 2,
        );
        print('📤 CustomerRepository: Balance update added to sync queue');
      } catch (e) {
        print('⚠️ CustomerRepository: Error adding to sync queue: $e');
      }

      return Right(updatedEntity);
    } catch (e) {
      print('❌ CustomerRepository: Error updating balance offline: $e');
      return Left(CacheFailure('Failed to update balance offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomer(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCustomer(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isarCustomer = await isar.isarCustomers
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarCustomer != null) {
            isarCustomer.softDelete();
            await isar.writeTxn(() async {
              await isar.isarCustomers.put(isarCustomer);
            });
            print('✅ Customer marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        try {
          await localDataSource.removeCachedCustomer(id);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de eliminar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ServerException en delete: ${e.message} - Fallback offline...');
        return _deleteCustomerOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ConnectionException en delete: ${e.message} - Fallback offline...');
        return _deleteCustomerOffline(id);
      } catch (e) {
        print('⚠️ [CUSTOMER_REPO] Exception en delete: $e - Fallback offline...');
        return _deleteCustomerOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      print('📴 [CUSTOMER_REPO] OFFLINE - Eliminando cliente offline...');
      return _deleteCustomerOffline(id);
    }
  }

  /// Elimina un cliente en modo offline
  /// Marca como eliminado en ISAR y agrega a cola de sincronización
  Future<Either<Failure, Unit>> _deleteCustomerOffline(String id) async {
    print('💾 CustomerRepository: Eliminando cliente offline: $id');
    try {
      // Soft delete en ISAR
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer != null) {
        isarCustomer.softDelete();
        await isar.writeTxn(() async {
          await isar.isarCustomers.put(isarCustomer);
        });
        print('✅ Customer marcado como eliminado en ISAR (offline): $id');
      }

      // Remover del cache (no crítico)
      try {
        await localDataSource.removeCachedCustomer(id);
        await _invalidateListCache();
      } catch (e) {
        print('⚠️ Error al actualizar cache (no crítico): $e');
      }

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 CustomerRepository: Eliminación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ CustomerRepository: Error agregando eliminación a cola: $e');
      }

      print('✅ CustomerRepository: Customer deleted offline successfully');
      return const Right(unit);
    } catch (e) {
      print('❌ CustomerRepository: Error deleting customer offline: $e');
      return Left(CacheFailure('Error al eliminar cliente offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> restoreCustomer(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.restoreCustomer(id);

        try {
          await localDataSource.cacheCustomer(response);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de restaurar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al restaurar cliente: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> isEmailAvailable(
    String email, {
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isAvailable = await remoteDataSource.isEmailAvailable(
          email,
          excludeId,
        );
        return Right(isAvailable);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al verificar email: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> isDocumentAvailable(
    DocumentType documentType,
    String documentNumber, {
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isAvailable = await remoteDataSource.isDocumentAvailable(
          documentType.name,
          documentNumber,
          excludeId,
        );
        return Right(isAvailable);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al verificar documento: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> canMakePurchase({
    required String customerId,
    required double amount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.canMakePurchase(
          customerId,
          amount,
        );
        return Right(result);
      } on ServerException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ServerException in canMakePurchase: ${e.message} - Fallback offline...');
        return _canMakePurchaseOffline(customerId, amount);
      } on ConnectionException catch (e) {
        print('⚠️ [CUSTOMER_REPO] ConnectionException in canMakePurchase: ${e.message} - Fallback offline...');
        return _canMakePurchaseOffline(customerId, amount);
      } catch (e) {
        print('⚠️ [CUSTOMER_REPO] Exception in canMakePurchase: $e - Fallback offline...');
        return _canMakePurchaseOffline(customerId, amount);
      }
    } else {
      // Offline mode - calculate from local data
      print('📴 [CUSTOMER_REPO] OFFLINE - Checking purchase capacity offline...');
      return _canMakePurchaseOffline(customerId, amount);
    }
  }

  /// Checks if customer can make a purchase in offline mode using ISAR data
  Future<Either<Failure, Map<String, dynamic>>> _canMakePurchaseOffline(
    String customerId,
    double amount,
  ) async {
    print('💾 CustomerRepository: Checking purchase capacity offline: $customerId, amount: $amount');
    try {
      // Get customer from ISAR
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .findFirst();

      if (isarCustomer == null) {
        return const Left(CacheFailure('Customer not found in local database'));
      }

      // Calculate available credit
      final availableCredit = isarCustomer.creditLimit - isarCustomer.currentBalance;
      final canPurchase = availableCredit >= amount;

      print('✅ Purchase check (offline): canPurchase=$canPurchase, available=$availableCredit');

      return Right({
        'canPurchase': canPurchase,
        'availableCredit': availableCredit,
        'creditLimit': isarCustomer.creditLimit,
        'currentBalance': isarCustomer.currentBalance,
      });
    } catch (e) {
      print('❌ CustomerRepository: Error checking purchase capacity offline: $e');
      return Left(CacheFailure('Failed to check purchase capacity offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerFinancialSummary(
    String customerId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCustomerFinancialSummary(
          customerId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener resumen financiero: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Customer>>> getCachedCustomers() async {
    try {
      final customers = await localDataSource.getCachedCustomers();
      return Right(customers.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al obtener cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCustomerCache() async {
    try {
      await localDataSource.clearCustomerCache();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al limpiar cache: $e'));
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Determinar si se debe cachear el resultado
  bool _shouldCacheResult(
    int page,
    String? search,
    CustomerStatus? status,
    DocumentType? documentType,
  ) {
    return page == 1 &&
        search == null &&
        status == null &&
        documentType == null;
  }

  /// Invalidar cache de listados para reflejar cambios
  Future<void> _invalidateListCache() async {
    try {
      await localDataSource.clearCustomerCache();
    } catch (e) {
      print('⚠️ Error al invalidar cache de listados: $e');
    }
  }

  /// Obtener clientes desde cache local (ISAR + SecureStorage fallback)
  Future<Either<Failure, PaginatedResult<Customer>>>
  _getCustomersFromCache() async {
    print('💾 [CUSTOMER_REPO] _getCustomersFromCache - Intentando ISAR primero...');
    try {
      // Intentar desde ISAR primero (más rápido y soporta filtros)
      final isarCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll() as List<IsarCustomer>;

      if (isarCustomers.isNotEmpty) {
        print('💾 [CUSTOMER_REPO] ISAR tiene ${isarCustomers.length} clientes');
        final customers = isarCustomers.map((ic) => ic.toEntity()).toList();

        final meta = PaginationMeta(
          page: 1,
          limit: customers.length,
          totalItems: customers.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );

        return Right(
          PaginatedResult<Customer>(
            data: customers,
            meta: meta,
          ),
        );
      }

      // Fallback a SecureStorage si ISAR está vacío
      print('💾 [CUSTOMER_REPO] ISAR vacío, intentando SecureStorage...');
      final customers = await localDataSource.getCachedCustomers();
      print('💾 [CUSTOMER_REPO] SecureStorage tiene ${customers.length} clientes');

      final meta = PaginationMeta(
        page: 1,
        limit: customers.length,
        totalItems: customers.length,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: false,
      );

      return Right(
        PaginatedResult<Customer>(
          data: customers.map((model) => model.toEntity()).toList(),
          meta: meta,
        ),
      );
    } on CacheException catch (e) {
      print('❌ [CUSTOMER_REPO] CacheException: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [CUSTOMER_REPO] Error en cache: $e');
      return Left(UnknownFailure('Error al obtener clientes desde cache: $e'));
    }
  }

  /// Obtener cliente individual desde cache local
  Future<Either<Failure, Customer>> _getCustomerFromCache(String id) async {
    try {
      final customer = await localDataSource.getCachedCustomer(id);
      if (customer != null) {
        return Right(customer.toEntity());
      } else {
        return const Left(CacheFailure('Datos no encontrados en cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener cliente desde cache: $e'));
    }
  }

  /// Obtener estadísticas desde cache
  Future<Either<Failure, CustomerStats>> _getCustomerStatsFromCache() async {
    try {
      final stats = await localDataSource.getCachedCustomerStats();
      if (stats != null) {
        return Right(stats.toEntity());
      } else {
        return const Left(CacheFailure('Datos no encontrados en cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Error al obtener estadísticas desde cache: $e'),
      );
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar clientes creados offline con el servidor
  Future<Either<Failure, List<Customer>>> syncOfflineCustomers() async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure.noInternet);
    }

    try {
      print('🔄 CustomerRepository: Starting offline customers sync...');

      // Obtener clientes no sincronizados desde ISAR
      final unsyncedCustomers = await isar.isarCustomers
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomer>;

      if (unsyncedCustomers.isEmpty) {
        print('✅ CustomerRepository: No customers to sync');
        return const Right([]);
      }

      print('📤 CustomerRepository: Syncing ${unsyncedCustomers.length} offline customers...');
      final syncedCustomers = <Customer>[];

      for (final isarCustomer in unsyncedCustomers) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarCustomer.serverId.startsWith('customer_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            print('📝 Creating customer: ${isarCustomer.firstName} ${isarCustomer.lastName}');

            final request = CreateCustomerRequestModel.fromParams(
              firstName: isarCustomer.firstName,
              lastName: isarCustomer.lastName,
              companyName: isarCustomer.companyName,
              email: isarCustomer.email,
              phone: isarCustomer.phone,
              mobile: isarCustomer.mobile,
              documentType: _mapIsarDocumentType(isarCustomer.documentType),
              documentNumber: isarCustomer.documentNumber,
              address: isarCustomer.address,
              city: isarCustomer.city,
              state: isarCustomer.state,
              zipCode: isarCustomer.zipCode,
              country: isarCustomer.country,
              status: _mapIsarCustomerStatus(isarCustomer.status),
              creditLimit: isarCustomer.creditLimit,
              paymentTerms: isarCustomer.paymentTerms,
              birthDate: isarCustomer.birthDate,
              notes: isarCustomer.notes,
            );

            final created = await remoteDataSource.createCustomer(request);

            // Actualizar ISAR con el ID real del servidor
            isarCustomer.serverId = created.id;
            isarCustomer.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarCustomers.put(isarCustomer);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheCustomer(created);

            syncedCustomers.add(created.toEntity());
            print('✅ Customer created and synced: ${isarCustomer.firstName} ${isarCustomer.lastName} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            print('📝 Updating customer: ${isarCustomer.firstName} ${isarCustomer.lastName}');

            final request = UpdateCustomerRequestModel.fromParams(
              firstName: isarCustomer.firstName,
              lastName: isarCustomer.lastName,
              companyName: isarCustomer.companyName,
              email: isarCustomer.email,
              phone: isarCustomer.phone,
              mobile: isarCustomer.mobile,
              documentType: _mapIsarDocumentType(isarCustomer.documentType),
              documentNumber: isarCustomer.documentNumber,
              address: isarCustomer.address,
              city: isarCustomer.city,
              state: isarCustomer.state,
              zipCode: isarCustomer.zipCode,
              country: isarCustomer.country,
              status: _mapIsarCustomerStatus(isarCustomer.status),
              creditLimit: isarCustomer.creditLimit,
              paymentTerms: isarCustomer.paymentTerms,
              birthDate: isarCustomer.birthDate,
              notes: isarCustomer.notes,
            );

            final updated = await remoteDataSource.updateCustomer(
              isarCustomer.serverId,
              request,
            );

            isarCustomer.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarCustomers.put(isarCustomer);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheCustomer(updated);

            syncedCustomers.add(updated.toEntity());
            print('✅ Customer updated and synced: ${isarCustomer.firstName} ${isarCustomer.lastName}');
          }
        } catch (e) {
          print('❌ Error sincronizando cliente ${isarCustomer.firstName} ${isarCustomer.lastName}: $e');
          // Continuar con la siguiente
        }
      }

      print('🎯 CustomerRepository: Sync completed. Success: ${syncedCustomers.length}');
      return Right(syncedCustomers);
    } catch (e) {
      print('💥 CustomerRepository: Error during offline customers sync: $e');
      return Left(UnknownFailure('Error al sincronizar clientes offline: $e'));
    }
  }

  // Helper methods para mapear tipos ISAR a domain
  DocumentType _mapIsarDocumentType(IsarDocumentType type) {
    switch (type) {
      case IsarDocumentType.cc:
        return DocumentType.cc;
      case IsarDocumentType.nit:
        return DocumentType.nit;
      case IsarDocumentType.ce:
        return DocumentType.ce;
      case IsarDocumentType.passport:
        return DocumentType.passport;
      case IsarDocumentType.other:
        return DocumentType.other;
    }
  }

  CustomerStatus _mapIsarCustomerStatus(IsarCustomerStatus status) {
    switch (status) {
      case IsarCustomerStatus.active:
        return CustomerStatus.active;
      case IsarCustomerStatus.inactive:
        return CustomerStatus.inactive;
      case IsarCustomerStatus.suspended:
        return CustomerStatus.suspended;
    }
  }

  /// Mapear ServerException a Failure específico
  Failure _mapServerExceptionToFailure(ServerException exception) {
    if (exception.statusCode != null) {
      return ServerFailure.fromStatusCode(
        exception.statusCode!,
        exception.message,
      );
    } else {
      return ServerFailure(exception.message);
    }
  }
}
