// lib/features/inventory/presentation/controllers/inventory_movements_controller.dart
import 'dart:async';
import '../../../../app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../domain/entities/inventory_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/usecases/get_inventory_movements_usecase.dart';
import '../../domain/usecases/get_warehouse_movements_usecase.dart';
import '../../domain/usecases/create_inventory_movement_usecase.dart';
import '../../domain/usecases/get_inventory_movement_by_id_usecase.dart';
import '../../domain/usecases/confirm_inventory_movement_usecase.dart';
import '../../domain/usecases/cancel_inventory_movement_usecase.dart';
import '../../domain/usecases/calculate_fifo_consumption_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';
import '../services/inventory_export_service.dart';
import '../../domain/entities/inventory_balance.dart';
import '../widgets/fifo_consumption_widget.dart';

class InventoryMovementsController extends GetxController {
  final GetInventoryMovementsUseCase getInventoryMovementsUseCase;
  final GetWarehouseMovementsUseCase getWarehouseMovementsUseCase;
  final CreateInventoryMovementUseCase createInventoryMovementUseCase;
  final GetInventoryMovementByIdUseCase getInventoryMovementByIdUseCase;
  final ConfirmInventoryMovementUseCase confirmInventoryMovementUseCase;
  final CancelInventoryMovementUseCase cancelInventoryMovementUseCase;
  final CalculateFifoConsumptionUseCase calculateFifoConsumptionUseCase;
  final SearchProductsUseCase searchProductsUseCase;

  InventoryMovementsController({
    required this.getInventoryMovementsUseCase,
    required this.getWarehouseMovementsUseCase,
    required this.createInventoryMovementUseCase,
    required this.getInventoryMovementByIdUseCase,
    required this.confirmInventoryMovementUseCase,
    required this.cancelInventoryMovementUseCase,
    required this.calculateFifoConsumptionUseCase,
    required this.searchProductsUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxList<InventoryMovement> movements = <InventoryMovement>[].obs;
  final RxList<InventoryMovement> filteredMovements = <InventoryMovement>[].obs;
  final Rx<InventoryMovement?> selectedMovement = Rx<InventoryMovement?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isCreating = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // Filters
  final RxString productIdFilter = ''.obs;
  final RxString warehouseIdFilter = ''.obs;
  final Rx<InventoryMovementType?> typeFilter = Rx<InventoryMovementType?>(
    null,
  );
  final Rx<InventoryMovementStatus?> statusFilter =
      Rx<InventoryMovementStatus?>(null);
  final Rx<DateTime?> startDateFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> endDateFilter = Rx<DateTime?>(null);

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPrevPage = false.obs;
  static const int pageSize = 20;

  // Sorting
  final RxString sortBy = 'movementDate'.obs;
  final RxString sortOrder = 'desc'.obs;

  // UI State
  final RxBool isRefreshing = false.obs;
  final RxBool showFilters = false.obs;

  // Form state for new movement
  final RxString selectedProductId = ''.obs;
  final RxString selectedProductName = ''.obs;
  final Rx<InventoryMovementType> selectedType =
      InventoryMovementType.inbound.obs;
  final Rx<InventoryMovementReason> selectedReason =
      InventoryMovementReason.adjustment.obs;
  final RxInt quantity = 1.obs;
  final RxDouble unitCost = 0.0.obs;
  final RxString notes = ''.obs;
  final Rx<DateTime> movementDate = DateTime.now().obs;

  // FIFO state
  final RxList<FifoConsumption> fifoConsumptions = <FifoConsumption>[].obs;
  final RxBool isCalculatingFifo = false.obs;
  final RxBool showFifoPreview = false.obs;

  // Controllers
  final searchController = TextEditingController();
  final notesController = TextEditingController();

  // Cache para nombres de productos
  final RxMap<String, String> productNamesCache = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    // Capturar argumentos de la navegación
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('productId')) {
      productIdFilter.value = args['productId'] as String;
      print(
        '🔍 InventoryMovementsController: Filtro por producto: ${productIdFilter.value}',
      );
    }

    if (args != null && args.containsKey('warehouseId')) {
      warehouseIdFilter.value = args['warehouseId'] as String;
      print(
        '🔍 InventoryMovementsController: Filtro por almacén: ${warehouseIdFilter.value}',
      );
    }

    loadMovements();
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
      currentPage.value = 1;
      movements.clear();
      loadMovements();
    });
  }

  Timer? _searchTimer;

  // Cargar nombres de productos faltantes
  Future<void> _loadMissingProductNames() async {
    try {
      // Obtener IDs de productos únicos que no están en el cache
      final missingProductIds = <String>{};
      for (final movement in movements) {
        if (!productNamesCache.containsKey(movement.productId)) {
          missingProductIds.add(movement.productId);
        }
      }

      if (missingProductIds.isEmpty) return;

      // Buscar todos los productos con una búsqueda general
      final searchResult = await searchProductsUseCase(
        const SearchProductsParams(
          searchTerm: '', // Búsqueda vacía para obtener todos
          limit: 1000, // Límite alto para obtener todos los productos
        ),
      );

      searchResult.fold(
        (failure) {
          // Si falla, poner nombres por defecto
          for (final id in missingProductIds) {
            productNamesCache[id] = 'Producto ID: ${id.substring(0, 8)}';
          }
        },
        (products) {
          // Crear un mapa para búsqueda rápida por ID
          final productsById = <String, String>{};
          for (final product in products) {
            productsById[product.id] = product.name;
          }

          // Agregar productos encontrados al cache
          for (final id in missingProductIds) {
            if (productsById.containsKey(id)) {
              productNamesCache[id] = productsById[id]!;
            } else {
              productNamesCache[id] = 'Producto eliminado';
            }
          }
        },
      );
    } catch (e) {
      print('Error cargando nombres de productos: $e');
      // Poner nombres por defecto en caso de error
      for (final movement in movements) {
        if (!productNamesCache.containsKey(movement.productId)) {
          productNamesCache[movement.productId] = 'Error al cargar';
        }
      }
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadMovements({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      error.value = '';

      // Check if we should use warehouse-specific endpoint
      final result =
          warehouseIdFilter.value.isNotEmpty
              ? await _loadWarehouseSpecificMovements()
              : await _loadGeneralMovements();

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

          // Siempre actualizar filteredMovements con los datos cargados
          filteredMovements.assignAll(movements);

          // Cargar nombres de productos faltantes
          _loadMissingProductNames();
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

  Future<void> loadMovementById(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await getInventoryMovementByIdUseCase(id);

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
        (movement) {
          selectedMovement.value = movement;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== MOVEMENT CREATION ====================

  Future<void> createMovement() async {
    if (!_validateForm()) return;

    try {
      isCreating.value = true;
      error.value = '';

      final params = CreateInventoryMovementParams(
        productId: selectedProductId.value,
        type: selectedType.value,
        reason: selectedReason.value,
        quantity:
            (selectedType.value == InventoryMovementType.outbound ||
                    selectedType.value == InventoryMovementType.transferOut)
                ? -quantity.value
                : quantity.value,
        unitCost: unitCost.value > 0 ? unitCost.value : 0.0,
        movementDate: movementDate.value,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      final result = await createInventoryMovementUseCase(params);

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
        (movement) {
          Get.snackbar(
            'Éxito',
            'Movimiento de inventario creado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          _clearForm();
          refreshMovements();
          Get.back(); // Close form dialog/screen
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isCreating.value = false;
    }
  }

  bool _validateForm() {
    if (selectedProductId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Debe seleccionar un producto',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    if (quantity.value <= 0) {
      Get.snackbar(
        'Error',
        'La cantidad debe ser mayor a cero',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    // Validate unit cost when required
    if (_isUnitCostRequired() && unitCost.value <= 0) {
      Get.snackbar(
        'Error',
        'El costo de compra es requerido para este tipo de movimiento',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    return true;
  }

  // Check if unit cost is required based on movement type and reason
  bool _isUnitCostRequired() {
    final type = selectedType.value;
    final reason = selectedReason.value;

    // Unit cost is required for purchases
    if ((type == InventoryMovementType.inbound ||
            type == InventoryMovementType.transferIn) &&
        reason == InventoryMovementReason.purchase) {
      return true;
    }

    return false; // Optional for other cases
  }

  void _clearForm() {
    selectedProductId.value = '';
    selectedProductName.value = '';
    selectedType.value = InventoryMovementType.inbound;
    selectedReason.value = InventoryMovementReason.adjustment;
    quantity.value = 1;
    unitCost.value = 0.0;
    notesController.clear();
    movementDate.value = DateTime.now();
  }

  // ==================== MOVEMENT ACTIONS ====================

  Future<void> confirmMovement(String id) async {
    try {
      isLoading.value = true;

      final result = await confirmInventoryMovementUseCase(id);

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
        (confirmedMovement) {
          Get.snackbar(
            'Éxito',
            'Movimiento confirmado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          refreshMovements();
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

  Future<void> cancelMovement(String id) async {
    try {
      isLoading.value = true;

      final result = await cancelInventoryMovementUseCase(id);

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
        (cancelledMovement) {
          Get.snackbar(
            'Éxito',
            'Movimiento cancelado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          refreshMovements();
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

  // ==================== PRODUCT SEARCH ====================

  Future<List<Product>> searchProducts(String query) async {
    try {
      final params = SearchProductsParams(searchTerm: query, limit: 10);
      final result = await searchProductsUseCase(params);

      return result.fold((failure) {
        print('❌ Error buscando productos: ${failure.message}');
        return <Product>[];
      }, (products) => products);
    } catch (e) {
      print('❌ Error inesperado buscando productos: $e');
      return <Product>[];
    }
  }

  void selectProduct(Product product) {
    print(
      '🎯 InventoryMovementsController: Selecting product - ${product.name} (${product.id})',
    );

    selectedProductId.value = product.id;
    selectedProductName.value = product.name;

    // Set default unit cost if available
    if (product.costPrice != null && product.costPrice! > 0) {
      unitCost.value = product.costPrice!;
      print('💰 Setting unit cost from costPrice: ${product.costPrice!}');
    } else if (product.sellingPrice != null && product.sellingPrice! > 0) {
      unitCost.value = product.sellingPrice!;
      print('💰 Setting unit cost from sellingPrice: ${product.sellingPrice!}');
    }

    print(
      '✅ Product selected: ID=${selectedProductId.value}, Name=${selectedProductName.value}',
    );
  }

  // ==================== FILTERING & SEARCH ====================

  void applyFilters() {
    currentPage.value = 1;
    movements.clear();
    loadMovements();
  }

  void clearFilters() {
    productIdFilter.value = '';
    warehouseIdFilter.value = '';
    typeFilter.value = null;
    statusFilter.value = null;
    startDateFilter.value = null;
    endDateFilter.value = null;
    searchController.clear();
    searchQuery.value = '';

    currentPage.value = 1;
    movements.clear();
    loadMovements();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // ==================== PAGINATION ====================

  Future<void> loadNextPage() async {
    if (!isLoadingMore.value && hasNextPage.value) {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadMovements(showLoading: false);
    }
  }

  // ==================== REFRESH & RELOAD ====================

  Future<void> refreshMovements() async {
    isRefreshing.value = true;
    currentPage.value = 1;
    movements.clear();
    await loadMovements(showLoading: false);
  }

  // ==================== SORTING ====================

  void sortMovements(String field) {
    if (sortBy.value == field) {
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      sortBy.value = field;
      sortOrder.value =
          ['movementDate', 'totalCost', 'quantity'].contains(field)
              ? 'desc'
              : 'asc';
    }

    currentPage.value = 1;
    movements.clear();
    loadMovements();
  }

  // ==================== UI HELPERS ====================

  void goToCreateMovement() {
    // Show dialog instead of navigating to a route
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 500,
          child: const Text('Create Movement Dialog'), // Placeholder
        ),
      ),
      barrierDismissible: false,
    );
  }

  void goToMovementDetail(InventoryMovement movement) {
    // Si el movimiento es de una venta y tiene referencia a factura, navegar a la factura
    if (movement.referenceType == 'invoice_paid' &&
        movement.referenceId != null) {
      Get.toNamed('/invoices/detail/${movement.referenceId}');
      return;
    }

    // Si es una compra y tiene referencia, navegar a la orden de compra
    if (movement.referenceType == 'purchase_order' &&
        movement.referenceId != null) {
      Get.snackbar(
        'Información',
        'Orden de compra: ${movement.referenceId}',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Para otros tipos de movimiento, mostrar información general
    Get.snackbar(
      'Información',
      'Movimiento: ${movement.type.name} - ${movement.quantity} unidades',
      snackPosition: SnackPosition.TOP,
    );
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String getProductName(String productId) {
    return productNamesCache[productId] ?? 'Cargando...';
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatDateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  Color getMovementTypeColor(InventoryMovementType type) {
    switch (type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        return Colors.green;
      case InventoryMovementType.outbound:
      case InventoryMovementType.transferOut:
        return Colors.red;
      case InventoryMovementType.adjustment:
        return Colors.orange;
      case InventoryMovementType.transfer:
        return Colors.blue;
    }
  }

  Color getMovementStatusColor(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return Colors.orange;
      case InventoryMovementStatus.confirmed:
        return Colors.green;
      case InventoryMovementStatus.cancelled:
        return Colors.red;
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  List<InventoryMovement> get displayedMovements {
    // Enriquecer movimientos con nombres de productos del cache
    return filteredMovements.map((movement) {
      final cachedName = productNamesCache[movement.productId];
      if (cachedName != null && movement.productName != cachedName) {
        // Crear una copia del movimiento con el nombre actualizado
        return InventoryMovement(
          id: movement.id,
          productId: movement.productId,
          productName: cachedName,
          productSku: movement.productSku,
          type: movement.type,
          status: movement.status,
          reason: movement.reason,
          quantity: movement.quantity,
          unitCost: movement.unitCost,
          totalCost: movement.totalCost,
          lotNumber: movement.lotNumber,
          expiryDate: movement.expiryDate,
          warehouseId: movement.warehouseId,
          warehouseName: movement.warehouseName,
          referenceId: movement.referenceId,
          referenceType: movement.referenceType,
          notes: movement.notes,
          userId: movement.userId,
          userName: movement.userName,
          movementDate: movement.movementDate,
          createdAt: movement.createdAt,
          updatedAt: movement.updatedAt,
        );
      }
      return movement;
    }).toList();
  }

  bool get hasMovements => movements.isNotEmpty;
  bool get hasResults => filteredMovements.isNotEmpty;

  String get resultsText {
    if (searchQuery.value.isNotEmpty) {
      return '${filteredMovements.length} movimientos encontrados';
    } else {
      return '${totalItems.value} movimientos de inventario';
    }
  }

  bool get canLoadMore =>
      hasNextPage.value && !isLoadingMore.value && !isLoading.value;

  bool get isFormValid =>
      selectedProductId.value.isNotEmpty && quantity.value > 0;

  Map<String, dynamic> get activeFiltersCount {
    int count = 0;
    final List<String> activeFilters = [];

    if (productIdFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Producto específico');
    }
    if (warehouseIdFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Almacén específico');
    }
    if (typeFilter.value != null) {
      count++;
      activeFilters.add('Tipo: ${typeFilter.value!.displayType}');
    }
    if (statusFilter.value != null) {
      count++;
      activeFilters.add('Estado: ${statusFilter.value!.displayStatus}');
    }
    if (startDateFilter.value != null) {
      count++;
      activeFilters.add('Desde: ${formatDate(startDateFilter.value!)}');
    }
    if (endDateFilter.value != null) {
      count++;
      activeFilters.add('Hasta: ${formatDate(endDateFilter.value!)}');
    }

    return {'count': count, 'filters': activeFilters};
  }

  // ==================== FIFO FUNCTIONALITY ====================

  Future<void> calculateFifoConsumption() async {
    if (selectedProductId.value.isEmpty || quantity.value <= 0) return;

    try {
      isCalculatingFifo.value = true;
      fifoConsumptions.clear();

      final params = CalculateFifoConsumptionParams(
        productId: selectedProductId.value,
        quantity: quantity.value,
      );

      final result = await calculateFifoConsumptionUseCase(params);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error FIFO',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (consumptions) {
          fifoConsumptions.value = consumptions;
          showFifoPreview.value = true;

          // Update unit cost based on FIFO calculation
          if (consumptions.isNotEmpty) {
            final totalCost = consumptions.fold(
              0.0,
              (sum, c) => sum + c.totalCost,
            );
            final totalQuantity = consumptions.fold(
              0,
              (sum, c) => sum + c.quantityConsumed,
            );
            if (totalQuantity > 0) {
              unitCost.value = totalCost / totalQuantity;
            }
          }
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado calculando FIFO: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isCalculatingFifo.value = false;
    }
  }

  void showFifoPreviewDialog() {
    if (fifoConsumptions.isEmpty) {
      calculateFifoConsumption();
      return;
    }

    FifoConsumptionDialog.show(
      consumptions: fifoConsumptions,
      productName: selectedProductName.value,
      totalQuantityRequested: quantity.value,
    );
  }

  void hideFifoPreview() {
    showFifoPreview.value = false;
    fifoConsumptions.clear();
  }

  bool get shouldShowFifoButton =>
      (selectedType.value == InventoryMovementType.outbound ||
          selectedType.value == InventoryMovementType.transferOut) &&
      selectedProductId.value.isNotEmpty &&
      quantity.value > 0;

  bool get hasFifoData => fifoConsumptions.isNotEmpty;

  // ==================== EXPORT FUNCTIONALITY ====================

  Future<void> exportMovementsToPdf() async {
    try {
      if (movements.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay movimientos para exportar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportMovementsToPDF(movements);

      Get.snackbar(
        'Éxito',
        'Movimientos exportados a PDF correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando a PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportMovementsToExcel() async {
    try {
      if (movements.isEmpty) {
        Get.snackbar(
          'Sin datos',
          'No hay movimientos para exportar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportMovementsToExcel(movements);

      Get.snackbar(
        'Éxito',
        'Movimientos exportados a Excel correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando a Excel: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== HELPER METHODS ====================

  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>>
  _loadWarehouseSpecificMovements() async {
    final params = InventoryMovementQueryParams(
      page: currentPage.value,
      limit: pageSize,
      search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      productId:
          productIdFilter.value.isNotEmpty ? productIdFilter.value : null,
      warehouseId:
          null, // Don't include warehouseId in query params for specific endpoint
      type: typeFilter.value,
      status: statusFilter.value,
      startDate: startDateFilter.value,
      endDate: endDateFilter.value,
      sortBy: sortBy.value,
      sortOrder: sortOrder.value,
    );

    return await getWarehouseMovementsUseCase.call(
      warehouseIdFilter.value,
      params,
    );
  }

  Future<Either<Failure, core.PaginatedResult<InventoryMovement>>>
  _loadGeneralMovements() async {
    final params = InventoryMovementQueryParams(
      page: currentPage.value,
      limit: pageSize,
      search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      productId:
          productIdFilter.value.isNotEmpty ? productIdFilter.value : null,
      warehouseId:
          warehouseIdFilter.value.isNotEmpty ? warehouseIdFilter.value : null,
      type: typeFilter.value,
      status: statusFilter.value,
      startDate: startDateFilter.value,
      endDate: endDateFilter.value,
      sortBy: sortBy.value,
      sortOrder: sortOrder.value,
    );

    return await getInventoryMovementsUseCase(params);
  }

  void showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Movimientos de Inventario',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: const Text('Exportar a PDF'),
                    subtitle: const Text('Formato para impresión'),
                    onTap: () {
                      Get.back();
                      exportMovementsToPdf();
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('Exportar a Excel'),
                    subtitle: const Text('Formato para análisis'),
                    onTap: () {
                      Get.back();
                      exportMovementsToExcel();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
