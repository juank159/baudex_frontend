// lib/features/dashboard/domain/entities/dashboard_stats.dart
import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final SalesStats sales;
  final InvoiceStats invoices;
  final ProductStats products;
  final CustomerStats customers;
  final ExpenseStats expenses;
  final ProfitabilityStats profitability; // 🆕 Métricas FIFO de rentabilidad
  final List<PaymentMethodStats> paymentMethodsBreakdown; // 🆕 NUEVO: Desglose por método de pago
  final IncomeTypeBreakdown incomeTypeBreakdown; // 🆕 NUEVO: Desglose por tipo de ingreso

  const DashboardStats({
    required this.sales,
    required this.invoices,
    required this.products,
    required this.customers,
    required this.expenses,
    required this.profitability,
    required this.paymentMethodsBreakdown,
    required this.incomeTypeBreakdown,
  });

  @override
  List<Object?> get props => [
    sales,
    invoices,
    products,
    customers,
    expenses,
    profitability,
    paymentMethodsBreakdown,
    incomeTypeBreakdown,
  ];
}

class SalesStats extends Equatable {
  final double totalAmount;
  final int totalSales;
  final double todaySales;
  final double yesterdaySales;
  final double monthlySales;
  final double yearSales;
  final double todayGrowth;
  final double monthlyGrowth;

  const SalesStats({
    required this.totalAmount,
    required this.totalSales,
    required this.todaySales,
    required this.yesterdaySales,
    required this.monthlySales,
    required this.yearSales,
    required this.todayGrowth,
    required this.monthlyGrowth,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    totalSales,
    todaySales,
    yesterdaySales,
    monthlySales,
    yearSales,
    todayGrowth,
    monthlyGrowth,
  ];
}

class InvoiceStats extends Equatable {
  final int totalInvoices;
  final int todayInvoices;
  final int pendingInvoices;
  final int paidInvoices;
  final double averageInvoiceValue;
  final double todayGrowth;

  const InvoiceStats({
    required this.totalInvoices,
    required this.todayInvoices,
    required this.pendingInvoices,
    required this.paidInvoices,
    required this.averageInvoiceValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalInvoices,
    todayInvoices,
    pendingInvoices,
    paidInvoices,
    averageInvoiceValue,
    todayGrowth,
  ];
}

class ProductStats extends Equatable {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;
  final int todayGrowth;

  const ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalInventoryValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    activeProducts,
    lowStockProducts,
    outOfStockProducts,
    totalInventoryValue,
    todayGrowth,
  ];
}

class CustomerStats extends Equatable {
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomersToday;
  final int newCustomersMonth;
  final double averageOrderValue;
  final double todayGrowth;

  const CustomerStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomersToday,
    required this.newCustomersMonth,
    required this.averageOrderValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalCustomers,
    activeCustomers,
    newCustomersToday,
    newCustomersMonth,
    averageOrderValue,
    todayGrowth,
  ];
}

class ExpenseStats extends Equatable {
  final double totalAmount;
  final int totalExpenses;
  final double monthlyExpenses;
  final double todayExpenses;
  final int pendingExpenses;
  final int approvedExpenses;
  final double monthlyGrowth;
  final Map<String, double> expensesByCategory;

  const ExpenseStats({
    required this.totalAmount,
    required this.totalExpenses,
    required this.monthlyExpenses,
    required this.todayExpenses,
    required this.pendingExpenses,
    required this.approvedExpenses,
    required this.monthlyGrowth,
    required this.expensesByCategory,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    totalExpenses,
    monthlyExpenses,
    todayExpenses,
    pendingExpenses,
    approvedExpenses,
    monthlyGrowth,
    expensesByCategory,
  ];
}

// 🆕 NUEVA ENTIDAD: Métricas de Rentabilidad FIFO
class ProfitabilityStats extends Equatable {
  final double totalRevenue;           // Total de ingresos
  final double totalCOGS;              // Costo de ventas FIFO real
  final double grossProfit;            // Ganancia bruta (revenue - COGS)
  final double grossMarginPercentage;  // Margen bruto %
  final double netProfit;              // Ganancia neta (gross - expenses)
  final double netMarginPercentage;    // Margen neto %
  final double averageMarginPerSale;   // Margen promedio por venta
  final List<ProductProfitability> topProfitableProducts;   // Top 5 más rentables
  final List<ProductProfitability> lowProfitableProducts;   // Top 5 menos rentables
  final Map<String, double> marginsByCategory;             // Márgenes por categoría
  final ProfitabilityTrend trend;                          // Tendencia de rentabilidad

  const ProfitabilityStats({
    required this.totalRevenue,
    required this.totalCOGS,
    required this.grossProfit,
    required this.grossMarginPercentage,
    required this.netProfit,
    required this.netMarginPercentage,
    required this.averageMarginPerSale,
    required this.topProfitableProducts,
    required this.lowProfitableProducts,
    required this.marginsByCategory,
    required this.trend,
  });

  @override
  List<Object?> get props => [
    totalRevenue,
    totalCOGS,
    grossProfit,
    grossMarginPercentage,
    netProfit,
    netMarginPercentage,
    averageMarginPerSale,
    topProfitableProducts,
    lowProfitableProducts,
    marginsByCategory,
    trend,
  ];
}

// 🆕 Rentabilidad por producto
class ProductProfitability extends Equatable {
  final String productId;
  final String productName;
  final String sku;
  final String? categoryName;
  final double totalRevenue;
  final double totalCOGS;
  final double grossProfit;
  final double marginPercentage;
  final int unitsSold;
  final double averageSellingPrice;
  final double averageFifoCost;

  const ProductProfitability({
    required this.productId,
    required this.productName,
    required this.sku,
    this.categoryName,
    required this.totalRevenue,
    required this.totalCOGS,
    required this.grossProfit,
    required this.marginPercentage,
    required this.unitsSold,
    required this.averageSellingPrice,
    required this.averageFifoCost,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    sku,
    categoryName,
    totalRevenue,
    totalCOGS,
    grossProfit,
    marginPercentage,
    unitsSold,
    averageSellingPrice,
    averageFifoCost,
  ];
}

// 🆕 Tendencia de rentabilidad
class ProfitabilityTrend extends Equatable {
  final double previousPeriodGrossMargin;
  final double currentPeriodGrossMargin;
  final double marginGrowth;
  final bool isImproving;
  final List<DailyMarginPoint> dailyMargins;

  const ProfitabilityTrend({
    required this.previousPeriodGrossMargin,
    required this.currentPeriodGrossMargin,
    required this.marginGrowth,
    required this.isImproving,
    required this.dailyMargins,
  });

  @override
  List<Object?> get props => [
    previousPeriodGrossMargin,
    currentPeriodGrossMargin,
    marginGrowth,
    isImproving,
    dailyMargins,
  ];
}

// 🆕 Punto de margen diario para gráficos
class DailyMarginPoint extends Equatable {
  final DateTime date;
  final double grossMarginPercentage;
  final double dailyRevenue;
  final double dailyCOGS;

  const DailyMarginPoint({
    required this.date,
    required this.grossMarginPercentage,
    required this.dailyRevenue,
    required this.dailyCOGS,
  });

  @override
  List<Object?> get props => [date, grossMarginPercentage, dailyRevenue, dailyCOGS];
}

// 🆕 NUEVO: Estadísticas por método de pago
class PaymentMethodStats extends Equatable {
  final String method;
  final int count;
  final double totalAmount;
  final double percentage;

  const PaymentMethodStats({
    required this.method,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });

  @override
  List<Object?> get props => [method, count, totalAmount, percentage];
}

// 🆕 NUEVO: Desglose por tipo de ingreso
class IncomeTypeBreakdown extends Equatable {
  final double invoices;
  final double credits;
  final double total;

  const IncomeTypeBreakdown({
    required this.invoices,
    required this.credits,
    required this.total,
  });

  @override
  List<Object?> get props => [invoices, credits, total];
}