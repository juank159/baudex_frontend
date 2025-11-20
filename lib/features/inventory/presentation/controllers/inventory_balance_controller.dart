// lib/features/inventory/presentation/controllers/inventory_balance_controller.dart
import 'dart:async';
import 'package:baudex_desktop/app/config/themes/app_colors.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/usecases/get_inventory_balances_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_export_service.dart';

class InventoryBalanceController extends GetxController {
  final GetInventoryBalancesUseCase getInventoryBalancesUseCase;
  final GetInventoryValuationUseCase getInventoryValuationUseCase;

  InventoryBalanceController({
    required this.getInventoryBalancesUseCase,
    required this.getInventoryValuationUseCase,
  });

  // ==================== CONTROLLERS ====================

  final TextEditingController searchTextController = TextEditingController();

  // ==================== REACTIVE VARIABLES ====================

  final RxList<InventoryBalance> inventoryBalances = <InventoryBalance>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMore = false.obs;

  // Filters
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedWarehouse = ''.obs;
  final RxBool showLowStock = false.obs;
  final RxBool showOutOfStock = false.obs;
  final RxBool showWithStock = false.obs;
  final RxBool showExpired = false.obs;
  final RxString sortBy = 'productName'.obs;
  final RxString sortOrder = 'asc'.obs;

  // UI State
  final RxBool showFilters = false.obs;
  final RxInt selectedAlertCard = 0.obs; // 0 = "Todos" seleccionado por defecto

  // Valuation
  final Rx<Map<String, double>?> inventoryValuation = Rx<Map<String, double>?>(
    null,
  );
  final RxMap<String, double> valuationData = <String, double>{}.obs;
  final RxString selectedValuationMethod = 'fifo'.obs;
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);

  // Variable para saber si estamos en modo general o almacén específico
  final RxBool isGeneralMode = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Capturar argumentos de la navegación
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('warehouseId')) {
      // Modo almacén específico
      selectedWarehouse.value = args['warehouseId'] as String;
      isGeneralMode.value = false;
      print(
        '🔍 InventoryBalanceController: Filtro por almacén: ${selectedWarehouse.value}',
      );
      print(
        '🏢 InventoryBalanceController: Nombre del almacén: ${args['warehouseName']}',
      );
    } else {
      // Modo general (desde centro de inventario)
      selectedWarehouse.value = '';
      isGeneralMode.value = true;
      print(
        '🌍 InventoryBalanceController: Modo general - suma de todos los almacenes',
      );
    }

    loadInventoryBalances();
    loadFixedCounters();
    // Comentado temporalmente hasta implementar endpoint correcto
    // loadInventoryValuation();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  // ==================== DATA LOADING ====================

  Future<void> loadFixedCounters() async {
    try {
      print('🔍 InventoryBalanceController: Cargando contadores fijos');

      // Aplicar filtro de almacén solo si NO estamos en modo general
      final warehouseFilter =
          isGeneralMode.value
              ? null
              : (selectedWarehouse.value.isNotEmpty
                  ? selectedWarehouse.value
                  : null);
      if (warehouseFilter != null) {
        print(
          '🏢 InventoryBalanceController: Aplicando filtro por almacén: $warehouseFilter',
        );
      } else if (isGeneralMode.value) {
        print(
          '🌍 InventoryBalanceController: Cargando contadores GENERALES (todos los almacenes)',
        );
      }

      // Cargar contadores en paralelo
      final results = await Future.wait([
        // Todos los productos (con filtro de almacén si aplica)
        getInventoryBalancesUseCase(
          InventoryBalanceQueryParams(
            page: 1,
            limit: 1,
            warehouseId: warehouseFilter,
            sortBy: 'productName',
            sortOrder: 'asc',
          ),
        ),
        // Stock bajo
        getInventoryBalancesUseCase(
          InventoryBalanceQueryParams(
            page: 1,
            limit: 1,
            warehouseId: warehouseFilter,
            lowStock: true,
            sortBy: 'productName',
            sortOrder: 'asc',
          ),
        ),
        // Sin stock
        getInventoryBalancesUseCase(
          InventoryBalanceQueryParams(
            page: 1,
            limit: 1,
            warehouseId: warehouseFilter,
            outOfStock: true,
            sortBy: 'productName',
            sortOrder: 'asc',
          ),
        ),
        // Con stock (productos que tienen cantidad > 0)
        getInventoryBalancesUseCase(
          InventoryBalanceQueryParams(
            page: 1,
            limit: 1,
            warehouseId: warehouseFilter,
            sortBy: 'productName',
            sortOrder: 'asc',
          ),
        ),
        // Vencidos
        getInventoryBalancesUseCase(
          InventoryBalanceQueryParams(
            page: 1,
            limit: 1,
            warehouseId: warehouseFilter,
            expired: true,
            sortBy: 'productName',
            sortOrder: 'asc',
          ),
        ),
      ]);

      // Asignar contadores desde los totales de cada consulta - CONTEXTUALES al filtro aplicado
      int totalProducts = 0;
      int outOfStockProducts = 0;

      results[0].fold((failure) => null, (result) {
        totalProducts = result.totalItems;
        fixedTotalItemsCount.value = result.totalItems;
      });
      results[1].fold(
        (failure) => null,
        (result) => fixedLowStockCount.value = result.totalItems,
      );
      results[2].fold((failure) => null, (result) {
        outOfStockProducts = result.totalItems;
        fixedOutOfStockCount.value = result.totalItems;
      });

      // Para "Con Stock" calculamos productos totales menos sin stock
      fixedWithStockCount.value = totalProducts - outOfStockProducts;

      // El resultado[3] ahora es solo para calcular "Con Stock", no lo necesitamos guardar
      results[4].fold(
        (failure) => null,
        (result) => fixedExpiredCount.value = result.totalItems,
      );

      if (isGeneralMode.value) {
        print('📊 CONTADORES GENERALES CARGADOS (todos los almacenes):');
      } else {
        print(
          '📊 CONTADORES ESPECÍFICOS CARGADOS (almacén: $warehouseFilter):',
        );
      }
      print('   • Total: ${fixedTotalItemsCount.value}');
      print('   • Stock Bajo: ${fixedLowStockCount.value}');
      print('   • Sin Stock: ${fixedOutOfStockCount.value}');
      print('   • Con Stock: ${fixedWithStockCount.value}');
      print('   • Vencidos: ${fixedExpiredCount.value}');
    } catch (e) {
      print('❌ InventoryBalanceController: Error cargando contadores - $e');
    }
  }

  Future<void> loadInventoryBalances({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        inventoryBalances.clear();
      }

      isLoading.value = refresh || inventoryBalances.isEmpty;
      isLoadingMore.value = !refresh && inventoryBalances.isNotEmpty;
      error.value = '';

      print(
        '🔍 InventoryBalanceController: Cargando balances página ${currentPage.value}',
      );

      final params = InventoryBalanceQueryParams(
        page: currentPage.value,
        limit: 20,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        categoryId:
            selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
        warehouseId:
            isGeneralMode.value
                ? null // En modo general no filtrar por almacén
                : (selectedWarehouse.value.isNotEmpty
                    ? selectedWarehouse.value
                    : null),
        lowStock: showLowStock.value ? true : null,
        outOfStock: showOutOfStock.value ? true : null,
        // Para filtro "Con Stock" no enviamos parámetro especial, se filtran en cliente
        expired: showExpired.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getInventoryBalancesUseCase(params);

      result.fold(
        (failure) {
          print('❌ InventoryBalanceController: Error - ${failure.message}');
          error.value = failure.message;
          Get.snackbar(
            'Error al cargar inventario',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          print(
            '✅ InventoryBalanceController: Balances cargados - ${paginatedResult.data.length} items',
          );

          // Aplicar filtro de "Con Stock" en el cliente si está activo
          List<InventoryBalance> filteredData = paginatedResult.data;
          if (showWithStock.value) {
            filteredData =
                paginatedResult.data
                    .where((balance) => balance.totalQuantity > 0)
                    .toList();
            print(
              '🔍 Filtro "Con Stock" aplicado: ${filteredData.length} productos con stock',
            );
          }

          if (refresh) {
            inventoryBalances.value = filteredData;
          } else {
            inventoryBalances.addAll(filteredData);
          }

          currentPage.value = paginatedResult.meta?.currentPage ?? 1;
          totalPages.value = paginatedResult.meta?.totalPages ?? 1;
          // Si aplicamos filtro local, usamos el tamaño filtrado, sino el total del servidor
          totalItems.value =
              showWithStock.value
                  ? filteredData.length
                  : (paginatedResult.meta?.totalItems ??
                      paginatedResult.data.length);
          hasMore.value = paginatedResult.meta?.hasNext ?? false;

          print(
            '📊 Pagination: ${currentPage.value}/${totalPages.value} - ${totalItems.value} total',
          );
        },
      );
    } catch (e) {
      print('❌ InventoryBalanceController: Exception - $e');
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error al cargar inventario',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadInventoryValuation() async {
    try {
      print('🔍 InventoryBalanceController: Cargando valoración de inventario');

      final result = await getInventoryValuationUseCase(
        warehouseId:
            selectedWarehouse.value.isNotEmpty ? selectedWarehouse.value : null,
        asOfDate: DateTime.now(),
      );

      result.fold(
        (failure) {
          print(
            '❌ InventoryBalanceController: Error en valoración - ${failure.message}',
          );
        },
        (valuation) {
          print(
            '✅ InventoryBalanceController: Valoración cargada - ${valuation.keys.length} categorías',
          );
          inventoryValuation.value = valuation;
        },
      );
    } catch (e) {
      print('❌ InventoryBalanceController: Exception en valoración - $e');
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;

    currentPage.value++;
    await loadInventoryBalances();
  }

  Future<void> refreshBalances() async {
    await Future.wait([
      loadInventoryBalances(refresh: true),
      loadFixedCounters(),
    ]);
    // Comentado temporalmente hasta implementar endpoint correcto
    // await loadInventoryValuation();
  }

  // ==================== SEARCH & FILTERS ====================

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    // NO actualizar searchTextController.text aquí para evitar loop
    _debounceSearch();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchTextController.clear();
    loadInventoryBalances(refresh: true);
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      loadInventoryBalances(refresh: true);
    });
  }

  void updateCategory(String? category) {
    selectedCategory.value = category ?? '';
    loadInventoryBalances(refresh: true);
  }

  void updateWarehouse(String? warehouse) {
    selectedWarehouse.value = warehouse ?? '';
    loadInventoryBalances(refresh: true);
    loadFixedCounters(); // ✅ Recargar contadores con filtro de almacén
    // Comentado temporalmente hasta implementar endpoint correcto
    // loadInventoryValuation();
  }

  void toggleLowStock() {
    showLowStock.value = !showLowStock.value;
    loadInventoryBalances(refresh: true);
  }

  void toggleOutOfStock() {
    showOutOfStock.value = !showOutOfStock.value;
    loadInventoryBalances(refresh: true);
  }

  void toggleWithStock() {
    showWithStock.value = !showWithStock.value;
    loadInventoryBalances(refresh: true);
  }

  void toggleExpired() {
    showExpired.value = !showExpired.value;
    loadInventoryBalances(refresh: true);
  }

  void updateSort(String field, String order) {
    sortBy.value = field;
    sortOrder.value = order;
    loadInventoryBalances(refresh: true);
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategory.value = '';
    selectedWarehouse.value = '';
    showLowStock.value = false;
    showOutOfStock.value = false;
    showWithStock.value = false;
    showExpired.value = false;
    sortBy.value = 'productName';
    sortOrder.value = 'asc';
    loadInventoryBalances(refresh: true);
    loadFixedCounters(); // ✅ Recargar contadores cuando se limpian filtros
  }

  // ==================== UI HELPERS ====================

  bool get hasCustomSort =>
      !(sortBy.value == 'productName' && sortOrder.value == 'asc');

  String getCurrentSortLabel() {
    switch ('${sortBy.value}_${sortOrder.value}') {
      case 'productName_asc':
        return hasCustomSort ? 'Nombre A-Z' : 'Ordenar';
      case 'productName_desc':
        return 'Nombre Z-A';
      case 'totalQuantity_desc':
        return 'Stock: Mayor a Menor';
      case 'totalQuantity_asc':
        return 'Stock: Menor a Mayor';
      case 'totalValue_desc':
        return 'Valor: Mayor a Menor';
      case 'totalValue_asc':
        return 'Valor: Menor a Mayor';
      default:
        return 'Ordenar';
    }
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  Color getStockLevelColor(InventoryBalance balance) {
    if (balance.isOutOfStock) return Colors.red;
    if (balance.isLowStock) return Colors.orange;
    if (balance.isOverStock) return Colors.blue;
    return Colors.green;
  }

  IconData getStockLevelIcon(InventoryBalance balance) {
    if (balance.isOutOfStock) return Icons.error;
    if (balance.isLowStock) return Icons.warning;
    if (balance.isOverStock) return Icons.trending_up;
    return Icons.check_circle;
  }

  double getStockLevelProgress(InventoryBalance balance) {
    return balance.stockLevel.clamp(0.0, 1.0);
  }

  // ==================== NAVIGATION ====================

  void goToProductDetail(String productId) {
    Get.toNamed(
      '/products/detail/$productId',
      arguments: {'productId': productId},
    );
  }

  void goToProductKardex(String productId) {
    Get.toNamed(
      '/inventory/product/$productId/kardex',
      arguments: {'productId': productId},
    );
  }

  void goToProductBatches(String productId) {
    Get.toNamed(
      '/inventory/product/$productId/batches',
      arguments: {'productId': productId},
    );
  }

  void goToInventoryMovements({String? productId}) {
    Get.toNamed(
      '/inventory/movements',
      arguments: productId != null ? {'productId': productId} : null,
    );
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasBalances => inventoryBalances.isNotEmpty;
  bool get hasError => error.value.isNotEmpty;
  bool get hasFiltersApplied =>
      searchQuery.value.isNotEmpty ||
      selectedCategory.value.isNotEmpty ||
      selectedWarehouse.value.isNotEmpty ||
      showLowStock.value ||
      showOutOfStock.value ||
      showWithStock.value ||
      showExpired.value;

  // Contadores contextuales - cambian según el filtro aplicado (almacén específico vs general)
  final RxInt fixedTotalItemsCount = 0.obs; // Total contextual
  final RxInt fixedLowStockCount = 0.obs;
  final RxInt fixedOutOfStockCount = 0.obs;
  final RxInt fixedWithStockCount = 0.obs;
  final RxInt fixedExpiredCount = 0.obs;

  int get lowStockCount => fixedLowStockCount.value;
  int get outOfStockCount => fixedOutOfStockCount.value;
  int get withStockCount => fixedWithStockCount.value;
  int get expiredCount => fixedExpiredCount.value;

  double get totalInventoryValue =>
      inventoryBalances.fold(0.0, (sum, b) => sum + b.totalValue);

  String get summaryText {
    // Para el summary mostramos el total de productos filtrados (dinámico)
    // pero para las cards usamos valores fijos
    if (totalItems.value == 0) return 'No hay productos en inventario';
    return '${totalItems.value} productos • ${formatCurrency(totalInventoryValue)}';
  }

  void selectAlertCard(int index) {
    selectedAlertCard.value = index;

    switch (index) {
      case 0: // Todos
        showLowStock.value = false;
        showOutOfStock.value = false;
        showWithStock.value = false;
        showExpired.value = false;
        break;
      case 1: // Con Stock
        showLowStock.value = false;
        showOutOfStock.value = false;
        showWithStock.value = true;
        showExpired.value = false;
        break;
      case 2: // Stock Bajo
        showLowStock.value = true;
        showOutOfStock.value = false;
        showWithStock.value = false;
        showExpired.value = false;
        break;
      case 3: // Sin Stock
        showLowStock.value = false;
        showOutOfStock.value = true;
        showWithStock.value = false;
        showExpired.value = false;
        break;
      case 4: // Vencidos
        showLowStock.value = false;
        showOutOfStock.value = false;
        showWithStock.value = false;
        showExpired.value = true;
        break;
    }

    loadInventoryBalances(refresh: true);
  }

  List<Map<String, dynamic>> get alertCards {
    return [
      {
        'title': 'Todos',
        'count': fixedTotalItemsCount.value, // Valor contextual al filtro
        'color': AppColors.primary,
        'icon': Icons.inventory,
        'index': 0,
      },
      {
        'title': 'Con Stock',
        'count': withStockCount,
        'color': Colors.green,
        'icon': Icons.check_circle,
        'index': 1,
      },
      {
        'title': 'Stock Bajo',
        'count': lowStockCount,
        'color': Colors.orange,
        'icon': Icons.warning,
        'index': 2,
      },
      {
        'title': 'Sin Stock',
        'count': outOfStockCount,
        'color': Colors.red,
        'icon': Icons.error,
        'index': 3,
      },
      {
        'title': 'Vencidos',
        'count': expiredCount,
        'color': Colors.red.shade800,
        'icon': Icons.dangerous,
        'index': 4,
      },
    ];
  }

  // ==================== VALUATION METHODS ====================

  Future<void> loadValuation() async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await getInventoryValuationUseCase(
        warehouseId:
            selectedWarehouse.value.isNotEmpty ? selectedWarehouse.value : null,
        asOfDate: selectedDate.value ?? DateTime.now(),
      );

      result.fold(
        (failure) {
          error.value = failure.message;
        },
        (valuation) {
          valuationData.clear();
          valuationData.addAll(valuation);
          lastUpdated.value = DateTime.now();
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportBalancesToPdf() async {
    try {
      isLoading.value = true;

      // Obtener TODOS los datos filtrados para exportación
      final allFilteredData = await _getAllFilteredBalances();

      if (allFilteredData.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para compartir con el filtro aplicado',
        );
        return;
      }

      await InventoryExportService.exportBalancesToPDF(
        allFilteredData,
        filterInfo: _getFilterInfo(),
        summary: _getSummaryInfo(allFilteredData),
      );
      Get.snackbar('Éxito', 'Balances compartidos correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadBalancesToPdf() async {
    try {
      isLoading.value = true;

      // Obtener TODOS los datos filtrados para exportación
      final allFilteredData = await _getAllFilteredBalances();

      if (allFilteredData.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para descargar con el filtro aplicado',
        );
        return;
      }

      final filePath = await InventoryExportService.downloadBalancesToPDF(
        allFilteredData,
        filterInfo: _getFilterInfo(),
        summary: _getSummaryInfo(allFilteredData),
      );

      // Extract just the filename for cleaner notification
      final fileName = filePath.split('/').last;

      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando PDF: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportBalancesToExcel() async {
    try {
      isLoading.value = true;

      // Obtener TODOS los datos filtrados para exportación
      final allFilteredData = await _getAllFilteredBalances();

      if (allFilteredData.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para compartir con el filtro aplicado',
        );
        return;
      }

      await InventoryExportService.exportBalancesToExcel(
        allFilteredData,
        filterInfo: _getFilterInfo(),
        summary: _getSummaryInfo(allFilteredData),
      );
      Get.snackbar('Éxito', 'Balances compartidos correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo Excel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadBalancesToExcel() async {
    try {
      isLoading.value = true;

      // Obtener TODOS los datos filtrados para exportación
      final allFilteredData = await _getAllFilteredBalances();

      if (allFilteredData.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay balances para descargar con el filtro aplicado',
        );
        return;
      }

      final filePath = await InventoryExportService.downloadBalancesToExcel(
        allFilteredData,
        filterInfo: _getFilterInfo(),
        summary: _getSummaryInfo(allFilteredData),
      );

      // Extract just the filename for cleaner notification
      final fileName = filePath.split('/').last;

      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando Excel: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== HELPER METHODS FOR EXPORT ====================

  /// Obtiene TODOS los datos filtrados desde el backend para exportación
  Future<List<InventoryBalance>> _getAllFilteredBalances() async {
    try {
      print('🔍 Obteniendo todos los datos filtrados para exportación...');

      final params = InventoryBalanceQueryParams(
        page: 1,
        limit: 1000, // Límite alto para obtener todos los datos
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        categoryId:
            selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
        warehouseId:
            selectedWarehouse.value.isNotEmpty ? selectedWarehouse.value : null,
        lowStock: showLowStock.value ? true : null,
        outOfStock: showOutOfStock.value ? true : null,
        expired: showExpired.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getInventoryBalancesUseCase(params);

      return result.fold(
        (failure) {
          print(
            '❌ Error obteniendo datos para exportación: ${failure.message}',
          );
          return <InventoryBalance>[];
        },
        (paginatedResult) {
          print(
            '✅ Datos para exportación obtenidos: ${paginatedResult.data.length} items',
          );

          // Aplicar filtro de "Con Stock" en el cliente si está activo
          List<InventoryBalance> filteredData = paginatedResult.data;
          if (showWithStock.value) {
            filteredData =
                paginatedResult.data
                    .where((balance) => balance.totalQuantity > 0)
                    .toList();
            print(
              '🔍 Filtro "Con Stock" aplicado para exportación: ${filteredData.length} productos',
            );
          }

          return filteredData;
        },
      );
    } catch (e) {
      print('❌ Error obteniendo datos filtrados para exportación: $e');
      return <InventoryBalance>[];
    }
  }

  Map<String, String> _getFilterInfo() {
    final Map<String, String> filterInfo = {};

    // Filtro de categoría seleccionado
    String filterName = 'Todos los productos';
    if (selectedAlertCard.value == 1)
      filterName = 'Con Stock';
    else if (selectedAlertCard.value == 2)
      filterName = 'Stock Bajo';
    else if (selectedAlertCard.value == 3)
      filterName = 'Sin Stock';
    else if (selectedAlertCard.value == 4)
      filterName = 'Vencidos';

    filterInfo['filterType'] = filterName;

    // Información de búsqueda
    if (searchQuery.value.isNotEmpty) {
      filterInfo['search'] = searchQuery.value;
    }

    // Información de ordenamiento
    filterInfo['sortBy'] = getCurrentSortLabel();

    return filterInfo;
  }

  Map<String, dynamic> _getSummaryInfo([List<InventoryBalance>? customData]) {
    final List<InventoryBalance> dataToUse = customData ?? inventoryBalances;
    final int totalProducts = dataToUse.length;
    final int totalQuantity = dataToUse.fold(
      0,
      (sum, b) => sum + b.totalQuantity,
    );
    final double totalValue = dataToUse.fold(
      0.0,
      (sum, b) => sum + b.totalValue,
    );
    final double averageCost =
        totalProducts > 0 && totalQuantity > 0
            ? (totalValue / totalQuantity)
            : 0.0;

    return {
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      'averageCost': averageCost,
    };
  }
}
