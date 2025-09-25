// lib/features/reports/data/datasources/reports_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/inventory_valuation_report.dart';
import '../../domain/entities/profitability_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/inventory_valuation_report_model.dart';
import '../models/profitability_report_model.dart';
import '../models/category_profitability_report_model.dart';
import '../models/profitability_trend_model.dart';
import '../models/inventory_valuation_summary_model.dart';
import '../models/category_valuation_summary_model.dart';
import '../models/category_valuation_breakdown_model.dart';
import '../models/inventory_valuation_variance_model.dart';
import '../models/kardex_entry_model.dart';
import '../models/kardex_movement_summary_model.dart';

abstract class ReportsRemoteDataSource {
  // Profitability Reports
  Future<PaginatedResult<ProfitabilityReport>> getProfitabilityByProducts(ProfitabilityReportParams params);
  Future<PaginatedResult<CategoryProfitabilityReport>> getProfitabilityByCategories(ProfitabilityReportParams params);
  Future<List<ProfitabilityReport>> getTopProfitableProducts(TopProfitableProductsParams params);
  Future<List<ProfitabilityReport>> getLeastProfitableProducts(TopProfitableProductsParams params);
  Future<List<ProfitabilityTrend>> getProductProfitabilityTrend(ProductProfitabilityTrendParams params);
  Future<List<ProfitabilityTrend>> getProfitabilityTrends(ProfitabilityTrendsParams params);
  
  // Valuation Reports
  Future<InventoryValuationSummary> getInventoryValuationSummary(InventoryValuationParams params);
  Future<PaginatedResult<InventoryValuationReport>> getProductValuationDetails(ProductValuationParams params);
  Future<List<CategoryValuationSummary>> getCategoryValuationSummary(InventoryValuationParams params);
  Future<PaginatedResult<InventoryValuationReport>> getInventoryValuationByProducts(InventoryValuationParams params);
  Future<PaginatedResult<CategoryValuationBreakdown>> getInventoryValuationByCategories(InventoryValuationParams params);
  Future<PaginatedResult<InventoryValuationVariance>> getValuationVariances(ValuationVariancesParams params);
  
  // Kardex Reports
  Future<List<KardexEntry>> getMultiProductKardex(MultiProductKardexParams params);
  Future<KardexMovementSummary> getKardexMovementsSummary(KardexMovementSummaryParams params);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final Dio dio;

  ReportsRemoteDataSourceImpl({required this.dio});

  @override
  Future<PaginatedResult<ProfitabilityReport>> getProfitabilityByProducts(
    ProfitabilityReportParams params,
  ) async {
    try {
      final queryParams = {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        if (params.categoryId != null) 'categoryId': params.categoryId,
        if (params.productId != null) 'productId': params.productId,
        'page': params.page.toString(),
        'limit': params.limit.toString(),
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/profitability/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final reports = items.map((json) => ProfitabilityReportModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: reports, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PaginatedResult<CategoryProfitabilityReport>> getProfitabilityByCategories(
    ProfitabilityReportParams params,
  ) async {
    try {
      final queryParams = {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        if (params.categoryId != null) 'categoryId': params.categoryId,
        'page': params.page.toString(),
        'limit': params.limit.toString(),
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/profitability/categories',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final reports = items.map((json) => CategoryProfitabilityReportModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: reports, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<ProfitabilityReport>> getTopProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    try {
      final queryParams = {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        if (params.categoryId != null) 'categoryId': params.categoryId,
        'limit': params.limit.toString(),
        'leastProfitable': params.leastProfitable.toString(),
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/profitability/top-products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ProfitabilityReportModel.fromJson(json).toDomain()).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<ProfitabilityReport>> getLeastProfitableProducts(
    TopProfitableProductsParams params,
  ) async {
    try {
      final modifiedParams = TopProfitableProductsParams(
        startDate: params.startDate,
        endDate: params.endDate,
        categoryId: params.categoryId,
        limit: params.limit,
        leastProfitable: true,
      );
      
      return await getTopProfitableProducts(modifiedParams);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<ProfitabilityTrend>> getProductProfitabilityTrend(
    ProductProfitabilityTrendParams params,
  ) async {
    try {
      final queryParams = {
        'productId': params.productId,
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'period': params.period,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/profitability/product-trend',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ProfitabilityTrendModel.fromJson(json).toDomain()).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<InventoryValuationSummary> getInventoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/summary',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return InventoryValuationSummaryModel.fromJson(response.data).toDomain();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PaginatedResult<InventoryValuationReport>> getProductValuationDetails(
    ProductValuationParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
        if (params.search != null) 'search': params.search,
        'page': params.page.toString(),
        'limit': params.limit.toString(),
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/product-details',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final reports = items.map((json) => InventoryValuationReportModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: reports, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<CategoryValuationSummary>> getCategoryValuationSummary(
    InventoryValuationParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/category-summary',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CategoryValuationSummaryModel.fromJson(json).toDomain()).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PaginatedResult<InventoryValuationReport>> getInventoryValuationByProducts(
    InventoryValuationParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final reports = items.map((json) => InventoryValuationReportModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: reports, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PaginatedResult<CategoryValuationBreakdown>> getInventoryValuationByCategories(
    InventoryValuationParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/categories',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final reports = items.map((json) => CategoryValuationBreakdownModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: reports, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<ProfitabilityTrend>> getProfitabilityTrends(
    ProfitabilityTrendsParams params,
  ) async {
    try {
      final queryParams = {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'period': params.period,
        if (params.productId != null) 'productId': params.productId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/profitability/trends',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ProfitabilityTrendModel.fromJson(json).toDomain()).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PaginatedResult<InventoryValuationVariance>> getValuationVariances(
    ValuationVariancesParams params,
  ) async {
    try {
      final queryParams = {
        if (params.asOfDate != null) 'asOfDate': params.asOfDate!.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.categoryId != null) 'categoryId': params.categoryId,
        if (params.minVariancePercentage != null) 'minVariancePercentage': params.minVariancePercentage.toString(),
        if (params.varianceType != null) 'varianceType': params.varianceType,
        'page': params.page.toString(),
        'limit': params.limit.toString(),
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/valuation/variances',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data['data'] ?? [];
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        
        final variances = items.map((json) => InventoryValuationVarianceModel.fromJson(json).toDomain()).toList();
        return PaginatedResult(data: variances, meta: meta);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<KardexEntry>> getMultiProductKardex(
    MultiProductKardexParams params,
  ) async {
    try {
      final queryParams = {
        'productIds': params.productIds.join(','),
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/kardex/multi-product',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => KardexEntryModel.fromJson(json).toDomain()).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<KardexMovementSummary> getKardexMovementsSummary(
    KardexMovementSummaryParams params,
  ) async {
    try {
      final queryParams = {
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        if (params.categoryId != null) 'categoryId': params.categoryId,
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
        if (params.movementType != null) 'movementType': params.movementType,
      };

      final response = await dio.get(
        '${ApiConstants.baseUrl}/reports/kardex/movements-summary',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return KardexMovementSummaryModel.fromJson(response.data).toDomain();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConnectionException.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConnectionException.socketException;
      } else {
        throw ServerException('Error del servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }
}