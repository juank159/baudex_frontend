// lib/features/dashboard/presentation/controllers/dashboard_controller.dart
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/profitability_stats_model.dart';
import '../../../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/entities/recent_activity_advanced.dart' hide ActivityType;
import '../../domain/entities/smart_notification.dart';
import '../../domain/entities/notification.dart' as dashboard;
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';

class DashboardController extends GetxController
    with SyncAutoRefreshMixin {
  final GetDashboardStatsUseCase _getDashboardStatsUseCase;
  final GetRecentActivityUseCase _getRecentActivityUseCase;
  final GetDashboardNotificationsUseCase _getNotificationsUseCase;
  final MarkDashboardNotificationAsReadUseCase _markNotificationAsReadUseCase;
  final GetUnreadNotificationsCountUseCase _getUnreadNotificationsCountUseCase;
  final GetProfitabilityStatsUseCase _getProfitabilityStatsUseCase;

  DashboardController({
    required GetDashboardStatsUseCase getDashboardStatsUseCase,
    required GetRecentActivityUseCase getRecentActivityUseCase,
    required GetDashboardNotificationsUseCase getNotificationsUseCase,
    required MarkDashboardNotificationAsReadUseCase markNotificationAsReadUseCase,
    required GetUnreadNotificationsCountUseCase getUnreadNotificationsCountUseCase,
    required GetProfitabilityStatsUseCase getProfitabilityStatsUseCase,
  }) : _getDashboardStatsUseCase = getDashboardStatsUseCase,
       _getRecentActivityUseCase = getRecentActivityUseCase,
       _getNotificationsUseCase = getNotificationsUseCase,
       _markNotificationAsReadUseCase = markNotificationAsReadUseCase,
       _getUnreadNotificationsCountUseCase = getUnreadNotificationsCountUseCase,
       _getProfitabilityStatsUseCase = getProfitabilityStatsUseCase;

  // Reactive state
  final _isLoadingStats = false.obs;
  final _isLoadingActivity = false.obs;
  final _isLoadingNotifications = false.obs;
  final _isLoadingExpenseChart = false.obs;
  final _isLoadingProfitability = false.obs;
  final _dashboardStats = Rxn<DashboardStats>();
  final _profitabilityStats = Rxn<ProfitabilityStats>();
  final _recentActivities = <RecentActivity>[].obs;
  final _recentActivitiesAdvanced = <RecentActivityAdvanced>[].obs;
  final _notifications = <dashboard.Notification>[].obs;
  final _smartNotifications = <SmartNotification>[].obs;
  final _unreadNotificationsCount = 0.obs;

  // Guard para evitar cargas concurrentes
  bool _isLoadingData = false;

  // Guard para evitar updates post-dispose
  bool _isDisposed = false;
  bool get _isAlive => !_isDisposed && !isClosed;

  // Error states
  final _statsError = Rxn<String>();
  final _activityError = Rxn<String>();
  final _notificationsError = Rxn<String>();
  final _profitabilityError = Rxn<String>();

  // Filters
  final _selectedDateRange = Rxn<DateTimeRange>();
  final _selectedActivityTypes = <ActivityType>[].obs;
  final _selectedPeriod = 'hoy'.obs;
  int _dataVersion = 0; // Previene race condition al cambiar filtros rápido

  // Getters
  bool get isLoadingStats => _isLoadingStats.value;
  bool get isLoadingActivity => _isLoadingActivity.value;
  bool get isLoadingNotifications => _isLoadingNotifications.value;
  bool get isLoadingExpenseChart => _isLoadingExpenseChart.value;
  bool get isLoadingProfitability => _isLoadingProfitability.value;
  bool get isLoading =>
      isLoadingStats || isLoadingActivity || isLoadingNotifications || isLoadingExpenseChart || isLoadingProfitability;

  DashboardStats? get dashboardStats => _dashboardStats.value;
  ProfitabilityStats? get profitabilityStats => _profitabilityStats.value;
  List<RecentActivity> get recentActivities => _recentActivities;
  List<RecentActivityAdvanced> get recentActivitiesAdvanced => _recentActivitiesAdvanced;
  List<dashboard.Notification> get notifications => _notifications;
  List<SmartNotification> get smartNotifications => _smartNotifications;
  int get unreadNotificationsCount => _unreadNotificationsCount.value;

  String? get statsError => _statsError.value;
  String? get activityError => _activityError.value;
  String? get notificationsError => _notificationsError.value;
  String? get profitabilityError => _profitabilityError.value;

  DateTimeRange? get selectedDateRange => _selectedDateRange.value;
  List<ActivityType> get selectedActivityTypes => _selectedActivityTypes;
  String get selectedPeriod => _selectedPeriod.value;

  // Quick stats getters
  double get totalRevenue => dashboardStats?.sales.totalAmount ?? 0.0;
  int get totalInvoices => dashboardStats?.invoices.totalInvoices ?? 0;
  int get pendingInvoices => dashboardStats?.invoices.pendingInvoices ?? 0;
  int get totalProducts => dashboardStats?.products.totalProducts ?? 0;
  int get lowStockProducts =>
      dashboardStats?.products.lowStockProducts ?? 0;
  double get totalExpenses => dashboardStats?.expenses.totalAmount ?? 0.0;
  
  // ✅ Calcular ganancia bruta correcta (Revenue - COGS)
  double get realGrossProfit => profitabilityStats?.grossProfit ?? 0.0;
  
  // ✅ COGS real del backend (o 0 si no está disponible)
  double get totalCOGS => profitabilityStats?.totalCOGS ?? 0.0;

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();
    print('🚀 DashboardController: onInit() - Controlador iniciado');

    // Establecer el rango de fechas para HOY
    final now = Get.find<TenantDateTimeService>().now();
    _selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    print('🔄 Rango de fechas inicial (HOY): ${_selectedDateRange.value?.start} - ${_selectedDateRange.value?.end}');

    // ✅ Marcar como cargando desde el inicio
    _isLoadingStats.value = true;
    _isLoadingActivity.value = true;
    _isLoadingNotifications.value = true;
    _isLoadingProfitability.value = true;
  }

  @override
  void onReady() {
    super.onReady();
    print('🚀 DashboardController: onReady() - Widget construido, cargando datos...');

    // ✅ Cargar datos inmediatamente cuando el widget está listo (SIN DELAY, SIN DOBLE CARGA)
    _loadInitialData();
  }

  @override
  Future<void> onSyncCompleted() async {
    if (!_isAlive) return;
    _isLoadingData = false;
    refreshAll();
  }

  /// ✅ Mostrar diálogo de suscripción DESPUÉS de que el Dashboard esté listo
  void _showSubscriptionDialogIfNeeded() {
    try {
      if (Get.isRegistered<SubscriptionController>()) {
        final subscriptionController = Get.find<SubscriptionController>();
        subscriptionController.showPendingSubscriptionDialogIfNeeded();
      } else {
        print('⚠️ SubscriptionController no registrado');
      }
    } catch (e) {
      print('⚠️ Error mostrando diálogo de suscripción: $e');
    }
  }

  Future<void> _loadInitialData() async {
    if (!_isAlive) return;
    // Guard: evitar cargas concurrentes
    if (_isLoadingData) {
      print('📊 Dashboard: Carga ya en progreso, ignorando duplicado');
      return;
    }
    _isLoadingData = true;

    try {
      final startDate = _selectedDateRange.value?.start;
      final endDate = _selectedDateRange.value?.end;

      // ═══ PASO 1: ISAR instantáneo (offline-first) ═══
      print('📊 Dashboard: Cargando desde ISAR (offline-first)...');
      await _loadAllOffline(startDate, endDate);
      if (!_isAlive) return;
      update();

      // ═══ PASO 2: Refresh en background si hay red ═══
      _refreshFromServer(startDate, endDate);

      _showSubscriptionDialogIfNeeded();
    } catch (e) {
      print('❌ Error crítico en _loadInitialData: $e');
      if (!_isAlive) return;
      _isLoadingStats.value = false;
      _isLoadingActivity.value = false;
      _isLoadingNotifications.value = false;
      _isLoadingExpenseChart.value = false;
      _isLoadingProfitability.value = false;
      update();
      _showSubscriptionDialogIfNeeded();
    } finally {
      _isLoadingData = false;
    }
  }

  /// Refresca datos del servidor en background (no bloquea UI)
  void _refreshFromServer(DateTime? startDate, DateTime? endDate, [int? version]) {
    final v = version ?? _dataVersion;
    () async {
      if (!_isAlive) return;
      try {
        final networkInfo = Get.find<NetworkInfo>();
        if (!networkInfo.isServerReachable) return;
        final isOnline = await networkInfo.isConnected;
        if (!isOnline || !_isAlive || v != _dataVersion) return;

        print('🌐 Dashboard: Refrescando desde servidor en background...');
        await Future.wait([
          loadDashboardStats(startDate: startDate, endDate: endDate).timeout(
            const Duration(seconds: 8),
            onTimeout: () => print('⏰ Timeout en estadísticas'),
          ),
          loadProfitabilityStats(startDate: startDate, endDate: endDate).timeout(
            const Duration(seconds: 6),
            onTimeout: () => print('⏰ Timeout en rentabilidad'),
          ),
          loadRecentActivity().timeout(
            const Duration(seconds: 6),
            onTimeout: () {},
          ).catchError((e) => print('⚠️ Error actividades: $e')),
          loadNotifications().timeout(
            const Duration(seconds: 6),
            onTimeout: () {},
          ).catchError((e) => print('⚠️ Error notificaciones: $e')),
          loadUnreadNotificationsCount().timeout(
            const Duration(seconds: 4),
            onTimeout: () {},
          ).catchError((e) {}),
        ]);

        if (!_isAlive || v != _dataVersion) return;
        _harmonizeFinancialData();

        await _loadExpensesByCategory().timeout(
          const Duration(seconds: 6),
          onTimeout: () => print('⏰ Timeout gastos por categoría'),
        ).catchError((e) => print('⚠️ Error gastos: $e'));

        if (!_isAlive || v != _dataVersion) return;
        update();
        print('✅ Dashboard: Datos actualizados desde servidor');
      } catch (e) {
        print('⚠️ Dashboard: Error en refresh background: $e');
      }
    }();
  }

  /// ⚡ Carga rápida offline: todo desde ISAR sin verificaciones de red adicionales
  Future<void> _loadAllOffline(DateTime? startDate, DateTime? endDate) async {
    if (!_isAlive) return;
    final localDataSource = Get.find<DashboardLocalDataSource>();

    // ═══════════════════════════════════════════════════════════════
    // PASO 1: Stats + actividades + notificaciones EN PARALELO
    // getCachedDashboardStats calcula TODO: stats, profitability, expensesByCategory
    // ═══════════════════════════════════════════════════════════════
    _isLoadingStats.value = true;
    _isLoadingProfitability.value = true;
    _isLoadingActivity.value = true;
    _isLoadingNotifications.value = true;
    _isLoadingExpenseChart.value = true;

    try {
      // ⚡ Lanzar TODO en paralelo - stats no depende de actividades/notificaciones
      final results = await Future.wait([
        // 0: Stats completas (incluye profitability + expensesByCategory)
        localDataSource.getCachedDashboardStats(startDate: startDate, endDate: endDate),
        // 1: Actividades recientes
        localDataSource.getOfflineRecentActivities(limit: 10),
        // 2: Notificaciones
        localDataSource.getOfflineSmartNotifications(limit: 10),
      ]);

      if (!_isAlive) return;

      // Procesar stats
      final stats = results[0] as DashboardStatsModel?;
      if (stats != null) {
        // ═══════════════════════════════════════════════════════════════
        // PROFITABILITY: Usar cache EXACTO para armonizar, fallback solo para COGS
        // ═══════════════════════════════════════════════════════════════
        bool hasExactCache = false;
        final exactProfitability = await _getExactCachedProfitabilityStats(startDate, endDate);
        if (exactProfitability != null) {
          _profitabilityStats.value = exactProfitability;
          hasExactCache = true;
          print('💾 Profitability offline: cache EXACTO del backend (COGS=${exactProfitability.totalCOGS})');
        } else {
          // Fallback: usar ISAR revenue como base, pero intentar obtener ratio COGS del cache
          final fallbackProfitability = await _getFallbackProfitabilityStats();
          if (fallbackProfitability != null && fallbackProfitability.totalRevenue > 0) {
            // Calcular ratio COGS del cache y aplicarlo al revenue de ISAR
            final cogsRatio = fallbackProfitability.totalCOGS / fallbackProfitability.totalRevenue;
            final isarRevenue = stats.profitability.totalRevenue;
            final estimatedCOGS = isarRevenue * cogsRatio;
            final estimatedGrossProfit = isarRevenue - estimatedCOGS;
            final estimatedNetProfit = estimatedGrossProfit - stats.expenses.totalAmount;
            _profitabilityStats.value = ProfitabilityStatsModel(
              totalRevenue: isarRevenue,
              totalCOGS: estimatedCOGS,
              grossProfit: estimatedGrossProfit,
              grossMarginPercentage: isarRevenue > 0 ? (estimatedGrossProfit / isarRevenue) * 100 : 0,
              netProfit: estimatedNetProfit,
              netMarginPercentage: isarRevenue > 0 ? (estimatedNetProfit / isarRevenue) * 100 : 0,
              averageMarginPerSale: stats.profitability.averageMarginPerSale,
              topProfitableProducts: fallbackProfitability.topProfitableProducts,
              lowProfitableProducts: fallbackProfitability.lowProfitableProducts,
              marginsByCategory: fallbackProfitability.marginsByCategory,
              trend: const ProfitabilityTrendModel(
                previousPeriodGrossMargin: 0.0,
                currentPeriodGrossMargin: 0.0,
                marginGrowth: 0.0,
                isImproving: false,
                dailyMargins: [],
              ),
            );
            print('📴 Profitability offline: ISAR revenue=$isarRevenue + COGS ratio=${(cogsRatio * 100).toStringAsFixed(1)}% del cache');
          } else {
            _profitabilityStats.value = stats.profitability;
            print('📴 Profitability offline: calculada desde ISAR (sin cache disponible)');
          }
        }

        // ⚡ Mapear nombres de categoría en expensesByCategory
        final rawExpensesByCategory = stats.expenses.expensesByCategory;
        if (rawExpensesByCategory.isNotEmpty) {
          final categoriesMap = await _getCachedCategoriesMap();
          final namedExpenses = <String, double>{};
          int unknownCounter = 1;
          for (final entry in rawExpensesByCategory.entries) {
            String name;
            if (categoriesMap.containsKey(entry.key)) {
              name = categoriesMap[entry.key]!;
            } else {
              name = 'Categoría $unknownCounter';
              unknownCounter++;
            }
            namedExpenses[name] = (namedExpenses[name] ?? 0.0) + entry.value;
          }

          _dashboardStats.value = DashboardStats(
            sales: stats.sales,
            invoices: stats.invoices,
            products: stats.products,
            customers: stats.customers,
            expenses: ExpenseStats(
              totalAmount: stats.expenses.totalAmount,
              totalExpenses: stats.expenses.totalExpenses,
              monthlyExpenses: stats.expenses.monthlyExpenses,
              todayExpenses: stats.expenses.todayExpenses,
              pendingExpenses: stats.expenses.pendingExpenses,
              approvedExpenses: stats.expenses.approvedExpenses,
              monthlyGrowth: stats.expenses.monthlyGrowth,
              expensesByCategory: namedExpenses,
            ),
            profitability: stats.profitability,
            paymentMethodsBreakdown: stats.paymentMethodsBreakdown,
            incomeTypeBreakdown: stats.incomeTypeBreakdown,
            currencyBreakdown: stats.currencyBreakdown,
            multiCurrencyEnabled: stats.multiCurrencyEnabled,
            baseCurrency: stats.baseCurrency,
          );
        } else {
          _dashboardStats.value = stats;
        }

        // ✅ Solo armonizar cuando tenemos cache EXACTO del backend para este rango
        // (el cache exacto tiene el Revenue correcto calculado por el servidor)
        // Si es fallback de otro rango, confiar en ISAR Revenue para este filtro
        if (hasExactCache) {
          _harmonizeFinancialData();
        }

        print('📴 Dashboard offline: Revenue=${_dashboardStats.value?.sales.totalAmount}, '
            'Expenses=${_dashboardStats.value?.expenses.totalAmount}, '
            'NetProfit=${_profitabilityStats.value?.netProfit}, '
            'Categories=${rawExpensesByCategory.length}, '
            'CacheExacto=$hasExactCache');
      }

      if (!_isAlive) return;

      // Procesar actividades
      final activities = results[1] as List<RecentActivityAdvanced>;
      _recentActivitiesAdvanced.assignAll(activities);

      // Procesar notificaciones
      final notifications = results[2] as List<SmartNotification>;
      _smartNotifications.assignAll(notifications);
      _unreadNotificationsCount.value = notifications.where((n) => n.isUnread).length;

      print('📴 Offline completo: ${activities.length} actividades, ${notifications.length} notificaciones');
    } catch (e) {
      print('⚠️ Error cargando datos offline: $e');
    } finally {
      if (_isAlive) {
        _isLoadingStats.value = false;
        _isLoadingProfitability.value = false;
        _isLoadingActivity.value = false;
        _isLoadingNotifications.value = false;
        _isLoadingExpenseChart.value = false;
      }
    }
  }

  /// Armoniza los datos financieros entre summary y profitability.
  /// Usa profitability.totalRevenue como fuente de verdad para que
  /// Revenue, COGS, Gross Profit y Net Profit cuadren consistentemente.
  void _harmonizeFinancialData() {
    if (!_isAlive) return;
    final stats = _dashboardStats.value;
    final profitability = _profitabilityStats.value;
    if (stats == null || profitability == null) return;
    if (profitability.totalRevenue <= 0) return;

    _dashboardStats.value = DashboardStats(
      sales: SalesStats(
        totalAmount: profitability.totalRevenue,
        totalSales: stats.sales.totalSales,
        todaySales: stats.sales.todaySales,
        yesterdaySales: stats.sales.yesterdaySales,
        monthlySales: stats.sales.monthlySales,
        yearSales: stats.sales.yearSales,
        todayGrowth: stats.sales.todayGrowth,
        monthlyGrowth: stats.sales.monthlyGrowth,
      ),
      invoices: stats.invoices,
      products: stats.products,
      customers: stats.customers,
      expenses: stats.expenses,
      profitability: profitability,
      paymentMethodsBreakdown: stats.paymentMethodsBreakdown,
      incomeTypeBreakdown: stats.incomeTypeBreakdown,
      currencyBreakdown: stats.currencyBreakdown,
      multiCurrencyEnabled: stats.multiCurrencyEnabled,
      baseCurrency: stats.baseCurrency,
    );
    print('🔄 Datos financieros armonizados: Revenue=${profitability.totalRevenue}, '
        'COGS=${profitability.totalCOGS}, GrossProfit=${profitability.grossProfit}, '
        'NetProfit=${profitability.netProfit}');
  }

  Future<void> loadDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isAlive) return;
    _isLoadingStats.value = true;
    _statsError.value = null;

    print('📊 Cargando dashboard stats...');
    final result = await _getDashboardStatsUseCase(
      GetDashboardStatsParams(startDate: startDate, endDate: endDate),
    );

    if (!_isAlive) return;
    result.fold(
      (failure) {
        print('❌ Error cargando dashboard stats: $failure');
        _statsError.value = _mapFailureToMessage(failure);
      },
      (stats) {
        print('✅ Dashboard stats cargados exitosamente!');
        print('   💰 Total Revenue: ${stats.profitability.totalRevenue}');
        print('   💸 Total Expenses: ${stats.expenses.totalAmount}');
        print('   💵 Gross Profit: ${stats.profitability.grossProfit}');
        print('   📊 Payment Methods: ${stats.paymentMethodsBreakdown.length} métodos');
        print('   💳 Income Breakdown - Facturas: ${stats.incomeTypeBreakdown.invoices}, Créditos: ${stats.incomeTypeBreakdown.credits}');
        _dashboardStats.value = stats;
        // ✅ Notificar a widgets GetBuilder
        update();
      },
    );

    if (_isAlive) _isLoadingStats.value = false;
  }

  Future<void> loadProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  }) async {
    if (!_isAlive) return;
    print('🎯 INICIANDO loadProfitabilityStats...');
    _isLoadingProfitability.value = true;
    _profitabilityError.value = null;

    final result = await _getProfitabilityStatsUseCase(
      GetProfitabilityStatsParams(
        startDate: startDate,
        endDate: endDate,
        warehouseId: warehouseId,
        categoryId: categoryId,
      ),
    );

    if (!_isAlive) return;
    if (result.isRight()) {
      final stats = result.getOrElse(() => throw Exception());
      print('✅ ÉXITO loadProfitabilityStats: Revenue=${stats.totalRevenue}, COGS=${stats.totalCOGS}');
      print('   📊 Gross Profit: ${stats.grossProfit}, Margin: ${stats.grossMarginPercentage}%');
      print('   📈 Top Products: ${stats.topProfitableProducts.length}');
      _profitabilityStats.value = stats;
      _cacheProfitabilityStats(stats, startDate, endDate);
      update();
    } else {
      final failure = result.fold((f) => f, (_) => throw Exception());
      print('❌ ERROR loadProfitabilityStats: $failure');
      final cached = await _getCachedProfitabilityStats(startDate, endDate);
      if (!_isAlive) return;
      if (cached != null) {
        _profitabilityStats.value = cached;
        print('💾 Profitability fallback: usando cache real (COGS=${cached.totalCOGS})');
      } else {
        _profitabilityError.value = _mapFailureToMessage(failure);
      }
    }

    if (_isAlive) _isLoadingProfitability.value = false;
  }

  Future<void> loadRecentActivity({
    int limit = 10,
    List<ActivityType>? types,
  }) async {
    if (!_isAlive) return;
    _isLoadingActivity.value = true;
    _activityError.value = null;

    try {
      await loadAdvancedRecentActivities(page: 1, limit: limit);
    } catch (e) {
      if (!_isAlive) return;
      final result = await _getRecentActivityUseCase(
        GetRecentActivityParams(limit: limit, types: types),
      );

      if (!_isAlive) return;
      result.fold(
        (failure) => _activityError.value = _mapFailureToMessage(failure),
        (activities) => _recentActivities.assignAll(activities),
      );
    }

    if (_isAlive) _isLoadingActivity.value = false;
  }

  // Método para cargar actividades avanzadas con paginación
  Future<void> loadAdvancedRecentActivities({
    int page = 1,
    int limit = 10,
    String? category,
    String? priority,
    String? timeFilter,
  }) async {
    if (!_isAlive) return;
    try {
      final networkInfo = Get.find<NetworkInfo>();
      if (!networkInfo.isServerReachable) {
        final localDataSource = Get.find<DashboardLocalDataSource>();
        final offlineActivities = await localDataSource.getOfflineRecentActivities(limit: limit);
        if (!_isAlive) return;
        _recentActivitiesAdvanced.assignAll(offlineActivities);
        return;
      }

      final dioClient = Get.find<DioClient>();

      final response = await dioClient.get(
        '/dashboard/activities/recent',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (category != null) 'category': category,
          if (priority != null) 'priority': priority,
          if (timeFilter != null) 'timeFilter': timeFilter,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data is Map<String, dynamic> && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        final secondLevel = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        final thirdLevel = secondLevel is Map<String, dynamic> && secondLevel.containsKey('data')
            ? secondLevel['data']
            : secondLevel;

        final activitiesJson = thirdLevel is Map<String, dynamic> && thirdLevel.containsKey('activities')
            ? thirdLevel['activities'] as List?
            : null;

        if (!_isAlive) return;
        if (activitiesJson != null) {
          final activities = activitiesJson
              .map((json) => RecentActivityAdvanced.fromJson(json))
              .toList();

          if (page == 1) {
            _recentActivitiesAdvanced.assignAll(activities);
          } else {
            _recentActivitiesAdvanced.addAll(activities);
          }

          print('✅ Actividades cargadas: ${activities.length} items (página $page)');
        } else {
          print('⚠️ No se encontraron actividades en la respuesta');
          _recentActivitiesAdvanced.clear();
        }
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      if (!_isAlive) return;
      try {
        final localDataSource = Get.find<DashboardLocalDataSource>();
        final offlineActivities = await localDataSource.getOfflineRecentActivities(limit: limit);
        if (!_isAlive) return;
        if (offlineActivities.isNotEmpty) {
          _recentActivitiesAdvanced.assignAll(offlineActivities);
          print('📴 Actividades fallback desde ISAR: ${offlineActivities.length}');
          return;
        }
      } catch (_) {}
      if (_isAlive) _activityError.value = 'Error al cargar actividades: $e';
      print('Error loading advanced activities: $e');
    }
  }

  Future<void> loadNotifications({int limit = 10, bool? unreadOnly}) async {
    if (!_isAlive) return;
    _isLoadingNotifications.value = true;
    _notificationsError.value = null;

    try {
      await loadAdvancedNotifications(page: 1, limit: limit, includeRead: !(unreadOnly ?? false));
    } catch (e) {
      if (!_isAlive) return;
      final result = await _getNotificationsUseCase(
        GetDashboardNotificationsParams(limit: limit, unreadOnly: unreadOnly),
      );

      if (!_isAlive) return;
      result.fold(
        (failure) => _notificationsError.value = _mapFailureToMessage(failure),
        (notifications) => _notifications.assignAll(notifications),
      );
    }

    if (_isAlive) _isLoadingNotifications.value = false;
  }

  // Método para cargar notificaciones avanzadas con paginación
  Future<void> loadAdvancedNotifications({
    int page = 1,
    int limit = 10,
    List<String>? priorities,
    List<String>? types,
    bool includeRead = false,
  }) async {
    if (!_isAlive) return;
    try {
      final networkInfo = Get.find<NetworkInfo>();
      if (!networkInfo.isServerReachable) {
        final localDataSource = Get.find<DashboardLocalDataSource>();
        final offlineNotifications = await localDataSource.getOfflineSmartNotifications(limit: limit);
        if (!_isAlive) return;
        _smartNotifications.assignAll(offlineNotifications);
        _unreadNotificationsCount.value = offlineNotifications.where((n) => n.isUnread).length;
        return;
      }

      final dioClient = Get.find<DioClient>();

      final response = await dioClient.get(
        '/dashboard/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (priorities != null) 'priorities': priorities.join(','),
          if (types != null) 'types': types.join(','),
          'includeRead': includeRead,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data is Map<String, dynamic> && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        final secondLevel = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        final thirdLevel = secondLevel is Map<String, dynamic> && secondLevel.containsKey('data')
            ? secondLevel['data']
            : secondLevel;

        final notificationsJson = thirdLevel is Map<String, dynamic> && thirdLevel.containsKey('notifications')
            ? thirdLevel['notifications'] as List?
            : null;

        if (!_isAlive) return;
        if (notificationsJson != null) {
          final notifications = notificationsJson
              .map((json) => SmartNotification.fromJson(json))
              .toList();

          if (page == 1) {
            _smartNotifications.assignAll(notifications);
          } else {
            _smartNotifications.addAll(notifications);
          }

          _unreadNotificationsCount.value = thirdLevel is Map<String, dynamic> && thirdLevel.containsKey('unreadCount')
              ? thirdLevel['unreadCount'] as int? ?? 0
              : 0;

          print('✅ Notificaciones cargadas: ${notifications.length} items (página $page)');
        } else {
          print('⚠️ No se encontraron notificaciones en la respuesta');
          _smartNotifications.clear();
          _unreadNotificationsCount.value = 0;
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      if (!_isAlive) return;
      try {
        final localDataSource = Get.find<DashboardLocalDataSource>();
        final offlineNotifications = await localDataSource.getOfflineSmartNotifications(limit: limit);
        if (!_isAlive) return;
        if (offlineNotifications.isNotEmpty) {
          _smartNotifications.assignAll(offlineNotifications);
          _unreadNotificationsCount.value = offlineNotifications.where((n) => n.isUnread).length;
          print('📴 Notificaciones fallback desde ISAR: ${offlineNotifications.length}');
          return;
        }
      } catch (_) {}
      if (_isAlive) _notificationsError.value = 'Error al cargar notificaciones: $e';
      print('Error loading advanced notifications: $e');
    }
  }

  Future<void> loadUnreadNotificationsCount() async {
    if (!_isAlive) return;
    final result = await _getUnreadNotificationsCountUseCase(NoParams());

    if (!_isAlive) return;
    result.fold(
      (failure) => {},
      (count) => _unreadNotificationsCount.value = count,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (!_isAlive) return;
    final result = await _markNotificationAsReadUseCase(
      MarkDashboardNotificationAsReadParams(notificationId: notificationId),
    );

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          _mapFailureToMessage(failure),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      },
      (updatedNotification) {
        if (!_isAlive) return;
        // Update local notification list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = updatedNotification;
        }

        // Update unread count
        _unreadNotificationsCount.value =
            (_unreadNotificationsCount.value - 1)
                .clamp(0, double.infinity)
                .toInt();
      },
    );
  }

  void setDateRange(DateTimeRange? dateRange) {
    print('🔄 Cambiando a rango personalizado: ${dateRange?.start} - ${dateRange?.end}');
    _selectedDateRange.value = dateRange;
    _selectedPeriod.value = 'custom';

    // Cargar datos con detección rápida de offline
    _loadDataForDateRange(dateRange?.start, dateRange?.end, 'rango personalizado');
  }

  void setActivityTypes(List<ActivityType> types) {
    _selectedActivityTypes.assignAll(types);
    loadRecentActivity(types: types.isEmpty ? null : types);
  }

  void clearFilters() {
    _selectedDateRange.value = null;
    _selectedActivityTypes.clear();
    _selectedPeriod.value = 'este_mes';
    _loadInitialData();
  }

  void setPredefinedPeriod(String period) {
    print('🔄 Cambiando período a: $period');
    _selectedPeriod.value = period;
    final now = Get.find<TenantDateTimeService>().now();
    DateTimeRange? dateRange;

    switch (period) {
      case 'hoy':
        // Use TenantDateTimeService to ensure we get today's date in tenant timezone
        final today = now;
        dateRange = DateTimeRange(
          start: DateTime(today.year, today.month, today.day, 0, 0, 0),
          end: DateTime(today.year, today.month, today.day, 23, 59, 59),
        );
        break;
      case 'esta_semana':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        dateRange = DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
        );
        break;
      case 'este_mes':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        break;
      case 'ultimos_3_meses':
        // ✅ PERÍODO POR DEFECTO: Incluir últimos 3 meses para mostrar datos existentes
        final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
        dateRange = DateTimeRange(
          start: threeMonthsAgo,
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        break;
      default:
        dateRange = null;
    }

    _selectedDateRange.value = dateRange;
    print('🔄 Nuevo rango de fechas: ${dateRange?.start} - ${dateRange?.end}');

    // ✅ Notificar a los widgets que usan GetBuilder
    update();

    // Cargar datos con detección rápida de offline
    _loadDataForDateRange(dateRange?.start, dateRange?.end, period);
  }

  /// Helper reutilizable para cargar datos con filtro de fecha (offline-first)
  void _loadDataForDateRange(DateTime? startDate, DateTime? endDate, String label) {
    final version = ++_dataVersion;
    () async {
      try {
        // ═══ PASO 1: ISAR instantáneo ═══
        await _loadAllOffline(startDate, endDate);
        if (version != _dataVersion || !_isAlive) return;
        update();

        // ═══ PASO 2: Refresh background ═══
        _refreshFromServer(startDate, endDate, version);
      } catch (error) {
        print('⚠️ Error cargando datos para $label: $error');
      }
    }();
  }

  Future<void> refreshAll() async {
    if (!_isAlive) return;
    try {
      await _loadInitialData();
    } catch (e) {
      print('Error in refreshAll: $e');
      if (!_isAlive) return;
      _isLoadingStats.value = false;
      _isLoadingActivity.value = false;
      _isLoadingNotifications.value = false;
      _isLoadingProfitability.value = false;
    }
  }

  Future<void> refreshStats() async {
    if (!_isAlive) return;
    await loadDashboardStats(
      startDate: _selectedDateRange.value?.start,
      endDate: _selectedDateRange.value?.end,
    );
  }

  Future<void> refreshActivity() async {
    if (!_isAlive) return;
    await loadRecentActivity(
      types: _selectedActivityTypes.isEmpty ? null : _selectedActivityTypes,
    );
  }

  Future<void> refreshNotifications() async {
    if (!_isAlive) return;
    await Future.wait([loadNotifications(), loadUnreadNotificationsCount()]);
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Error del servidor. Inténtalo más tarde.';
      case CacheFailure:
        return 'Error de datos locales.';
      case ConnectionFailure:
        return 'Sin conexión a internet.';
      default:
        return 'Error inesperado.';
    }
  }

  // Método para cargar gastos por categoría obteniendo gastos individuales con paginación
  Future<void> _loadExpensesByCategory() async {
    if (!_isAlive) return;
    _isLoadingExpenseChart.value = true;
    try {
      final networkInfo = Get.find<NetworkInfo>();
      if (!networkInfo.isServerReachable) {
        await _loadExpensesByCategoryOffline();
        return;
      }

      final dioClient = Get.find<DioClient>();

      // PASO 1: Obtener las categorías para mapear IDs a nombres
      final categoriesMap = await _loadCategoriesMap();

      // Usar las mismas fechas del período seleccionado
      final dateRange = _selectedDateRange.value;
      final expensesByCategory = <String, double>{};
      bool hadConnectionError = false;

      int page = 1;
      const int limit = 100;
      bool hasMoreData = true;

      while (hasMoreData) {
        try {
          final params = <String, dynamic>{
            'page': page,
            'limit': limit,
            'status': 'approved',
          };

          if (dateRange != null) {
            params['startDate'] = dateRange.start.toIso8601String();
            params['endDate'] = dateRange.end.toIso8601String();
          }

          final response = await dioClient.get(
            '/expenses',
            queryParameters: params,
          );

          if (response.statusCode == 200) {
            final responseData = response.data;
            final expenses = responseData['data'] as List<dynamic>? ?? [];
            final meta = responseData['meta'] as Map<String, dynamic>? ?? {};
            final totalPages = meta['totalPages'] as int? ?? 1;

            print('📄 Página $page/$totalPages: ${expenses.length} gastos');

            for (int expenseIndex = 0; expenseIndex < expenses.length; expenseIndex++) {
              final expenseJson = expenses[expenseIndex];
              if (expenseJson is Map<String, dynamic>) {
                try {
                  final amountStr = expenseJson['amount']?.toString() ?? '0';
                  final amount = double.tryParse(amountStr) ?? 0.0;

                  final category = expenseJson['category'];
                  String categoryName = 'Sin categoría';

                  if (category != null && category is Map<String, dynamic>) {
                    categoryName = category['name']?.toString() ?? 'Sin categoría';
                  } else {
                    final categoryId = expenseJson['categoryId']?.toString();
                    if (categoryId != null && categoryId.isNotEmpty) {
                      categoryName = categoriesMap[categoryId] ?? 'Categoría desconocida';
                    }
                  }

                  expensesByCategory[categoryName] = (expensesByCategory[categoryName] ?? 0) + amount;
                } catch (expenseError) {
                  print('⚠️ Error processing expense $expenseIndex: $expenseError');
                }
              }
            }

            hasMoreData = page < totalPages;
            page++;

            if (page > 50) {
              print('⚠️ Límite de páginas alcanzado (50), deteniendo carga');
              break;
            }
          } else {
            break;
          }
        } catch (pageError) {
          print('⚠️ Error cargando página $page: $pageError');
          hadConnectionError = true;
          break;
        }
      }

      // Si hubo error de conexión y no se obtuvieron datos, fallback a ISAR
      if (expensesByCategory.isEmpty && hadConnectionError) {
        print('📴 Gastos online fallaron, usando fallback ISAR...');
        await _loadExpensesByCategoryOffline();
        return;
      }

      if (!_isAlive) return;
      _updateExpensesByCategoryInStats(expensesByCategory);

      print('✅ Gastos por categoría cargados: ${expensesByCategory.length} categorías');

    } catch (e) {
      print('⚠️ Error cargando gastos por categoría: $e - Intentando offline...');
      try {
        if (_isAlive) await _loadExpensesByCategoryOffline();
      } catch (_) {}
    } finally {
      if (_isAlive) _isLoadingExpenseChart.value = false;
    }
  }

  // Helper: cargar gastos por categoría desde ISAR
  Future<void> _loadExpensesByCategoryOffline() async {
    if (!_isAlive) return;
    final localDataSource = Get.find<DashboardLocalDataSource>();
    final dateRange = _selectedDateRange.value;

    final offlineExpenses = await localDataSource.getOfflineExpensesByCategory(
      startDate: dateRange?.start,
      endDate: dateRange?.end,
    );

    if (offlineExpenses.isNotEmpty) {
      // Intentar mapear categoryId a nombre desde cache
      final categoriesMap = await _getCachedCategoriesMap();
      final namedExpenses = <String, double>{};
      int unknownCounter = 1;
      for (var entry in offlineExpenses.entries) {
        String name;
        if (categoriesMap.containsKey(entry.key)) {
          name = categoriesMap[entry.key]!;
        } else {
          // Si el key parece un UUID, usar nombre genérico
          name = 'Categoría $unknownCounter';
          unknownCounter++;
        }
        namedExpenses[name] = (namedExpenses[name] ?? 0.0) + entry.value;
      }

      _updateExpensesByCategoryInStats(namedExpenses);
      print('📴 Gastos por categoría offline: ${namedExpenses.length} categorías');
    }
  }

  // Helper: actualizar dashboardStats con expensesByCategory
  void _updateExpensesByCategoryInStats(Map<String, double> expensesByCategory) {
    if (!_isAlive) return;
    if (_dashboardStats.value != null) {
      final currentStats = _dashboardStats.value!;
      final updatedExpenseStats = ExpenseStats(
        totalAmount: currentStats.expenses.totalAmount,
        totalExpenses: currentStats.expenses.totalExpenses,
        monthlyExpenses: currentStats.expenses.monthlyExpenses,
        todayExpenses: currentStats.expenses.todayExpenses,
        pendingExpenses: currentStats.expenses.pendingExpenses,
        approvedExpenses: currentStats.expenses.approvedExpenses,
        monthlyGrowth: currentStats.expenses.monthlyGrowth,
        expensesByCategory: expensesByCategory,
      );

      _dashboardStats.value = DashboardStats(
        sales: currentStats.sales,
        invoices: currentStats.invoices,
        products: currentStats.products,
        customers: currentStats.customers,
        expenses: updatedExpenseStats,
        profitability: currentStats.profitability,
        paymentMethodsBreakdown: currentStats.paymentMethodsBreakdown,
        incomeTypeBreakdown: currentStats.incomeTypeBreakdown,
        currencyBreakdown: currentStats.currencyBreakdown,
        multiCurrencyEnabled: currentStats.multiCurrencyEnabled,
        baseCurrency: currentStats.baseCurrency,
      );

      update();
    }
  }

  static const String _categoriesMapCacheKey = 'dashboard_expense_categories_map';
  static const String _profitabilityCachePrefix = 'dashboard_profitability_';
  static const String _profitabilityLatestKey = 'dashboard_profitability_latest';

  // Método para cargar mapa de categorías (ID -> Nombre)
  Future<Map<String, String>> _loadCategoriesMap() async {
    try {
      // ⚡ Check sync rápido
      final networkInfo = Get.find<NetworkInfo>();
      if (!networkInfo.isServerReachable) {
        return _getCachedCategoriesMap();
      }

      final dioClient = Get.find<DioClient>();

      final response = await dioClient.get(
        '/expense-categories',
        queryParameters: {'limit': 100},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          return _getCachedCategoriesMap();
        }

        List<dynamic>? categories;

        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic> && data.containsKey('categories')) {
            categories = data['categories'] as List<dynamic>?;
          } else if (data is List<dynamic>) {
            categories = data;
          }
        } else if (responseData.containsKey('categories')) {
          categories = responseData['categories'] as List<dynamic>?;
        }

        if (categories == null || categories.isEmpty) {
          return _getCachedCategoriesMap();
        }

        final categoriesMap = <String, String>{};
        for (var categoryJson in categories) {
          if (categoryJson is Map<String, dynamic>) {
            final id = categoryJson['id']?.toString();
            final name = categoryJson['name']?.toString() ?? 'Sin nombre';
            if (id != null && id.isNotEmpty) {
              categoriesMap[id] = name;
            }
          }
        }

        print('📋 Categorías cargadas: ${categoriesMap.length}');

        // Cachear para uso offline
        _cacheCategoriesMap(categoriesMap);

        return categoriesMap;
      }
    } catch (e) {
      print('⚠️ Error cargando categorías: $e - Usando cache...');
    }

    return _getCachedCategoriesMap();
  }

  // Cachear mapa de categorías en SecureStorage
  Future<void> _cacheCategoriesMap(Map<String, String> categoriesMap) async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      await secureStorage.write(_categoriesMapCacheKey, json.encode(categoriesMap));
    } catch (e) {
      print('⚠️ Error cacheando categorías: $e');
    }
  }

  // Leer mapa de categorías desde cache (busca en múltiples fuentes)
  Future<Map<String, String>> _getCachedCategoriesMap() async {
    try {
      final secureStorage = Get.find<SecureStorageService>();

      // Fuente 1: Cache propio del dashboard
      final cachedData = await secureStorage.read(_categoriesMapCacheKey);
      if (cachedData != null) {
        final decoded = json.decode(cachedData) as Map<String, dynamic>;
        final result = decoded.map((k, v) => MapEntry(k, v.toString()));
        if (result.isNotEmpty) return result;
      }

      // Fuente 2: Cache del módulo de expenses (expense_categories_cache)
      final expenseCategoriesCache = await secureStorage.read('expense_categories_cache');
      if (expenseCategoriesCache != null) {
        final List<dynamic> jsonList = json.decode(expenseCategoriesCache);
        final result = <String, String>{};
        for (var catJson in jsonList) {
          if (catJson is Map<String, dynamic>) {
            final id = catJson['id']?.toString();
            final name = catJson['name']?.toString();
            if (id != null && name != null) {
              result[id] = name;
            }
          }
        }
        if (result.isNotEmpty) {
          // Cachear en nuestro formato para próxima vez
          _cacheCategoriesMap(result);
          return result;
        }
      }
    } catch (e) {
      print('⚠️ Error leyendo cache de categorías: $e');
    }
    return <String, String>{};
  }

  // ==================== PROFITABILITY CACHE ====================

  /// Genera clave de cache para un rango de fechas específico
  String _profitabilityCacheKey(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '${_profitabilityCachePrefix}all';
    final s = start?.toIso8601String().substring(0, 10) ?? 'null';
    final e = end?.toIso8601String().substring(0, 10) ?? 'null';
    return '$_profitabilityCachePrefix${s}_$e';
  }

  /// Cachear datos reales de rentabilidad del backend (COGS, márgenes, productos, tendencias)
  Future<void> _cacheProfitabilityStats(
    ProfitabilityStats stats, DateTime? startDate, DateTime? endDate,
  ) async {
    try {
      final model = ProfitabilityStatsModel.fromEntity(stats);
      final jsonStr = json.encode(model.toJson());
      final secureStorage = Get.find<SecureStorageService>();

      // Cache con key exacta del rango de fechas
      await secureStorage.write(_profitabilityCacheKey(startDate, endDate), jsonStr);

      // Siempre actualizar "latest" como fallback general
      final metadata = json.encode({
        'data': model.toJson(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'cachedAt': DateTime.now().toIso8601String(),
      });
      await secureStorage.write(_profitabilityLatestKey, metadata);

      print('💾 Profitability cacheada: ${_profitabilityCacheKey(startDate, endDate)}');
    } catch (e) {
      print('⚠️ Error cacheando profitability: $e');
    }
  }

  /// Leer datos reales de rentabilidad cacheados para un rango EXACTO
  Future<ProfitabilityStatsModel?> _getExactCachedProfitabilityStats(
    DateTime? startDate, DateTime? endDate,
  ) async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      final exactKey = _profitabilityCacheKey(startDate, endDate);
      final exactData = await secureStorage.read(exactKey);
      if (exactData != null) {
        final jsonMap = json.decode(exactData) as Map<String, dynamic>;
        print('💾 Profitability desde cache exacto: $exactKey');
        return ProfitabilityStatsModel.fromJson(jsonMap);
      }
    } catch (e) {
      print('⚠️ Error leyendo cache exacto de profitability: $e');
    }
    return null;
  }

  /// Leer ultimo cache de profitability (cualquier rango) solo para COGS/margenes
  Future<ProfitabilityStatsModel?> _getFallbackProfitabilityStats() async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      final latestData = await secureStorage.read(_profitabilityLatestKey);
      if (latestData != null) {
        final metadata = json.decode(latestData) as Map<String, dynamic>;
        final data = metadata['data'] as Map<String, dynamic>;
        print('💾 Profitability desde cache latest (solo COGS/margenes)');
        return ProfitabilityStatsModel.fromJson(data);
      }
    } catch (e) {
      print('⚠️ Error leyendo cache fallback de profitability: $e');
    }
    return null;
  }

  /// Leer datos de rentabilidad: primero exacto, luego fallback
  Future<ProfitabilityStatsModel?> _getCachedProfitabilityStats(
    DateTime? startDate, DateTime? endDate,
  ) async {
    return await _getExactCachedProfitabilityStats(startDate, endDate) ??
           await _getFallbackProfitabilityStats();
  }

  // Helper methods for chart data
  Map<String, double> get expensesByCategory {
    return dashboardStats?.expenses.expensesByCategory ?? <String, double>{};
  }

  // Navigation helpers
  void navigateToSales() {
    Get.toNamed('/sales');
  }

  void navigateToInvoices() {
    Get.toNamed('/invoices');
  }

  void navigateToProducts() {
    Get.toNamed('/products');
  }

  void navigateToExpenses() {
    Get.toNamed('/expenses');
  }

  void navigateToCustomers() {
    Get.toNamed('/customers');
  }

  void navigateToReports() {
    Get.toNamed('/reports');
  }

  @override
  void onClose() {
    _isDisposed = true;
    _isLoadingStats.close();
    _isLoadingActivity.close();
    _isLoadingNotifications.close();
    _isLoadingExpenseChart.close();
    _isLoadingProfitability.close();
    _dashboardStats.close();
    _profitabilityStats.close();
    _recentActivities.close();
    _recentActivitiesAdvanced.close();
    _smartNotifications.close();
    _notifications.close();
    _unreadNotificationsCount.close();
    _statsError.close();
    _activityError.close();
    _notificationsError.close();
    _profitabilityError.close();
    _selectedDateRange.close();
    _selectedActivityTypes.close();
    _selectedPeriod.close();
    super.onClose();
  }
}
