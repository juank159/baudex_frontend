// lib/features/reports/domain/repositories/reports_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/profitability_report.dart';
import '../entities/inventory_valuation_report.dart';

abstract class ReportsRepository {
  // ==================== PROFITABILITY REPORTS ====================
  
  Future<Either<Failure, PaginatedResult<ProfitabilityReport>>> getProfitabilityByProducts(
    ProfitabilityReportParams params,
  );

  Future<Either<Failure, PaginatedResult<CategoryProfitabilityReport>>> getProfitabilityByCategories(
    ProfitabilityReportParams params,
  );

  Future<Either<Failure, List<ProfitabilityReport>>> getTopProfitableProducts(
    TopProfitableProductsParams params,
  );

  Future<Either<Failure, List<ProfitabilityReport>>> getLeastProfitableProducts(
    TopProfitableProductsParams params,
  );

  Future<Either<Failure, List<ProfitabilityTrend>>> getProductProfitabilityTrend(
    ProductProfitabilityTrendParams params,
  );

  Future<Either<Failure, List<ProfitabilityTrend>>> getProfitabilityTrends(
    ProfitabilityTrendsParams params,
  );

  // ==================== INVENTORY VALUATION REPORTS ====================
  
  Future<Either<Failure, InventoryValuationSummary>> getInventoryValuationSummary(
    InventoryValuationParams params,
  );

  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getProductValuationDetails(
    ProductValuationParams params,
  );

  Future<Either<Failure, List<CategoryValuationSummary>>> getCategoryValuationSummary(
    InventoryValuationParams params,
  );

  Future<Either<Failure, PaginatedResult<InventoryValuationReport>>> getInventoryValuationByProducts(
    InventoryValuationParams params,
  );

  Future<Either<Failure, PaginatedResult<CategoryValuationBreakdown>>> getInventoryValuationByCategories(
    InventoryValuationParams params,
  );

  Future<Either<Failure, PaginatedResult<InventoryValuationVariance>>> getValuationVariances(
    ValuationVariancesParams params,
  );

  // ==================== ADVANCED KARDEX REPORTS ====================
  
  Future<Either<Failure, List<KardexEntry>>> getMultiProductKardex(
    MultiProductKardexParams params,
  );

  Future<Either<Failure, KardexMovementSummary>> getKardexMovementsSummary(
    KardexMovementSummaryParams params,
  );
}

// ==================== PARAMETER CLASSES ====================

class ProfitabilityReportParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final String? productId;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const ProfitabilityReportParams({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.productId,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'grossProfit',
    this.sortOrder = 'desc',
  });
}

class TopProfitableProductsParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final int limit;
  final bool leastProfitable;

  const TopProfitableProductsParams({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.limit = 10,
    this.leastProfitable = false,
  });
}

class ProductProfitabilityTrendParams {
  final String productId;
  final DateTime startDate;
  final DateTime endDate;
  final String period; // daily, weekly, monthly

  const ProductProfitabilityTrendParams({
    required this.productId,
    required this.startDate,
    required this.endDate,
    this.period = 'monthly',
  });
}

class InventoryValuationParams {
  final DateTime? asOfDate;
  final String? warehouseId;
  final String? categoryId;

  const InventoryValuationParams({
    this.asOfDate,
    this.warehouseId,
    this.categoryId,
  });
}

class ProductValuationParams {
  final DateTime? asOfDate;
  final String? warehouseId;
  final String? categoryId;
  final String? search;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const ProductValuationParams({
    this.asOfDate,
    this.warehouseId,
    this.categoryId,
    this.search,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'totalValue',
    this.sortOrder = 'desc',
  });
}

class MultiProductKardexParams {
  final List<String> productIds;
  final DateTime startDate;
  final DateTime endDate;
  final String? warehouseId;

  const MultiProductKardexParams({
    required this.productIds,
    required this.startDate,
    required this.endDate,
    this.warehouseId,
  });
}

class KardexMovementSummaryParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final String? warehouseId;
  final String? movementType;

  const KardexMovementSummaryParams({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.warehouseId,
    this.movementType,
  });
}

// Helper entities for kardex reports
class KardexEntry {
  final String id;
  final String productId;
  final String productName;
  final DateTime date;
  final String movementType;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final int balance;
  final String? referenceId;
  final String? notes;

  const KardexEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.date,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.balance,
    this.referenceId,
    this.notes,
  });
}

class KardexMovementSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMovements;
  final double totalInboundValue;
  final double totalOutboundValue;
  final double netValue;
  final Map<String, int> movementsByType;
  final Map<String, double> valuesByType;
  final List<DailyMovementSummary> dailySummaries;

  const KardexMovementSummary({
    required this.startDate,
    required this.endDate,
    required this.totalMovements,
    required this.totalInboundValue,
    required this.totalOutboundValue,
    required this.netValue,
    required this.movementsByType,
    required this.valuesByType,
    required this.dailySummaries,
  });
}

class DailyMovementSummary {
  final DateTime date;
  final int movementCount;
  final double inboundValue;
  final double outboundValue;
  final double netValue;

  const DailyMovementSummary({
    required this.date,
    required this.movementCount,
    required this.inboundValue,
    required this.outboundValue,
    required this.netValue,
  });
}

class ProfitabilityTrendsParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final String? productId;
  final String period; // daily, weekly, monthly

  const ProfitabilityTrendsParams({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.productId,
    this.period = 'monthly',
  });
}

class ValuationVariancesParams {
  final DateTime? asOfDate;
  final String? warehouseId;
  final String? categoryId;
  final double? minVariancePercentage;
  final String? varianceType; // 'overvalued', 'undervalued', 'all'
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const ValuationVariancesParams({
    this.asOfDate,
    this.warehouseId,
    this.categoryId,
    this.minVariancePercentage,
    this.varianceType,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'variancePercentage',
    this.sortOrder = 'desc',
  });
}