// lib/features/suppliers/data/repositories/supplier_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_remote_datasource.dart';
import '../datasources/supplier_local_datasource.dart';
import '../models/create_supplier_request_model.dart';
import '../models/update_supplier_request_model.dart';

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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final localResult = await localDataSource.getSuppliers(params);
        
        // Convertir models a entities
        final suppliers = localResult.data.map((model) => model.toEntity()).toList();
        
        return Right(PaginatedResult<Supplier>(
          data: suppliers,
          meta: localResult.meta,
        ));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error en cache local: $e'));
      }
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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final supplierModel = await localDataSource.getSupplierById(id);
        
        if (supplierModel != null) {
          return Right(supplierModel.toEntity());
        } else {
          return Left(CacheFailure('Proveedor no encontrado en cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error en cache local: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String searchTerm, {
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModels = await remoteDataSource.searchSuppliers(
          searchTerm,
          limit: limit,
        );
        
        // Cachear los resultados
        for (final supplier in supplierModels) {
          await localDataSource.cacheSupplier(supplier);
        }
        
        final suppliers = supplierModels.map((model) => model.toEntity()).toList();
        return Right(suppliers);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final supplierModels = await localDataSource.searchSuppliers(
          searchTerm,
          limit: limit,
        );
        
        final suppliers = supplierModels.map((model) => model.toEntity()).toList();
        return Right(suppliers);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error en cache local: $e'));
      }
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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final supplierModels = await localDataSource.getActiveSuppliers();
        final suppliers = supplierModels.map((model) => model.toEntity()).toList();
        return Right(suppliers);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error en cache local: $e'));
      }
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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final statsModel = await localDataSource.getCachedSupplierStats();
        
        if (statsModel != null) {
          return Right(statsModel.toEntity());
        } else {
          return Left(CacheFailure('Estadísticas no disponibles en cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error en cache local: $e'));
      }
    }
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para crear proveedor'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para actualizar proveedor'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para actualizar estado'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSupplier(id);
        
        // Remover del cache
        await localDataSource.removeCachedSupplier(id);
        
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para eliminar proveedor'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> restoreSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final supplierModel = await remoteDataSource.restoreSupplier(id);
        
        // Actualizar cache
        await localDataSource.cacheSupplier(supplierModel);
        
        return Right(supplierModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para restaurar proveedor'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para validar documento'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para validar código'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para validar email'));
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
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No hay conexión a internet para validar documento'));
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
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error en cache local: $e'));
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
}