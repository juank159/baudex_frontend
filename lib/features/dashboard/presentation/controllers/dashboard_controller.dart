// lib/features/dashboard/presentation/controllers/dashboard_controller.dart
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import '../../../../app/core/utils/app_logger.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import '../../../../app/data/local/sync_service.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/datasources/profitability_cache.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../domain/services/dashboard_rules.dart';
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
  // Se pidió otra carga mientras una estaba en curso: se hace UNA más al
  // terminar (con el rango de fechas vigente), en vez de varias en paralelo.
  bool _reloadPending = false;

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
  /// La ganancia, el costo de lo vendido y los márgenes del negocio solo los
  /// ve el ADMINISTRADOR del tenant. Empleados (rol `user`) y encargados (rol
  /// `manager`) no los ven. Es reactivo: si cambia el usuario en sesión, las
  /// pantallas que lo observan se actualizan.
  ///
  /// El servidor aplica la misma regla (devuelve esos datos en cero a quien
  /// no es administrador); esto además oculta lo calculado localmente sin
  /// conexión.
  bool get canSeeProfit {
    try {
      return Get.find<AuthController>().currentUser?.isAdmin ?? false;
    } catch (_) {
      return false;
    }
  }

  ProfitabilityStats? get profitabilityStats =>
      canSeeProfit ? _profitabilityStats.value : null;
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
  /// Dinero realmente cobrado en el período (por fecha de pago). Es la
  /// métrica principal. Si no se cobró nada, se muestra 0: no se reemplaza
  /// por lo facturado.
  double get totalCollected => dashboardStats?.totalCollected ?? 0.0;

  /// Total facturado en el período (incluye crédito). Métrica secundaria.
  double get totalBilled => dashboardStats?.totalBilled ?? 0.0;

  /// Phase 1B: total de notas de crédito aplicadas en el período.
  double get creditNotesTotal => dashboardStats?.creditNotesTotal ?? 0.0;

  /// Phase 1B: cantidad de notas de crédito aplicadas en el período.
  int get creditNotesCount => dashboardStats?.creditNotesCount ?? 0;

  /// Phase 1B: ingreso neto = `totalCollected - creditNotesTotal`.
  /// Delega en `DashboardStats.effectiveNetRevenue` que centraliza el
  /// fallback. Mantenemos este getter aquí solo para que widgets que
  /// reciben el controller (no stats) puedan leerlo igual.
  double get netRevenue =>
      dashboardStats?.effectiveNetRevenue ?? totalCollected;

  /// Indicador para la UI: ¿hubo devoluciones en el período?
  bool get hasCreditNotes => creditNotesTotal > 0;

  /// @deprecated Usar totalCollected o totalBilled según el caso.
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

  /// Margen bruto real (con COGS). Usa el campo del backend si está
  /// disponible; si no, el de la rentabilidad (ventas contra su costo).
  double get grossMarginPercentage {
    if (!canSeeProfit) return 0.0;
    final server = dashboardStats?.grossMarginPercentage ?? 0.0;
    if (server != 0) return server;
    return profitabilityStats?.grossMarginPercentage ?? 0.0;
  }

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();

    // Establecer el rango de fechas para HOY
    final now = Get.find<TenantDateTimeService>().now();
    _selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    // ✅ Marcar como cargando desde el inicio
    _isLoadingStats.value = true;
    _isLoadingActivity.value = true;
    _isLoadingNotifications.value = true;
    _isLoadingProfitability.value = true;
  }

  @override
  void onReady() {
    super.onReady();

    // ✅ Cargar datos inmediatamente cuando el widget está listo (SIN DELAY, SIN DOBLE CARGA)
    _loadInitialData();
  }

  /// No se ve en facturación: recarga al salir de ahí.
  @override
  bool get deferRefreshWhileSelling => true;

  @override
  Future<void> onSyncCompleted() async {
    if (!_isAlive) return;
    refreshAll();
  }

  /// ✅ Mostrar diálogo de suscripción DESPUÉS de que el Dashboard esté listo
  void _showSubscriptionDialogIfNeeded() {
    try {
      if (Get.isRegistered<SubscriptionController>()) {
        final subscriptionController = Get.find<SubscriptionController>();
        subscriptionController.showPendingSubscriptionDialogIfNeeded();
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadInitialData() async {
    if (!_isAlive) return;
    // Guard: nunca dos cargas a la vez. Si llega otra petición (sincronización,
    // cambio de fechas), se anota y se hace una sola carga más al terminar.
    // Antes cada sincronización reiniciaba el guard y el tablero se calculaba
    // varias veces seguidas al abrir la app.
    if (_isLoadingData) {
      _reloadPending = true;
      return;
    }
    _isLoadingData = true;

    try {
      final startDate = _selectedDateRange.value?.start;
      final endDate = _selectedDateRange.value?.end;

      // ═══ PASO 1: ISAR instantáneo (offline-first) ═══
      await _loadAllOffline(startDate, endDate);
      if (!_isAlive) return;
      update();

      // ═══ PASO 2: Refresh en background si hay red ═══
      _refreshFromServer(startDate, endDate);

      _showSubscriptionDialogIfNeeded();
    } catch (e) {
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
      if (_reloadPending && _isAlive) {
        _reloadPending = false;
        unawaited(_loadInitialData());
      }
    }
  }

  /// Refresca datos del servidor en background (no bloquea UI)
  void _refreshFromServer(DateTime? startDate, DateTime? endDate,
      [int? version]) {
    final v = version ?? _dataVersion;
    () async {
      if (!_isAlive) return;
      try {
        final networkInfo = Get.find<NetworkInfo>();
        if (!networkInfo.isServerReachable) return;
        final isOnline = await networkInfo.isConnected;
        if (!isOnline || !_isAlive || v != _dataVersion) return;

        // Con cambios del equipo sin subir no se consulta al servidor: aún
        // no los conoce y sus cifras taparían las locales, que sí los
        // incluyen. Cuando la subida termina, `onSyncCompleted()` vuelve a
        // disparar este refresh. Ver `DashboardRules.shouldAskServer`.
        if (!_shouldAskServer) return;

        // Patrón nuevo: `_withSoftTimeout` en vez de `.timeout(...)` —
        // evita que el debugger de VSCode pause en TimeoutException
        // cada vez que el usuario navega y los futures siguen volando.
        await Future.wait([
          _withSoftTimeout(
            () => loadDashboardStats(startDate: startDate, endDate: endDate),
            timeout: const Duration(seconds: 8),
            tag: 'estadísticas',
            onTimeoutOrError: () => _isLoadingStats.value = false,
          ),
          _withSoftTimeout(
            () => loadProfitabilityStats(startDate: startDate, endDate: endDate),
            timeout: const Duration(seconds: 6),
            tag: 'rentabilidad',
            onTimeoutOrError: () => _isLoadingProfitability.value = false,
          ),
          _withSoftTimeout(
            () => loadRecentActivity(),
            timeout: const Duration(seconds: 6),
            tag: 'actividades',
            onTimeoutOrError: () => _isLoadingActivity.value = false,
          ),
          _withSoftTimeout(
            () => loadNotifications(),
            timeout: const Duration(seconds: 6),
            tag: 'notificaciones',
            onTimeoutOrError: () => _isLoadingNotifications.value = false,
          ),
          _withSoftTimeout(
            () => loadUnreadNotificationsCount(),
            timeout: const Duration(seconds: 4),
            tag: 'unread-count',
          ),
        ]);

        if (!_isAlive || v != _dataVersion) return;
        _harmonizeFinancialData();

        await _withSoftTimeout(
          () => _loadExpensesByCategory(),
          timeout: const Duration(seconds: 6),
          tag: 'gastos por categoría',
        );

        if (!_isAlive || v != _dataVersion) return;
        update();
      } catch (e) {
      }
    }();
  }

  /// Operaciones del equipo que aún no han subido al servidor.
  @visibleForTesting
  int Function() pendingSyncOperations = () {
    try {
      if (Get.isRegistered<SyncService>()) {
        return Get.find<SyncService>().pendingOperationsCount;
      }
    } catch (_) {}
    return 0;
  };

  bool get _shouldAskServer => DashboardRules.shouldAskServer(
      pendingSyncOperations: pendingSyncOperations());

  /// Organización en sesión (para que la caché no se cruce entre empresas).
  String? get _organizationId {
    try {
      return Get.find<AuthController>().currentUser?.organizationId;
    } catch (_) {
      return null;
    }
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
        // RENTABILIDAD: la última que dio el servidor para esta organización
        // y este mismo rango, sea ganancia o pérdida. Si no hay, la calculada
        // en el equipo con el costo guardado en cada línea (no se estima con
        // el margen de otro período).
        final exactProfitability =
            await _profitabilityCache.load(
          organizationId: _organizationId,
          start: startDate,
          end: endDate,
        );
        final hasExactCache = exactProfitability != null;
        _profitabilityStats.value = exactProfitability ?? stats.profitability;

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

          _dashboardStats.value = stats.copyWith(
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
      }

      if (!_isAlive) return;

      // Procesar actividades
      final activities = results[1] as List<RecentActivityAdvanced>;
      _recentActivitiesAdvanced.assignAll(activities);

      // Procesar notificaciones
      final notifications = results[2] as List<SmartNotification>;
      _smartNotifications.assignAll(notifications);
      _unreadNotificationsCount.value = notifications.where((n) => n.isUnread).length;

    } catch (e) {
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
  /// Mantiene sales.totalAmount del summary (incluye pagos en facturas antiguas)
  /// y usa profitability solo para COGS/margenes.
  void _harmonizeFinancialData() {
    if (!_isAlive) return;
    final stats = _dashboardStats.value;
    final profitability = _profitabilityStats.value;
    if (stats == null || profitability == null) return;
    if (profitability.totalRevenue <= 0) return;

    _dashboardStats.value = stats.copyWith(profitability: profitability);
  }

  Future<void> loadDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isAlive) return;
    // Con cambios sin subir se deja el cálculo local (ver _refreshFromServer).
    if (!_shouldAskServer) return;
    _isLoadingStats.value = true;
    _statsError.value = null;

    try {
      final result = await _getDashboardStatsUseCase(
        GetDashboardStatsParams(startDate: startDate, endDate: endDate),
      );

      if (!_isAlive) return;
      result.fold(
        (failure) {
          // Sin respuesta: queda en pantalla el cálculo local.
          _statsError.value = _mapFailureToMessage(failure);
        },
        (stats) {
          // Con respuesta del servidor se muestran SUS cifras completas
          // (cobrado, facturado, gastos, notas crédito). Antes ganaba "el
          // mayor" entre servidor y equipo, y gastos y notas crédito salían
          // del equipo aunque ganara el servidor: las cifras saltaban y no
          // cuadraban entre sí. El desglose de gastos por categoría sí se
          // arma después desde el equipo, con la misma definición.
          _dashboardStats.value = stats;
          update();
        },
      );
    } catch (e) {
      if (_isAlive) _statsError.value = 'Error inesperado';
    } finally {
      // CRÍTICO: el flag siempre se resetea para que el spinner del gráfico
      // de barras NO quede colgado si el use case lanza excepción.
      if (_isAlive) _isLoadingStats.value = false;
    }
  }

  Future<void> loadProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  }) async {
    if (!_isAlive) return;

    // Solo el administrador consulta la rentabilidad: el dispositivo de un
    // empleado ni la pide ni la guarda.
    if (!canSeeProfit) {
      _profitabilityStats.value = null;
      _profitabilityError.value = null;
      _isLoadingProfitability.value = false;
      return;
    }

    _isLoadingProfitability.value = true;
    _profitabilityError.value = null;

    try {
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
        AppLogger.d('[PROFIT] revenue=${stats.totalRevenue.toStringAsFixed(2)} '
            'COGS=${stats.totalCOGS.toStringAsFixed(2)} '
            'grossProfit=${stats.grossProfit.toStringAsFixed(2)} '
            'netProfit=${stats.netProfit.toStringAsFixed(2)}');
        _profitabilityStats.value = stats;
        unawaited(_profitabilityCache.save(
          organizationId: _organizationId,
          start: startDate,
          end: endDate,
          stats: stats,
        ));
        update();
      } else {
        final failure = result.fold((f) => f, (_) => throw Exception());
        // Solo la caché de ESTE rango; la de otro período no aplica.
        final cached = await _profitabilityCache.load(
          organizationId: _organizationId,
          start: startDate,
          end: endDate,
        );
        if (!_isAlive) return;
        if (cached != null) {
          _profitabilityStats.value = cached;
        } else {
          _profitabilityError.value = _mapFailureToMessage(failure);
        }
      }
    } catch (e) {
    } finally {
      if (_isAlive) _isLoadingProfitability.value = false;
    }
  }

  Future<void> loadRecentActivity({
    int limit = 10,
    List<ActivityType>? types,
  }) async {
    if (!_isAlive) return;
    _isLoadingActivity.value = true;
    _activityError.value = null;

    try {
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
    } catch (e) {
    } finally {
      if (_isAlive) _isLoadingActivity.value = false;
    }
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

        } else {
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
          return;
        }
      } catch (_) {}
      if (_isAlive) _activityError.value = 'Error al cargar actividades: $e';
    }
  }

  Future<void> loadNotifications({int limit = 10, bool? unreadOnly}) async {
    if (!_isAlive) return;
    _isLoadingNotifications.value = true;
    _notificationsError.value = null;

    try {
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
    } catch (e) {
    } finally {
      if (_isAlive) _isLoadingNotifications.value = false;
    }
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

        } else {
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
          return;
        }
      } catch (_) {}
      if (_isAlive) _notificationsError.value = 'Error al cargar notificaciones: $e';
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
          snackPosition: SnackPosition.TOP,
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
      }
    }();
  }

  Future<void> refreshAll() async {
    if (!_isAlive) return;
    try {
      await _loadInitialData();
    } catch (e) {
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

  // Gastos por categoría — desde ISAR, con la misma definición del total
  // (aprobados o pagados, por fecha del gasto), para que el gráfico por
  // categoría y el total de gastos coincidan con o sin conexión.
  Future<void> _loadExpensesByCategory() async {
    if (!_isAlive) return;
    _isLoadingExpenseChart.value = true;
    try {
      await _loadExpensesByCategoryOffline();
    } catch (e) {
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

      _dashboardStats.value = currentStats.copyWith(expenses: updatedExpenseStats);

      update();
    }
  }

  static const String _categoriesMapCacheKey = 'dashboard_expense_categories_map';

  // Cachear mapa de categorías en SecureStorage
  Future<void> _cacheCategoriesMap(Map<String, String> categoriesMap) async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      await secureStorage.write(_categoriesMapCacheKey, json.encode(categoriesMap));
    } catch (e) {
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
    }
    return <String, String>{};
  }

  // ==================== PROFITABILITY CACHE ====================

  /// Última rentabilidad del servidor por organización y rango (incluye
  /// pérdidas). Ver [ProfitabilityCache].
  late final ProfitabilityCache _profitabilityCache = ProfitabilityCache(
    read: (key) => Get.find<SecureStorageService>().read(key),
    write: (key, value) => Get.find<SecureStorageService>().write(key, value),
  );

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

  /// Ejecuta un Future con timeout SIN lanzar `TimeoutException`.
  ///
  /// El problema con `Future.timeout(..., onTimeout: ...)` es que
  /// internamente la VM crea una `TimeoutException`, y aunque haya
  /// `onTimeout` que la suprime, el debugger de VSCode con
  /// "Uncaught Exceptions" o "All Exceptions" pausa en el throw —
  /// el usuario tenía que apretar Play repetidas veces para destrabar
  /// la sesión.
  ///
  /// Este helper usa `Future.any` con un Timer manual: si el timer se
  /// dispara primero, completa con un valor "vacío", el future original
  /// queda volando pero sin afectarnos. Si el future original termina
  /// antes, cancelamos el timer. Nunca hay throw → el debugger no
  /// pausa y el flujo es limpio.
  Future<void> _withSoftTimeout(
    Future<void> Function() task, {
    required Duration timeout,
    required String tag,
    VoidCallback? onTimeoutOrError,
  }) async {
    final completer = Completer<void>();
    Timer? timer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        if (kDebugMode) print('⏰ Timeout en $tag');
        if (onTimeoutOrError != null && _isAlive) onTimeoutOrError();
        completer.complete();
      }
    });

    task().then((_) {
      if (!completer.isCompleted) {
        timer?.cancel();
        completer.complete();
      }
    }).catchError((e) {
      if (!completer.isCompleted) {
        timer?.cancel();
        if (kDebugMode) print('⚠️ Error en $tag: $e');
        if (onTimeoutOrError != null && _isAlive) onTimeoutOrError();
        completer.complete();
      }
    });

    return completer.future;
  }
}
