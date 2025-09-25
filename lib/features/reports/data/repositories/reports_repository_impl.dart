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

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ReportsRepositoryImpl({
    required this.remoteDataSource,
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
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> getProfitabilityByCategories(
    ProfitabilityReportParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getProfitabilityByCategories(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> getTopProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getTopProfitableProducts(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> getLeastProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getLeastProfitableProducts(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> getProductProfitabilityTrend(
    ProductProfitabilityTrendParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final trends = await remoteDataSource.getProductProfitabilityTrend(params);
        return Right(trends);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> getProfitabilityTrends(
    ProfitabilityTrendsParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final trends = await remoteDataSource.getProfitabilityTrends(params);
        return Right(trends);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
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
        return Right(summary);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getProductValuationDetails(
    ProductValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getProductValuationDetails(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryValuationSummary>>> getCategoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summaries = await remoteDataSource.getCategoryValuationSummary(params);
        return Right(summaries);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getInventoryValuationByProducts(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getInventoryValuationByProducts(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> getInventoryValuationByCategories(
    InventoryValuationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final reports = await remoteDataSource.getInventoryValuationByCategories(params);
        return Right(reports);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> getValuationVariances(
    ValuationVariancesParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final variances = await remoteDataSource.getValuationVariances(params);
        return Right(variances);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
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
        return Right(entries);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, KardexMovementSummary>> getKardexMovementsSummary(
    KardexMovementSummaryParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDataSource.getKardexMovementsSummary(params);
        return Right(summary);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ConnectionException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }
}