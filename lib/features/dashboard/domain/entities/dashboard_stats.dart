// lib/features/dashboard/domain/entities/dashboard_stats.dart
import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final SalesStats sales;
  final InvoiceStats invoices;
  final ProductStats products;
  final CustomerStats customers;
  final ExpenseStats expenses;
  final ProfitabilityStats profitability;
  final List<PaymentMethodStats> paymentMethodsBreakdown;
  final IncomeTypeBreakdown incomeTypeBreakdown;
  final List<CurrencyBreakdownStats>? currencyBreakdown;
  final bool multiCurrencyEnabled;
  final String baseCurrency;
  final ReceivablesStats? receivables;

  const DashboardStats({
    required this.sales,
    required this.invoices,
    required this.products,
    required this.customers,
    required this.expenses,
    required this.profitability,
    required this.paymentMethodsBreakdown,
    required this.incomeTypeBreakdown,
    this.currencyBreakdown,
    this.multiCurrencyEnabled = false,
    this.baseCurrency = 'COP',
    this.receivables,
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
    currencyBreakdown,
    multiCurrencyEnabled,
    baseCurrency,
    receivables,
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
  final double accountsReceivable;
  final int receivableCount;

  const SalesStats({
    required this.totalAmount,
    required this.totalSales,
    required this.todaySales,
    required this.yesterdaySales,
    required this.monthlySales,
    required this.yearSales,
    required this.todayGrowth,
    required this.monthlyGrowth,
    this.accountsReceivable = 0,
    this.receivableCount = 0,
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
    accountsReceivable,
    receivableCount,
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
  // Total de facturas (incluye ventas nuevas + abonos en facturas viejas).
  // Se conserva para compatibilidad retro.
  final double invoices;
  // Ventas facturadas dentro del período.
  final double newInvoices;
  // Abonos recibidos en el período sobre facturas de fechas anteriores.
  final double paymentsOnOldInvoices;
  final double credits;
  final double total;

  const IncomeTypeBreakdown({
    required this.invoices,
    required this.newInvoices,
    required this.paymentsOnOldInvoices,
    required this.credits,
    required this.total,
  });

  @override
  List<Object?> get props => [
    invoices,
    newInvoices,
    paymentsOnOldInvoices,
    credits,
    total,
  ];
}

// Cuentas por cobrar con semáforo de urgencia
class ReceivablesBucket extends Equatable {
  final int count;
  final double total;
  final int maxDaysOverdue;

  const ReceivablesBucket({
    required this.count,
    required this.total,
    this.maxDaysOverdue = 0,
  });

  static const empty = ReceivablesBucket(count: 0, total: 0);

  @override
  List<Object?> get props => [count, total, maxDaysOverdue];
}

class TopDebtor extends Equatable {
  final String customerId;
  final String customerName;
  final int invoiceCount;
  final double totalBalance;
  final int maxDaysOverdue;

  const TopDebtor({
    required this.customerId,
    required this.customerName,
    required this.invoiceCount,
    required this.totalBalance,
    this.maxDaysOverdue = 0,
  });

  @override
  List<Object?> get props => [
    customerId,
    customerName,
    invoiceCount,
    totalBalance,
    maxDaysOverdue,
  ];
}

class ReceivablesStats extends Equatable {
  final double total;
  final int count;
  // Semáforo: verde (vigente), amarillo (por vencer), rojo (vencida)
  final ReceivablesBucket current;
  final ReceivablesBucket dueSoon;
  final ReceivablesBucket overdue;
  final List<TopDebtor> topDebtors;

  const ReceivablesStats({
    required this.total,
    required this.count,
    required this.current,
    required this.dueSoon,
    required this.overdue,
    required this.topDebtors,
  });

  bool get hasAny => count > 0;
  bool get hasOverdue => overdue.count > 0;
  bool get hasDueSoon => dueSoon.count > 0;

  @override
  List<Object?> get props => [total, count, current, dueSoon, overdue, topDebtors];
}

// Desglose por moneda (solo cuando multiCurrencyEnabled)
class CurrencyBreakdownStats extends Equatable {
  final String currency;
  final int count;
  final double totalBaseAmount;
  final double totalForeignAmount;
  final double avgRate;
  final double percentage;

  const CurrencyBreakdownStats({
    required this.currency,
    required this.count,
    required this.totalBaseAmount,
    required this.totalForeignAmount,
    required this.avgRate,
    required this.percentage,
  });

  bool get isForeignCurrency => avgRate != 1.0;

  @override
  List<Object?> get props => [
    currency,
    count,
    totalBaseAmount,
    totalForeignAmount,
    avgRate,
    percentage,
  ];
}