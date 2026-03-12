// lib/features/reports/data/repositories/reports_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/inventory_valuation_report.dart';
import '../../domain/entities/profitability_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';
import '../datasources/reports_local_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;
  final ReportsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ReportsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ==================== PROFITABILITY REPORTS ====================

  @override
  Future<Either<Failure, PaginatedResult<ProfitabilityReport>>> getProfitabilityByProducts(
    ProfitabilityReportParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getProfitabilityByProducts(params);
        // Cache resultado
        await localDataSource.cacheProfitabilityByProducts(params, reports);
        return Right(reports);
      } on ServerException catch (e) {
        // Intentar cache en caso de error de servidor
        final cachedResult = await localDataSource.getCachedProfitabilityByProducts(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      // Modo offline - usar cache
      return localDataSource.getCachedProfitabilityByProducts(params);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> getProfitabilityByCategories(
    ProfitabilityReportParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getProfitabilityByCategories(params);
        await localDataSource.cacheProfitabilityByCategories(params, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedProfitabilityByCategories(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedProfitabilityByCategories(params);
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> getTopProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getTopProfitableProducts(params);
        await localDataSource.cacheTopProfitableProducts(params, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedTopProfitableProducts(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedTopProfitableProducts(params);
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> getLeastProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    // Reutilizar el mismo cache con flag leastProfitable
    final cacheParams = TopProfitableProductsParams(
      startDate: params.startDate,
      endDate: params.endDate,
      categoryId: params.categoryId,
      limit: params.limit,
      leastProfitable: true,
    );

    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getLeastProfitableProducts(params);
        await localDataSource.cacheTopProfitableProducts(cacheParams, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedTopProfitableProducts(cacheParams);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedTopProfitableProducts(cacheParams);
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> getProductProfitabilityTrend(
    ProductProfitabilityTrendParams params,
  ) async {
    // Convertir a ProfitabilityTrendsParams para caching
    final cacheParams = ProfitabilityTrendsParams(
      startDate: params.startDate,
      endDate: params.endDate,
      productId: params.productId,
      period: params.period,
    );

    if (await networkInfo.isConnected) {
      try {
        final trends = await remoteDataSource.getProductProfitabilityTrend(params);
        await localDataSource.cacheProfitabilityTrends(cacheParams, trends);
        return Right(trends);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedProfitabilityTrends(cacheParams);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedProfitabilityTrends(cacheParams);
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> getProfitabilityTrends(
    ProfitabilityTrendsParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final trends = await remoteDataSource.getProfitabilityTrends(params);
        await localDataSource.cacheProfitabilityTrends(params, trends);
        return Right(trends);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedProfitabilityTrends(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedProfitabilityTrends(params);
    }
  }

  // ==================== INVENTORY VALUATION REPORTS ====================

  @override
  Future<Either<Failure, InventoryValuationSummary>> getInventoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDataSource.getInventoryValuationSummary(params);
        await localDataSource.cacheInventoryValuationSummary(params, summary);
        return Right(summary);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedInventoryValuationSummary(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedInventoryValuationSummary(params);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getProductValuationDetails(
    ProductValuationParams params,
  ) async {
    // Convertir a InventoryValuationParams para caching
    final cacheParams = InventoryValuationParams(
      asOfDate: params.asOfDate,
      warehouseId: params.warehouseId,
      categoryId: params.categoryId,
    );

    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getProductValuationDetails(params);
        await localDataSource.cacheInventoryValuationByProducts(cacheParams, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedInventoryValuationByProducts(cacheParams);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedInventoryValuationByProducts(cacheParams);
    }
  }

  @override
  Future<Either<Failure, List<CategoryValuationSummary>>> getCategoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summaries = await remoteDataSource.getCategoryValuationSummary(params);
        await localDataSource.cacheCategoryValuationSummary(params, summaries);
        return Right(summaries);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedCategoryValuationSummary(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedCategoryValuationSummary(params);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getInventoryValuationByProducts(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getInventoryValuationByProducts(params);
        await localDataSource.cacheInventoryValuationByProducts(params, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedInventoryValuationByProducts(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedInventoryValuationByProducts(params);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> getInventoryValuationByCategories(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getInventoryValuationByCategories(params);
        await localDataSource.cacheInventoryValuationByCategories(params, reports);
        return Right(reports);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedInventoryValuationByCategories(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedInventoryValuationByCategories(params);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> getValuationVariances(
    ValuationVariancesParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final variances = await remoteDataSource.getValuationVariances(params);
        // Cache resultado para uso offline
        await localDataSource.cacheValuationVariances(params, variances);
        return Right(variances);
      } on ServerException catch (e) {
        // Intentar cache en caso de error de servidor
        final cachedResult = await localDataSource.getCachedValuationVariances(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        // Intentar cache en caso de error de conexión
        final cachedResult = await localDataSource.getCachedValuationVariances(params);
        return cachedResult.fold(
          (failure) => Left(NetworkFailure(e.message)),
          (cached) => Right(cached),
        );
      } catch (e) {
        // Intentar cache en caso de cualquier otro error
        final cachedResult = await localDataSource.getCachedValuationVariances(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure('Error inesperado: ${e.toString()}')),
          (cached) => Right(cached),
        );
      }
    } else {
      // Modo offline - usar cache
      return localDataSource.getCachedValuationVariances(params);
    }
  }

  // ==================== ADVANCED KARDEX REPORTS ====================

  @override
  Future<Either<Failure, List<KardexEntry>>> getMultiProductKardex(
    MultiProductKardexParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final entries = await remoteDataSource.getMultiProductKardex(params);
        await localDataSource.cacheMultiProductKardex(params, entries);
        return Right(entries);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedMultiProductKardex(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedMultiProductKardex(params);
    }
  }

  @override
  Future<Either<Failure, KardexMovementSummary>> getKardexMovementsSummary(
    KardexMovementSummaryParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDataSource.getKardexMovementsSummary(params);
        await localDataSource.cacheKardexMovementsSummary(params, summary);
        return Right(summary);
      } on ServerException catch (e) {
        final cachedResult = await localDataSource.getCachedKardexMovementsSummary(params);
        return cachedResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (cached) => Right(cached),
        );
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return localDataSource.getCachedKardexMovementsSummary(params);
    }
  }

  /// Limpiar cache expirado de reportes
  Future<void> clearExpiredCache() async {
    await localDataSource.clearExpiredCache();
  }

  /// Limpiar todo el cache de reportes
  Future<void> clearAllCache() async {
    await localDataSource.clearAllReportsCache();
  }
}
