// lib/features/dashboard/data/models/dashboard_stats_model.dart
import '../../domain/entities/dashboard_stats.dart';
import 'profitability_stats_model.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required SalesStatsModel sales,
    required InvoiceStatsModel invoices,
    required ProductStatsModel products,
    required CustomerStatsModel customers,
    required ExpenseStatsModel expenses,
    required ProfitabilityStatsModel profitability,
  }) : super(
          sales: sales,
          invoices: invoices,
          products: products,
          customers: customers,
          expenses: expenses,
          profitability: profitability,
        );

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    // Mapear desde la estructura plana del backend a la estructura anidada del frontend
    return DashboardStatsModel(
      sales: SalesStatsModel(
        totalAmount: (json['totalRevenue'] ?? 0).toDouble(), // ✅ CORREGIDO: usar totalRevenue
        totalSales: json['totalInvoices'] ?? 0,
        todaySales: (json['totalRevenue'] ?? 0).toDouble(), // Usar revenue real 
        yesterdaySales: 0.0, // TODO: agregar al backend
        monthlySales: (json['totalRevenue'] ?? 0).toDouble(), // Usar revenue real
        yearSales: (json['totalRevenue'] ?? 0).toDouble(), // Usar revenue real
        todayGrowth: (json['revenueGrowth'] ?? 0).toDouble(), // Usar growth real
        monthlyGrowth: 0.0, // TODO: agregar al backend
      ),
      invoices: InvoiceStatsModel(
        totalInvoices: json['totalInvoices'] ?? 0,
        todayInvoices: 0, // TODO: agregar al backend
        pendingInvoices: json['pendingInvoices'] ?? 0,
        paidInvoices: json['paidInvoices'] ?? 0,
        averageInvoiceValue: json['totalInvoices'] > 0 
          ? ((json['totalRevenue'] ?? 0).toDouble() / json['totalInvoices'])
          : 0.0,
        todayGrowth: 0.0, // TODO: agregar al backend
      ),
      products: ProductStatsModel(
        totalProducts: json['totalProducts'] ?? 0,
        activeProducts: json['totalProducts'] ?? 0,
        lowStockProducts: json['lowStockProducts'] ?? 0,
        outOfStockProducts: json['outOfStockProducts'] ?? 0,
        totalInventoryValue: 0.0, // TODO: agregar al backend
        todayGrowth: 0, // TODO: agregar al backend
      ),
      customers: CustomerStatsModel(
        totalCustomers: json['totalCustomers'] ?? 0,
        activeCustomers: json['activeCustomers'] ?? 0,
        newCustomersToday: 0, // TODO: agregar al backend
        newCustomersMonth: json['newCustomersThisMonth'] ?? 0,
        averageOrderValue: json['totalInvoices'] > 0 
          ? ((json['totalRevenue'] ?? 0).toDouble() / json['totalInvoices'])
          : 0.0,
        todayGrowth: 0.0, // TODO: agregar al backend
      ),
      expenses: ExpenseStatsModel(
        totalAmount: (json['totalExpenses'] ?? 0).toDouble(),
        totalExpenses: 0, // TODO: agregar al backend
        monthlyExpenses: (json['totalExpenses'] ?? 0).toDouble(),
        todayExpenses: 0.0, // TODO: agregar al backend
        pendingExpenses: 0, // TODO: agregar al backend
        approvedExpenses: 0, // TODO: agregar al backend
        monthlyGrowth: 0.0, // TODO: agregar al backend
        expensesByCategory: _parseExpensesByCategory(json['expensesByCategory']),
      ),
      profitability: json['profitability'] != null 
        ? ProfitabilityStatsModel.fromJson(json['profitability'])
        : _createDefaultProfitabilityStats(json),
    );
  }

  Map<String, dynamic> toJson() {
    // Convertir a la estructura esperada por el backend
    return {
      'totalRevenue': sales.totalAmount,
      'totalExpenses': expenses.totalAmount,
      'netProfit': sales.totalAmount - expenses.totalAmount,
      'profitMargin': sales.totalAmount > 0 
        ? ((sales.totalAmount - expenses.totalAmount) / sales.totalAmount * 100) 
        : 0.0,
      'totalInvoices': invoices.totalInvoices,
      'paidInvoices': invoices.paidInvoices,
      'pendingInvoices': invoices.pendingInvoices,
      'totalCustomers': customers.totalCustomers,
      'activeCustomers': customers.activeCustomers,
      'newCustomersThisMonth': customers.newCustomersMonth,
      'totalProducts': products.totalProducts,
      'lowStockProducts': products.lowStockProducts,
      'outOfStockProducts': products.outOfStockProducts,
      'profitability': (profitability as ProfitabilityStatsModel).toJson(),
    };
  }

  static ProfitabilityStatsModel _createDefaultProfitabilityStats(Map<String, dynamic> json) {
    final totalRevenue = (json['totalRevenue'] ?? 0).toDouble();
    final totalCOGS = 0.0; // TODO: Calcular COGS real cuando esté el backend
    final grossProfit = totalRevenue - totalCOGS;
    final grossMarginPercentage = totalRevenue > 0 ? (grossProfit / totalRevenue * 100) : 0.0;
    final totalExpenses = (json['totalExpenses'] ?? 0).toDouble();
    final netProfit = grossProfit - totalExpenses;
    final netMarginPercentage = totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;

    return ProfitabilityStatsModel(
      totalRevenue: totalRevenue,
      totalCOGS: totalCOGS,
      grossProfit: grossProfit,
      grossMarginPercentage: grossMarginPercentage,
      netProfit: netProfit,
      netMarginPercentage: netMarginPercentage,
      averageMarginPerSale: grossMarginPercentage,
      topProfitableProducts: const [],
      lowProfitableProducts: const [],
      marginsByCategory: const {},
      trend: const ProfitabilityTrendModel(
        previousPeriodGrossMargin: 0.0,
        currentPeriodGrossMargin: 0.0,
        marginGrowth: 0.0,
        isImproving: false,
        dailyMargins: [],
      ),
    );
  }

  static Map<String, double> _parseExpensesByCategory(dynamic categoriesData) {
    if (categoriesData == null) return <String, double>{};
    
    if (categoriesData is Map<String, dynamic>) {
      return categoriesData.map((key, value) => MapEntry(key, (value ?? 0).toDouble()));
    } else if (categoriesData is List) {
      final Map<String, double> result = <String, double>{};
      for (final item in categoriesData) {
        if (item is Map<String, dynamic>) {
          final categoryName = item['categoryName'] ?? item['name'] ?? 'Sin categoría';
          final amount = (item['totalAmount'] ?? item['amount'] ?? 0).toDouble();
          result[categoryName] = amount;
        }
      }
      return result;
    }
    
    return <String, double>{};
  }
}

class SalesStatsModel extends SalesStats {
  const SalesStatsModel({
    required double totalAmount,
    required int totalSales,
    required double todaySales,
    required double yesterdaySales,
    required double monthlySales,
    required double yearSales,
    required double todayGrowth,
    required double monthlyGrowth,
  }) : super(
          totalAmount: totalAmount,
          totalSales: totalSales,
          todaySales: todaySales,
          yesterdaySales: yesterdaySales,
          monthlySales: monthlySales,
          yearSales: yearSales,
          todayGrowth: todayGrowth,
          monthlyGrowth: monthlyGrowth,
        );

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) {
    return SalesStatsModel(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalSales: json['totalSales'] ?? 0,
      todaySales: (json['todaySales'] ?? 0).toDouble(),
      yesterdaySales: (json['yesterdaySales'] ?? 0).toDouble(),
      monthlySales: (json['monthlySales'] ?? 0).toDouble(),
      yearSales: (json['yearSales'] ?? 0).toDouble(),
      todayGrowth: (json['todayGrowth'] ?? 0).toDouble(),
      monthlyGrowth: (json['monthlyGrowth'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalSales': totalSales,
      'todaySales': todaySales,
      'yesterdaySales': yesterdaySales,
      'monthlySales': monthlySales,
      'yearSales': yearSales,
      'todayGrowth': todayGrowth,
      'monthlyGrowth': monthlyGrowth,
    };
  }
}

class InvoiceStatsModel extends InvoiceStats {
  const InvoiceStatsModel({
    required int totalInvoices,
    required int todayInvoices,
    required int pendingInvoices,
    required int paidInvoices,
    required double averageInvoiceValue,
    required double todayGrowth,
  }) : super(
          totalInvoices: totalInvoices,
          todayInvoices: todayInvoices,
          pendingInvoices: pendingInvoices,
          paidInvoices: paidInvoices,
          averageInvoiceValue: averageInvoiceValue,
          todayGrowth: todayGrowth,
        );

  factory InvoiceStatsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceStatsModel(
      totalInvoices: json['totalInvoices'] ?? 0,
      todayInvoices: json['todayInvoices'] ?? 0,
      pendingInvoices: json['pendingInvoices'] ?? 0,
      paidInvoices: json['paidInvoices'] ?? 0,
      averageInvoiceValue: (json['averageInvoiceValue'] ?? 0).toDouble(),
      todayGrowth: (json['todayGrowth'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInvoices': totalInvoices,
      'todayInvoices': todayInvoices,
      'pendingInvoices': pendingInvoices,
      'paidInvoices': paidInvoices,
      'averageInvoiceValue': averageInvoiceValue,
      'todayGrowth': todayGrowth,
    };
  }
}

class ProductStatsModel extends ProductStats {
  const ProductStatsModel({
    required int totalProducts,
    required int activeProducts,
    required int lowStockProducts,
    required int outOfStockProducts,
    required double totalInventoryValue,
    required int todayGrowth,
  }) : super(
          totalProducts: totalProducts,
          activeProducts: activeProducts,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
          totalInventoryValue: totalInventoryValue,
          todayGrowth: todayGrowth,
        );

  factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
    return ProductStatsModel(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      totalInventoryValue: (json['totalInventoryValue'] ?? 0).toDouble(),
      todayGrowth: json['todayGrowth'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'totalInventoryValue': totalInventoryValue,
      'todayGrowth': todayGrowth,
    };
  }
}

class CustomerStatsModel extends CustomerStats {
  const CustomerStatsModel({
    required int totalCustomers,
    required int activeCustomers,
    required int newCustomersToday,
    required int newCustomersMonth,
    required double averageOrderValue,
    required double todayGrowth,
  }) : super(
          totalCustomers: totalCustomers,
          activeCustomers: activeCustomers,
          newCustomersToday: newCustomersToday,
          newCustomersMonth: newCustomersMonth,
          averageOrderValue: averageOrderValue,
          todayGrowth: todayGrowth,
        );

  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      totalCustomers: json['totalCustomers'] ?? 0,
      activeCustomers: json['activeCustomers'] ?? 0,
      newCustomersToday: json['newCustomersToday'] ?? 0,
      newCustomersMonth: json['newCustomersMonth'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      todayGrowth: (json['todayGrowth'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'newCustomersToday': newCustomersToday,
      'newCustomersMonth': newCustomersMonth,
      'averageOrderValue': averageOrderValue,
      'todayGrowth': todayGrowth,
    };
  }
}

class ExpenseStatsModel extends ExpenseStats {
  const ExpenseStatsModel({
    required double totalAmount,
    required int totalExpenses,
    required double monthlyExpenses,
    required double todayExpenses,
    required int pendingExpenses,
    required int approvedExpenses,
    required double monthlyGrowth,
    required Map<String, double> expensesByCategory,
  }) : super(
          totalAmount: totalAmount,
          totalExpenses: totalExpenses,
          monthlyExpenses: monthlyExpenses,
          todayExpenses: todayExpenses,
          pendingExpenses: pendingExpenses,
          approvedExpenses: approvedExpenses,
          monthlyGrowth: monthlyGrowth,
          expensesByCategory: expensesByCategory,
        );

  factory ExpenseStatsModel.fromJson(Map<String, dynamic> json) {
    return ExpenseStatsModel(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalExpenses: json['totalExpenses'] ?? 0,
      monthlyExpenses: (json['monthlyExpenses'] ?? 0).toDouble(),
      todayExpenses: (json['todayExpenses'] ?? 0).toDouble(),
      pendingExpenses: json['pendingExpenses'] ?? 0,
      approvedExpenses: json['approvedExpenses'] ?? 0,
      monthlyGrowth: (json['monthlyGrowth'] ?? 0).toDouble(),
      expensesByCategory: ExpenseStatsModel._parseExpensesByCategory(json['expensesByCategory']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalExpenses': totalExpenses,
      'monthlyExpenses': monthlyExpenses,
      'todayExpenses': todayExpenses,
      'pendingExpenses': pendingExpenses,
      'approvedExpenses': approvedExpenses,
      'monthlyGrowth': monthlyGrowth,
      'expensesByCategory': expensesByCategory,
    };
  }

  static Map<String, double> _parseExpensesByCategory(dynamic categoriesData) {
    if (categoriesData == null) return <String, double>{};
    
    if (categoriesData is Map<String, dynamic>) {
      return categoriesData.map((key, value) => MapEntry(key, (value ?? 0).toDouble()));
    } else if (categoriesData is List) {
      final Map<String, double> result = <String, double>{};
      for (final item in categoriesData) {
        if (item is Map<String, dynamic>) {
          final categoryName = item['categoryName'] ?? item['name'] ?? 'Sin categoría';
          final amount = (item['totalAmount'] ?? item['amount'] ?? 0).toDouble();
          result[categoryName] = amount;
        }
      }
      return result;
    }
    
    return <String, double>{};
  }
}