// lib/features/notifications/presentation/controllers/notifications_controller.dart
import 'dart:async';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:get/get.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_notification_by_id_usecase.dart';
import '../../domain/usecases/create_notification_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/search_notifications_usecase.dart';

class NotificationsController extends GetxController
    with SyncAutoRefreshMixin {
  // Dependencies
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetNotificationByIdUseCase _getNotificationByIdUseCase;
  final CreateNotificationUseCase _createNotificationUseCase;
  final MarkNotificationAsReadUseCase _markAsReadUseCase;
  final MarkAllAsReadUseCase _markAllAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final SearchNotificationsUseCase _searchNotificationsUseCase;

  NotificationsController({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetNotificationByIdUseCase getNotificationByIdUseCase,
    required CreateNotificationUseCase createNotificationUseCase,
    required MarkNotificationAsReadUseCase markAsReadUseCase,
    required MarkAllAsReadUseCase markAllAsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required SearchNotificationsUseCase searchNotificationsUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _getNotificationByIdUseCase = getNotificationByIdUseCase,
        _createNotificationUseCase = createNotificationUseCase,
        _markAsReadUseCase = markAsReadUseCase,
        _markAllAsReadUseCase = markAllAsReadUseCase,
        _deleteNotificationUseCase = deleteNotificationUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _searchNotificationsUseCase = searchNotificationsUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isDeleting = false.obs;
  final _isMarkingAsRead = false.obs;
  final _errorMessage = ''.obs;

  // Datos
  final _notifications = <Notification>[].obs;
  final _searchResults = <Notification>[].obs;
  final _unreadCount = 0.obs;
  final _stats = Rxn<NotificationStats>();

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;
  final _hasPreviousPage = false.obs;

  // Filtros
  final _showUnreadOnly = false.obs;
  final _selectedType = Rxn<NotificationType>();
  final _selectedPriority = Rxn<NotificationPriority>();
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();
  final _searchTerm = ''.obs;
  final _sortBy = 'timestamp'.obs;
  final _sortOrder = 'DESC'.obs;

  // UI Controllers
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;

  // Configuración
  static const int _pageSize = 20;
  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  // Cache para carga rápida
  static List<Notification>? _cachedNotifications;
  static int? _cachedUnreadCount;
  static NotificationStats? _cachedStats;
  static DateTime? _lastCacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isDeleting => _isDeleting.value;
  bool get isMarkingAsRead => _isMarkingAsRead.value;
  String get errorMessage => _errorMessage.value;
  bool get hasMorePages => _hasNextPage.value;

  List<Notification> get notifications => _notifications;
  List<Notification> get searchResults => _searchResults;
  int get unreadCount => _unreadCount.value;
  NotificationStats? get stats => _stats.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;

  bool get showUnreadOnly => _showUnreadOnly.value;
  NotificationType? get selectedType => _selectedType.value;
  NotificationPriority? get selectedPriority => _selectedPriority.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;
  String get searchTerm => _searchTerm.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;

  // Alias for searchTerm for backwards compatibility
  RxString get searchQuery => _searchTerm;

  bool get hasNotifications => _notifications.isNotEmpty;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;
  bool get hasUnreadNotifications => _unreadCount.value > 0;

  // Paginación profesional
  String get paginationInfo =>
      'Página $currentPage de $totalPages ($totalItems notificaciones)';
  double get loadingProgress => totalPages > 0 ? currentPage / totalPages : 0.0;
  bool get canLoadMore =>
      hasNextPage && !_isLoadingMore.value && !_isLoading.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();
    _setupScrollListener();
    _setupSearchListener();
    _setupAutoRefresh();
  }

  @override
  Future<void> onSyncCompleted() async {
    _cachedNotifications = null;
    _cachedUnreadCount = null;
    _cachedStats = null;
    _lastCacheTime = null;
    _refreshInBackground();
  }

  @override
  void onReady() {
    super.onReady();
    print('🔄 NotificationsController: onReady - Controller listo');
    ensureDataLoaded();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _searchDebounceTimer = null;
    _autoRefreshTimer = null;
    super.onClose();
  }

  /// Configurar listener de búsqueda con debounce
  void _setupSearchListener() {
    searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        final query = searchController.text;
        _searchTerm.value = query;
        if (query.trim().isEmpty) {
          _searchResults.clear();
          loadNotifications();
        } else if (query.trim().length >= 2) {
          searchNotifications(query);
        }
      });
    });
  }

  /// Configurar auto-refresh cada 30 segundos
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!_isLoading.value && !_isLoadingMore.value) {
        print('🔄 NotificationsController: Auto-refresh ejecutándose...');
        _refreshInBackground();
      }
    });
  }

  /// Configurar listener del scroll para paginación infinita
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore.value && _hasNextPage.value) {
          loadMoreNotifications();
        }
      }
    });
  }

  // ==================== INITIALIZATION ====================

  /// Asegurar que los datos estén cargados
  Future<void> ensureDataLoaded() async {
    // Intentar usar caché para mostrar datos inmediatamente
    if (_notifications.isEmpty && _isCacheValid()) {
      print('🚀 NotificationsController: Usando caché para carga instantánea');
      _notifications.value = List.from(_cachedNotifications!);
      if (_cachedUnreadCount != null) {
        _unreadCount.value = _cachedUnreadCount!;
      }
      if (_cachedStats != null) {
        _stats.value = _cachedStats;
      }

      // Actualizar en segundo plano si el caché tiene más de 1 minuto
      if (_lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) >
              const Duration(minutes: 1)) {
        _refreshInBackground();
      }
      return;
    }

    // Solo cargar si no hay datos y no está cargando
    if (_notifications.isEmpty && !_isLoading.value) {
      print('🔄 NotificationsController: Cargando datos por primera vez...');
      await loadInitialData();
    } else {
      print('🔄 NotificationsController: Datos ya cargados o cargando...');
    }
  }

  /// Verifica si el caché es válido
  bool _isCacheValid() {
    if (_cachedNotifications == null || _cachedNotifications!.isEmpty) {
      return false;
    }
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration;
  }

  /// Actualiza el caché con los datos actuales
  void _updateCache() {
    _cachedNotifications = List.from(_notifications);
    _cachedUnreadCount = _unreadCount.value;
    _cachedStats = _stats.value;
    _lastCacheTime = DateTime.now();
    print(
      '💾 NotificationsController: Caché actualizado con ${_notifications.length} notificaciones',
    );
  }

  /// Refresca datos en segundo plano sin mostrar loading
  Future<void> _refreshInBackground() async {
    print('🔄 NotificationsController: Refrescando en segundo plano...');
    try {
      await Future.wait([
        _loadNotificationsInternal(),
        _loadUnreadCountInternal(),
        _loadStatsInternal(),
      ]);
      _updateCache();
      print('✅ Actualización en segundo plano completada');
    } catch (e) {
      print('⚠️ Error en actualización en segundo plano: $e');
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar datos iniciales
  Future<void> loadInitialData() async {
    print('🚀 NotificationsController: Iniciando carga inicial...');

    _isLoading.value = true;

    try {
      await Future.wait([
        _loadNotificationsInternal(),
        _loadUnreadCountInternal(),
        _loadStatsInternal(),
      ]);

      _updateCache();
      print('✅ Carga inicial completada exitosamente');
    } catch (e) {
      print('❌ Error en carga inicial: $e');
      _showError('Error de carga', 'No se pudo cargar la información inicial');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar notificaciones interno
  Future<void> _loadNotificationsInternal() async {
    try {
      final result = await _getNotificationsUseCase(
        GetNotificationsParams(
          page: 1,
          limit: _pageSize,
          unreadOnly: _showUnreadOnly.value ? true : null,
          type: _selectedType.value,
          priority: _selectedPriority.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar notificaciones: ${failure.message}');
          _notifications.clear();
        },
        (paginatedResult) {
          _notifications.value = paginatedResult.data;
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Notificaciones cargadas: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando notificaciones: $e');
      _notifications.clear();
    }
  }

  /// Cargar contador de no leídas interno
  Future<void> _loadUnreadCountInternal() async {
    try {
      final result = await _getUnreadCountUseCase(const NoParams());

      result.fold(
        (failure) {
          print('❌ Error al cargar contador no leídas: ${failure.message}');
          _unreadCount.value = 0;
        },
        (count) {
          _unreadCount.value = count;
          print('✅ Contador no leídas: $count');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando contador: $e');
      _unreadCount.value = 0;
    }
  }

  /// Cargar estadísticas interno
  Future<void> _loadStatsInternal() async {
    try {
      final result = await _getNotificationsUseCase(
        GetNotificationsParams(page: 1, limit: 1),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar estadísticas: ${failure.message}');
        },
        (paginatedResult) {
          // Crear estadísticas desde la metadata
          final meta = paginatedResult.meta;
          _stats.value = NotificationStats(
            total: meta.totalItems,
            unread: _unreadCount.value,
            read: meta.totalItems - _unreadCount.value,
            byType: {},
            byPriority: {},
          );
          print('✅ Estadísticas calculadas: ${_stats.value}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando estadísticas: $e');
    }
  }

  /// Cargar notificaciones
  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;

    try {
      await _loadNotificationsInternal();
    } finally {
      if (showLoading) _isLoading.value = false;
    }
  }

  /// Cargar más notificaciones (paginación)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _isLoadingMore.value = true;

    try {
      final result = await _getNotificationsUseCase(
        GetNotificationsParams(
          page: _currentPage.value + 1,
          limit: _pageSize,
          unreadOnly: _showUnreadOnly.value ? true : null,
          type: _selectedType.value,
          priority: _selectedPriority.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar más notificaciones', failure.message);
        },
        (paginatedResult) {
          // Prevenir duplicados
          final existingIds = _notifications.map((n) => n.id).toSet();
          final newNotifications =
              paginatedResult.data
                  .where((notification) => !existingIds.contains(notification.id))
                  .toList();

          if (newNotifications.isNotEmpty) {
            _notifications.addAll(newNotifications);
            print(
              '✅ NotificationsController: Agregadas ${newNotifications.length} notificaciones nuevas',
            );
          } else {
            print(
              '⚠️ NotificationsController: No hay notificaciones nuevas para agregar',
            );
          }

          _updatePaginationInfo(paginatedResult.meta);
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar notificaciones
  Future<void> refreshNotifications() async {
    print('🔄 NotificationsController: Refrescando datos...');

    _currentPage.value = 1;

    await Future.wait([
      _loadNotificationsInternal(),
      _loadUnreadCountInternal(),
      _loadStatsInternal(),
    ]);

    _updateCache();
    print('✅ Datos refrescados exitosamente');
  }

  /// Buscar notificaciones
  Future<void> searchNotifications(String query) async {
    if (query.trim().length < 2) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      final result = await _searchNotificationsUseCase(
        SearchNotificationsParams(query: query.trim(), limit: 50),
      );

      result.fold(
        (failure) {
          _showError('Error en búsqueda', failure.message);
          _searchResults.clear();
        },
        (results) {
          _searchResults.value = results;
        },
      );
    } finally {
      _isSearching.value = false;
    }
  }

  /// Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    _isMarkingAsRead.value = true;

    try {
      final result = await _markAsReadUseCase(
        MarkNotificationAsReadParams(id: notificationId),
      );

      result.fold(
        (failure) {
          _showError('Error al marcar como leída', failure.message);
        },
        (notification) {
          // Actualizar en la lista
          final index =
              _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = notification;
            _notifications.refresh();
          }

          // Decrementar contador de no leídas
          if (_unreadCount.value > 0) {
            _unreadCount.value--;
          }

          print('✅ Notificación marcada como leída: $notificationId');
        },
      );
    } finally {
      _isMarkingAsRead.value = false;
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
    if (!hasUnreadNotifications) {
      _showInfo('Todas las notificaciones ya están leídas');
      return;
    }

    _isMarkingAsRead.value = true;

    try {
      final result = await _markAllAsReadUseCase(const NoParams());

      result.fold(
        (failure) {
          _showError('Error al marcar todas como leídas', failure.message);
        },
        (_) {
          // Actualizar todas las notificaciones en la lista
          _notifications.value = _notifications.map((n) {
            return n.copyWith(isRead: true);
          }).toList();

          _unreadCount.value = 0;
          _showSuccess('Todas las notificaciones marcadas como leídas');
          print('✅ Todas las notificaciones marcadas como leídas');
        },
      );
    } finally {
      _isMarkingAsRead.value = false;
    }
  }

  /// Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    _isDeleting.value = true;

    try {
      final result = await _deleteNotificationUseCase(
        DeleteNotificationParams(id: notificationId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          // Verificar si la notificación estaba sin leer antes de eliminarla
          final notification =
              _notifications.firstWhereOrNull((n) => n.id == notificationId);
          final wasUnread = notification != null && !notification.isRead;

          // Remover de la lista local
          _notifications.removeWhere((n) => n.id == notificationId);

          // Actualizar contador si era no leída
          if (wasUnread && _unreadCount.value > 0) {
            _unreadCount.value--;
          }

          _showSuccess('Notificación eliminada exitosamente');
          print('✅ Notificación eliminada: $notificationId');
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Obtener notificación por ID
  Future<Notification?> getNotificationById(String notificationId) async {
    try {
      final result = await _getNotificationByIdUseCase(
        GetNotificationByIdParams(id: notificationId),
      );

      return result.fold(
        (failure) {
          _showError('Error al obtener notificación', failure.message);
          return null;
        },
        (notification) => notification,
      );
    } catch (e) {
      print('❌ Error inesperado obteniendo notificación: $e');
      return null;
    }
  }

  // ==================== FILTER & SORT METHODS ====================

  /// Toggle filtro de solo no leídas
  void toggleUnreadFilter() {
    _showUnreadOnly.value = !_showUnreadOnly.value;
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Aplicar filtro por tipo
  void applyTypeFilter(NotificationType? type) {
    _selectedType.value = type;
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Alias for applyTypeFilter for backwards compatibility
  void filterByType(NotificationType? type) => applyTypeFilter(type);

  /// Aplicar filtro por prioridad
  void applyPriorityFilter(NotificationPriority? priority) {
    _selectedPriority.value = priority;
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Alias for applyPriorityFilter for backwards compatibility
  void filterByPriority(NotificationPriority? priority) => applyPriorityFilter(priority);

  /// Aplicar filtro por rango de fechas
  void applyDateFilter(DateTime? startDate, DateTime? endDate) {
    _startDate.value = startDate;
    _endDate.value = endDate;
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Cambiar ordenamiento
  void changeSorting(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Limpiar filtros
  void clearFilters() {
    _showUnreadOnly.value = false;
    _selectedType.value = null;
    _selectedPriority.value = null;
    _startDate.value = null;
    _endDate.value = null;
    _searchTerm.value = '';
    searchController.clear();
    _searchResults.clear();
    _currentPage.value = 1;
    loadNotifications();
  }

  /// Limpiar todos los filtros y refrescar lista completamente
  Future<void> clearFiltersAndRefresh() async {
    print('🔄 NotificationsController: Limpiando filtros y refrescando...');

    clearFilters();
    await refreshNotifications();

    print('✅ NotificationsController: Filtros limpiados y lista refrescada');
  }

  /// Búsqueda con debounce
  void debouncedSearch(String query) {
    print('🔍 debouncedSearch LLAMADO con: "$query"');

    _searchDebounceTimer?.cancel();
    _searchTerm.value = query;

    if (query.trim().isEmpty) {
      print('   🧹 Query vacío, limpiando resultados');
      _searchResults.clear();
      loadNotifications();
      return;
    }

    if (query.trim().length >= 2) {
      print('   ⏱️ Creando timer de 500ms para buscar: "$query"');
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        print('   🚀 Timer expiró, ejecutando searchNotifications("$query")');
        searchNotifications(query);
      });
    }
  }

  // ==================== NAVEGACIÓN DE PAGINACIÓN ====================

  /// Ir a una página específica
  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 ||
        pageNumber > totalPages ||
        pageNumber == currentPage) {
      return;
    }

    print('🔄 NotificationsController: Navegando a página $pageNumber');
    _currentPage.value = pageNumber;
    await loadNotifications();
  }

  /// Ir a la primera página
  Future<void> goToFirstPage() async {
    if (currentPage == 1) return;
    await goToPage(1);
  }

  /// Ir a la última página
  Future<void> goToLastPage() async {
    if (currentPage == totalPages) return;
    await goToPage(totalPages);
  }

  /// Ir a la página siguiente
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    await goToPage(currentPage + 1);
  }

  /// Ir a la página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    await goToPage(currentPage - 1);
  }

  // ==================== UI HELPERS ====================

  /// Confirmar eliminación
  void confirmDelete(Notification notification) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Notificación'),
        content: Text(
          '¿Estás seguro que deseas eliminar esta notificación?\n\n'
          '"${notification.title}"\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteNotification(notification.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar detalles de notificación
  void showNotificationDetails(String notificationId) {
    // Marcar como leída al ver detalles
    final notification =
        _notifications.firstWhereOrNull((n) => n.id == notificationId);
    if (notification != null && !notification.isRead) {
      markAsRead(notificationId);
    }

    Get.toNamed('/notifications/detail/$notificationId');
  }

  // ==================== PRIVATE METHODS ====================

  /// Actualizar información de paginación
  void _updatePaginationInfo(PaginationMeta meta) {
    _currentPage.value = meta.page;
    _totalPages.value = meta.totalPages;
    _totalItems.value = meta.totalItems;
    _hasNextPage.value = meta.hasNextPage;
    _hasPreviousPage.value = meta.hasPreviousPage;
  }

  /// Mostrar mensaje de error
  void _showError(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: duration ?? const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Mostrar mensaje de éxito
  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Mostrar mensaje informativo
  void _showInfo(String message) {
    Get.snackbar(
      'Información',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
