// lib/features/purchase_orders/presentation/controllers/purchase_orders_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';
import '../../domain/usecases/delete_purchase_order_usecase.dart';
import '../../domain/usecases/search_purchase_orders_usecase.dart';
import '../../domain/usecases/get_purchase_order_stats_usecase.dart';
import '../../domain/usecases/approve_purchase_order_usecase.dart';
import '../../domain/repositories/purchase_order_repository.dart';

class PurchaseOrdersController extends GetxController
    with SyncAutoRefreshMixin {
  final GetPurchaseOrdersUseCase getPurchaseOrdersUseCase;
  final DeletePurchaseOrderUseCase deletePurchaseOrderUseCase;
  final SearchPurchaseOrdersUseCase searchPurchaseOrdersUseCase;
  final GetPurchaseOrderStatsUseCase getPurchaseOrderStatsUseCase;
  final ApprovePurchaseOrderUseCase approvePurchaseOrderUseCase;

  PurchaseOrdersController({
    required this.getPurchaseOrdersUseCase,
    required this.deletePurchaseOrderUseCase,
    required this.searchPurchaseOrdersUseCase,
    required this.getPurchaseOrderStatsUseCase,
    required this.approvePurchaseOrderUseCase,
  });

  // ==================== CACHÉ ESTÁTICO (DRY: InvoiceListController) ====================
  static List<PurchaseOrder>? _cachedOrders;
  static PurchaseOrderStats? _cachedStats;
  static DateTime? _lastCacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);
  static bool _needsRefreshOnNextVisit = false;

  static bool _isCacheValid() {
    if (_cachedOrders == null || _lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration;
  }

  static void _updateCache(List<PurchaseOrder> orders, PurchaseOrderStats? statsData) {
    _cachedOrders = List.from(orders);
    _cachedStats = statsData;
    _lastCacheTime = DateTime.now();
  }

  /// Invalidar cache para forzar refresh en próxima visita
  static void invalidateCache() {
    _cachedOrders = null;
    _cachedStats = null;
    _lastCacheTime = null;
    _needsRefreshOnNextVisit = true;
  }

  // Guard para evitar refresh concurrentes en background
  bool _isRefreshingInBackground = false;

  // ==================== REACTIVE VARIABLES ====================

  final RxList<PurchaseOrder> purchaseOrders = <PurchaseOrder>[].obs;
  final RxList<PurchaseOrder> filteredPurchaseOrders = <PurchaseOrder>[].obs;
  final Rx<PurchaseOrderStats?> stats = Rx<PurchaseOrderStats?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // Filtros
  final Rx<PurchaseOrderStatus?> statusFilter = Rx<PurchaseOrderStatus?>(null);
  final Rx<PurchaseOrderPriority?> priorityFilter = Rx<PurchaseOrderPriority?>(
    null,
  );
  final RxString supplierIdFilter = ''.obs;
  final Rx<DateTime?> startDateFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> endDateFilter = Rx<DateTime?>(null);
  final RxBool showOverdueOnly = false.obs;
  final RxBool showPendingApprovalOnly = false.obs;

  // Paginación
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPrevPage = false.obs;
  static const int pageSize = 20;

  // Ordenamiento
  final RxString sortBy = 'orderDate'.obs;
  final RxString sortOrder = 'desc'.obs;

  // UI State
  final RxBool isRefreshing = false.obs;
  final RxBool showFilters = false.obs;
  final RxInt selectedTab = 0.obs; // 0: Lista, 1: Estadísticas

  // Controllers para búsqueda
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();
    _initializeData();
    _setupSearchListener();
  }

  @override
  Future<void> onSyncCompleted() async {
    invalidateCache();
    _refreshInBackground();
  }

  @override
  void onReady() {
    super.onReady();
    // Solo refrescar si hay una nueva orden, _initializeData() ya carga datos en onInit
    final parameters = Get.parameters;
    if (parameters.containsKey('newOrderId')) {
      print(
        '🎆 Nueva orden detectada: ${parameters['newOrderId']}, forzando refresh',
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        refreshPurchaseOrders();
      });
    }
  }

  @override
  void onClose() {
    // Don't dispose searchController since we're using permanent: true
    // This prevents the disposed controller error
    // searchController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    loadPurchaseOrders();
    loadStats();
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      if (searchController.text != searchQuery.value) {
        searchQuery.value = searchController.text;
        _debounceSearch();
      }
    });
  }

  void _debounceSearch() {
    // Cancelar timer anterior si existe
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();

    // Crear nuevo timer
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery.value.isNotEmpty) {
        searchPurchaseOrders(searchQuery.value);
      } else {
        filteredPurchaseOrders.value = purchaseOrders;
      }
    });
  }

  Timer? _searchTimer;

  /// Refrescar datos en background sin afectar UI
  Future<void> _refreshInBackground() async {
    if (_isRefreshingInBackground) return; // Evitar llamadas concurrentes
    _isRefreshingInBackground = true;
    try {
      final params = PurchaseOrderQueryParams(
        page: 1,
        limit: pageSize,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );
      final result = await getPurchaseOrdersUseCase(params);
      result.fold((_) {}, (response) {
        if (!isClosed) {
          purchaseOrders.value = response.data;
          if (searchQuery.value.isEmpty) {
            filteredPurchaseOrders.value = response.data;
          }
          _updateCache(response.data, stats.value);
        }
      });
      // También refrescar stats en background
      final statsResult = await getPurchaseOrderStatsUseCase(const NoParams());
      statsResult.fold((_) {}, (s) {
        if (!isClosed) {
          stats.value = s;
          _cachedStats = s;
        }
      });
    } catch (_) {
    } finally {
      _isRefreshingInBackground = false;
    }
  }

  /// Verificar si hay filtros activos
  bool _hasActiveFilters() {
    return statusFilter.value != null || priorityFilter.value != null ||
        supplierIdFilter.value.isNotEmpty || startDateFilter.value != null ||
        endDateFilter.value != null || showOverdueOnly.value ||
        showPendingApprovalOnly.value;
  }

  // ==================== DATA LOADING ====================

  Future<void> loadPurchaseOrders({bool showLoading = true, bool forceRefresh = false}) async {
    // Cache-first: Si hay cache válido y no hay filtros/búsqueda, usar cache
    if (!forceRefresh && !_needsRefreshOnNextVisit && _isCacheValid() &&
        currentPage.value == 1 && searchQuery.value.isEmpty && !_hasActiveFilters()) {
      purchaseOrders.value = List.from(_cachedOrders!);
      filteredPurchaseOrders.value = List.from(_cachedOrders!);
      if (_cachedStats != null) stats.value = _cachedStats;
      isLoading.value = false;
      _refreshInBackground();
      return;
    }
    _needsRefreshOnNextVisit = false;

    try {
      if (showLoading) isLoading.value = true;
      error.value = '';

      final params = PurchaseOrderQueryParams(
        page: currentPage.value,
        limit: pageSize,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        status: statusFilter.value,
        priority: priorityFilter.value,
        supplierId:
            supplierIdFilter.value.isNotEmpty ? supplierIdFilter.value : null,
        startDate: startDateFilter.value,
        endDate: endDateFilter.value,
        isOverdue: showOverdueOnly.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getPurchaseOrdersUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          if (currentPage.value == 1) {
            purchaseOrders.value = paginatedResult.data;
          } else {
            purchaseOrders.addAll(paginatedResult.data);
          }

          // Actualizar metadatos de paginación
          if (paginatedResult.meta != null) {
            totalPages.value = paginatedResult.meta!.totalPages;
            totalItems.value = paginatedResult.meta!.total;
            hasNextPage.value = paginatedResult.meta!.hasNext;
            hasPrevPage.value = paginatedResult.meta!.hasPrev;
          }

          // Si no hay búsqueda activa, actualizar lista filtrada
          if (searchQuery.value.isEmpty) {
            filteredPurchaseOrders.value = purchaseOrders;
          }

          // Actualizar cache en página 1 sin filtros
          if (currentPage.value == 1 && searchQuery.value.isEmpty && !_hasActiveFilters()) {
            _updateCache(purchaseOrders.toList(), stats.value);
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> searchPurchaseOrders(String query) async {
    if (query.isEmpty) {
      filteredPurchaseOrders.value = purchaseOrders;
      return;
    }

    try {
      isSearching.value = true;

      final params = SearchPurchaseOrdersParams(searchTerm: query, limit: 50);

      final result = await searchPurchaseOrdersUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          filteredPurchaseOrders.value = purchaseOrders;
        },
        (searchResults) {
          filteredPurchaseOrders.value = searchResults;
        },
      );
    } catch (e) {
      error.value = 'Error en búsqueda: $e';
      filteredPurchaseOrders.value = purchaseOrders;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      final result = await getPurchaseOrderStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print('Error cargando estadísticas: ${failure.message}');
          // No bloquear la aplicación por errores de estadísticas
        },
        (purchaseOrderStats) {
          // Enriquecer las estadísticas con las órdenes actuales para cálculos dinámicos
          final enrichedStats = PurchaseOrderStats(
            totalPurchaseOrders: purchaseOrderStats.totalPurchaseOrders,
            pendingOrders: purchaseOrderStats.pendingOrders,
            approvedOrders: purchaseOrderStats.approvedOrders,
            sentOrders: purchaseOrderStats.sentOrders,
            partiallyReceivedOrders: purchaseOrderStats.partiallyReceivedOrders,
            receivedOrders: purchaseOrderStats.receivedOrders,
            cancelledOrders: purchaseOrderStats.cancelledOrders,
            overdueOrders: purchaseOrderStats.overdueOrders,
            totalValue: purchaseOrderStats.totalValue,
            cancellationRate: purchaseOrderStats.cancellationRate,
            averageOrderValue: purchaseOrderStats.averageOrderValue,
            totalPending: purchaseOrderStats.totalPending,
            totalReceived: purchaseOrderStats.totalReceived,
            ordersBySupplier: purchaseOrderStats.ordersBySupplier,
            valueBySupplier: purchaseOrderStats.valueBySupplier,
            ordersByMonth: purchaseOrderStats.ordersByMonth,
            topOrdersByValue: purchaseOrderStats.topOrdersByValue,
            recentActivity: purchaseOrderStats.recentActivity,
            orders: purchaseOrders, // Pasar las órdenes para cálculos dinámicos
          );
          stats.value = enrichedStats;
        },
      );
    } catch (e) {
      print('Error inesperado cargando estadísticas: $e');
      // No bloquear la aplicación por errores de estadísticas
    }
  }

  // ==================== PAGINATION ====================

  Future<void> loadNextPage() async {
    if (!isLoadingMore.value && hasNextPage.value) {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadPurchaseOrders(showLoading: false);
    }
  }

  Future<void> loadPreviousPage() async {
    if (!isLoadingMore.value && hasPrevPage.value) {
      isLoadingMore.value = true;
      currentPage.value--;
      await loadPurchaseOrders(showLoading: false);
    }
  }

  void goToFirstPage() {
    if (currentPage.value != 1) {
      currentPage.value = 1;
      purchaseOrders.clear();
      loadPurchaseOrders();
    }
  }

  void goToLastPage() {
    if (currentPage.value != totalPages.value) {
      currentPage.value = totalPages.value;
      purchaseOrders.clear();
      loadPurchaseOrders();
    }
  }

  // ==================== REFRESH & RELOAD ====================

  Future<void> refreshPurchaseOrders() async {
    try {
      print('🔄 PurchaseOrdersController: Starting refresh...');
      isRefreshing.value = true;
      currentPage.value = 1;

      // Clear all data first
      purchaseOrders.clear();
      filteredPurchaseOrders.clear();
      error.value = '';

      // Load fresh data — SIEMPRE forzar refresh (no usar cache)
      await loadPurchaseOrders(showLoading: false, forceRefresh: true);
      await loadStats();

      print('✅ PurchaseOrdersController: Refresh completed successfully');
    } catch (e) {
      print('❌ PurchaseOrdersController: Error during refresh: $e');
      error.value = 'Error al actualizar las órdenes de compra';
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Método especializado para actualizar después de crear/editar una orden
  Future<void> refreshAfterOrderChange(
    String? newOrderId, {
    bool isUpdate = false,
  }) async {
    try {
      print(
        '🎆 Actualizando lista después de ${isUpdate ? 'actualizar' : 'crear'} orden: $newOrderId',
      );

      invalidateCache();
      await refreshPurchaseOrders();

      // Si tenemos el ID de la nueva orden, intentar ponerla al inicio
      if (newOrderId != null && purchaseOrders.isNotEmpty) {
        _prioritizeNewOrder(newOrderId);
      }

      print(
        '✅ Lista actualizada exitosamente después de ${isUpdate ? 'actualización' : 'creación'}',
      );
    } catch (e) {
      print('❌ Error al actualizar lista después de cambios: $e');
    }
  }

  /// Intenta mover la nueva orden al inicio de la lista para mejor visibilidad
  void _prioritizeNewOrder(String orderId) {
    try {
      final orderIndex = purchaseOrders.indexWhere(
        (order) => order.id == orderId,
      );
      if (orderIndex > 0) {
        final newOrder = purchaseOrders.removeAt(orderIndex);
        purchaseOrders.insert(0, newOrder);

        // Actualizar la lista filtrada también
        applyFilters();

        print('🔝 Orden $orderId movida al inicio de la lista');
      } else if (orderIndex == 0) {
        print('🎆 Orden $orderId ya está al inicio de la lista');
      } else {
        print('⚠️ Orden $orderId no encontrada en la lista actual');
      }
    } catch (e) {
      print('❌ Error al priorizar nueva orden: $e');
    }
  }

  void reloadPurchaseOrders() {
    currentPage.value = 1;
    purchaseOrders.clear();
    loadPurchaseOrders(forceRefresh: true);
  }

  /// Actualizar una PO específica en la lista en memoria (sin re-cargar del servidor)
  void updateOrderInList(PurchaseOrder updatedOrder) {
    final index = purchaseOrders.indexWhere((o) => o.id == updatedOrder.id);
    if (index >= 0) {
      purchaseOrders[index] = updatedOrder;
    } else {
      // Orden nueva — agregar al inicio
      purchaseOrders.insert(0, updatedOrder);
    }
    // Actualizar lista filtrada
    filteredPurchaseOrders.value = List.from(purchaseOrders);
    print('✅ Orden ${updatedOrder.id.substring(0, 8)} actualizada en lista (total: ${updatedOrder.totalAmount})');
  }

  // ==================== FILTERING ====================

  void applyFilters() {
    currentPage.value = 1;
    purchaseOrders.clear();
    loadPurchaseOrders();
  }

  void clearFilters() {
    statusFilter.value = null;
    priorityFilter.value = null;
    supplierIdFilter.value = '';
    startDateFilter.value = null;
    endDateFilter.value = null;
    showOverdueOnly.value = false;
    showPendingApprovalOnly.value = false;
    searchController.clear();
    searchQuery.value = '';

    currentPage.value = 1;
    purchaseOrders.clear();
    loadPurchaseOrders();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // ==================== SORTING ====================

  void sortPurchaseOrders(String field) {
    if (sortBy.value == field) {
      // Cambiar orden si es el mismo campo
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      // Nuevo campo, empezar con descendente para fechas y montos
      sortBy.value = field;
      sortOrder.value =
          [
                'orderDate',
                'expectedDeliveryDate',
                'totalAmount',
                'createdAt',
              ].contains(field)
              ? 'desc'
              : 'asc';
    }

    invalidateCache(); // Cache tiene orden anterior
    currentPage.value = 1;
    purchaseOrders.clear();
    loadPurchaseOrders();
  }

  // ==================== PURCHASE ORDER ACTIONS ====================

  Future<void> deletePurchaseOrder(String id) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Está seguro de que desea eliminar esta orden de compra?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (result == true) {
        isLoading.value = true;

        final deleteResult = await deletePurchaseOrderUseCase(id);

        deleteResult.fold(
          (failure) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
          },
          (_) {
            Get.snackbar(
              'Éxito',
              'Orden de compra eliminada correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );

            invalidateCache();
            refreshPurchaseOrders();
          },
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approvePurchaseOrder(String id) async {
    try {
      isLoading.value = true;

      final params = ApprovePurchaseOrderParams(id: id);
      final result = await approvePurchaseOrderUseCase(params);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (approvedOrder) {
          Get.snackbar(
            'Éxito',
            'Orden de compra aprobada correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          // Actualizar orden en la lista
          final index = purchaseOrders.indexWhere((order) => order.id == id);
          if (index != -1) {
            purchaseOrders[index] = approvedOrder;
            filteredPurchaseOrders.refresh();
          }
          invalidateCache();
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== NAVIGATION ====================

  void goToPurchaseOrderDetail(String purchaseOrderId) {
    Get.toNamed('/purchase-orders/detail/$purchaseOrderId');
  }

  void goToPurchaseOrderEdit(String purchaseOrderId) async {
    print(
      '🔄 PurchaseOrdersController: Navigating to edit form: $purchaseOrderId',
    );
    final result = await Get.toNamed('/purchase-orders/edit/$purchaseOrderId');

    // Refresh data when returning from edit form
    print(
      '🔄 PurchaseOrdersController: Returned from edit form, refreshing data',
    );
    await refreshPurchaseOrders();

    if (result != null) {
      print('✅ PurchaseOrdersController: Edit form returned result: $result');
    }
  }

  void goToCreatePurchaseOrder() {
    print('🔄 PurchaseOrdersController: Navigating to create form');
    Get.toNamed('/purchase-orders/create');
    // No need to wait for result since form uses Get.offAllNamed
  }

  void goToCreateFromSupplier(String supplierId) {
    print(
      '🔄 PurchaseOrdersController: Navigating to create form with supplier: $supplierId',
    );
    Get.toNamed(
      '/purchase-orders/create',
      arguments: {'supplierId': supplierId},
    );
    // No need to wait for result since form uses Get.offAllNamed
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 1 && stats.value == null) {
      loadStats();
    }
  }

  String getStatusText(PurchaseOrderStatus status) {
    return status.displayStatus;
  }

  Color getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.pending:
        return Colors.orange;
      case PurchaseOrderStatus.approved:
        return Colors.blue;
      case PurchaseOrderStatus.rejected:
        return Colors.red;
      case PurchaseOrderStatus.sent:
        return Colors.purple;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.amber;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  String getPriorityText(PurchaseOrderPriority priority) {
    return priority.displayPriority;
  }

  Color getPriorityColor(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Colors.green;
      case PurchaseOrderPriority.medium:
        return Colors.orange;
      case PurchaseOrderPriority.high:
        return Colors.red;
      case PurchaseOrderPriority.urgent:
        return Colors.deepPurple;
    }
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatDateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  // ==================== COMPUTED PROPERTIES ====================

  List<PurchaseOrder> get displayedPurchaseOrders => filteredPurchaseOrders;

  bool get hasPurchaseOrders => purchaseOrders.isNotEmpty;

  bool get hasResults => filteredPurchaseOrders.isNotEmpty;

  String get resultsText {
    if (searchQuery.value.isNotEmpty) {
      return '${filteredPurchaseOrders.length} resultados para "${searchQuery.value}"';
    } else {
      return '${totalItems.value} órdenes de compra';
    }
  }

  bool get canLoadMore =>
      hasNextPage.value && !isLoadingMore.value && !isLoading.value;

  Map<String, dynamic> get activeFiltersCount {
    int count = 0;
    final List<String> activeFilters = [];

    if (statusFilter.value != null) {
      count++;
      activeFilters.add('Estado: ${getStatusText(statusFilter.value!)}');
    }
    if (priorityFilter.value != null) {
      count++;
      activeFilters.add('Prioridad: ${getPriorityText(priorityFilter.value!)}');
    }
    if (supplierIdFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Proveedor específico');
    }
    if (startDateFilter.value != null) {
      count++;
      activeFilters.add('Desde: ${formatDate(startDateFilter.value!)}');
    }
    if (endDateFilter.value != null) {
      count++;
      activeFilters.add('Hasta: ${formatDate(endDateFilter.value!)}');
    }
    if (showOverdueOnly.value) {
      count++;
      activeFilters.add('Solo vencidas');
    }
    if (showPendingApprovalOnly.value) {
      count++;
      activeFilters.add('Solo pendientes de aprobación');
    }

    return {'count': count, 'filters': activeFilters};
  }
}
