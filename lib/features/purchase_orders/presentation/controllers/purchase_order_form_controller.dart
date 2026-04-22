// lib/features/purchase_orders/presentation/controllers/purchase_order_form_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/create_purchase_order_usecase.dart';
import '../../domain/usecases/update_purchase_order_usecase.dart';
import '../../domain/usecases/get_purchase_order_by_id_usecase.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/usecases/search_suppliers_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';
import 'purchase_orders_controller.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../../../settings/domain/entities/organization.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class PurchaseOrderFormController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final CreatePurchaseOrderUseCase createPurchaseOrderUseCase;
  final UpdatePurchaseOrderUseCase updatePurchaseOrderUseCase;
  final GetPurchaseOrderByIdUseCase getPurchaseOrderByIdUseCase;
  final SearchSuppliersUseCase searchSuppliersUseCase;
  final SearchProductsUseCase searchProductsUseCase;

  PurchaseOrderFormController({
    required this.createPurchaseOrderUseCase,
    required this.updatePurchaseOrderUseCase,
    required this.getPurchaseOrderByIdUseCase,
    required this.searchSuppliersUseCase,
    required this.searchProductsUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;
  final Rx<PurchaseOrder?> purchaseOrder = Rx<PurchaseOrder?>(null);
  final RxBool isEditMode = false.obs;

  // Form validation - Generate unique key per instance to avoid conflicts
  late final GlobalKey<FormState> formKey;
  final RxBool isFormValid = false.obs;

  // Form Controllers - Basic Info
  final supplierController = TextEditingController();
  final orderDateController = TextEditingController();
  final expectedDeliveryDateController = TextEditingController();
  final currencyController = TextEditingController();
  final notesController = TextEditingController();
  final internalNotesController = TextEditingController();

  // Form Controllers - Delivery Info
  final deliveryAddressController = TextEditingController();
  final contactPersonController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final contactEmailController = TextEditingController();

  // Dropdowns and selections
  final RxString selectedSupplierId = ''.obs;
  final RxString selectedSupplierName = ''.obs;
  final Rx<Supplier?> selectedSupplier = Rx<Supplier?>(null);
  final Rx<PurchaseOrderPriority> priority = PurchaseOrderPriority.medium.obs;
  final Rx<DateTime> orderDate = DateTime.now().obs;
  final Rx<DateTime> expectedDeliveryDate =
      DateTime.now().add(const Duration(days: 7)).obs;

  // Items management
  final RxList<PurchaseOrderItemForm> items = <PurchaseOrderItemForm>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble taxAmount = 0.0.obs;
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble totalAmount = 0.0.obs;

  // Multi-moneda (opcional). Si selectedPurchaseCurrency == null o coincide
  // con la moneda base de la organización, el PO se guarda sin los 3 campos
  // multi-moneda. Si el usuario elige otra moneda, se activa el cálculo
  // automático: totalAmount (base) = foreignAmount * exchangeRate.
  final Rxn<String> selectedPurchaseCurrency = Rxn<String>();
  final Rxn<double> exchangeRate = Rxn<double>();
  final Rxn<double> foreignAmount = Rxn<double>();
  final exchangeRateController = TextEditingController();
  final foreignAmountController = TextEditingController();

  // Config reactiva de la organización (multi-moneda). Se hidrata en onInit
  // desde OrganizationController y se mantiene sincronizada vía worker, así
  // el dropdown aparece al abrir el form sin necesidad de forzar refresh.
  final RxBool multiCurrencyEnabledRx = false.obs;
  final RxString baseCurrencyCodeRx = 'COP'.obs;
  final RxList<Map<String, dynamic>> acceptedCurrenciesRx =
      <Map<String, dynamic>>[].obs;
  Worker? _orgWorker;

  // Getters legacy (no-reactivos) por compatibilidad con código existente.
  bool get multiCurrencyEnabled => multiCurrencyEnabledRx.value;
  String get baseCurrencyCode => baseCurrencyCodeRx.value;
  List<Map<String, dynamic>> get acceptedCurrencies =>
      acceptedCurrenciesRx.toList();

  // Active item tracking
  final RxInt activeItemIndex = (-1).obs;

  // Search within added items
  final itemSearchController = TextEditingController();
  final RxString itemSearchQuery = ''.obs;

  // ScrollController para la lista de items
  final itemsScrollController = ScrollController();

  // Validation flags
  final RxBool supplierError = false.obs;
  final RxBool orderDateError = false.obs;
  final RxBool expectedDeliveryDateError = false.obs;
  final RxBool itemsError = false.obs;

  // UI State
  final RxBool showDeliveryInfo = false.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isStepValid = false.obs;

  @override
  void onInit() {
    print('🏗️ PurchaseOrderFormController onInit iniciado');
    super.onInit();
    SyncService.notifyFormOpened();
    try {
      // Initialize truly unique form key using timestamp to prevent GlobalKey conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = 'PurchaseOrderForm_${timestamp}_${hashCode.toString()}';
      formKey = GlobalKey<FormState>(debugLabel: uniqueId);
      print('🔑 FormKey único generado: $uniqueId');

      _initializeForm();
      _setupFormValidation();
      // Arrancar watcher de organization para que el dropdown multi-moneda
      // aparezca al abrir el form sin depender de que el usuario entre a
      // settings primero.
      _startOrgWatcher();
      print('✅ PurchaseOrderFormController inicializado correctamente');
    } catch (e) {
      print('❌ Error en PurchaseOrderFormController onInit: $e');
      error.value = 'Error en inicialización: $e';
    }
  }

  @override
  void onClose() {
    SyncService.notifyFormClosed();
    print(
      '🗑️ PurchaseOrderFormController: Iniciando dispose de controladores...',
    );

    try {
      // Dispose form key and clear form state
      if (formKey.currentState != null) {
        formKey.currentState?.reset();
      }
      print('🔑 FormKey limpiado');

      // Clear all reactive variables
      isLoading.value = false;
      isSaving.value = false;
      error.value = '';
      items.clear();

      // Dispose scroll controller
      itemsScrollController.dispose();

      // Dispose all text controllers
      _disposeControllers();

      // Cerrar watcher del org para no fugar listeners.
      _orgWorker?.dispose();
      _orgWorker = null;

      print('✅ PurchaseOrderFormController: Dispose completado exitosamente');
    } catch (e) {
      print('❌ Error durante dispose: $e');
    }

    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeForm() {
    // Valores por defecto — usar timezone del tenant (no DateTime.now() del device)
    final dtService = Get.find<TenantDateTimeService>();
    orderDate.value = dtService.now();
    expectedDeliveryDate.value = dtService.now().add(const Duration(days: 7));
    currencyController.text = 'COP';
    orderDateController.text = _formatDate(orderDate.value);
    expectedDeliveryDateController.text = _formatDate(
      expectedDeliveryDate.value,
    );

    // Verificar si viene un supplierId preseleccionado
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('supplierId')) {
      selectedSupplierId.value = args['supplierId'] as String;
      // TODO: Cargar nombre del proveedor
    }

    // Si hay un ID en los argumentos, cargar la orden
    if (args != null && args.containsKey('purchaseOrderId')) {
      final purchaseOrderId = args['purchaseOrderId'] as String;
      loadPurchaseOrder(purchaseOrderId);
    } else {
      // Agregar un item vacío por defecto
      addEmptyItem();
    }
  }

  void _setupFormValidation() {
    // Escuchar cambios en los campos principales
    supplierController.addListener(_validateForm);
    orderDateController.addListener(_validateForm);
    expectedDeliveryDateController.addListener(_validateForm);

    // Escuchar cambios en items y en el item activo
    ever(items, (_) {
      _validateForm();
      _watchForNewDuplicates();
    });
    ever(activeItemIndex, (_) => _validateForm());
  }

  // Cantidad de duplicados previos — usado para detectar el MOMENTO exacto
  // en que aparecen duplicados nuevos (no en cada tick).
  int _lastDuplicateCount = 0;

  void _watchForNewDuplicates() {
    final currentCount = duplicateItemIndices.length;
    if (currentCount > _lastDuplicateCount && currentCount > 0) {
      _elegantSnack(
        'Producto repetido detectado',
        'Hay $currentCount producto(s) repetido(s). No podrás guardar hasta eliminarlos.',
        type: 'error',
      );
    }
    _lastDuplicateCount = currentCount;
  }

  void _disposeControllers() {
    try {
      // Dispose each controller only if it hasn't been disposed already
      _safeDispose(supplierController, 'supplierController');
      _safeDispose(orderDateController, 'orderDateController');
      _safeDispose(
        expectedDeliveryDateController,
        'expectedDeliveryDateController',
      );
      _safeDispose(currencyController, 'currencyController');
      _safeDispose(notesController, 'notesController');
      _safeDispose(internalNotesController, 'internalNotesController');
      _safeDispose(deliveryAddressController, 'deliveryAddressController');
      _safeDispose(contactPersonController, 'contactPersonController');
      _safeDispose(contactPhoneController, 'contactPhoneController');
      _safeDispose(contactEmailController, 'contactEmailController');
      _safeDispose(itemSearchController, 'itemSearchController');
      _safeDispose(exchangeRateController, 'exchangeRateController');
      _safeDispose(foreignAmountController, 'foreignAmountController');
      print('✅ Todos los controladores disposed correctamente');
    } catch (e) {
      print('❌ Error disposing controladores: $e');
    }
  }

  void _safeDispose(TextEditingController controller, String name) {
    try {
      print('🗑️ Disposing $name...');
      controller.dispose();
    } catch (e) {
      if (e.toString().contains('disposed')) {
        print('ℹ️ $name ya estaba disposed');
      } else {
        print('⚠️ Error disposing $name: $e');
      }
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadPurchaseOrder(String purchaseOrderId) async {
    try {
      isLoading.value = true;
      isEditMode.value = true;
      error.value = '';

      final result = await getPurchaseOrderByIdUseCase(purchaseOrderId);

      result.fold(
        (failure) {
          error.value = failure.message;
          _elegantSnack('Error', failure.message, type: 'error');
        },
        (loadedPurchaseOrder) {
          purchaseOrder.value = loadedPurchaseOrder;
          _populateForm(loadedPurchaseOrder);
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      _elegantSnack('Error', 'Error inesperado: $e', type: 'error');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateForm(PurchaseOrder order) {
    // Poblar datos del proveedor
    selectedSupplierId.value = order.supplierId ?? '';
    selectedSupplierName.value = order.supplierName ?? '';
    supplierController.text = order.supplierName ?? '';

    // Crear objeto Supplier básico si tenemos la información
    if (order.supplierId != null && order.supplierName != null) {
      selectedSupplier.value = Supplier(
        id: order.supplierId!,
        name: order.supplierName!,
        documentType: DocumentType.nit,
        documentNumber: '000000000',
        status: SupplierStatus.active,
        currency: order.currency ?? 'COP',
        paymentTermsDays: 30,
        creditLimit: 0.0,
        discountPercentage: 0.0,
        organizationId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      print(
        '📝 Proveedor básico creado para edición: ${order.supplierName!} (${order.supplierId!})',
      );
    }

    // Poblar prioridad (puede venir del campo priority o metadata)
    priority.value = order.priority ?? PurchaseOrderPriority.medium;
    print('📝 Prioridad cargada: ${priority.value}');
    final dtService = Get.find<TenantDateTimeService>();
    orderDate.value = order.orderDate ?? dtService.now();
    expectedDeliveryDate.value = order.expectedDeliveryDate ?? dtService.now();
    orderDateController.text = _formatDate(order.orderDate ?? dtService.now());
    expectedDeliveryDateController.text = _formatDate(
      order.expectedDeliveryDate ?? dtService.now(),
    );

    currencyController.text = order.currency ?? 'COP';

    // Cargar multi-moneda si la PO fue creada con moneda foránea.
    if (order.purchaseCurrency != null) {
      selectedPurchaseCurrency.value = order.purchaseCurrency;
      exchangeRate.value = order.exchangeRate;
      foreignAmount.value = order.purchaseCurrencyAmount;
      exchangeRateController.text =
          AppFormatters.formatRate(order.exchangeRate ?? 0);
      foreignAmountController.text =
          AppFormatters.formatRate(order.purchaseCurrencyAmount ?? 0);
    }

    notesController.text = order.notes ?? '';
    internalNotesController.text = order.internalNotes ?? '';

    deliveryAddressController.text = order.deliveryAddress ?? '';
    contactPersonController.text = order.contactPerson ?? '';
    contactPhoneController.text = order.contactPhone ?? '';
    contactEmailController.text = order.contactEmail ?? '';

    showDeliveryInfo.value = order.hasDeliveryInfo;

    // Cargar items
    items.value =
        order.items
            .map((item) => PurchaseOrderItemForm.fromEntity(item))
            .toList();
    print('📝 Items cargados: ${items.length}');

    // Calcular totales y validar formulario
    calculateTotals();
    _validateForm();

    // Forzar actualización de la UI
    update();

    print('✅ Formulario poblado exitosamente para edición:');
    print(
      '   - Proveedor: ${selectedSupplier.value?.name ?? "No asignado"} (${selectedSupplierId.value})',
    );
    print('   - Prioridad: ${priority.value}');
    print('   - Items: ${items.length}');
    print('   - Total: ${totalAmount.value}');
  }

  // ==================== FORM VALIDATION ====================

  void _validateForm() {
    // Validación básica
    final hasSupplier = selectedSupplierId.value.isNotEmpty;
    final hasValidDate = orderDate.value.isBefore(expectedDeliveryDate.value);
    final hasItems = items.isNotEmpty && items.any((item) => item.isValid);
    final noDupes = duplicateItemIndices.isEmpty;

    isFormValid.value = hasSupplier && hasValidDate && hasItems && noDupes;

    // Validar step actual
    switch (currentStep.value) {
      case 0: // Información básica
        isStepValid.value = hasSupplier && hasValidDate;
        break;
      case 1: // Items - todos válidos, sin duplicados y sin item en edición
        isStepValid.value =
            items.isNotEmpty &&
            items.every((item) => item.isValid) &&
            noDupes &&
            activeItemIndex.value < 0;
        break;
      case 2: // Información adicional
        isStepValid.value = true; // Información adicional es opcional
        break;
      default:
        isStepValid.value = true;
    }
  }

  // ==================== DETECCIÓN DE DUPLICADOS ====================

  /// Índices de items que están repetidos en la lista (segunda aparición en
  /// adelante). Compara por productId, nombre, SKU y barcode — si alguno
  /// coincide con un item previo, se marca como duplicado.
  Set<int> get duplicateItemIndices {
    final dupes = <int>{};
    for (var i = 1; i < items.length; i++) {
      final a = items[i];
      if (a.productId.isEmpty) continue;
      for (var j = 0; j < i; j++) {
        final b = items[j];
        if (b.productId.isEmpty) continue;
        if (_itemsMatch(a, b)) {
          dupes.add(i);
          break;
        }
      }
    }
    return dupes;
  }

  bool _itemsMatch(PurchaseOrderItemForm a, PurchaseOrderItemForm b) {
    if (a.productId == b.productId) return true;
    final an = a.productName.trim().toLowerCase();
    final bn = b.productName.trim().toLowerCase();
    if (an.isNotEmpty && an == bn) return true;
    final asku = a.productSku.trim().toLowerCase();
    final bsku = b.productSku.trim().toLowerCase();
    if (asku.isNotEmpty && asku == bsku) return true;
    final abc = a.productBarcode.trim().toLowerCase();
    final bbc = b.productBarcode.trim().toLowerCase();
    if (abc.isNotEmpty && abc == bbc) return true;
    return false;
  }

  /// Descripción legible de los duplicados encontrados, para mostrar en banner.
  String get duplicatesSummary {
    final dupes = duplicateItemIndices;
    if (dupes.isEmpty) return '';
    final names = dupes
        .map((i) => items[i].productName)
        .where((n) => n.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
    if (names.isEmpty) return '${dupes.length} producto(s) repetido(s)';
    final extra = dupes.length > names.length ? '…' : '';
    return '${names.join(', ')}$extra';
  }

  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return _validateBasicInfo();
      case 1:
        return _validateItems();
      case 2:
        return _validateAdditionalInfo();
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    bool isValid = true;

    // Validar proveedor
    if (selectedSupplierId.value.isEmpty) {
      supplierError.value = true;
      isValid = false;
    } else {
      supplierError.value = false;
    }

    // Validar fechas
    if (orderDate.value.isAfter(expectedDeliveryDate.value)) {
      orderDateError.value = true;
      expectedDeliveryDateError.value = true;
      isValid = false;
    } else {
      orderDateError.value = false;
      expectedDeliveryDateError.value = false;
    }

    return isValid;
  }

  bool _validateItems() {
    bool isValid = true;

    if (items.isEmpty || !items.any((item) => item.isValid)) {
      itemsError.value = true;
      isValid = false;
    } else {
      itemsError.value = false;
    }

    // Bloquear si hay duplicados — no se avanza ni se guarda con repetidos
    if (duplicateItemIndices.isNotEmpty) {
      itemsError.value = true;
      isValid = false;
    }

    return isValid;
  }

  bool _validateAdditionalInfo() {
    // Validar email si está presente
    if (contactEmailController.text.isNotEmpty &&
        !GetUtils.isEmail(contactEmailController.text)) {
      return false;
    }

    return true;
  }

  // ==================== ITEMS MANAGEMENT ====================

  void addEmptyItem() {
    clearItemSearch();
    items.add(PurchaseOrderItemForm());
    activeItemIndex.value = items.length - 1;
    calculateTotals();
    // Auto-scroll al nuevo item después de que el frame se renderice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemsScrollController.hasClients) {
        itemsScrollController.animateTo(
          itemsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToItem(int index) {
    if (!itemsScrollController.hasClients) return;
    // Estimar posición: cada item completado ~60px, item activo ~280px
    final estimatedOffset = index * 65.0;
    final maxScroll = itemsScrollController.position.maxScrollExtent;
    itemsScrollController.animateTo(
      estimatedOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void clearItemSearch() {
    itemSearchQuery.value = '';
    itemSearchController.clear();
  }

  /// Retorna los índices originales de items que coinciden con la búsqueda.
  /// Busca en nombre, SKU y código de barras (case-insensitive).
  List<int> get filteredItemIndices {
    final query = itemSearchQuery.value.toLowerCase().trim();
    if (query.isEmpty) {
      return List.generate(items.length, (i) => i);
    }
    final indices = <int>[];
    for (var i = 0; i < items.length; i++) {
      // Siempre mostrar el item activo (en edición) para no desorientar
      if (i == activeItemIndex.value) {
        indices.add(i);
        continue;
      }
      final it = items[i];
      final name = it.productName.toLowerCase();
      final sku = it.productSku.toLowerCase();
      final barcode = it.productBarcode.toLowerCase();
      if (name.contains(query) ||
          (sku.isNotEmpty && sku.contains(query)) ||
          (barcode.isNotEmpty && barcode.contains(query))) {
        indices.add(i);
      }
    }
    return indices;
  }

  void completeActiveItem() {
    if (activeItemIndex.value >= 0 && activeItemIndex.value < items.length) {
      final item = items[activeItemIndex.value];
      if (item.isValid) {
        activeItemIndex.value = -1;
      }
    }
  }

  void editItem(int index) {
    if (index >= 0 && index < items.length) {
      activeItemIndex.value = index;
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    if (items.length > 1) {
      final removedName = items[index].productName;
      items.removeAt(index);
      if (activeItemIndex.value == index) {
        activeItemIndex.value = -1;
      } else if (activeItemIndex.value > index) {
        activeItemIndex.value--;
      }
      calculateTotals();
      _elegantSnack(
        'Producto eliminado',
        '"$removedName" removido. Quedan ${items.length} productos.',
        type: 'warning',
      );
    }
  }

  void updateItemProduct(
    int index,
    String productId,
    String productName,
    double unitPrice,
  ) {
    if (index < items.length) {
      items[index] = items[index].copyWith(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
      );
      calculateTotals();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    print('🔢 updateItemQuantity llamado: index=$index, quantity=$quantity');
    if (index < items.length) {
      final oldItem = items[index];
      print('🔢 Item anterior: quantity=${oldItem.quantity}');
      items[index] = items[index].copyWith(quantity: quantity);
      print('🔢 Item actualizado: quantity=${items[index].quantity}');
      calculateTotals();
    } else {
      print(
        '🔢 ERROR: Index $index fuera de rango (items.length=${items.length})',
      );
    }
  }

  void updateItemPrice(int index, double unitPrice) {
    if (index < items.length) {
      // Si el usuario edita manualmente el precio en base, rompemos el link
      // con el precio extranjero (evita que se recalcule y sobrescriba el
      // valor manual al cambiar la tasa).
      items[index] = items[index].copyWith(
        unitPrice: unitPrice,
        clearForeignUnitPrice: true,
      );
      calculateTotals();
    }
  }

  /// El usuario ingresó el precio unitario EN moneda extranjera para un item.
  /// Internamente convertimos a base usando la tasa actual y guardamos ambos.
  void updateItemForeignPrice(int index, double foreignPrice) {
    if (index < 0 || index >= items.length) return;
    final rate = exchangeRate.value;
    if (rate == null || rate <= 0) {
      // Sin tasa válida, tratamos el valor como base y limpiamos el foreign
      items[index] = items[index].copyWith(
        unitPrice: foreignPrice,
        clearForeignUnitPrice: true,
      );
    } else {
      // Convención del proyecto: 1 foreign = rate base
      // baseAmount = foreignAmount * rate
      final baseUnitPrice = foreignPrice * rate;
      items[index] = items[index].copyWith(
        unitPrice: baseUnitPrice,
        foreignUnitPrice: foreignPrice,
      );
    }
    calculateTotals();
  }

  /// Recalcula unitPrice (en base) de todos los items que tienen
  /// foreignUnitPrice, usando la tasa actual. Se invoca al cambiar la tasa o
  /// la moneda seleccionada para mantener consistencia.
  void _reapplyForeignPricesToBase() {
    final rate = exchangeRate.value;
    if (rate == null || rate <= 0) return;
    bool anyChanged = false;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final f = it.foreignUnitPrice;
      if (f == null) continue;
      final newBase = f * rate;
      if ((newBase - it.unitPrice).abs() > 0.000001) {
        items[i] = it.copyWith(unitPrice: newBase);
        anyChanged = true;
      }
    }
    if (anyChanged) calculateTotals();
  }

  void updateItemDiscount(int index, double discountPercentage) {
    if (index < items.length) {
      items[index] = items[index].copyWith(
        discountPercentage: discountPercentage,
      );
      calculateTotals();
    }
  }

  void updateItemTax(int index, double taxPercentage) {
    if (index < items.length) {
      items[index] = items[index].copyWith(taxPercentage: taxPercentage);
      calculateTotals();
    }
  }

  void calculateTotals() {
    double calculatedSubtotal = 0.0;
    double calculatedTaxAmount = 0.0;
    double calculatedDiscountAmount = 0.0;

    for (final item in items) {
      if (item.isValid) {
        final itemSubtotal = item.quantity * item.unitPrice;
        final itemDiscountAmount =
            itemSubtotal * (item.discountPercentage / 100);
        final itemSubtotalAfterDiscount = itemSubtotal - itemDiscountAmount;
        final itemTaxAmount =
            itemSubtotalAfterDiscount * (item.taxPercentage / 100);

        calculatedSubtotal += itemSubtotal;
        calculatedDiscountAmount += itemDiscountAmount;
        calculatedTaxAmount += itemTaxAmount;
      }
    }

    subtotal.value = calculatedSubtotal;
    discountAmount.value = calculatedDiscountAmount;
    taxAmount.value = calculatedTaxAmount;
    totalAmount.value =
        calculatedSubtotal - calculatedDiscountAmount + calculatedTaxAmount;

    // Si hay moneda extranjera seleccionada, mantener el monto foráneo
    // sincronizado con el total base recién calculado.
    if (selectedPurchaseCurrency.value != null) {
      _recomputeForeignFromBase();
    }
  }

  // ==================== MULTI-MONEDA ====================

  /// Hidrata la config multi-moneda desde OrganizationController. Seguro de
  /// llamar múltiples veces (idempotente). Si el org aún no ha cargado,
  /// mantiene defaults y el worker la sincronizará cuando llegue.
  void _hydrateOrgConfig() {
    try {
      if (!Get.isRegistered<OrganizationController>()) return;
      final org = Get.find<OrganizationController>().currentOrganization;
      if (org == null) return;
      baseCurrencyCodeRx.value = org.currency;
      multiCurrencyEnabledRx.value = org.multiCurrencyEnabled;
      acceptedCurrenciesRx.value = List<Map<String, dynamic>>.from(
        org.acceptedCurrencies,
      );
    } catch (_) {}
  }

  /// Escucha cambios del org (cuando termina de cargarse o el usuario
  /// edita settings) y re-hidrata la config. Se arranca en onInit.
  void _startOrgWatcher() {
    try {
      if (!Get.isRegistered<OrganizationController>()) return;
      final ctrl = Get.find<OrganizationController>();

      // Sync inicial inmediato (si la org ya está en memoria).
      _hydrateOrgConfig();

      // Si aún no hay org cargada, disparamos la carga para asegurar que
      // el dropdown aparezca al abrir el form por primera vez.
      if (ctrl.currentOrganization == null) {
        // ignore: discarded_futures
        ctrl.loadCurrentOrganization().then((_) => _hydrateOrgConfig());
      }

      // Escuchar cambios futuros (p.ej. usuario edita settings y regresa).
      _orgWorker = ever<Organization?>(ctrl.currentOrganizationRx, (_) {
        _hydrateOrgConfig();
      });
    } catch (_) {}
  }

  /// Cambia la moneda seleccionada. Si es la base, limpia los campos
  /// multi-moneda. Si es otra, pre-carga la tasa desde acceptedCurrencies.
  void onCurrencyChanged(String? code) {
    if (code == null || code == baseCurrencyCode) {
      selectedPurchaseCurrency.value = null;
      exchangeRate.value = null;
      foreignAmount.value = null;
      exchangeRateController.clear();
      foreignAmountController.clear();
      return;
    }
    selectedPurchaseCurrency.value = code;
    final info = acceptedCurrencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => <String, dynamic>{},
    );
    final defaultRate = (info['defaultRate'] as num?)?.toDouble() ?? 1.0;
    exchangeRate.value = defaultRate;
    // Usa el mismo formateador que el dialog de pago de facturas (es_CO).
    exchangeRateController.text = AppFormatters.formatRate(defaultRate);
    _recomputeForeignFromBase();
    // Cualquier precio ya ingresado en moneda extranjera debe re-convertirse
    // a base con la nueva tasa (para items agregados antes de cambiar moneda).
    _reapplyForeignPricesToBase();
  }

  /// El usuario editó la tasa manualmente — re-calcular monto extranjero.
  /// Usa `parseRate` (igual que facturas) para interpretar correctamente el
  /// formato es_CO: "6" → 6, "6,00" → 6, "4.000" → 4000, "0,12" → 0.12.
  void onExchangeRateChanged(String text) {
    final parsed = AppFormatters.parseRate(text);
    if (parsed == null || parsed <= 0) return;
    exchangeRate.value = parsed;
    _recomputeForeignFromBase();
    _reapplyForeignPricesToBase();
  }

  /// El usuario editó el monto extranjero — re-calcular total base.
  /// Nota: por ahora la "fuente de verdad" es el total en base (subtotal+tax),
  /// por lo que normalmente no es necesario que el usuario edite el foráneo.
  void onForeignAmountChanged(String text) {
    final parsed = AppFormatters.parseRate(text);
    if (parsed == null || parsed <= 0) return;
    foreignAmount.value = parsed;
  }

  /// Recalcula `foreignAmount = totalAmount / exchangeRate`.
  void _recomputeForeignFromBase() {
    final rate = exchangeRate.value;
    if (rate == null || rate <= 0 || totalAmount.value <= 0) {
      foreignAmount.value = null;
      foreignAmountController.clear();
      return;
    }
    final f = totalAmount.value / rate;
    foreignAmount.value = f;
    foreignAmountController.text = f.toStringAsFixed(2);
  }

  // ==================== FORM SUBMISSION ====================

  Future<void> savePurchaseOrder() async {
    // Corte duro: productos duplicados no se guardan (ni como borrador)
    if (duplicateItemIndices.isNotEmpty) {
      final list = duplicatesSummary;
      _elegantSnack(
        'Hay productos repetidos',
        list.isEmpty
            ? 'Elimina los items duplicados antes de guardar.'
            : 'Duplicados: $list. Elimínalos antes de guardar.',
        type: 'error',
      );
      // Forzar al usuario al paso de items para que los vea
      currentStep.value = 1;
      itemsError.value = true;
      return;
    }

    if (!isFormValid.value || !formKey.currentState!.validate()) {
      _elegantSnack(
        'Revisa el formulario',
        'Por favor completa los campos requeridos',
        type: 'warning',
      );
      return;
    }

    try {
      isSaving.value = true;
      error.value = '';

      if (isEditMode.value) {
        await _updatePurchaseOrder();
      } else {
        await _createPurchaseOrder();
      }
    } catch (e) {
      error.value = 'Error inesperado: $e';
      _elegantSnack('Error', 'Error inesperado: $e', type: 'error');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _createPurchaseOrder() async {
    final validItems = items.where((item) => item.isValid).toList();

    final params = CreatePurchaseOrderParams(
      supplierId: selectedSupplierId.value,
      supplierName: selectedSupplierName.value.isNotEmpty
          ? selectedSupplierName.value
          : null,
      priority: priority.value,
      orderDate: orderDate.value,
      expectedDeliveryDate: expectedDeliveryDate.value,
      currency:
          currencyController.text.trim().isNotEmpty
              ? currencyController.text.trim()
              : 'COP',
      items:
          validItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return item.toCreateParams(lineNumber: index + 1);
          }).toList(),
      notes:
          notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
      internalNotes:
          internalNotesController.text.trim().isNotEmpty
              ? internalNotesController.text.trim()
              : null,
      deliveryAddress:
          deliveryAddressController.text.trim().isNotEmpty
              ? deliveryAddressController.text.trim()
              : null,
      contactPerson:
          contactPersonController.text.trim().isNotEmpty
              ? contactPersonController.text.trim()
              : null,
      contactPhone:
          contactPhoneController.text.trim().isNotEmpty
              ? contactPhoneController.text.trim()
              : null,
      contactEmail:
          contactEmailController.text.trim().isNotEmpty
              ? contactEmailController.text.trim()
              : null,
      // Multi-moneda (solo si el usuario seleccionó moneda extranjera).
      purchaseCurrency: selectedPurchaseCurrency.value,
      purchaseCurrencyAmount: selectedPurchaseCurrency.value != null
          ? foreignAmount.value
          : null,
      exchangeRate: selectedPurchaseCurrency.value != null
          ? exchangeRate.value
          : null,
    );

    final result = await createPurchaseOrderUseCase(params);

    result.fold(
      (failure) {
        print('❌ Error del use case: ${failure.message}');
        error.value = failure.message;
        _elegantSnack('No se pudo crear la orden', failure.message,
            type: 'error');
      },
      (createdPurchaseOrder) {
        print(
          '✅ Orden de compra creada exitosamente: ${createdPurchaseOrder.id}',
        );
        _elegantSnack(
          'Orden creada',
          'La orden de compra se creó correctamente',
          type: 'success',
        );
        _navigateToListAndRefresh(createdPurchaseOrder);
      },
    );
  }

  Future<void> _updatePurchaseOrder() async {
    if (purchaseOrder.value == null) return;

    final params = UpdatePurchaseOrderParams(
      id: purchaseOrder.value!.id,
      supplierId: selectedSupplierId.value,
      priority: priority.value,
      orderDate: orderDate.value,
      expectedDeliveryDate: expectedDeliveryDate.value,
      currency:
          currencyController.text.trim().isNotEmpty
              ? currencyController.text.trim()
              : 'COP',
      items:
          items
              .where((item) => item.isValid)
              .map((item) => item.toUpdateParams())
              .toList(),
      notes:
          notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
      internalNotes:
          internalNotesController.text.trim().isNotEmpty
              ? internalNotesController.text.trim()
              : null,
      deliveryAddress:
          deliveryAddressController.text.trim().isNotEmpty
              ? deliveryAddressController.text.trim()
              : null,
      contactPerson:
          contactPersonController.text.trim().isNotEmpty
              ? contactPersonController.text.trim()
              : null,
      contactPhone:
          contactPhoneController.text.trim().isNotEmpty
              ? contactPhoneController.text.trim()
              : null,
      contactEmail:
          contactEmailController.text.trim().isNotEmpty
              ? contactEmailController.text.trim()
              : null,
      // Multi-moneda: mismo patrón que en create.
      purchaseCurrency: selectedPurchaseCurrency.value,
      purchaseCurrencyAmount: selectedPurchaseCurrency.value != null
          ? foreignAmount.value
          : null,
      exchangeRate: selectedPurchaseCurrency.value != null
          ? exchangeRate.value
          : null,
    );

    final result = await updatePurchaseOrderUseCase(params);

    result.fold(
      (failure) {
        error.value = failure.message;
        _elegantSnack('No se pudo actualizar la orden', failure.message,
            type: 'error');
      },
      (updatedPurchaseOrder) {
        _navigateToListAndRefresh(updatedPurchaseOrder);
      },
    );
  }

  /// Navega al listado inmediatamente y actualiza la PO en la lista
  void _navigateToListAndRefresh(PurchaseOrder savedOrder) {
    // Navegar inmediatamente — no bloquear al usuario
    Get.until((route) =>
        route.settings.name == '/purchase-orders' || route.isFirst);

    // Mostrar notificación de éxito inmediatamente
    _showSuccessNotification(savedOrder);

    // Invalidar cache para que loadPurchaseOrders() no sobreescriba con datos viejos
    PurchaseOrdersController.invalidateCache();

    // Actualizar la PO directamente en la lista (sin re-cargar del servidor)
    // Esto evita que el servidor sobrescriba cambios offline aún no sincronizados
    Future.microtask(() {
      if (Get.isRegistered<PurchaseOrdersController>()) {
        final listController = Get.find<PurchaseOrdersController>();
        listController.updateOrderInList(savedOrder);
      }
    });
  }

  void _showSuccessNotification(PurchaseOrder order) {
    final isUpdate = isEditMode.value;
    final hasTempId = order.id.startsWith('po_offline_') ||
        (order.id.startsWith('po_') && !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(order.id));
    // Detectar offline para CREATEs (ID temporal) Y para UPDATEs (servidor no alcanzable)
    bool isOffline = hasTempId;
    if (!isOffline && isUpdate) {
      try {
        final networkInfo = Get.find<NetworkInfo>();
        isOffline = !networkInfo.isServerReachable;
      } catch (_) {}
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (isOffline) {
        _elegantSnack(
          'Guardado offline',
          'Se sincronizará automáticamente cuando vuelva la conexión',
          type: 'warning',
        );
      } else {
        final actionText = isUpdate ? 'actualizada' : 'creada';
        final title = isUpdate ? 'Orden actualizada' : 'Orden creada';
        _elegantSnack(
          title,
          'Orden ${order.orderNumber ?? '#${order.id.substring(0, 8)}'} $actionText exitosamente',
          type: 'success',
        );
      }
    });
  }

  // ==================== STEPPER NAVIGATION ====================

  void nextStep() {
    if (validateCurrentStep() && currentStep.value < 2) {
      currentStep.value++;
      _validateForm();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      _validateForm();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      currentStep.value = step;
      _validateForm();
    }
  }

  // ==================== UI HELPERS ====================

  void toggleDeliveryInfo() {
    showDeliveryInfo.value = !showDeliveryInfo.value;
  }

  void selectOrderDate() async {
    final selectedDate = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: orderDate.value,
        firstDate: Get.find<TenantDateTimeService>().now().subtract(const Duration(days: 30)),
        lastDate: Get.find<TenantDateTimeService>().now().add(const Duration(days: 365)),
      ),
    );

    if (selectedDate != null) {
      orderDate.value = selectedDate;
      orderDateController.text = _formatDate(selectedDate);
      _validateForm();
    }
  }

  void selectExpectedDeliveryDate() async {
    final selectedDate = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: expectedDeliveryDate.value,
        firstDate: orderDate.value,
        lastDate: Get.find<TenantDateTimeService>().now().add(const Duration(days: 365)),
      ),
    );

    if (selectedDate != null) {
      expectedDeliveryDate.value = selectedDate;
      expectedDeliveryDateController.text = _formatDate(selectedDate);
      _validateForm();
    }
  }

  // ==================== PROTECCIÓN CONTRA PÉRDIDA DE DATOS ====================

  /// True si el formulario tiene datos capturados que se perderían al salir
  /// o al limpiar. Se evalúa sobre campos relevantes para el usuario — se
  /// ignoran valores por defecto (fechas, prioridad media, moneda COP).
  bool get hasUnsavedChanges {
    if (selectedSupplierId.value.isNotEmpty) return true;
    // Cualquier item con producto seleccionado cuenta como dato no guardado
    if (items.any((i) => i.productId.isNotEmpty)) return true;
    final textFields = <TextEditingController>[
      notesController,
      internalNotesController,
      deliveryAddressController,
      contactPersonController,
      contactPhoneController,
      contactEmailController,
    ];
    for (final c in textFields) {
      if (c.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  /// Muestra confirmación antes de limpiar el formulario. Si no hay datos,
  /// limpia directamente (sin molestar al usuario).
  Future<void> confirmClearForm() async {
    if (!hasUnsavedChanges) {
      clearForm();
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '¿Limpiar formulario?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Se borrarán todos los datos que has capturado (proveedor, productos, notas). Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.cleaning_services_rounded, size: 16),
            label: const Text('Limpiar'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed == true) {
      clearForm();
      _elegantSnack(
        'Formulario limpio',
        'Todos los datos fueron eliminados',
        type: 'info',
      );
    }
  }

  /// Se dispara cuando el usuario intenta salir del form (back button).
  /// Retorna true si es seguro salir (no había datos o el usuario descartó).
  /// Si hay datos capturados, muestra opciones: Guardar / Descartar / Cancelar.
  Future<bool> confirmExit() async {
    if (!hasUnsavedChanges) return true;

    final canSave = isFormValid.value;
    final isEdit = isEditMode.value;

    final result = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.save_alt_rounded,
                color: Color(0xFF1D4ED8),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEdit ? '¿Descartar cambios?' : '¿Guardar antes de salir?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          canSave
              ? 'Tienes datos sin guardar. ¿Qué quieres hacer?'
              : 'Tienes datos capturados pero el formulario está incompleto, así que aún no se puede guardar. Puedes descartar los cambios o regresar a completarlos.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'cancel'),
            child: const Text('Cancelar'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => Get.back(result: 'discard'),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                label: const Text(
                  'Descartar',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
              if (canSave) ...[
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () => Get.back(result: 'save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: Text(isEdit ? 'Guardar' : 'Guardar borrador'),
                ),
              ],
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result == 'save') {
      await savePurchaseOrder();
      // savePurchaseOrder() navega por sí mismo al listado si tuvo éxito.
      // Devolvemos false para que PopScope no haga un pop adicional.
      return false;
    }
    return result == 'discard';
  }

  void clearForm() {
    formKey.currentState?.reset();

    selectedSupplierId.value = '';
    selectedSupplierName.value = '';
    supplierController.clear();

    final dtService = Get.find<TenantDateTimeService>();
    priority.value = PurchaseOrderPriority.medium;
    orderDate.value = dtService.now();
    expectedDeliveryDate.value = dtService.now().add(const Duration(days: 7));
    orderDateController.text = _formatDate(orderDate.value);
    expectedDeliveryDateController.text = _formatDate(
      expectedDeliveryDate.value,
    );

    currencyController.text = 'COP';
    notesController.clear();
    internalNotesController.clear();

    deliveryAddressController.clear();
    contactPersonController.clear();
    contactPhoneController.clear();
    contactEmailController.clear();

    items.clear();
    addEmptyItem();
    clearItemSearch();

    showDeliveryInfo.value = false;
    currentStep.value = 0;

    supplierError.value = false;
    orderDateError.value = false;
    expectedDeliveryDateError.value = false;
    itemsError.value = false;
  }

  // ==================== SNACKBARS ELEGANTES ====================
  // Unifica todos los Get.snackbar del feature con el sistema visual
  // ElegantLightTheme (gradientes + sombra elevada + iconos consistentes).
  // `type` controla el color: 'error' | 'success' | 'info' | 'warning'.

  void _elegantSnack(String title, String message, {String type = 'info'}) {
    final palette = _snackPalette(type);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: palette.bg,
      colorText: palette.fg,
      icon: Icon(palette.icon, color: palette.fg, size: 22),
      borderRadius: 14,
      margin: const EdgeInsets.all(12),
      duration: const Duration(milliseconds: 2800),
      boxShadows: ElegantLightTheme.elevatedShadow,
      animationDuration: const Duration(milliseconds: 250),
    );
  }

  _SnackPalette _snackPalette(String type) {
    switch (type) {
      case 'success':
        return _SnackPalette(
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF047857),
          icon: Icons.check_circle_rounded,
        );
      case 'error':
        return _SnackPalette(
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
          icon: Icons.error_rounded,
        );
      case 'warning':
        return _SnackPalette(
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFFB45309),
          icon: Icons.warning_rounded,
        );
      default:
        return _SnackPalette(
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1D4ED8),
          icon: Icons.info_rounded,
        );
    }
  }

  String getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Información Básica';
      case 1:
        return 'Productos y Cantidades';
      case 2:
        return 'Información Adicional';
      default:
        return 'Paso ${step + 1}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get canProceed => isStepValid.value;

  bool get isLastStep => currentStep.value == 2;

  bool get isFirstStep => currentStep.value == 0;

  String get saveButtonText => isEditMode.value ? 'Actualizar' : 'Crear';

  String get titleText =>
      isEditMode.value ? 'Editar Orden de Compra' : 'Nueva Orden de Compra';

  String get formattedTotal =>
      'Total: \$${totalAmount.value.toStringAsFixed(2)}';

  // ==================== SEARCH METHODS ====================

  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      final params = SearchSuppliersParams(searchTerm: query, limit: 10);
      final result = await searchSuppliersUseCase(params);

      return result.fold((failure) {
        print('❌ Error buscando proveedores: ${failure.message}');
        return <Supplier>[];
      }, (suppliers) => suppliers);
    } catch (e) {
      print('❌ Error inesperado buscando proveedores: $e');
      return <Supplier>[];
    }
  }

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

  void selectSupplier(Supplier supplier) {
    print('🏢 selectSupplier llamado con: ${supplier.toString()}');
    selectedSupplier.value = supplier;
    selectedSupplierId.value = supplier.id;
    selectedSupplierName.value = supplier.name;
    supplierController.text = supplier.name;
    print('🏢 Estado después de selección:');
    print('🏢   selectedSupplierId: "${selectedSupplierId.value}"');
    print('🏢   selectedSupplierName: "${selectedSupplierName.value}"');
    print('🏢   supplierController.text: "${supplierController.text}"');
    _validateForm();
  }

  void clearSupplier() {
    selectedSupplier.value = null;
    selectedSupplierId.value = '';
    selectedSupplierName.value = '';
    supplierController.clear();
    _validateForm();
  }

  void selectProductForItem(int index, Product product) {
    if (index < 0 || index >= items.length) return;

    // Normalizamos los 4 criterios de dedup (id, nombre, sku, barcode) para
    // comparar ignorando espacios y mayúsculas. Un match en cualquiera implica
    // que el producto ya está en la lista.
    final normName = product.name.trim().toLowerCase();
    final normSku = product.sku.trim().toLowerCase();
    final normBarcode = (product.barcode ?? '').trim().toLowerCase();

    int existingIndex = -1;
    String matchReason = '';
    for (var i = 0; i < items.length; i++) {
      if (i == index) continue;
      final it = items[i];
      if (it.productId.isEmpty) continue;

      if (it.productId == product.id) {
        existingIndex = i;
        matchReason = 'el mismo producto';
        break;
      }
      if (normName.isNotEmpty &&
          it.productName.trim().toLowerCase() == normName) {
        existingIndex = i;
        matchReason = 'el mismo nombre';
        break;
      }
      if (normSku.isNotEmpty &&
          it.productSku.trim().toLowerCase() == normSku) {
        existingIndex = i;
        matchReason = 'el mismo código (SKU)';
        break;
      }
      if (normBarcode.isNotEmpty &&
          it.productBarcode.trim().toLowerCase() == normBarcode) {
        existingIndex = i;
        matchReason = 'el mismo código de barras';
        break;
      }
    }

    if (existingIndex >= 0) {
      // Remover el slot vacío/activo y saltar al item duplicado para editarlo
      items.removeAt(index);
      final adjustedIndex =
          existingIndex > index ? existingIndex - 1 : existingIndex;
      activeItemIndex.value = adjustedIndex;
      calculateTotals();
      _validateForm();
      _elegantSnack(
        'Producto duplicado',
        '${product.name} ya está en la lista ($matchReason). Te llevamos al item existente para que lo edites.',
        type: 'warning',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToItem(adjustedIndex);
      });
      return;
    }

    final currentItem = items[index];
    items[index] = currentItem.copyWith(
      productId: product.id,
      productName: product.name,
      productSku: product.sku,
      productBarcode: product.barcode ?? '',
      unitPrice: 0.0,
    );
    calculateTotals();
    _validateForm();
  }
}

// Helper class for form items
class PurchaseOrderItemForm {
  final String? id; // ID para items existentes
  final String productId;
  final String productName;
  final String productSku; // Código interno — usado para dedup y búsqueda
  final String productBarcode; // Código de barras — usado para dedup y búsqueda
  final int quantity;
  final double unitPrice; // SIEMPRE en moneda base (COP). Fuente de verdad.
  final double discountPercentage;
  final double taxPercentage;
  final String notes;
  // Precio unitario en la moneda extranjera seleccionada (runtime-only,
  // no se persiste). Cuando !=null, el usuario lo ingresó en la moneda
  // de compra y unitPrice = foreignUnitPrice * exchangeRate (en base).
  final double? foreignUnitPrice;

  PurchaseOrderItemForm({
    this.id,
    this.productId = '',
    this.productName = '',
    this.productSku = '',
    this.productBarcode = '',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.notes = '',
    this.foreignUnitPrice,
  });

  bool get isValid => productId.isNotEmpty && quantity > 0 && unitPrice > 0;

  PurchaseOrderItemForm copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? productBarcode,
    int? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? taxPercentage,
    String? notes,
    double? foreignUnitPrice,
    bool clearForeignUnitPrice = false,
  }) {
    return PurchaseOrderItemForm(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productBarcode: productBarcode ?? this.productBarcode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      notes: notes ?? this.notes,
      foreignUnitPrice: clearForeignUnitPrice
          ? null
          : (foreignUnitPrice ?? this.foreignUnitPrice),
    );
  }

  factory PurchaseOrderItemForm.fromEntity(PurchaseOrderItem item) {
    return PurchaseOrderItemForm(
      id: item.id, // Incluir ID para items existentes
      productId: item.productId,
      productName: item.productName,
      productSku: item.productCode ?? '',
      productBarcode: '', // entity no persiste barcode
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountPercentage: item.discountPercentage,
      taxPercentage: item.taxPercentage,
      notes: item.notes ?? '',
    );
  }

  CreatePurchaseOrderItemParams toCreateParams({int? lineNumber}) {
    return CreatePurchaseOrderItemParams(
      productId: productId,
      productName: productName.isNotEmpty ? productName : null,
      lineNumber: lineNumber,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      taxPercentage: taxPercentage,
      notes: notes.isNotEmpty ? notes : null,
    );
  }

  UpdatePurchaseOrderItemParams toUpdateParams() {
    return UpdatePurchaseOrderItemParams(
      id: id, // Incluir ID para items existentes (null para nuevos)
      productId: productId,
      productName: productName.isNotEmpty ? productName : null,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      taxPercentage: taxPercentage,
      notes: notes.isNotEmpty ? notes : null,
    );
  }
}

/// Paleta interna para snackbars elegantes (fondo, texto e icono).
class _SnackPalette {
  final Color bg;
  final Color fg;
  final IconData icon;
  const _SnackPalette({required this.bg, required this.fg, required this.icon});
}
