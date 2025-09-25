// lib/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import '../../domain/usecases/get_inventory_balance_by_product_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/warehouse.dart';
import 'inventory_controller.dart';
import 'inventory_balance_controller.dart';

class BulkAdjustmentItem {
  final String id;
  final Product product;
  final InventoryBalance? currentBalance;
  final RxInt newQuantity = 0.obs;
  final RxString notes = ''.obs;
  final RxBool isSelected = true.obs;

  BulkAdjustmentItem({
    required this.id,
    required this.product,
    this.currentBalance,
  });

  int get currentQuantity => currentBalance?.totalQuantity ?? 0;
  int get adjustmentDifference => newQuantity.value - currentQuantity;
  bool get hasChanges => adjustmentDifference != 0;
  InventoryMovementReason get adjustmentReason => InventoryMovementReason.adjustment;
  
  Color get adjustmentColor {
    if (adjustmentDifference > 0) return Colors.green;
    if (adjustmentDifference < 0) return Colors.red;
    return Colors.grey;
  }

  IconData get adjustmentIcon {
    if (adjustmentDifference > 0) return Icons.add;
    if (adjustmentDifference < 0) return Icons.remove;
    return Icons.remove;
  }
}

class InventoryBulkAdjustmentsController extends GetxController {
  final CreateBulkStockAdjustmentsUseCase createBulkStockAdjustmentsUseCase;
  final GetInventoryBalanceByProductUseCase getInventoryBalanceByProductUseCase;
  final SearchProductsUseCase searchProductsUseCase;
  final GetWarehousesUseCase getWarehousesUseCase;

  InventoryBulkAdjustmentsController({
    required this.createBulkStockAdjustmentsUseCase,
    required this.getInventoryBalanceByProductUseCase,
    required this.searchProductsUseCase,
    required this.getWarehousesUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxList<BulkAdjustmentItem> adjustmentItems = <BulkAdjustmentItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString error = ''.obs;
  final RxString globalNotes = ''.obs;
  final Rx<InventoryMovementReason> globalReason = InventoryMovementReason.adjustment.obs;
  
  // Almacén seleccionado para los ajustes
  final RxString selectedWarehouseId = ''.obs;
  final RxString selectedWarehouseName = 'Seleccionar almacén'.obs;
  final RxList<Warehouse> warehouses = <Warehouse>[].obs;

  // Controllers
  final globalNotesController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    globalNotesController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _initializeData() {
    loadWarehouses();
  }

  // ==================== WAREHOUSE LOADING ====================

  Future<void> loadWarehouses() async {
    try {
      isLoading.value = true;
      final result = await getWarehousesUseCase();
      
      result.fold(
        (failure) {
          print('❌ Error cargando almacenes: ${failure.message}');
          error.value = 'Error cargando almacenes: ${failure.message}';
        },
        (warehousesList) {
          warehouses.value = warehousesList;
          print('✅ Almacenes cargados: ${warehousesList.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando almacenes: $e');
      error.value = 'Error inesperado cargando almacenes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== PRODUCT MANAGEMENT ====================

  Future<List<Product>> searchProducts(String query) async {
    try {
      final params = SearchProductsParams(searchTerm: query, limit: 20);
      final result = await searchProductsUseCase(params);
      
      return result.fold(
        (failure) {
          print('❌ Error buscando productos: ${failure.message}');
          return <Product>[];
        },
        (products) => products,
      );
    } catch (e) {
      print('❌ Error inesperado buscando productos: $e');
      return <Product>[];
    }
  }

  Future<void> addProductToAdjustment(Product product) async {
    // Check if warehouse is selected
    if (selectedWarehouseId.value.isEmpty) {
      Get.snackbar(
        '🏪 Seleccione un almacén',
        'Primero debe seleccionar el almacén donde se aplicarán los ajustes. Use el selector de arriba.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.warehouse, color: Colors.orange),
      );
      return;
    }

    // Check if product already exists
    if (adjustmentItems.any((item) => item.product.id == product.id)) {
      Get.snackbar(
        'Información',
        'El producto ${product.name} ya está en la lista',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      isLoading.value = true;
      
      // Get current balance for the product in the selected warehouse
      print('🔍 Obteniendo balance para ${product.name} en almacén ${selectedWarehouseName.value}');
      final balanceResult = await getInventoryBalanceByProductUseCase(
        product.id,
        warehouseId: selectedWarehouseId.value,
      );
      
      InventoryBalance? currentBalance;
      balanceResult.fold(
        (failure) {
          print('⚠️ No se pudo obtener balance para ${product.name} en ${selectedWarehouseName.value}: ${failure.message}');
          currentBalance = null;
        },
        (balance) {
          currentBalance = balance;
          print('✅ Balance obtenido para ${product.name} en ${selectedWarehouseName.value}: ${balance.totalQuantity} unidades');
          print('📊 Detalles del balance: Available=${balance.availableQuantity}, Reserved=${balance.reservedQuantity}');
        },
      );

      // Create adjustment item
      final item = BulkAdjustmentItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        currentBalance: currentBalance,
      );
      
      // Set default new quantity to current quantity
      item.newQuantity.value = item.currentQuantity;
      
      adjustmentItems.add(item);
      
      Get.snackbar(
        'Éxito',
        'Producto ${product.name} agregado (${item.currentQuantity} en ${selectedWarehouseName.value})',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      error.value = 'Error agregando producto: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void removeAdjustmentItem(String itemId) {
    adjustmentItems.removeWhere((item) => item.id == itemId);
    Get.snackbar(
      'Información',
      'Producto removido de la lista',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  void toggleItemSelection(String itemId) {
    final item = adjustmentItems.firstWhereOrNull((item) => item.id == itemId);
    if (item != null) {
      item.isSelected.value = !item.isSelected.value;
    }
  }

  void selectAllItems() {
    for (final item in adjustmentItems) {
      item.isSelected.value = true;
    }
  }

  void deselectAllItems() {
    for (final item in adjustmentItems) {
      item.isSelected.value = false;
    }
  }

  // ==================== BULK OPERATIONS ====================

  void setQuantityForAllSelected(int quantity) {
    for (final item in adjustmentItems) {
      if (item.isSelected.value) {
        item.newQuantity.value = quantity;
      }
    }
  }

  void adjustQuantityForAllSelected(int adjustment) {
    for (final item in adjustmentItems) {
      if (item.isSelected.value) {
        final newQuantity = item.newQuantity.value + adjustment;
        item.newQuantity.value = newQuantity < 0 ? 0 : newQuantity;
      }
    }
  }

  void resetQuantityForAllSelected() {
    for (final item in adjustmentItems) {
      if (item.isSelected.value) {
        item.newQuantity.value = item.currentQuantity;
      }
    }
  }

  void setNotesForAllSelected(String notes) {
    for (final item in adjustmentItems) {
      if (item.isSelected.value) {
        item.notes.value = notes;
      }
    }
  }

  // ==================== VALIDATION ====================

  bool get isFormValid {
    if (selectedWarehouseId.value.isEmpty) return false;
    if (adjustmentItems.isEmpty) return false;
    
    final selectedItems = adjustmentItems.where((item) => item.isSelected.value);
    if (selectedItems.isEmpty) return false;
    
    // Check if at least one item has changes
    return selectedItems.any((item) => item.hasChanges);
  }

  List<BulkAdjustmentItem> get itemsWithChanges {
    return adjustmentItems
        .where((item) => item.isSelected.value && item.hasChanges)
        .toList();
  }

  // ==================== ADJUSTMENT CREATION ====================

  Future<void> createBulkAdjustments() async {
    if (!isFormValid) {
      String errorMessage = '';
      
      if (selectedWarehouseId.value.isEmpty) {
        errorMessage = 'Debe seleccionar un almacén donde aplicar los ajustes';
      } else if (adjustmentItems.isEmpty) {
        errorMessage = 'Debe agregar al menos un producto para ajustar';
      } else if (!adjustmentItems.any((item) => item.isSelected.value)) {
        errorMessage = 'Debe seleccionar al menos un producto';
      } else {
        errorMessage = 'Debe realizar al menos un cambio en las cantidades';
      }
      
      Get.snackbar(
        'Formulario incompleto',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      isCreating.value = true;
      error.value = '';

      final adjustmentsToCreate = itemsWithChanges.map((item) {
        // Para ajustes positivos, obtener el costo del producto
        final unitCost = item.adjustmentDifference > 0 
            ? (item.product.costPrice ?? item.product.sellingPrice ?? 0.0)
            : 0.0;
            
        print('💰 Producto ${item.product.name}: ajuste=${item.adjustmentDifference}, costo=$unitCost');
        
        return CreateStockAdjustmentParams(
          productId: item.product.id,
          adjustmentQuantity: item.adjustmentDifference,
          reason: item.adjustmentReason,
          warehouseId: selectedWarehouseId.value, // INCLUIR EL ALMACÉN SELECCIONADO
          notes: item.notes.value.isNotEmpty 
              ? item.notes.value 
              : globalNotesController.text.trim().isNotEmpty
                  ? globalNotesController.text.trim()
                  : null,
          movementDate: DateTime.now(),
          unitCost: unitCost, // Agregar el costo unitario
        );
      }).toList();

      final result = await createBulkStockAdjustmentsUseCase(adjustmentsToCreate);

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
        (movements) {
          Get.snackbar(
            'Éxito',
            '${movements.length} ajustes creados correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
          
          // Esperar un momento y luego forzar actualización de balances
          Future.delayed(const Duration(seconds: 1), () {
            _forceInventoryRefresh();
          });
          
          _clearForm();
          Get.back(); // Return to previous screen
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isCreating.value = false;
    }
  }

  // ==================== WAREHOUSE MANAGEMENT ====================

  void setSelectedWarehouse(String warehouseId, String warehouseName) {
    // Si cambia el almacén, limpiar la lista de productos
    if (selectedWarehouseId.value != warehouseId && adjustmentItems.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Cambiar almacén'),
          content: const Text('Al cambiar el almacén se perderá la lista actual de productos. ¿Desea continuar?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _applyWarehouseChange(warehouseId, warehouseName);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    } else {
      _applyWarehouseChange(warehouseId, warehouseName);
    }
  }

  void _applyWarehouseChange(String warehouseId, String warehouseName) {
    selectedWarehouseId.value = warehouseId;
    selectedWarehouseName.value = warehouseName;
    adjustmentItems.clear(); // Limpiar productos al cambiar almacén
    
    Get.snackbar(
      'Almacén seleccionado',
      'Los ajustes se aplicarán en: $warehouseName',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // Forzar actualización de datos de inventario después de los ajustes
  void _forceInventoryRefresh() {
    try {
      print('🔄 Forzando actualización de inventario después de ajustes...');
      
      // Obtener el controlador principal de inventario si existe
      if (Get.isRegistered<InventoryController>()) {
        final inventoryController = Get.find<InventoryController>();
        print('📊 Refrescando balances en controlador principal...');
        inventoryController.refreshData();
      }
      
      // También refrescar el controlador de balances si existe
      if (Get.isRegistered<InventoryBalanceController>()) {
        final balanceController = Get.find<InventoryBalanceController>();
        print('💰 Refrescando balances...');
        // balanceController.refreshData(); // Si tiene este método
      }
      
      print('✅ Actualización de inventario iniciada');
    } catch (e) {
      print('⚠️ Error al forzar actualización de inventario: $e');
    }
  }

  void _clearForm() {
    adjustmentItems.clear();
    globalNotesController.clear();
    globalNotes.value = '';
    globalReason.value = InventoryMovementReason.adjustment;
    selectedWarehouseId.value = '';
    selectedWarehouseName.value = 'Seleccionar almacén';
  }

  // ==================== UI HELPERS ====================

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String get summaryText {
    final total = adjustmentItems.length;
    final selected = adjustmentItems.where((item) => item.isSelected.value).length;
    final withChanges = itemsWithChanges.length;
    
    return '$total productos • $selected seleccionados • $withChanges con cambios';
  }

  Color getReasonColor(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.adjustment:
        return Colors.orange;
      case InventoryMovementReason.damage:
        return Colors.red;
      case InventoryMovementReason.loss:
        return Colors.red;
      case InventoryMovementReason.purchase:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getReasonIcon(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.adjustment:
        return Icons.tune;
      case InventoryMovementReason.damage:
        return Icons.broken_image;
      case InventoryMovementReason.loss:
        return Icons.remove_circle;
      case InventoryMovementReason.purchase:
        return Icons.add_shopping_cart;
      default:
        return Icons.help;
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasItems => adjustmentItems.isNotEmpty;
  bool get hasSelectedItems => adjustmentItems.any((item) => item.isSelected.value);
  int get selectedItemsCount => adjustmentItems.where((item) => item.isSelected.value).length;
  int get totalAdjustments => itemsWithChanges.length;

  double get totalValueImpact {
    return itemsWithChanges.fold(0.0, (sum, item) {
      final unitCost = item.product.costPrice ?? item.product.sellingPrice ?? 0.0;
      return sum + (item.adjustmentDifference * unitCost);
    });
  }
}