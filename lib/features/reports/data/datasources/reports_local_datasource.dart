// lib/features/reports/data/datasources/reports_local_datasource.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/profitability_report.dart';
import '../../domain/entities/inventory_valuation_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/profitability_report_model.dart';
import '../models/inventory_valuation_report_model.dart';
import '../models/category_profitability_report_model.dart';
import '../models/inventory_valuation_summary_model.dart';
import '../models/category_valuation_summary_model.dart';
import '../models/category_valuation_breakdown_model.dart';
import '../models/inventory_valuation_variance_model.dart';
import '../models/profitability_trend_model.dart';
import '../models/kardex_entry_model.dart';
import '../models/kardex_movement_summary_model.dart';

abstract class ReportsLocalDataSource {
  // Profitability Reports
  Future<Either<Failure, PaginatedResult<ProfitabilityReport>>> getCachedProfitabilityByProducts(
    ProfitabilityReportParams params,
  );
  Future<void> cacheProfitabilityByProducts(
    ProfitabilityReportParams params,
    PaginatedResult<ProfitabilityReport> result,
  );

  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> getCachedProfitabilityByCategories(
    ProfitabilityReportParams params,
  );
  Future<void> cacheProfitabilityByCategories(
    ProfitabilityReportParams params,
    PaginatedResult<CategoryProfitabilityReport> result,
  );

  Future<Either<Failure, List<ProfitabilityReport>>> getCachedTopProfitableProducts(
    TopProfitableProductsParams params,
  );
  Future<void> cacheTopProfitableProducts(
    TopProfitableProductsParams params,
    List<ProfitabilityReport> result,
  );

  Future<Either<Failure, List<ProfitabilityTrend>>> getCachedProfitabilityTrends(
    ProfitabilityTrendsParams params,
  );
  Future<void> cacheProfitabilityTrends(
    ProfitabilityTrendsParams params,
    List<ProfitabilityTrend> result,
  );

  // Inventory Valuation Reports
  Future<Either<Failure, InventoryValuationSummary>> getCachedInventoryValuationSummary(
    InventoryValuationParams params,
  );
  Future<void> cacheInventoryValuationSummary(
    InventoryValuationParams params,
    InventoryValuationSummary result,
  );

  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getCachedInventoryValuationByProducts(
    InventoryValuationParams params,
  );
  Future<void> cacheInventoryValuationByProducts(
    InventoryValuationParams params,
    PaginatedResult<InventoryValuationReport> result,
  );

  Future<Either<Failure, List<CategoryValuationSummary>>> getCachedCategoryValuationSummary(
    InventoryValuationParams params,
  );
  Future<void> cacheCategoryValuationSummary(
    InventoryValuationParams params,
    List<CategoryValuationSummary> result,
  );

  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> getCachedInventoryValuationByCategories(
    InventoryValuationParams params,
  );
  Future<void> cacheInventoryValuationByCategories(
    InventoryValuationParams params,
    PaginatedResult<CategoryValuationBreakdown> result,
  );

  // Kardex Reports
  Future<Either<Failure, List<KardexEntry>>> getCachedMultiProductKardex(
    MultiProductKardexParams params,
  );
  Future<void> cacheMultiProductKardex(
    MultiProductKardexParams params,
    List<KardexEntry> result,
  );

  Future<Either<Failure, KardexMovementSummary>> getCachedKardexMovementsSummary(
    KardexMovementSummaryParams params,
  );
  Future<void> cacheKardexMovementsSummary(
    KardexMovementSummaryParams params,
    KardexMovementSummary result,
  );

  // Valuation Variances
  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> getCachedValuationVariances(
    ValuationVariancesParams params,
  );
  Future<void> cacheValuationVariances(
    ValuationVariancesParams params,
    PaginatedResult<InventoryValuationVariance> result,
  );

  // Cache Management
  Future<void> clearExpiredCache();
  Future<void> clearAllReportsCache();
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  // Cache expiration time (1 hour by default)
  static const Duration _cacheExpiration = Duration(hours: 1);

  // Cache key prefixes
  static const String _prefixProfitabilityProducts = 'report_prof_products_';
  static const String _prefixProfitabilityCategories = 'report_prof_categories_';
  static const String _prefixTopProfitable = 'report_top_profitable_';
  static const String _prefixProfitabilityTrends = 'report_prof_trends_';
  static const String _prefixValuationSummary = 'report_valuation_summary_';
  static const String _prefixValuationProducts = 'report_valuation_products_';
  static const String _prefixCategoryValuation = 'report_category_valuation_';
  static const String _prefixValuationCategories = 'report_valuation_categories_';
  static const String _prefixKardex = 'report_kardex_';
  static const String _prefixKardexSummary = 'report_kardex_summary_';
  static const String _prefixValuationVariances = 'report_valuation_variances_';

  ReportsLocalDataSourceImpl({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ==================== PROFITABILITY REPORTS ====================

  @override
  Future<Either<Failure, PaginatedResult<ProfitabilityReport>>> getCachedProfitabilityByProducts(
    ProfitabilityReportParams params,
  ) async {
    try {
      final key = _generateKey(_prefixProfitabilityProducts, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => ProfitabilityReportModel.fromJson(item).toDomain())
          .toList();
      final meta = PaginationMeta.fromJson(cached['meta']);

      return Right(PaginatedResult(data: items, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheProfitabilityByProducts(
    ProfitabilityReportParams params,
    PaginatedResult<ProfitabilityReport> result,
  ) async {
    final key = _generateKey(_prefixProfitabilityProducts, params);
    final cacheData = {
      'items': result.data
          .map((item) => ProfitabilityReportModel.fromDomain(item).toJson())
          .toList(),
      'meta': result.meta.toJson(),
    };
    await _setCachedData(key, cacheData);
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> getCachedProfitabilityByCategories(
    ProfitabilityReportParams params,
  ) async {
    try {
      final key = _generateKey(_prefixProfitabilityCategories, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => CategoryProfitabilityReportModel.fromJson(item).toDomain())
          .toList();
      final meta = PaginationMeta.fromJson(cached['meta']);

      return Right(PaginatedResult(data: items, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheProfitabilityByCategories(
    ProfitabilityReportParams params,
    PaginatedResult<CategoryProfitabilityReport> result,
  ) async {
    final key = _generateKey(_prefixProfitabilityCategories, params);
    final cacheData = {
      'items': result.data
          .map((item) => CategoryProfitabilityReportModel.fromDomain(item).toJson())
          .toList(),
      'meta': result.meta.toJson(),
    };
    await _setCachedData(key, cacheData);
  }

  @override
  Future<Either<Failure, List<ProfitabilityReport>>> getCachedTopProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    try {
      final key = _generateKey(_prefixTopProfitable, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => ProfitabilityReportModel.fromJson(item).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheTopProfitableProducts(
    TopProfitableProductsParams params,
    List<ProfitabilityReport> result,
  ) async {
    final key = _generateKey(_prefixTopProfitable, params);
    final data = {
      'items': result
          .map((item) => (item as ProfitabilityReportModel).toJson())
          .toList(),
    };
    await _setCachedData(key, data);
  }

  @override
  Future<Either<Failure, List<ProfitabilityTrend>>> getCachedProfitabilityTrends(
    ProfitabilityTrendsParams params,
  ) async {
    try {
      final key = _generateKey(_prefixProfitabilityTrends, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => ProfitabilityTrendModel.fromJson(item).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheProfitabilityTrends(
    ProfitabilityTrendsParams params,
    List<ProfitabilityTrend> result,
  ) async {
    final key = _generateKey(_prefixProfitabilityTrends, params);
    final data = {
      'items': result
          .map((item) => (item as ProfitabilityTrendModel).toJson())
          .toList(),
    };
    await _setCachedData(key, data);
  }

  // ==================== INVENTORY VALUATION REPORTS ====================

  @override
  Future<Either<Failure, InventoryValuationSummary>> getCachedInventoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    try {
      final key = _generateKey(_prefixValuationSummary, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      return Right(InventoryValuationSummaryModel.fromJson(cached['data']).toDomain());
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheInventoryValuationSummary(
    InventoryValuationParams params,
    InventoryValuationSummary result,
  ) async {
    final key = _generateKey(_prefixValuationSummary, params);
    final data = {
      'data': (result as InventoryValuationSummaryModel).toJson(),
    };
    await _setCachedData(key, data);
  }

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getCachedInventoryValuationByProducts(
    InventoryValuationParams params,
  ) async {
    try {
      final key = _generateKey(_prefixValuationProducts, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => InventoryValuationReportModel.fromJson(item).toDomain())
          .toList();
      final meta = PaginationMeta.fromJson(cached['meta']);

      return Right(PaginatedResult(data: items, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheInventoryValuationByProducts(
    InventoryValuationParams params,
    PaginatedResult<InventoryValuationReport> result,
  ) async {
    final key = _generateKey(_prefixValuationProducts, params);
    final data = {
      'items': result.data
          .map((item) => (item as InventoryValuationReportModel).toJson())
          .toList(),
      'meta': result.meta.toJson(),
    };
    await _setCachedData(key, data);
  }

  @override
  Future<Either<Failure, List<CategoryValuationSummary>>> getCachedCategoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    try {
      final key = _generateKey(_prefixCategoryValuation, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => CategoryValuationSummaryModel.fromJson(item).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheCategoryValuationSummary(
    InventoryValuationParams params,
    List<CategoryValuationSummary> result,
  ) async {
    final key = _generateKey(_prefixCategoryValuation, params);
    final data = {
      'items': result
          .map((item) => (item as CategoryValuationSummaryModel).toJson())
          .toList(),
    };
    await _setCachedData(key, data);
  }

  @override
  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> getCachedInventoryValuationByCategories(
    InventoryValuationParams params,
  ) async {
    try {
      final key = _generateKey(_prefixValuationCategories, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => CategoryValuationBreakdownModel.fromJson(item).toDomain())
          .toList();
      final meta = PaginationMeta.fromJson(cached['meta']);

      return Right(PaginatedResult(data: items, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheInventoryValuationByCategories(
    InventoryValuationParams params,
    PaginatedResult<CategoryValuationBreakdown> result,
  ) async {
    final key = _generateKey(_prefixValuationCategories, params);
    final data = {
      'items': result.data
          .map((item) => (item as CategoryValuationBreakdownModel).toJson())
          .toList(),
      'meta': result.meta.toJson(),
    };
    await _setCachedData(key, data);
  }

  // ==================== KARDEX REPORTS ====================

  @override
  Future<Either<Failure, List<KardexEntry>>> getCachedMultiProductKardex(
    MultiProductKardexParams params,
  ) async {
    try {
      final key = _generateKey(_prefixKardex, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      final items = (cached['items'] as List)
          .map((item) => KardexEntryModel.fromJson(item).toDomain())
          .toList();

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheMultiProductKardex(
    MultiProductKardexParams params,
    List<KardexEntry> result,
  ) async {
    final key = _generateKey(_prefixKardex, params);
    final data = {
      'items': result
          .map((item) => (item as KardexEntryModel).toJson())
          .toList(),
    };
    await _setCachedData(key, data);
  }

  @override
  Future<Either<Failure, KardexMovementSummary>> getCachedKardexMovementsSummary(
    KardexMovementSummaryParams params,
  ) async {
    try {
      final key = _generateKey(_prefixKardexSummary, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados'));
      }

      return Right(KardexMovementSummaryModel.fromJson(cached['data']).toDomain());
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheKardexMovementsSummary(
    KardexMovementSummaryParams params,
    KardexMovementSummary result,
  ) async {
    final key = _generateKey(_prefixKardexSummary, params);
    final data = {
      'data': (result as KardexMovementSummaryModel).toJson(),
    };
    await _setCachedData(key, data);
  }

  // ==================== VALUATION VARIANCES ====================

  @override
  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> getCachedValuationVariances(
    ValuationVariancesParams params,
  ) async {
    try {
      final key = _generateKey(_prefixValuationVariances, params);
      final cached = await _getCachedData(key);

      if (cached == null) {
        return Left(CacheFailure('No hay datos cacheados de varianzas de valuación'));
      }

      final items = (cached['items'] as List)
          .map((item) => InventoryValuationVarianceModel.fromJson(item).toDomain())
          .toList();
      final meta = PaginationMeta.fromJson(cached['meta']);

      return Right(PaginatedResult(data: items, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error leyendo cache de varianzas: ${e.toString()}'));
    }
  }

  @override
  Future<void> cacheValuationVariances(
    ValuationVariancesParams params,
    PaginatedResult<InventoryValuationVariance> result,
  ) async {
    final key = _generateKey(_prefixValuationVariances, params);
    final data = {
      'items': result.data
          .map((item) => InventoryValuationVarianceModel(
                productId: item.productId,
                productName: item.productName,
                productSku: item.productSku,
                categoryId: item.categoryId ?? '',
                categoryName: item.categoryName ?? '',
                warehouseId: '',
                warehouseName: '',
                bookValue: item.bookValue,
                marketValue: item.marketValue,
                varianceAmount: item.variance,
                variancePercentage: item.variancePercentage,
                varianceType: item.varianceType,
                currentQuantity: 0,
                unitBookValue: item.bookValue,
                unitMarketValue: item.marketValue,
                lastCostUpdate: item.analysisDate,
                lastPriceUpdate: item.analysisDate,
                asOfDate: item.analysisDate,
                notes: item.reason,
              ).toJson())
          .toList(),
      'meta': result.meta.toJson(),
    };
    await _setCachedData(key, data);
  }

  // ==================== CACHE MANAGEMENT ====================

  @override
  Future<void> clearExpiredCache() async {
    try {
      final allKeys = await _getAllCacheKeys();

      for (final key in allKeys) {
        if (key.startsWith('report_')) {
          final data = await _secureStorage.read(key: key);
          if (data != null) {
            try {
              final decoded = jsonDecode(data);
              final cachedAt = DateTime.parse(decoded['cachedAt']);
              if (DateTime.now().difference(cachedAt) > _cacheExpiration) {
                await _secureStorage.delete(key: key);
              }
            } catch (_) {
              // Si hay error parsing, eliminar entrada corrupta
              await _secureStorage.delete(key: key);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - no es crítico
    }
  }

  @override
  Future<void> clearAllReportsCache() async {
    try {
      final allKeys = await _getAllCacheKeys();

      for (final key in allKeys) {
        if (key.startsWith('report_')) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  // ==================== PRIVATE HELPERS ====================

  String _generateKey(String prefix, dynamic params) {
    // Crear hash único basado en los parámetros
    final paramsJson = jsonEncode(_paramsToMap(params));
    final hash = md5.convert(utf8.encode(paramsJson)).toString();
    return '$prefix$hash';
  }

  Map<String, dynamic> _paramsToMap(dynamic params) {
    if (params is ProfitabilityReportParams) {
      return {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'categoryId': params.categoryId,
        'productId': params.productId,
        'page': params.page,
        'limit': params.limit,
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };
    } else if (params is TopProfitableProductsParams) {
      return {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'categoryId': params.categoryId,
        'limit': params.limit,
        'leastProfitable': params.leastProfitable,
      };
    } else if (params is ProfitabilityTrendsParams) {
      return {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'categoryId': params.categoryId,
        'productId': params.productId,
        'period': params.period,
      };
    } else if (params is InventoryValuationParams) {
      return {
        'asOfDate': params.asOfDate?.toIso8601String(),
        'warehouseId': params.warehouseId,
        'categoryId': params.categoryId,
      };
    } else if (params is MultiProductKardexParams) {
      return {
        'productIds': params.productIds,
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'warehouseId': params.warehouseId,
      };
    } else if (params is KardexMovementSummaryParams) {
      return {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'categoryId': params.categoryId,
        'warehouseId': params.warehouseId,
        'movementType': params.movementType,
      };
    } else if (params is ValuationVariancesParams) {
      return {
        'asOfDate': params.asOfDate?.toIso8601String(),
        'warehouseId': params.warehouseId,
        'categoryId': params.categoryId,
        'minVariancePercentage': params.minVariancePercentage,
        'varianceType': params.varianceType,
        'page': params.page,
        'limit': params.limit,
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };
    }
    return {};
  }

  Future<Map<String, dynamic>?> _getCachedData(String key) async {
    try {
      final data = await _secureStorage.read(key: key);
      if (data == null) return null;

      final decoded = jsonDecode(data);
      final cachedAt = DateTime.parse(decoded['cachedAt']);

      // Verificar si ha expirado
      if (DateTime.now().difference(cachedAt) > _cacheExpiration) {
        await _secureStorage.delete(key: key);
        return null;
      }

      return decoded['payload'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> _setCachedData(String key, Map<String, dynamic> data) async {
    try {
      final wrapper = {
        'cachedAt': DateTime.now().toIso8601String(),
        'payload': data,
      };
      await _secureStorage.write(key: key, value: jsonEncode(wrapper));
    } catch (e) {
      // Silently fail - caching es best-effort
    }
  }

  Future<List<String>> _getAllCacheKeys() async {
    try {
      final all = await _secureStorage.readAll();
      return all.keys.toList();
    } catch (e) {
      return [];
    }
  }
}
