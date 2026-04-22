// lib/features/dashboard/data/models/dashboard_stats_model.dart
import '../../domain/entities/dashboard_stats.dart';
import 'profitability_stats_model.dart';

// Helper para convertir valores a double de manera segura
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required SalesStatsModel sales,
    required InvoiceStatsModel invoices,
    required ProductStatsModel products,
    required CustomerStatsModel customers,
    required ExpenseStatsModel expenses,
    required ProfitabilityStatsModel profitability,
    required List<PaymentMethodStats> paymentMethodsBreakdown,
    required IncomeTypeBreakdown incomeTypeBreakdown,
    List<CurrencyBreakdownStats>? currencyBreakdown,
    List<CurrencyBreakdownStats>? purchaseCurrencyBreakdown,
    bool multiCurrencyEnabled = false,
    String baseCurrency = 'COP',
    ReceivablesStats? receivables,
    double totalCollected = 0,
    double totalBilled = 0,
    double grossMarginPercentage = 0,
    double netMarginPercentage = 0,
    List<TrendPoint> trend = const [],
    CashFlowStats cashFlow = const CashFlowStats.empty(),
  }) : super(
         sales: sales,
         invoices: invoices,
         products: products,
         customers: customers,
         expenses: expenses,
         profitability: profitability,
         paymentMethodsBreakdown: paymentMethodsBreakdown,
         incomeTypeBreakdown: incomeTypeBreakdown,
         currencyBreakdown: currencyBreakdown,
         purchaseCurrencyBreakdown: purchaseCurrencyBreakdown,
         multiCurrencyEnabled: multiCurrencyEnabled,
         baseCurrency: baseCurrency,
         receivables: receivables,
         totalCollected: totalCollected,
         totalBilled: totalBilled,
         grossMarginPercentage: grossMarginPercentage,
         netMarginPercentage: netMarginPercentage,
         trend: trend,
         cashFlow: cashFlow,
       );

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    // Backend nuevo envía totalCollected y trend; backend viejo solo totalRevenue.
    // Fallback: si no viene totalCollected, asumimos que totalRevenue es cash basis.
    final totalCollected = json['totalCollected'] != null
        ? _toDouble(json['totalCollected'])
        : _toDouble(json['totalRevenue']);
    final totalBilled = json['totalBilled'] != null
        ? _toDouble(json['totalBilled'])
        : _toDouble(json['totalRevenue']);

    // Mapear desde la estructura plana del backend a la estructura anidada del frontend
    return DashboardStatsModel(
      sales: SalesStatsModel(
        totalAmount: _toDouble(json['totalRevenue']),
        totalSales: json['totalInvoices'] ?? 0,
        todaySales: _toDouble(json['totalRevenue']),
        yesterdaySales: 0.0,
        monthlySales: _toDouble(json['totalRevenue']),
        yearSales: _toDouble(json['totalRevenue']),
        todayGrowth: _toDouble(json['revenueGrowth']),
        monthlyGrowth: 0.0,
        accountsReceivable: _toDouble(json['accountsReceivable']),
        receivableCount: json['receivableCount'] ?? 0,
      ),
      invoices: InvoiceStatsModel(
        totalInvoices: json['totalInvoices'] ?? 0,
        todayInvoices: 0, // TODO: agregar al backend
        pendingInvoices: json['pendingInvoices'] ?? 0,
        paidInvoices: json['paidInvoices'] ?? 0,
        averageInvoiceValue:
            json['totalInvoices'] > 0
                ? (_toDouble(json['totalRevenue']) / json['totalInvoices'])
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
        averageOrderValue:
            json['totalInvoices'] > 0
                ? (_toDouble(json['totalRevenue']) / json['totalInvoices'])
                : 0.0,
        todayGrowth: 0.0, // TODO: agregar al backend
      ),
      expenses: ExpenseStatsModel(
        totalAmount: _toDouble(json['totalExpenses']),
        totalExpenses: 0, // TODO: agregar al backend
        monthlyExpenses: _toDouble(json['totalExpenses']),
        todayExpenses: 0.0, // TODO: agregar al backend
        pendingExpenses: 0, // TODO: agregar al backend
        approvedExpenses: 0, // TODO: agregar al backend
        monthlyGrowth: 0.0, // TODO: agregar al backend
        expensesByCategory: _parseExpensesByCategory(
          json['expensesByCategory'],
        ),
      ),
      profitability:
          json['profitability'] != null
              ? ProfitabilityStatsModel.fromJson(json['profitability'])
              : _createDefaultProfitabilityStats(json),
      paymentMethodsBreakdown: _parsePaymentMethodsBreakdown(
        json['paymentMethodsBreakdown'],
      ),
      incomeTypeBreakdown: _parseIncomeTypeBreakdown(
        json['incomeTypeBreakdown'],
      ),
      currencyBreakdown: _parseCurrencyBreakdown(json['currencyBreakdown']),
      purchaseCurrencyBreakdown:
          _parseCurrencyBreakdown(json['purchaseCurrencyBreakdown']),
      multiCurrencyEnabled: json['multiCurrencyEnabled'] ?? false,
      baseCurrency: json['baseCurrency'] ?? 'COP',
      receivables: _parseReceivables(json['receivables']),
      totalCollected: totalCollected,
      totalBilled: totalBilled,
      grossMarginPercentage: _toDouble(json['grossMarginPercentage']),
      netMarginPercentage: _toDouble(json['netMarginPercentage']),
      trend: _parseTrend(json['trend']),
      cashFlow: json['cashFlow'] is Map<String, dynamic>
          ? CashFlowStats.fromJson(json['cashFlow'] as Map<String, dynamic>)
          : const CashFlowStats.empty(),
    );
  }

  static List<TrendPoint> _parseTrend(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map((m) {
      final dateStr = m['date']?.toString() ?? '';
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      return TrendPoint(
        date: date,
        revenue: _toDouble(m['revenue']),
        billed: _toDouble(m['billed']),
        expenses: _toDouble(m['expenses']),
      );
    }).toList();
  }

  static ReceivablesStats? _parseReceivables(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    ReceivablesBucket bucket(String key) {
      final b = data['byUrgency']?[key];
      if (b is! Map) return ReceivablesBucket.empty;
      return ReceivablesBucket(
        count: (b['count'] as num?)?.toInt() ?? 0,
        total: _toDouble(b['total']),
        maxDaysOverdue: (b['maxDaysOverdue'] as num?)?.toInt() ?? 0,
      );
    }

    final debtors = (data['topDebtors'] as List?) ?? const [];
    return ReceivablesStats(
      total: _toDouble(data['total']),
      count: (data['count'] as num?)?.toInt() ?? 0,
      current: bucket('current'),
      dueSoon: bucket('dueSoon'),
      overdue: bucket('overdue'),
      topDebtors: debtors.whereType<Map>().map((d) => TopDebtor(
            customerId: d['customerId']?.toString() ?? '',
            customerName: d['customerName']?.toString() ?? 'Sin nombre',
            invoiceCount: (d['invoiceCount'] as num?)?.toInt() ?? 0,
            totalBalance: _toDouble(d['totalBalance']),
            maxDaysOverdue: (d['maxDaysOverdue'] as num?)?.toInt() ?? 0,
          )).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': sales.totalAmount,
      'totalExpenses': expenses.totalAmount,
      'netProfit': sales.totalAmount - expenses.totalAmount,
      'profitMargin':
          sales.totalAmount > 0
              ? ((sales.totalAmount - expenses.totalAmount) /
                  sales.totalAmount *
                  100)
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
      'accountsReceivable': sales.accountsReceivable,
      'receivableCount': sales.receivableCount,
      'currencyBreakdown': currencyBreakdown?.map((c) => {
        'currency': c.currency,
        'count': c.count,
        'totalBaseAmount': c.totalBaseAmount,
        'totalForeignAmount': c.totalForeignAmount,
        'avgRate': c.avgRate,
        'percentage': c.percentage,
      }).toList(),
      'multiCurrencyEnabled': multiCurrencyEnabled,
      'baseCurrency': baseCurrency,
    };
  }

  static ProfitabilityStatsModel _createDefaultProfitabilityStats(
    Map<String, dynamic> json,
  ) {
    final totalRevenue = _toDouble(json['totalRevenue']);
    final totalCOGS = 0.0; // TODO: Calcular COGS real cuando esté el backend
    final grossProfit = totalRevenue - totalCOGS;
    final grossMarginPercentage =
        totalRevenue > 0 ? (grossProfit / totalRevenue * 100) : 0.0;
    final totalExpenses = _toDouble(json['totalExpenses']);
    final netProfit = grossProfit - totalExpenses;
    final netMarginPercentage =
        totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;

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
      return categoriesData.map(
        (key, value) => MapEntry(key, _toDouble(value)),
      );
    } else if (categoriesData is List) {
      final Map<String, double> result = <String, double>{};
      for (final item in categoriesData) {
        if (item is Map<String, dynamic>) {
          final categoryName =
              item['categoryName'] ?? item['name'] ?? 'Sin categoría';
          final amount = _toDouble(item['totalAmount'] ?? item['amount']);
          result[categoryName] = amount;
        }
      }
      return result;
    }

    return <String, double>{};
  }


  static List<PaymentMethodStats> _parsePaymentMethodsBreakdown(
    dynamic paymentMethodsData,
  ) {
    if (paymentMethodsData == null) return <PaymentMethodStats>[];

    if (paymentMethodsData is List) {
      return paymentMethodsData.map((item) {
        if (item is Map<String, dynamic>) {
          return PaymentMethodStats(
            method: item['method'] ?? '',
            count: item['count'] ?? 0,
            totalAmount: _toDouble(item['totalAmount']),
            percentage: _toDouble(item['percentage']),
          );
        }
        return const PaymentMethodStats(
          method: '',
          count: 0,
          totalAmount: 0.0,
          percentage: 0.0,
        );
      }).toList();
    }

    return <PaymentMethodStats>[];
  }

  static List<CurrencyBreakdownStats>? _parseCurrencyBreakdown(dynamic data) {
    if (data == null) return null;
    if (data is! List) return null;
    return data.map((item) {
      if (item is Map<String, dynamic>) {
        return CurrencyBreakdownStats(
          currency: item['currency'] ?? '',
          count: item['count'] ?? 0,
          totalBaseAmount: _toDouble(item['totalBaseAmount']),
          totalForeignAmount: _toDouble(item['totalForeignAmount']),
          avgRate: _toDouble(item['avgRate']),
          percentage: _toDouble(item['percentage']),
        );
      }
      return const CurrencyBreakdownStats(
        currency: '',
        count: 0,
        totalBaseAmount: 0,
        totalForeignAmount: 0,
        avgRate: 1,
        percentage: 0,
      );
    }).toList();
  }

  static IncomeTypeBreakdown _parseIncomeTypeBreakdown(
    dynamic incomeTypeData,
  ) {
    if (incomeTypeData == null) {
      return const IncomeTypeBreakdown(
        invoices: 0.0,
        newInvoices: 0.0,
        paymentsOnOldInvoices: 0.0,
        credits: 0.0,
        total: 0.0,
      );
    }

    if (incomeTypeData is Map<String, dynamic>) {
      final invoices = _toDouble(incomeTypeData['invoices']);
      // Fallback: si el backend no envía newInvoices (versión anterior), derivarlo.
      final newInvoices = incomeTypeData['newInvoices'] != null
          ? _toDouble(incomeTypeData['newInvoices'])
          : invoices;
      final paymentsOnOldInvoices = _toDouble(
        incomeTypeData['paymentsOnOldInvoices'],
      );
      return IncomeTypeBreakdown(
        invoices: invoices,
        newInvoices: newInvoices,
        paymentsOnOldInvoices: paymentsOnOldInvoices,
        credits: _toDouble(incomeTypeData['credits']),
        total: _toDouble(incomeTypeData['total']),
      );
    }

    return const IncomeTypeBreakdown(
      invoices: 0.0,
      newInvoices: 0.0,
      paymentsOnOldInvoices: 0.0,
      credits: 0.0,
      total: 0.0,
    );
  }
}

class SalesStatsModel extends SalesStats {
  const SalesStatsModel({
    required super.totalAmount,
    required super.totalSales,
    required super.todaySales,
    required super.yesterdaySales,
    required super.monthlySales,
    required super.yearSales,
    required super.todayGrowth,
    required super.monthlyGrowth,
    super.accountsReceivable = 0,
    super.receivableCount = 0,
  });

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) {
    return SalesStatsModel(
      totalAmount: _toDouble(json['totalAmount']),
      totalSales: json['totalSales'] ?? 0,
      todaySales: _toDouble(json['todaySales']),
      yesterdaySales: _toDouble(json['yesterdaySales']),
      monthlySales: _toDouble(json['monthlySales']),
      yearSales: _toDouble(json['yearSales']),
      todayGrowth: _toDouble(json['todayGrowth']),
      monthlyGrowth: _toDouble(json['monthlyGrowth']),
      accountsReceivable: _toDouble(json['accountsReceivable']),
      receivableCount: json['receivableCount'] ?? 0,
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
      'accountsReceivable': accountsReceivable,
      'receivableCount': receivableCount,
    };
  }
}

class InvoiceStatsModel extends InvoiceStats {
  const InvoiceStatsModel({
    required super.totalInvoices,
    required super.todayInvoices,
    required super.pendingInvoices,
    required super.paidInvoices,
    required super.averageInvoiceValue,
    required super.todayGrowth,
  });

  factory InvoiceStatsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceStatsModel(
      totalInvoices: json['totalInvoices'] ?? 0,
      todayInvoices: json['todayInvoices'] ?? 0,
      pendingInvoices: json['pendingInvoices'] ?? 0,
      paidInvoices: json['paidInvoices'] ?? 0,
      averageInvoiceValue: _toDouble(json['averageInvoiceValue']),
      todayGrowth: _toDouble(json['todayGrowth']),
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
    required super.totalProducts,
    required super.activeProducts,
    required super.lowStockProducts,
    required super.outOfStockProducts,
    required super.totalInventoryValue,
    required super.todayGrowth,
  });

  factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
    return ProductStatsModel(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      totalInventoryValue: _toDouble(json['totalInventoryValue']),
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
    required super.totalCustomers,
    required super.activeCustomers,
    required super.newCustomersToday,
    required super.newCustomersMonth,
    required super.averageOrderValue,
    required super.todayGrowth,
  });

  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      totalCustomers: json['totalCustomers'] ?? 0,
      activeCustomers: json['activeCustomers'] ?? 0,
      newCustomersToday: json['newCustomersToday'] ?? 0,
      newCustomersMonth: json['newCustomersMonth'] ?? 0,
      averageOrderValue: _toDouble(json['averageOrderValue']),
      todayGrowth: _toDouble(json['todayGrowth']),
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
    required super.totalAmount,
    required super.totalExpenses,
    required super.monthlyExpenses,
    required super.todayExpenses,
    required super.pendingExpenses,
    required super.approvedExpenses,
    required super.monthlyGrowth,
    required super.expensesByCategory,
  });

  factory ExpenseStatsModel.fromJson(Map<String, dynamic> json) {
    return ExpenseStatsModel(
      totalAmount: _toDouble(json['totalAmount']),
      totalExpenses: json['totalExpenses'] ?? 0,
      monthlyExpenses: _toDouble(json['monthlyExpenses']),
      todayExpenses: _toDouble(json['todayExpenses']),
      pendingExpenses: json['pendingExpenses'] ?? 0,
      approvedExpenses: json['approvedExpenses'] ?? 0,
      monthlyGrowth: _toDouble(json['monthlyGrowth']),
      expensesByCategory: ExpenseStatsModel._parseExpensesByCategory(
        json['expensesByCategory'],
      ),
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
      return categoriesData.map(
        (key, value) => MapEntry(key, _toDouble(value)),
      );
    } else if (categoriesData is List) {
      final Map<String, double> result = <String, double>{};
      for (final item in categoriesData) {
        if (item is Map<String, dynamic>) {
          final categoryName =
              item['categoryName'] ?? item['name'] ?? 'Sin categoría';
          final amount = _toDouble(item['totalAmount'] ?? item['amount']);
          result[categoryName] = amount;
        }
      }
      return result;
    }

    return <String, double>{};
  }
}
