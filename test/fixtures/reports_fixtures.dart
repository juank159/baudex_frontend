// test/fixtures/reports_fixtures.dart
import 'package:baudex_desktop/features/reports/domain/entities/profitability_report.dart';
import 'package:baudex_desktop/features/reports/domain/entities/inventory_valuation_report.dart';
import 'package:baudex_desktop/features/reports/domain/repositories/reports_repository.dart';

/// Test fixtures for Reports module
class ReportsFixtures {
  // ============================================================================
  // PROFITABILITY REPORT ENTITY FIXTURES
  // ============================================================================

  /// Creates a single profitability report entity
  static ProfitabilityReport createProfitabilityReportEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String? categoryId = 'cat-001',
    String? categoryName = 'Test Category',
    String? warehouseId,
    String? warehouseName,
    int quantitySold = 50,
    double totalRevenue = 500000.0,
    double totalCost = 300000.0,
    double grossProfit = 200000.0,
    double profitMargin = 0.40,
    double profitPercentage = 40.0,
    double averageSellingPrice = 10000.0,
    double averageCostPrice = 6000.0,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<ProfitabilityTrend>? trends,
  }) {
    return ProfitabilityReport(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      quantitySold: quantitySold,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      profitPercentage: profitPercentage,
      averageSellingPrice: averageSellingPrice,
      averageCostPrice: averageCostPrice,
      periodStart: periodStart ?? DateTime(2024, 1, 1),
      periodEnd: periodEnd ?? DateTime(2024, 1, 31),
      trends: trends ?? [],
    );
  }

  /// Creates a list of profitability report entities
  static List<ProfitabilityReport> createProfitabilityReportList(int count) {
    return List.generate(count, (index) {
      return createProfitabilityReportEntity(
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        quantitySold: 50 - (index * 2),
        totalRevenue: 500000.0 - (index * 10000),
        totalCost: 300000.0 - (index * 5000),
        grossProfit: 200000.0 - (index * 5000),
      );
    });
  }

  /// Creates a profitability trend entity
  static ProfitabilityTrend createProfitabilityTrendEntity({
    DateTime? date,
    double revenue = 100000.0,
    double cost = 60000.0,
    double profit = 40000.0,
    double margin = 0.40,
    int quantity = 10,
  }) {
    return ProfitabilityTrend(
      date: date ?? DateTime(2024, 1, 1),
      revenue: revenue,
      cost: cost,
      profit: profit,
      margin: margin,
      quantity: quantity,
    );
  }

  /// Creates a list of profitability trends
  static List<ProfitabilityTrend> createProfitabilityTrendList(int count) {
    return List.generate(count, (index) {
      return createProfitabilityTrendEntity(
        date: DateTime(2024, 1, index + 1),
        revenue: 100000.0 + (index * 5000),
        cost: 60000.0 + (index * 3000),
        profit: 40000.0 + (index * 2000),
        quantity: 10 + index,
      );
    });
  }

  /// Creates a category profitability report entity
  static CategoryProfitabilityReport createCategoryProfitabilityReportEntity({
    String categoryId = 'cat-001',
    String categoryName = 'Test Category',
    int totalProducts = 10,
    int quantitySold = 100,
    double totalRevenue = 1000000.0,
    double totalCost = 600000.0,
    double grossProfit = 400000.0,
    double profitMargin = 0.40,
    double profitPercentage = 40.0,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<ProfitabilityReport>? topProducts,
  }) {
    return CategoryProfitabilityReport(
      categoryId: categoryId,
      categoryName: categoryName,
      totalProducts: totalProducts,
      quantitySold: quantitySold,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      profitPercentage: profitPercentage,
      periodStart: periodStart ?? DateTime(2024, 1, 1),
      periodEnd: periodEnd ?? DateTime(2024, 1, 31),
      topProducts: topProducts ?? [],
    );
  }

  /// Creates a list of category profitability reports
  static List<CategoryProfitabilityReport> createCategoryProfitabilityReportList(int count) {
    return List.generate(count, (index) {
      return createCategoryProfitabilityReportEntity(
        categoryId: 'cat-${(index + 1).toString().padLeft(3, '0')}',
        categoryName: 'Category ${index + 1}',
        totalProducts: 10 - index,
        quantitySold: 100 - (index * 5),
      );
    });
  }

  // ============================================================================
  // INVENTORY VALUATION REPORT ENTITY FIXTURES
  // ============================================================================

  /// Creates an inventory valuation report entity
  static InventoryValuationReport createInventoryValuationReportEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String? categoryId = 'cat-001',
    String? categoryName = 'Test Category',
    int currentStock = 100,
    double averageCost = 5000.0,
    double fifoValue = 500000.0,
    double lifoValue = 480000.0,
    double weightedAverageValue = 490000.0,
    double currentMarketValue = 510000.0,
    double totalValue = 500000.0,
    DateTime? valuationDate,
    List<InventoryValuationBatch>? batchDetails,
  }) {
    return InventoryValuationReport(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      currentStock: currentStock,
      averageCost: averageCost,
      fifoValue: fifoValue,
      lifoValue: lifoValue,
      weightedAverageValue: weightedAverageValue,
      currentMarketValue: currentMarketValue,
      totalValue: totalValue,
      valuationDate: valuationDate ?? DateTime(2024, 1, 31),
      batchDetails: batchDetails ?? [],
    );
  }

  /// Creates a list of inventory valuation reports
  static List<InventoryValuationReport> createInventoryValuationReportList(int count) {
    return List.generate(count, (index) {
      final stock = 100 - (index * 5);
      final avgCost = 5000.0 + (index * 100);
      return createInventoryValuationReportEntity(
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        currentStock: stock,
        averageCost: avgCost,
        totalValue: stock * avgCost,
      );
    });
  }

  /// Creates an inventory valuation batch entity
  static InventoryValuationBatch createInventoryValuationBatchEntity({
    String batchId = 'batch-001',
    String batchNumber = 'BATCH-001',
    int quantity = 50,
    double unitCost = 5000.0,
    double totalCost = 250000.0,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? supplierId,
    String? supplierName,
  }) {
    return InventoryValuationBatch(
      batchId: batchId,
      batchNumber: batchNumber,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      purchaseDate: purchaseDate ?? DateTime(2024, 1, 1),
      expiryDate: expiryDate,
      supplierId: supplierId,
      supplierName: supplierName,
    );
  }

  /// Creates a list of inventory valuation batches
  static List<InventoryValuationBatch> createInventoryValuationBatchList(int count) {
    return List.generate(count, (index) {
      final quantity = 50 - (index * 5);
      final unitCost = 5000.0 + (index * 100);
      return createInventoryValuationBatchEntity(
        batchId: 'batch-${(index + 1).toString().padLeft(3, '0')}',
        batchNumber: 'BATCH-${(index + 1).toString().padLeft(3, '0')}',
        quantity: quantity,
        unitCost: unitCost,
        totalCost: quantity * unitCost,
        purchaseDate: DateTime(2024, 1, index + 1),
      );
    });
  }

  /// Creates an inventory valuation summary entity
  static InventoryValuationSummary createInventoryValuationSummaryEntity({
    double totalInventoryValue = 5000000.0,
    double totalFifoValue = 5000000.0,
    double totalLifoValue = 4800000.0,
    double totalWeightedAverageValue = 4900000.0,
    double totalMarketValue = 5100000.0,
    int totalProducts = 100,
    int totalCategories = 10,
    int totalQuantity = 1000,
    double averageCostPerUnit = 5000.0,
    double averageStockDays = 30.0,
    DateTime? valuationDate,
    String valuationMethod = 'FIFO',
    List<CategoryValuationSummary>? categorySummaries,
    List<WarehouseValuationBreakdown>? warehouseBreakdown,
    List<TopValuedProduct>? topValuedProducts,
  }) {
    return InventoryValuationSummary(
      totalInventoryValue: totalInventoryValue,
      totalFifoValue: totalFifoValue,
      totalLifoValue: totalLifoValue,
      totalWeightedAverageValue: totalWeightedAverageValue,
      totalMarketValue: totalMarketValue,
      totalProducts: totalProducts,
      totalCategories: totalCategories,
      totalQuantity: totalQuantity,
      averageCostPerUnit: averageCostPerUnit,
      averageStockDays: averageStockDays,
      valuationDate: valuationDate ?? DateTime(2024, 1, 31),
      valuationMethod: valuationMethod,
      categorySummaries: categorySummaries ?? [],
      warehouseBreakdown: warehouseBreakdown ?? [],
      topValuedProducts: topValuedProducts ?? [],
    );
  }

  /// Creates a category valuation summary entity
  static CategoryValuationSummary createCategoryValuationSummaryEntity({
    String categoryId = 'cat-001',
    String categoryName = 'Test Category',
    double totalValue = 500000.0,
    double fifoValue = 500000.0,
    double lifoValue = 480000.0,
    double weightedAverageValue = 490000.0,
    double marketValue = 510000.0,
    int productCount = 10,
    double averageStockDays = 30.0,
  }) {
    return CategoryValuationSummary(
      categoryId: categoryId,
      categoryName: categoryName,
      totalValue: totalValue,
      fifoValue: fifoValue,
      lifoValue: lifoValue,
      weightedAverageValue: weightedAverageValue,
      marketValue: marketValue,
      productCount: productCount,
      averageStockDays: averageStockDays,
    );
  }

  /// Creates a list of category valuation summaries
  static List<CategoryValuationSummary> createCategoryValuationSummaryList(int count) {
    return List.generate(count, (index) {
      return createCategoryValuationSummaryEntity(
        categoryId: 'cat-${(index + 1).toString().padLeft(3, '0')}',
        categoryName: 'Category ${index + 1}',
        totalValue: 500000.0 - (index * 10000),
        productCount: 10 - index,
      );
    });
  }

  /// Creates a category valuation breakdown entity
  static CategoryValuationBreakdown createCategoryValuationBreakdownEntity({
    String categoryId = 'cat-001',
    String categoryName = 'Test Category',
    int productCount = 10,
    int totalQuantity = 100,
    double totalValue = 500000.0,
    double averageUnitCost = 5000.0,
    double fifoValue = 500000.0,
    double lifoValue = 480000.0,
    double weightedAverageValue = 490000.0,
    double marketValue = 510000.0,
    double valuationVariance = -10000.0,
    double valuationVariancePercentage = -1.96,
    double percentageOfTotalValue = 10.0,
    List<TopValuedProduct>? topProducts,
  }) {
    return CategoryValuationBreakdown(
      categoryId: categoryId,
      categoryName: categoryName,
      productCount: productCount,
      totalQuantity: totalQuantity,
      totalValue: totalValue,
      averageUnitCost: averageUnitCost,
      fifoValue: fifoValue,
      lifoValue: lifoValue,
      weightedAverageValue: weightedAverageValue,
      marketValue: marketValue,
      valuationVariance: valuationVariance,
      valuationVariancePercentage: valuationVariancePercentage,
      percentageOfTotalValue: percentageOfTotalValue,
      topProducts: topProducts ?? [],
    );
  }

  /// Creates a list of category valuation breakdowns
  static List<CategoryValuationBreakdown> createCategoryValuationBreakdownList(int count) {
    return List.generate(count, (index) {
      return createCategoryValuationBreakdownEntity(
        categoryId: 'cat-${(index + 1).toString().padLeft(3, '0')}',
        categoryName: 'Category ${index + 1}',
        totalValue: 500000.0 - (index * 10000),
        percentageOfTotalValue: 10.0 - index,
      );
    });
  }

  /// Creates a top valued product entity
  static TopValuedProduct createTopValuedProductEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String? categoryId = 'cat-001',
    String? categoryName = 'Test Category',
    int quantity = 100,
    double unitCost = 5000.0,
    double totalValue = 500000.0,
    double percentageOfCategoryValue = 20.0,
    double percentageOfTotalValue = 10.0,
    int ranking = 1,
  }) {
    return TopValuedProduct(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      quantity: quantity,
      unitCost: unitCost,
      totalValue: totalValue,
      percentageOfCategoryValue: percentageOfCategoryValue,
      percentageOfTotalValue: percentageOfTotalValue,
      ranking: ranking,
    );
  }

  /// Creates a list of top valued products
  static List<TopValuedProduct> createTopValuedProductList(int count) {
    return List.generate(count, (index) {
      return createTopValuedProductEntity(
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        totalValue: 500000.0 - (index * 10000),
        ranking: index + 1,
      );
    });
  }

  /// Creates an inventory valuation variance entity
  static InventoryValuationVariance createInventoryValuationVarianceEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String? categoryId = 'cat-001',
    String? categoryName = 'Test Category',
    double bookValue = 500000.0,
    double marketValue = 510000.0,
    double variance = -10000.0,
    double variancePercentage = -1.96,
    String varianceType = 'undervalued',
    String reason = 'Market price increased',
    DateTime? analysisDate,
    double recommendedAdjustment = 10000.0,
  }) {
    return InventoryValuationVariance(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryId: categoryId,
      categoryName: categoryName,
      bookValue: bookValue,
      marketValue: marketValue,
      variance: variance,
      variancePercentage: variancePercentage,
      varianceType: varianceType,
      reason: reason,
      analysisDate: analysisDate ?? DateTime(2024, 1, 31),
      recommendedAdjustment: recommendedAdjustment,
    );
  }

  /// Creates a list of inventory valuation variances
  static List<InventoryValuationVariance> createInventoryValuationVarianceList(int count) {
    return List.generate(count, (index) {
      final isOvervalued = index % 2 == 0;
      return createInventoryValuationVarianceEntity(
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        varianceType: isOvervalued ? 'overvalued' : 'undervalued',
        variance: isOvervalued ? 10000.0 + (index * 1000) : -10000.0 - (index * 1000),
      );
    });
  }

  /// Creates a kardex entry entity
  static KardexEntry createKardexEntryEntity({
    String id = 'kardex-001',
    String productId = 'prod-001',
    String productName = 'Test Product',
    DateTime? date,
    String movementType = 'purchase',
    int quantity = 10,
    double unitCost = 5000.0,
    double totalCost = 50000.0,
    int balance = 100,
    String? referenceId,
    String? notes,
  }) {
    return KardexEntry(
      id: id,
      productId: productId,
      productName: productName,
      date: date ?? DateTime(2024, 1, 1),
      movementType: movementType,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      balance: balance,
      referenceId: referenceId,
      notes: notes,
    );
  }

  /// Creates a list of kardex entries
  static List<KardexEntry> createKardexEntryList(int count) {
    return List.generate(count, (index) {
      return createKardexEntryEntity(
        id: 'kardex-${(index + 1).toString().padLeft(3, '0')}',
        date: DateTime(2024, 1, index + 1),
        movementType: index % 2 == 0 ? 'purchase' : 'sale',
        quantity: 10 + index,
        balance: 100 + (index * 5),
      );
    });
  }

  /// Creates a kardex movement summary entity
  static KardexMovementSummary createKardexMovementSummaryEntity({
    DateTime? startDate,
    DateTime? endDate,
    int totalMovements = 50,
    double totalInboundValue = 1000000.0,
    double totalOutboundValue = 800000.0,
    double netValue = 200000.0,
    Map<String, int>? movementsByType,
    Map<String, double>? valuesByType,
    List<DailyMovementSummary>? dailySummaries,
  }) {
    return KardexMovementSummary(
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      totalMovements: totalMovements,
      totalInboundValue: totalInboundValue,
      totalOutboundValue: totalOutboundValue,
      netValue: netValue,
      movementsByType: movementsByType ?? {'purchase': 30, 'sale': 20},
      valuesByType: valuesByType ?? {'purchase': 1000000.0, 'sale': 800000.0},
      dailySummaries: dailySummaries ?? [],
    );
  }

  /// Creates a daily movement summary entity
  static DailyMovementSummary createDailyMovementSummaryEntity({
    DateTime? date,
    int movementCount = 5,
    double inboundValue = 50000.0,
    double outboundValue = 30000.0,
    double netValue = 20000.0,
  }) {
    return DailyMovementSummary(
      date: date ?? DateTime(2024, 1, 1),
      movementCount: movementCount,
      inboundValue: inboundValue,
      outboundValue: outboundValue,
      netValue: netValue,
    );
  }

  // ============================================================================
  // PARAMETER CLASSES
  // ============================================================================

  static ProfitabilityReportParams createProfitabilityReportParams({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? productId,
    int page = 1,
    int limit = 20,
    String sortBy = 'grossProfit',
    String sortOrder = 'desc',
  }) {
    return ProfitabilityReportParams(
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      categoryId: categoryId,
      productId: productId,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  static TopProfitableProductsParams createTopProfitableProductsParams({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int limit = 10,
    bool leastProfitable = false,
  }) {
    return TopProfitableProductsParams(
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      categoryId: categoryId,
      limit: limit,
      leastProfitable: leastProfitable,
    );
  }

  static ProductProfitabilityTrendParams createProductProfitabilityTrendParams({
    String productId = 'prod-001',
    DateTime? startDate,
    DateTime? endDate,
    String period = 'monthly',
  }) {
    return ProductProfitabilityTrendParams(
      productId: productId,
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      period: period,
    );
  }

  static ProfitabilityTrendsParams createProfitabilityTrendsParams({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? productId,
    String period = 'monthly',
  }) {
    return ProfitabilityTrendsParams(
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      categoryId: categoryId,
      productId: productId,
      period: period,
    );
  }

  static InventoryValuationParams createInventoryValuationParams({
    DateTime? asOfDate,
    String? warehouseId,
    String? categoryId,
  }) {
    return InventoryValuationParams(
      asOfDate: asOfDate,
      warehouseId: warehouseId,
      categoryId: categoryId,
    );
  }

  static ProductValuationParams createProductValuationParams({
    DateTime? asOfDate,
    String? warehouseId,
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'totalValue',
    String sortOrder = 'desc',
  }) {
    return ProductValuationParams(
      asOfDate: asOfDate,
      warehouseId: warehouseId,
      categoryId: categoryId,
      search: search,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  static ValuationVariancesParams createValuationVariancesParams({
    DateTime? asOfDate,
    String? warehouseId,
    String? categoryId,
    double? minVariancePercentage,
    String? varianceType,
    int page = 1,
    int limit = 20,
    String sortBy = 'variancePercentage',
    String sortOrder = 'desc',
  }) {
    return ValuationVariancesParams(
      asOfDate: asOfDate,
      warehouseId: warehouseId,
      categoryId: categoryId,
      minVariancePercentage: minVariancePercentage,
      varianceType: varianceType,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  static MultiProductKardexParams createMultiProductKardexParams({
    List<String>? productIds,
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
  }) {
    return MultiProductKardexParams(
      productIds: productIds ?? ['prod-001', 'prod-002'],
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      warehouseId: warehouseId,
    );
  }

  static KardexMovementSummaryParams createKardexMovementSummaryParams({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? warehouseId,
    String? movementType,
  }) {
    return KardexMovementSummaryParams(
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      categoryId: categoryId,
      warehouseId: warehouseId,
      movementType: movementType,
    );
  }
}
