// lib/features/inventory/presentation/controllers/inventory_adjustments_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/usecases/create_stock_adjustment_usecase.dart';
import '../../domain/usecases/get_inventory_balance_by_product_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/warehouse.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

class InventoryAdjustmentsController extends GetxController {
  final CreateStockAdjustmentUseCase createStockAdjustmentUseCase;
  final GetInventoryBalanceByProductUseCase getInventoryBalanceByProductUseCase;
  final SearchProductsUseCase searchProductsUseCase;
  final GetWarehousesUseCase getWarehousesUseCase;

  InventoryAdjustmentsController({
    required this.createStockAdjustmentUseCase,
    required this.getInventoryBalanceByProductUseCase,
    required this.searchProductsUseCase,
    required this.getWarehousesUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString error = ''.obs;

  // Selected product
  final RxString selectedProductId = ''.obs;
  final RxString selectedProductName = ''.obs;
  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final Rx<InventoryBalance?> currentBalance = Rx<InventoryBalance?>(null);

  // Warehouse selection (similar to bulk adjustments)
  final RxString selectedWarehouseId = ''.obs;
  final RxString selectedWarehouseName = 'Seleccionar almacén'.obs;
  final RxList<Warehouse> warehouses = <Warehouse>[].obs;

  // Adjustment form
  final RxInt currentStock = 0.obs;
  final RxInt newQuantity = 0.obs;
  final RxDouble unitCost = 0.0.obs;
  final RxString reason = ''.obs;
  final RxString notes = ''.obs;

  // Controllers
  final newQuantityController = TextEditingController();
  final unitCostController = TextEditingController();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();

  // Predefined reasons
  final List<String> adjustmentReasons = [
    'Corrección de inventario físico',
    'Mercancía dañada',
    'Productos vencidos',
    'Pérdida o robo',
    'Error en sistema',
    'Devolución de cliente',
    'Ajuste por diferencias de conteo',
    'Otro',
  ];

  @override
  void onInit() {
    super.onInit();
    _setupControllerListeners();
    loadWarehouses();
  }

  @override
  void onClose() {
    newQuantityController.dispose();
    unitCostController.dispose();
    reasonController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _setupControllerListeners() {
    newQuantityController.addListener(() {
      final value = int.tryParse(newQuantityController.text) ?? 0;
      newQuantity.value = value;
    });

    unitCostController.addListener(() {
      final value = double.tryParse(unitCostController.text) ?? 0.0;
      unitCost.value = value;
    });

    reasonController.addListener(() {
      reason.value = reasonController.text;
    });

    notesController.addListener(() {
      notes.value = notesController.text;
    });
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

  Future<void> selectProduct(Product product) async {
    selectedProduct.value = product;
    selectedProductId.value = product.id;
    selectedProductName.value = product.name;

    // Load current inventory balance first
    await loadCurrentBalance();

    // Set default unit cost - PRIORITY: costo promedio > costo del producto > dejar vacío
    double? defaultCost;

    // 1. Prioridad: Costo promedio del inventario
    if (currentBalance.value != null && currentBalance.value!.averageCost > 0) {
      defaultCost = currentBalance.value!.averageCost;
    }
    // 2. Si no hay costo promedio, usar costo del producto
    else if (product.costPrice != null && product.costPrice! > 0) {
      defaultCost = product.costPrice!;
    }
    // 3. NO usar precio de venta como fallback - dejar que usuario ingrese manualmente

    if (defaultCost != null) {
      unitCost.value = defaultCost;
      unitCostController.text = defaultCost.toStringAsFixed(2);
    } else {
      // Limpiar campo para que usuario ingrese manualmente
      unitCost.value = 0.0;
      unitCostController.clear();
    }
  }

  Future<void> loadCurrentBalance() async {
    if (selectedProductId.value.isEmpty) return;

    try {
      isLoading.value = true;
      error.value = '';

      // Include warehouse ID when loading balance if a warehouse is selected
      final warehouseIdForBalance =
          selectedWarehouseId.value.isNotEmpty
              ? selectedWarehouseId.value
              : null;

      final result = await getInventoryBalanceByProductUseCase(
        selectedProductId.value,
        warehouseId: warehouseIdForBalance,
      );

      result.fold(
        (failure) {
          error.value = failure.message;
          currentBalance.value = null;
          currentStock.value = 0;
        },
        (balance) {
          currentBalance.value = balance;
          currentStock.value = balance.totalQuantity;
          newQuantityController.text = balance.totalQuantity.toString();
          newQuantity.value = balance.totalQuantity;

          print('📊 Balance cargado para ${selectedProductName.value}:');
          print('   🏪 Almacén: ${selectedWarehouseName.value}');
          print('   📦 Cantidad actual: ${balance.totalQuantity}');
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      currentBalance.value = null;
      currentStock.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== WAREHOUSE MANAGEMENT ====================

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
          print(
            '✅ Almacenes cargados para ajustes individuales: ${warehousesList.length}',
          );
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando almacenes: $e');
      error.value = 'Error inesperado cargando almacenes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void setSelectedWarehouse(String warehouseId, String warehouseName) {
    selectedWarehouseId.value = warehouseId;
    selectedWarehouseName.value = warehouseName;

    print(
      '🏪 Almacén seleccionado para ajuste individual: $warehouseName ($warehouseId)',
    );

    // If a product is already selected, reload its balance for the new warehouse
    if (selectedProductId.value.isNotEmpty) {
      loadCurrentBalance();
    }

    Get.snackbar(
      'Almacén seleccionado',
      'El ajuste se aplicará en: $warehouseName',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // ==================== ADJUSTMENT CREATION ====================

  Future<void> createAdjustment() async {
    if (!_validateForm()) return;

    try {
      isCreating.value = true;
      error.value = '';

      // ✅ FORMATO CORRECTO PARA EL BACKEND (igual que ajustes masivos)
      // Calcular la diferencia para enviar como adjustmentQuantity
      final adjustmentQuantity = newQuantity.value - currentStock.value;

      final requestData = {
        'productId': selectedProductId.value,
        'adjustmentQuantity': adjustmentQuantity, // Diferencia (+5, -3, etc.)
        'warehouseId':
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
        'notes':
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
        'movementDate': DateTime.now().toIso8601String(),
        'unitCost': unitCost.value > 0 ? unitCost.value : 0.0,
      };

      print('📝 Ajuste individual - Producto: ${selectedProductName.value}');
      print('📝 Ajuste individual - Almacén: ${selectedWarehouseName.value}');
      print('📝 Ajuste individual - Cantidad actual: ${currentStock.value}');
      print('📝 Ajuste individual - Nueva cantidad: ${newQuantity.value}');
      print('📝 Ajuste individual - Diferencia: $adjustmentQuantity');
      print('📝 Ajuste individual - Datos a enviar: $requestData');

      final result = await createStockAdjustmentUseCase(requestData);

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
        (adjustment) {
          Get.snackbar(
            'Éxito',
            'Ajuste de inventario creado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          _clearForm();
          Get.back(); // Close form dialog/screen
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

    if (selectedWarehouseId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Debe seleccionar un almacén donde aplicar el ajuste',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    if (newQuantity.value < 0) {
      Get.snackbar(
        'Error',
        'La cantidad no puede ser negativa',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    if (reason.value.isEmpty && reasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Debe especificar una razón para el ajuste',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return false;
    }

    return true;
  }

  void _clearForm() {
    selectedProduct.value = null;
    selectedProductId.value = '';
    selectedProductName.value = '';
    selectedWarehouseId.value = '';
    selectedWarehouseName.value = 'Seleccionar almacén';
    currentBalance.value = null;
    currentStock.value = 0;
    newQuantity.value = 0;
    unitCost.value = 0.0;
    reason.value = '';
    notes.value = '';

    newQuantityController.clear();
    unitCostController.clear();
    reasonController.clear();
    notesController.clear();
  }

  // ==================== QUICK ACTIONS ====================

  void setReasonFromPredefined(String predefinedReason) {
    reason.value = predefinedReason;
    reasonController.text = predefinedReason;
  }

  void increaseQuantity() {
    newQuantity.value++;
    newQuantityController.text = newQuantity.value.toString();
  }

  void decreaseQuantity() {
    if (newQuantity.value > 0) {
      newQuantity.value--;
      newQuantityController.text = newQuantity.value.toString();
    }
  }

  void setQuantityToZero() {
    newQuantity.value = 0;
    newQuantityController.text = '0';
  }

  void resetToCurrentStock() {
    newQuantity.value = currentStock.value;
    newQuantityController.text = currentStock.value.toString();
  }

  // ==================== UI HELPERS ====================

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  Color getAdjustmentColor() {
    final difference = adjustmentDifference;
    if (difference > 0) return Colors.green;
    if (difference < 0) return Colors.red;
    return Colors.grey;
  }

  IconData getAdjustmentIcon() {
    final difference = adjustmentDifference;
    if (difference > 0) return Icons.trending_up;
    if (difference < 0) return Icons.trending_down;
    return Icons.remove;
  }

  String getAdjustmentText() {
    final difference = adjustmentDifference;
    if (difference > 0) return 'Incremento de $difference unidades';
    if (difference < 0) return 'Disminución de ${-difference} unidades';
    return 'Sin cambios';
  }

  // ==================== COMPUTED PROPERTIES ====================

  int get adjustmentDifference => newQuantity.value - currentStock.value;

  bool get hasCurrentBalance => currentBalance.value != null;

  bool get isFormValid =>
      selectedProductId.value.isNotEmpty &&
      selectedWarehouseId.value.isNotEmpty &&
      newQuantity.value >= 0 &&
      (reason.value.isNotEmpty || reasonController.text.trim().isNotEmpty);

  double get adjustmentValue {
    if (unitCost.value <= 0) return 0.0;
    return adjustmentDifference * unitCost.value;
  }

  String get adjustmentValueText {
    final value = adjustmentValue;
    if (value == 0) return 'Sin impacto monetario';

    final sign = value > 0 ? '+' : '';
    return '$sign${formatCurrency(value.abs())}';
  }

  bool get showUnitCostField {
    // Mostrar siempre para incrementos (necesitamos saber el costo de las nuevas unidades)
    if (adjustmentDifference > 0) return true;

    // Para decrementos, solo mostrar si no tenemos costo promedio del inventario
    if (adjustmentDifference < 0) {
      return currentBalance.value?.averageCost == null ||
          currentBalance.value!.averageCost <= 0;
    }

    // Sin cambios, no mostrar
    return false;
  }

  String get submitButtonText {
    if (adjustmentDifference == 0) return 'Sin cambios';
    if (adjustmentDifference > 0) return 'Incrementar Inventario';
    return 'Disminuir Inventario';
  }
}
