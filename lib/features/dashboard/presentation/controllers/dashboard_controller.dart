// lib/features/dashboard/presentation/controllers/dashboard_controller.dart
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
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

  DashboardController({
    required GetDashboardStatsUseCase getDashboardStatsUseCase,
    required GetRecentActivityUseCase getRecentActivityUseCase,
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationAsReadUseCase markNotificationAsReadUseCase,
    required GetUnreadNotificationsCountUseCase
    getUnreadNotificationsCountUseCase,
  }) : _getDashboardStatsUseCase = getDashboardStatsUseCase,
       _getRecentActivityUseCase = getRecentActivityUseCase,
       _getNotificationsUseCase = getNotificationsUseCase,
       _markNotificationAsReadUseCase = markNotificationAsReadUseCase,
       _getUnreadNotificationsCountUseCase = getUnreadNotificationsCountUseCase;

  // Reactive state
  final _isLoadingStats = false.obs;
  final _isLoadingActivity = false.obs;
  final _isLoadingNotifications = false.obs;
  final _dashboardStats = Rxn<DashboardStats>();
  final _recentActivities = <RecentActivity>[].obs;
  final _recentActivitiesAdvanced = <RecentActivityAdvanced>[].obs;
  final _notifications = <dashboard.Notification>[].obs;
  final _smartNotifications = <SmartNotification>[].obs;
  final _unreadNotificationsCount = 0.obs;

  // Error states
  final _statsError = Rxn<String>();
  final _activityError = Rxn<String>();
  final _notificationsError = Rxn<String>();

  // Filters
  final _selectedDateRange = Rxn<DateTimeRange>();
  final _selectedActivityTypes = <ActivityType>[].obs;
  final _selectedPeriod = 'hoy'.obs;

  // Getters
  bool get isLoadingStats => _isLoadingStats.value;
  bool get isLoadingActivity => _isLoadingActivity.value;
  bool get isLoadingNotifications => _isLoadingNotifications.value;
  bool get isLoading =>
      isLoadingStats || isLoadingActivity || isLoadingNotifications;

  DashboardStats? get dashboardStats => _dashboardStats.value;
  List<RecentActivity> get recentActivities => _recentActivities;
  List<RecentActivityAdvanced> get recentActivitiesAdvanced => _recentActivitiesAdvanced;
  List<dashboard.Notification> get notifications => _notifications;
  List<SmartNotification> get smartNotifications => _smartNotifications;
  int get unreadNotificationsCount => _unreadNotificationsCount.value;

  String? get statsError => _statsError.value;
  String? get activityError => _activityError.value;
  String? get notificationsError => _notificationsError.value;

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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Ejecutar en paralelo pero con manejo independiente de errores
      await Future.wait([
        loadDashboardStats().catchError((e) => print('Error loading stats: $e')),
        loadRecentActivity().catchError((e) => print('Error loading activity: $e')),
        loadNotifications().catchError((e) => print('Error loading notifications: $e')),
        loadUnreadNotificationsCount().catchError((e) => print('Error loading unread count: $e')),
      ]);
    } catch (e) {
      print('Error in _loadInitialData: $e');
      // Asegurar que todos los estados de loading se reseteen
      _isLoadingStats.value = false;
      _isLoadingActivity.value = false;
      _isLoadingNotifications.value = false;
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
        // La estructura es: response.data.data.data.activities (debido a la envoltura)
        final responseData = response.data['data']; // Primera capa de data
        final actualData = responseData['data']; // Segunda capa de data  
        final activitiesJson = actualData['activities'] as List?;
        
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
        // La estructura es: response.data.data.data.notifications (debido a la envoltura)
        final responseData = response.data['data']; // Primera capa de data
        final actualData = responseData['data']; // Segunda capa de data
        final notificationsJson = actualData['notifications'] as List?;
        
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
          _unreadNotificationsCount.value = actualData['unreadCount'] as int? ?? 0;
          
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
    _selectedDateRange.value = dateRange;
    _selectedPeriod.value = 'custom';
    loadDashboardStats(startDate: dateRange?.start, endDate: dateRange?.end);
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
    _selectedPeriod.value = period;
    final now = DateTime.now();
    DateTimeRange? dateRange;

    switch (period) {
      case 'hoy':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
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
    loadDashboardStats(startDate: dateRange?.start, endDate: dateRange?.end);
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
    _dashboardStats.close();
    _recentActivities.close();
    _notifications.close();
    _unreadNotificationsCount.close();
    _statsError.close();
    _activityError.close();
    _notificationsError.close();
    _selectedDateRange.close();
    _selectedActivityTypes.close();
    _selectedPeriod.close();
    super.onClose();
  }
}
