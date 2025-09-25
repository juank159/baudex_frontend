// lib/features/purchase_orders/presentation/controllers/purchase_order_form_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
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

class PurchaseOrderFormController extends GetxController with GetSingleTickerProviderStateMixin {
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
  final Rx<DateTime> expectedDeliveryDate = DateTime.now().add(const Duration(days: 7)).obs;

  // Items management
  final RxList<PurchaseOrderItemForm> items = <PurchaseOrderItemForm>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble taxAmount = 0.0.obs;
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble totalAmount = 0.0.obs;

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
    try {
      // Initialize truly unique form key using timestamp to prevent GlobalKey conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = 'PurchaseOrderForm_${timestamp}_${hashCode.toString()}';
      formKey = GlobalKey<FormState>(debugLabel: uniqueId);
      print('🔑 FormKey único generado: $uniqueId');
      
      _initializeForm();
      _setupFormValidation();
      print('✅ PurchaseOrderFormController inicializado correctamente');
    } catch (e) {
      print('❌ Error en PurchaseOrderFormController onInit: $e');
      error.value = 'Error en inicialización: $e';
    }
  }

  @override
  void onClose() {
    print('🗑️ PurchaseOrderFormController: Iniciando dispose de controladores...');
    
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
      
      // Dispose all text controllers
      _disposeControllers();
      
      print('✅ PurchaseOrderFormController: Dispose completado exitosamente');
    } catch (e) {
      print('❌ Error durante dispose: $e');
    }
    
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeForm() {
    // Valores por defecto
    currencyController.text = 'COP';
    orderDateController.text = _formatDate(orderDate.value);
    expectedDeliveryDateController.text = _formatDate(expectedDeliveryDate.value);

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
    
    // Escuchar cambios en items
    ever(items, (_) => _validateForm());
  }

  void _disposeControllers() {
    try {
      // Dispose each controller only if it hasn't been disposed already
      _safeDispose(supplierController, 'supplierController');
      _safeDispose(orderDateController, 'orderDateController');
      _safeDispose(expectedDeliveryDateController, 'expectedDeliveryDateController');
      _safeDispose(currencyController, 'currencyController');
      _safeDispose(notesController, 'notesController');
      _safeDispose(internalNotesController, 'internalNotesController');
      _safeDispose(deliveryAddressController, 'deliveryAddressController');
      _safeDispose(contactPersonController, 'contactPersonController');
      _safeDispose(contactPhoneController, 'contactPhoneController');
      _safeDispose(contactEmailController, 'contactEmailController');
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
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (loadedPurchaseOrder) {
          purchaseOrder.value = loadedPurchaseOrder;
          _populateForm(loadedPurchaseOrder);
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
      print('📝 Proveedor básico creado para edición: ${order.supplierName!} (${order.supplierId!})');
    }
    
    // Poblar prioridad (puede venir del campo priority o metadata)
    priority.value = order.priority ?? PurchaseOrderPriority.medium;
    print('📝 Prioridad cargada: ${priority.value}');
    orderDate.value = order.orderDate ?? DateTime.now();
    expectedDeliveryDate.value = order.expectedDeliveryDate ?? DateTime.now();
    orderDateController.text = _formatDate(order.orderDate ?? DateTime.now());
    expectedDeliveryDateController.text = _formatDate(order.expectedDeliveryDate ?? DateTime.now());
    
    currencyController.text = order.currency ?? 'COP';
    notesController.text = order.notes ?? '';
    internalNotesController.text = order.internalNotes ?? '';
    
    deliveryAddressController.text = order.deliveryAddress ?? '';
    contactPersonController.text = order.contactPerson ?? '';
    contactPhoneController.text = order.contactPhone ?? '';
    contactEmailController.text = order.contactEmail ?? '';
    
    showDeliveryInfo.value = order.hasDeliveryInfo;
    
    // Cargar items
    items.value = order.items.map((item) => PurchaseOrderItemForm.fromEntity(item)).toList();
    print('📝 Items cargados: ${items.length}');
    
    // Calcular totales y validar formulario
    calculateTotals();
    _validateForm();
    
    // Forzar actualización de la UI
    update();
    
    print('✅ Formulario poblado exitosamente para edición:');
    print('   - Proveedor: ${selectedSupplier.value?.name ?? "No asignado"} (${selectedSupplierId.value})');
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
    
    isFormValid.value = hasSupplier && hasValidDate && hasItems;
    
    // Validar step actual
    switch (currentStep.value) {
      case 0: // Información básica
        isStepValid.value = hasSupplier && hasValidDate;
        break;
      case 1: // Items
        isStepValid.value = items.isNotEmpty && items.every((item) => item.isValid);
        break;
      case 2: // Información adicional
        isStepValid.value = true; // Información adicional es opcional
        break;
      default:
        isStepValid.value = true;
    }
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

    return isValid;
  }

  bool _validateAdditionalInfo() {
    // Validar email si está presente
    if (contactEmailController.text.isNotEmpty && !GetUtils.isEmail(contactEmailController.text)) {
      return false;
    }

    return true;
  }

  // ==================== ITEMS MANAGEMENT ====================

  void addEmptyItem() {
    items.add(PurchaseOrderItemForm());
    calculateTotals();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
      calculateTotals();
    }
  }

  void updateItemProduct(int index, String productId, String productName, double unitPrice) {
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
      print('🔢 ERROR: Index $index fuera de rango (items.length=${items.length})');
    }
  }

  void updateItemPrice(int index, double unitPrice) {
    if (index < items.length) {
      items[index] = items[index].copyWith(unitPrice: unitPrice);
      calculateTotals();
    }
  }

  void updateItemDiscount(int index, double discountPercentage) {
    if (index < items.length) {
      items[index] = items[index].copyWith(discountPercentage: discountPercentage);
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
        final itemDiscountAmount = itemSubtotal * (item.discountPercentage / 100);
        final itemSubtotalAfterDiscount = itemSubtotal - itemDiscountAmount;
        final itemTaxAmount = itemSubtotalAfterDiscount * (item.taxPercentage / 100);

        calculatedSubtotal += itemSubtotal;
        calculatedDiscountAmount += itemDiscountAmount;
        calculatedTaxAmount += itemTaxAmount;
      }
    }

    subtotal.value = calculatedSubtotal;
    discountAmount.value = calculatedDiscountAmount;
    taxAmount.value = calculatedTaxAmount;
    totalAmount.value = calculatedSubtotal - calculatedDiscountAmount + calculatedTaxAmount;
  }

  // ==================== FORM SUBMISSION ====================

  Future<void> savePurchaseOrder() async {
    print('💾 Intentando guardar orden de compra...');
    print('📋 isFormValid: ${isFormValid.value}');
    print('📋 formKey valid: ${formKey.currentState?.validate()}');
    print('📋 selectedSupplierId: ${selectedSupplierId.value}');
    print('📋 items count: ${items.length}');
    
    if (!isFormValid.value || !formKey.currentState!.validate()) {
      print('❌ Formulario no válido');
      Get.snackbar(
        'Error',
        'Por favor complete los campos requeridos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      print('🔄 Iniciando proceso de guardado...');
      isSaving.value = true;
      error.value = '';

      if (isEditMode.value) {
        print('📝 Modo edición - actualizando orden existente');
        await _updatePurchaseOrder();
      } else {
        print('🆕 Modo creación - creando nueva orden');
        await _createPurchaseOrder();
      }
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _createPurchaseOrder() async {
    print('🏗️ Construyendo parámetros para crear orden de compra...');
    
    // Debug información del proveedor
    print('🏢 DEBUG PROVEEDOR:');
    print('🏢 selectedSupplierId: "${selectedSupplierId.value}"');
    print('🏢 selectedSupplierName: "${selectedSupplierName.value}"');
    print('🏢 selectedSupplier: ${selectedSupplier.value?.toString() ?? "null"}');
    print('🏢 supplierController.text: "${supplierController.text}"');
    
    print('📋 Items totales en la lista: ${items.length}');
    
    // Debug: Mostrar todos los items antes del filtrado
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      print('📋 Item $i: productId=${item.productId}, productName=${item.productName}, quantity=${item.quantity}, unitPrice=${item.unitPrice}, isValid=${item.isValid}');
    }
    
    final validItems = items.where((item) => item.isValid).toList();
    print('📋 Items válidos después del filtrado: ${validItems.length}');
    
    // Debug: Mostrar items válidos
    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      print('📋 Valid Item $i: productId=${item.productId}, productName=${item.productName}, quantity=${item.quantity}, unitPrice=${item.unitPrice}');
    }
    
    final params = CreatePurchaseOrderParams(
      supplierId: selectedSupplierId.value,
      priority: priority.value,
      orderDate: orderDate.value,
      expectedDeliveryDate: expectedDeliveryDate.value,
      currency: currencyController.text.trim().isNotEmpty 
          ? currencyController.text.trim() 
          : 'COP',
      items: validItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        print('📋 Mapeando item $index: productId=${item.productId}, lineNumber=${index + 1}');
        return item.toCreateParams(lineNumber: index + 1);
      }).toList(),
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
      internalNotes: internalNotesController.text.trim().isNotEmpty 
          ? internalNotesController.text.trim() 
          : null,
      deliveryAddress: deliveryAddressController.text.trim().isNotEmpty 
          ? deliveryAddressController.text.trim() 
          : null,
      contactPerson: contactPersonController.text.trim().isNotEmpty 
          ? contactPersonController.text.trim() 
          : null,
      contactPhone: contactPhoneController.text.trim().isNotEmpty 
          ? contactPhoneController.text.trim() 
          : null,
      contactEmail: contactEmailController.text.trim().isNotEmpty 
          ? contactEmailController.text.trim() 
          : null,
    );

    print('📤 Enviando datos al use case...');
    print('📋 Params: supplierId=${params.supplierId}, items=${params.items.length}');
    
    // Debug: Mostrar parámetros finales
    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];
      print('📋 Final Param Item $i: productId=${item.productId}, quantity=${item.quantity}, lineNumber=${item.lineNumber}');
    }
    
    final result = await createPurchaseOrderUseCase(params);

    print('🔄 Use case completado, procesando resultado...');
    
    result.fold(
      (failure) {
        print('❌ Error del use case: ${failure.message}');
        error.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      },
(createdPurchaseOrder) {
        print('✅ Orden de compra creada exitosamente: ${createdPurchaseOrder.id}');
        Get.snackbar(
          'Éxito',
          'Orden de compra creada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Navegar y actualizar la lista de órdenes de compra
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
      currency: currencyController.text.trim().isNotEmpty 
          ? currencyController.text.trim() 
          : 'COP',
      items: items.where((item) => item.isValid).map((item) => item.toUpdateParams()).toList(),
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
      internalNotes: internalNotesController.text.trim().isNotEmpty 
          ? internalNotesController.text.trim() 
          : null,
      deliveryAddress: deliveryAddressController.text.trim().isNotEmpty 
          ? deliveryAddressController.text.trim() 
          : null,
      contactPerson: contactPersonController.text.trim().isNotEmpty 
          ? contactPersonController.text.trim() 
          : null,
      contactPhone: contactPhoneController.text.trim().isNotEmpty 
          ? contactPhoneController.text.trim() 
          : null,
      contactEmail: contactEmailController.text.trim().isNotEmpty 
          ? contactEmailController.text.trim() 
          : null,
    );

    final result = await updatePurchaseOrderUseCase(params);

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
      (updatedPurchaseOrder) {
        Get.snackbar(
          'Éxito',
          'Orden de compra actualizada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Navegar y actualizar la lista de órdenes de compra
        _navigateToListAndRefresh(updatedPurchaseOrder);
      },
    );
  }

  /// Navega a la lista de órdenes de compra y la actualiza para mostrar la nueva orden
  Future<void> _navigateToListAndRefresh(PurchaseOrder createdOrder) async {
    try {
      print('🔄 Navegando a lista y actualizando con nueva orden: ${createdOrder.id}');
      
      // Navegar a la lista con parámetro para indicar que hay una nueva orden
      Get.offAllNamed('/purchase-orders', parameters: {
        'newOrderId': createdOrder.id,
        'action': isEditMode.value ? 'updated' : 'created'
      });
      
      // Esperar un momento para que la navegación complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Buscar el controlador de la lista y actualizarla
      if (Get.isRegistered<PurchaseOrdersController>()) {
        final listController = Get.find<PurchaseOrdersController>();
        print('✅ Controlador de lista encontrado, actualizando...');
        
        // Usar el método especializado para actualización después de cambios
        await listController.refreshAfterOrderChange(
          createdOrder.id, 
          isUpdate: isEditMode.value
        );
        
        // Mostrar notificación de éxito personalizada
        _showSuccessNotification(createdOrder);
      } else {
        print('⚠️ Controlador de lista no encontrado, la lista se actualizará al cargar');
        // Como backup, mostrar notificación y la lista se cargará automáticamente
        _showSuccessNotification(createdOrder);
      }
    } catch (e) {
      print('❌ Error al actualizar lista después de crear orden: $e');
      // Si hay error, al menos mostramos que la orden se procesó exitosamente
      Get.snackbar(
        isEditMode.value ? 'Orden Actualizada' : 'Orden Creada',
        'La acción se completó correctamente. Desliza para actualizar la lista si es necesario.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.shade50,
        colorText: Colors.blue.shade800,
        icon: Icon(isEditMode.value ? Icons.edit_note : Icons.add_task, color: Colors.blue),
        duration: const Duration(seconds: 4),
      );
    }
  }
  
  /// Muestra una notificación de éxito personalizada
  void _showSuccessNotification(PurchaseOrder order) {
    final isUpdate = isEditMode.value;
    final actionText = isUpdate ? 'actualizada' : 'creada';
    final icon = isUpdate ? Icons.edit_note : Icons.add_task;
    final title = isUpdate ? '📝 Orden Actualizada' : '🎉 ¡Nueva Orden Creada!';
    
    Future.delayed(const Duration(milliseconds: 700), () {
      Get.snackbar(
        title,
        'Orden ${order.orderNumber ?? '#${order.id.substring(0, 8)}'} $actionText exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade800,
        borderColor: Colors.green.shade300,
        borderWidth: 1.5,
        icon: Icon(icon, color: Colors.green.shade600, size: 24),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        isDismissible: true,
        animationDuration: const Duration(milliseconds: 500),
      );
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
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
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
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );

    if (selectedDate != null) {
      expectedDeliveryDate.value = selectedDate;
      expectedDeliveryDateController.text = _formatDate(selectedDate);
      _validateForm();
    }
  }

  void clearForm() {
    formKey.currentState?.reset();
    
    selectedSupplierId.value = '';
    selectedSupplierName.value = '';
    supplierController.clear();
    
    priority.value = PurchaseOrderPriority.medium;
    orderDate.value = DateTime.now();
    expectedDeliveryDate.value = DateTime.now().add(const Duration(days: 7));
    orderDateController.text = _formatDate(orderDate.value);
    expectedDeliveryDateController.text = _formatDate(expectedDeliveryDate.value);
    
    currencyController.text = 'COP';
    notesController.clear();
    internalNotesController.clear();
    
    deliveryAddressController.clear();
    contactPersonController.clear();
    contactPhoneController.clear();
    contactEmailController.clear();
    
    items.clear();
    addEmptyItem();
    
    showDeliveryInfo.value = false;
    currentStep.value = 0;
    
    supplierError.value = false;
    orderDateError.value = false;
    expectedDeliveryDateError.value = false;
    itemsError.value = false;
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
  
  String get titleText => isEditMode.value ? 'Editar Orden de Compra' : 'Nueva Orden de Compra';

  String get formattedTotal => 'Total: \$${totalAmount.value.toStringAsFixed(2)}';

  // ==================== SEARCH METHODS ====================

  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      final params = SearchSuppliersParams(searchTerm: query, limit: 10);
      final result = await searchSuppliersUseCase(params);
      
      return result.fold(
        (failure) {
          print('❌ Error buscando proveedores: ${failure.message}');
          return <Supplier>[];
        },
        (suppliers) => suppliers,
      );
    } catch (e) {
      print('❌ Error inesperado buscando proveedores: $e');
      return <Supplier>[];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final params = SearchProductsParams(searchTerm: query, limit: 10);
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
    if (index >= 0 && index < items.length) {
      final currentItem = items[index];
      final updatedItem = currentItem.copyWith(
        productId: product.id,
        productName: product.name,
        // ✅ NO usar precio de venta - iniciar en 0 para que el usuario ingrese el precio de compra
        unitPrice: 0.0,
      );
      items[index] = updatedItem;
      calculateTotals();
      _validateForm();
    }
  }
}

// Helper class for form items
class PurchaseOrderItemForm {
  final String? id; // ID para items existentes
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountPercentage;
  final double taxPercentage;
  final String notes;

  PurchaseOrderItemForm({
    this.id,
    this.productId = '',
    this.productName = '',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.notes = '',
  });

  bool get isValid => productId.isNotEmpty && quantity > 0 && unitPrice > 0;

  PurchaseOrderItemForm copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? taxPercentage,
    String? notes,
  }) {
    return PurchaseOrderItemForm(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      notes: notes ?? this.notes,
    );
  }

  factory PurchaseOrderItemForm.fromEntity(PurchaseOrderItem item) {
    return PurchaseOrderItemForm(
      id: item.id, // Incluir ID para items existentes
      productId: item.productId,
      productName: item.productName,
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
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      taxPercentage: taxPercentage,
      notes: notes.isNotEmpty ? notes : null,
    );
  }
}