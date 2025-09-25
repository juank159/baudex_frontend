// lib/features/dashboard/presentation/controllers/dashboard_controller.dart
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/entities/recent_activity_advanced.dart' hide ActivityType;
import '../../domain/entities/smart_notification.dart';
import '../../domain/entities/notification.dart' as dashboard;
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';

class DashboardController extends GetxController {
  final GetDashboardStatsUseCase _getDashboardStatsUseCase;
  final GetRecentActivityUseCase _getRecentActivityUseCase;
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationAsReadUseCase _markNotificationAsReadUseCase;
  final GetUnreadNotificationsCountUseCase _getUnreadNotificationsCountUseCase;
  final GetProfitabilityStatsUseCase _getProfitabilityStatsUseCase;

  DashboardController({
    required GetDashboardStatsUseCase getDashboardStatsUseCase,
    required GetRecentActivityUseCase getRecentActivityUseCase,
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationAsReadUseCase markNotificationAsReadUseCase,
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

  // Error states
  final _statsError = Rxn<String>();
  final _activityError = Rxn<String>();
  final _notificationsError = Rxn<String>();
  final _profitabilityError = Rxn<String>();

  // Filters
  final _selectedDateRange = Rxn<DateTimeRange>();
  final _selectedActivityTypes = <ActivityType>[].obs;
  final _selectedPeriod = 'hoy'.obs;

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

  @override
  void onInit() {
    super.onInit();
    print('🚀 DashboardController: Iniciando controlador...');
    
    // ✅ Marcar como cargando desde el inicio
    _isLoadingStats.value = true;
    _isLoadingActivity.value = true;
    _isLoadingNotifications.value = true;
    _isLoadingProfitability.value = true;
    
    // Cargar datos con pequeño delay para evitar problemas de navegación
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      print('📊 Dashboard: Iniciando carga de datos...');
      
      // Aplicar el período inicial seleccionado (hoy) antes de cargar datos
      setPredefinedPeriod(_selectedPeriod.value);
      
      // ✅ CRÍTICO: Cargar estadísticas principales primero (son las más importantes)
      print('📊 Dashboard: Cargando estadísticas principales...');
      await loadDashboardStats(
        startDate: _selectedDateRange.value?.start,
        endDate: _selectedDateRange.value?.end,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => print('⏰ Timeout en estadísticas del dashboard'),
      );
      
      // Ejecutar datos secundarios en paralelo con timeout
      print('📊 Dashboard: Cargando datos secundarios...');
      await Future.wait([
        loadRecentActivity().timeout(
          const Duration(seconds: 8),
          onTimeout: () => print('⏰ Timeout en actividad reciente'),
        ).catchError((e) => print('❌ Error loading activity: $e')),
        
        loadNotifications().timeout(
          const Duration(seconds: 8),
          onTimeout: () => print('⏰ Timeout en notificaciones'),
        ).catchError((e) => print('❌ Error loading notifications: $e')),
        
        loadUnreadNotificationsCount().timeout(
          const Duration(seconds: 5),
          onTimeout: () => print('⏰ Timeout en conteo de notificaciones'),
        ).catchError((e) => print('❌ Error loading unread count: $e')),
        
        _loadExpensesByCategory().timeout(
          const Duration(seconds: 8),
          onTimeout: () => print('⏰ Timeout en gastos por categoría'),
        ).catchError((e) => print('❌ Error loading expenses by category: $e')),
        
        loadProfitabilityStats(
          startDate: _selectedDateRange.value?.start,
          endDate: _selectedDateRange.value?.end,
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => print('⏰ Timeout en métricas de rentabilidad'),
        ).catchError((e) => print('❌ Error loading profitability: $e')),
      ]);
      
      print('✅ Dashboard: Carga inicial completada exitosamente');
    } catch (e) {
      print('❌ Error crítico en _loadInitialData: $e');
      // Asegurar que todos los estados de loading se reseteen
      _isLoadingStats.value = false;
      _isLoadingActivity.value = false;
      _isLoadingNotifications.value = false;
      _isLoadingExpenseChart.value = false;
      _isLoadingProfitability.value = false;
    }
  }

  Future<void> loadDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingStats.value = true;
    _statsError.value = null;

    final result = await _getDashboardStatsUseCase(
      GetDashboardStatsParams(startDate: startDate, endDate: endDate),
    );

    result.fold(
      (failure) => _statsError.value = _mapFailureToMessage(failure),
      (stats) => _dashboardStats.value = stats,
    );

    _isLoadingStats.value = false;
  }

  Future<void> loadProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  }) async {
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

    result.fold(
      (failure) {
        print('❌ ERROR loadProfitabilityStats: $failure');
        _profitabilityError.value = _mapFailureToMessage(failure);
      },
      (stats) {
        print('✅ ÉXITO loadProfitabilityStats: Revenue=${stats.totalRevenue}, COGS=${stats.totalCOGS}');
        _profitabilityStats.value = stats;
      },
    );

    _isLoadingProfitability.value = false;
  }

  Future<void> loadRecentActivity({
    int limit = 10,
    List<ActivityType>? types,
  }) async {
    _isLoadingActivity.value = true;
    _activityError.value = null;

    try {
      // Usar el nuevo endpoint de actividades avanzadas con paginación
      await loadAdvancedRecentActivities(page: 1, limit: limit);
    } catch (e) {
      // Fallback al método original si falla
      final result = await _getRecentActivityUseCase(
        GetRecentActivityParams(limit: limit, types: types),
      );

      result.fold(
        (failure) => _activityError.value = _mapFailureToMessage(failure),
        (activities) => _recentActivities.assignAll(activities),
      );
    }

    _isLoadingActivity.value = false;
  }

  // Nuevo método para cargar actividades avanzadas con paginación
  Future<void> loadAdvancedRecentActivities({
    int page = 1,
    int limit = 10,
    String? category,
    String? priority,
    String? timeFilter,
  }) async {
    try {
      // Obtener DioClient desde GetX
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
        // La estructura es: response.data.data.data.activities (anidación triple)
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
        
        if (activitiesJson != null) {
          // Convertir a RecentActivityAdvanced usando el fromJson
          final activities = activitiesJson
              .map((json) => RecentActivityAdvanced.fromJson(json))
              .toList();
              
          if (page == 1) {
            // Primera página - reemplazar datos
            _recentActivitiesAdvanced.assignAll(activities);
          } else {
            // Páginas siguientes - agregar datos
            _recentActivitiesAdvanced.addAll(activities);
          }
          
          // Actualizar información de paginación si es necesaria
          print('✅ Actividades cargadas: ${activities.length} items (página $page)');
        } else {
          print('⚠️ No se encontraron actividades en la respuesta');
          _recentActivitiesAdvanced.clear();
        }
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      _activityError.value = 'Error al cargar actividades: $e';
      print('Error loading advanced activities: $e');
      // No hacer rethrow para evitar interrumpir el flujo completo
    }
  }

  Future<void> loadNotifications({int limit = 10, bool? unreadOnly}) async {
    _isLoadingNotifications.value = true;
    _notificationsError.value = null;

    try {
      // Usar el nuevo endpoint de notificaciones avanzadas con paginación
      await loadAdvancedNotifications(page: 1, limit: limit, includeRead: !(unreadOnly ?? false));
    } catch (e) {
      // Fallback al método original si falla
      final result = await _getNotificationsUseCase(
        GetNotificationsParams(limit: limit, unreadOnly: unreadOnly),
      );

      result.fold(
        (failure) => _notificationsError.value = _mapFailureToMessage(failure),
        (notifications) => _notifications.assignAll(notifications),
      );
    }

    _isLoadingNotifications.value = false;
  }

  // Nuevo método para cargar notificaciones avanzadas con paginación
  Future<void> loadAdvancedNotifications({
    int page = 1,
    int limit = 10,
    List<String>? priorities,
    List<String>? types,
    bool includeRead = false,
  }) async {
    try {
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
        // La estructura es: response.data.data.data.notifications (anidación triple)
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
        
        if (notificationsJson != null) {
          // Convertir a SmartNotification usando el fromJson
          final notifications = notificationsJson
              .map((json) => SmartNotification.fromJson(json))
              .toList();
              
          if (page == 1) {
            // Primera página - reemplazar datos
            _smartNotifications.assignAll(notifications);
          } else {
            // Páginas siguientes - agregar datos
            _smartNotifications.addAll(notifications);
          }
          
          // También actualizar el contador
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
      _notificationsError.value = 'Error al cargar notificaciones: $e';
      print('Error loading advanced notifications: $e');
      // No hacer rethrow para evitar interrumpir el flujo completo
    }
  }

  Future<void> loadUnreadNotificationsCount() async {
    final result = await _getUnreadNotificationsCountUseCase(NoParams());

    result.fold(
      (failure) => {}, // Silently fail for count
      (count) => _unreadNotificationsCount.value = count,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final result = await _markNotificationAsReadUseCase(
      MarkNotificationAsReadParams(notificationId: notificationId),
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
    
    // Cargar todos los datos en paralelo para mejor rendimiento
    Future.wait([
      loadDashboardStats(startDate: dateRange?.start, endDate: dateRange?.end),
      loadProfitabilityStats(startDate: dateRange?.start, endDate: dateRange?.end), // ✅ AGREGAR RENTABILIDAD FIFO
      _loadExpensesByCategory(), // También recargar datos de categorías con el nuevo filtro
    ]).then((_) {
      print('✅ Datos del rango personalizado cargados completamente');
    }).catchError((error) {
      print('⚠️ Error cargando datos para rango personalizado: $error');
    });
  }

  void setActivityTypes(List<ActivityType> types) {
    _selectedActivityTypes.assignAll(types);
    loadRecentActivity(types: types.isEmpty ? null : types);
  }

  void clearFilters() {
    _selectedDateRange.value = null;
    _selectedActivityTypes.clear();
    _selectedPeriod.value = 'hoy';
    _loadInitialData();
  }

  void setPredefinedPeriod(String period) {
    print('🔄 Cambiando período a: $period');
    _selectedPeriod.value = period;
    final now = DateTime.now();
    DateTimeRange? dateRange;

    switch (period) {
      case 'hoy':
        // Use DateTime.now() to ensure we get today's date in local timezone
        final today = DateTime.now();
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
      default:
        dateRange = null;
    }

    _selectedDateRange.value = dateRange;
    print('🔄 Nuevo rango de fechas: ${dateRange?.start} - ${dateRange?.end}');
    
    // Cargar todos los datos en paralelo para mejor rendimiento
    Future.wait([
      loadDashboardStats(startDate: dateRange?.start, endDate: dateRange?.end),
      loadProfitabilityStats(startDate: dateRange?.start, endDate: dateRange?.end), // ✅ AGREGAR RENTABILIDAD FIFO
      _loadExpensesByCategory(), // También recargar datos de categorías con el nuevo filtro
    ]).then((_) {
      print('✅ Datos del período $period cargados completamente');
    }).catchError((error) {
      print('⚠️ Error cargando datos para período $period: $error');
    });
  }

  Future<void> refreshAll() async {
    try {
      await _loadInitialData();
    } catch (e) {
      print('Error in refreshAll: $e');
      // Asegurar que los estados de loading se reseteen incluso si hay error
      _isLoadingStats.value = false;
      _isLoadingActivity.value = false;
      _isLoadingNotifications.value = false;
      _isLoadingProfitability.value = false;
    }
  }

  Future<void> refreshStats() async {
    await loadDashboardStats(
      startDate: _selectedDateRange.value?.start,
      endDate: _selectedDateRange.value?.end,
    );
  }

  Future<void> refreshActivity() async {
    await loadRecentActivity(
      types: _selectedActivityTypes.isEmpty ? null : _selectedActivityTypes,
    );
  }

  Future<void> refreshNotifications() async {
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
    _isLoadingExpenseChart.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      
      // PASO 1: Obtener las categorías para mapear IDs a nombres
      final categoriesMap = await _loadCategoriesMap();
      
      // Usar las mismas fechas del período seleccionado
      final dateRange = _selectedDateRange.value;
      final expensesByCategory = <String, double>{};
      
      int page = 1;
      const int limit = 100; // Límite máximo permitido por el backend
      bool hasMoreData = true;
      
      while (hasMoreData) {
        try {
          final params = <String, dynamic>{
            'page': page,
            'limit': limit,
            'status': 'approved', // Solo gastos aprobados
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
            
            // Procesar gastos de esta página
            for (int expenseIndex = 0; expenseIndex < expenses.length; expenseIndex++) {
              final expenseJson = expenses[expenseIndex];
              print('🔍 Processing expense $expenseIndex: ${expenseJson.runtimeType}');
              
              if (expenseJson is Map<String, dynamic>) {
                try {
                  // El amount viene como String, necesitamos parsearlo
                  final amountStr = expenseJson['amount']?.toString() ?? '0';
                  final amount = double.tryParse(amountStr) ?? 0.0;
                  
                  final category = expenseJson['category'];
                  String categoryName = 'Sin categoría';
                  
                  print('🔍 Expense $expenseIndex category: ${category.runtimeType}');
                  
                  // Si category es null, buscar por categoryId en el mapa
                  if (category != null && category is Map<String, dynamic>) {
                    categoryName = category['name']?.toString() ?? 'Sin categoría';
                    print('🔍 Category from object: $categoryName');
                  } else {
                    final categoryId = expenseJson['categoryId']?.toString();
                    print('🔍 CategoryId: $categoryId');
                    
                    if (categoryId != null && categoryId.isNotEmpty) {
                      // Usar el nombre real de la categoría del mapa
                      categoryName = categoriesMap[categoryId] ?? 'Categoría desconocida';
                      print('🔍 Category from map: $categoryName');
                    }
                  }
                  
                  expensesByCategory[categoryName] = (expensesByCategory[categoryName] ?? 0) + amount;
                  
                  print('   💰 Gasto: $amountStr -> $amount ($categoryName)');
                } catch (expenseError) {
                  print('⚠️ Error processing expense $expenseIndex: $expenseError');
                }
              } else {
                print('⚠️ Expense $expenseIndex is not a Map: ${expenseJson.runtimeType}');
              }
            }
            
            // Verificar si hay más páginas
            hasMoreData = page < totalPages;
            page++;
            
            // Prevenir bucle infinito
            if (page > 50) {
              print('⚠️ Límite de páginas alcanzado (50), deteniendo carga');
              break;
            }
          } else {
            print('⚠️ Error en respuesta página $page: ${response.statusCode}');
            break;
          }
        } catch (pageError) {
          print('⚠️ Error cargando página $page: $pageError');
          break;
        }
      }
      
      // Actualizar el dashboardStats con los nuevos datos de categorías
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
        
        print('🔍 DEBUG updatedExpenseStats:');
        print('   totalAmount: ${updatedExpenseStats.totalAmount}');
        print('   expensesByCategory: ${updatedExpenseStats.expensesByCategory}');
        
        _dashboardStats.value = DashboardStats(
          sales: currentStats.sales,
          invoices: currentStats.invoices,
          products: currentStats.products,
          customers: currentStats.customers,
          expenses: updatedExpenseStats,
          profitability: currentStats.profitability,
        );
        
        print('🔍 DEBUG _dashboardStats.value después de actualizar:');
        print('   totalAmount: ${_dashboardStats.value?.expenses.totalAmount}');
        print('   expensesByCategory: ${_dashboardStats.value?.expenses.expensesByCategory}');
        
        // FORZAR ACTUALIZACIÓN DEL UI
        print('🔄 Forzando actualización del UI...');
        update(); // Forzar actualización de GetX
      }
      
      print('✅ Gastos por categoría cargados: ${expensesByCategory.length} categorías');
      expensesByCategory.forEach((category, amount) {
        print('   - $category: \$${amount.toStringAsFixed(0)}');
      });
      
    } catch (e) {
      print('⚠️ Error cargando gastos por categoría: $e');
      // No hacer rethrow - es un error no crítico
    } finally {
      _isLoadingExpenseChart.value = false;
    }
  }

  // Método para cargar mapa de categorías (ID -> Nombre)
  Future<Map<String, String>> _loadCategoriesMap() async {
    try {
      final dioClient = Get.find<DioClient>();
      
      final response = await dioClient.get(
        '/expense-categories',
        queryParameters: {'limit': 100}, // Obtener muchas categorías
      );

      if (response.statusCode == 200) {
        print('🔍 Response status: ${response.statusCode}');
        print('🔍 Response data structure: ${response.data.runtimeType}');
        
        final responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          print('⚠️ Response data is not a Map: ${responseData.runtimeType}');
          return <String, String>{};
        }
        
        // Verificar la estructura de la respuesta
        print('🔍 Response keys: ${responseData.keys.toList()}');
        
        // Manejar diferentes estructuras de respuesta
        List<dynamic>? categories;
        
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          print('🔍 Data structure: ${data.runtimeType}');
          
          if (data is Map<String, dynamic> && data.containsKey('categories')) {
            // Estructura: {data: {categories: [...]}}
            categories = data['categories'] as List<dynamic>?;
            print('🔍 Found categories in data.categories: ${categories?.length}');
          } else if (data is List<dynamic>) {
            // Estructura: {data: [...]}
            categories = data;
            print('🔍 Found categories directly in data: ${categories.length}');
          }
        } else if (responseData.containsKey('categories')) {
          // Estructura: {categories: [...]}
          categories = responseData['categories'] as List<dynamic>?;
          print('🔍 Found categories in root: ${categories?.length}');
        }
        
        if (categories == null || categories.isEmpty) {
          print('⚠️ No categories found in response');
          return <String, String>{};
        }
        
        final categoriesMap = <String, String>{};
        for (int i = 0; i < categories.length; i++) {
          final categoryJson = categories[i];
          print('🔍 Processing category $i: ${categoryJson.runtimeType}');
          
          if (categoryJson is Map<String, dynamic>) {
            final id = categoryJson['id']?.toString();
            final name = categoryJson['name']?.toString() ?? 'Sin nombre';
            print('🔍 Category $i: id=$id, name=$name');
            
            if (id != null && id.isNotEmpty) {
              categoriesMap[id] = name;
            }
          } else {
            print('⚠️ Category $i is not a Map: ${categoryJson.runtimeType}');
          }
        }
        
        print('📋 Categorías cargadas: ${categoriesMap.length}');
        categoriesMap.forEach((id, name) {
          print('   📋 $id -> $name');
        });
        
        return categoriesMap;
      } else {
        print('⚠️ Response status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('⚠️ Error cargando categorías: $e');
      print('🔍 Stack trace: $stackTrace');
    }
    
    return <String, String>{}; // Mapa vacío en caso de error
  }

  // Helper methods for chart data
  Map<String, double> get expensesByCategory {
    final expensesByCategory = dashboardStats?.expenses.expensesByCategory ?? {};
    
    print('🔍 DEBUG expensesByCategory getter called: ${expensesByCategory.length} categorías');
    expensesByCategory.forEach((category, amount) {
      print('   🔍 $category: \$${amount.toStringAsFixed(0)}');
    });
    
    // Si no hay datos reales, devolver mapa vacío para mostrar "Sin datos"
    if (expensesByCategory.isEmpty) {
      print('⚠️ expensesByCategory está vacío, mostrando "Sin datos"');
      return <String, double>{};
    }
    
    return expensesByCategory;
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
    _isLoadingStats.close();
    _isLoadingActivity.close();
    _isLoadingNotifications.close();
    _isLoadingExpenseChart.close();
    _isLoadingProfitability.close();
    _dashboardStats.close();
    _profitabilityStats.close();
    _recentActivities.close();
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
