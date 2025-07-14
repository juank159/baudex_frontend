// lib/features/invoices/presentation/controllers/invoice_form_controller.dart
import 'dart:async';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';

import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Domain entities
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/update_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';

// Customer and Product entities
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../customers/domain/usecases/search_customers_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

// Bindings
import '../../../customers/presentation/bindings/customer_binding.dart';
import '../../../products/presentation/bindings/product_binding.dart';

// Presentation models
import 'package:baudex_desktop/features/invoices/data/models/invoice_form_models.dart';

// ✅ NUEVO IMPORT: Controlador de impresión térmica

class InvoiceFormController extends GetxController {
  // ==================== DEPENDENCIES ====================

  final CreateInvoiceUseCase _createInvoiceUseCase;
  final UpdateInvoiceUseCase _updateInvoiceUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;
  GetCustomersUseCase? _getCustomersUseCase;
  SearchCustomersUseCase? _searchCustomersUseCase;
  GetProductsUseCase? _getProductsUseCase;
  SearchProductsUseCase? _searchProductsUseCase;
  GetCustomerByIdUseCase? _getCustomerByIdUseCase;

  // ✅ NUEVO: Controlador de impresión térmica
  late final ThermalPrinterController _thermalPrinterController;

  InvoiceFormController({
    required CreateInvoiceUseCase createInvoiceUseCase,
    required UpdateInvoiceUseCase updateInvoiceUseCase,
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
    GetCustomersUseCase? getCustomersUseCase,
    SearchCustomersUseCase? searchCustomersUseCase,
    GetProductsUseCase? getProductsUseCase,
    SearchProductsUseCase? searchProductsUseCase,
    GetCustomerByIdUseCase? getCustomerByIdUseCase,
  }) : _createInvoiceUseCase = createInvoiceUseCase,
       _updateInvoiceUseCase = updateInvoiceUseCase,
       _getInvoiceByIdUseCase = getInvoiceByIdUseCase,
       _getCustomersUseCase = getCustomersUseCase,
       _searchCustomersUseCase = searchCustomersUseCase,
       _getProductsUseCase = getProductsUseCase,
       _searchProductsUseCase = searchProductsUseCase,
       _getCustomerByIdUseCase = getCustomerByIdUseCase {
    print('🎮 InvoiceFormController: Instancia creada correctamente');

    // ✅ INICIALIZAR CONTROLADOR DE IMPRESIÓN (REUTILIZAR SI YA EXISTE)
    try {
      _thermalPrinterController = Get.find<ThermalPrinterController>();
      print('♻️ Reutilizando ThermalPrinterController existente');
    } catch (e) {
      _thermalPrinterController = Get.put(ThermalPrinterController());
      print('🆕 Creando nuevo ThermalPrinterController');
    }
  }

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isLoadingCustomers = false.obs;
  final _isLoadingProducts = false.obs;

  // ✅ NUEVO: Estado de impresión
  final _isPrinting = false.obs;

  // Modo de edición
  final _isEditMode = false.obs;
  final _editingInvoiceId = Rxn<String>();

  // Datos del formulario
  final _selectedCustomer = Rxn<Customer>();
  final _invoiceItems = <InvoiceItemFormData>[].obs;
  final _invoiceDate = DateTime.now().obs;
  final _dueDate = DateTime.now().add(const Duration(days: 30)).obs;
  final _paymentMethod = PaymentMethod.cash.obs;
  final _taxPercentage = 19.0.obs;
  final _discountPercentage = 0.0.obs;
  final _discountAmount = 0.0.obs;

  // Datos disponibles
  final _availableCustomers = <Customer>[].obs;
  final _availableProducts = <Product>[].obs;

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final notesController = TextEditingController();
  final termsController = TextEditingController();

  // ==================== GETTERS ====================

  // Estados de carga
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isLoadingCustomers => _isLoadingCustomers.value;
  bool get isLoadingProducts => _isLoadingProducts.value;

  // Formato de número para precios
  final format = NumberFormat('#,###', 'es_CO');

  // ✅ NUEVO: Getter para estado de impresión
  bool get isPrinting => _isPrinting.value;

  // Modo de edición
  bool get isEditMode => _isEditMode.value;
  String? get editingInvoiceId => _editingInvoiceId.value;

  // Datos del formulario
  static const String DEFAULT_CUSTOMER_ID =
      '3c605381-362b-454a-8c0f-b3c055aa568d';
  Customer? get selectedCustomer => _selectedCustomer.value;
  List<InvoiceItemFormData> get invoiceItems => _invoiceItems;
  DateTime get invoiceDate => _invoiceDate.value;
  DateTime get dueDate => _dueDate.value;
  PaymentMethod get paymentMethod => _paymentMethod.value;
  double get taxPercentage => _taxPercentage.value;
  double get discountPercentage => _discountPercentage.value;
  double get discountAmount => _discountAmount.value;

  // Datos disponibles
  List<Customer> get availableCustomers => _availableCustomers;
  List<Product> get availableProducts => _availableProducts;

  // Validación del formulario
  bool get canSave =>
      invoiceItems.isNotEmpty &&
      invoiceItems.every((item) => item.isValid) &&
      selectedCustomer != null;

  // Cálculos
  double get subtotalWithoutTax {
    return _invoiceItems.fold(0.0, (sum, item) {
      final priceWithoutTax = item.unitPrice / (1 + (taxPercentage / 100));
      final itemSubtotal = item.quantity * priceWithoutTax;
      final percentageDiscount = (itemSubtotal * item.discountPercentage) / 100;
      final totalDiscount = percentageDiscount + item.discountAmount;
      return sum + (itemSubtotal - totalDiscount);
    });
  }

  double get subtotal {
    return subtotalWithoutTax + taxAmount;
  }

  double get totalDiscountAmount {
    final subtotalWithoutTax = this.subtotalWithoutTax;
    final percentageDiscount = (subtotalWithoutTax * discountPercentage) / 100;
    return percentageDiscount + discountAmount;
  }

  double get taxableAmount {
    return subtotalWithoutTax - totalDiscountAmount;
  }

  double get taxAmount {
    return taxableAmount * (taxPercentage / 100);
  }

  double get total {
    return taxableAmount + taxAmount;
  }

  // UI helpers
  String get pageTitle => isEditMode ? 'Editar Factura' : 'Punto de Venta';
  String get saveButtonText => isEditMode ? 'Actualizar' : 'Procesar Venta';

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    final instanceId = hashCode;
    print(
      '🚀 InvoiceFormController: Inicializando punto de venta... (Instance: $instanceId)',
    );
    print('📊 DEBUG: Estado inicial:');
    print('   - availableProducts: ${_availableProducts.length} items');
    print('   - invoiceItems: ${_invoiceItems.length} items');
    _initializeForm();
    // ✅ SOLO INICIALIZAR LO MÍNIMO EN onInit PARA EVITAR ANR
    _initializeMinimal();
  }

  // ✅ NUEVA FUNCIÓN: Auto-inicializar dependencias faltantes
  void _autoInitializeDependencies() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('🔄 [AUTO-INIT] Verificando dependencias faltantes...');

        // Solo inicializar si son null (fueron creadas sin dependencias)
        if (_getCustomersUseCase == null &&
            !Get.isRegistered<GetCustomersUseCase>()) {
          print('👥 [AUTO-INIT] Inicializando CustomerBinding...');
          CustomerBinding().dependencies();

          // Actualizar las referencias
          final getCustomersUseCase =
              Get.isRegistered<GetCustomersUseCase>()
                  ? Get.find<GetCustomersUseCase>()
                  : null;
          final searchCustomersUseCase =
              Get.isRegistered<SearchCustomersUseCase>()
                  ? Get.find<SearchCustomersUseCase>()
                  : null;
          final getCustomerByIdUseCase =
              Get.isRegistered<GetCustomerByIdUseCase>()
                  ? Get.find<GetCustomerByIdUseCase>()
                  : null;

          // Re-asignar las dependencias
          _getCustomersUseCase = getCustomersUseCase;
          _searchCustomersUseCase = searchCustomersUseCase;
          _getCustomerByIdUseCase = getCustomerByIdUseCase;

          print('✅ [AUTO-INIT] CustomerBinding inicializado');
        }

        await Future.delayed(const Duration(milliseconds: 50));

        if (_getProductsUseCase == null &&
            !Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [AUTO-INIT] Inicializando ProductBinding...');
          ProductBinding().dependencies();

          // Actualizar las referencias
          final getProductsUseCase =
              Get.isRegistered<GetProductsUseCase>()
                  ? Get.find<GetProductsUseCase>()
                  : null;
          final searchProductsUseCase =
              Get.isRegistered<SearchProductsUseCase>()
                  ? Get.find<SearchProductsUseCase>()
                  : null;

          // Re-asignar las dependencias
          _getProductsUseCase = getProductsUseCase;
          _searchProductsUseCase = searchProductsUseCase;

          print('✅ [AUTO-INIT] ProductBinding inicializado');
        }

        print('🎉 [AUTO-INIT] Auto-inicialización completada');
      } catch (e) {
        print('❌ [AUTO-INIT] Error en auto-inicialización: $e');
      }
    });
  }

  @override
  void onClose() {
    print('🔚 InvoiceFormController: Liberando recursos...');
    _disposeControllers();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  // ✅ NUEVA FUNCIÓN: Inicialización mínima para evitar ANR
  void _initializeMinimal() {
    // Cargar cliente por defecto de forma asíncrona pero inmediata
    _loadDefaultCustomer();

    // Programar carga completa después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataAfterFirstFrame();
    });
  }

  void _initializeForm() {
    _invoiceDate.value = DateTime.now();
    _dueDate.value = DateTime.now();
    termsController.text = 'Venta de contado';

    final invoiceId = Get.parameters['id'];
    if (invoiceId != null && invoiceId.isNotEmpty) {
      _isEditMode.value = true;
      _editingInvoiceId.value = invoiceId;
      // Cargar factura después para no bloquear
      _loadInvoiceForEditAsync(invoiceId);
    }
  }

  // ✅ NUEVA FUNCIÓN: Cargar datos después del primer frame
  void _loadDataAfterFirstFrame() async {
    try {
      print('📅 Cargando datos después del primer frame...');

      // Esperar un poco más para asegurar que la UI esté lista
      await Future.delayed(const Duration(milliseconds: 500));

      // Auto-inicializar dependencias si es necesario
      _autoInitializeDependencies();

      // Esperar otro poco
      await Future.delayed(const Duration(milliseconds: 200));

      // Cliente ya está cargándose en _initializeMinimal

      // Cargar otros datos de forma escalonada
      _loadInitialDataStaggered();
    } catch (e) {
      print('❌ Error en carga después del primer frame: $e');
    }
  }

  // ✅ OPTIMIZACIÓN: NO cargar todos los datos inicialmente
  void _loadInitialDataStaggered() async {
    try {
      print('⚡ Inicialización optimizada - No cargando todos los datos');
      print('💡 Los clientes se cargarán cuando se busquen');
      print('💡 Los productos se cargarán cuando se busquen');

      // Solo asegurar que las listas estén limpias
      _availableCustomers.clear();
      _availableProducts.clear();

      // Los datos se cargarán bajo demanda:
      // - Clientes: cuando el usuario use CustomerSelectorWidget
      // - Productos: cuando el usuario use ProductSearchWidget
    } catch (e) {
      print('❌ Error en inicialización optimizada: $e');
    }
  }

  void debugPriceCalculations() {
    print('🧮 DEBUG Cálculos de Precios:');
    print('   - Subtotal con IVA: \${subtotal.toStringAsFixed(2)}');
    print('   - Subtotal sin IVA: \${subtotalWithoutTax.toStringAsFixed(2)}');
    print('   - Descuentos: \${totalDiscountAmount.toStringAsFixed(2)}');
    print('   - Monto gravable: \${taxableAmount.toStringAsFixed(2)}');
    print('   - IVA (${taxPercentage}%): \${taxAmount.toStringAsFixed(2)}');
    print('   - TOTAL: \${total.toStringAsFixed(2)}');
  }

  Future<void> _loadDefaultCustomer() async {
    try {
      print('🔍 Cargando cliente final desde BD: $DEFAULT_CUSTOMER_ID');

      // ✅ ESTABLECER CLIENTE FALLBACK INMEDIATAMENTE
      _setFallbackDefaultCustomer();

      if (_getCustomerByIdUseCase != null) {
        print('✅ GetCustomerByIdUseCase disponible, realizando consulta...');

        // ✅ CARGAR CLIENTE REAL EN BACKGROUND SIN BLOQUEAR
        _getCustomerByIdUseCase!(GetCustomerByIdParams(id: DEFAULT_CUSTOMER_ID))
            .timeout(const Duration(seconds: 5))
            .then((result) {
              result.fold(
                (failure) {
                  print(
                    '❌ Error cargando cliente final: ${failure.toString()}',
                  );
                  // Mantener cliente fallback
                },
                (customer) {
                  _selectedCustomer.value = customer;
                  print('✅ Cliente final cargado exitosamente:');
                  print('   - ID: ${customer.id}');
                  print('   - Nombre: ${customer.displayName}');
                  print('   - Email: ${customer.email}');
                },
              );
            })
            .catchError((e) {
              print('💥 Error inesperado cargando cliente final: $e');
              // Mantener cliente fallback
            });
      } else {
        print('❌ GetCustomerByIdUseCase NO disponible');
        print('🔄 Usando cliente fallback...');
      }
    } catch (e) {
      print('💥 Error inesperado cargando cliente final: $e');
      print('🔄 Usando cliente fallback...');
      _setFallbackDefaultCustomer();
    }
  }

  // ✅ NUEVA FUNCIÓN: Cargar cliente asíncronamente
  void _loadDefaultCustomerAsync() {
    try {
      print('🔍 Cargando cliente final desde BD: $DEFAULT_CUSTOMER_ID');

      if (_getCustomerByIdUseCase != null) {
        print('✅ GetCustomerByIdUseCase disponible, realizando consulta...');

        _getCustomerByIdUseCase!(GetCustomerByIdParams(id: DEFAULT_CUSTOMER_ID))
            .timeout(const Duration(seconds: 5))
            .then((result) {
              result.fold(
                (failure) {
                  print(
                    '❌ Error cargando cliente final: ${failure.toString()}',
                  );
                  // Mantener cliente fallback
                },
                (customer) {
                  _selectedCustomer.value = customer;
                  print('✅ Cliente final cargado exitosamente:');
                  print('   - ID: ${customer.id}');
                  print('   - Nombre: ${customer.displayName}');
                  print('   - Email: ${customer.email}');
                },
              );
            })
            .catchError((e) {
              print('💥 Error inesperado cargando cliente final: $e');
              // Mantener cliente fallback
            });
      } else {
        print('❌ GetCustomerByIdUseCase NO disponible');
        print('🔄 Usando cliente fallback...');
      }
    } catch (e) {
      print('💥 Error inesperado cargando cliente final: $e');
    }
  }

  // ✅ NUEVA FUNCIÓN: Cargar factura para edición asíncronamente
  void _loadInvoiceForEditAsync(String invoiceId) {
    // Programar carga después de que la UI esté lista
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      _loadInvoiceForEdit(invoiceId);
    });
  }

  void _setFallbackDefaultCustomer() {
    final fallbackCustomer = Customer(
      id: DEFAULT_CUSTOMER_ID,
      firstName: 'Consumidor',
      lastName: 'Final',
      email: 'ventas@empresa.com',
      documentType: DocumentType.cc,
      documentNumber: '222222222222',
      address: 'Venta mostrador',
      city: 'Cúcuta',
      state: 'Norte de Santander',
      country: 'Colombia',
      status: CustomerStatus.active,
      creditLimit: 0,
      currentBalance: 0,
      paymentTerms: 0,
      totalPurchases: 0,
      totalOrders: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _selectedCustomer.value = fallbackCustomer;
    print(
      '👤 Cliente fallback establecido con ID real: ${fallbackCustomer.id}',
    );
    print('   - Nombre: ${fallbackCustomer.displayName}');
  }

  // ✅ FUNCIÓN OBSOLETA - YA NO SE USA
  // Se reemplazó por _loadInitialDataStaggered para evitar ANR

  // ==================== INVOICE LOADING (EDIT MODE) ====================

  Future<void> _loadInvoiceForEdit(String invoiceId) async {
    try {
      _isLoading.value = true;
      print('📄 Cargando factura para editar: $invoiceId');

      final result = await _getInvoiceByIdUseCase(
        GetInvoiceByIdParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar factura: ${failure.message}');
          _showError('Error al cargar factura', failure.message);
          Get.back();
        },
        (invoice) {
          _populateFormFromInvoice(invoice);
          print('✅ Factura cargada para edición');
        },
      );
    } catch (e) {
      print('💥 Error inesperado al cargar factura: $e');
      _showError('Error inesperado', 'No se pudo cargar la factura');
      Get.back();
    } finally {
      _isLoading.value = false;
    }
  }

  void _populateFormFromInvoice(Invoice invoice) {
    _invoiceDate.value = invoice.date;
    _dueDate.value = invoice.dueDate;
    _paymentMethod.value = invoice.paymentMethod;
    _taxPercentage.value = invoice.taxPercentage;
    _discountPercentage.value = invoice.discountPercentage;
    _discountAmount.value = invoice.discountAmount;
    notesController.text = invoice.notes ?? '';
    termsController.text = invoice.terms ?? '';
    _selectedCustomer.value = invoice.customer;
    _invoiceItems.value =
        invoice.items
            .map((item) => InvoiceItemFormData.fromEntity(item))
            .toList();
  }

  // // ✅ MÉTODO CORREGIDO EN invoice_form_controller.dart
  // void addOrUpdateProductToInvoice(Product product, {double quantity = 1}) {
  //   print('🛒 Procesando producto: ${product.name} (cantidad: $quantity)');

  //   // ✅ DETECCIÓN DE PRODUCTO TEMPORAL
  //   final isTemporary =
  //       product.id.startsWith('temp_') ||
  //       product.id.startsWith('unregistered_') ||
  //       (product.metadata?['isTemporary'] == true);

  //   if (isTemporary) {
  //     print('🎭 Producto TEMPORAL detectado: ${product.name}');
  //   } else {
  //     print('📦 Producto REGISTRADO: ${product.name}');

  //     // Solo validar stock para productos registrados
  //     if (product.stock <= 0) {
  //       _showError('Sin Stock', '${product.name} no tiene stock disponible');
  //       return;
  //     }
  //   }

  //   _ensureProductIsAvailable(product);

  //   final defaultPrice = product.getPriceByType(PriceType.price1);
  //   final unitPrice = defaultPrice?.finalAmount ?? product.sellingPrice ?? 0;

  //   if (unitPrice <= 0) {
  //     _showError('Sin Precio', '${product.name} no tiene precio configurado');
  //     return;
  //   }

  //   final existingIndex = _invoiceItems.indexWhere(
  //     (item) => item.productId == product.id,
  //   );

  //   if (existingIndex != -1) {
  //     final existingItem = _invoiceItems[existingIndex];
  //     final newQuantity = existingItem.quantity + quantity;

  //     // Solo validar stock para productos registrados
  //     if (!isTemporary && newQuantity > product.stock) {
  //       _showError(
  //         'Stock Insuficiente',
  //         'Solo hay ${product.stock} unidades disponibles de ${product.name}',
  //       );
  //       return;
  //     }

  //     final updatedItem = existingItem.copyWith(quantity: newQuantity);
  //     _invoiceItems[existingIndex] = updatedItem;

  //     print(
  //       '✅ Cantidad actualizada: ${existingItem.description} -> $newQuantity',
  //     );
  //     _showProductUpdatedMessage(product.name, newQuantity);
  //   } else {
  //     // Solo validar stock para productos registrados
  //     if (!isTemporary && quantity > product.stock) {
  //       _showError(
  //         'Stock Insuficiente',
  //         'Solo hay ${product.stock} unidades disponibles de ${product.name}',
  //       );
  //       return;
  //     }

  //     final newItem = InvoiceItemFormData(
  //       id: DateTime.now().millisecondsSinceEpoch.toString(),
  //       description: product.name,
  //       quantity: quantity,
  //       unitPrice: unitPrice,
  //       unit: product.unit ?? 'pcs',
  //       productId:
  //           product
  //               .id, // ✅ El ID temporal se maneja en el CreateInvoiceItemRequestModel
  //     );

  //     _invoiceItems.add(newItem);

  //     if (isTemporary) {
  //       print(
  //         '➕ Producto TEMPORAL agregado: ${product.name} - Precio: \$${unitPrice.toStringAsFixed(2)}',
  //       );
  //     } else {
  //       print(
  //         '➕ Producto REGISTRADO agregado: ${product.name} - Precio: \$${unitPrice.toStringAsFixed(2)}',
  //       );
  //     }

  //     _showProductAddedMessage(product.name);
  //   }

  //   _recalculateTotals();
  // }

  void addOrUpdateProductToInvoice(Product product, {double quantity = 1}) {
    final instanceId = hashCode;
    print(
      '🛒 Procesando producto: ${product.name} (cantidad: $quantity) (Instance: $instanceId)',
    );
    print('📊 Estado actual antes de agregar:');
    print('   - Items en factura: ${_invoiceItems.length}');
    print('   - Productos disponibles: ${_availableProducts.length}');

    // ✅ DETECCIÓN DE PRODUCTO TEMPORAL
    final isTemporary =
        product.id.startsWith('temp_') ||
        product.id.startsWith('unregistered_') ||
        (product.metadata?['isTemporary'] == true);

    if (isTemporary) {
      print('🎭 Producto TEMPORAL detectado: ${product.name}');
    } else {
      print('📦 Producto REGISTRADO: ${product.name}');

      // Solo validar stock para productos registrados
      if (product.stock <= 0) {
        _showError('Sin Stock', '${product.name} no tiene stock disponible');
        return;
      }
    }

    _ensureProductIsAvailable(product);

    final defaultPrice = product.getPriceByType(PriceType.price1);
    final unitPrice = defaultPrice?.finalAmount ?? product.sellingPrice ?? 0;

    if (unitPrice <= 0) {
      _showError('Sin Precio', '${product.name} no tiene precio configurado');
      return;
    }

    final existingIndex = _invoiceItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // ✅ MODIFICACIÓN: Actualizar producto existente SIN moverlo de posición
      final existingItem = _invoiceItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Solo validar stock para productos registrados
      if (!isTemporary && newQuantity > product.stock) {
        _showError(
          'Stock Insuficiente',
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        return;
      }

      final updatedItem = existingItem.copyWith(quantity: newQuantity);

      // ✅ NUEVO: Actualizar en la misma posición, NO mover al inicio
      _invoiceItems[existingIndex] = updatedItem;

      print(
        '✅ Cantidad actualizada (mantiene posición): ${existingItem.description} -> $newQuantity (índice: $existingIndex)',
      );
      _showProductUpdatedMessage(product.name, newQuantity);
    } else {
      // Solo validar stock para productos registrados
      if (!isTemporary && quantity > product.stock) {
        _showError(
          'Stock Insuficiente',
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        return;
      }

      final newItem = InvoiceItemFormData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: product.name,
        quantity: quantity,
        unitPrice: unitPrice,
        unit: product.unit ?? 'pcs',
        productId: product.id,
      );

      // ✅ MODIFICACIÓN: Agregar al inicio de la lista
      _invoiceItems.insert(0, newItem);

      if (isTemporary) {
        print(
          '➕ Producto TEMPORAL agregado al inicio: ${product.name} - Precio: \$${unitPrice.toStringAsFixed(2)}',
        );
      } else {
        print(
          '➕ Producto REGISTRADO agregado al inicio: ${product.name} - Precio: \$${unitPrice.toStringAsFixed(2)}',
        );
      }
    }

    _recalculateTotals();
  }

  void _ensureProductIsAvailable(Product product) {
    final instanceId = hashCode;
    final existingIndex = _availableProducts.indexWhere(
      (p) => p.id == product.id,
    );

    if (existingIndex == -1) {
      _availableProducts.add(product);
      print(
        '📦 Producto agregado a lista disponible: ${product.name} (Instance: $instanceId)',
      );
      print(
        '📊 Total productos en esta instancia: ${_availableProducts.length}',
      );
    } else {
      _availableProducts[existingIndex] = product;
      print(
        '📦 Producto actualizado en lista disponible: ${product.name} (Instance: $instanceId)',
      );
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    print('🔍 Iniciando búsqueda de productos: "$query"');

    if (query.trim().isEmpty) return [];

    // ✅ VERIFICAR ESTADO DE CARGA
    if (_isLoadingProducts.value) {
      print('⚠️ Productos aún cargando, usando búsqueda local limitada');
      return _searchInLocalProducts(query).take(5).toList();
    }

    try {
      List<Product> results = [];

      final barcodeMatch = await _searchByBarcode(query);
      if (barcodeMatch != null) {
        results.add(barcodeMatch);
        print('✅ Encontrado por código de barras: ${barcodeMatch.name}');
      }

      final skuMatch = await _searchBySku(query);
      if (skuMatch != null && !results.any((p) => p.id == skuMatch.id)) {
        results.add(skuMatch);
        print('✅ Encontrado por SKU: ${skuMatch.name}');
      }

      if (results.isEmpty) {
        if (_searchProductsUseCase != null && !_isLoadingProducts.value) {
          // ✅ TIMEOUT PARA EVITAR BLOQUEOS
          final searchResult = await _searchProductsUseCase!(
                SearchProductsParams(searchTerm: query, limit: 20),
              )
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  print('⚠️ Búsqueda por API timeout, usando local');
                  return Left(ServerFailure('Timeout en búsqueda'));
                },
              );

          searchResult.fold(
            (failure) {
              print('❌ Error en búsqueda de productos: ${failure.message}');
              results.addAll(_searchInLocalProducts(query));
            },
            (products) {
              results.addAll(products);
              print(
                '✅ Búsqueda por API completada: ${products.length} productos',
              );
            },
          );
        } else {
          print('⚠️ SearchProductsUseCase no disponible o cargando');
          results.addAll(_searchInLocalProducts(query));
        }
      }

      final uniqueResults = <String, Product>{};
      for (final product in results) {
        if (product.status == ProductStatus.active && product.stock > 0) {
          uniqueResults[product.id] = product;
        }
      }

      final finalResults = uniqueResults.values.take(10).toList();
      print(
        '✅ Búsqueda completada: ${finalResults.length} productos encontrados',
      );

      return finalResults;
    } catch (e) {
      print('💥 Error inesperado en búsqueda de productos: $e');
      return _searchInLocalProducts(query).take(5).toList();
    }
  }

  Future<Product?> _searchByBarcode(String barcode) async {
    try {
      final products = _availableProducts;
      return products.firstWhereOrNull(
        (product) =>
            product.barcode?.toLowerCase() == barcode.toLowerCase() &&
            product.status == ProductStatus.active,
      );
    } catch (e) {
      print('❌ Error en búsqueda por código de barras: $e');
      return null;
    }
  }

  Future<Product?> _searchBySku(String sku) async {
    try {
      final products = _availableProducts;
      return products.firstWhereOrNull(
        (product) =>
            product.sku.toLowerCase() == sku.toLowerCase() &&
            product.status == ProductStatus.active,
      );
    } catch (e) {
      print('❌ Error en búsqueda por SKU: $e');
      return null;
    }
  }

  List<Product> _searchInLocalProducts(String query) {
    final searchTerm = query.toLowerCase();

    return _availableProducts.where((product) {
      return product.status == ProductStatus.active &&
          (product.name.toLowerCase().contains(searchTerm) ||
              product.sku.toLowerCase().contains(searchTerm) ||
              (product.description?.toLowerCase().contains(searchTerm) ??
                  false) ||
              (product.barcode?.toLowerCase().contains(searchTerm) ?? false));
    }).toList();
  }

  Future<void> _loadProducts() async {
    if (_getProductsUseCase == null) {
      print('⚠️ GetProductsUseCase no disponible - no se cargarán productos');
      _availableProducts.clear();
      _isLoadingProducts.value = false;
      return;
    }

    try {
      _isLoadingProducts.value = true;
      print('📦 Cargando productos desde la base de datos...');

      // ✅ USAR YIELD PARA NO BLOQUEAR EL HILO PRINCIPAL
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await _getProductsUseCase!(
            const GetProductsParams(
              page: 1,
              limit: 50, // ✅ REDUCIR LÍMITE INICIAL
              status: ProductStatus.active,
              includePrices: true,
            ),
          )
          .timeout(
            const Duration(seconds: 8), // ✅ TIMEOUT MÁS CORTO
            onTimeout: () {
              print('⚠️ Timeout cargando productos');
              return Left(ServerFailure('Timeout al cargar productos'));
            },
          );

      // ✅ YIELD ENTRE OPERACIONES
      await Future.delayed(const Duration(milliseconds: 10));

      result.fold(
        (failure) {
          print('❌ Error al cargar productos: ${failure.message}');
          _availableProducts.clear();
        },
        (paginatedResult) {
          _availableProducts.value = paginatedResult.data;
          print('✅ Productos cargados: ${paginatedResult.data.length}');

          // ✅ CARGAR MÁS PRODUCTOS EN BACKGROUND MUY DESPACIO
          if (paginatedResult.data.length == 50 &&
              paginatedResult.meta.hasNextPage) {
            _loadMoreProductsSlowly(2);
          }
        },
      );
    } catch (e) {
      print('💥 Error al cargar productos: $e');
      _availableProducts.clear();
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: Carga asíncrona de más productos MUY LENTAMENTE
  void _loadMoreProductsSlowly(int page) {
    // Esperar mucho tiempo antes de cargar más productos
    Timer(const Duration(seconds: 3), () {
      _loadMoreProducts(page).catchError((e) {
        print('❌ Error cargando página $page: $e');
      });
    });
  }

  Future<void> _loadMoreProducts(int page) async {
    if (_getProductsUseCase == null) return;

    try {
      // ✅ TIMEOUT PARA PÁGINAS ADICIONALES
      final result = await _getProductsUseCase!(
            GetProductsParams(
              page: page,
              limit: 100,
              status: ProductStatus.active,
              includePrices: true,
            ),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⚠️ Timeout cargando página $page');
              return Left(ServerFailure('Timeout'));
            },
          );

      result.fold(
        (failure) {
          print('❌ Error cargando página $page: ${failure.message}');
        },
        (paginatedResult) {
          _availableProducts.addAll(paginatedResult.data);
          print(
            '✅ Productos página $page cargados: ${paginatedResult.data.length}',
          );

          if (page < 5 && paginatedResult.meta.hasNextPage) {
            // ✅ CARGAR SIGUIENTE PÁGINA DE FORMA ASÍNCRONA
            // _loadMoreProductsAsync(page + 1);
          }
        },
      );
    } catch (e) {
      print('💥 Error cargando página $page: $e');
    }
  }

  // ==================== CUSTOMER MANAGEMENT ====================

  Future<void> _loadCustomers() async {
    if (_getCustomersUseCase == null) {
      print('⚠️ GetCustomersUseCase no disponible - no se cargarán clientes');
      _availableCustomers.clear();
      _isLoadingCustomers.value = false;
      return;
    }

    try {
      _isLoadingCustomers.value = true;
      print('👥 Cargando clientes desde la base de datos...');

      // ✅ YIELD PARA NO BLOQUEAR
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await _getCustomersUseCase!(
            const GetCustomersParams(
              page: 1,
              limit: 50, // ✅ REDUCIR LÍMITE
              status: CustomerStatus.active,
            ),
          )
          .timeout(
            const Duration(seconds: 6), // ✅ TIMEOUT MÁS CORTO
            onTimeout: () {
              print('⚠️ Timeout cargando clientes');
              return Left(ServerFailure('Timeout al cargar clientes'));
            },
          );

      // ✅ YIELD ENTRE OPERACIONES
      await Future.delayed(const Duration(milliseconds: 10));

      result.fold(
        (failure) {
          print('❌ Error al cargar clientes: ${failure.message}');
          _availableCustomers.clear();
        },
        (paginatedResult) {
          _availableCustomers.value = paginatedResult.data;
          print('✅ Clientes cargados: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('💥 Error al cargar clientes: $e');
      _availableCustomers.clear();
    } finally {
      _isLoadingCustomers.value = false;
    }
  }

  Future<List<Customer>> searchCustomers(String query) async {
    print('🔍 Buscando clientes: "$query"');

    if (query.trim().isEmpty) return [];

    try {
      List<Customer> results = [];

      if (_searchCustomersUseCase != null) {
        final searchResult = await _searchCustomersUseCase!(
          SearchCustomersParams(searchTerm: query, limit: 20),
        );

        searchResult.fold(
          (failure) {
            print('❌ Error en búsqueda de clientes: ${failure.message}');
            results = _searchInLocalCustomers(query);
          },
          (customers) {
            results = customers;
            print(
              '✅ Búsqueda por API completada: ${customers.length} clientes',
            );
          },
        );
      } else {
        print('⚠️ SearchCustomersUseCase no disponible');
        results = _searchInLocalCustomers(query);
      }

      final filteredResults =
          results
              .where((customer) => customer.status == CustomerStatus.active)
              .take(10)
              .toList();

      print(
        '✅ Búsqueda de clientes completada: ${filteredResults.length} encontrados',
      );
      return filteredResults;
    } catch (e) {
      print('💥 Error inesperado en búsqueda de clientes: $e');
      return [];
    }
  }

  List<Customer> _searchInLocalCustomers(String query) {
    final searchTerm = query.toLowerCase();

    return _availableCustomers.where((customer) {
      return customer.status == CustomerStatus.active &&
          (customer.firstName.toLowerCase().contains(searchTerm) ||
              customer.lastName.toLowerCase().contains(searchTerm) ||
              (customer.companyName?.toLowerCase().contains(searchTerm) ??
                  false) ||
              customer.email.toLowerCase().contains(searchTerm) ||
              (customer.phone?.contains(searchTerm) ?? false) ||
              customer.documentNumber.contains(searchTerm));
    }).toList();
  }

  void selectCustomer(Customer customer) {
    _selectedCustomer.value = customer;
    print('👤 Cliente seleccionado: ${customer.displayName}');

    if (customer.paymentTerms > 0) {
      _dueDate.value = _invoiceDate.value.add(
        Duration(days: customer.paymentTerms),
      );
    } else {
      _dueDate.value = _invoiceDate.value;
    }
  }

  void clearCustomer() {
    _loadDefaultCustomer();
    print('🔄 Cliente vuelto a consumidor final');
  }

  // ==================== ITEM MANAGEMENT ====================

  // void addItem(InvoiceItemFormData item) {
  //   _invoiceItems.add(item);
  //   _recalculateTotals();
  //   print('➕ Item agregado: ${item.description}');
  // }

  void addItem(InvoiceItemFormData item) {
    _invoiceItems.insert(0, item); // Agregar al inicio
    _recalculateTotals();
    print('➕ Item agregado al inicio: ${item.description}');
  }

  // void updateItem(int index, InvoiceItemFormData updatedItem) {
  //   if (index >= 0 && index < _invoiceItems.length) {
  //     _invoiceItems[index] = updatedItem;
  //     _recalculateTotals();
  //     print('✏️ Item actualizado en posición $index');
  //   }
  // }

  void updateItem(int index, InvoiceItemFormData updatedItem) {
    if (index >= 0 && index < _invoiceItems.length) {
      // ✅ CORREGIDO: Actualizar en la misma posición, NO mover al inicio
      _invoiceItems[index] = updatedItem;
      print(
        '✏️ Item actualizado (mantiene posición $index): ${updatedItem.description}',
      );

      _recalculateTotals();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _invoiceItems.length) {
      final removedItem = _invoiceItems.removeAt(index);
      _recalculateTotals();
      print('🗑️ Item removido: ${removedItem.description}');

      Get.snackbar(
        'Producto Eliminado',
        removedItem.description,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.remove_circle, color: Colors.orange),
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(8),
      );
    }
  }

  void moveItem(int fromIndex, int toIndex) {
    if (fromIndex >= 0 &&
        fromIndex < _invoiceItems.length &&
        toIndex >= 0 &&
        toIndex < _invoiceItems.length) {
      final item = _invoiceItems.removeAt(fromIndex);
      _invoiceItems.insert(toIndex, item);
      print('🔄 Item movido de $fromIndex a $toIndex');
    }
  }

  void clearItems() {
    _invoiceItems.clear();
    _recalculateTotals();
    print('🧹 Todos los items removidos');
  }

  // ==================== DATE MANAGEMENT ====================

  void setInvoiceDate(DateTime date) {
    _invoiceDate.value = date;
    final daysDifference = _dueDate.value.difference(_invoiceDate.value).inDays;
    if (daysDifference < 1) {
      _dueDate.value = date.add(const Duration(days: 30));
    }
    print('📅 Fecha de factura: ${date.toString().split(' ')[0]}');
  }

  void setDueDate(DateTime date) {
    if (date.isAfter(_invoiceDate.value) ||
        date.isAtSameMomentAs(_invoiceDate.value)) {
      _dueDate.value = date;
      print('📅 Fecha de vencimiento: ${date.toString().split(' ')[0]}');
    } else {
      _showError(
        'Fecha inválida',
        'La fecha de vencimiento debe ser posterior a la fecha de emisión',
      );
    }
  }

  // ==================== PAYMENT & DISCOUNT MANAGEMENT ====================

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod.value = method;
    print('💳 Método de pago: ${method.displayName}');
  }

  void setTaxPercentage(double percentage) {
    if (percentage >= 0 && percentage <= 100) {
      _taxPercentage.value = percentage;
      _recalculateTotals();
      print('📊 Impuesto: $percentage%');
    }
  }

  void setDiscountPercentage(double percentage) {
    if (percentage >= 0 && percentage <= 100) {
      _discountPercentage.value = percentage;
      _recalculateTotals();
      print('💰 Descuento porcentual: $percentage%');
    }
  }

  void setDiscountAmount(double amount) {
    if (amount >= 0) {
      _discountAmount.value = amount;
      _recalculateTotals();
      print('💰 Descuento fijo: \${amount.toStringAsFixed(2)}');
    }
  }

  // ==================== CALCULATIONS ====================

  void _recalculateTotals() {
    update();
  }

  // ==================== PAYMENT & SAVE ====================

  // ✅ MÉTODO PRINCIPAL ACTUALIZADO CON IMPRESIÓN
  Future<void> saveInvoiceWithPayment(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status,
    bool shouldPrint, // ✅ NUEVO PARÁMETRO
  ) async {
    if (!_validateForm()) return;

    try {
      _isSaving.value = true;

      print('🚀 === INICIANDO GUARDADO DE FACTURA ===');
      print('💾 Datos recibidos:');
      print('   - Método: ${paymentMethod.displayName}');
      print('   - Estado: ${status.displayName}');
      print('   - Total: \${total.toStringAsFixed(2)}');
      print('   - Recibido: \${receivedAmount.toStringAsFixed(2)}');
      print('   - Cambio: \${change.toStringAsFixed(2)}');
      print('   - Es edición: $isEditMode');
      print('   - Debe imprimir: $shouldPrint'); // ✅ NUEVO LOG

      _paymentMethod.value = paymentMethod;

      final paymentInfo = _buildPaymentNotes(receivedAmount, change, status);
      notesController.text = paymentInfo;

      _adjustDueDateByPaymentMethod(paymentMethod, status);

      print('📅 Fecha de vencimiento ajustada: ${_dueDate.value}');
      print('📝 Notas generadas: ${paymentInfo.length} caracteres');

      Invoice? savedInvoice;

      if (isEditMode) {
        print('✏️ Actualizando factura existente...');
        savedInvoice = await _updateExistingInvoice(status);
      } else {
        print('➕ Creando nueva factura...');
        savedInvoice = await _createNewInvoice(status);
      }

      // ✅ NUEVA LÓGICA: IMPRIMIR SI SE SOLICITÓ
      if (savedInvoice != null && shouldPrint) {
        print('🖨️ Iniciando impresión automática...');
        await _printInvoiceAutomatically(savedInvoice);
      }

      print('✅ === FACTURA GUARDADA EXITOSAMENTE ===');
    } catch (e) {
      print('💥 Error inesperado al guardar: $e');
      _showError('Error inesperado', 'No se pudo procesar la venta');
    } finally {
      _isSaving.value = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: IMPRESIÓN AUTOMÁTICA
  Future<void> _printInvoiceAutomatically(Invoice invoice) async {
    try {
      _isPrinting.value = true;
      print('🖨️ === INICIANDO IMPRESIÓN AUTOMÁTICA ===');
      print('   - Factura: ${invoice.number}');
      print('   - Cliente: ${invoice.customerName}');
      print('   - Total: \${invoice.total.toStringAsFixed(2)}');

      // Usar el controlador de impresión térmica
      final success = await _thermalPrinterController.printInvoice(invoice);

      if (success) {
        print('✅ Impresión automática exitosa');
        _showPrintSuccess('Factura impresa exitosamente');
      } else {
        print('❌ Error en impresión automática');
        _showPrintError(
          'Error al imprimir: ${_thermalPrinterController.lastError ?? "Error desconocido"}',
        );
      }
    } catch (e) {
      print('💥 Error inesperado en impresión automática: $e');
      _showPrintError('Error inesperado al imprimir: $e');
    } finally {
      _isPrinting.value = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: IMPRIMIR FACTURA MANUALMENTE
  Future<void> printInvoice(Invoice invoice) async {
    if (_isPrinting.value) {
      //_showError('Ya hay una impresión en curso');
      _showError('Título del Error', 'Mensaje descriptivo del error');
      return;
    }

    try {
      _isPrinting.value = true;
      print('🖨️ Impresión manual solicitada para factura: ${invoice.number}');

      final success = await _thermalPrinterController.printInvoice(invoice);

      if (success) {
        _showPrintSuccess('Factura impresa exitosamente');
      } else {
        _showPrintError(
          'Error al imprimir: ${_thermalPrinterController.lastError ?? "Error desconocido"}',
        );
      }
    } catch (e) {
      print('💥 Error en impresión manual: $e');
      _showPrintError('Error inesperado al imprimir: $e');
    } finally {
      _isPrinting.value = false;
    }
  }

  void _adjustDueDateByPaymentMethod(
    PaymentMethod method,
    InvoiceStatus status,
  ) {
    if (status == InvoiceStatus.draft) {
      _dueDate.value = _invoiceDate.value.add(const Duration(days: 30));
      print(
        '📅 Borrador - Fecha de vencimiento: ${_dueDate.value.toString().split(' ')[0]}',
      );
      return;
    }

    switch (method) {
      case PaymentMethod.cash:
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
      case PaymentMethod.bankTransfer:
        _dueDate.value = _invoiceDate.value;
        break;
      case PaymentMethod.credit:
        final creditDays = selectedCustomer?.paymentTerms ?? 30;
        _dueDate.value = _invoiceDate.value.add(Duration(days: creditDays));
        break;
      case PaymentMethod.check:
        _dueDate.value = _invoiceDate.value.add(const Duration(days: 15));
        break;
      case PaymentMethod.other:
        if (selectedCustomer != null && selectedCustomer!.paymentTerms > 0) {
          _dueDate.value = _invoiceDate.value.add(
            Duration(days: selectedCustomer!.paymentTerms),
          );
        } else {
          _dueDate.value = _invoiceDate.value.add(const Duration(days: 30));
        }
        break;
    }

    print(
      '📅 Fecha de vencimiento ajustada: ${_dueDate.value.toString().split(' ')[0]}',
    );
  }

  String _buildPaymentNotes(
    double receivedAmount,
    double change,
    InvoiceStatus status,
  ) {
    final buffer = StringBuffer();
    // buffer.writeln('=== INFORMACIÓN DE FACTURA ===');
    buffer.writeln('Estado: ${status.displayName.toUpperCase()}');

    if (status == InvoiceStatus.draft) {
      buffer.writeln('PENDIENTE DE REVISIÓN Y APROBACIÓN');
      buffer.writeln(
        'Creado por: [Usuario actual]',
      ); // Aquí puedes agregar el usuario actual
      buffer.writeln('Requiere aprobación de supervisor');
    } else {
      buffer.writeln('Metodo de Pago: ${paymentMethod.displayName}');
    }

    // ✅ MOSTRAR SUBTOTAL SIN IVA CORRECTAMENTE
    buffer.writeln(
      //'Subtotal sin IVA: \$${subtotalWithoutTax.toStringAsFixed(2)}',
      'Subtotal sin IVA: \$${format.format(subtotalWithoutTax)}',
    );

    if (totalDiscountAmount > 0) {
      buffer.writeln('Descuento: \$${totalDiscountAmount.toStringAsFixed(2)}');
    }

    if (taxAmount > 0) {
      buffer.writeln('IVA (${taxPercentage}%): \$${format.format(taxAmount)}');
    }

    // ✅ MOSTRAR EL TOTAL CORRECTO (que debe coincidir con el precio del producto)
    buffer.writeln('TOTAL: \$${format.format(total)}');

    if (status != InvoiceStatus.draft) {
      // ✅ INFORMACIÓN ESPECÍFICA SEGÚN MÉTODO DE PAGO (solo si no es borrador)
      switch (paymentMethod) {
        case PaymentMethod.cash:
          buffer.writeln('Recibido: \$${format.format(receivedAmount)}');
          buffer.writeln('Cambio: \$${format.format(change)}');
          break;
        case PaymentMethod.credit:
          buffer.writeln(
            'Vencimiento: ${_dueDate.value.toString().split(' ')[0]}',
          );
          buffer.writeln(
            'Términos: ${selectedCustomer?.paymentTerms ?? 30} días',
          );
          break;
        case PaymentMethod.check:
          buffer.writeln('Pago con cheque - Pendiente de cobro');
          break;
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          buffer.writeln('Pago con tarjeta procesado');
          break;
        case PaymentMethod.bankTransfer:
          buffer.writeln('Transferencia bancaria confirmada');
          break;
        default:
          buffer.writeln('Pago procesado');
      }
    }

    buffer.writeln('Fecha: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Cliente: ${selectedCustomer?.displayName ?? 'N/A'}');

    if (notesController.text.isNotEmpty &&
        !notesController.text.contains('INFORMACIÓN DE')) {
      buffer.writeln('\n=== NOTAS ADICIONALES ===');
      buffer.writeln(notesController.text);
    }

    return buffer.toString();
  }

  Future<void> saveInvoice() async {
    if (!_validateForm()) return;

    try {
      _isSaving.value = true;
      print('💾 Guardando factura...');

      const defaultStatus = InvoiceStatus.draft;

      if (isEditMode) {
        await _updateExistingInvoice(defaultStatus);
      } else {
        await _createNewInvoice(defaultStatus);
      }
    } catch (e) {
      print('💥 Error inesperado al guardar: $e');
      _showError('Error inesperado', 'No se pudo guardar la factura');
    } finally {
      _isSaving.value = false;
    }
  }

  // ✅ MODIFICADO: Retornar la factura creada
  Future<Invoice?> _createNewInvoice(InvoiceStatus status) async {
    final items =
        _invoiceItems
            .map(
              (item) => CreateInvoiceItemParams(
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                discountPercentage: item.discountPercentage,
                discountAmount: item.discountAmount,
                unit: item.unit,
                notes: item.notes,
                productId: item.productId,
              ),
            )
            .toList();

    final result = await _createInvoiceUseCase(
      CreateInvoiceParams(
        customerId: selectedCustomer!.id,
        items: items,
        number: null,
        date: invoiceDate,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        terms: termsController.text.isNotEmpty ? termsController.text : null,
      ),
    );

    return result.fold(
      (failure) {
        _showError('Error al procesar venta', failure.message);
        return null;
      },
      (invoice) {
        _showSuccessWithStatus('¡Venta procesada exitosamente!', status);
        _prepareForNewSale();
        return invoice; // ✅ RETORNAR LA FACTURA CREADA
      },
    );
  }

  // ✅ MODIFICADO: Retornar la factura actualizada
  Future<Invoice?> _updateExistingInvoice(InvoiceStatus status) async {
    final items =
        _invoiceItems
            .map(
              (item) => CreateInvoiceItemParams(
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                discountPercentage: item.discountPercentage,
                discountAmount: item.discountAmount,
                unit: item.unit,
                notes: item.notes,
                productId: item.productId,
              ),
            )
            .toList();

    final result = await _updateInvoiceUseCase(
      UpdateInvoiceParams(
        id: editingInvoiceId!,
        number: null,
        date: invoiceDate,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        terms: termsController.text.isNotEmpty ? termsController.text : null,
        customerId: selectedCustomer?.id,
        items: items,
      ),
    );

    return result.fold(
      (failure) {
        _showError('Error al actualizar factura', failure.message);
        return null;
      },
      (invoice) {
        _showSuccessWithStatus('Factura actualizada exitosamente', status);
        Get.offAndToNamed('/invoices/detail/${invoice.id}');
        return invoice; // ✅ RETORNAR LA FACTURA ACTUALIZADA
      },
    );
  }

  void clearFormForNewSale() {
    _prepareForNewSale();
    _showSuccess('Lista para nueva venta');
  }

  void _prepareForNewSale() {
    _invoiceItems.clear();
    _loadDefaultCustomer();
    _invoiceDate.value = DateTime.now();
    _dueDate.value = DateTime.now();
    notesController.clear();
    termsController.text = 'Venta de contado';
    _discountPercentage.value = 0.0;
    _discountAmount.value = 0.0;
    _recalculateTotals();

    print('🔄 Formulario preparado para nueva venta');
  }

  void clearForm() {
    notesController.clear();
    termsController.text = _getDefaultTerms();

    _selectedCustomer.value = null;
    _invoiceItems.clear();
    _invoiceDate.value = DateTime.now();
    _dueDate.value = DateTime.now().add(const Duration(days: 30));
    _paymentMethod.value = PaymentMethod.cash;
    _taxPercentage.value = 19.0;
    _discountPercentage.value = 0.0;
    _discountAmount.value = 0.0;

    formKey.currentState?.reset();
    print('🧹 Formulario limpiado');
    _showSuccess('Formulario limpiado exitosamente');
  }

  void previewInvoice() {
    if (!_validateForm()) return;
    _showInfo('Vista Previa', 'Función de vista previa en desarrollo');
  }

  // ==================== VALIDATIONS ====================

  bool _validateForm() {
    if (invoiceItems.isEmpty) {
      _showError(
        'Sin productos',
        'Debe agregar al menos un producto a la venta',
      );
      return false;
    }

    if (invoiceItems.any((item) => !item.isValid)) {
      _showError(
        'Productos inválidos',
        'Algunos productos tienen datos incorrectos',
      );
      return false;
    }

    if (selectedCustomer == null) {
      _showError('Cliente requerido', 'Debe seleccionar un cliente');
      return false;
    }

    return true;
  }

  Future<void> confirmDraftInvoice(String invoiceId) async {
    try {
      print('✅ Confirmando borrador de factura: $invoiceId');
      _showSuccess('Factura confirmada y lista para procesamiento');
    } catch (e) {
      print('❌ Error al confirmar borrador: $e');
      _showError('Error', 'No se pudo confirmar la factura');
    }
  }

  // ==================== MESSAGE HELPERS ====================

  void _showSuccessWithStatus(String message, InvoiceStatus status) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData statusIcon;
    String statusMessage;

    switch (status) {
      case InvoiceStatus.paid:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusMessage = 'Venta procesada y pagada';
        break;
      case InvoiceStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        iconColor = Colors.orange.shade600;
        statusIcon = Icons.schedule;
        statusMessage = 'Factura pendiente de pago';
        break;
      case InvoiceStatus.draft:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        iconColor = Colors.blue.shade600;
        statusIcon = Icons.edit;
        statusMessage = 'Guardada como borrador - Pendiente de revisión';
        break;
      case InvoiceStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconColor = Colors.red.shade600;
        statusIcon = Icons.cancel;
        statusMessage = 'Factura cancelada';
        break;
      case InvoiceStatus.overdue:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconColor = Colors.red.shade600;
        statusIcon = Icons.warning;
        statusMessage = 'Factura vencida';
        break;
      case InvoiceStatus.partiallyPaid:
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        iconColor = Colors.amber.shade600;
        statusIcon = Icons.schedule;
        statusMessage = 'Pago parcial recibido';
        break;
      default:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusMessage = 'Procesada exitosamente';
    }

    Get.snackbar(
      status == InvoiceStatus.draft ? '¡Borrador Guardado!' : '¡Éxito!',
      statusMessage,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: textColor,
      icon: Icon(statusIcon, color: iconColor),
      duration: Duration(seconds: status == InvoiceStatus.draft ? 5 : 4),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showProductUpdatedMessage(String productName, double newQuantity) {
    Get.snackbar(
      'Cantidad Actualizada',
      '$productName (${newQuantity.toInt()} unidades) - Movido al inicio',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.add_circle, color: Colors.blue),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }

  // ✅ NUEVOS MENSAJES PARA IMPRESIÓN
  void _showPrintSuccess(String message) {
    Get.snackbar(
      '🖨️ Impresión Exitosa',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.print, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showPrintError(String message) {
    Get.snackbar(
      '🖨️ Error de Impresión',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.print_disabled, color: Colors.red),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      '¡Éxito!',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _getDefaultTerms() {
    return 'Términos y condiciones:\n'
        '• El pago debe realizarse en la fecha de vencimiento\n'
        '• Después del vencimiento se aplicarán intereses\n'
        '• Factura válida por 30 días';
  }

  void _disposeControllers() {
    notesController.dispose();
    termsController.dispose();
  }

  // ==================== DEBUG METHODS ====================

  void debugFormState() {
    print('🔍 DEBUG Form State:');
    print('   - Customer: ${selectedCustomer?.displayName ?? "None"}');
    print('   - Items: ${invoiceItems.length}');
    print('   - Subtotal: \${subtotal.toStringAsFixed(2)}');
    print('   - Tax: \${taxAmount.toStringAsFixed(2)}');
    print('   - Total: \${total.toStringAsFixed(2)}');
    print('   - Can Save: $canSave');
    print('   - Is Printing: $isPrinting');
  }
}
