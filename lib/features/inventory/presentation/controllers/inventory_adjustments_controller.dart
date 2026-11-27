// lib/features/inventory/presentation/controllers/inventory_adjustments_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../../../app/shared/widgets/cost_above_price_dialog.dart';
import '../../domain/usecases/create_stock_adjustment_usecase.dart';
import '../../domain/usecases/get_inventory_balance_by_product_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/warehouse.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

// ==================== REGLA (pura, sin Flutter ni GetX) ====================

/// Qué quiere hacer el dueño con el stock.
enum StockAdjustMode {
  /// Entran unidades: quedan actual + n.
  add,

  /// Salen unidades: quedan actual − n.
  subtract,

  /// Contó y hay otro número: quedan n.
  exact,
}

/// Aviso cuando el saldo aún no está confirmado en este equipo.
const String kUnconfirmedStockMessage =
    'Saldo sin confirmar: el lote de este producto aún no se ha descargado. '
    'Espera un momento y vuelve a elegir el producto.';

/// Signo menos tipográfico (se lee mejor que el guion).
const String kMinus = '−';

/// "+5", "−5" o "0".
String signedUnits(int value) {
  if (value > 0) return '+$value';
  if (value < 0) return '$kMinus${-value}';
  return '0';
}

/// Cálculo de un ajuste: con cuántas unidades se queda el producto, la
/// diferencia que se envía al servidor y los textos que ve el dueño.
class StockAdjustmentPlan {
  /// Unidades que hay hoy en el almacén.
  final int current;
  final StockAdjustMode? mode;

  /// Número escrito en el campo (null = vacío).
  final int? amount;

  const StockAdjustmentPlan({
    required this.current,
    required this.mode,
    required this.amount,
  });

  /// Unidades con las que queda el producto (null si falta la opción o el
  /// número).
  int? get newQuantity {
    final n = amount;
    if (mode == null || n == null) return null;
    switch (mode!) {
      case StockAdjustMode.add:
        return current + n;
      case StockAdjustMode.subtract:
        return current - n;
      case StockAdjustMode.exact:
        return n;
    }
  }

  /// Lo que se envía como `adjustmentQuantity` (+5, −3…). 0 si no hay plan.
  int get difference {
    final q = newQuantity;
    return q == null ? 0 : q - current;
  }

  /// Problema que impide guardar, dicho para el dueño. null si todo bien o
  /// si aún no ha escrito nada.
  String? get error {
    final n = amount;
    if (mode == null || n == null) return null;
    if (n < 0) return 'Escribe un número de 0 en adelante.';
    switch (mode!) {
      case StockAdjustMode.add:
        if (n == 0) return 'Escribe cuántas unidades entran.';
        return null;
      case StockAdjustMode.subtract:
        if (n == 0) return 'Escribe cuántas unidades salen.';
        if (n > current) return 'No puedes restar $n: solo hay $current.';
        return null;
      case StockAdjustMode.exact:
        if (n == current) return 'Ya hay $current. No hay nada que cambiar.';
        return null;
    }
  }

  /// Hay opción, número y ningún problema.
  bool get isReady => newQuantity != null && error == null && difference != 0;

  /// "Hay 20 → quedarán 15 (−5)". null si falta algo o hay error.
  String? get resultText {
    if (!isReady) return null;
    return 'Hay $current → quedarán ${newQuantity!} (${signedUnits(difference)})';
  }

  /// Texto corto para filas: "20 → 15 (−5)".
  String? get shortResultText {
    if (!isReady) return null;
    return '$current → ${newQuantity!} (${signedUnits(difference)})';
  }

  /// Verbo del botón: "Restar 5 unidades", "Sumar 1 unidad", "Guardar: quedan 15".
  String get buttonText {
    String units(int n) => n == 1 ? '1 unidad' : '$n unidades';
    final n = amount;
    switch (mode) {
      case StockAdjustMode.add:
        return n == null || n <= 0 ? 'Sumar unidades' : 'Sumar ${units(n)}';
      case StockAdjustMode.subtract:
        return n == null || n <= 0 ? 'Restar unidades' : 'Restar ${units(n)}';
      case StockAdjustMode.exact:
        return n == null ? 'Guardar' : 'Guardar: quedan $n';
      case null:
        return 'Guardar ajuste';
    }
  }

  /// Pregunta del campo según la opción.
  static String questionFor(StockAdjustMode mode) {
    switch (mode) {
      case StockAdjustMode.add:
        return '¿Cuántas unidades entran?';
      case StockAdjustMode.subtract:
        return '¿Cuántas unidades salen?';
      case StockAdjustMode.exact:
        return '¿Cuántas unidades contaste?';
    }
  }
}

/// Razones que encajan con cada opción (tomadas de la lista de siempre).
List<String> reasonsForMode(StockAdjustMode? mode) {
  switch (mode) {
    case StockAdjustMode.subtract:
      return const [
        'Mercancía dañada',
        'Productos vencidos',
        'Pérdida o robo',
        'Error en sistema',
        'Otro',
      ];
    case StockAdjustMode.add:
      return const ['Devolución de cliente', 'Error en sistema', 'Otro'];
    case StockAdjustMode.exact:
      return const [
        'Corrección de inventario físico',
        'Ajuste por diferencias de conteo',
        'Error en sistema',
        'Otro',
      ];
    case null:
      return const [];
  }
}

/// Razón que queda elegida al cambiar de opción.
String defaultReasonForMode(StockAdjustMode? mode) =>
    mode == StockAdjustMode.exact ? 'Corrección de inventario físico' : '';

// ==================== CONTROLADOR ====================

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

  /// Leyendo cuántas unidades hay del producto elegido.
  final RxBool isLoadingBalance = false.obs;

  /// No se pudo leer cuántas unidades hay (sin ese dato no se ajusta).
  final RxString balanceError = ''.obs;

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

  /// Opción elegida (ninguna al entrar).
  final Rx<StockAdjustMode?> mode = Rx<StockAdjustMode?>(null);

  /// Número del campo (null = vacío).
  final Rx<int?> amount = Rx<int?>(null);

  /// Unidades con las que queda el producto; se calcula de [mode] y [amount].
  final RxInt newQuantity = 0.obs;
  final RxDouble unitCost = 0.0.obs;
  final RxString reason = ''.obs;
  final RxString notes = ''.obs;

  // Controllers
  /// Campo único: "¿Cuántas unidades entran / salen / contaste?".
  final amountController = TextEditingController();
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
    amountController.dispose();
    unitCostController.dispose();
    reasonController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _setupControllerListeners() {
    amountController.addListener(() {
      final text = amountController.text.trim();
      final value = text.isEmpty ? null : int.tryParse(text);
      if (amount.value != value) setAmount(value);
    });

    unitCostController.addListener(() {
      // parseRate entiende "14.000" (miles) y "1,5" (decimal); double.tryParse
      // leía "14.000" como 14.
      final value = AppFormatters.parseRate(unitCostController.text) ?? 0.0;
      unitCost.value = value;
    });

    reasonController.addListener(() {
      reason.value = reasonController.text;
    });

    notesController.addListener(() {
      notes.value = notesController.text;
    });
  }

  // ==================== MODO Y CANTIDAD ====================

  StockAdjustmentPlan get plan => StockAdjustmentPlan(
    current: currentStock.value,
    mode: mode.value,
    amount: amount.value,
  );

  void _recompute() {
    newQuantity.value = plan.newQuantity ?? currentStock.value;
  }

  /// Elige Sumar / Restar / Poner cantidad exacta. Limpia el número y deja
  /// la razón que encaje.
  void setMode(StockAdjustMode value) {
    if (mode.value == value) return;
    mode.value = value;
    if (!reasonsForMode(value).contains(reason.value)) {
      setReasonFromPredefined(defaultReasonForMode(value));
    }
    amount.value = null;
    if (amountController.text.isNotEmpty) amountController.clear();
    _recompute();
  }

  void setAmount(int? value) {
    amount.value = value;
    _recompute();
  }

  // ==================== PRODUCT SEARCH ====================

  Future<List<Product>> searchProducts(String query) async {
    try {
      final params = SearchProductsParams(searchTerm: query, limit: 10);
      final result = await searchProductsUseCase(params);

      return result.fold((failure) {
        return <Product>[];
      }, (products) => products);
    } catch (e) {
      return <Product>[];
    }
  }

  Future<void> selectProduct(Product product) async {
    selectedProduct.value = product;
    selectedProductId.value = product.id;
    selectedProductName.value = product.name;
    _resetAdjustmentInput();

    // Load current inventory balance first
    await loadCurrentBalance();
    // Mientras se leía se eligió otro producto: este ya no cuenta.
    if (selectedProductId.value != product.id) return;

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

  /// Número de la lectura de saldo en curso: si mientras el servidor
  /// responde se elige otro producto o almacén, la respuesta vieja se ignora.
  int _balanceRequest = 0;

  Future<void> loadCurrentBalance() async {
    if (selectedProductId.value.isEmpty) return;
    final request = ++_balanceRequest;
    bool stale() => request != _balanceRequest;

    try {
      isLoadingBalance.value = true;
      balanceError.value = '';
      error.value = '';
      // Mientras se lee, no hay stock conocido: no se puede ajustar.
      currentBalance.value = null;

      // Include warehouse ID when loading balance if a warehouse is selected
      final warehouseIdForBalance =
          selectedWarehouseId.value.isNotEmpty
              ? selectedWarehouseId.value
              : null;

      final result = await getInventoryBalanceByProductUseCase(
        selectedProductId.value,
        warehouseId: warehouseIdForBalance,
      );
      if (stale()) return;

      result.fold(
        (failure) {
          error.value = failure.message;
          balanceError.value = failure.message;
          currentBalance.value = null;
          currentStock.value = 0;
        },
        (balance) {
          currentBalance.value = balance;
          currentStock.value = balance.totalQuantity;
        },
      );
    } catch (e) {
      if (stale()) return;
      error.value = 'Error inesperado: $e';
      balanceError.value = 'Error inesperado: $e';
      currentBalance.value = null;
      currentStock.value = 0;
    } finally {
      if (!stale()) {
        isLoadingBalance.value = false;
        _recompute();
      }
    }
  }

  // ==================== WAREHOUSE MANAGEMENT ====================

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
            setSelectedWarehouse(w.id, w.name);
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado cargando almacenes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Limpia el formulario manteniendo el almacén seleccionado (útil tras submit exitoso).
  void clearForm() {
    _clearForm();
  }

  void setSelectedWarehouse(String warehouseId, String warehouseName) {
    selectedWarehouseId.value = warehouseId;
    selectedWarehouseName.value = warehouseName;

    // If a product is already selected, reload its balance for the new warehouse
    if (selectedProductId.value.isNotEmpty) {
      _resetAdjustmentInput();
      loadCurrentBalance();
    }
  }

  // ==================== ADJUSTMENT CREATION ====================

  Future<void> createAdjustment() async {
    if (!_validateForm()) return;

    // Entrada de mercancía: el costo ingresado será el de un lote nuevo.
    if (newQuantity.value > currentStock.value) {
      final warning = CostAbovePrice.check(
        productName: selectedProductName.value,
        unitCost: unitCost.value,
        unitPrice: selectedProduct.value?.sellingPrice,
      );
      if (!await confirmCostsAbovePrice([if (warning != null) warning])) {
        return;
      }
    }

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

      final result = await createStockAdjustmentUseCase(requestData);

      result.fold(
        (failure) {
          error.value = failure.message;
          FuturisticNotifications.showError(
            'No se guardó el ajuste',
            _cleanMessage(failure.message),
          );
        },
        (adjustment) {
          FuturisticNotifications.showSuccess(
            'Ajuste guardado',
            'Quedan ${newQuantity.value} unidades de ${selectedProductName.value}.',
          );

          _clearForm();
          Get.back();
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      FuturisticNotifications.showError(
        'No se guardó el ajuste',
        'Error inesperado: $e',
      );
    } finally {
      isCreating.value = false;
    }
  }

  /// Quita el prefijo técnico que pone el cliente HTTP a los 400.
  static String _cleanMessage(String message) =>
      message.replaceFirst(RegExp(r'^Solicitud incorrecta:\s*'), '');

  bool _validateForm() {
    final problem = blockingReason;
    if (problem != null) {
      FuturisticNotifications.showWarning('Falta algo', problem);
      return false;
    }
    return true;
  }

  void _resetAdjustmentInput() {
    mode.value = null;
    amount.value = null;
    if (amountController.text.isNotEmpty) amountController.clear();
    reason.value = '';
    if (reasonController.text.isNotEmpty) reasonController.clear();
    newQuantity.value = currentStock.value;
  }

  void _clearForm() {
    // Una lectura de saldo en curso ya no aplica al formulario vacío.
    _balanceRequest++;
    isLoadingBalance.value = false;
    selectedProduct.value = null;
    selectedProductId.value = '';
    selectedProductName.value = '';
    selectedWarehouseId.value = '';
    selectedWarehouseName.value = 'Seleccionar almacén';
    currentBalance.value = null;
    balanceError.value = '';
    currentStock.value = 0;
    newQuantity.value = 0;
    mode.value = null;
    amount.value = null;
    unitCost.value = 0.0;
    reason.value = '';
    notes.value = '';

    amountController.clear();
    unitCostController.clear();
    reasonController.clear();
    notesController.clear();
  }

  // ==================== QUICK ACTIONS ====================

  void setReasonFromPredefined(String predefinedReason) {
    reason.value = predefinedReason;
    reasonController.text = predefinedReason;
  }

  // ==================== UI HELPERS ====================

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  Color getAdjustmentColor() {
    final difference = adjustmentDifference;
    if (difference > 0) return ElegantLightTheme.successGreen;
    if (difference < 0) return ElegantLightTheme.errorRed;
    return ElegantLightTheme.textTertiary;
  }

  // ==================== COMPUTED PROPERTIES ====================

  int get adjustmentDifference => newQuantity.value - currentStock.value;

  bool get hasCurrentBalance => currentBalance.value != null;

  /// El lote del producto aún no bajó al equipo: `totalQuantity` es el
  /// total del producto, no el del almacén. No se ajusta con ese número.
  bool get isStockUnconfirmed =>
      currentBalance.value?.isStockUnconfirmed == true;

  /// Se sabe cuántas unidades hay: solo entonces se puede ajustar.
  bool get canAdjust =>
      hasCurrentBalance && !isLoadingBalance.value && !isStockUnconfirmed;

  /// Qué falta para guardar, dicho para el dueño (null = listo).
  String? get blockingReason {
    if (selectedWarehouseId.value.isEmpty) return 'Elige el almacén.';
    if (selectedProductId.value.isEmpty) return 'Busca y elige el producto.';
    if (isLoadingBalance.value) {
      return 'Espera: estamos leyendo cuántas unidades hay.';
    }
    if (!hasCurrentBalance) {
      return 'No pudimos leer cuántas unidades hay. Sin ese dato no se puede ajustar.';
    }
    if (isStockUnconfirmed) return kUnconfirmedStockMessage;
    final p = plan;
    if (p.mode == null) {
      return 'Elige si vas a sumar, restar o poner la cantidad exacta.';
    }
    if (p.amount == null) return 'Escribe la cantidad.';
    final e = p.error;
    if (e != null) return e;
    if (reason.value.isEmpty && reasonController.text.trim().isEmpty) {
      return 'Elige una razón para guardar';
    }
    return null;
  }

  bool get isFormValid => blockingReason == null;

  /// Costo de las unidades que entran o salen. 0 si no hay costo.
  double get adjustmentValue {
    if (unitCost.value <= 0) return 0.0;
    return adjustmentDifference * unitCost.value;
  }

  /// "Costo de lo que sale: $ 12.500" / "Costo de lo que entra: $ 12.500".
  String? get costText {
    final value = adjustmentValue;
    if (value == 0 || !plan.isReady) return null;
    final label = value > 0 ? 'Costo de lo que entra' : 'Costo de lo que sale';
    return '$label: ${formatCurrency(value.abs())}';
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

  String get submitButtonText => canAdjust ? plan.buttonText : 'Guardar ajuste';
}
