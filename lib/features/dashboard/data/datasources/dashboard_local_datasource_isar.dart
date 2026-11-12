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
import '../../../expenses/domain/entities/expense.dart' show ExpenseStatus;
import '../../../invoices/domain/entities/invoice.dart'
    show InvoiceStatus, PaymentMethod;
import '../../../invoices/domain/entities/invoice_payment.dart';
import '../../domain/services/dashboard_rules.dart';
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
  final BusinessClock? _businessClock;
  final DateTime Function()? _nowOverride;

  /// [businessClock] y [now] solo se pasan en pruebas; en la app salen de la
  /// zona horaria del negocio (`TenantDateTimeService`).
  DashboardLocalDataSourceIsar({
    IsarDatabase? database,
    BusinessClock? businessClock,
    DateTime Function()? now,
  })  : _database = database ?? IsarDatabase.instance,
        _businessClock = businessClock,
        _nowOverride = now;

  Isar get _isar => _database.database;

  /// "Ahora" en el reloj del negocio.
  DateTime _now() => _nowOverride?.call() ?? tenantNow();

  /// Instante → hora del reloj del negocio (no UTC, no la del equipo).
  DateTime _toBusinessTime(DateTime instant) {
    if (_businessClock != null) return _businessClock(instant);
    try {
      if (Get.isRegistered<TenantDateTimeService>()) {
        return Get.find<TenantDateTimeService>().toLocal(instant);
      }
    } catch (_) {}
    return instant.toLocal();
  }

  DateTime _businessDay(DateTime value) =>
      DashboardRules.businessDay(value, _toBusinessTime);

  bool _expenseCounts(IsarExpenseStatus status) =>
      DashboardRules.expenseCounts(ExpenseStatus.values.byName(status.name));

  /// Factura de Isar → lo que usan las reglas del tablero.
  SaleRecord _toSale(IsarInvoice inv) {
    var payments = IsarInvoice.decodePayments(inv.paymentsJson);
    if (payments.isEmpty && inv.paidAmount > 0) {
      // Factura guardada sin el detalle de pagos: lo único que se sabe es
      // cuánto se pagó y con qué método. Se toma como un pago en la fecha de
      // la factura para no perder ese dinero del tablero.
      payments = [
        InvoicePayment(
          id: '',
          amount: inv.paidAmount,
          paymentMethod: PaymentMethod.values.byName(inv.paymentMethod.name),
          paymentDate: inv.date,
          invoiceId: inv.serverId,
          createdById: '',
          organizationId: '',
          createdAt: inv.date,
          updatedAt: inv.date,
        ),
      ];
    }
    return SaleRecord(
      id: inv.serverId,
      status: InvoiceStatus.values.byName(inv.status.name),
      date: inv.date,
      total: inv.total,
      payments: payments,
      lines: _decodeLines(inv.itemsJson),
    );
  }

  List<SaleLine> _decodeLines(String? itemsJson) {
    if (itemsJson == null || itemsJson.isEmpty) return const [];
    try {
      final decoded = jsonDecode(itemsJson);
      if (decoded is! List) return const [];
      double? number(dynamic v) =>
          v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
      return [
        for (final item in decoded)
          if (item is Map)
            SaleLine(
              productId: item['productId']?.toString(),
              quantity: number(item['quantity']) ?? 0.0,
              unitPrice: number(item['unitPrice']) ?? 0.0,
              presentationFactor: number(item['presentationFactor']),
              unitCost: number(item['unitCost']),
              totalCost: number(item['totalCost']),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Quita las copias hechas sin conexión que ya tienen versión del servidor.
  List<IsarInvoice> _withoutOfflineDuplicates(List<IsarInvoice> invoices) {
    bool isOffline(IsarInvoice i) => i.serverId.startsWith('invoice_offline_');
    final realNumbers =
        invoices.where((i) => !isOffline(i)).map((i) => i.number).toSet();
    final result = invoices
        .where((i) => !(isOffline(i) && realNumbers.contains(i.number)))
        .toList();
    if (result.length != invoices.length) {
      AppLogger.w(
          'ISAR: filtrando ${invoices.length - result.length} facturas offline duplicadas',
          tag: 'DASHBOARD');
    }
    return result;
  }

  @override
  Future<DashboardStatsModel?> getCachedDashboardStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      // Mismas definiciones que el servidor: ver `DashboardRules`.
      final period = BusinessPeriod.fromRange(startDate, endDate);

      final results = await Future.wait([
        // 0: Facturas del período + las que pudieron recibir pagos en él
        _queryInvoiceCandidates(startDate, endDate),
        // 1: Gastos del período
        _queryExpenses(startDate, endDate),
        // 2: Bank accounts (para resolver nombres en paymentMethodsBreakdown)
        _isar.isarBankAccounts.filter().deletedAtIsNull().findAll(),
      ]);

      final candidates =
          _withoutOfflineDuplicates(results[0] as List<IsarInvoice>);
      final expenses = (results[1] as List<IsarExpense>)
          .where((e) => period.contains(_businessDay(e.date)))
          .toList();
      final bankAccounts = results[2] as List<IsarBankAccount>;

      final sales = [for (final inv in candidates) _toSale(inv)];

      // Mapa bankAccountId → nombre para resolver pagos por cuenta bancaria (ej: Nequi)
      final bankAccountNames = <String, String>{};
      for (final ba in bankAccounts) {
        bankAccountNames[ba.serverId] = ba.name;
      }

      final now = _now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // ⚡ Multi-currency: leer config de org
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

      // ───── COBRADO: pagos por FECHA DE PAGO (definición 1) ─────
      // Incluye los abonos hechos en el período a facturas de otra fecha y
      // deja por fuera anuladas, saldo a favor y el ajuste de Bre-B.
      final collected = DashboardRules.collectedPayments(
        invoices: sales,
        period: period,
        toBusinessTime: _toBusinessTime,
      );

      double totalRevenue = 0.0;
      double todaySales = 0.0;
      double monthlySales = 0.0;
      double paymentIncomeFromOldInvoices = 0.0;
      final paidInvoiceIds = <String>{};
      final paymentMethodsMap = <String, _PMAccumulator>{};
      final currencyMap = <String, _CurrencyAccumulator>{};

      for (final c in collected) {
        final p = c.payment;
        totalRevenue += p.amount;
        paidInvoiceIds.add(c.invoice.id);
        // "Hoy" y "este mes" incluyen el primer instante del día (antes una
        // fecha a medianoche quedaba por fuera).
        if (!c.day.isBefore(todayStart)) todaySales += p.amount;
        if (!c.day.isBefore(monthStart)) monthlySales += p.amount;
        if (c.onInvoiceOutsidePeriod) paymentIncomeFromOldInvoices += p.amount;

        // Mismo formato que el servidor: nombre de la cuenta ("Nequi") o el
        // value del método ("cash"); Bre-B aparte de las transferencias.
        final bankName = p.bankAccountId != null && p.bankAccountId!.isNotEmpty
            ? bankAccountNames[p.bankAccountId]
            : null;
        final methodKey = p.channel == 'breb'
            ? (bankName != null ? 'Bre-B · $bankName' : 'Bre-B')
            : (bankName ?? p.paymentMethod.value);
        final pm = paymentMethodsMap.putIfAbsent(
            methodKey, () => _PMAccumulator(methodKey));
        pm.count++;
        pm.totalAmount += p.amount;

        if (isMultiCurrencyEnabled && p.isForeignCurrency) {
          final acc = currencyMap.putIfAbsent(
              p.paymentCurrency!, () => _CurrencyAccumulator());
          acc.count++;
          acc.totalBase += p.amount;
          acc.totalForeign += (p.paymentCurrencyAmount ?? 0);
          acc.totalRate += (p.exchangeRate ?? 0);
        }
      }
      final totalPaidCount = paidInvoiceIds.length;
      if (paymentIncomeFromOldInvoices > 0) {
        AppLogger.d('ISAR: Abonos en facturas antiguas: \$$paymentIncomeFromOldInvoices', tag: 'DASHBOARD');
      }

      // ───── FACTURADO: facturas del período, sin anuladas ni borradores
      // (definición 2). Conteos como el servidor. ─────
      final billed = DashboardRules.billedInvoices(
        invoices: sales,
        period: period,
        toBusinessTime: _toBusinessTime,
      );
      double totalBilled = 0.0;
      int todayInvoicesCount = 0;
      int pendingInvoices = 0;
      int paidInvoices = 0;
      for (final inv in billed) {
        totalBilled += inv.total;
        if (inv.status == InvoiceStatus.paid) paidInvoices++;
        if (inv.status == InvoiceStatus.pending ||
            inv.status == InvoiceStatus.partiallyPaid ||
            inv.status == InvoiceStatus.overdue) {
          pendingInvoices++;
        }
        if (!_businessDay(inv.date).isBefore(todayStart)) todayInvoicesCount++;
      }
      // "Ingresos por facturas", igual que el servidor: lo facturado en el
      // período (pagado, parcial o a crédito) + abonos a facturas anteriores.
      final invoicesIncome = totalBilled + paymentIncomeFromOldInvoices;

      // Payment methods con porcentajes
      final paymentMethodsList = paymentMethodsMap.values.map((pm) => PaymentMethodStats(
        method: pm.method,
        count: pm.count,
        totalAmount: pm.totalAmount,
        percentage: totalRevenue > 0 ? (pm.totalAmount / totalRevenue) * 100 : 0,
      )).toList();

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

      // ───── GASTOS: solo aprobados o pagados (definición 3) ─────
      double totalExpensesAmount = 0.0;
      double monthlyExpensesAmount = 0.0;
      double todayExpensesAmount = 0.0;
      int pendingExpenses = 0;
      int approvedExpenses = 0;
      final expensesByCategory = <String, double>{};

      for (final exp in expenses) {
        if (_expenseCounts(exp.status)) {
          final day = _businessDay(exp.date);
          totalExpensesAmount += exp.amount;
          if (!day.isBefore(monthStart)) monthlyExpensesAmount += exp.amount;
          if (!day.isBefore(todayStart)) todayExpensesAmount += exp.amount;
          expensesByCategory[exp.categoryId] =
              (expensesByCategory[exp.categoryId] ?? 0.0) + exp.amount;
        }
        if (exp.status == IsarExpenseStatus.pending) pendingExpenses++;
        if (exp.status == IsarExpenseStatus.approved) approvedExpenses++;
      }

      // Conteos de productos y clientes dentro de la base (sin cargarlos).
      final productBase = _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .and()
          .not()
          .serverIdEqualTo('STATS_CACHE');
      final totalProducts = await productBase.count();
      final activeProducts =
          await productBase.and().statusEqualTo(IsarProductStatus.active).count();
      final outOfStockProducts =
          await productBase.and().stockLessThan(0, include: true).count();
      // Stock bajo compara dos columnas: se leen solo esas dos.
      final stocks = await productBase.stockProperty().findAll();
      final minStocks = await productBase.minStockProperty().findAll();
      int lowStockProducts = 0;
      for (var i = 0; i < stocks.length && i < minStocks.length; i++) {
        if (stocks[i] <= minStocks[i]) lowStockProducts++;
      }

      final customerBase = _isar.isarCustomers.filter().deletedAtIsNull();
      final totalCustomers = await customerBase.count();
      final activeCustomers =
          await customerBase.and().statusEqualTo(IsarCustomerStatus.active).count();
      final newCustomersMonth =
          await customerBase.and().createdAtGreaterThan(monthStart).count();
      final newCustomersToday =
          await customerBase.and().createdAtGreaterThan(todayStart).count();

      final averageOrderValue = totalPaidCount > 0 ? totalRevenue / totalPaidCount : 0.0;

      // ⚡ TREND por día del negocio dentro del rango (definición 5)
      final trendPoints = _buildTrend(
        period: period,
        collected: collected,
        billed: billed,
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

      // ───── UTILIDAD (definición 4): ventas devengadas del período contra
      // el costo de esas mismas líneas. Puede ser negativa. ─────
      final profitability =
          await _buildProfitability(sales, period, totalExpensesAmount);

      AppLogger.d(
        'Dashboard ISAR: cobrado=\$$totalRevenue, facturado=\$$totalBilled, NCs=\$$creditNotesTotal ($creditNotesCount), netRevenue=\$$netRevenue',
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
          totalInvoices: billed.length,
          todayInvoices: todayInvoicesCount,
          pendingInvoices: pendingInvoices,
          paidInvoices: paidInvoices,
          averageInvoiceValue: averageOrderValue,
          todayGrowth: 0.0,
        ),
        products: ProductStatsModel(
          totalProducts: totalProducts,
          activeProducts: activeProducts,
          lowStockProducts: lowStockProducts,
          outOfStockProducts: outOfStockProducts,
          totalInventoryValue: 0.0,
          todayGrowth: 0,
        ),
        customers: CustomerStatsModel(
          totalCustomers: totalCustomers,
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
        profitability: profitability,
        paymentMethodsBreakdown: paymentMethodsList,
        incomeTypeBreakdown: IncomeTypeBreakdown(
          invoices: invoicesIncome,
          newInvoices: totalBilled,
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
        grossMarginPercentage: profitability.grossMarginPercentage,
        netMarginPercentage: profitability.netMarginPercentage,
        trend: trendPoints,
      );
    } catch (e) {
      AppLogger.e('Error calculating dashboard stats from Isar: $e', tag: 'DASHBOARD');
      return null;
    }
  }

  // ─────── Helpers de paridad con backend ───────

  /// Construye puntos de tendencia por día del negocio dentro del rango,
  /// con las mismas definiciones de los totales.
  List<TrendPoint> _buildTrend({
    required BusinessPeriod period,
    required List<CollectedPayment> collected,
    required List<SaleRecord> billed,
    required List<IsarExpense> expenses,
  }) {
    final start = period.firstDay;
    final end = period.lastDay;
    if (start == null || end == null) return const [];

    // Mapas por YYYY-MM-DD para O(1) lookup.
    final revenueByDay = <String, double>{};
    final billedByDay = <String, double>{};
    final expensesByDay = <String, double>{};

    for (final c in collected) {
      final key = _isoDay(c.day);
      revenueByDay[key] = (revenueByDay[key] ?? 0) + c.payment.amount;
    }
    for (final inv in billed) {
      final key = _isoDay(_businessDay(inv.date));
      billedByDay[key] = (billedByDay[key] ?? 0) + inv.total;
    }
    for (final exp in expenses) {
      if (_expenseCounts(exp.status)) {
        final key = _isoDay(_businessDay(exp.date));
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
      // Por calendario (no +24 h): un cambio de hora no salta ni repite días.
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
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

  /// Margen de un día a cada lado del rango: la consulta filtra por instante
  /// y el día exacto (zona del negocio) se decide después en memoria.
  static const _edge = Duration(days: 1);

  /// Facturas que el tablero necesita para un período:
  /// - las que tienen fecha en el período, y
  /// - las de otra fecha que pudieron recibir un pago en él. Un pago toca la
  ///   factura, así que basta traer las modificadas desde el inicio del
  ///   período; el día de cada pago se revisa después con su fecha de pago.
  ///   (Antes se exigía que la última modificación cayera DENTRO del período
  ///   y un abono dejaba de verse en cuanto la factura volvía a cambiar.)
  Future<List<IsarInvoice>> _queryInvoiceCandidates(
      DateTime? startDate, DateTime? endDate) async {
    if (startDate == null) {
      // Sin inicio, cualquier factura puede tener pagos en el período.
      return _isar.isarInvoices.filter().deletedAtIsNull().findAll();
    }
    final byDate = await _queryInvoices(startDate, endDate);
    final touched = await _isar.isarInvoices
        .filter()
        .deletedAtIsNull()
        .updatedAtGreaterThan(startDate.subtract(_edge), include: true)
        .findAll();
    final seen = byDate.map((i) => i.id).toSet();
    return [...byDate, ...touched.where((i) => seen.add(i.id))];
  }

  /// ⚡ Query invoices con filtro de fecha nativo ISAR (usa índice @Index en date)
  Future<List<IsarInvoice>> _queryInvoices(DateTime? startDate, DateTime? endDate) async {
    final from = startDate?.subtract(_edge);
    final to = endDate?.add(_edge);
    if (from != null && to != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateBetween(from, to)
          .findAll();
    } else if (from != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateGreaterThan(from, include: true)
          .findAll();
    } else if (to != null) {
      return _isar.isarInvoices.filter()
          .deletedAtIsNull()
          .dateLessThan(to, include: true)
          .findAll();
    }
    return _isar.isarInvoices.filter().deletedAtIsNull().findAll();
  }

  /// ⚡ Query expenses con filtro de fecha nativo ISAR (usa índice @Index en date).
  /// Trae un día de margen a cada lado; quien llama filtra por día del negocio.
  Future<List<IsarExpense>> _queryExpenses(DateTime? startDate, DateTime? endDate) async {
    final from = startDate?.subtract(_edge);
    final to = endDate?.add(_edge);
    if (from != null && to != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateBetween(from, to)
          .findAll();
    } else if (from != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateGreaterThan(from, include: true)
          .findAll();
    } else if (to != null) {
      return _isar.isarExpenses.filter()
          .deletedAtIsNull()
          .dateLessThan(to, include: true)
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
      // Misma utilidad que muestra el tablero (definición 4).
      final period = BusinessPeriod.fromRange(startDate, endDate);
      final results = await Future.wait([
        _queryInvoices(startDate, endDate),
        _queryExpenses(startDate, endDate),
      ]);
      final sales = [
        for (final inv
            in _withoutOfflineDuplicates(results[0] as List<IsarInvoice>))
          _toSale(inv),
      ];
      double totalExpenses = 0.0;
      for (final exp in results[1] as List<IsarExpense>) {
        if (_expenseCounts(exp.status) &&
            period.contains(_businessDay(exp.date))) {
          totalExpenses += exp.amount;
        }
      }
      return await _buildProfitability(sales, period, totalExpenses);
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
      final period = BusinessPeriod.fromRange(startDate, endDate);
      final expenses = await _queryExpenses(startDate, endDate);

      // Criterio IDÉNTICO al de getCachedDashboardStats (aprobados o
      // pagados, por día del negocio): el gráfico por categoría y el total
      // de gastos siempre coinciden.
      final result = <String, double>{};
      for (final expense in expenses) {
        if (_expenseCounts(expense.status) &&
            period.contains(_businessDay(expense.date))) {
          result[expense.categoryId] =
              (result[expense.categoryId] ?? 0.0) + expense.amount;
        }
      }
      return result;
    } catch (e) {
      AppLogger.e('Error calculating offline expenses by category: $e', tag: 'DASHBOARD');
      return {};
    }
  }

  // ==================== UTILIDAD ====================

  /// Utilidad del período con la definición 4 (ver `DashboardRules.profit`).
  Future<ProfitabilityStatsModel> _buildProfitability(
    List<SaleRecord> sales,
    BusinessPeriod period,
    double expensesAmount,
  ) async {
    final accrued = sales
        .where((s) =>
            DashboardRules.isAccruedSale(s.status) &&
            period.contains(_businessDay(s.date)))
        .toList();
    final products = await _productsSoldIn(accrued);
    final currentCosts =
        _currentCostByProduct(products, await _batchCostByProduct(products));
    final profit = DashboardRules.profit(
      invoices: accrued,
      period: period,
      toBusinessTime: _toBusinessTime,
      expenses: expensesAmount,
      currentUnitCosts: currentCosts,
    );
    final byProduct = _productProfitability(accrued, products, currentCosts);

    AppLogger.d(
      'Utilidad offline: ventas=${profit.salesRevenue}, costo=${profit.costOfGoodsSold}, '
      'bruta=${profit.grossProfit}, neta=${profit.netProfit}',
      tag: 'DASHBOARD',
    );

    return ProfitabilityStatsModel(
      // Ventas devengadas (no lo cobrado), como la rentabilidad del servidor.
      totalRevenue: profit.salesRevenue,
      totalCOGS: profit.costOfGoodsSold,
      grossProfit: profit.grossProfit,
      grossMarginPercentage: profit.grossMarginPercentage,
      netProfit: profit.netProfit,
      netMarginPercentage: profit.netMarginPercentage,
      averageMarginPerSale: profit.averageMarginPerSale,
      topProfitableProducts: byProduct.topProfitableProducts,
      lowProfitableProducts: byProduct.lowProfitableProducts,
      marginsByCategory: byProduct.marginsByCategory,
      trend: const ProfitabilityTrendModel(
        previousPeriodGrossMargin: 0.0,
        currentPeriodGrossMargin: 0.0,
        marginGrowth: 0.0,
        isImproving: false,
        dailyMargins: [],
      ),
    );
  }

  /// Solo los productos vendidos en esas facturas, en una consulta.
  Future<List<IsarProduct>> _productsSoldIn(List<SaleRecord> sales) async {
    final ids = <String>{
      for (final sale in sales)
        for (final line in sale.lines)
          if (line.productId != null && line.productId!.isNotEmpty)
            line.productId!,
    }.toList();
    if (ids.isEmpty) return const [];
    return _isar.isarProducts
        .filter()
        .anyOf(ids, (q, String id) => q.serverIdEqualTo(id))
        .findAll();
  }

  /// Costo promedio ponderado por producto desde sus lotes con existencias
  /// (lectura asíncrona: no congela la pantalla).
  Future<Map<String, double>> _batchCostByProduct(List<IsarProduct> products) async {
    if (products.isEmpty) return const {};
    try {
      final ids = products.map((p) => p.serverId).toList();
      final batches = await _isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .currentQuantityGreaterThan(0)
          .and()
          .anyOf(ids, (q, String id) => q.productIdEqualTo(id))
          .findAll();
      final accum = <String, List<double>>{};
      for (final batch in batches) {
        if (batch.unitCost > 0) {
          final a = accum.putIfAbsent(batch.productId, () => [0.0, 0.0]);
          a[0] += batch.unitCost * batch.currentQuantity;
          a[1] += batch.currentQuantity;
        }
      }
      if (accum.isNotEmpty) {
        AppLogger.d('COGS: costos de ${accum.length} productos desde batches', tag: 'DASHBOARD');
      }
      return {
        for (final e in accum.entries)
          if (e.value[1] > 0) e.key: e.value[0] / e.value[1],
      };
    } catch (e) {
      AppLogger.w('COGS: error leyendo lotes, usando precios de costo: $e', tag: 'DASHBOARD');
      return const {};
    }
  }

  /// Costo ACTUAL por producto (por unidad base). Solo se usa en las líneas
  /// que no traen su costo guardado. Prioridad: costo promedio de los lotes
  /// con existencias; si no hay, el precio de costo del producto.
  Map<String, double> _currentCostByProduct(
    List<IsarProduct> products,
    Map<String, double> batchCosts,
  ) {
    final costs = <String, double>{};
    for (final product in products) {
      for (final price in product.prices) {
        if (price.type == IsarPriceType.cost && price.status == IsarPriceStatus.active) {
          costs[product.serverId] = price.finalAmount;
          break;
        }
      }
    }
    costs.addAll(batchCosts);
    return costs;
  }

  /// Utilidad por producto y por categoría de las ventas devengadas, con el
  /// mismo costo por línea que el total (`DashboardRules.lineCost`).
  _COGSResult _productProfitability(
    Iterable<SaleRecord> accruedSales,
    List<IsarProduct> products,
    Map<String, double> currentCosts,
  ) {
    final productNameMap = <String, String>{};
    final productCategoryMap = <String, String>{};
    for (final product in products) {
      productNameMap[product.serverId] = product.name;
      productCategoryMap[product.serverId] = product.categoryId;
    }

    final productProfitability = <String, _ProductProfit>{};
    for (final sale in accruedSales) {
      for (final line in sale.lines) {
        final productId = line.productId;
        if (productId == null || productId.isEmpty) continue;
        final acc = productProfitability.putIfAbsent(productId, () => _ProductProfit(
          productId: productId,
          productName: productNameMap[productId] ?? 'Producto',
          categoryId: productCategoryMap[productId] ?? '',
        ));
        acc.totalRevenue += line.revenue;
        acc.totalCOGS += DashboardRules.lineCost(line,
            currentUnitCost: currentCosts[productId]);
        acc.unitsSold += line.quantity.toInt();
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
      averageFifoCost: p.unitsSold > 0 ? p.totalCOGS / p.unitsSold : 0.0,
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
      averageFifoCost: p.unitsSold > 0 ? p.totalCOGS / p.unitsSold : 0.0,
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

    return _COGSResult(
      topProfitableProducts: topProducts,
      lowProfitableProducts: lowProducts,
      marginsByCategory: marginsByCategory,
    );
  }

  // ==================== HELPER METHODS ====================

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
  final List<ProductProfitabilityModel> topProfitableProducts;
  final List<ProductProfitabilityModel> lowProfitableProducts;
  final Map<String, double> marginsByCategory;

  _COGSResult({
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
  double totalRevenue = 0.0;
  double totalCOGS = 0.0;
  int unitsSold = 0;

  _ProductProfit({
    required this.productId,
    required this.productName,
    required this.categoryId,
  });

  double get grossProfit => totalRevenue - totalCOGS;
  double get marginPercentage => totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;
}
