// lib/features/reports/domain/entities/inventory_valuation_report.dart
import 'package:equatable/equatable.dart';

class InventoryValuationReport extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final int currentStock;
  final double averageCost;
  final double fifoValue;
  final double lifoValue;
  final double weightedAverageValue;
  final double currentMarketValue;
  final double totalValue;
  final DateTime valuationDate;
  final List<InventoryValuationBatch> batchDetails;

  const InventoryValuationReport({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    required this.currentStock,
    required this.averageCost,
    required this.fifoValue,
    required this.lifoValue,
    required this.weightedAverageValue,
    required this.currentMarketValue,
    required this.totalValue,
    required this.valuationDate,
    this.batchDetails = const [],
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        categoryId,
        categoryName,
        currentStock,
        averageCost,
        fifoValue,
        lifoValue,
        weightedAverageValue,
        currentMarketValue,
        totalValue,
        valuationDate,
        batchDetails,
      ];

  // Computed properties
  bool get hasStock => currentStock > 0;
  double get costPerUnit => currentStock > 0 ? totalValue / currentStock : 0.0;
  
  double get valuationVariance => totalValue - currentMarketValue;
  double get valuationVariancePercentage => 
      currentMarketValue > 0 ? (valuationVariance / currentMarketValue) * 100 : 0.0;

  bool get isOvervalued => valuationVariance > 0;
  bool get isUndervalued => valuationVariance < 0;
  
  // Aliases for compatibility
  int get currentQuantity => currentStock;
  double get unitCost => averageCost;
  String? get warehouseName => null;
  String get valuationMethod => 'FIFO';
  DateTime get asOfDate => valuationDate;
  DateTime? get lastPurchaseDate => null;
  double? get lastPurchaseCost => null;
  List<ValuationBatchDetail>? get batches => batchDetails.cast<ValuationBatchDetail>();

  String get valuationStatus {
    if (isOvervalued) return 'Sobrevaluado';
    if (isUndervalued) return 'Subvaluado';
    return 'Valuación correcta';
  }

  InventoryValuationReport copyWith({
    String? productId,
    String? productName,
    String? productSku,
    String? categoryId,
    String? categoryName,
    int? currentStock,
    double? averageCost,
    double? fifoValue,
    double? lifoValue,
    double? weightedAverageValue,
    double? currentMarketValue,
    double? totalValue,
    DateTime? valuationDate,
    List<InventoryValuationBatch>? batchDetails,
  }) {
    return InventoryValuationReport(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      currentStock: currentStock ?? this.currentStock,
      averageCost: averageCost ?? this.averageCost,
      fifoValue: fifoValue ?? this.fifoValue,
      lifoValue: lifoValue ?? this.lifoValue,
      weightedAverageValue: weightedAverageValue ?? this.weightedAverageValue,
      currentMarketValue: currentMarketValue ?? this.currentMarketValue,
      totalValue: totalValue ?? this.totalValue,
      valuationDate: valuationDate ?? this.valuationDate,
      batchDetails: batchDetails ?? this.batchDetails,
    );
  }
}

class InventoryValuationBatch extends Equatable {
  final String batchId;
  final String batchNumber;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String? supplierId;
  final String? supplierName;

  const InventoryValuationBatch({
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.purchaseDate,
    this.expiryDate,
    this.supplierId,
    this.supplierName,
  });

  @override
  List<Object?> get props => [
        batchId,
        batchNumber,
        quantity,
        unitCost,
        totalCost,
        purchaseDate,
        expiryDate,
        supplierId,
        supplierName,
      ];

  bool get hasExpiry => expiryDate != null;
  bool get isExpired => hasExpiry && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry => hasExpiry && 
      expiryDate!.difference(DateTime.now()).inDays <= 30;

  int get daysInStock => DateTime.now().difference(purchaseDate).inDays;

  InventoryValuationBatch copyWith({
    String? batchId,
    String? batchNumber,
    int? quantity,
    double? unitCost,
    double? totalCost,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? supplierId,
    String? supplierName,
  }) {
    return InventoryValuationBatch(
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
    );
  }
}

class InventoryValuationSummary extends Equatable {
  final double totalInventoryValue;
  final double totalFifoValue;
  final double totalLifoValue;
  final double totalWeightedAverageValue;
  final double totalMarketValue;
  final int totalProducts;
  final int totalCategories;
  final int totalQuantity;
  final double averageCostPerUnit;
  final double averageStockDays;
  final DateTime valuationDate;
  final String valuationMethod;
  final List<CategoryValuationSummary> categorySummaries;
  final List<WarehouseValuationBreakdown> warehouseBreakdown;
  final List<TopValuedProduct> topValuedProducts;

  const InventoryValuationSummary({
    required this.totalInventoryValue,
    required this.totalFifoValue,
    required this.totalLifoValue,
    required this.totalWeightedAverageValue,
    required this.totalMarketValue,
    required this.totalProducts,
    required this.totalCategories,
    required this.totalQuantity,
    required this.averageCostPerUnit,
    required this.averageStockDays,
    required this.valuationDate,
    required this.valuationMethod,
    this.categorySummaries = const [],
    this.warehouseBreakdown = const [],
    this.topValuedProducts = const [],
  });

  @override
  List<Object?> get props => [
        totalInventoryValue,
        totalFifoValue,
        totalLifoValue,
        totalWeightedAverageValue,
        totalMarketValue,
        totalProducts,
        totalCategories,
        totalQuantity,
        averageCostPerUnit,
        averageStockDays,
        valuationDate,
        valuationMethod,
        categorySummaries,
        warehouseBreakdown,
        topValuedProducts,
      ];

  double get valuationVariance => totalInventoryValue - totalMarketValue;
  double get valuationVariancePercentage => 
      totalMarketValue > 0 ? (valuationVariance / totalMarketValue) * 100 : 0.0;

  bool get isOvervalued => valuationVariance > 0;
  bool get isUndervalued => valuationVariance < 0;

  // Compatibility aliases for widgets
  List<CategoryValuationBreakdown>? get categoryBreakdown => 
      categorySummaries.map((summary) => CategoryValuationBreakdown(
        categoryId: summary.categoryId,
        categoryName: summary.categoryName,
        productCount: summary.productCount,
        totalQuantity: 0, // Not available in summary
        totalValue: summary.totalValue,
        averageUnitCost: 0, // Not available in summary
        fifoValue: summary.fifoValue,
        lifoValue: summary.lifoValue,
        weightedAverageValue: summary.weightedAverageValue,
        marketValue: summary.marketValue,
        valuationVariance: summary.valuationVariance,
        valuationVariancePercentage: summary.valuationVariancePercentage,
        percentageOfTotalValue: totalInventoryValue > 0 ? (summary.totalValue / totalInventoryValue) * 100 : 0,
      )).toList();

  InventoryValuationSummary copyWith({
    double? totalInventoryValue,
    double? totalFifoValue,
    double? totalLifoValue,
    double? totalWeightedAverageValue,
    double? totalMarketValue,
    int? totalProducts,
    int? totalCategories,
    int? totalQuantity,
    double? averageCostPerUnit,
    double? averageStockDays,
    DateTime? valuationDate,
    String? valuationMethod,
    List<CategoryValuationSummary>? categorySummaries,
    List<WarehouseValuationBreakdown>? warehouseBreakdown,
    List<TopValuedProduct>? topValuedProducts,
  }) {
    return InventoryValuationSummary(
      totalInventoryValue: totalInventoryValue ?? this.totalInventoryValue,
      totalFifoValue: totalFifoValue ?? this.totalFifoValue,
      totalLifoValue: totalLifoValue ?? this.totalLifoValue,
      totalWeightedAverageValue: totalWeightedAverageValue ?? this.totalWeightedAverageValue,
      totalMarketValue: totalMarketValue ?? this.totalMarketValue,
      totalProducts: totalProducts ?? this.totalProducts,
      totalCategories: totalCategories ?? this.totalCategories,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      averageCostPerUnit: averageCostPerUnit ?? this.averageCostPerUnit,
      averageStockDays: averageStockDays ?? this.averageStockDays,
      valuationDate: valuationDate ?? this.valuationDate,
      valuationMethod: valuationMethod ?? this.valuationMethod,
      categorySummaries: categorySummaries ?? this.categorySummaries,
      warehouseBreakdown: warehouseBreakdown ?? this.warehouseBreakdown,
      topValuedProducts: topValuedProducts ?? this.topValuedProducts,
    );
  }
}

class ValuationBatchDetail extends Equatable {
  final String batchId;
  final String batchNumber;
  final String productId;
  final String productName;
  final String productSku;
  final int quantity;
  final double unitCost;
  final double totalValue;
  final DateTime purchaseDate;
  final DateTime? expirationDate;
  final String? supplierId;
  final String? supplierName;
  final String? warehouseId;
  final String? warehouseName;
  final int daysInStock;
  final bool isExpired;
  final bool isNearExpiry;

  const ValuationBatchDetail({
    required this.batchId,
    required this.batchNumber,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.purchaseDate,
    this.expirationDate,
    this.supplierId,
    this.supplierName,
    this.warehouseId,
    this.warehouseName,
    required this.daysInStock,
    required this.isExpired,
    required this.isNearExpiry,
  });

  @override
  List<Object?> get props => [
        batchId,
        batchNumber,
        productId,
        productName,
        productSku,
        quantity,
        unitCost,
        totalValue,
        purchaseDate,
        expirationDate,
        supplierId,
        supplierName,
        warehouseId,
        warehouseName,
        daysInStock,
        isExpired,
        isNearExpiry,
      ];

  ValuationBatchDetail copyWith({
    String? batchId,
    String? batchNumber,
    String? productId,
    String? productName,
    String? productSku,
    int? quantity,
    double? unitCost,
    double? totalValue,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? supplierId,
    String? supplierName,
    String? warehouseId,
    String? warehouseName,
    int? daysInStock,
    bool? isExpired,
    bool? isNearExpiry,
  }) {
    return ValuationBatchDetail(
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalValue: totalValue ?? this.totalValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      daysInStock: daysInStock ?? this.daysInStock,
      isExpired: isExpired ?? this.isExpired,
      isNearExpiry: isNearExpiry ?? this.isNearExpiry,
    );
  }
}

class CategoryValuationBreakdown extends Equatable {
  final String categoryId;
  final String categoryName;
  final int productCount;
  final int totalQuantity;
  final double totalValue;
  final double averageUnitCost;
  final double fifoValue;
  final double lifoValue;
  final double weightedAverageValue;
  final double marketValue;
  final double valuationVariance;
  final double valuationVariancePercentage;
  final double percentageOfTotalValue;
  final List<TopValuedProduct> topProducts;

  const CategoryValuationBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.productCount,
    required this.totalQuantity,
    required this.totalValue,
    required this.averageUnitCost,
    required this.fifoValue,
    required this.lifoValue,
    required this.weightedAverageValue,
    required this.marketValue,
    required this.valuationVariance,
    required this.valuationVariancePercentage,
    required this.percentageOfTotalValue,
    this.topProducts = const [],
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        productCount,
        totalQuantity,
        totalValue,
        averageUnitCost,
        fifoValue,
        lifoValue,
        weightedAverageValue,
        marketValue,
        valuationVariance,
        valuationVariancePercentage,
        percentageOfTotalValue,
        topProducts,
      ];

  bool get isOvervalued => valuationVariance > 0;
  bool get isUndervalued => valuationVariance < 0;
  
  // Aliases for compatibility
  int get currentQuantity => totalQuantity;
  double get averageCost => averageUnitCost;

  CategoryValuationBreakdown copyWith({
    String? categoryId,
    String? categoryName,
    int? productCount,
    int? totalQuantity,
    double? totalValue,
    double? averageUnitCost,
    double? fifoValue,
    double? lifoValue,
    double? weightedAverageValue,
    double? marketValue,
    double? valuationVariance,
    double? valuationVariancePercentage,
    double? percentageOfTotalValue,
    List<TopValuedProduct>? topProducts,
  }) {
    return CategoryValuationBreakdown(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      productCount: productCount ?? this.productCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalValue: totalValue ?? this.totalValue,
      averageUnitCost: averageUnitCost ?? this.averageUnitCost,
      fifoValue: fifoValue ?? this.fifoValue,
      lifoValue: lifoValue ?? this.lifoValue,
      weightedAverageValue: weightedAverageValue ?? this.weightedAverageValue,
      marketValue: marketValue ?? this.marketValue,
      valuationVariance: valuationVariance ?? this.valuationVariance,
      valuationVariancePercentage: valuationVariancePercentage ?? this.valuationVariancePercentage,
      percentageOfTotalValue: percentageOfTotalValue ?? this.percentageOfTotalValue,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}

class WarehouseValuationBreakdown extends Equatable {
  final String warehouseId;
  final String warehouseName;
  final int productCount;
  final int totalQuantity;
  final double totalValue;
  final double averageUnitCost;
  final double fifoValue;
  final double lifoValue;
  final double weightedAverageValue;
  final double marketValue;
  final double valuationVariance;
  final double valuationVariancePercentage;
  final double percentageOfTotalValue;
  final List<TopValuedProduct> topProducts;

  const WarehouseValuationBreakdown({
    required this.warehouseId,
    required this.warehouseName,
    required this.productCount,
    required this.totalQuantity,
    required this.totalValue,
    required this.averageUnitCost,
    required this.fifoValue,
    required this.lifoValue,
    required this.weightedAverageValue,
    required this.marketValue,
    required this.valuationVariance,
    required this.valuationVariancePercentage,
    required this.percentageOfTotalValue,
    this.topProducts = const [],
  });

  @override
  List<Object?> get props => [
        warehouseId,
        warehouseName,
        productCount,
        totalQuantity,
        totalValue,
        averageUnitCost,
        fifoValue,
        lifoValue,
        weightedAverageValue,
        marketValue,
        valuationVariance,
        valuationVariancePercentage,
        percentageOfTotalValue,
        topProducts,
      ];

  bool get isOvervalued => valuationVariance > 0;
  bool get isUndervalued => valuationVariance < 0;

  WarehouseValuationBreakdown copyWith({
    String? warehouseId,
    String? warehouseName,
    int? productCount,
    int? totalQuantity,
    double? totalValue,
    double? averageUnitCost,
    double? fifoValue,
    double? lifoValue,
    double? weightedAverageValue,
    double? marketValue,
    double? valuationVariance,
    double? valuationVariancePercentage,
    double? percentageOfTotalValue,
    List<TopValuedProduct>? topProducts,
  }) {
    return WarehouseValuationBreakdown(
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      productCount: productCount ?? this.productCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalValue: totalValue ?? this.totalValue,
      averageUnitCost: averageUnitCost ?? this.averageUnitCost,
      fifoValue: fifoValue ?? this.fifoValue,
      lifoValue: lifoValue ?? this.lifoValue,
      weightedAverageValue: weightedAverageValue ?? this.weightedAverageValue,
      marketValue: marketValue ?? this.marketValue,
      valuationVariance: valuationVariance ?? this.valuationVariance,
      valuationVariancePercentage: valuationVariancePercentage ?? this.valuationVariancePercentage,
      percentageOfTotalValue: percentageOfTotalValue ?? this.percentageOfTotalValue,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}

class TopValuedProduct extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final int quantity;
  final double unitCost;
  final double totalValue;
  final double percentageOfCategoryValue;
  final double percentageOfTotalValue;
  final int ranking;

  const TopValuedProduct({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.percentageOfCategoryValue,
    required this.percentageOfTotalValue,
    required this.ranking,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        categoryId,
        categoryName,
        quantity,
        unitCost,
        totalValue,
        percentageOfCategoryValue,
        percentageOfTotalValue,
        ranking,
      ];

  TopValuedProduct copyWith({
    String? productId,
    String? productName,
    String? productSku,
    String? categoryId,
    String? categoryName,
    int? quantity,
    double? unitCost,
    double? totalValue,
    double? percentageOfCategoryValue,
    double? percentageOfTotalValue,
    int? ranking,
  }) {
    return TopValuedProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalValue: totalValue ?? this.totalValue,
      percentageOfCategoryValue: percentageOfCategoryValue ?? this.percentageOfCategoryValue,
      percentageOfTotalValue: percentageOfTotalValue ?? this.percentageOfTotalValue,
      ranking: ranking ?? this.ranking,
    );
  }
}

class InventoryValuationVariance extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final double bookValue;
  final double marketValue;
  final double variance;
  final double variancePercentage;
  final String varianceType; // 'overvalued', 'undervalued', 'fair'
  final String reason;
  final DateTime analysisDate;
  final double recommendedAdjustment;

  const InventoryValuationVariance({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    required this.bookValue,
    required this.marketValue,
    required this.variance,
    required this.variancePercentage,
    required this.varianceType,
    required this.reason,
    required this.analysisDate,
    required this.recommendedAdjustment,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        categoryId,
        categoryName,
        bookValue,
        marketValue,
        variance,
        variancePercentage,
        varianceType,
        reason,
        analysisDate,
        recommendedAdjustment,
      ];

  bool get isOvervalued => varianceType == 'overvalued';
  bool get isUndervalued => varianceType == 'undervalued';
  bool get isFairValue => varianceType == 'fair';
  bool get requiresAdjustment => recommendedAdjustment.abs() > 0;

  InventoryValuationVariance copyWith({
    String? productId,
    String? productName,
    String? productSku,
    String? categoryId,
    String? categoryName,
    double? bookValue,
    double? marketValue,
    double? variance,
    double? variancePercentage,
    String? varianceType,
    String? reason,
    DateTime? analysisDate,
    double? recommendedAdjustment,
  }) {
    return InventoryValuationVariance(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      bookValue: bookValue ?? this.bookValue,
      marketValue: marketValue ?? this.marketValue,
      variance: variance ?? this.variance,
      variancePercentage: variancePercentage ?? this.variancePercentage,
      varianceType: varianceType ?? this.varianceType,
      reason: reason ?? this.reason,
      analysisDate: analysisDate ?? this.analysisDate,
      recommendedAdjustment: recommendedAdjustment ?? this.recommendedAdjustment,
    );
  }
}

class CategoryValuationSummary extends Equatable {
  final String categoryId;
  final String categoryName;
  final double totalValue;
  final double fifoValue;
  final double lifoValue;
  final double weightedAverageValue;
  final double marketValue;
  final int productCount;
  final double averageStockDays;

  const CategoryValuationSummary({
    required this.categoryId,
    required this.categoryName,
    required this.totalValue,
    required this.fifoValue,
    required this.lifoValue,
    required this.weightedAverageValue,
    required this.marketValue,
    required this.productCount,
    required this.averageStockDays,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        totalValue,
        fifoValue,
        lifoValue,
        weightedAverageValue,
        marketValue,
        productCount,
        averageStockDays,
      ];

  double get valuationVariance => totalValue - marketValue;
  double get valuationVariancePercentage => 
      marketValue > 0 ? (valuationVariance / marketValue) * 100 : 0.0;
  
  // For compatibility with widgets expecting this property
  double get percentageOfTotalValue => 0.0; // Should be calculated by parent

  CategoryValuationSummary copyWith({
    String? categoryId,
    String? categoryName,
    double? totalValue,
    double? fifoValue,
    double? lifoValue,
    double? weightedAverageValue,
    double? marketValue,
    int? productCount,
    double? averageStockDays,
  }) {
    return CategoryValuationSummary(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      totalValue: totalValue ?? this.totalValue,
      fifoValue: fifoValue ?? this.fifoValue,
      lifoValue: lifoValue ?? this.lifoValue,
      weightedAverageValue: weightedAverageValue ?? this.weightedAverageValue,
      marketValue: marketValue ?? this.marketValue,
      productCount: productCount ?? this.productCount,
      averageStockDays: averageStockDays ?? this.averageStockDays,
    );
  }
}