// lib/features/dashboard/data/models/dashboard_stats_model.dart
import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required SalesStatsModel sales,
    required InvoiceStatsModel invoices,
    required ProductStatsModel products,
    required CustomerStatsModel customers,
    required ExpenseStatsModel expenses,
  }) : super(
          sales: sales,
          invoices: invoices,
          products: products,
          customers: customers,
          expenses: expenses,
        );

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    // Mapear desde la estructura plana del backend a la estructura anidada del frontend
    return DashboardStatsModel(
      sales: SalesStatsModel(
        totalAmount: (json['totalSales'] ?? 0).toDouble(),
        totalSales: json['totalInvoices'] ?? 0,
        todaySales: 0.0, // TODO: agregar al backend
        yesterdaySales: 0.0, // TODO: agregar al backend
        monthlySales: (json['totalSales'] ?? 0).toDouble(),
        yearSales: (json['totalSales'] ?? 0).toDouble(),
        todayGrowth: 0.0, // TODO: agregar al backend
        monthlyGrowth: 0.0, // TODO: agregar al backend
      ),
      invoices: InvoiceStatsModel(
        totalInvoices: json['totalInvoices'] ?? 0,
        todayInvoices: 0, // TODO: agregar al backend
        pendingInvoices: json['pendingInvoices'] ?? 0,
        paidInvoices: json['paidInvoices'] ?? 0,
        averageInvoiceValue: json['totalInvoices'] > 0 
          ? ((json['totalSales'] ?? 0).toDouble() / json['totalInvoices'])
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
          ? ((json['totalSales'] ?? 0).toDouble() / json['totalInvoices'])
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
      ),
    );
  }

  Map<String, dynamic> toJson() {
    // Convertir a la estructura esperada por el backend
    return {
      'totalSales': sales.totalAmount,
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
    };
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
  }) : super(
          totalAmount: totalAmount,
          totalExpenses: totalExpenses,
          monthlyExpenses: monthlyExpenses,
          todayExpenses: todayExpenses,
          pendingExpenses: pendingExpenses,
          approvedExpenses: approvedExpenses,
          monthlyGrowth: monthlyGrowth,
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
    };
  }
}