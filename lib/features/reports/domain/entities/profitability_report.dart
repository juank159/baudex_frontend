// lib/features/reports/domain/entities/profitability_report.dart
import 'package:equatable/equatable.dart';

class ProfitabilityReport extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final String? categoryId;
  final String? categoryName;
  final String? warehouseId;
  final String? warehouseName;
  final int quantitySold;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final double profitPercentage;
  final double averageSellingPrice;
  final double averageCostPrice;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ProfitabilityTrend> trends;

  const ProfitabilityReport({
    required this.productId,
    required this.productName,
    required this.productSku,
    this.categoryId,
    this.categoryName,
    this.warehouseId,
    this.warehouseName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.profitPercentage,
    required this.averageSellingPrice,
    required this.averageCostPrice,
    required this.periodStart,
    required this.periodEnd,
    this.trends = const [],
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        categoryId,
        categoryName,
        warehouseId,
        warehouseName,
        quantitySold,
        totalRevenue,
        totalCost,
        grossProfit,
        profitMargin,
        profitPercentage,
        averageSellingPrice,
        averageCostPrice,
        periodStart,
        periodEnd,
        trends,
      ];

  // Computed properties
  bool get isProfitable => grossProfit > 0;
  bool get hasLoss => grossProfit < 0;
  bool get isHighMargin => profitMargin > 0.3; // 30%
  bool get isLowMargin => profitMargin < 0.1; // 10%
  
  // Aliases for compatibility
  double get grossMarginPercentage => profitMargin * 100;
  int get unitsSold => quantitySold;
  double get rotationRate => quantitySold > 0 ? totalRevenue / quantitySold : 0;
  double get averageCost => averageCostPrice;

  String get profitabilityStatus {
    if (hasLoss) return 'Pérdida';
    if (isHighMargin) return 'Alto margen';
    if (isLowMargin) return 'Bajo margen';
    return 'Margen normal';
  }

  ProfitabilityReport copyWith({
    String? productId,
    String? productName,
    String? productSku,
    String? categoryId,
    String? categoryName,
    String? warehouseId,
    String? warehouseName,
    int? quantitySold,
    double? totalRevenue,
    double? totalCost,
    double? grossProfit,
    double? profitMargin,
    double? profitPercentage,
    double? averageSellingPrice,
    double? averageCostPrice,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<ProfitabilityTrend>? trends,
  }) {
    return ProfitabilityReport(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      quantitySold: quantitySold ?? this.quantitySold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      averageSellingPrice: averageSellingPrice ?? this.averageSellingPrice,
      averageCostPrice: averageCostPrice ?? this.averageCostPrice,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      trends: trends ?? this.trends,
    );
  }
}

class ProfitabilityTrend extends Equatable {
  final DateTime date;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final int quantity;

  const ProfitabilityTrend({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.quantity,
  });

  @override
  List<Object?> get props => [date, revenue, cost, profit, margin, quantity];

  ProfitabilityTrend copyWith({
    DateTime? date,
    double? revenue,
    double? cost,
    double? profit,
    double? margin,
    int? quantity,
  }) {
    return ProfitabilityTrend(
      date: date ?? this.date,
      revenue: revenue ?? this.revenue,
      cost: cost ?? this.cost,
      profit: profit ?? this.profit,
      margin: margin ?? this.margin,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ProfitabilityDetail extends Equatable {
  final String id;
  final DateTime date;
  final String transactionType; // 'sale', 'return', 'adjustment'
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final String? invoiceId;
  final String? customerId;
  final String? customerName;

  const ProfitabilityDetail({
    required this.id,
    required this.date,
    required this.transactionType,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    this.invoiceId,
    this.customerId,
    this.customerName,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        transactionType,
        quantity,
        unitPrice,
        unitCost,
        revenue,
        cost,
        profit,
        margin,
        invoiceId,
        customerId,
        customerName,
      ];

  bool get isProfitable => profit > 0;
  bool get isReturn => transactionType == 'return';
  bool get isSale => transactionType == 'sale';

  ProfitabilityDetail copyWith({
    String? id,
    DateTime? date,
    String? transactionType,
    int? quantity,
    double? unitPrice,
    double? unitCost,
    double? revenue,
    double? cost,
    double? profit,
    double? margin,
    String? invoiceId,
    String? customerId,
    String? customerName,
  }) {
    return ProfitabilityDetail(
      id: id ?? this.id,
      date: date ?? this.date,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      revenue: revenue ?? this.revenue,
      cost: cost ?? this.cost,
      profit: profit ?? this.profit,
      margin: margin ?? this.margin,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
    );
  }
}

class CategoryProfitabilityReport extends Equatable {
  final String categoryId;
  final String categoryName;
  final int totalProducts;
  final int quantitySold;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final double profitPercentage;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ProfitabilityReport> topProducts;

  const CategoryProfitabilityReport({
    required this.categoryId,
    required this.categoryName,
    required this.totalProducts,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.profitPercentage,
    required this.periodStart,
    required this.periodEnd,
    this.topProducts = const [],
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        totalProducts,
        quantitySold,
        totalRevenue,
        totalCost,
        grossProfit,
        profitMargin,
        profitPercentage,
        periodStart,
        periodEnd,
        topProducts,
      ];

  bool get isProfitable => grossProfit > 0;
  bool get hasLoss => grossProfit < 0;

  CategoryProfitabilityReport copyWith({
    String? categoryId,
    String? categoryName,
    int? totalProducts,
    int? quantitySold,
    double? totalRevenue,
    double? totalCost,
    double? grossProfit,
    double? profitMargin,
    double? profitPercentage,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<ProfitabilityReport>? topProducts,
  }) {
    return CategoryProfitabilityReport(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      totalProducts: totalProducts ?? this.totalProducts,
      quantitySold: quantitySold ?? this.quantitySold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}