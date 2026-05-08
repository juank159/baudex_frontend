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
import '../../../bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../credit_notes/data/models/isar/isar_credit_note.dart';
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
        // 4: Bank accounts (para resolver nombres en paymentMethodsBreakdown)
        _isar.isarBankAccounts.filter().deletedAtIsNull().findAll(),
      ]);

      final invoices = results[0] as List<IsarInvoice>;
      final expenses = results[1] as List<IsarExpense>;
      final products = results[2] as List<IsarProduct>;
      final customers = results[3] as List<IsarCustomer>;
      final bankAccounts = results[4] as List<IsarBankAccount>;

      // Mapa bankAccountId → nombre para resolver pagos por cuenta bancaria (ej: Nequi)
      final bankAccountNames = <String, String>{};
      for (final ba in bankAccounts) {
        bankAccountNames[ba.serverId] = ba.name;
      }

      // ⚡ INGRESOS POR PAGOS: Buscar facturas fuera del rango de fecha que recibieron
      // pagos DENTRO del rango. Esto permite que abonos hechos hoy en facturas viejas
      // se reflejen en el dashboard de hoy.
      double paymentIncomeFromOldInvoices = 0.0;
      final paymentIncomeByMethod = <String, _PMAccumulator>{};
      if (startDate != null && endDate != null) {
        final invoiceServerIds = invoices.map((i) => i.serverId).toSet();
        // Facturas paid/partiallyPaid actualizadas en el rango pero creadas fuera
        final oldInvoicesWithRecentPayments = await _isar.isarInvoices.filter()
            .deletedAtIsNull()
            .group((q) => q
                .statusEqualTo(IsarInvoiceStatus.paid)
                .or()
                .statusEqualTo(IsarInvoiceStatus.partiallyPaid))
            .updatedAtBetween(startDate, endDate)
            .findAll();

        for (final inv in oldInvoicesWithRecentPayments) {
          // Excluir facturas ya incluidas por su fecha de creación
          if (invoiceServerIds.contains(inv.serverId)) continue;

          final payments = IsarInvoice.decodePayments(inv.paymentsJson);
          for (final p in payments) {
            // Solo contar pagos cuya fecha cae dentro del rango
            if (p.paymentDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                p.paymentDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
              paymentIncomeFromOldInvoices += p.amount;

              // Acumular método de pago
              String methodKey;
              if (p.bankAccountId != null && p.bankAccountId!.isNotEmpty &&
                  bankAccountNames.containsKey(p.bankAccountId)) {
                methodKey = bankAccountNames[p.bankAccountId]!;
              } else {
                methodKey = p.paymentMethod.value;
              }
              paymentIncomeByMethod.putIfAbsent(methodKey, () => _PMAccumulator(methodKey));
              paymentIncomeByMethod[methodKey]!.count++;
              paymentIncomeByMethod[methodKey]!.totalAmount += p.amount;
            }
          }
        }
        if (paymentIncomeFromOldInvoices > 0) {
          AppLogger.d('ISAR: Abonos en facturas antiguas: \$$paymentIncomeFromOldInvoices', tag: 'DASHBOARD');
        }
      }

      // Filtrar duplicados offline que ya tienen versión real del servidor.
      final offlineDuplicates = invoices.where((i) => i.serverId.startsWith('invoice_offline_')).toList();
      if (offlineDuplicates.isNotEmpty) {
        final offlineNumbers = offlineDuplicates.map((i) => i.number).toSet();
        final realVersionExists = invoices.where((i) =>
          !i.serverId.startsWith('invoice_offline_') && offlineNumbers.contains(i.number)).toList();
        if (realVersionExists.isNotEmpty) {
          AppLogger.w('ISAR: filtrando ${offlineDuplicates.length} facturas offline duplicadas', tag: 'DASHBOARD');
          invoices.removeWhere((i) => i.serverId.startsWith('invoice_offline_') &&
            realVersionExists.any((r) => r.number == i.number));
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
      double totalBilled = 0.0; // accrual basis: suma de invoice.total en el rango
      double todaySales = 0.0;
      double monthlySales = 0.0;
      double invoicesIncome = 0.0;
      int todayInvoicesCount = 0;
      int pendingInvoices = 0;
      int paidInvoices = 0;
      int totalPaidCount = 0;
      final paymentMethodsMap = <String, _PMAccumulator>{};

      for (final inv in invoices) {
        final isPaid = inv.status == IsarInvoiceStatus.paid;
        final isPartial = inv.status == IsarInvoiceStatus.partiallyPaid;
        final isPending = inv.status == IsarInvoiceStatus.pending;
        // `credited` y `partiallyCredited` significan que se aplicó una NC
        // posteriormente. El dinero SÍ entró cuando se pagó originalmente,
        // así que cuentan como revenue. La devolución se descuenta vía NC.
        final isCredited = inv.status == IsarInvoiceStatus.credited;
        final isPartiallyCredited =
            inv.status == IsarInvoiceStatus.partiallyCredited;

        // Todas las facturas no canceladas cuentan a lo facturado.
        if (inv.status != IsarInvoiceStatus.cancelled) {
          totalBilled += inv.total;
        }

        if (isPaid || isPartial || isCredited || isPartiallyCredited) {
          totalRevenue += inv.paidAmount;
          totalPaidCount++;
          if (inv.date.isAfter(todayStart)) todaySales += inv.paidAmount;
          if (inv.date.isAfter(monthStart)) monthlySales += inv.paidAmount;

          // Payment methods: desglosar desde pagos individuales (no inv.paymentMethod)
          // Esto permite ver "Nequi", "Bancolombia", etc. por nombre de cuenta bancaria
          // Usa mismo formato que el servidor: PaymentMethod.value ("cash") o nombre de cuenta ("Nequi")
          final payments = IsarInvoice.decodePayments(inv.paymentsJson);
          if (payments.isNotEmpty) {
            for (final p in payments) {
              String methodKey;
              if (p.bankAccountId != null && p.bankAccountId!.isNotEmpty &&
                  bankAccountNames.containsKey(p.bankAccountId)) {
                // Pago asociado a cuenta bancaria → usar nombre (ej: "Nequi")
                methodKey = bankAccountNames[p.bankAccountId]!;
              } else {
                // Pago sin cuenta bancaria → usar value del enum (ej: "cash", "credit_card")
                methodKey = p.paymentMethod.value;
              }
              paymentMethodsMap.putIfAbsent(methodKey, () => _PMAccumulator(methodKey));
              paymentMethodsMap[methodKey]!.count++;
              paymentMethodsMap[methodKey]!.totalAmount += p.amount;
            }
          } else {
            // Fallback: sin payments decodificados, usar método a nivel de factura
            final methodKey = _paymentMethodToString(inv.paymentMethod);
            paymentMethodsMap.putIfAbsent(methodKey, () => _PMAccumulator(methodKey));
            paymentMethodsMap[methodKey]!.count++;
            paymentMethodsMap[methodKey]!.totalAmount += inv.paidAmount;
          }
        }
        if (isPaid || isCredited) {
          paidInvoices++;
          invoicesIncome += inv.paidAmount;
        }
        if (isPending) pendingInvoices++;
        if (inv.date.isAfter(todayStart)) todayInvoicesCount++;
      }

      // ⚡ Sumar ingresos por pagos en facturas antiguas al revenue total
      if (paymentIncomeFromOldInvoices > 0) {
        totalRevenue += paymentIncomeFromOldInvoices;
        todaySales += paymentIncomeFromOldInvoices;
        invoicesIncome += paymentIncomeFromOldInvoices;
        // Merge payment methods
        for (final entry in paymentIncomeByMethod.entries) {
          paymentMethodsMap.putIfAbsent(entry.key, () => _PMAccumulator(entry.key));
          paymentMethodsMap[entry.key]!.count += entry.value.count;
          paymentMethodsMap[entry.key]!.totalAmount += entry.value.totalAmount;
        }
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

      // ⚡ TREND por día dentro del rango (mismo formato que el backend)
      final trendPoints = _buildTrend(
        startDate: startDate,
        endDate: endDate,
        invoices: invoices,
        expenses: expenses,
      );

      // ⚡ RECEIVABLES con semáforo (global, no filtrado por fecha)
      final receivables = await _buildReceivables(now);

      // ⚡ NOTAS DE CRÉDITO APLICADAS en el rango (paridad con backend dashboard)
      // Filtra NCs confirmed (= aplicadas en este sistema) cuyo appliedAt
      // (o date como fallback) cae dentro del rango. Suma el total devuelto.
      final isar = _database.database;
      final creditNotesAll = await isar.isarCreditNotes
          .filter()
          .deletedAtIsNull()
          .and()
          .statusEqualTo(IsarCreditNoteStatus.confirmed)
          .findAll();
      double creditNotesTotal = 0.0;
      int creditNotesCount = 0;
      final ncRangeStart = startDate ?? DateTime(1970);
      final ncRangeEnd = endDate ?? DateTime(2100);
      for (final cn in creditNotesAll) {
        // Usar appliedAt si existe (más correcto contablemente), si no date.
        final ref = cn.appliedAt ?? cn.date;
        if (!ref.isBefore(ncRangeStart) && !ref.isAfter(ncRangeEnd)) {
          creditNotesTotal += cn.total;
          creditNotesCount++;
        }
      }

      // Phase 1B: ingreso neto = lo cobrado menos las notas de crédito.
      // Refleja el dinero que efectivamente se quedó la empresa.
      final netRevenue = totalRevenue - creditNotesTotal;

      // ⚡ CALCULAR COGS REAL desde precios de costo de productos
      final cogsResult = _calculateCOGSFromProducts(invoices, products);
      final totalCOGS = cogsResult.totalCOGS;
      // Phase 1B: profitabilidad sobre netRevenue (no totalRevenue) para que
      // los márgenes reflejen la realidad económica cuando hay devoluciones.
      final grossProfit = netRevenue - totalCOGS;
      final grossMarginPercentage = netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0.0;
      final netProfit = grossProfit - totalExpensesAmount;
      final netMarginPercentage = netRevenue > 0 ? (netProfit / netRevenue) * 100 : 0.0;
      final averageMarginPerSale = totalPaidCount > 0 ? grossProfit / totalPaidCount : 0.0;

      AppLogger.d(
        'Dashboard ISAR: revenue=\$$totalRevenue, NCs=\$$creditNotesTotal ($creditNotesCount), netRevenue=\$$netRevenue',
        tag: 'DASHBOARD',
      );

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
          newInvoices: invoicesIncome - paymentIncomeFromOldInvoices,
          paymentsOnOldInvoices: paymentIncomeFromOldInvoices,
          credits: 0.0,
          total: invoicesIncome,
        ),
        currencyBreakdown: currencyBreakdown,
        multiCurrencyEnabled: isMultiCurrencyEnabled,
        baseCurrency: baseCurrency,
        receivables: receivables,
        totalCollected: totalRevenue,
        totalBilled: totalBilled,
        creditNotesTotal: creditNotesTotal,
        creditNotesCount: creditNotesCount,
        netRevenue: netRevenue,
        grossMarginPercentage: grossMarginPercentage.toDouble(),
        netMarginPercentage: netMarginPercentage.toDouble(),
        trend: trendPoints,
      );
    } catch (e) {
      AppLogger.e('Error calculating dashboard stats from Isar: $e', tag: 'DASHBOARD');
      return null;
    }
  }

  // ─────── Helpers de paridad con backend ───────

  /// Construye puntos de tendencia por día dentro del rango.
  List<TrendPoint> _buildTrend({
    DateTime? startDate,
    DateTime? endDate,
    required List<IsarInvoice> invoices,
    required List<IsarExpense> expenses,
  }) {
    if (startDate == null || endDate == null) return const [];
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Mapas por YYYY-MM-DD para O(1) lookup.
    final revenueByDay = <String, double>{};
    final billedByDay = <String, double>{};
    final expensesByDay = <String, double>{};

    for (final inv in invoices) {
      final key = _isoDay(inv.date);
      if (inv.status != IsarInvoiceStatus.cancelled) {
        billedByDay[key] = (billedByDay[key] ?? 0) + inv.total;
      }
      if (inv.status == IsarInvoiceStatus.paid ||
          inv.status == IsarInvoiceStatus.partiallyPaid) {
        final payments = IsarInvoice.decodePayments(inv.paymentsJson);
        for (final p in payments) {
          final pKey = _isoDay(p.paymentDate);
          revenueByDay[pKey] = (revenueByDay[pKey] ?? 0) + p.amount;
        }
      }
    }

    for (final exp in expenses) {
      if (exp.status == IsarExpenseStatus.approved ||
          exp.status == IsarExpenseStatus.paid) {
        final key = _isoDay(exp.date);
        expensesByDay[key] = (expensesByDay[key] ?? 0) + exp.amount;
      }
    }

    final points = <TrendPoint>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final key = _isoDay(cursor);
      points.add(TrendPoint(
        date: cursor,
        revenue: revenueByDay[key] ?? 0,
        billed: billedByDay[key] ?? 0,
        expenses: expensesByDay[key] ?? 0,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }
    return points;
  }

  String _isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Calcula receivables globales con semáforo desde ISAR.
  Future<ReceivablesStats> _buildReceivables(DateTime now) async {
    final pending = await _isar.isarInvoices.filter()
        .deletedAtIsNull()
        .group((q) => q
            .statusEqualTo(IsarInvoiceStatus.pending)
            .or()
            .statusEqualTo(IsarInvoiceStatus.partiallyPaid))
        .balanceDueGreaterThan(0)
        .findAll();

    final today = DateTime(now.year, now.month, now.day);
    int curCount = 0, dueCount = 0, overCount = 0;
    double curTotal = 0, dueTotal = 0, overTotal = 0;
    int maxDaysOverdue = 0;

    final byCustomer = <String, _DebtorAcc>{};

    for (final inv in pending) {
      final bal = inv.balanceDue;
      // IsarInvoice.dueDate es late (no-null). Con saldo pendiente siempre hay una
      // fecha de vencimiento — nunca necesitamos el fallback a 'current'.
      final dueDate = inv.dueDate;
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final diff = today.difference(dueDay).inDays;
      final daysOverdue = diff > 0 ? diff : 0;
      final String urgency;
      {
        if (dueDay.isBefore(today)) {
          urgency = 'overdue';
        } else if (!dueDay.isAfter(today.add(const Duration(days: 7)))) {
          urgency = 'dueSoon';
        } else {
          urgency = 'current';
        }
      }

      switch (urgency) {
        case 'overdue':
          overCount++;
          overTotal += bal;
          if (daysOverdue > maxDaysOverdue) maxDaysOverdue = daysOverdue;
          break;
        case 'dueSoon':
          dueCount++;
          dueTotal += bal;
          break;
        default:
          curCount++;
          curTotal += bal;
      }

      final customerId = inv.customerId;
      byCustomer.putIfAbsent(customerId, () => _DebtorAcc());
      final acc = byCustomer[customerId]!;
      acc.count++;
      acc.total += bal;
      if (daysOverdue > acc.maxDaysOverdue) acc.maxDaysOverdue = daysOverdue;
    }

    // Top 3 deudores
    final sortedDebtors = byCustomer.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final topDebtors = <TopDebtor>[];
    for (final entry in sortedDebtors.take(3)) {
      final customer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(entry.key)
          .findFirst();
      final name = customer != null
          ? [customer.firstName, customer.lastName].where((s) => s.isNotEmpty).join(' ')
          : 'Sin nombre';
      topDebtors.add(TopDebtor(
        customerId: entry.key,
        customerName: name.isEmpty ? 'Sin nombre' : name,
        invoiceCount: entry.value.count,
        totalBalance: entry.value.total,
        maxDaysOverdue: entry.value.maxDaysOverdue,
      ));
    }

    return ReceivablesStats(
      total: curTotal + dueTotal + overTotal,
      count: curCount + dueCount + overCount,
      current: ReceivablesBucket(count: curCount, total: curTotal),
      dueSoon: ReceivablesBucket(count: dueCount, total: dueTotal),
      overdue: ReceivablesBucket(count: overCount, total: overTotal, maxDaysOverdue: maxDaysOverdue),
      topDebtors: topDebtors,
    );
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
        AppLogger.d('COGS: costos de ${batchCostAccum.length} productos desde batches', tag: 'DASHBOARD');
      }
    } catch (e) {
      AppLogger.w('COGS: error leyendo inventory batches, usando product prices: $e', tag: 'DASHBOARD');
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

    AppLogger.d(
      'COGS offline: total=$totalCOGS, products con costo=${costPriceMap.length}/${products.length}',
      tag: 'DASHBOARD',
    );

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

/// Helper para acumular deudores del semáforo de receivables
class _DebtorAcc {
  int count = 0;
  double total = 0.0;
  int maxDaysOverdue = 0;
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
