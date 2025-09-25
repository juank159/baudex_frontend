// lib/features/inventory/presentation/controllers/inventory_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/usecases/get_inventory_balances_usecase.dart';
import '../../domain/usecases/get_inventory_movements_usecase.dart';
import '../../domain/usecases/get_inventory_stats_usecase.dart';
import '../../domain/usecases/get_low_stock_products_usecase.dart';
import '../../domain/usecases/get_out_of_stock_products_usecase.dart';
import '../../domain/usecases/get_expired_products_usecase.dart';
import '../../domain/usecases/get_near_expiry_products_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_export_service.dart';
import 'inventory_transfers_controller.dart';

class InventoryController extends GetxController {
  final GetInventoryBalancesUseCase getInventoryBalancesUseCase;
  final GetInventoryMovementsUseCase getInventoryMovementsUseCase;
  final GetInventoryStatsUseCase getInventoryStatsUseCase;
  final GetLowStockProductsUseCase getLowStockProductsUseCase;
  final GetOutOfStockProductsUseCase getOutOfStockProductsUseCase;
  final GetExpiredProductsUseCase getExpiredProductsUseCase;
  final GetNearExpiryProductsUseCase getNearExpiryProductsUseCase;

  InventoryController({
    required this.getInventoryBalancesUseCase,
    required this.getInventoryMovementsUseCase,
    required this.getInventoryStatsUseCase,
    required this.getLowStockProductsUseCase,
    required this.getOutOfStockProductsUseCase,
    required this.getExpiredProductsUseCase,
    required this.getNearExpiryProductsUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  // Balances
  final RxList<InventoryBalance> balances = <InventoryBalance>[].obs;
  final RxList<InventoryBalance> filteredBalances = <InventoryBalance>[].obs;
  
  // Movements
  final RxList<InventoryMovement> movements = <InventoryMovement>[].obs;
  final RxList<InventoryMovement> filteredMovements = <InventoryMovement>[].obs;
  
  // Stats
  final Rx<InventoryStats?> stats = Rx<InventoryStats?>(null);
  final Rx<InventoryStats?> inventoryStats = Rx<InventoryStats?>(null);
  
  // Recent activity
  final RxList<InventoryMovement> recentMovements = <InventoryMovement>[].obs;
  
  // Weekly stats count (para resumen semanal)
  final RxInt weeklyTransfersCount = 0.obs;
  final RxInt weeklyAdjustmentsCount = 0.obs;
  final RxInt weeklyNewProductsCount = 0.obs;
  
  // Alert products
  final RxList<InventoryBalance> lowStockProducts = <InventoryBalance>[].obs;
  final RxList<InventoryBalance> outOfStockProducts = <InventoryBalance>[].obs;
  final RxList<InventoryBalance> expiredProducts = <InventoryBalance>[].obs;
  final RxList<InventoryBalance> nearExpiryProducts = <InventoryBalance>[].obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // Filters
  final RxString categoryIdFilter = ''.obs;
  final RxString warehouseIdFilter = ''.obs;
  final RxBool showLowStockOnly = false.obs;
  final RxBool showOutOfStockOnly = false.obs;
  final RxBool showNearExpiryOnly = false.obs;
  final RxBool showExpiredOnly = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPrevPage = false.obs;
  static const int pageSize = 20;

  // Sorting
  final RxString sortBy = 'productName'.obs;
  final RxString sortOrder = 'asc'.obs;

  // UI State
  final RxBool isRefreshing = false.obs;
  final RxBool showFilters = false.obs;
  final RxInt selectedTab = 0.obs; // 0: Balances, 1: Movements, 2: Stats

  // Controllers
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    loadBalances();
    loadStats();
    loadRecentMovements();
    loadAlertProducts();
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
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery.value.isNotEmpty) {
        _filterBalances();
      } else {
        filteredBalances.value = balances;
      }
    });
  }

  Timer? _searchTimer;

  // ==================== DATA LOADING ====================

  Future<void> loadBalances({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      error.value = '';

      final params = InventoryBalanceQueryParams(
        page: currentPage.value,
        limit: pageSize,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        categoryId: categoryIdFilter.value.isNotEmpty ? categoryIdFilter.value : null,
        warehouseId: warehouseIdFilter.value.isNotEmpty ? warehouseIdFilter.value : null,
        lowStock: showLowStockOnly.value ? true : null,
        outOfStock: showOutOfStockOnly.value ? true : null,
        nearExpiry: showNearExpiryOnly.value ? true : null,
        expired: showExpiredOnly.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getInventoryBalancesUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          if (currentPage.value == 1) {
            balances.value = paginatedResult.data;
          } else {
            balances.addAll(paginatedResult.data);
          }

          // Update pagination metadata
          if (paginatedResult.meta != null) {
            totalPages.value = paginatedResult.meta!.totalPages;
            totalItems.value = paginatedResult.meta!.total;
            hasNextPage.value = paginatedResult.meta!.hasNext;
            hasPrevPage.value = paginatedResult.meta!.hasPrev;
          }

          if (searchQuery.value.isEmpty) {
            filteredBalances.value = balances;
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMovements({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      error.value = '';

      final params = InventoryMovementQueryParams(
        page: currentPage.value,
        limit: pageSize,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        warehouseId: warehouseIdFilter.value.isNotEmpty ? warehouseIdFilter.value : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getInventoryMovementsUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          if (currentPage.value == 1) {
            movements.value = paginatedResult.data;
          } else {
            movements.addAll(paginatedResult.data);
          }

          // Update pagination metadata
          if (paginatedResult.meta != null) {
            totalPages.value = paginatedResult.meta!.totalPages;
            totalItems.value = paginatedResult.meta!.total;
            hasNextPage.value = paginatedResult.meta!.hasNext;
            hasPrevPage.value = paginatedResult.meta!.hasPrev;
          }

          if (searchQuery.value.isEmpty) {
            filteredMovements.value = movements;
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      print('🔍 DEBUG: loadStats() called');
      final params = InventoryStatsParams(
        warehouseId: warehouseIdFilter.value.isNotEmpty ? warehouseIdFilter.value : null,
        categoryId: categoryIdFilter.value.isNotEmpty ? categoryIdFilter.value : null,
      );
      print('🔍 DEBUG: params created: warehouseId=${params.warehouseId}, categoryId=${params.categoryId}');

      print('🔍 DEBUG: Calling getInventoryStatsUseCase...');
      final result = await getInventoryStatsUseCase(params);
      print('🔍 DEBUG: getInventoryStatsUseCase completed');

      result.fold(
        (failure) {
          print('❌ DEBUG: failure received: ${failure.runtimeType}');
          print('❌ DEBUG: failure message: ${failure.message}');
          print('Error cargando estadísticas: ${failure.message}');
        },
        (inventoryStats) {
          print('✅ DEBUG: success received: $inventoryStats');
          stats.value = inventoryStats;
          this.inventoryStats.value = inventoryStats;
        },
      );
    } catch (e) {
      print('❌ DEBUG: Exception caught: ${e.runtimeType}');
      print('❌ DEBUG: Exception details: $e');
      print('Error inesperado cargando estadísticas: $e');
    }
  }

  // ==================== FILTERING & SEARCH ====================

  void _filterBalances() {
    List<InventoryBalance> filtered = List.from(balances);

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((balance) =>
          balance.productName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          balance.productSku.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
    }

    filteredBalances.value = filtered;
  }

  void applyFilters() {
    currentPage.value = 1;
    balances.clear();
    if (selectedTab.value == 0) {
      loadBalances();
    } else if (selectedTab.value == 1) {
      loadMovements();
    }
  }

  void clearFilters() {
    categoryIdFilter.value = '';
    warehouseIdFilter.value = '';
    showLowStockOnly.value = false;
    showOutOfStockOnly.value = false;
    showNearExpiryOnly.value = false;
    showExpiredOnly.value = false;
    searchController.clear();
    searchQuery.value = '';
    
    currentPage.value = 1;
    balances.clear();
    movements.clear();
    
    if (selectedTab.value == 0) {
      loadBalances();
    } else if (selectedTab.value == 1) {
      loadMovements();
    }
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // ==================== PAGINATION ====================

  Future<void> loadNextPage() async {
    if (!isLoadingMore.value && hasNextPage.value) {
      isLoadingMore.value = true;
      currentPage.value++;
      if (selectedTab.value == 0) {
        await loadBalances(showLoading: false);
      } else if (selectedTab.value == 1) {
        await loadMovements(showLoading: false);
      }
    }
  }

  // ==================== REFRESH & RELOAD ====================

  Future<void> refreshData() async {
    isRefreshing.value = true;
    currentPage.value = 1;
    balances.clear();
    movements.clear();
    
    // Load main data
    if (selectedTab.value == 0) {
      await loadBalances(showLoading: false);
    } else if (selectedTab.value == 1) {
      await loadMovements(showLoading: false);
    }
    
    // Load supporting data for dashboard
    await Future.wait([
      loadStats(),
      loadRecentMovements(),
      loadAlertProducts(),
      _loadWeeklyStats(), // Cargar todas las estadísticas semanales
    ]);
  }

  Future<void> loadRecentMovements() async {
    try {
      final params = InventoryMovementQueryParams(
        limit: 20, // Incrementado para obtener más datos
        sortBy: 'movementDate',
        sortOrder: 'desc',
      );

      final result = await getInventoryMovementsUseCase(params);
      result.fold(
        (failure) => print('❌ Error loading recent movements: ${failure.message}'),
        (paginatedResult) => recentMovements.value = paginatedResult.data,
      );
    } catch (e) {
      print('❌ Exception loading recent movements: $e');
    }
  }

  // Método específico para obtener transferencias de la semana
  Future<int> getWeeklyTransfersCount() async {
    try {
      final now = DateTime.now();
      // USAR LA MISMA LÓGICA QUE EN TRANSFERENCIAS: desde lunes de esta semana
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      // Obtener transferencias transferOut de esta semana (desde lunes)
      final params = InventoryMovementQueryParams(
        limit: 100, // Más límite para obtener transferencias de la semana
        type: InventoryMovementType.transferOut,
        startDate: startOfWeekDay, // Desde lunes 00:00:00
        endDate: now,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final result = await getInventoryMovementsUseCase(params);
      
      return result.fold(
        (failure) {
          print('❌ Error loading weekly transfers: ${failure.message}');
          return 0;
        },
        (paginatedResult) {
          final transferOutMovements = paginatedResult.data;
          
          // Agrupar transferencias usando la misma lógica que en dashboard
          final groupedTransfers = <String, List<InventoryMovement>>{};
          
          for (final transfer in transferOutMovements) {
            final groupKey = _generateTransferGroupKey(transfer);
            if (!groupedTransfers.containsKey(groupKey)) {
              groupedTransfers[groupKey] = [];
            }
            groupedTransfers[groupKey]!.add(transfer);
          }
          
          final weeklyTransfersCount = groupedTransfers.length;
          print('🏠 DASHBOARD - Transferencias de la semana:');
          print('   • Desde: ${startOfWeekDay.toIso8601String()}');
          print('   • Hasta: ${now.toIso8601String()}');
          print('   • Movimientos transferOut: ${transferOutMovements.length}');
          print('   • Grupos únicos: $weeklyTransfersCount');
          
          return weeklyTransfersCount;
        },
      );
    } catch (e) {
      print('❌ Exception loading weekly transfers: $e');
      return 0;
    }
  }

  // Método auxiliar para generar clave de agrupamiento (igual que en dashboard)
  String _generateTransferGroupKey(InventoryMovement transfer) {
    // Usar lógica simplificada sin dependencia de warehouses
    final timeWindow = transfer.createdAt.millisecondsSinceEpoch ~/ 60000; // Ventana de 1 minuto
    final notesKey = transfer.notes?.contains('Transfer between warehouses') == true
        ? 'batch_transfer' // Agrupar transferencias automáticas
        : transfer.notes ?? 'no_notes';
    
    // Usar metadata para obtener almacenes
    String fromWarehouse = 'unknown';
    String toWarehouse = 'unknown';
    
    try {
      if (transfer.metadata != null) {
        fromWarehouse = transfer.metadata!['originWarehouse'] as String? ?? transfer.warehouseId ?? 'unknown';
        toWarehouse = transfer.metadata!['destinationWarehouse'] as String? ?? 'unknown';
      } else {
        fromWarehouse = transfer.warehouseId ?? 'unknown';
      }
    } catch (e) {
      // Usar fallback si hay error
    }
    
    return '${fromWarehouse}_${toWarehouse}_${timeWindow}_${notesKey}';
  }

  // Cargar TODAS las estadísticas semanales
  Future<void> _loadWeeklyStats() async {
    try {
      // REPLICAR EXACTAMENTE la lógica del controlador de transferencias
      
      // 1. Cargar TODOS los datos como lo hace el controlador de transferencias
      final transferInParams = InventoryMovementQueryParams(
        page: 1,
        limit: 50, // Mismo límite que transferencias
        type: InventoryMovementType.transferIn,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final transferOutParams = InventoryMovementQueryParams(
        page: 1,
        limit: 50, // Mismo límite que transferencias
        type: InventoryMovementType.transferOut,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final transferInResult = await getInventoryMovementsUseCase(transferInParams);
      final transferOutResult = await getInventoryMovementsUseCase(transferOutParams);

      List<InventoryMovement> allTransfers = [];

      transferInResult.fold(
        (failure) => print('Transfer_in query failed: ${failure.message}'),
        (paginatedResult) => allTransfers.addAll(paginatedResult.data),
      );

      transferOutResult.fold(
        (failure) => print('Transfer_out query failed: ${failure.message}'),
        (paginatedResult) => allTransfers.addAll(paginatedResult.data),
      );

      // 2. Filtrar por semana usando EXACTAMENTE la misma lógica
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final weekTransfersList = allTransfers.where((t) => t.createdAt.isAfter(startOfWeekDay)).toList();
      
      // 3. Agrupar usando EXACTAMENTE la misma lógica
      final transfersCount = _groupTransfersLikeTransfersController(weekTransfersList);
      weeklyTransfersCount.value = transfersCount;
      
      // 4. Cargar AJUSTES de la semana
      await _loadWeeklyAdjustments(startOfWeekDay, now);
      
      // 5. Cargar PRODUCTOS NUEVOS de la semana
      await _loadWeeklyNewProducts(startOfWeekDay, now);
      
      print('🏠 DASHBOARD - Estadísticas semana (${startOfWeekDay.day}/${startOfWeekDay.month} - ${now.day}/${now.month}):');
      print('   • Transferencias: $transfersCount');
      print('   • Ajustes: ${weeklyAdjustmentsCount.value}');
      print('   • Productos nuevos: ${weeklyNewProductsCount.value}');
      
    } catch (e) {
      print('❌ Error cargando estadísticas semanales: $e');
      weeklyTransfersCount.value = 0;
      weeklyAdjustmentsCount.value = 0;
      weeklyNewProductsCount.value = 0;
    }
  }

  // Replicar EXACTAMENTE la lógica de agrupamiento del controlador de transferencias
  int _groupTransfersLikeTransfersController(List<InventoryMovement> transfers) {
    // FILTRAR SOLO TRANSFER_OUT para evitar duplicar cantidades
    final outTransfers = transfers.where((t) => 
      t.type == InventoryMovementType.transferOut
    ).toList();
    
    final Map<String, List<InventoryMovement>> groupedTransfers = {};
    
    for (final transfer in outTransfers) {
      final groupKey = _generateTransferGroupKey(transfer);
      
      if (!groupedTransfers.containsKey(groupKey)) {
        groupedTransfers[groupKey] = [];
      }
      groupedTransfers[groupKey]!.add(transfer);
    }
    
    print('🏠 DASHBOARD DEBUG:');
    print('   • Total transfers: ${transfers.length}');
    print('   • TransferOut: ${outTransfers.length}');
    print('   • Grupos únicos: ${groupedTransfers.length}');
    
    return groupedTransfers.length;
  }

  // Cargar ajustes realizados en la semana
  Future<void> _loadWeeklyAdjustments(DateTime startOfWeek, DateTime endOfWeek) async {
    try {
      final params = InventoryMovementQueryParams(
        limit: 100,
        type: InventoryMovementType.adjustment,
        startDate: startOfWeek,
        endDate: endOfWeek,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final result = await getInventoryMovementsUseCase(params);
      
      result.fold(
        (failure) {
          print('❌ Error loading weekly adjustments: ${failure.message}');
          weeklyAdjustmentsCount.value = 0;
        },
        (paginatedResult) {
          weeklyAdjustmentsCount.value = paginatedResult.data.length;
          print('📊 AJUSTES - Encontrados ${paginatedResult.data.length} ajustes esta semana');
        },
      );
    } catch (e) {
      print('❌ Exception loading weekly adjustments: $e');
      weeklyAdjustmentsCount.value = 0;
    }
  }

  // Cargar productos nuevos agregados en la semana (entradas/inbound)
  Future<void> _loadWeeklyNewProducts(DateTime startOfWeek, DateTime endOfWeek) async {
    try {
      final params = InventoryMovementQueryParams(
        limit: 100,
        type: InventoryMovementType.inbound,
        startDate: startOfWeek,
        endDate: endOfWeek,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final result = await getInventoryMovementsUseCase(params);
      
      result.fold(
        (failure) {
          print('❌ Error loading weekly new products: ${failure.message}');
          weeklyNewProductsCount.value = 0;
        },
        (paginatedResult) {
          // Contar productos únicos (evitar duplicados)
          final uniqueProducts = paginatedResult.data
              .map((movement) => movement.productId)
              .toSet()
              .length;
          
          weeklyNewProductsCount.value = uniqueProducts;
          print('📦 PRODUCTOS NUEVOS - ${paginatedResult.data.length} entradas, $uniqueProducts productos únicos esta semana');
        },
      );
    } catch (e) {
      print('❌ Exception loading weekly new products: $e');
      weeklyNewProductsCount.value = 0;
    }
  }

  Future<void> loadAlertProducts() async {
    try {
      // Load different types of alert products
      await Future.wait([
        _loadLowStockProducts(),
        _loadOutOfStockProducts(),
        _loadExpiredProducts(),
        _loadNearExpiryProducts(),
      ]);
    } catch (e) {
      print('❌ Exception loading alert products: $e');
    }
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final result = await getLowStockProductsUseCase(const GetLowStockProductsParams());
      result.fold(
        (failure) => print('❌ Error loading low stock products: ${failure.message}'),
        (products) => lowStockProducts.value = products,
      );
    } catch (e) {
      print('❌ Exception loading low stock products: $e');
    }
  }

  Future<void> _loadOutOfStockProducts() async {
    try {
      final result = await getOutOfStockProductsUseCase();
      result.fold(
        (failure) => print('❌ Error loading out of stock products: ${failure.message}'),
        (products) => outOfStockProducts.value = products,
      );
    } catch (e) {
      print('❌ Exception loading out of stock products: $e');
    }
  }

  Future<void> _loadExpiredProducts() async {
    try {
      final result = await getExpiredProductsUseCase();
      result.fold(
        (failure) => print('❌ Error loading expired products: ${failure.message}'),
        (products) => expiredProducts.value = products,
      );
    } catch (e) {
      print('❌ Exception loading expired products: $e');
    }
  }

  Future<void> _loadNearExpiryProducts() async {
    try {
      final result = await getNearExpiryProductsUseCase();
      result.fold(
        (failure) => print('❌ Error loading near expiry products: ${failure.message}'),
        (products) => nearExpiryProducts.value = products,
      );
    } catch (e) {
      print('❌ Exception loading near expiry products: $e');
    }
  }

  // ==================== SORTING ====================

  void sortData(String field) {
    if (sortBy.value == field) {
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      sortBy.value = field;
      sortOrder.value = ['totalValue', 'totalQuantity', 'averageCost'].contains(field) ? 'desc' : 'asc';
    }

    currentPage.value = 1;
    balances.clear();
    movements.clear();
    
    if (selectedTab.value == 0) {
      loadBalances();
    } else if (selectedTab.value == 1) {
      loadMovements();
    }
  }

  // ==================== NAVIGATION ====================

  void goToProductDetail(String productId) {
    Get.toNamed(AppRoutes.inventoryProductDetail(productId));
  }

  void goToMovementDetail(String movementId) {
    Get.toNamed(AppRoutes.inventoryMovementDetail(movementId));
  }

  void goToCreateMovement() {
    Get.toNamed(AppRoutes.inventoryMovementsCreate);
  }

  void goToCreateAdjustment() {
    Get.toNamed(AppRoutes.inventoryAdjustmentsCreate);
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
    currentPage.value = 1;
    
    if (index == 0) {
      // Balances tab
      if (balances.isEmpty) {
        loadBalances();
      }
    } else if (index == 1) {
      // Movements tab
      if (movements.isEmpty) {
        loadMovements();
      }
    } else if (index == 2) {
      // Stats tab
      if (stats.value == null) {
        loadStats();
      }
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

  // ==================== EXPORT METHODS ====================

  Future<void> exportBalancesToExcel() async {
    try {
      if (filteredBalances.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para exportar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportBalancesToExcel(filteredBalances);
      
      Get.snackbar(
        'Éxito',
        'Balances exportados a Excel correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando balances a Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportMovementsToExcel() async {
    try {
      if (filteredMovements.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay movimientos para exportar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportMovementsToExcel(filteredMovements);
      
      Get.snackbar(
        'Éxito',
        'Movimientos exportados a Excel correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando movimientos a Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportFullReportToPdf() async {
    try {
      if (selectedTab.value == 0 && filteredBalances.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para exportar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      if (selectedTab.value == 1 && filteredMovements.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay movimientos para exportar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      
      if (selectedTab.value == 0) {
        // Export balances to PDF
        await InventoryExportService.exportBalancesToPDF(filteredBalances);
      } else {
        // Export movements to PDF
        await InventoryExportService.exportMovementsToPDF(filteredMovements);
      }
      
      Get.snackbar(
        'Éxito',
        'Reporte exportado a PDF correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando reporte a PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  List<InventoryBalance> get displayedBalances => filteredBalances;
  List<InventoryMovement> get displayedMovements => filteredMovements;

  bool get hasBalances => balances.isNotEmpty;
  bool get hasMovements => movements.isNotEmpty;
  bool get hasResults => selectedTab.value == 0 ? filteredBalances.isNotEmpty : filteredMovements.isNotEmpty;

  String get resultsText {
    if (selectedTab.value == 0) {
      if (searchQuery.value.isNotEmpty) {
        return '${filteredBalances.length} productos encontrados';
      } else {
        return '${totalItems.value} productos en inventario';
      }
    } else {
      if (searchQuery.value.isNotEmpty) {
        return '${filteredMovements.length} movimientos encontrados';
      } else {
        return '${totalItems.value} movimientos de inventario';
      }
    }
  }

  bool get canLoadMore => hasNextPage.value && !isLoadingMore.value && !isLoading.value;

  Map<String, dynamic> get activeFiltersCount {
    int count = 0;
    final List<String> activeFilters = [];

    if (categoryIdFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Categoría específica');
    }
    if (warehouseIdFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Almacén específico');
    }
    if (showLowStockOnly.value) {
      count++;
      activeFilters.add('Solo stock bajo');
    }
    if (showOutOfStockOnly.value) {
      count++;
      activeFilters.add('Solo sin stock');
    }
    if (showNearExpiryOnly.value) {
      count++;
      activeFilters.add('Solo próximos a vencer');
    }
    if (showExpiredOnly.value) {
      count++;
      activeFilters.add('Solo vencidos');
    }

    return {
      'count': count,
      'filters': activeFilters,
    };
  }
}