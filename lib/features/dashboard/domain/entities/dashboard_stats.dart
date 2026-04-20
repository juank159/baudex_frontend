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

  /// Dinero realmente cobrado en el período (cash basis).
  /// Es la métrica principal a mostrar al usuario.
  final double totalCollected;

  /// Total facturado en el período (accrual basis, incluye crédito no cobrado).
  /// Se muestra como métrica secundaria.
  final double totalBilled;

  /// Margen bruto real con COGS descontado (sobre totalCollected).
  final double grossMarginPercentage;

  /// Margen neto con COGS + gastos (sobre totalCollected).
  final double netMarginPercentage;

  /// Puntos de tendencia reales por día (no fabricados).
  final List<TrendPoint> trend;

  /// Resumen de caja: ventas + préstamos + anticipos, desagregados.
  /// Mostrado en el widget "Resumen de caja" del dashboard.
  final CashFlowStats cashFlow;

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
    this.totalCollected = 0,
    this.totalBilled = 0,
    this.grossMarginPercentage = 0,
    this.netMarginPercentage = 0,
    this.trend = const [],
    this.cashFlow = const CashFlowStats.empty(),
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
    totalCollected,
    totalBilled,
    grossMarginPercentage,
    netMarginPercentage,
    trend,
    cashFlow,
  ];

  /// Clona la instancia sobreescribiendo solo los campos dados.
  /// IMPORTANTE: usar esto en vez de `DashboardStats(...)` para mutaciones
  /// parciales; así no olvidamos los campos nuevos al agregarlos.
  DashboardStats copyWith({
    SalesStats? sales,
    InvoiceStats? invoices,
    ProductStats? products,
    CustomerStats? customers,
    ExpenseStats? expenses,
    ProfitabilityStats? profitability,
    List<PaymentMethodStats>? paymentMethodsBreakdown,
    IncomeTypeBreakdown? incomeTypeBreakdown,
    List<CurrencyBreakdownStats>? currencyBreakdown,
    bool? multiCurrencyEnabled,
    String? baseCurrency,
    ReceivablesStats? receivables,
    double? totalCollected,
    double? totalBilled,
    double? grossMarginPercentage,
    double? netMarginPercentage,
    List<TrendPoint>? trend,
    CashFlowStats? cashFlow,
  }) {
    return DashboardStats(
      sales: sales ?? this.sales,
      invoices: invoices ?? this.invoices,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      expenses: expenses ?? this.expenses,
      profitability: profitability ?? this.profitability,
      paymentMethodsBreakdown: paymentMethodsBreakdown ?? this.paymentMethodsBreakdown,
      incomeTypeBreakdown: incomeTypeBreakdown ?? this.incomeTypeBreakdown,
      currencyBreakdown: currencyBreakdown ?? this.currencyBreakdown,
      multiCurrencyEnabled: multiCurrencyEnabled ?? this.multiCurrencyEnabled,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      receivables: receivables ?? this.receivables,
      totalCollected: totalCollected ?? this.totalCollected,
      totalBilled: totalBilled ?? this.totalBilled,
      grossMarginPercentage: grossMarginPercentage ?? this.grossMarginPercentage,
      netMarginPercentage: netMarginPercentage ?? this.netMarginPercentage,
      trend: trend ?? this.trend,
      cashFlow: cashFlow ?? this.cashFlow,
    );
  }
}

/// Flujo de caja del período desagregado por origen.
/// Separa ventas de recuperación de préstamos y de anticipos, para reportar
/// con criterio contable correcto (ventas ≠ cartera ≠ pasivos).
class CashFlowStats extends Equatable {
  /// Cobros por venta (facturas). Coincide con `totalCollected`.
  final double salesCollected;
  final int salesCollectedCount;

  /// Abonos a préstamos directos (créditos sin factura). Recuperación de cartera.
  final double loanPayments;
  final int loanPaymentsCount;

  /// Depósitos a saldo a favor del cliente. Pasivo hasta que se aplique.
  final double customerDeposits;
  final int customerDepositsCount;

  /// Caja total del período: ventas + préstamos + anticipos.
  final double totalCashIn;

  /// Desglose de abonos a préstamos por cuenta bancaria o método de pago.
  final List<CashFlowMethodRow> loanPaymentsBreakdown;

  /// Desglose de anticipos por método de pago.
  final List<CashFlowMethodRow> customerDepositsBreakdown;

  const CashFlowStats({
    required this.salesCollected,
    required this.salesCollectedCount,
    required this.loanPayments,
    required this.loanPaymentsCount,
    required this.customerDeposits,
    required this.customerDepositsCount,
    required this.totalCashIn,
    this.loanPaymentsBreakdown = const [],
    this.customerDepositsBreakdown = const [],
  });

  const CashFlowStats.empty()
      : salesCollected = 0,
        salesCollectedCount = 0,
        loanPayments = 0,
        loanPaymentsCount = 0,
        customerDeposits = 0,
        customerDepositsCount = 0,
        totalCashIn = 0,
        loanPaymentsBreakdown = const [],
        customerDepositsBreakdown = const [];

  factory CashFlowStats.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    List<CashFlowMethodRow> rows(dynamic v) {
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((m) => CashFlowMethodRow.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return CashFlowStats(
      salesCollected: d(json['salesCollected']),
      salesCollectedCount: i(json['salesCollectedCount']),
      loanPayments: d(json['loanPayments']),
      loanPaymentsCount: i(json['loanPaymentsCount']),
      customerDeposits: d(json['customerDeposits']),
      customerDepositsCount: i(json['customerDepositsCount']),
      totalCashIn: d(json['totalCashIn']),
      loanPaymentsBreakdown: rows(json['loanPaymentsBreakdown']),
      customerDepositsBreakdown: rows(json['customerDepositsBreakdown']),
    );
  }

  bool get hasAny => salesCollected > 0 || loanPayments > 0 || customerDeposits > 0;

  @override
  List<Object?> get props => [
        salesCollected,
        salesCollectedCount,
        loanPayments,
        loanPaymentsCount,
        customerDeposits,
        customerDepositsCount,
        totalCashIn,
        loanPaymentsBreakdown,
        customerDepositsBreakdown,
      ];
}

/// Fila de desglose por cuenta bancaria o método de pago.
class CashFlowMethodRow extends Equatable {
  final String method;
  final int count;
  final double total;

  const CashFlowMethodRow({
    required this.method,
    required this.count,
    required this.total,
  });

  factory CashFlowMethodRow.fromJson(Map<String, dynamic> json) {
    return CashFlowMethodRow(
      method: json['method']?.toString() ?? 'Sin especificar',
      count: (json['count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [method, count, total];
}

/// Punto de tendencia diario. Mapea 1:1 con el TrendPoint del backend.
class TrendPoint extends Equatable {
  final DateTime date;
  final double revenue;  // cobrado ese día
  final double billed;   // facturado ese día (incluye crédito)
  final double expenses;

  const TrendPoint({
    required this.date,
    required this.revenue,
    required this.billed,
    required this.expenses,
  });

  @override
  List<Object?> get props => [date, revenue, billed, expenses];
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