// lib/features/purchase_orders/data/repositories/purchase_order_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../datasources/purchase_order_local_datasource.dart';
import '../datasources/purchase_order_remote_datasource.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  final PurchaseOrderRemoteDataSource remoteDataSource;
  final PurchaseOrderLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const PurchaseOrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPurchaseOrders(params);
        
        // Cache solo la primera página para evitar problemas de sincronización
        if (params.page == 1) {
          try {
            await localDataSource.cachePurchaseOrders(remotePurchaseOrders.data);
          } catch (e) {
            print('Error al guardar en cache: $e');
            // No bloquear la aplicación por errores de cache
          }
        }
        
        return Right(
          PaginatedResult<PurchaseOrder>(
            data: remotePurchaseOrders.data.map((model) => model.toEntity()).toList(),
            meta: remotePurchaseOrders.meta,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.filterCachedPurchaseOrders(params);
        
        // Simular paginación offline
        final startIndex = (params.page - 1) * params.limit;
        final endIndex = startIndex + params.limit;
        final paginatedData = cachedPurchaseOrders.skip(startIndex).take(params.limit).toList();
        
        return Right(
          PaginatedResult<PurchaseOrder>(
            data: paginatedData.map((model) => model.toEntity()).toList(),
            meta: null, // Sin metadatos en modo offline
          ),
        );
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> getPurchaseOrderById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrder = await remoteDataSource.getPurchaseOrderById(id);
        
        // Actualizar cache con la orden obtenida
        try {
          await localDataSource.cachePurchaseOrder(remotePurchaseOrder);
        } catch (e) {
          print('Error al guardar en cache: $e');
          // No bloquear la aplicación por errores de cache
        }
        
        return Right(remotePurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrder = await localDataSource.getCachedPurchaseOrderById(id);
        
        if (cachedPurchaseOrder != null) {
          return Right(cachedPurchaseOrder.toEntity());
        } else {
          return Left(CacheFailure('Orden de compra no encontrada en cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.searchPurchaseOrders(params);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.searchCachedPurchaseOrders(
          params.searchTerm,
        );
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al buscar en cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderStats>> getPurchaseOrderStats() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStats = await remoteDataSource.getPurchaseOrderStats();
        
        // Guardar estadísticas en cache
        await localDataSource.cacheStats(remoteStats);
        
        return Right(remoteStats.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedStats = await localDataSource.getCachedStats();
        
        if (cachedStats != null) {
          return Right(cachedStats.toEntity());
        } else {
          return Left(CacheFailure('Estadísticas no disponibles offline'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder a estadísticas en cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final createdPurchaseOrder = await remoteDataSource.createPurchaseOrder(params);
        
        // Intentar agregar al cache (no bloquear si falla)
        try {
          await localDataSource.cachePurchaseOrder(createdPurchaseOrder);
        } catch (e) {
          print('Error al guardar orden de compra en cache: $e');
          // No bloquear la aplicación por errores de cache
        }
        
        return Right(createdPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede crear orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedPurchaseOrder = await remoteDataSource.updatePurchaseOrder(params);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(updatedPurchaseOrder);
        
        return Right(updatedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede actualizar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseOrder(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePurchaseOrder(id);
        
        // Eliminar del cache
        await localDataSource.removeCachedPurchaseOrder(id);
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede eliminar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final approvedPurchaseOrder = await remoteDataSource.approvePurchaseOrder(id, approvalNotes);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(approvedPurchaseOrder);
        
        return Right(approvedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede aprobar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final rejectedPurchaseOrder = await remoteDataSource.rejectPurchaseOrder(id, rejectionReason);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(rejectedPurchaseOrder);
        
        return Right(rejectedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede rechazar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> sendPurchaseOrder(
    String id,
    String? sendNotes,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final sentPurchaseOrder = await remoteDataSource.sendPurchaseOrder(id, sendNotes);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(sentPurchaseOrder);
        
        return Right(sentPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede enviar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final receivedPurchaseOrder = await remoteDataSource.receivePurchaseOrder(params);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(receivedPurchaseOrder);
        
        return Right(receivedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede recibir orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final cancelledPurchaseOrder = await remoteDataSource.cancelPurchaseOrder(id, cancellationReason);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(cancelledPurchaseOrder);
        
        return Right(cancelledPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede cancelar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrdersBySupplier(String supplierId) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPurchaseOrdersBySupplier(supplierId);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getPurchaseOrdersBySupplier(supplierId);
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getOverduePurchaseOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getOverduePurchaseOrders();
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getOverduePurchaseOrders();
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPendingApprovalPurchaseOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPendingApprovalPurchaseOrders();
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getPendingApprovalPurchaseOrders();
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getRecentPurchaseOrders(int limit) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getRecentPurchaseOrders(limit);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getRecentPurchaseOrders();
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  // TODO: Implementar métodos de reportes cuando estén disponibles en el backend
  @override
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseOrderSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByStatus() async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersStatsbySupplier() async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByMonth(int year) async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }
}