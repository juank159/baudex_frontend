// lib/features/customers/data/repositories/customer_repository_impl.dart
import 'package:baudex_desktop/features/customers/data/models/customer_query_model.dart';
import 'package:baudex_desktop/features/customers/data/models/update_customer_request_model.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_stats.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../datasources/customer_local_datasource.dart';

import '../models/create_customer_request_model.dart';

/// Implementación del repositorio de clientes
class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
    if (await networkInfo.isConnected) {
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

        // Cache solo resultados de la primera página sin filtros específicos
        if (_shouldCacheResult(page, search, status, documentType)) {
          try {
            await localDataSource.cacheCustomers(response.data);
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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al obtener clientes: $e'));
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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al crear cliente: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al actualizar cliente: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
    // Esta operación normalmente se haría desde el backend automáticamente
    // al crear/actualizar facturas, pero la implementamos por completitud
    return const Left(ServerFailure('Operación no implementada'));
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomer(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCustomer(id);

        try {
          await localDataSource.removeCachedCustomer(id);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de eliminar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al eliminar cliente: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al verificar capacidad de compra: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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

  /// Obtener clientes desde cache local
  Future<Either<Failure, PaginatedResult<Customer>>>
  _getCustomersFromCache() async {
    try {
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
