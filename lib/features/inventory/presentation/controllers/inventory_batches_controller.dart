// lib/features/inventory/presentation/controllers/inventory_batches_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/usecases/get_inventory_batches_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_export_service.dart';

class InventoryBatchesController extends GetxController {
  final GetInventoryBatchesUseCase getInventoryBatchesUseCase;

  InventoryBatchesController({required this.getInventoryBatchesUseCase});

  // ==================== CONTROLLERS ====================
  
  final TextEditingController searchTextController = TextEditingController();

  // ==================== REACTIVE VARIABLES ====================

  final RxList<InventoryBatch> inventoryBatches = <InventoryBatch>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxString productId = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMore = false.obs;

  // Filters
  final RxString searchQuery = ''.obs;
  final RxString selectedWarehouse = ''.obs;
  final RxString selectedStatus = ''.obs;
  final RxBool showExpiredOnly = false.obs;
  final RxBool showNearExpiryOnly = false.obs;
  final RxBool showActiveOnly = false.obs;
  final RxString sortBy = 'purchaseDate'.obs;
  final RxString sortOrder = 'desc'.obs;

  // UI State
  final RxBool showFilters = false.obs;
  final RxInt selectedTab =
      0.obs; // 0: Todos, 1: Activos, 2: Vencidos, 3: Consumidos

  // Product info
  final RxString productName = ''.obs;
  final RxString productSku = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // No llamar _initializeData aquí porque los parámetros de ruta
    // aún no están disponibles
  }

  @override
  void onReady() {
    super.onReady();
    // Llamar aquí cuando los parámetros de ruta ya están disponibles
    _initializeData();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() async {
    // Obtener el productId desde los argumentos o parámetros de ruta
    final args = Get.arguments as Map<String, dynamic>?;
    final paramId = Get.parameters['productId'];

    print('🔍 [BATCHES] Inicializando datos...');
    print('🔍 [BATCHES] Get.arguments: $args');
    print('🔍 [BATCHES] Get.parameters: ${Get.parameters}');
    print('🔍 [BATCHES] paramId from parameters: $paramId');

    if (args != null && args.containsKey('productId')) {
      productId.value = args['productId'] as String;
      productName.value = args['productName'] as String? ?? '';
      productSku.value = args['productSku'] as String? ?? '';
      print('✅ [BATCHES] ProductId obtenido de arguments: ${productId.value}');
    } else if (paramId != null && paramId.isNotEmpty) {
      productId.value = paramId;
      print('✅ [BATCHES] ProductId obtenido de parameters: ${productId.value}');
    }

    if (productId.value.isNotEmpty) {
      print('✅ [BATCHES] Cargando lotes para producto: ${productId.value}');
      loadInventoryBatches();
    } else {
      print('❌ [BATCHES] No se encontró productId válido');
      error.value = 'ID de producto no válido';
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadBatchCounts() async {
    try {
      print('🔍 InventoryBatchesController: Cargando contadores de lotes');

      // Cargar todos los lotes sin filtros para contar cada categoría
      final params = InventoryBatchQueryParams(
        productId: productId.value,
        page: 1,
        limit: 1000, // Cargar muchos para tener todos
        sortBy: 'purchaseDate',
        sortOrder: 'desc',
      );

      final result = await getInventoryBatchesUseCase(params);

      result.fold(
        (failure) {
          print('❌ Error cargando contadores: ${failure.message}');
        },
        (paginatedResult) {
          final allBatches = paginatedResult.data;
          print('📊 Calculando contadores de ${allBatches.length} lotes');

          // Calcular contadores
          activeBatchesCount.value = allBatches.where((b) => b.isActive).length;
          expiredBatchesCount.value =
              allBatches.where((b) => b.isExpiredByDate).length;
          consumedBatchesCount.value =
              allBatches.where((b) => b.isConsumed).length;

          // Actualizar el total FIJO (nunca cambia después de esto)
          totalFixedItems.value = allBatches.length;

          print('📊 CONTADORES CALCULADOS:');
          print('   • Total: ${totalFixedItems.value}');
          print('   • Activos: ${activeBatchesCount.value}');
          print('   • Vencidos: ${expiredBatchesCount.value}');
          print('   • Agotados: ${consumedBatchesCount.value}');
        },
      );
    } catch (e) {
      print('❌ Exception cargando contadores: $e');
    }
  }

  Future<void> loadInventoryBatches({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        inventoryBatches.clear();
      }

      isLoading.value = refresh || inventoryBatches.isEmpty;
      isLoadingMore.value = !refresh && inventoryBatches.isNotEmpty;
      error.value = '';

      print(
        '🔍 InventoryBatchesController: Cargando lotes para producto ${productId.value}',
      );

      final params = InventoryBatchQueryParams(
        productId: productId.value,
        page: currentPage.value,
        limit: 20,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        warehouseId:
            selectedWarehouse.value.isNotEmpty ? selectedWarehouse.value : null,
        status: _getSelectedStatus(),
        expiredOnly: showExpiredOnly.value ? true : null,
        nearExpiryOnly: showNearExpiryOnly.value ? true : null,
        activeOnly: showActiveOnly.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      print(
        '🔍 SORT DEBUG: sortBy=${sortBy.value}, sortOrder=${sortOrder.value}',
      );

      final result = await getInventoryBatchesUseCase(params);

      result.fold(
        (failure) {
          print('❌ InventoryBatchesController: Error - ${failure.message}');
          error.value = failure.message;
          Get.snackbar(
            'Error al cargar lotes',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          print(
            '✅ InventoryBatchesController: Lotes cargados - ${paginatedResult.data.length} items',
          );

          if (refresh) {
            inventoryBatches.value = paginatedResult.data;
          } else {
            inventoryBatches.addAll(paginatedResult.data);
          }

          currentPage.value = paginatedResult.meta?.currentPage ?? 1;
          totalPages.value = paginatedResult.meta?.totalPages ?? 1;
          totalItems.value =
              paginatedResult.meta?.totalItems ?? paginatedResult.data.length;
          hasMore.value = paginatedResult.meta?.hasNext ?? false;

          // Calcular contadores SOLO la primera vez (nunca más)
          if (totalFixedItems.value == 0 && selectedTab.value == 0) {
            totalFixedItems.value = inventoryBatches.length;
            activeBatchesCount.value = inventoryBatches.where((b) => b.isActive).length;
            expiredBatchesCount.value = inventoryBatches.where((b) => b.isExpiredByDate).length;
            consumedBatchesCount.value = inventoryBatches.where((b) => b.isConsumed).length;
            print('📊 Contadores FIJOS calculados: Todos=${totalFixedItems.value}, Activos=${activeBatchesCount.value}, Agotados=${consumedBatchesCount.value}');
          }

          // Update product info from first batch if available
          if (inventoryBatches.isNotEmpty && productName.value.isEmpty) {
            final firstBatch = inventoryBatches.first;
            productName.value = firstBatch.productName;
            productSku.value = firstBatch.productSku;
          }

          print(
            '📊 Pagination: ${currentPage.value}/${totalPages.value} - ${totalItems.value} total',
          );
        },
      );
    } catch (e) {
      print('❌ InventoryBatchesController: Exception - $e');
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error al cargar lotes',
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

  InventoryBatchStatus? _getSelectedStatus() {
    if (selectedStatus.value.isEmpty) return null;
    return InventoryBatchStatus.values.firstWhere(
      (status) => status.name == selectedStatus.value,
    );
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;

    currentPage.value++;
    await loadInventoryBatches();
  }

  Future<void> refreshBatches() async {
    await loadInventoryBatches(refresh: true);
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
    loadInventoryBatches(refresh: true);
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();
    if (searchQuery.value.isEmpty) {
      // Si está vacío, buscar inmediatamente
      loadInventoryBatches(refresh: true);
    } else {
      // Si hay texto, esperar 800ms para evitar demasiadas peticiones
      _searchTimer = Timer(const Duration(milliseconds: 800), () {
        print('🔍 SEARCH DEBUG: Buscando con query: "${searchQuery.value}"');
        loadInventoryBatches(refresh: true);
      });
    }
  }

  void updateWarehouse(String? warehouse) {
    selectedWarehouse.value = warehouse ?? '';
    loadInventoryBatches(refresh: true);
  }

  void updateStatus(String? status) {
    selectedStatus.value = status ?? '';
    loadInventoryBatches(refresh: true);
  }

  void toggleExpiredOnly() {
    showExpiredOnly.value = !showExpiredOnly.value;
    if (showExpiredOnly.value) {
      showNearExpiryOnly.value = false;
      showActiveOnly.value = false;
    }
    loadInventoryBatches(refresh: true);
  }

  void toggleNearExpiryOnly() {
    showNearExpiryOnly.value = !showNearExpiryOnly.value;
    if (showNearExpiryOnly.value) {
      showExpiredOnly.value = false;
      showActiveOnly.value = false;
    }
    loadInventoryBatches(refresh: true);
  }

  void toggleActiveOnly() {
    showActiveOnly.value = !showActiveOnly.value;
    if (showActiveOnly.value) {
      showExpiredOnly.value = false;
      showNearExpiryOnly.value = false;
    }
    loadInventoryBatches(refresh: true);
  }

  void updateSort(String field, String order) {
    sortBy.value = field;
    sortOrder.value = order;
    loadInventoryBatches(refresh: true);
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedWarehouse.value = '';
    selectedStatus.value = '';
    showExpiredOnly.value = false;
    showNearExpiryOnly.value = false;
    showActiveOnly.value = false;
    sortBy.value = 'purchaseDate';
    sortOrder.value = 'desc';
    loadInventoryBatches(refresh: true);
  }

  // ==================== TAB MANAGEMENT ====================

  void switchTab(int index) {
    selectedTab.value = index;

    // Apply filters based on tab
    switch (index) {
      case 0: // Todos
        showActiveOnly.value = false;
        showExpiredOnly.value = false;
        showNearExpiryOnly.value = false;
        selectedStatus.value = '';
        break;
      case 1: // Activos
        showActiveOnly.value = true;
        showExpiredOnly.value = false;
        showNearExpiryOnly.value = false;
        selectedStatus.value = 'active';
        break;
      case 2: // Vencidos
        showActiveOnly.value = false;
        showExpiredOnly.value = true;
        showNearExpiryOnly.value = false;
        selectedStatus.value = '';
        break;
      case 3: // Agotados
        showActiveOnly.value = false;
        showExpiredOnly.value = false;
        showNearExpiryOnly.value = false;
        selectedStatus.value = 'depleted';
        break;
    }

    loadInventoryBatches(refresh: true);
  }

  // ==================== UI HELPERS ====================

  bool get hasCustomSort =>
      !(sortBy.value == 'purchaseDate' && sortOrder.value == 'desc');

  String getCurrentSortLabel() {
    switch ('${sortBy.value}_${sortOrder.value}') {
      case 'purchaseDate_desc':
        return hasCustomSort ? 'Más Reciente' : 'Ordenar';
      case 'purchaseDate_asc':
        return 'Más Antiguo';
      case 'expirationDate_asc':
        return 'Vence Próximo';
      case 'expirationDate_desc':
        return 'Vence Lejano';
      case 'currentQuantity_desc':
        return 'Mayor Cantidad';
      case 'currentQuantity_asc':
        return 'Menor Cantidad';
      default:
        return 'Ordenar';
    }
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  Color getBatchStatusColor(InventoryBatch batch) {
    if (batch.isExpiredByDate) return Colors.red;
    if (batch.isNearExpiry) return Colors.orange;
    if (batch.isConsumed) return Colors.grey;
    if (batch.isActive) return Colors.green;
    return Colors.blue;
  }

  IconData getBatchStatusIcon(InventoryBatch batch) {
    if (batch.isExpiredByDate) return Icons.dangerous;
    if (batch.isNearExpiry) return Icons.warning;
    if (batch.isConsumed) return Icons.inventory_2;
    if (batch.isActive) return Icons.check_circle;
    return Icons.help;
  }

  String getBatchAgeText(InventoryBatch batch) {
    final days = batch.daysInStock;
    if (days == 0) return 'Hoy';
    if (days == 1) return '1 día';
    return '$days días';
  }

  String getExpiryText(InventoryBatch batch) {
    if (!batch.hasExpiry) return 'Sin vencimiento';

    final days = batch.daysUntilExpiry;
    if (days < 0) return 'Vencido hace ${(-days)} días';
    if (days == 0) return 'Vence hoy';
    if (days == 1) return 'Vence mañana';
    return 'Vence en $days días';
  }

  // ==================== NAVIGATION ====================

  void goToProductDetail() {
    if (productId.value.isNotEmpty) {
      Get.toNamed(
        '/products/detail/${productId.value}',
        arguments: {'productId': productId.value},
      );
    }
  }

  void goToProductKardex() {
    if (productId.value.isNotEmpty) {
      Get.toNamed(
        '/inventory/product/${productId.value}/kardex',
        arguments: {'productId': productId.value},
      );
    }
  }

  void goToPurchaseOrder(String? purchaseOrderId) {
    if (purchaseOrderId != null && purchaseOrderId.isNotEmpty) {
      Get.toNamed(
        '/purchase-orders/detail/$purchaseOrderId',
        arguments: {'purchaseOrderId': purchaseOrderId},
      );
    }
  }

  void goToSupplierDetail(String? supplierId) {
    if (supplierId != null && supplierId.isNotEmpty) {
      Get.toNamed(
        '/suppliers/detail/$supplierId',
        arguments: {'supplierId': supplierId},
      );
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasBatches => inventoryBatches.isNotEmpty;
  bool get hasError => error.value.isNotEmpty;
  bool get hasFiltersApplied =>
      searchQuery.value.isNotEmpty ||
      selectedWarehouse.value.isNotEmpty ||
      selectedStatus.value.isNotEmpty ||
      showExpiredOnly.value ||
      showNearExpiryOnly.value ||
      showActiveOnly.value;

  String get displayTitle =>
      productName.value.isNotEmpty
          ? 'Lotes - ${productName.value}'
          : 'Lotes de Inventario';

  // Contadores fijos desde el backend o carga inicial completa
  final RxInt totalFixedItems = 0.obs; // Total FIJO (nunca cambia)
  final RxInt activeBatchesCount = 0.obs;
  final RxInt expiredBatchesCount = 0.obs;
  final RxInt nearExpiryBatchesCount = 0.obs;
  final RxInt consumedBatchesCount = 0.obs;

  int get totalCurrentQuantity =>
      inventoryBatches.fold(0, (sum, b) => sum + b.currentQuantity);
  double get totalCurrentValue =>
      inventoryBatches.fold(0.0, (sum, b) => sum + b.displayValue);
  

  String get summaryText {
    if (inventoryBatches.isEmpty) return 'No hay lotes para este producto';
    
    final currentLotes = inventoryBatches.length;
    int totalQuantity = 0;
    double totalValue = 0.0;
    
    // Calcular según el estado de los lotes
    for (final batch in inventoryBatches) {
      if (batch.isActive) {
        // Activos: cantidad actual + valor actual
        totalQuantity += batch.currentQuantity;
        totalValue += batch.currentValue;
      } else if (batch.isConsumed) {
        // Agotados: cantidad consumida + valor consumido
        totalQuantity += batch.consumedQuantity;
        totalValue += batch.consumedValue;
      } else {
        // Otros estados: usar cantidad actual + valor actual
        totalQuantity += batch.currentQuantity;
        totalValue += batch.currentValue;
      }
    }
    
    return '$currentLotes lotes • $totalQuantity unidades • ${formatCurrency(totalValue)}';
  }

  List<Map<String, dynamic>> get tabData {
    return [
      {
        'title': 'Todos', 
        'count': totalFixedItems.value, // FIJO: siempre muestra el total real
        'icon': Icons.inventory,
      },
      {
        'title': 'Activos',
        'count': activeBatchesCount.value,
        'icon': Icons.check_circle,
      },
      {
        'title': 'Vencidos',
        'count': expiredBatchesCount.value,
        'icon': Icons.dangerous,
      },
      {
        'title': 'Agotados',
        'count': consumedBatchesCount.value,
        'icon': Icons.inventory_2,
      },
    ];
  }

  // ==================== EXPORT FUNCTIONALITY ====================

  Future<void> exportBatchesToExcel() async {
    try {
      if (inventoryBatches.isEmpty) {
        Get.snackbar('Sin datos', 'No hay lotes para compartir');
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportBatchesToExcel(
        inventoryBatches,
        productName.value,
      );
      Get.snackbar('Éxito', 'Lotes compartidos correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo Excel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadBatchesToExcel() async {
    try {
      if (inventoryBatches.isEmpty) {
        Get.snackbar('Sin datos', 'No hay lotes para descargar');
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadBatchesToExcel(
        inventoryBatches,
        productName.value,
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

  Future<void> exportBatchesToPdf() async {
    try {
      if (inventoryBatches.isEmpty) {
        Get.snackbar('Sin datos', 'No hay lotes para compartir');
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportBatchesToPDF(
        inventoryBatches,
        productName.value,
      );
      Get.snackbar('Éxito', 'Lotes compartidos correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadBatchesToPdf() async {
    try {
      if (inventoryBatches.isEmpty) {
        Get.snackbar('Sin datos', 'No hay lotes para descargar');
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadBatchesToPDF(
        inventoryBatches,
        productName.value,
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
}
