// test/fixtures/dashboard_fixtures.dart
import 'package:baudex_desktop/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:baudex_desktop/features/dashboard/data/models/notification_model.dart';
import 'package:baudex_desktop/features/dashboard/data/models/profitability_stats_model.dart';
import 'package:baudex_desktop/features/dashboard/data/models/recent_activity_model.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/notification.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/recent_activity.dart';

class DashboardFixtures {
  // ==================== DASHBOARD STATS ====================

  static DashboardStatsModel createDashboardStatsModel({
    SalesStatsModel? sales,
    InvoiceStatsModel? invoices,
    ProductStatsModel? products,
    CustomerStatsModel? customers,
    ExpenseStatsModel? expenses,
    ProfitabilityStatsModel? profitability,
    List<PaymentMethodStats>? paymentMethodsBreakdown,
    IncomeTypeBreakdown? incomeTypeBreakdown,
  }) {
    return DashboardStatsModel(
      sales: sales ?? createSalesStatsModel(),
      invoices: invoices ?? createInvoiceStatsModel(),
      products: products ?? createProductStatsModel(),
      customers: customers ?? createCustomerStatsModel(),
      expenses: expenses ?? createExpenseStatsModel(),
      profitability: profitability ?? createProfitabilityStatsModel(),
      paymentMethodsBreakdown: paymentMethodsBreakdown ?? createPaymentMethodsBreakdown(),
      incomeTypeBreakdown: incomeTypeBreakdown ?? createIncomeTypeBreakdown(),
    );
  }

  static Map<String, dynamic> createDashboardStatsJson({
    double totalRevenue = 1500000.0,
    double totalExpenses = 500000.0,
    int totalInvoices = 150,
    int paidInvoices = 120,
    int pendingInvoices = 30,
    int totalCustomers = 85,
    int activeCustomers = 75,
    int newCustomersThisMonth = 12,
    int totalProducts = 250,
    int lowStockProducts = 15,
    int outOfStockProducts = 5,
    double revenueGrowth = 15.5,
  }) {
    return {
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netProfit': totalRevenue - totalExpenses,
      'profitMargin': ((totalRevenue - totalExpenses) / totalRevenue) * 100,
      'totalInvoices': totalInvoices,
      'paidInvoices': paidInvoices,
      'pendingInvoices': pendingInvoices,
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'newCustomersThisMonth': newCustomersThisMonth,
      'totalProducts': totalProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'revenueGrowth': revenueGrowth,
      'expensesByCategory': {
        'Servicios': 150000.0,
        'Productos': 250000.0,
        'Personal': 100000.0,
      },
      'paymentMethodsBreakdown': [
        {
          'method': 'Efectivo',
          'count': 45,
          'totalAmount': 450000.0,
          'percentage': 30.0,
        },
        {
          'method': 'Transferencia',
          'count': 75,
          'totalAmount': 750000.0,
          'percentage': 50.0,
        },
        {
          'method': 'Tarjeta',
          'count': 30,
          'totalAmount': 300000.0,
          'percentage': 20.0,
        },
      ],
      'incomeTypeBreakdown': {
        'invoices': 1400000.0,
        'credits': 100000.0,
        'total': 1500000.0,
      },
      'profitability': createProfitabilityStatsJson(),
    };
  }

  // ==================== SALES STATS ====================

  static SalesStatsModel createSalesStatsModel({
    double totalAmount = 1500000.0,
    int totalSales = 150,
    double todaySales = 50000.0,
    double yesterdaySales = 45000.0,
    double monthlySales = 800000.0,
    double yearSales = 1500000.0,
    double todayGrowth = 11.1,
    double monthlyGrowth = 15.5,
  }) {
    return SalesStatsModel(
      totalAmount: totalAmount,
      totalSales: totalSales,
      todaySales: todaySales,
      yesterdaySales: yesterdaySales,
      monthlySales: monthlySales,
      yearSales: yearSales,
      todayGrowth: todayGrowth,
      monthlyGrowth: monthlyGrowth,
    );
  }

  static Map<String, dynamic> createSalesStatsJson({
    double totalAmount = 1500000.0,
    int totalSales = 150,
    double todaySales = 50000.0,
    double yesterdaySales = 45000.0,
    double monthlySales = 800000.0,
    double yearSales = 1500000.0,
    double todayGrowth = 11.1,
    double monthlyGrowth = 15.5,
  }) {
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

  // ==================== INVOICE STATS ====================

  static InvoiceStatsModel createInvoiceStatsModel({
    int totalInvoices = 150,
    int todayInvoices = 5,
    int pendingInvoices = 30,
    int paidInvoices = 120,
    double averageInvoiceValue = 10000.0,
    double todayGrowth = 25.0,
  }) {
    return InvoiceStatsModel(
      totalInvoices: totalInvoices,
      todayInvoices: todayInvoices,
      pendingInvoices: pendingInvoices,
      paidInvoices: paidInvoices,
      averageInvoiceValue: averageInvoiceValue,
      todayGrowth: todayGrowth,
    );
  }

  static Map<String, dynamic> createInvoiceStatsJson({
    int totalInvoices = 150,
    int todayInvoices = 5,
    int pendingInvoices = 30,
    int paidInvoices = 120,
    double averageInvoiceValue = 10000.0,
    double todayGrowth = 25.0,
  }) {
    return {
      'totalInvoices': totalInvoices,
      'todayInvoices': todayInvoices,
      'pendingInvoices': pendingInvoices,
      'paidInvoices': paidInvoices,
      'averageInvoiceValue': averageInvoiceValue,
      'todayGrowth': todayGrowth,
    };
  }

  // ==================== PRODUCT STATS ====================

  static ProductStatsModel createProductStatsModel({
    int totalProducts = 250,
    int activeProducts = 230,
    int lowStockProducts = 15,
    int outOfStockProducts = 5,
    double totalInventoryValue = 5000000.0,
    int todayGrowth = 3,
  }) {
    return ProductStatsModel(
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      totalInventoryValue: totalInventoryValue,
      todayGrowth: todayGrowth,
    );
  }

  static Map<String, dynamic> createProductStatsJson({
    int totalProducts = 250,
    int activeProducts = 230,
    int lowStockProducts = 15,
    int outOfStockProducts = 5,
    double totalInventoryValue = 5000000.0,
    int todayGrowth = 3,
  }) {
    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'totalInventoryValue': totalInventoryValue,
      'todayGrowth': todayGrowth,
    };
  }

  // ==================== CUSTOMER STATS ====================

  static CustomerStatsModel createCustomerStatsModel({
    int totalCustomers = 85,
    int activeCustomers = 75,
    int newCustomersToday = 2,
    int newCustomersMonth = 12,
    double averageOrderValue = 17647.0,
    double todayGrowth = 5.5,
  }) {
    return CustomerStatsModel(
      totalCustomers: totalCustomers,
      activeCustomers: activeCustomers,
      newCustomersToday: newCustomersToday,
      newCustomersMonth: newCustomersMonth,
      averageOrderValue: averageOrderValue,
      todayGrowth: todayGrowth,
    );
  }

  static Map<String, dynamic> createCustomerStatsJson({
    int totalCustomers = 85,
    int activeCustomers = 75,
    int newCustomersToday = 2,
    int newCustomersMonth = 12,
    double averageOrderValue = 17647.0,
    double todayGrowth = 5.5,
  }) {
    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'newCustomersToday': newCustomersToday,
      'newCustomersMonth': newCustomersMonth,
      'averageOrderValue': averageOrderValue,
      'todayGrowth': todayGrowth,
    };
  }

  // ==================== EXPENSE STATS ====================

  static ExpenseStatsModel createExpenseStatsModel({
    double totalAmount = 500000.0,
    int totalExpenses = 45,
    double monthlyExpenses = 300000.0,
    double todayExpenses = 15000.0,
    int pendingExpenses = 5,
    int approvedExpenses = 40,
    double monthlyGrowth = 8.5,
    Map<String, double>? expensesByCategory,
  }) {
    return ExpenseStatsModel(
      totalAmount: totalAmount,
      totalExpenses: totalExpenses,
      monthlyExpenses: monthlyExpenses,
      todayExpenses: todayExpenses,
      pendingExpenses: pendingExpenses,
      approvedExpenses: approvedExpenses,
      monthlyGrowth: monthlyGrowth,
      expensesByCategory: expensesByCategory ?? {
        'Servicios': 150000.0,
        'Productos': 250000.0,
        'Personal': 100000.0,
      },
    );
  }

  static Map<String, dynamic> createExpenseStatsJson({
    double totalAmount = 500000.0,
    int totalExpenses = 45,
    double monthlyExpenses = 300000.0,
    double todayExpenses = 15000.0,
    int pendingExpenses = 5,
    int approvedExpenses = 40,
    double monthlyGrowth = 8.5,
    Map<String, double>? expensesByCategory,
  }) {
    return {
      'totalAmount': totalAmount,
      'totalExpenses': totalExpenses,
      'monthlyExpenses': monthlyExpenses,
      'todayExpenses': todayExpenses,
      'pendingExpenses': pendingExpenses,
      'approvedExpenses': approvedExpenses,
      'monthlyGrowth': monthlyGrowth,
      'expensesByCategory': expensesByCategory ?? {
        'Servicios': 150000.0,
        'Productos': 250000.0,
        'Personal': 100000.0,
      },
    };
  }

  // ==================== PROFITABILITY STATS ====================

  static ProfitabilityStatsModel createProfitabilityStatsModel({
    double totalRevenue = 1500000.0,
    double totalCOGS = 900000.0,
    double grossProfit = 600000.0,
    double grossMarginPercentage = 40.0,
    double netProfit = 500000.0,
    double netMarginPercentage = 33.33,
    double averageMarginPerSale = 40.0,
    List<ProductProfitabilityModel>? topProfitableProducts,
    List<ProductProfitabilityModel>? lowProfitableProducts,
    Map<String, double>? marginsByCategory,
    ProfitabilityTrendModel? trend,
  }) {
    return ProfitabilityStatsModel(
      totalRevenue: totalRevenue,
      totalCOGS: totalCOGS,
      grossProfit: grossProfit,
      grossMarginPercentage: grossMarginPercentage,
      netProfit: netProfit,
      netMarginPercentage: netMarginPercentage,
      averageMarginPerSale: averageMarginPerSale,
      topProfitableProducts: topProfitableProducts ?? createTopProfitableProducts(),
      lowProfitableProducts: lowProfitableProducts ?? createLowProfitableProducts(),
      marginsByCategory: marginsByCategory ?? {
        'Electronicos': 45.5,
        'Ropa': 55.0,
        'Alimentos': 25.5,
      },
      trend: trend ?? createProfitabilityTrendModel(),
    );
  }

  static Map<String, dynamic> createProfitabilityStatsJson({
    double totalRevenue = 1500000.0,
    double totalCOGS = 900000.0,
    double grossProfit = 600000.0,
    double grossMarginPercentage = 40.0,
    double netProfit = 500000.0,
    double netMarginPercentage = 33.33,
    double averageMarginPerSale = 40.0,
  }) {
    return {
      'totalRevenue': totalRevenue,
      'totalCOGS': totalCOGS,
      'grossProfit': grossProfit,
      'grossMarginPercentage': grossMarginPercentage,
      'netProfit': netProfit,
      'netMarginPercentage': netMarginPercentage,
      'averageMarginPerSale': averageMarginPerSale,
      'topProfitableProducts': [
        createProductProfitabilityJson(
          productId: 'prod-001',
          productName: 'Laptop Dell XPS 15',
          sku: 'DELL-XPS-15',
          categoryName: 'Electronicos',
          totalRevenue: 50000.0,
          totalCOGS: 25000.0,
          grossProfit: 25000.0,
          marginPercentage: 50.0,
          unitsSold: 5,
          averageSellingPrice: 10000.0,
          averageFifoCost: 5000.0,
        ),
        createProductProfitabilityJson(
          productId: 'prod-002',
          productName: 'iPhone 14 Pro',
          sku: 'IPHONE-14-PRO',
          categoryName: 'Electronicos',
          totalRevenue: 45000.0,
          totalCOGS: 24750.0,
          grossProfit: 20250.0,
          marginPercentage: 45.0,
          unitsSold: 3,
          averageSellingPrice: 15000.0,
          averageFifoCost: 8250.0,
        ),
      ],
      'lowProfitableProducts': [
        createProductProfitabilityJson(
          productId: 'prod-100',
          productName: 'Cable USB-C',
          sku: 'CABLE-USBC',
          categoryName: 'Accesorios',
          totalRevenue: 1000.0,
          totalCOGS: 900.0,
          grossProfit: 100.0,
          marginPercentage: 10.0,
          unitsSold: 50,
          averageSellingPrice: 20.0,
          averageFifoCost: 18.0,
        ),
      ],
      'marginsByCategory': {
        'Electronicos': 45.5,
        'Ropa': 55.0,
        'Alimentos': 25.5,
      },
      'trend': createProfitabilityTrendJson(),
    };
  }

  static List<ProductProfitabilityModel> createTopProfitableProducts() {
    return [
      createProductProfitabilityModel(
        productId: 'prod-001',
        productName: 'Laptop Dell XPS 15',
        sku: 'DELL-XPS-15',
        categoryName: 'Electronicos',
        totalRevenue: 50000.0,
        totalCOGS: 25000.0,
        grossProfit: 25000.0,
        marginPercentage: 50.0,
        unitsSold: 5,
        averageSellingPrice: 10000.0,
        averageFifoCost: 5000.0,
      ),
      createProductProfitabilityModel(
        productId: 'prod-002',
        productName: 'iPhone 14 Pro',
        sku: 'IPHONE-14-PRO',
        categoryName: 'Electronicos',
        totalRevenue: 45000.0,
        totalCOGS: 24750.0,
        grossProfit: 20250.0,
        marginPercentage: 45.0,
        unitsSold: 3,
        averageSellingPrice: 15000.0,
        averageFifoCost: 8250.0,
      ),
    ];
  }

  static List<ProductProfitabilityModel> createLowProfitableProducts() {
    return [
      createProductProfitabilityModel(
        productId: 'prod-100',
        productName: 'Cable USB-C',
        sku: 'CABLE-USBC',
        categoryName: 'Accesorios',
        totalRevenue: 1000.0,
        totalCOGS: 900.0,
        grossProfit: 100.0,
        marginPercentage: 10.0,
        unitsSold: 50,
        averageSellingPrice: 20.0,
        averageFifoCost: 18.0,
      ),
    ];
  }

  // ==================== PRODUCT PROFITABILITY ====================

  static ProductProfitabilityModel createProductProfitabilityModel({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String sku = 'TEST-SKU',
    String? categoryName = 'Test Category',
    double totalRevenue = 10000.0,
    double totalCOGS = 6000.0,
    double grossProfit = 4000.0,
    double marginPercentage = 40.0,
    int unitsSold = 10,
    double averageSellingPrice = 1000.0,
    double averageFifoCost = 600.0,
  }) {
    return ProductProfitabilityModel(
      productId: productId,
      productName: productName,
      sku: sku,
      categoryName: categoryName,
      totalRevenue: totalRevenue,
      totalCOGS: totalCOGS,
      grossProfit: grossProfit,
      marginPercentage: marginPercentage,
      unitsSold: unitsSold,
      averageSellingPrice: averageSellingPrice,
      averageFifoCost: averageFifoCost,
    );
  }

  static Map<String, dynamic> createProductProfitabilityJson({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String sku = 'TEST-SKU',
    String? categoryName = 'Test Category',
    double totalRevenue = 10000.0,
    double totalCOGS = 6000.0,
    double grossProfit = 4000.0,
    double marginPercentage = 40.0,
    int unitsSold = 10,
    double averageSellingPrice = 1000.0,
    double averageFifoCost = 600.0,
  }) {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'categoryName': categoryName,
      'totalRevenue': totalRevenue,
      'totalCOGS': totalCOGS,
      'grossProfit': grossProfit,
      'marginPercentage': marginPercentage,
      'unitsSold': unitsSold,
      'averageSellingPrice': averageSellingPrice,
      'averageFifoCost': averageFifoCost,
    };
  }

  // ==================== PROFITABILITY TREND ====================

  static ProfitabilityTrendModel createProfitabilityTrendModel({
    double previousPeriodGrossMargin = 38.5,
    double currentPeriodGrossMargin = 40.0,
    double marginGrowth = 1.5,
    bool isImproving = true,
    List<DailyMarginPointModel>? dailyMargins,
  }) {
    return ProfitabilityTrendModel(
      previousPeriodGrossMargin: previousPeriodGrossMargin,
      currentPeriodGrossMargin: currentPeriodGrossMargin,
      marginGrowth: marginGrowth,
      isImproving: isImproving,
      dailyMargins: dailyMargins ?? createDailyMargins(),
    );
  }

  static Map<String, dynamic> createProfitabilityTrendJson({
    double previousPeriodGrossMargin = 38.5,
    double currentPeriodGrossMargin = 40.0,
    double marginGrowth = 1.5,
    bool isImproving = true,
  }) {
    return {
      'previousPeriodGrossMargin': previousPeriodGrossMargin,
      'currentPeriodGrossMargin': currentPeriodGrossMargin,
      'marginGrowth': marginGrowth,
      'isImproving': isImproving,
      'dailyMargins': [
        createDailyMarginPointJson(
          date: DateTime.now().subtract(const Duration(days: 6)),
          grossMarginPercentage: 38.0,
          dailyRevenue: 50000.0,
          dailyCOGS: 31000.0,
        ),
        createDailyMarginPointJson(
          date: DateTime.now().subtract(const Duration(days: 5)),
          grossMarginPercentage: 39.0,
          dailyRevenue: 55000.0,
          dailyCOGS: 33550.0,
        ),
        createDailyMarginPointJson(
          date: DateTime.now().subtract(const Duration(days: 4)),
          grossMarginPercentage: 40.0,
          dailyRevenue: 60000.0,
          dailyCOGS: 36000.0,
        ),
      ],
    };
  }

  static List<DailyMarginPointModel> createDailyMargins() {
    return [
      createDailyMarginPointModel(
        date: DateTime.now().subtract(const Duration(days: 6)),
        grossMarginPercentage: 38.0,
        dailyRevenue: 50000.0,
        dailyCOGS: 31000.0,
      ),
      createDailyMarginPointModel(
        date: DateTime.now().subtract(const Duration(days: 5)),
        grossMarginPercentage: 39.0,
        dailyRevenue: 55000.0,
        dailyCOGS: 33550.0,
      ),
      createDailyMarginPointModel(
        date: DateTime.now().subtract(const Duration(days: 4)),
        grossMarginPercentage: 40.0,
        dailyRevenue: 60000.0,
        dailyCOGS: 36000.0,
      ),
    ];
  }

  // ==================== DAILY MARGIN POINT ====================

  static DailyMarginPointModel createDailyMarginPointModel({
    DateTime? date,
    double grossMarginPercentage = 40.0,
    double dailyRevenue = 50000.0,
    double dailyCOGS = 30000.0,
  }) {
    return DailyMarginPointModel(
      date: date ?? DateTime.now(),
      grossMarginPercentage: grossMarginPercentage,
      dailyRevenue: dailyRevenue,
      dailyCOGS: dailyCOGS,
    );
  }

  static Map<String, dynamic> createDailyMarginPointJson({
    DateTime? date,
    double grossMarginPercentage = 40.0,
    double dailyRevenue = 50000.0,
    double dailyCOGS = 30000.0,
  }) {
    return {
      'date': (date ?? DateTime.now()).toIso8601String(),
      'grossMarginPercentage': grossMarginPercentage,
      'dailyRevenue': dailyRevenue,
      'dailyCOGS': dailyCOGS,
    };
  }

  // ==================== PAYMENT METHODS BREAKDOWN ====================

  static List<PaymentMethodStats> createPaymentMethodsBreakdown() {
    return [
      const PaymentMethodStats(
        method: 'Efectivo',
        count: 45,
        totalAmount: 450000.0,
        percentage: 30.0,
      ),
      const PaymentMethodStats(
        method: 'Transferencia',
        count: 75,
        totalAmount: 750000.0,
        percentage: 50.0,
      ),
      const PaymentMethodStats(
        method: 'Tarjeta',
        count: 30,
        totalAmount: 300000.0,
        percentage: 20.0,
      ),
    ];
  }

  // ==================== INCOME TYPE BREAKDOWN ====================

  static IncomeTypeBreakdown createIncomeTypeBreakdown({
    double invoices = 1400000.0,
    double credits = 100000.0,
    double total = 1500000.0,
    double newInvoices = 1400000.0,
    double paymentsOnOldInvoices = 0.0,
  }) {
    return IncomeTypeBreakdown(
      invoices: invoices,
      newInvoices: newInvoices,
      paymentsOnOldInvoices: paymentsOnOldInvoices,
      credits: credits,
      total: total,
    );
  }

  // ==================== NOTIFICATIONS ====================

  static NotificationModel createNotificationModel({
    String id = 'notif-001',
    NotificationType type = NotificationType.invoice,
    String title = 'Test Notification',
    String message = 'This is a test notification',
    DateTime? timestamp,
    bool isRead = false,
    NotificationPriority priority = NotificationPriority.medium,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp ?? DateTime.now(),
      isRead: isRead,
      priority: priority,
      relatedId: relatedId,
      actionData: actionData,
    );
  }

  static List<NotificationModel> createNotificationList(int count) {
    return List.generate(
      count,
      (index) => createNotificationModel(
        id: 'notif-${index.toString().padLeft(3, '0')}',
        title: 'Notification $index',
        message: 'Message for notification $index',
        isRead: index % 3 == 0,
        type: NotificationType.values[index % NotificationType.values.length],
        priority: NotificationPriority.values[index % NotificationPriority.values.length],
      ),
    );
  }

  static Map<String, dynamic> createNotificationJson({
    String id = 'notif-001',
    String type = 'invoice',
    String title = 'Test Notification',
    String message = 'This is a test notification',
    DateTime? timestamp,
    bool isRead = false,
    String priority = 'medium',
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'isRead': isRead,
      'priority': priority,
      'relatedId': relatedId,
      'actionData': actionData,
    };
  }

  // ==================== RECENT ACTIVITY ====================

  static RecentActivityModel createRecentActivityModel({
    String id = 'activity-001',
    ActivityType type = ActivityType.invoice,
    String title = 'Test Activity',
    String description = 'This is a test activity',
    DateTime? timestamp,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) {
    return RecentActivityModel(
      id: id,
      type: type,
      title: title,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      relatedId: relatedId,
      metadata: metadata,
    );
  }

  static List<RecentActivityModel> createRecentActivityList(int count) {
    return List.generate(
      count,
      (index) => createRecentActivityModel(
        id: 'activity-${index.toString().padLeft(3, '0')}',
        title: 'Activity $index',
        description: 'Description for activity $index',
        type: ActivityType.values[index % ActivityType.values.length],
      ),
    );
  }

  static Map<String, dynamic> createRecentActivityJson({
    String id = 'activity-001',
    String type = 'invoice',
    String title = 'Test Activity',
    String description = 'This is a test activity',
    DateTime? timestamp,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }
}
