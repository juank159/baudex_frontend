// lib/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/cost_above_price_dialog.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
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
import '../../../../app/core/theme/futuristic_notifications.dart';
import 'inventory_adjustments_controller.dart';
import 'inventory_controller.dart';

class BulkAdjustmentItem {
  final String id;
  final Product product;
  final InventoryBalance? currentBalance;
  final RxInt newQuantity = 0.obs;
  final RxString notes = ''.obs;
  final RxBool isSelected = true.obs;

  /// Sumar / Restar / Poner cantidad exacta (ninguna al agregar).
  final Rx<StockAdjustMode?> mode = Rx<StockAdjustMode?>(null);

  /// Número escrito en la fila (null = vacío).
  final Rx<int?> amount = Rx<int?>(null);

  BulkAdjustmentItem({
    required this.id,
    required this.product,
    this.currentBalance,
  });

  /// Se pudo leer cuántas unidades hay. Sin ese dato la fila no se ajusta
  /// (antes un fallo dejaba stock 0 y todo parecía aumento).
  bool get stockKnown =>
      currentBalance != null && !currentBalance!.isStockUnconfirmed;

  /// El lote aún no bajó al equipo: el número no es el del almacén.
  bool get stockUnconfirmed => currentBalance?.isStockUnconfirmed == true;

  int get currentQuantity => currentBalance?.totalQuantity ?? 0;
  int get adjustmentDifference => newQuantity.value - currentQuantity;

  StockAdjustmentPlan get plan => StockAdjustmentPlan(
    current: currentQuantity,
    mode: mode.value,
    amount: amount.value,
  );

  /// Problema de la fila ("No puedes restar 25: solo hay 20.").
  String? get errorText => stockKnown ? plan.error : null;

  bool get hasChanges =>
      stockKnown &&
      adjustmentDifference != 0 &&
      newQuantity.value >= 0 &&
      errorText == null;

  InventoryMovementReason get adjustmentReason =>
      InventoryMovementReason.adjustment;

  void setMode(StockAdjustMode? value) {
    if (mode.value == value) return;
    mode.value = value;
    amount.value = null;
    _recompute();
  }

  void setAmount(int? value) {
    amount.value = value;
    _recompute();
  }

  /// Deja la fila en una cantidad exacta (para "Poner en Cero").
  void setExact(int value) {
    mode.value = StockAdjustMode.exact;
    amount.value = value;
    _recompute();
  }

  /// Vuelve a "sin cambios".
  void reset() {
    mode.value = null;
    amount.value = null;
    _recompute();
  }

  void _recompute() {
    newQuantity.value = plan.newQuantity ?? currentQuantity;
  }

  Color get adjustmentColor {
    if (adjustmentDifference > 0) return ElegantLightTheme.successGreen;
    if (adjustmentDifference < 0) return ElegantLightTheme.errorRed;
    return ElegantLightTheme.textTertiary;
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
  final Rx<InventoryMovementReason> globalReason =
      InventoryMovementReason.adjustment.obs;

  /// Razón general elegida en pantalla. Igual que en el ajuste individual,
  /// NO se envía como campo (el servidor rechaza campos extra).
  final RxString generalReason = ''.obs;

  /// Razones de la lista de siempre que sirven para varios productos.
  static const List<String> generalReasons = [
    'Corrección de inventario físico',
    'Mercancía dañada',
    'Productos vencidos',
    'Pérdida o robo',
    'Devolución de cliente',
    'Error en sistema',
    'Otro',
  ];

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
          error.value = 'Error cargando almacenes: ${failure.message}';
        },
        (warehousesList) {
          warehouses.value = warehousesList;
          // Auto-seleccionar si hay exactamente un almacén disponible
          if (warehousesList.length == 1) {
            final w = warehousesList.first;
            _applyWarehouseChange(w.id, w.name);
          }
        },
      );
    } catch (e) {
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

      return result.fold((failure) {
        return <Product>[];
      }, (products) => products);
    } catch (e) {
      return <Product>[];
    }
  }

  Future<void> addProductToAdjustment(Product product) async {
    // Check if warehouse is selected
    if (selectedWarehouseId.value.isEmpty) {
      FuturisticNotifications.showWarning(
        'Elige el almacén',
        'Primero elige el almacén donde se harán los ajustes.',
      );
      return;
    }

    // Check if product already exists
    if (adjustmentItems.any((item) => item.product.id == product.id)) {
      FuturisticNotifications.showInfo(
        'Ya está en la lista',
        '${product.name} ya está en la lista.',
      );
      return;
    }

    try {
      isLoading.value = true;

      // Get current balance for the product in the selected warehouse
      final balanceResult = await getInventoryBalanceByProductUseCase(
        product.id,
        warehouseId: selectedWarehouseId.value,
      );

      InventoryBalance? currentBalance;
      balanceResult.fold(
        (failure) {
          currentBalance = null;
        },
        (balance) {
          currentBalance = balance;
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
    } catch (e) {
      error.value = 'Error agregando producto: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void removeAdjustmentItem(String itemId) {
    adjustmentItems.removeWhere((item) => item.id == itemId);
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
      if (item.isSelected.value && item.stockKnown) {
        item.setExact(quantity);
      }
    }
  }

  void adjustQuantityForAllSelected(int adjustment) {
    for (final item in adjustmentItems) {
      if (item.isSelected.value && item.stockKnown) {
        final newQuantity = item.newQuantity.value + adjustment;
        item.setExact(newQuantity < 0 ? 0 : newQuantity);
      }
    }
  }

  void resetQuantityForAllSelected() {
    for (final item in adjustmentItems) {
      if (item.isSelected.value) {
        item.reset();
      }
    }
  }

  /// Productos seleccionados que se pueden ajustar (se sabe cuánto hay).
  int get selectedAdjustableCount =>
      adjustmentItems
          .where((item) => item.isSelected.value && item.stockKnown)
          .length;

  /// Alguna fila marcada tiene el saldo sin confirmar (lote sin descargar).
  bool get hasUnconfirmedSelected => adjustmentItems.any(
    (item) => item.isSelected.value && item.stockUnconfirmed,
  );

  /// Filas seleccionadas con un número imposible (p. ej. restar de más).
  List<BulkAdjustmentItem> get itemsWithErrors =>
      adjustmentItems
          .where((item) => item.isSelected.value && item.errorText != null)
          .toList();

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

    final selectedItems = adjustmentItems.where(
      (item) => item.isSelected.value,
    );
    if (selectedItems.isEmpty) return false;

    // Una fila con error (restar de más) bloquea: corregirla primero.
    if (itemsWithErrors.isNotEmpty) return false;

    // Saldo sin confirmar en una fila marcada: esperar o quitarla.
    if (hasUnconfirmedSelected) return false;

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
      } else if (hasUnconfirmedSelected) {
        errorMessage = kUnconfirmedStockMessage;
      } else if (itemsWithErrors.isNotEmpty) {
        errorMessage = itemsWithErrors.first.errorText!;
      } else {
        errorMessage = 'Debe realizar al menos un cambio en las cantidades';
      }

      FuturisticNotifications.showWarning('Falta algo', errorMessage);
      return;
    }

    // Las entradas crean lotes con el costo de la ficha del producto.
    final costWarnings =
        [
          for (final item in itemsWithChanges)
            if (item.adjustmentDifference > 0)
              CostAbovePrice.check(
                productName: item.product.name,
                unitCost: item.product.costPrice ?? 0.0,
                unitPrice: item.product.sellingPrice,
              ),
        ].whereType<CostAbovePrice>().toList();
    if (!await confirmCostsAbovePrice(costWarnings)) return;

    try {
      isCreating.value = true;
      error.value = '';

      final adjustmentsToCreate =
          itemsWithChanges.map((item) {
            // Para ajustes positivos, obtener el costo del producto
            final unitCost =
                item.adjustmentDifference > 0
                    ? (item.product.costPrice ??
                        item.product.sellingPrice ??
                        0.0)
                    : 0.0;

            return CreateStockAdjustmentParams(
              productId: item.product.id,
              adjustmentQuantity: item.adjustmentDifference,
              reason: item.adjustmentReason,
              warehouseId:
                  selectedWarehouseId.value, // INCLUIR EL ALMACÉN SELECCIONADO
              notes:
                  item.notes.value.isNotEmpty
                      ? item.notes.value
                      : globalNotesController.text.trim().isNotEmpty
                      ? globalNotesController.text.trim()
                      : null,
              movementDate: Get.find<TenantDateTimeService>().now(),
              unitCost: unitCost, // Agregar el costo unitario
            );
          }).toList();

      final result = await createBulkStockAdjustmentsUseCase(
        adjustmentsToCreate,
      );

      result.fold(
        (failure) {
          error.value = failure.message;
          FuturisticNotifications.showError(
            'No se guardaron los ajustes',
            failure.message.replaceFirst(
              RegExp(r'^Solicitud incorrecta:\s*'),
              '',
            ),
          );
        },
        (movements) {
          FuturisticNotifications.showSuccess(
            'Ajustes guardados',
            movements.length == 1
                ? 'Se guardó 1 ajuste.'
                : 'Se guardaron ${movements.length} ajustes.',
          );

          // Forzar actualización de balances tras un breve delay
          Future.delayed(const Duration(seconds: 1), () {
            _forceInventoryRefresh();
          });

          _clearForm();
          Get.back();
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
    if (selectedWarehouseId.value != warehouseId &&
        adjustmentItems.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          backgroundColor: ElegantLightTheme.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('¿Cambiar de almacén?'),
          content: const Text(
            'Se quitará la lista de productos que llevas. ¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Get.back();
                _applyWarehouseChange(warehouseId, warehouseName);
              },
              child: const Text('Cambiar almacén'),
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
  }

  // Forzar actualización de datos de inventario después de los ajustes
  void _forceInventoryRefresh() {
    try {
      // Obtener el controlador principal de inventario si existe
      if (Get.isRegistered<InventoryController>()) {
        final inventoryController = Get.find<InventoryController>();
        inventoryController.refreshData();
      }
    } catch (e) {}
  }

  void _clearForm() {
    adjustmentItems.clear();
    globalNotesController.clear();
    globalNotes.value = '';
    globalReason.value = InventoryMovementReason.adjustment;
    generalReason.value = '';
    selectedWarehouseId.value = '';
    selectedWarehouseName.value = 'Seleccionar almacén';
  }

  // ==================== UI HELPERS ====================

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String get summaryText {
    final total = adjustmentItems.length;
    final selected =
        adjustmentItems.where((item) => item.isSelected.value).length;
    final withChanges = itemsWithChanges.length;

    return '$total productos • $selected seleccionados • $withChanges con cambios';
  }

  Color getReasonColor(InventoryMovementReason reason) {
    switch (reason) {
      case InventoryMovementReason.adjustment:
        return ElegantLightTheme.warningOrange;
      case InventoryMovementReason.damage:
        return ElegantLightTheme.errorRed;
      case InventoryMovementReason.loss:
        return ElegantLightTheme.errorRed;
      case InventoryMovementReason.purchase:
        return ElegantLightTheme.successGreen;
      default:
        return ElegantLightTheme.textTertiary;
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
  bool get hasSelectedItems =>
      adjustmentItems.any((item) => item.isSelected.value);
  int get selectedItemsCount =>
      adjustmentItems.where((item) => item.isSelected.value).length;
  int get totalAdjustments => itemsWithChanges.length;

  double get totalValueImpact {
    return itemsWithChanges.fold(0.0, (sum, item) {
      final unitCost =
          item.product.costPrice ?? item.product.sellingPrice ?? 0.0;
      return sum + (item.adjustmentDifference * unitCost);
    });
  }
}
