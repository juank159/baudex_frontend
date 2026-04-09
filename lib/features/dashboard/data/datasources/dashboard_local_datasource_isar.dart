// lib/features/dashboard/data/datasources/dashboard_local_datasource_isar.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';
import '../../../expenses/data/models/isar/isar_expense.dart';
import '../../../products/data/models/isar/isar_product.dart';
import '../../../customers/data/models/isar/isar_customer.dart';
import '../../../notifications/data/models/isar/isar_notification.dart';
import '../../../inventory/data/models/isar/isar_inventory_batch.dart';
import '../../../settings/data/models/isar/isar_organization.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_activity_advanced.dart';
import '../../domain/entities/smart_notification.dart';
import '../models/dashboard_stats_model.dart';
import '../models/profitability_stats_model.dart';
import '../models/recent_activity_model.dart';
import '../models/notification_model.dart';
import 'dashboard_local_datasource.dart';

/// Implementacion de DashboardLocalDataSource usando ISAR
///
/// Calcula estadisticas del dashboard dinamicamente desde la base de datos local
/// en lugar de usar cache en SecureStorage
class DashboardLocalDataSourceIsar implements DashboardLocalDataSource {
  final IsarDatabase _database;

  DashboardLocalDataSourceIsar({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  @override
  Future<DashboardStatsModel?> getCachedDashboardStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      // ⚡ OPTIMIZACIÓN: Cargar las 4 colecciones EN PARALELO
      // Invoices y expenses usan filtro de fecha nativo de ISAR (campo indexado)
      // Products y customers no necesitan filtro de fecha
      final results = await Future.wait([
        // 0: Invoices con filtro de fecha nativo ISAR
        _queryInvoices(startDate, endDate),
        // 1: Expenses con filtro de fecha nativo ISAR
        _queryExpenses(startDate, endDate),
        // 2: Products (sin filtro de fecha)
        _isar.isarProducts.filter().deletedAtIsNull().findAll(),
        // 3: Customers (sin filtro de fecha)
        _isar.isarCustomers.filter().deletedAtIsNull().findAll(),
      ]);

      final invoices = results[0] as List<IsarInvoice>;
      final expenses = results[1] as List<IsarExpense>;
      final products = results[2] as List<IsarProduct>;
      final customers = results[3] as List<IsarCustomer>;

      // 🔍 DIAGNÓSTICO: Cuántas facturas retornó el filtro de fecha
      final offlineDuplicates = invoices.where((i) => i.serverId.startsWith('invoice_offline_')).toList();
      print('📊 ISAR Dashboard: ${invoices.length} facturas entre $startDate y $endDate'
          '${offlineDuplicates.isNotEmpty ? ' (⚠️ ${offlineDuplicates.length} DUPLICADOS OFFLINE)' : ''}');
      if (invoices.isNotEmpty) {
        final dates = invoices.map((i) => i.date).toList()..sort();
        print('📊 ISAR fechas: primera=${dates.first}, última=${dates.last}');
        final paidInvoices = invoices.where((i) =>
          i.status == IsarInvoiceStatus.paid || i.status == IsarInvoiceStatus.partiallyPaid).toList();
        final totalPaid = paidInvoices.fold<double>(0.0, (sum, i) => sum + i.paidAmount);
        print('📊 ISAR pagadas: ${paidInvoices.length} facturas, totalPaidAmount=$totalPaid');
      }

      // ⚡ FILTRAR duplicados offline para cálculos correctos
      // (registros con serverId 'invoice_offline_' que tienen un duplicado real del servidor)
      if (offlineDuplicates.isNotEmpty) {
        // Obtener números de factura de los duplicados offline
        final offlineNumbers = offlineDuplicates.map((i) => i.number).toSet();
        // Verificar cuáles ya tienen versión real (mismo número pero serverId sin prefijo offline)
        final realVersionExists = invoices.where((i) =>
          !i.serverId.startsWith('invoice_offline_') && offlineNumbers.contains(i.number)).toList();
        if (realVersionExists.isNotEmpty) {
          print('⚠️ ISAR: Filtrando ${offlineDuplicates.length} facturas offline duplicadas');
          invoices.removeWhere((i) => i.serverId.startsWith('invoice_offline_') &&
            realVersionExists.any((r) => r.number == i.number));
          print('📊 ISAR después de filtrar: ${invoices.length} facturas');
        }
      }

      // ⚡ SINGLE-PASS: Calcular todas las métricas de invoices en una sola iteración
      // Usar TenantDateTimeService para "hoy" correcto en timezone del tenant
      DateTime now;
      try {
        if (Get.isRegistered<TenantDateTimeService>()) {
          now = Get.find<TenantDateTimeService>().now();
        } else {
          now = DateTime.now();
        }
      } catch (_) {
        now = DateTime.now();
      }
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      double totalRevenue = 0.0;
      double todaySales = 0.0;
      double monthlySales = 0.0;
      double invoicesIncome = 0.0;
      int todayInvoicesCount = 0;
      int pendingInvoices = 0;
      int paidInvoices = 0;
      int totalPaidCount = 0;
      final paymentMethodsMap = <IsarPaymentMethod, _PMAccumulator>{};

      for (final inv in invoices) {
        final isPaid = inv.status == IsarInvoiceStatus.paid;
        final isPartial = inv.status == IsarInvoiceStatus.partiallyPaid;
        final isPending = inv.status == IsarInvoiceStatus.pending;

        if (isPaid || isPartial) {
          totalRevenue += inv.paidAmount;
          totalPaidCount++;
          if (inv.date.isAfter(todayStart)) todaySales += inv.paidAmount;
          if (inv.date.isAfter(monthStart)) monthlySales += inv.paidAmount;

          // Payment methods
          final method = inv.paymentMethod;
          paymentMethodsMap.putIfAbsent(method, () => _PMAccumulator(_paymentMethodToString(method)));
          paymentMethodsMap[method]!.count++;
          paymentMethodsMap[method]!.totalAmount += inv.paidAmount;
        }
        if (isPaid) {
          paidInvoices++;
          invoicesIncome += inv.paidAmount;
        }
        if (isPending) pendingInvoices++;
        if (inv.date.isAfter(todayStart)) todayInvoicesCount++;
      }

      // Payment methods con porcentajes
      final paymentMethodsList = paymentMethodsMap.values.map((pm) => PaymentMethodStats(
        method: pm.method,
        count: pm.count,
        totalAmount: pm.totalAmount,
        percentage: totalRevenue > 0 ? (pm.totalAmount / totalRevenue) * 100 : 0,
      )).toList();

      // ⚡ Multi-currency: leer config de org y calcular desglose por moneda
      bool isMultiCurrencyEnabled = false;
      String baseCurrency = 'COP';
      List<CurrencyBreakdownStats>? currencyBreakdown;
      try {
        final org = await _isar.isarOrganizations.where().findFirst();
        if (org != null) {
          final entity = org.toEntity();
          isMultiCurrencyEnabled = entity.multiCurrencyEnabled;
          baseCurrency = entity.currency;
        }
      } catch (_) {}

      if (isMultiCurrencyEnabled) {
        final currencyMap = <String, _CurrencyAccumulator>{};
        for (final inv in invoices) {
          final isPaid = inv.status == IsarInvoiceStatus.paid;
          final isPartial = inv.status == IsarInvoiceStatus.partiallyPaid;
          if (!isPaid && !isPartial) continue;

          final payments = IsarInvoice.decodePayments(inv.paymentsJson);
          for (final p in payments) {
            if (p.isForeignCurrency) {
              final curr = p.paymentCurrency!;
              currencyMap.putIfAbsent(curr, () => _CurrencyAccumulator());
              currencyMap[curr]!.count++;
              currencyMap[curr]!.totalBase += p.amount;
              currencyMap[curr]!.totalForeign += (p.paymentCurrencyAmount ?? 0);
              currencyMap[curr]!.totalRate += (p.exchangeRate ?? 0);
            }
          }
        }

        if (currencyMap.isNotEmpty) {
          currencyBreakdown = currencyMap.entries.map((e) {
            final acc = e.value;
            return CurrencyBreakdownStats(
              currency: e.key,
              count: acc.count,
              totalBaseAmount: acc.totalBase,
              totalForeignAmount: acc.totalForeign,
              avgRate: acc.count > 0 ? acc.totalRate / acc.count : 0,
              percentage: totalRevenue > 0 ? (acc.totalBase / totalRevenue) * 100 : 0,
            );
          }).toList();
        }
      }

      // ⚡ SINGLE-PASS: Calcular todas las métricas de expenses en una sola iteración
      double totalExpensesAmount = 0.0;
      double monthlyExpensesAmount = 0.0;
      double todayExpensesAmount = 0.0;
      int pendingExpenses = 0;
      int approvedExpenses = 0;
      final expensesByCategory = <String, double>{};

      for (final exp in expenses) {
        final isCountable = exp.status == IsarExpenseStatus.paid ||
            exp.status == IsarExpenseStatus.approved;
        if (isCountable) {
          totalExpensesAmount += exp.amount;
          if (exp.date.isAfter(monthStart)) monthlyExpensesAmount += exp.amount;
          if (exp.date.isAfter(todayStart)) todayExpensesAmount += exp.amount;
          expensesByCategory[exp.categoryId] =
              (expensesByCategory[exp.categoryId] ?? 0.0) + exp.amount;
        }
        if (exp.status == IsarExpenseStatus.pending) pendingExpenses++;
        if (exp.status == IsarExpenseStatus.approved) approvedExpenses++;
      }

      // ⚡ SINGLE-PASS: Products stats
      int activeProducts = 0;
      int lowStockProducts = 0;
      int outOfStockProducts = 0;
      for (final p in products) {
        if (p.status == IsarProductStatus.active) activeProducts++;
        if (p.stock <= p.minStock) lowStockProducts++;
        if (p.stock <= 0) outOfStockProducts++;
      }

      // ⚡ SINGLE-PASS: Customer stats
      int activeCustomers = 0;
      int newCustomersMonth = 0;
      int newCustomersToday = 0;
      for (final c in customers) {
        if (c.status == IsarCustomerStatus.active) activeCustomers++;
        if (c.createdAt.isAfter(monthStart)) newCustomersMonth++;
        if (c.createdAt.isAfter(todayStart)) newCustomersToday++;
      }

      final averageOrderValue = totalPaidCount > 0 ? totalRevenue / totalPaidCount : 0.0;

      // ⚡ CALCULAR COGS REAL desde precios de costo de productos
      final cogsResult = _calculateCOGSFromProducts(invoices, products);
      final totalCOGS = cogsResult.totalCOGS;
      final grossProfit = totalRevenue - totalCOGS;
      final grossMarginPercentage = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
      final netProfit = grossProfit - totalExpensesAmount;
      final netMarginPercentage = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
      final averageMarginPerSale = totalPaidCount > 0 ? grossProfit / totalPaidCount : 0.0;

      return DashboardStatsModel(
        sales: SalesStatsModel(
          totalAmount: totalRevenue,
          totalSales: totalPaidCount,
          todaySales: todaySales,
          yesterdaySales: 0.0,
          monthlySales: monthlySales,
          yearSales: totalRevenue,
          todayGrowth: 0.0,
          monthlyGrowth: 0.0,
        ),
        invoices: InvoiceStatsModel(
          totalInvoices: invoices.length,
          todayInvoices: todayInvoicesCount,
          pendingInvoices: pendingInvoices,
          paidInvoices: paidInvoices,
          averageInvoiceValue: averageOrderValue,
          todayGrowth: 0.0,
        ),
        products: ProductStatsModel(
          totalProducts: products.length,
          activeProducts: activeProducts,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
          totalInventoryValue: 0.0,
          todayGrowth: 0,
        ),
        customers: CustomerStatsModel(
          totalCustomers: customers.length,
          activeCustomers: activeCustomers,
          newCustomersToday: newCustomersToday,
          newCustomersMonth: newCustomersMonth,
          averageOrderValue: averageOrderValue,
          todayGrowth: 0.0,
        ),
        expenses: ExpenseStatsModel(
          totalAmount: totalExpensesAmount,
          totalExpenses: expenses.length,
          monthlyExpenses: monthlyExpensesAmount,
          todayExpenses: todayExpensesAmount,
          pendingExpenses: pendingExpenses,
          approvedExpenses: approvedExpenses,
          monthlyGrowth: 0.0,
          expensesByCategory: expensesByCategory,
        ),
        profitability: ProfitabilityStatsModel(
          totalRevenue: totalRevenue,
          totalCOGS: totalCOGS,
          grossProfit: grossProfit,
          grossMarginPercentage: grossMarginPercentage,
          netProfit: netProfit,
          netMarginPercentage: netMarginPercentage,
          averageMarginPerSale: averageMarginPerSale,
          topProfitableProducts: cogsResult.topProfitableProducts,
          lowProfitableProducts: cogsResult.lowProfitableProducts,
          marginsByCategory: cogsResult.marginsByCategory,
          trend: const ProfitabilityTrendModel(
            previousPeriodGrossMargin: 0.0,
            currentPeriodGrossMargin: 0.0,
            marginGrowth: 0.0,
            isImproving: false,
            dailyMargins: [],
          ),
        ),
        paymentMethodsBreakdown: paymentMethodsList,
        incomeTypeBreakdown: IncomeTypeBreakdown(
          invoices: invoicesIncome,
          credits: 0.0,
          total: invoicesIncome,
        ),
        currencyBreakdown: currencyBreakdown,
        multiCurrencyEnabled: isMultiCurrencyEnabled,
        baseCurrency: baseCurrency,
      );
    } catch (e) {
      AppLogger.e('Error calculating dashboard stats from Isar: $e', tag: 'DASHBOARD');
      return null;
    }
  }

  /// ⚡ Query invoices con filtro de fecha nativo ISAR (usa índice @Index en date)
  Future<List<IsarInvoice>> _queryInvoices(DateTime? startDate, DateTime? endDate) async {
    if (startDate != null && endDate != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateBetween(startDate, endDate)
          .findAll();
    } else if (startDate != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateGreaterThan(startDate, include: true)
          .findAll();
    } else if (endDate != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateLessThan(endDate, include: true)
          .findAll();
    }
    return _isar.isarInvoices.filter().deletedAtIsNull().findAll();
  }

  /// ⚡ Query expenses con filtro de fecha nativo ISAR (usa índice @Index en date)
  Future<List<IsarExpense>> _queryExpenses(DateTime? startDate, DateTime? endDate) async {
    if (startDate != null && endDate != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateBetween(startDate, endDate)
          .findAll();
    } else if (startDate != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateGreaterThan(startDate, include: true)
          .findAll();
    } else if (endDate != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateLessThan(endDate, include: true)
          .findAll();
    }
    return _isar.isarExpenses.filter().deletedAtIsNull().findAll();
  }

  @override
  Future<void> cacheDashboardStats(DashboardStatsModel stats) async {
    // No operation - stats are calculated dynamically from Isar
  }

  @override
  Future<List<RecentActivityModel>?> getCachedRecentActivity() async {
    return null;
  }

  @override
  Future<void> cacheRecentActivity(List<RecentActivityModel> activities) async {
    // No operation
  }

  @override
  Future<List<NotificationModel>?> getCachedNotifications() async {
    return null;
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    // No operation
  }

  @override
  Future<int?> getCachedUnreadNotificationsCount() async {
    try {
      final count = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .isReadEqualTo(false)
          .count();
      return count;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> cacheUnreadNotificationsCount(int count) async {
    // No operation - count is calculated dynamically
  }

  @override
  Future<void> clearCache() async {
    // No operation - no cache to clear
  }

  // ==================== OFFLINE ADVANCED METHODS ====================

  @override
  Future<ProfitabilityStatsModel?> getOfflineProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ⚡ Cargar invoices, expenses y products en paralelo
      final results = await Future.wait([
        _queryInvoices(startDate, endDate),
        _queryExpenses(startDate, endDate),
        _isar.isarProducts.filter().deletedAtIsNull().findAll(),
      ]);

      final invoices = results[0] as List<IsarInvoice>;
      final expenses = results[1] as List<IsarExpense>;
      final products = results[2] as List<IsarProduct>;

      double totalRevenue = 0.0;
      int paidCount = 0;
      for (final inv in invoices) {
        if (inv.status == IsarInvoiceStatus.paid ||
            inv.status == IsarInvoiceStatus.partiallyPaid) {
          totalRevenue += inv.paidAmount;
          paidCount++;
        }
      }

      double totalExpenses = 0.0;
      for (final exp in expenses) {
        if (exp.status == IsarExpenseStatus.paid ||
            exp.status == IsarExpenseStatus.approved) {
          totalExpenses += exp.amount;
        }
      }

      // ⚡ CALCULAR COGS REAL desde precios de costo de productos
      final cogsResult = _calculateCOGSFromProducts(invoices, products);
      final totalCOGS = cogsResult.totalCOGS;
      final grossProfit = totalRevenue - totalCOGS;
      final grossMarginPercentage = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
      final netProfit = grossProfit - totalExpenses;
      final netMarginPercentage = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
      final averageMarginPerSale = paidCount > 0 ? grossProfit / paidCount : 0.0;

      return ProfitabilityStatsModel(
        totalRevenue: totalRevenue,
        totalCOGS: totalCOGS,
        grossProfit: grossProfit,
        grossMarginPercentage: grossMarginPercentage,
        netProfit: netProfit,
        netMarginPercentage: netMarginPercentage,
        averageMarginPerSale: averageMarginPerSale,
        topProfitableProducts: cogsResult.topProfitableProducts,
        lowProfitableProducts: cogsResult.lowProfitableProducts,
        marginsByCategory: cogsResult.marginsByCategory,
        trend: const ProfitabilityTrendModel(
          previousPeriodGrossMargin: 0.0,
          currentPeriodGrossMargin: 0.0,
          marginGrowth: 0.0,
          isImproving: false,
          dailyMargins: [],
        ),
      );
    } catch (e) {
      AppLogger.e('Error calculating offline profitability: $e', tag: 'DASHBOARD');
      return null;
    }
  }

  @override
  Future<List<RecentActivityAdvanced>> getOfflineRecentActivities({int limit = 10}) async {
    try {
      final activities = <RecentActivityAdvanced>[];

      // 1. Facturas recientes
      final recentInvoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .sortByUpdatedAtDesc()
          .limit(5)
          .findAll();

      for (var inv in recentInvoices) {
        activities.add(RecentActivityAdvanced(
          id: 'inv_${inv.serverId}',
          type: _mapInvoiceStatusToActivityType(inv.status),
          category: ActivityCategory.financial,
          priority: ActivityPriority.medium,
          title: 'Factura #${inv.number}',
          description: 'Total: \$${inv.total.toStringAsFixed(0)} - ${_invoiceStatusLabel(inv.status)}',
          entityId: inv.serverId,
          entityType: 'invoice',
          metadata: {'amount': inv.total},
          icon: 'receipt_long',
          color: Colors.blue,
          userId: '',
          userName: 'Local',
          organizationId: '',
          createdAt: inv.updatedAt,
          updatedAt: inv.updatedAt,
        ));
      }

      // 2. Gastos recientes
      final recentExpenses = await _isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .sortByUpdatedAtDesc()
          .limit(5)
          .findAll();

      for (var exp in recentExpenses) {
        activities.add(RecentActivityAdvanced(
          id: 'exp_${exp.serverId}',
          type: _mapExpenseStatusToActivityType(exp.status),
          category: ActivityCategory.financial,
          priority: ActivityPriority.low,
          title: 'Gasto: ${exp.description.length > 40 ? '${exp.description.substring(0, 40)}...' : exp.description}',
          description: 'Monto: \$${exp.amount.toStringAsFixed(0)} - ${_expenseStatusLabel(exp.status)}',
          entityId: exp.serverId,
          entityType: 'expense',
          metadata: {'amount': exp.amount},
          icon: 'money_off',
          color: Colors.orange,
          userId: '',
          userName: 'Local',
          organizationId: '',
          createdAt: exp.updatedAt,
          updatedAt: exp.updatedAt,
        ));
      }

      // 3. Clientes recientes
      final recentCustomers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .sortByUpdatedAtDesc()
          .limit(3)
          .findAll();

      for (var cust in recentCustomers) {
        activities.add(RecentActivityAdvanced(
          id: 'cust_${cust.serverId}',
          type: ActivityType.customerCreated,
          category: ActivityCategory.customer,
          priority: ActivityPriority.low,
          title: 'Cliente: ${cust.firstName} ${cust.lastName}',
          description: 'Cliente ${_customerStatusLabel(cust.status)}',
          entityId: cust.serverId,
          entityType: 'customer',
          icon: 'person_add',
          color: Colors.green,
          userId: '',
          userName: 'Local',
          organizationId: '',
          createdAt: cust.updatedAt,
          updatedAt: cust.updatedAt,
        ));
      }

      // Ordenar por fecha descendente y limitar
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activities.take(limit).toList();
    } catch (e) {
      AppLogger.e('Error generating offline activities: $e', tag: 'DASHBOARD');
      return [];
    }
  }

  @override
  Future<List<SmartNotification>> getOfflineSmartNotifications({int limit = 10}) async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();

      return isarNotifications.map((n) {
        return SmartNotification(
          id: n.serverId,
          type: _mapIsarNotifTypeToSmartType(n.type),
          priority: _mapIsarNotifPriorityToSmartPriority(n.priority),
          status: n.isRead ? NotificationStatus.read : NotificationStatus.pending,
          channels: const [NotificationChannel.inApp],
          title: n.title,
          message: n.message,
          entityId: n.relatedId,
          icon: _notifTypeToIcon(n.type),
          color: _notifPriorityToColor(n.priority),
          userId: '',
          organizationId: '',
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
      }).toList();
    } catch (e) {
      AppLogger.e('Error loading offline notifications: $e', tag: 'DASHBOARD');
      return [];
    }
  }

  @override
  Future<Map<String, double>> getOfflineExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ⚡ Usar query con filtro de fecha nativo ISAR
      final expenses = await _queryExpenses(startDate, endDate);

      final result = <String, double>{};
      for (final expense in expenses) {
        if (expense.status == IsarExpenseStatus.approved ||
            expense.status == IsarExpenseStatus.paid) {
          result[expense.categoryId] = (result[expense.categoryId] ?? 0.0) + expense.amount;
        }
      }
      return result;
    } catch (e) {
      AppLogger.e('Error calculating offline expenses by category: $e', tag: 'DASHBOARD');
      return {};
    }
  }

  // ==================== COGS CALCULATION ====================

  /// Calcula COGS real desde inventory batches (FIFO) y precios de costo de productos en ISAR.
  /// Prioridad: 1) unitCost de inventory_batches (como hace el backend), 2) costPrice de product_prices
  _COGSResult _calculateCOGSFromProducts(List<IsarInvoice> invoices, List<IsarProduct> products) {
    // 1. Construir mapa productId → costPrice usando múltiples fuentes
    final costPriceMap = <String, double>{};
    final productNameMap = <String, String>{};
    final productCategoryMap = <String, String>{};

    for (final product in products) {
      productNameMap[product.serverId] = product.name;
      productCategoryMap[product.serverId] = product.categoryId;

      // Fallback: Buscar precio de costo en la lista de precios del producto
      for (final price in product.prices) {
        if (price.type == IsarPriceType.cost && price.status == IsarPriceStatus.active) {
          costPriceMap[product.serverId] = price.finalAmount;
          break;
        }
      }
    }

    // Fuente principal: Calcular costo promedio ponderado desde IsarInventoryBatch
    // Esto replica la lógica FIFO del backend que usa inventory_batches.unitCost
    try {
      final isar = _database.database;
      final batches = isar.isarInventoryBatchs.filter()
          .deletedAtIsNull()
          .currentQuantityGreaterThan(0)
          .findAllSync();

      // Mapa productId → (totalCost, totalQuantity) para promedio ponderado
      final batchCostAccum = <String, List<double>>{}; // [totalCost, totalQty]

      for (final batch in batches) {
        if (batch.unitCost > 0) {
          final accum = batchCostAccum.putIfAbsent(batch.productId, () => [0.0, 0.0]);
          accum[0] += batch.unitCost * batch.currentQuantity;
          accum[1] += batch.currentQuantity;
        }
      }

      // Sobrescribir costPriceMap con costos reales de batches (promedio ponderado)
      for (final entry in batchCostAccum.entries) {
        if (entry.value[1] > 0) {
          costPriceMap[entry.key] = entry.value[0] / entry.value[1];
        }
      }

      if (batchCostAccum.isNotEmpty) {
        print('📊 COGS: Usando costos de ${batchCostAccum.length} productos desde inventory_batches');
      }
    } catch (e) {
      print('⚠️ COGS: Error leyendo inventory batches, usando solo product prices: $e');
    }

    // 2. Para cada factura pagada, calcular COGS por item
    double totalCOGS = 0.0;
    final productProfitability = <String, _ProductProfit>{};

    for (final inv in invoices) {
      final isPaid = inv.status == IsarInvoiceStatus.paid ||
          inv.status == IsarInvoiceStatus.partiallyPaid;
      if (!isPaid) continue;
      if (inv.itemsJson == null || inv.itemsJson!.isEmpty) continue;

      try {
        final decoded = jsonDecode(inv.itemsJson!);
        if (decoded is! List) continue;

        for (final item in decoded) {
          if (item is! Map<String, dynamic>) continue;

          final productId = item['productId']?.toString();
          if (productId == null || productId.isEmpty) continue;

          final double quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          final double unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
          final costPrice = costPriceMap[productId];

          if (costPrice != null && costPrice > 0) {
            final itemCOGS = quantity * costPrice;
            final itemRevenue = quantity * unitPrice;
            totalCOGS += itemCOGS;

            // Acumular profitability por producto
            productProfitability.putIfAbsent(productId, () => _ProductProfit(
              productId: productId,
              productName: productNameMap[productId] ?? 'Producto',
              categoryId: productCategoryMap[productId] ?? '',
              costPrice: costPrice,
            ));
            productProfitability[productId]!.totalRevenue += itemRevenue;
            productProfitability[productId]!.totalCOGS += itemCOGS;
            productProfitability[productId]!.unitsSold += quantity.toInt();
          }
        }
      } catch (e) {
        // Skip invoice items que no se puedan decodificar
        continue;
      }
    }

    // 3. Generar top/low profitable products
    final profitableList = productProfitability.values.where((p) => p.totalRevenue > 0).toList();
    profitableList.sort((a, b) => b.grossProfit.compareTo(a.grossProfit));

    final topProducts = profitableList.take(5).map((p) => ProductProfitabilityModel(
      productId: p.productId,
      productName: p.productName,
      sku: '',
      categoryName: p.categoryId,
      totalRevenue: p.totalRevenue,
      totalCOGS: p.totalCOGS,
      grossProfit: p.grossProfit,
      marginPercentage: p.marginPercentage,
      unitsSold: p.unitsSold,
      averageSellingPrice: p.unitsSold > 0 ? p.totalRevenue / p.unitsSold : 0.0,
      averageFifoCost: p.costPrice,
    )).toList();

    final lowProducts = profitableList.reversed.take(5).map((p) => ProductProfitabilityModel(
      productId: p.productId,
      productName: p.productName,
      sku: '',
      categoryName: p.categoryId,
      totalRevenue: p.totalRevenue,
      totalCOGS: p.totalCOGS,
      grossProfit: p.grossProfit,
      marginPercentage: p.marginPercentage,
      unitsSold: p.unitsSold,
      averageSellingPrice: p.unitsSold > 0 ? p.totalRevenue / p.unitsSold : 0.0,
      averageFifoCost: p.costPrice,
    )).toList();

    // 4. Márgenes por categoría
    final categoryMargins = <String, double>{};
    for (final p in profitableList) {
      if (p.categoryId.isNotEmpty) {
        final catRevenue = categoryMargins['${p.categoryId}_rev'] ?? 0.0;
        final catCogs = categoryMargins['${p.categoryId}_cogs'] ?? 0.0;
        categoryMargins['${p.categoryId}_rev'] = catRevenue + p.totalRevenue;
        categoryMargins['${p.categoryId}_cogs'] = catCogs + p.totalCOGS;
      }
    }
    final marginsByCategory = <String, double>{};
    for (final key in categoryMargins.keys.where((k) => k.endsWith('_rev'))) {
      final catId = key.replaceAll('_rev', '');
      final rev = categoryMargins['${catId}_rev'] ?? 0.0;
      final cogs = categoryMargins['${catId}_cogs'] ?? 0.0;
      if (rev > 0) {
        marginsByCategory[catId] = ((rev - cogs) / rev) * 100;
      }
    }

    print('📊 COGS offline: total=$totalCOGS, products con costo=${costPriceMap.length}/${products.length}');

    return _COGSResult(
      totalCOGS: totalCOGS,
      topProfitableProducts: topProducts,
      lowProfitableProducts: lowProducts,
      marginsByCategory: marginsByCategory,
    );
  }

  // ==================== HELPER METHODS ====================

  String _paymentMethodToString(IsarPaymentMethod method) {
    switch (method) {
      case IsarPaymentMethod.cash:
        return 'Efectivo';
      case IsarPaymentMethod.credit:
        return 'Credito';
      case IsarPaymentMethod.creditCard:
        return 'Tarjeta de Credito';
      case IsarPaymentMethod.debitCard:
        return 'Tarjeta de Debito';
      case IsarPaymentMethod.bankTransfer:
        return 'Transferencia';
      case IsarPaymentMethod.check:
        return 'Cheque';
      case IsarPaymentMethod.clientBalance:
        return 'Saldo Cliente';
      case IsarPaymentMethod.other:
        return 'Otro';
    }
  }

  ActivityType _mapInvoiceStatusToActivityType(IsarInvoiceStatus status) {
    switch (status) {
      case IsarInvoiceStatus.paid:
        return ActivityType.invoicePaid;
      case IsarInvoiceStatus.partiallyPaid:
        return ActivityType.invoicePartiallyPaid;
      case IsarInvoiceStatus.cancelled:
        return ActivityType.invoiceCancelled;
      default:
        return ActivityType.invoiceCreated;
    }
  }

  String _invoiceStatusLabel(IsarInvoiceStatus status) {
    switch (status) {
      case IsarInvoiceStatus.paid:
        return 'Pagada';
      case IsarInvoiceStatus.partiallyPaid:
        return 'Pago parcial';
      case IsarInvoiceStatus.pending:
        return 'Pendiente';
      case IsarInvoiceStatus.cancelled:
        return 'Cancelada';
      default:
        return status.name;
    }
  }

  ActivityType _mapExpenseStatusToActivityType(IsarExpenseStatus status) {
    switch (status) {
      case IsarExpenseStatus.approved:
        return ActivityType.expenseApproved;
      case IsarExpenseStatus.paid:
        return ActivityType.expensePaid;
      case IsarExpenseStatus.rejected:
        return ActivityType.expenseRejected;
      default:
        return ActivityType.expenseCreated;
    }
  }

  String _expenseStatusLabel(IsarExpenseStatus status) {
    switch (status) {
      case IsarExpenseStatus.paid:
        return 'Pagado';
      case IsarExpenseStatus.approved:
        return 'Aprobado';
      case IsarExpenseStatus.pending:
        return 'Pendiente';
      case IsarExpenseStatus.rejected:
        return 'Rechazado';
      default:
        return status.name;
    }
  }

  String _customerStatusLabel(IsarCustomerStatus status) {
    switch (status) {
      case IsarCustomerStatus.active:
        return 'activo';
      case IsarCustomerStatus.inactive:
        return 'inactivo';
      default:
        return status.name;
    }
  }

  NotificationType _mapIsarNotifTypeToSmartType(IsarNotificationType type) {
    switch (type) {
      case IsarNotificationType.payment:
        return NotificationType.paymentReceived;
      case IsarNotificationType.invoice:
        return NotificationType.invoiceOverdue;
      case IsarNotificationType.lowStock:
        return NotificationType.stockLow;
      case IsarNotificationType.expense:
        return NotificationType.paymentReceived;
      case IsarNotificationType.sale:
        return NotificationType.salesMilestone;
      case IsarNotificationType.user:
        return NotificationType.newCustomer;
      case IsarNotificationType.system:
        return NotificationType.backupCompleted;
      case IsarNotificationType.reminder:
        return NotificationType.invoiceDueSoon;
    }
  }

  NotificationPriority _mapIsarNotifPriorityToSmartPriority(IsarNotificationPriority priority) {
    switch (priority) {
      case IsarNotificationPriority.low:
        return NotificationPriority.low;
      case IsarNotificationPriority.medium:
        return NotificationPriority.medium;
      case IsarNotificationPriority.high:
        return NotificationPriority.high;
      case IsarNotificationPriority.urgent:
        return NotificationPriority.critical;
    }
  }

  String _notifTypeToIcon(IsarNotificationType type) {
    switch (type) {
      case IsarNotificationType.payment:
        return 'payment';
      case IsarNotificationType.invoice:
        return 'schedule';
      case IsarNotificationType.lowStock:
        return 'warning';
      case IsarNotificationType.expense:
        return 'account_balance_wallet';
      case IsarNotificationType.sale:
        return 'trending_up';
      default:
        return 'notifications';
    }
  }

  Color _notifPriorityToColor(IsarNotificationPriority priority) {
    switch (priority) {
      case IsarNotificationPriority.urgent:
        return Colors.red;
      case IsarNotificationPriority.high:
        return Colors.orange;
      case IsarNotificationPriority.medium:
        return Colors.blue;
      case IsarNotificationPriority.low:
        return Colors.grey;
    }
  }
}

/// Helper para acumular payment method stats sin crear objetos inmutables en cada iteración
class _PMAccumulator {
  final String method;
  int count = 0;
  double totalAmount = 0.0;
  _PMAccumulator(this.method);
}

/// Helper para acumular stats de pagos por moneda extranjera
class _CurrencyAccumulator {
  int count = 0;
  double totalBase = 0.0;
  double totalForeign = 0.0;
  double totalRate = 0.0;
}

/// Resultado del cálculo de COGS
class _COGSResult {
  final double totalCOGS;
  final List<ProductProfitabilityModel> topProfitableProducts;
  final List<ProductProfitabilityModel> lowProfitableProducts;
  final Map<String, double> marginsByCategory;

  _COGSResult({
    required this.totalCOGS,
    required this.topProfitableProducts,
    required this.lowProfitableProducts,
    required this.marginsByCategory,
  });
}

/// Helper para acumular profitability por producto
class _ProductProfit {
  final String productId;
  final String productName;
  final String categoryId;
  final double costPrice;
  double totalRevenue = 0.0;
  double totalCOGS = 0.0;
  int unitsSold = 0;

  _ProductProfit({
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.costPrice,
  });

  double get grossProfit => totalRevenue - totalCOGS;
  double get marginPercentage => totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
}
