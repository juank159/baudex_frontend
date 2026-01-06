// lib/features/dashboard/data/datasources/dashboard_local_datasource_isar.dart
import 'package:isar/isar.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';
import '../../../expenses/data/models/isar/isar_expense.dart';
import '../../../products/data/models/isar/isar_product.dart';
import '../../../customers/data/models/isar/isar_customer.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../models/dashboard_stats_model.dart';
import '../models/profitability_stats_model.dart';
import '../models/recent_activity_model.dart';
import '../models/notification_model.dart';
import 'dashboard_local_datasource.dart';
import 'dart:convert';

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
  Future<DashboardStatsModel?> getCachedDashboardStats() async {
    try {
      // Obtener todas las entidades necesarias desde Isar
      final invoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .findAll();

      final expenses = await _isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .findAll();

      final products = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .findAll();

      final customers = await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .findAll();

      // Calcular estadisticas de ventas
      final totalRevenue = invoices
          .where((i) => i.status == IsarInvoiceStatus.paid ||
                       i.status == IsarInvoiceStatus.partiallyPaid)
          .fold(0.0, (sum, i) => sum + i.paidAmount);

      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
      final todayInvoices = invoices.where((i) => i.date.isAfter(todayStart));
      final todaySales = todayInvoices
          .where((i) => i.status == IsarInvoiceStatus.paid ||
                       i.status == IsarInvoiceStatus.partiallyPaid)
          .fold(0.0, (sum, i) => sum + i.paidAmount);

      final monthStart = DateTime.now().copyWith(day: 1, hour: 0, minute: 0, second: 0);
      final monthlyInvoices = invoices.where((i) => i.date.isAfter(monthStart));
      final monthlySales = monthlyInvoices
          .where((i) => i.status == IsarInvoiceStatus.paid ||
                       i.status == IsarInvoiceStatus.partiallyPaid)
          .fold(0.0, (sum, i) => sum + i.paidAmount);

      // Calcular estadisticas de gastos
      final totalExpensesAmount = expenses
          .where((e) => e.status == IsarExpenseStatus.paid)
          .fold(0.0, (sum, e) => sum + e.amount);

      final monthlyExpensesAmount = expenses
          .where((e) => e.status == IsarExpenseStatus.paid &&
                       e.date.isAfter(monthStart))
          .fold(0.0, (sum, e) => sum + e.amount);

      final todayExpensesAmount = expenses
          .where((e) => e.status == IsarExpenseStatus.paid &&
                       e.date.isAfter(todayStart))
          .fold(0.0, (sum, e) => sum + e.amount);

      // Payment methods breakdown
      final paymentMethodsMap = <IsarPaymentMethod, PaymentMethodStats>{};
      for (var invoice in invoices) {
        if (invoice.status == IsarInvoiceStatus.paid ||
            invoice.status == IsarInvoiceStatus.partiallyPaid) {
          final method = invoice.paymentMethod;
          if (!paymentMethodsMap.containsKey(method)) {
            paymentMethodsMap[method] = PaymentMethodStats(
              method: _paymentMethodToString(method),
              count: 0,
              totalAmount: 0.0,
              percentage: 0.0,
            );
          }
          paymentMethodsMap[method] = PaymentMethodStats(
            method: paymentMethodsMap[method]!.method,
            count: paymentMethodsMap[method]!.count + 1,
            totalAmount: paymentMethodsMap[method]!.totalAmount + invoice.paidAmount,
            percentage: paymentMethodsMap[method]!.percentage,
          );
        }
      }

      // Calcular percentages para payment methods
      final paymentMethodsList = paymentMethodsMap.values.map((pm) {
        return PaymentMethodStats(
          method: pm.method,
          count: pm.count,
          totalAmount: pm.totalAmount,
          percentage: totalRevenue > 0 ? (pm.totalAmount / totalRevenue) * 100 : 0,
        );
      }).toList();

      // Income breakdown
      final invoicesIncome = invoices
          .where((i) => i.status == IsarInvoiceStatus.paid)
          .fold(0.0, (sum, i) => sum + i.paidAmount);

      // TODO: Agregar creditos cuando exista el campo en IsarInvoice
      final creditsIncome = 0.0;

      // Expenses by category
      final expensesByCategory = <String, double>{};
      for (var expense in expenses) {
        if (expense.status == IsarExpenseStatus.paid) {
          final categoryId = expense.categoryId;
          expensesByCategory[categoryId] =
              (expensesByCategory[categoryId] ?? 0.0) + expense.amount;
        }
      }

      // Calcular estadisticas de productos
      final activeProducts = products.where((p) => p.status == IsarProductStatus.active).length;
      final lowStockProducts = products.where((p) =>
          p.stock <= p.minStock).length;
      final outOfStockProducts = products.where((p) =>
          p.stock <= 0).length;

      // TODO: Calcular valor total de inventario desde precios reales
      final totalInventoryValue = products
          .fold(0.0, (sum, p) => sum + (p.stock * 0.0)); // Necesita precio

      // Estadisticas de clientes
      final activeCustomers = customers.where((c) => c.status == IsarCustomerStatus.active).length;
      final newCustomersMonth = customers.where((c) => c.createdAt.isAfter(monthStart)).length;
      final newCustomersToday = customers.where((c) => c.createdAt.isAfter(todayStart)).length;

      // Calcular average order value
      final totalInvoicesCount = invoices.where((i) =>
          i.status == IsarInvoiceStatus.paid ||
          i.status == IsarInvoiceStatus.partiallyPaid).length;
      final averageOrderValue = totalInvoicesCount > 0
          ? totalRevenue / totalInvoicesCount
          : 0.0;

      // Construir DashboardStatsModel
      return DashboardStatsModel(
        sales: SalesStatsModel(
          totalAmount: totalRevenue,
          totalSales: totalInvoicesCount,
          todaySales: todaySales,
          yesterdaySales: 0.0, // TODO: Calcular cuando se necesite
          monthlySales: monthlySales,
          yearSales: totalRevenue, // TODO: Filtrar por año actual
          todayGrowth: 0.0, // TODO: Calcular comparando con ayer
          monthlyGrowth: 0.0, // TODO: Calcular comparando con mes anterior
        ),
        invoices: InvoiceStatsModel(
          totalInvoices: invoices.length,
          todayInvoices: todayInvoices.length,
          pendingInvoices: invoices.where((i) => i.status == IsarInvoiceStatus.pending).length,
          paidInvoices: invoices.where((i) => i.status == IsarInvoiceStatus.paid).length,
          averageInvoiceValue: totalInvoicesCount > 0
              ? totalRevenue / totalInvoicesCount
              : 0.0,
          todayGrowth: 0.0, // TODO: Calcular
        ),
        products: ProductStatsModel(
          totalProducts: products.length,
          activeProducts: activeProducts,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
          totalInventoryValue: totalInventoryValue,
          todayGrowth: 0, // TODO: Calcular
        ),
        customers: CustomerStatsModel(
          totalCustomers: customers.length,
          activeCustomers: activeCustomers,
          newCustomersToday: newCustomersToday,
          newCustomersMonth: newCustomersMonth,
          averageOrderValue: averageOrderValue,
          todayGrowth: 0.0, // TODO: Calcular
        ),
        expenses: ExpenseStatsModel(
          totalAmount: totalExpensesAmount,
          totalExpenses: expenses.length,
          monthlyExpenses: monthlyExpensesAmount,
          todayExpenses: todayExpensesAmount,
          pendingExpenses: expenses.where((e) => e.status == IsarExpenseStatus.pending).length,
          approvedExpenses: expenses.where((e) => e.status == IsarExpenseStatus.approved).length,
          monthlyGrowth: 0.0, // TODO: Calcular
          expensesByCategory: expensesByCategory,
        ),
        profitability: const ProfitabilityStatsModel(
          totalRevenue: 0.0, // Will be calculated below
          totalCOGS: 0.0, // TODO: Calcular COGS real cuando este implementado FIFO
          grossProfit: 0.0,
          grossMarginPercentage: 0.0,
          netProfit: 0.0,
          netMarginPercentage: 0.0,
          averageMarginPerSale: 0.0,
          topProfitableProducts: [],
          lowProfitableProducts: [],
          marginsByCategory: {},
          trend: ProfitabilityTrendModel(
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
          credits: creditsIncome,
          total: invoicesIncome + creditsIncome,
        ),
      );
    } catch (e) {
      print('Error calculating dashboard stats from Isar: $e');
      return null;
    }
  }

  @override
  Future<void> cacheDashboardStats(DashboardStatsModel stats) async {
    // No operation - stats are calculated dynamically from Isar
    // No necesitamos cachear porque siempre calculamos desde Isar
  }

  @override
  Future<List<RecentActivityModel>?> getCachedRecentActivity() async {
    // TODO: Implementar cuando se tenga modelo de actividad en Isar
    return null;
  }

  @override
  Future<void> cacheRecentActivity(List<RecentActivityModel> activities) async {
    // No operation for now
  }

  @override
  Future<List<NotificationModel>?> getCachedNotifications() async {
    // TODO: Implementar desde IsarNotification cuando se necesite
    return null;
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    // No operation for now
  }

  @override
  Future<int?> getCachedUnreadNotificationsCount() async {
    // TODO: Implementar cuando exista IsarNotification collection
    return 0;
  }

  @override
  Future<void> cacheUnreadNotificationsCount(int count) async {
    // No operation - count is calculated dynamically
  }

  @override
  Future<void> clearCache() async {
    // No operation - no cache to clear
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
}
