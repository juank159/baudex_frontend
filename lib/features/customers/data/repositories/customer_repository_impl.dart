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
import '../../../../app/core/services/conflict_resolver.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_stats.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../datasources/customer_local_datasource.dart';
import '../models/isar/isar_customer.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../customer_credits/data/models/isar/isar_customer_credit.dart';
import '../models/customer_model.dart';

import '../models/create_customer_request_model.dart';

/// Implementación del repositorio de clientes con sincronización dual cache
class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final IIsarDatabase database;

  const CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.database,
  });

  // Helper getter for ISAR access
  Isar get isar => database.database as Isar;

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

    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
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

        // ✅ Resetear estado de conectividad si el servidor respondió
        networkInfo.resetServerReachability();

        // Cache resultados en ISAR y SecureStorage para uso offline
        if (_shouldCacheResult(page, search, status, documentType)) {
          try {
            // Cachear en SecureStorage
            await localDataSource.cacheCustomers(response.data);

            // También cachear en ISAR para acceso offline
            for (final customerModel in response.data) {
              final customer = customerModel.toEntity();
              await updateInIsar(customer);
            }
          } catch (e) {
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
        // ✅ Marcar servidor como no alcanzable si es error de conexión/timeout
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomersFromCache();
      } on ConnectionException catch (e) {
        // ✅ Marcar servidor como no alcanzable para evitar timeouts repetidos
        networkInfo.markServerUnreachable();
        return _getCustomersFromCache();
      } on CacheException catch (e) {
        return _getCustomersFromCache();
      } catch (e) {
        // ✅ Marcar servidor como no alcanzable si es error de conexión
        if (e.toString().contains('timeout') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomersFromCache();
      }
    } else {
      return _getCustomersFromCache();
    }
  }

  @override
  Future<Either<Failure, Customer?>> getDefaultCustomer(
    String customerId,
  ) async {
    if (await networkInfo.isConnected) {
      try {

        final response = await remoteDataSource.getCustomerById(customerId);

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {

        // Intentar desde cache como fallback
        final cacheResult = await _getCustomerFromCache(customerId);
        return cacheResult.fold(
          (failure) => const Right(null), // Retornar null en lugar de error
          (customer) => Right(customer),
        );
      } on ConnectionException catch (e) {
        return const Right(null);
      } catch (e) {
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

        // ⭐ FASE 1: Resolución de conflictos con ConflictResolver
        Customer finalCustomer = response.toEntity();
        try {
          // Obtener versión local de ISAR para acceder a campos de versionamiento
          final localIsarCustomer = await localDataSource.getIsarCustomer(id);

          if (localIsarCustomer != null && !localIsarCustomer.isSynced) {
            // Hay una versión local no sincronizada, verificar conflictos

            // Crear versión ISAR del servidor para comparar
            final serverIsarCustomer = IsarCustomer.fromModel(response);

            // Usar ConflictResolver para detectar y resolver
            final resolver = Get.find<ConflictResolver>();
            final resolution = resolver.resolveConflict<IsarCustomer>(
              localData: localIsarCustomer,
              serverData: serverIsarCustomer,
              strategy: ConflictResolutionStrategy.newerWins,
              hasConflictWith: (local, server) => local.hasConflictWith(server),
              getVersion: (data) => data.version,
              getLastModifiedAt: (data) => data.lastModifiedAt,
            );

            if (resolution.hadConflict) {
              finalCustomer = resolution.resolvedData.toEntity();
            } else {
            }
          } else if (localIsarCustomer == null) {
          } else {
          }
        } catch (e) {
        }

        // Cachear el cliente final (resuelto)
        try {
          await localDataSource.cacheCustomer(CustomerModel.fromEntity(finalCustomer));
        } catch (e) {
        }

        return Right(finalCustomer);
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
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        // Si el servidor falla, intentar cache local antes de devolver error
        final cached =
            await localDataSource.getCachedCustomerByDocument(documentNumber);
        if (cached != null) return Right(cached.toEntity());
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (_) {
        // Conexión perdida durante la request: caer al cache local.
        final cached =
            await localDataSource.getCachedCustomerByDocument(documentNumber);
        if (cached != null) return Right(cached.toEntity());
        return const Left(ConnectionFailure.noInternet);
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener cliente por documento: $e',
          ),
        );
      }
    } else {
      // Offline: leer directamente del cache local (Isar). El método
      // devuelve null si no está cacheado — solo en ese caso reportamos
      // sin conexión para evitar bloquear al cajero por DNI no consultados.
      final cached =
          await localDataSource.getCachedCustomerByDocument(documentNumber);
      if (cached != null) return Right(cached.toEntity());
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
    int? limit,
  }) async {
    // El remote data source exige `int` no nullable. Si el caller no
    // envía límite (búsqueda completa), aplicamos un cap defensivo alto
    // en el server para no traer una página gigante por accidente. La
    // rama offline (ISAR) sí respeta el null y devuelve todo.
    final remoteLimit = limit ?? 100;
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.searchCustomers(
          searchTerm,
          remoteLimit,
        );
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión') || e.message.contains('Connection')) {
          networkInfo.markServerUnreachable();
        }
        return _searchCustomersOffline(searchTerm, limit: limit);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _searchCustomersOffline(searchTerm, limit: limit);
      } catch (e) {
        if (e.toString().contains('Connection') || e.toString().contains('timeout')) {
          networkInfo.markServerUnreachable();
        }
        return _searchCustomersOffline(searchTerm, limit: limit);
      }
    } else {
      return _searchCustomersOffline(searchTerm, limit: limit);
    }
  }

  /// Búsqueda de clientes offline usando ISAR.
  /// `limit` null → sin tope, devuelve todos los matches.
  Future<Either<Failure, List<Customer>>> _searchCustomersOffline(
    String searchTerm, {
    int? limit,
  }) async {
    try {

      // ✅ Dividir término de búsqueda en palabras para búsqueda más flexible
      final searchWords = searchTerm.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList();

      // Obtener todos los clientes activos
      final allCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .findAll();

      // Filtrar manualmente para soportar búsqueda de múltiples palabras
      final matchingCustomers = allCustomers.where((customer) {
        final firstName = customer.firstName.toLowerCase();
        final lastName = customer.lastName.toLowerCase();
        final fullName = '$firstName $lastName';
        final email = (customer.email ?? '').toLowerCase();
        final documentNumber = (customer.documentNumber ?? '').toLowerCase();
        final companyName = (customer.companyName ?? '').toLowerCase();

        // Verificar si TODAS las palabras de búsqueda están presentes en alguno de los campos
        for (final word in searchWords) {
          final wordFound = firstName.contains(word) ||
              lastName.contains(word) ||
              fullName.contains(word) ||
              email.contains(word) ||
              documentNumber.contains(word) ||
              companyName.contains(word);

          if (!wordFound) return false;
        }
        return true;
      }).toList();

      // Aplicar `limit` solo si se especificó (null = todos los matches).
      final matchingCustomersLimited =
          limit != null ? matchingCustomers.take(limit).toList() : matchingCustomers;
      final customers = matchingCustomersLimited.map((isarCustomer) => isarCustomer.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Error buscando clientes offline: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerStats>> getCustomerStats() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCustomerStats();

        // ✅ Resetear estado de conectividad si el servidor respondió
        networkInfo.resetServerReachability();

        try {
          await localDataSource.cacheCustomerStats(response);
        } catch (e) {
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('Connection')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomerStatsFromCache();
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _getCustomerStatsFromCache();
      } catch (e) {
        if (e.toString().contains('Connection') || e.toString().contains('timeout')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomerStatsFromCache();
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
        networkInfo.resetServerReachability();
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomersWithOverdueFromIsar();
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _getCustomersWithOverdueFromIsar();
      } catch (e) {
        if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
          networkInfo.markServerUnreachable();
        }
        return _getCustomersWithOverdueFromIsar();
      }
    } else {
      return _getCustomersWithOverdueFromIsar();
    }
  }

  /// Obtener clientes con facturas vencidas desde ISAR (aproximación: clientes con balance > 0)
  Future<Either<Failure, List<Customer>>> _getCustomersWithOverdueFromIsar() async {
    try {
      final isarCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .currentBalanceGreaterThan(0)
          .sortByCurrentBalanceDesc()
          .findAll();

      final customers = isarCustomers.map((ic) => ic.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return const Right(<Customer>[]);
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getTopCustomers({
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getTopCustomers(limit);
        networkInfo.resetServerReachability();
        final customers = response.map((model) => model.toEntity()).toList();
        return Right(customers);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getTopCustomersFromIsar(limit);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _getTopCustomersFromIsar(limit);
      } catch (e) {
        if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
          networkInfo.markServerUnreachable();
        }
        return _getTopCustomersFromIsar(limit);
      }
    } else {
      return _getTopCustomersFromIsar(limit);
    }
  }

  /// ✅ Obtener top clientes desde ISAR (ordenados por totalPurchases)
  Future<Either<Failure, List<Customer>>> _getTopCustomersFromIsar(int limit) async {
    try {
      final isarCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByTotalPurchasesDesc()
          .limit(limit)
          .findAll();

      final customers = isarCustomers.map((ic) => ic.toEntity()).toList();
      return Right(customers);
    } catch (e) {
      return const Right(<Customer>[]);
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
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        // Errores de validación (400, 409, 422) NO se deben crear offline - el usuario debe corregir
        if (e.statusCode == 400 || e.statusCode == 409 || e.statusCode == 422) {
          return Left(ServerFailure(e.message));
        }
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
      }

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
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
      } catch (e) {
      }

      return Right(tempCustomer);
    } catch (e) {
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
    // Si el ID es temporal (cliente creado offline), ir directo a offline
    // No enviar temp ID al servidor → causaría 400 (UUID inválido)
    if (id.startsWith('customer_offline_')) {
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
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        // Errores de validación (400, 422) y conflictos (409) NO se deben crear offline
        // El usuario debe corregir los datos
        if (e.statusCode == 400 || e.statusCode == 422 || e.statusCode == 409) {
          return Left(ServerFailure(e.message));
        }
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
      } catch (e) {
      }

      return Right(updatedCustomer);
    } catch (e) {
      return Left(CacheFailure('Error al actualizar cliente offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomerStatus({
    required String id,
    required CustomerStatus status,
  }) async {
    // Para IDs temporales, ir directo a offline
    if (id.startsWith('customer_offline_')) {
      return _updateCustomerOffline(id: id, status: status);
    }

    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateCustomerStatus(
          id,
          status.name,
        );

        try {
          await localDataSource.cacheCustomer(response);
        } catch (e) {
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _updateCustomerOffline(id: id, status: status);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _updateCustomerOffline(id: id, status: status);
      } catch (e) {
        return _updateCustomerOffline(id: id, status: status);
      }
    } else {
      return _updateCustomerOffline(id: id, status: status);
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
        return _updateCustomerBalanceOffline(id, amount, operation);
      } on ConnectionException catch (e) {
        return _updateCustomerBalanceOffline(id, amount, operation);
      } catch (e) {
        return _updateCustomerBalanceOffline(id, amount, operation);
      }
    } else {
      // Offline mode
      return _updateCustomerBalanceOffline(id, amount, operation);
    }
  }

  /// Updates customer balance in offline mode
  Future<Either<Failure, Customer>> _updateCustomerBalanceOffline(
    String id,
    double amount,
    String operation,
  ) async {
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

      // Update cache
      final updatedEntity = isarCustomer.toEntity();
      final updatedModel = CustomerModel.fromEntity(updatedEntity);

      try {
        await localDataSource.cacheCustomer(updatedModel);
      } catch (e) {
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
      } catch (e) {
      }

      return Right(updatedEntity);
    } catch (e) {
      return Left(CacheFailure('Failed to update balance offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomer(String id) async {
    // Si el ID es temporal (cliente creado offline y nunca sincronizado),
    // cancelar la operación CREATE pendiente y eliminar de ISAR directamente
    if (id.startsWith('customer_offline_')) {
      return _deleteOfflineCreatedCustomer(id);
    }

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
          }
        } catch (e) {
        }

        try {
          await localDataSource.removeCachedCustomer(id);
          await _invalidateListCache();
        } catch (e) {
        }

        return const Right(unit);
      } on ServerException catch (e) {
        return _deleteCustomerOffline(id);
      } on ConnectionException catch (e) {
        return _deleteCustomerOffline(id);
      } catch (e) {
        return _deleteCustomerOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      return _deleteCustomerOffline(id);
    }
  }

  /// Elimina un cliente creado offline que nunca fue sincronizado al servidor.
  /// Cancela la operación CREATE pendiente en SyncQueue y elimina de ISAR.
  Future<Either<Failure, Unit>> _deleteOfflineCreatedCustomer(String id) async {
    try {
      // 1. Cancelar operaciones pendientes en SyncQueue para este ID
      try {
        await IsarDatabase.instance.deleteSyncOperationsByEntityId(id);
      } catch (e) {
      }

      // 2. Eliminar de ISAR (hard delete, ya que nunca existió en el servidor)
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer != null) {
        await isar.writeTxn(() async {
          await isar.isarCustomers.delete(isarCustomer.id);
        });
      }

      // 3. Remover del cache SecureStorage
      try {
        await localDataSource.removeCachedCustomer(id);
        await _invalidateListCache();
      } catch (e) {
      }

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar cliente offline: $e'));
    }
  }

  /// Elimina un cliente en modo offline
  /// Marca como eliminado en ISAR y agrega a cola de sincronización
  Future<Either<Failure, Unit>> _deleteCustomerOffline(String id) async {
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
      }

      // Remover del cache (no crítico)
      try {
        await localDataSource.removeCachedCustomer(id);
        await _invalidateListCache();
      } catch (e) {
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
      } catch (e) {
      }

      return const Right(unit);
    } catch (e) {
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
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _restoreCustomerOffline(id);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _restoreCustomerOffline(id);
      } catch (e) {
        return _restoreCustomerOffline(id);
      }
    } else {
      return _restoreCustomerOffline(id);
    }
  }

  /// Restaurar un cliente eliminado en modo offline
  Future<Either<Failure, Customer>> _restoreCustomerOffline(String id) async {
    try {
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Cliente no encontrado en ISAR: $id'));
      }

      isarCustomer.deletedAt = null;
      isarCustomer.markAsUnsynced();

      await isar.writeTxn(() async {
        await isar.isarCustomers.put(isarCustomer);
      });

      // Cancelar DELETE pendiente y encolar UPDATE
      try {
        await IsarDatabase.instance.deleteSyncOperationsByEntityId(id);
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'status': 'active'},
          priority: 1,
        );
      } catch (e) {
      }

      return Right(isarCustomer.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restaurando cliente offline: $e'));
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
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _isEmailAvailableOffline(email, excludeId: excludeId);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _isEmailAvailableOffline(email, excludeId: excludeId);
      } catch (e) {
        return _isEmailAvailableOffline(email, excludeId: excludeId);
      }
    } else {
      return _isEmailAvailableOffline(email, excludeId: excludeId);
    }
  }

  /// Verificar disponibilidad de email offline usando ISAR
  Future<Either<Failure, bool>> _isEmailAvailableOffline(
    String email, {
    String? excludeId,
  }) async {
    try {
      var query = isar.isarCustomers
          .filter()
          .emailEqualTo(email, caseSensitive: false)
          .and()
          .deletedAtIsNull();

      if (excludeId != null) {
        query = query.and().not().serverIdEqualTo(excludeId);
      }

      final count = await query.count();
      return Right(count == 0);
    } catch (e) {
      // En caso de error, asumir disponible (el servidor validará al sincronizar)
      return const Right(true);
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
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _isDocumentAvailableOffline(documentType, documentNumber, excludeId: excludeId);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _isDocumentAvailableOffline(documentType, documentNumber, excludeId: excludeId);
      } catch (e) {
        return _isDocumentAvailableOffline(documentType, documentNumber, excludeId: excludeId);
      }
    } else {
      return _isDocumentAvailableOffline(documentType, documentNumber, excludeId: excludeId);
    }
  }

  /// Verificar disponibilidad de documento offline usando ISAR
  Future<Either<Failure, bool>> _isDocumentAvailableOffline(
    DocumentType documentType,
    String documentNumber, {
    String? excludeId,
  }) async {
    try {
      final isarDocType = IsarDocumentType.values.firstWhere(
        (e) => e.name == documentType.name,
        orElse: () => IsarDocumentType.other,
      );

      var query = isar.isarCustomers
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
      // En caso de error, asumir disponible (el servidor validará al sincronizar)
      return const Right(true);
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
        return _canMakePurchaseOffline(customerId, amount);
      } on ConnectionException catch (e) {
        return _canMakePurchaseOffline(customerId, amount);
      } catch (e) {
        return _canMakePurchaseOffline(customerId, amount);
      }
    } else {
      // Offline mode - calculate from local data
      return _canMakePurchaseOffline(customerId, amount);
    }
  }

  /// Checks if customer can make a purchase in offline mode using ISAR data
  Future<Either<Failure, Map<String, dynamic>>> _canMakePurchaseOffline(
    String customerId,
    double amount,
  ) async {
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

      return Right({
        'canPurchase': canPurchase,
        'availableCredit': availableCredit,
        'creditLimit': isarCustomer.creditLimit,
        'currentBalance': isarCustomer.currentBalance,
      });
    } catch (e) {
      return Left(CacheFailure('Failed to check purchase capacity offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerFinancialSummary(
    String customerId,
  ) async {
    // Calcular deuda real desde ISAR customer_credits (fuente de verdad local).
    // El campo currentBalance en la entidad Customer del backend no se actualizaba
    // correctamente al crear facturas a crédito, así que lo calculamos aquí
    // sumando el balanceDue de todos los créditos activos del cliente.
    final isarPendingAmount = await _calculatePendingAmountFromIsar(customerId);

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCustomerFinancialSummary(
          customerId,
        );
        // Sobrescribir pendingAmount con el valor calculado desde ISAR (más preciso).
        result['pendingAmount'] = isarPendingAmount;
        return Right(result);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getFinancialSummaryOffline(customerId,
            isarPendingAmount: isarPendingAmount);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _getFinancialSummaryOffline(customerId,
            isarPendingAmount: isarPendingAmount);
      } catch (e) {
        return _getFinancialSummaryOffline(customerId,
            isarPendingAmount: isarPendingAmount);
      }
    } else {
      return _getFinancialSummaryOffline(customerId,
          isarPendingAmount: isarPendingAmount);
    }
  }

  /// Suma el balanceDue de todos los créditos activos del cliente desde ISAR.
  /// Este es el valor correcto de "deuda pendiente" del cliente.
  Future<double> _calculatePendingAmountFromIsar(String customerId) async {
    try {
      final credits = await isar.isarCustomerCredits
          .filter()
          .customerIdEqualTo(customerId)
          .findAll();

      final activeCredits = credits.where((c) =>
          c.status == IsarCreditStatus.pending ||
          c.status == IsarCreditStatus.partiallyPaid ||
          c.status == IsarCreditStatus.overdue);

      return activeCredits.fold<double>(0.0, (sum, c) => sum + c.balanceDue);
    } catch (_) {
      return 0.0;
    }
  }

  /// Obtener resumen financiero desde ISAR
  Future<Either<Failure, Map<String, dynamic>>> _getFinancialSummaryOffline(
    String customerId, {
    double? isarPendingAmount,
  }) async {
    try {
      final isarCustomer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .findFirst();

      if (isarCustomer == null) {
        return Left(CacheFailure('Cliente no encontrado: $customerId'));
      }

      // Usar el pendingAmount calculado desde créditos ISAR si está disponible
      final pendingAmount =
          isarPendingAmount ?? await _calculatePendingAmountFromIsar(customerId);
      final availableCredit =
          (isarCustomer.creditLimit - pendingAmount).clamp(0.0, double.infinity);

      return Right({
        'customerId': customerId,
        'currentBalance': pendingAmount,
        'pendingAmount': pendingAmount,
        'creditLimit': isarCustomer.creditLimit,
        'availableCredit': availableCredit,
        'totalPurchases': isarCustomer.totalPurchases,
        'totalOrders': isarCustomer.totalOrders,
        'lastPurchaseAt': isarCustomer.lastPurchaseAt?.toIso8601String(),
        'paymentTerms': isarCustomer.paymentTerms,
        'status': isarCustomer.status.name,
      });
    } catch (e) {
      return Left(CacheFailure('Error obteniendo resumen financiero offline: $e'));
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
  /// FASE 3: Siempre cachear a ISAR (upsert por serverId evita duplicados)
  bool _shouldCacheResult(
    int page,
    String? search,
    CustomerStatus? status,
    DocumentType? documentType,
  ) {
    return true;
  }

  /// Invalidar cache de listados para reflejar cambios
  Future<void> _invalidateListCache() async {
    try {
      await localDataSource.clearCustomerCache();
    } catch (e) {
    }
  }

  /// Obtener clientes desde cache local (ISAR + SecureStorage fallback)
  Future<Either<Failure, PaginatedResult<Customer>>>
  _getCustomersFromCache() async {
    try {
      // Intentar desde ISAR primero (más rápido y soporta filtros)
      final isarCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll() as List<IsarCustomer>;

      if (isarCustomers.isNotEmpty) {
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
      final customers = await localDataSource.getCachedCustomers();

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
      return Left(CacheFailure(e.message));
    } catch (e) {
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

  /// Obtener estadísticas desde cache (SecureStorage primero, luego ISAR)
  Future<Either<Failure, CustomerStats>> _getCustomerStatsFromCache() async {
    // Intentar SecureStorage primero
    try {
      final stats = await localDataSource.getCachedCustomerStats();
      if (stats != null) {
        return Right(stats.toEntity());
      }
    } catch (e) {
    }

    // Fallback: calcular stats desde ISAR
    try {
      final isarCustomers = await isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .findAll();

      if (isarCustomers.isEmpty) {
        return const Right(CustomerStats(
          total: 0, active: 0, inactive: 0, suspended: 0,
          totalCreditLimit: 0, totalBalance: 0, activePercentage: 0,
          customersWithOverdue: 0, averagePurchaseAmount: 0,
        ));
      }

      int active = 0, inactive = 0, suspended = 0;
      double totalCreditLimit = 0, totalBalance = 0, totalPurchases = 0;
      int totalOrders = 0;

      for (final c in isarCustomers) {
        switch (c.status) {
          case IsarCustomerStatus.active:
            active++;
            break;
          case IsarCustomerStatus.inactive:
            inactive++;
            break;
          case IsarCustomerStatus.suspended:
            suspended++;
            break;
        }
        totalCreditLimit += c.creditLimit;
        totalBalance += c.currentBalance;
        totalPurchases += c.totalPurchases;
        totalOrders += c.totalOrders;
      }

      final total = isarCustomers.length;
      final activePercentage = total > 0 ? (active / total) * 100 : 0.0;
      final avgPurchase = totalOrders > 0 ? totalPurchases / totalOrders : 0.0;

      final stats = CustomerStats(
        total: total,
        active: active,
        inactive: inactive,
        suspended: suspended,
        totalCreditLimit: totalCreditLimit,
        totalBalance: totalBalance,
        activePercentage: activePercentage,
        customersWithOverdue: 0, // No se puede determinar offline sin facturas
        averagePurchaseAmount: avgPurchase,
      );

      return Right(stats);
    } catch (e) {
      return const Right(CustomerStats(
        total: 0, active: 0, inactive: 0, suspended: 0,
        totalCreditLimit: 0, totalBalance: 0, activePercentage: 0,
        customersWithOverdue: 0, averagePurchaseAmount: 0,
      ));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar clientes creados offline con el servidor
  Future<Either<Failure, List<Customer>>> syncOfflineCustomers() async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure.noInternet);
    }

    try {

      // Obtener clientes no sincronizados desde ISAR
      final unsyncedCustomers = await isar.isarCustomers
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomer>;

      if (unsyncedCustomers.isEmpty) {
        return const Right([]);
      }

      final syncedCustomers = <Customer>[];

      for (final isarCustomer in unsyncedCustomers) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarCustomer.serverId.startsWith('customer_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real

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
          } else {
            // UPDATE: Enviar actualización al servidor

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
          }
        } catch (e) {
          // Continuar con la siguiente
        }
      }

      return Right(syncedCustomers);
    } catch (e) {
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
