// lib/features/invoices/presentation/controllers/invoice_form_controller.dart
import 'dart:async';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/audio_notification_service.dart';
import 'package:baudex_desktop/features/cash_register/presentation/controllers/cash_register_controller.dart';
import 'package:baudex_desktop/features/cash_register/presentation/widgets/open_cash_register_dialog.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import '../../../../app/shared/utils/subscription_error_handler.dart';
import '../../../../app/shared/services/subscription_validation_service.dart';
import '../../../../app/core/network/network_info.dart';

import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

// Domain entities
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/update_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';

// Customer and Product entities
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/data/repositories/customer_offline_repository.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../customers/domain/usecases/search_customers_usecase.dart';
import '../../../customers/domain/usecases/create_customer_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/data/repositories/product_offline_repository.dart';
import '../../../products/domain/entities/product_presentation.dart';
import '../../../products/domain/entities/tax_enums.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/domain/usecases/get_product_presentations_usecase.dart';
import '../../../products/presentation/bindings/product_presentation_binding.dart';
import '../widgets/presentation_picker_dialog.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

// Bindings
import '../../../customers/presentation/bindings/customer_binding.dart';
import '../../../products/presentation/bindings/product_binding.dart';

// Presentation models
import 'package:baudex_desktop/features/invoices/data/models/invoice_form_models.dart';

// ✅ NUEVO IMPORT: Controlador de impresión térmica
import '../services/invoice_inventory_service.dart';
import '../../../settings/presentation/controllers/user_preferences_controller.dart';

class InvoiceFormController extends GetxController {
  // ==================== DEPENDENCIES ====================

  final CreateInvoiceUseCase _createInvoiceUseCase;
  final UpdateInvoiceUseCase _updateInvoiceUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;
  GetCustomersUseCase? _getCustomersUseCase;
  SearchCustomersUseCase? _searchCustomersUseCase;
  CreateCustomerUseCase? _createCustomerUseCase;
  GetProductsUseCase? _getProductsUseCase;
  SearchProductsUseCase? _searchProductsUseCase;
  GetCustomerByIdUseCase? _getCustomerByIdUseCase;

  // ✅ NUEVO: Controlador de impresión térmica
  late final ThermalPrinterController _thermalPrinterController;

  // ✅ NUEVO: Servicio de integración con inventario (opcional)
  InvoiceInventoryService? _inventoryService;

  // Helper para obtener preferencias de usuario
  bool get shouldValidateStock {
    try {
      final ctrl = Get.find<UserPreferencesController>();
      return ctrl.validateStockBeforeInvoice && !ctrl.allowOverselling;
    } catch (_) {
      return true; // default seguro
    }
  }

  InvoiceFormController({
    required CreateInvoiceUseCase createInvoiceUseCase,
    required UpdateInvoiceUseCase updateInvoiceUseCase,
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
    GetCustomersUseCase? getCustomersUseCase,
    SearchCustomersUseCase? searchCustomersUseCase,
    CreateCustomerUseCase? createCustomerUseCase,
    GetProductsUseCase? getProductsUseCase,
    SearchProductsUseCase? searchProductsUseCase,
    GetCustomerByIdUseCase? getCustomerByIdUseCase,
  }) : _createInvoiceUseCase = createInvoiceUseCase,
       _updateInvoiceUseCase = updateInvoiceUseCase,
       _getInvoiceByIdUseCase = getInvoiceByIdUseCase,
       _getCustomersUseCase = getCustomersUseCase,
       _searchCustomersUseCase = searchCustomersUseCase,
       _createCustomerUseCase = createCustomerUseCase,
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

    // ✅ INICIALIZAR SERVICIO DE INVENTARIO (OPCIONAL)
    if (Get.isRegistered<InvoiceInventoryService>()) {
      _inventoryService = Get.find<InvoiceInventoryService>();
      print('♻️ Reutilizando InvoiceInventoryService existente');
    } else {
      _inventoryService = null;
      print(
        'ℹ️ InvoiceInventoryService no disponible - descuento automático de inventario deshabilitado',
      );
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
  final _invoiceDate = DateTime.now().obs; // Se reemplaza en _initializeForm() con TenantDateTimeService
  final _dueDate = DateTime.now().obs; // Se reemplaza en _initializeForm() con TenantDateTimeService
  final _paymentMethod = PaymentMethod.cash.obs;
  final _taxPercentage = 0.0.obs; // Se establece desde el primer producto agregado
  final _discountPercentage = 0.0.obs;
  final _discountAmount = 0.0.obs;

  // Datos disponibles
  final _availableCustomers = <Customer>[].obs;
  final _availableProducts = <Product>[].obs;

  // ✅ NUEVO: Para manejar selección automática cuando se actualiza un producto
  final _lastUpdatedItemIndex = Rxn<int>();
  final _shouldHighlightUpdatedItem = false.obs;

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
  static const String DEFAULT_CUSTOMER_NAME = 'Consumidor Final';

  // ==================== CACHE DE OPTIMIZACIÓN ====================

  // Cache del cliente "Consumidor Final" para evitar búsquedas repetidas
  Customer? _cachedDefaultCustomer;
  DateTime? _customerCacheTime;
  static const Duration _customerCacheExpiry = Duration(minutes: 30);

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

  // ✅ NUEVO: Getters para selección automática
  int? get lastUpdatedItemIndex => _lastUpdatedItemIndex.value;
  bool get shouldHighlightUpdatedItem => _shouldHighlightUpdatedItem.value;

  // ✅ NUEVO: Getters de observables para reactividad externa
  Rxn<int> get lastUpdatedItemIndexObs => _lastUpdatedItemIndex;
  RxBool get shouldHighlightUpdatedItemObs => _shouldHighlightUpdatedItem;

  // Validación del formulario
  bool get canSave =>
      invoiceItems.isNotEmpty &&
      invoiceItems.every((item) => item.isValid) &&
      selectedCustomer != null;

  // ✅ CÁLCULOS ACTUALIZADOS PARA USAR IVA POR ITEM

  /// Subtotal SIN IVA (base gravable) - usa el IVA individual de cada item
  double get subtotalWithoutTax {
    return _invoiceItems.fold(0.0, (sum, item) {
      return sum + item.subtotalWithoutTax;
    });
  }

  /// Subtotal CON IVA (precio de venta)
  double get subtotal {
    return subtotalWithoutTax + taxAmount;
  }

  /// Descuento total aplicado
  double get totalDiscountAmount {
    final percentageDiscount = (subtotalWithoutTax * discountPercentage) / 100;
    return percentageDiscount + discountAmount;
  }

  /// Base gravable después de descuentos
  double get taxableAmount {
    return subtotalWithoutTax - totalDiscountAmount;
  }

  /// ✅ IVA total calculado sumando el IVA de cada item
  double get taxAmount {
    final baseSubtotal = subtotalWithoutTax;
    if (baseSubtotal <= 0) return 0;

    final subtotalAfterDiscount = baseSubtotal - totalDiscountAmount;
    final discountRatio =
        subtotalAfterDiscount > 0 ? subtotalAfterDiscount / baseSubtotal : 0;

    // Sumar el IVA de cada item, ajustado proporcionalmente al descuento
    return _invoiceItems.fold(0.0, (sum, item) {
      return sum + (item.taxAmount * discountRatio);
    });
  }

  /// Total final (base + IVA)
  double get total {
    return taxableAmount + taxAmount;
  }

  /// ✅ Recalcular el IVA promedio ponderado para mostrar en UI
  void _recalculateAverageTaxPercentage() {
    final taxable = taxableAmount;
    if (taxable <= 0) {
      _taxPercentage.value = 0;
      return;
    }

    // Calcular IVA promedio ponderado basado en el monto de impuesto real
    final averageTax = (taxAmount / taxable) * 100;
    _taxPercentage.value = double.parse(averageTax.toStringAsFixed(2));
    print('📊 IVA promedio calculado: ${_taxPercentage.value}%');
  }

  // UI helpers
  String get pageTitle => isEditMode ? 'Editar Factura' : 'Punto de Venta';
  String get saveButtonText => isEditMode ? 'Actualizar' : 'Procesar Venta';

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    SyncService.notifyFormOpened();
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

        // Inicializar si faltan dependencias críticas
        if (!Get.isRegistered<CreateCustomerUseCase>() ||
            _createCustomerUseCase == null) {
          print('👥 [AUTO-INIT] Inicializando CustomerBinding completo...');

          // Inicializar CustomerBinding completo
          CustomerBinding().dependencies();

          // Esperar un poco para que se registren todas las dependencias
          await Future.delayed(const Duration(milliseconds: 100));

          // Verificar y actualizar referencias
          print('🔍 [AUTO-INIT] Verificando dependencias registradas...');
          print(
            '   - GetCustomersUseCase: ${Get.isRegistered<GetCustomersUseCase>()}',
          );
          print(
            '   - SearchCustomersUseCase: ${Get.isRegistered<SearchCustomersUseCase>()}',
          );
          print(
            '   - CreateCustomerUseCase: ${Get.isRegistered<CreateCustomerUseCase>()}',
          );
          print(
            '   - GetCustomerByIdUseCase: ${Get.isRegistered<GetCustomerByIdUseCase>()}',
          );

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
          final createCustomerUseCase =
              Get.isRegistered<CreateCustomerUseCase>()
                  ? Get.find<CreateCustomerUseCase>()
                  : null;

          // Re-asignar las dependencias
          _getCustomersUseCase = getCustomersUseCase;
          _searchCustomersUseCase = searchCustomersUseCase;
          _createCustomerUseCase = createCustomerUseCase;
          _getCustomerByIdUseCase = getCustomerByIdUseCase;

          print('✅ [AUTO-INIT] CustomerBinding inicializado');
          print(
            '✅ [AUTO-INIT] CreateCustomerUseCase disponible: ${_createCustomerUseCase != null}',
          );
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
    SyncService.notifyFormClosed();
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
    final dtService = Get.find<TenantDateTimeService>();
    _invoiceDate.value = dtService.now();
    _dueDate.value = dtService.now();
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

      // 🔔 VERIFICAR ESTADO DE SUSCRIPCIÓN (ASYNC - funciona online y offline)
      // Usa ISAR si no hay datos en memoria
      await SubscriptionValidationService.showExpirationWarningIfNeededAsync();

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

  // ✅ OPTIMIZACIÓN: Cargar productos en background para búsqueda offline
  void _loadInitialDataStaggered() async {
    try {
      print('⚡ Inicialización optimizada - cargando productos en background');
      print('💡 Los clientes se cargarán cuando se busquen');

      _availableCustomers.clear();

      // Cargar productos en background para búsqueda offline
      _loadProducts();
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
    print('   - IVA ($taxPercentage%): \${taxAmount.toStringAsFixed(2)}');
    print('   - TOTAL: \${total.toStringAsFixed(2)}');
  }

  /// ⚡ OPTIMIZADO: Cargar cliente por defecto con cache
  Future<void> _loadDefaultCustomer() async {
    try {
      // Verificar cache primero
      if (_cachedDefaultCustomer != null && _customerCacheTime != null) {
        final timeSinceCache = DateTime.now().difference(_customerCacheTime!);
        if (timeSinceCache < _customerCacheExpiry) {
          print(
            '⚡ Cargando cliente "$DEFAULT_CUSTOMER_NAME" desde CACHE (${timeSinceCache.inMinutes}min antiguo)',
          );
          _selectedCustomer.value = _cachedDefaultCustomer;
          return;
        }
      }

      print('🔍 Buscando cliente "$DEFAULT_CUSTOMER_NAME" en BD...');

      // ✅ ESTABLECER CLIENTE FALLBACK INMEDIATAMENTE
      _setFallbackDefaultCustomer();

      if (_searchCustomersUseCase != null) {
        print(
          '✅ SearchCustomersUseCase disponible, realizando búsqueda en servidor...',
        );

        // ✅ BUSCAR CLIENTE "Consumidor Final" EN BACKGROUND SIN BLOQUEAR
        _searchCustomersUseCase!(
              SearchCustomersParams(
                searchTerm: DEFAULT_CUSTOMER_NAME,
                limit: 5,
              ),
            )
            .timeout(const Duration(seconds: 5))
            .then((result) {
              result.fold(
                (failure) {
                  print(
                    '❌ Error buscando cliente final: ${failure.toString()}',
                  );
                  // Mantener cliente fallback
                },
                (customers) {
                  // Buscar cliente que coincida exactamente con "Consumidor Final"
                  Customer? defaultCustomer;
                  try {
                    defaultCustomer = customers.firstWhere((customer) {
                      final fullName =
                          '${customer.firstName} ${customer.lastName}'.trim();
                      return fullName.toLowerCase() ==
                          DEFAULT_CUSTOMER_NAME.toLowerCase();
                    });
                  } catch (e) {
                    // No se encontró el cliente
                    defaultCustomer = null;
                  }

                  if (defaultCustomer != null) {
                    _selectedCustomer.value = defaultCustomer;

                    // ⚡ GUARDAR EN CACHE
                    _cachedDefaultCustomer = defaultCustomer;
                    _customerCacheTime = DateTime.now();

                    print('✅ Cliente final encontrado y cargado exitosamente:');
                    print('   - ID: ${defaultCustomer.id}');
                    print('   - Nombre: ${defaultCustomer.displayName}');
                    print('   - Email: ${defaultCustomer.email}');
                    print('💾 Cliente cacheado para próximas cargas');
                  } else {
                    print(
                      '⚠️ No se encontró cliente "$DEFAULT_CUSTOMER_NAME", usando fallback',
                    );
                  }
                },
              );
            })
            .catchError((e) {
              print('💥 Error inesperado buscando cliente final: $e');
              // Mantener cliente fallback
            });
      } else {
        print('❌ SearchCustomersUseCase NO disponible');
        print('🔄 Usando cliente fallback...');
      }
    } catch (e) {
      print('💥 Error inesperado cargando cliente final: $e');
      print('🔄 Usando cliente fallback...');
      _setFallbackDefaultCustomer();
    }
  }

  // ✅ FUNCIÓN OBSOLETA: Ahora se usa _loadDefaultCustomer que busca por nombre
  void _loadDefaultCustomerAsync() {
    print(
      '⚠️ _loadDefaultCustomerAsync está obsoleto, usando _loadDefaultCustomer',
    );
    _loadDefaultCustomer();
  }

  // ✅ NUEVA FUNCIÓN: Cargar factura para edición asíncronamente
  void _loadInvoiceForEditAsync(String invoiceId) {
    // Programar carga después de que la UI esté lista
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      _loadInvoiceForEdit(invoiceId);
    });
  }

  /// Asegurar que tenemos un cliente válido antes de crear factura
  /// ✅ MEJORADO: Permite clientes offline cuando no hay conexión
  Future<Customer?> _ensureValidCustomer() async {
    final currentCustomer = selectedCustomer;

    if (currentCustomer == null) {
      print('❌ No hay cliente seleccionado');
      return null;
    }

    // Verificar si el cliente actual es válido (tiene UUID real)
    if (_isValidUUID(currentCustomer.id) &&
        !currentCustomer.id.startsWith('fallback_')) {
      print(
        '✅ Cliente actual es válido: ${currentCustomer.displayName} (${currentCustomer.id})',
      );
      return currentCustomer;
    }

    // ✅ NUEVO: Permitir clientes creados offline (customer_offline_...)
    if (currentCustomer.id.startsWith('customer_offline_')) {
      print(
        '✅ Cliente offline válido: ${currentCustomer.displayName} (${currentCustomer.id})',
      );
      print('   💡 Se sincronizará cuando haya conexión');
      return currentCustomer;
    }

    print('⚠️ Cliente actual es temporal/fallback, buscando cliente real...');

    // Si es el cliente fallback "Consumidor Final", buscar el real
    if (_isDefaultCustomer(currentCustomer)) {
      final realCustomer = await _findOrCreateDefaultCustomer();
      if (realCustomer != null) {
        // Actualizar el cliente seleccionado al real
        _selectedCustomer.value = realCustomer;
        print(
          '✅ Cliente real encontrado y actualizado: ${realCustomer.displayName} (${realCustomer.id})',
        );
        return realCustomer;
      }

      // ✅ NUEVO: Si estamos offline y no se pudo crear/encontrar cliente,
      // usar el fallback para permitir facturación offline
      final isOffline = await _checkIfOffline();
      if (isOffline) {
        print('📴 MODO OFFLINE: Usando cliente fallback para facturación');
        print('   💡 La factura se creará con cliente temporal y se resolverá al sincronizar');
        return currentCustomer; // Retornar el fallback
      }
    }

    print('❌ No se pudo resolver a un cliente válido');
    return null;
  }

  /// Verificar si estamos en modo offline
  Future<bool> _checkIfOffline() async {
    try {
      if (Get.isRegistered<NetworkInfo>()) {
        final networkInfo = Get.find<NetworkInfo>();
        final isConnected = await networkInfo.isConnected;
        return !isConnected;
      }
      return false;
    } catch (e) {
      print('⚠️ Error verificando conexión: $e');
      return false;
    }
  }

  /// Verificar si un string es un UUID válido
  bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    return uuidRegex.hasMatch(id.toLowerCase());
  }

  /// Verificar si un cliente es el cliente por defecto
  bool _isDefaultCustomer(Customer customer) {
    final fullName = '${customer.firstName} ${customer.lastName}'.trim();
    return fullName.toLowerCase() == DEFAULT_CUSTOMER_NAME.toLowerCase() ||
        customer.id.startsWith('fallback_consumidor_final');
  }

  /// ⚡ OPTIMIZADO: Buscar o crear el cliente "Consumidor Final" con cache
  Future<Customer?> _findOrCreateDefaultCustomer() async {
    try {
      // Verificar cache primero
      if (_cachedDefaultCustomer != null && _customerCacheTime != null) {
        final timeSinceCache = DateTime.now().difference(_customerCacheTime!);
        if (timeSinceCache < _customerCacheExpiry) {
          print(
            '⚡ Usando cliente "$DEFAULT_CUSTOMER_NAME" desde CACHE (${timeSinceCache.inMinutes}min antiguo)',
          );
          return _cachedDefaultCustomer;
        } else {
          print('🔄 Cache del cliente expirado, buscando en servidor...');
        }
      }

      print('🔍 Buscando cliente real "$DEFAULT_CUSTOMER_NAME" en servidor...');

      if (_searchCustomersUseCase != null) {
        // Buscar primero por nombre
        final nameResult = await _searchCustomersUseCase!(
              SearchCustomersParams(
                searchTerm: DEFAULT_CUSTOMER_NAME,
                limit: 5,
              ),
            )
            .timeout(const Duration(seconds: 5));

        Customer? foundCustomer = nameResult.fold(
          (failure) {
            print('❌ Error buscando cliente por nombre: ${failure.message}');
            return null;
          },
          (customers) {
            // Buscar cliente que coincida exactamente por nombre
            try {
              return customers.firstWhere((customer) {
                final fullName =
                    '${customer.firstName} ${customer.lastName}'.trim();
                return fullName.toLowerCase() ==
                    DEFAULT_CUSTOMER_NAME.toLowerCase();
              });
            } catch (e) {
              return null;
            }
          },
        );

        // Si no se encontró por nombre, buscar por documento
        if (foundCustomer == null) {
          print(
            '🔍 No encontrado por nombre, buscando por documento "222222222222"...',
          );
          final documentResult = await _searchCustomersUseCase!(
                SearchCustomersParams(searchTerm: '222222222222', limit: 5),
              )
              .timeout(const Duration(seconds: 5));

          foundCustomer = documentResult.fold(
            (failure) {
              print(
                '❌ Error buscando cliente por documento: ${failure.message}',
              );
              return null;
            },
            (customers) {
              // Buscar cliente que coincida por documento
              try {
                return customers.firstWhere((customer) {
                  return customer.documentNumber == '222222222222';
                });
              } catch (e) {
                return null;
              }
            },
          );
        }

        if (foundCustomer != null) {
          print(
            '✅ Cliente real encontrado: ${foundCustomer.displayName} (${foundCustomer.id})',
          );
          print('   - Documento: ${foundCustomer.documentNumber}');

          // ⚡ GUARDAR EN CACHE
          _cachedDefaultCustomer = foundCustomer;
          _customerCacheTime = DateTime.now();
          print(
            '💾 Cliente cacheado para futuras búsquedas (expira en ${_customerCacheExpiry.inMinutes}min)',
          );

          return foundCustomer;
        } else {
          print(
            '⚠️ Cliente "$DEFAULT_CUSTOMER_NAME" no existe, creando automáticamente...',
          );
          return await _createDefaultCustomer();
        }
      } else {
        print('❌ SearchCustomersUseCase no disponible');
        return null;
      }
    } catch (e) {
      print('💥 Error buscando cliente por defecto: $e');
      return null;
    }
  }

  /// Crear automáticamente el cliente "Consumidor Final"
  Future<Customer?> _createDefaultCustomer() async {
    try {
      // Intentar obtener CreateCustomerUseCase si no está disponible
      if (_createCustomerUseCase == null) {
        if (Get.isRegistered<CreateCustomerUseCase>()) {
          _createCustomerUseCase = Get.find<CreateCustomerUseCase>();
          print('✅ CreateCustomerUseCase obtenido desde Get.find');
        } else {
          print(
            '❌ CreateCustomerUseCase no disponible - no se puede crear cliente',
          );
          print(
            '💡 SOLUCIÓN: Crea manualmente un cliente "Consumidor Final" con documento "222222222222"',
          );
          return null;
        }
      }

      print('➕ Creando cliente "$DEFAULT_CUSTOMER_NAME" automáticamente...');

      final createResult = await _createCustomerUseCase!(
            CreateCustomerParams(
              firstName: 'Consumidor',
              lastName: 'Final',
              email: 'consumidor.final@empresa.com',
              documentType: DocumentType.cc,
              documentNumber: '222222222222',
              address: 'Venta de mostrador',
              city: 'Cúcuta',
              state: 'Norte de Santander',
              country: 'Colombia',
              status: CustomerStatus.active,
              paymentTerms: 1,
              creditLimit: 0.0,
              notes: 'Cliente creado automáticamente para ventas de mostrador',
              metadata: {
                'isDefaultCustomer': true,
                'autoCreated': true,
                'createdAt': DateTime.now().toIso8601String(),
              },
            ),
          )
          .timeout(const Duration(seconds: 10));

      return createResult.fold(
        (failure) {
          print('❌ Error creando cliente por defecto: ${failure.message}');
          return null;
        },
        (customer) {
          print('✅ Cliente "$DEFAULT_CUSTOMER_NAME" creado exitosamente:');
          print('   - ID: ${customer.id}');
          print('   - Nombre: ${customer.displayName}');
          print('   - Email: ${customer.email}');

          // ⚡ GUARDAR EN CACHE
          _cachedDefaultCustomer = customer;
          _customerCacheTime = DateTime.now();
          print('💾 Nuevo cliente cacheado para futuras búsquedas');

          return customer;
        },
      );
    } catch (e) {
      print('💥 Error inesperado creando cliente por defecto: $e');
      return null;
    }
  }

  void _setFallbackDefaultCustomer() {
    final fallbackCustomer = Customer(
      id: 'fallback_consumidor_final_${DateTime.now().millisecondsSinceEpoch}',
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
      paymentTerms: 1,
      totalPurchases: 0,
      totalOrders: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _selectedCustomer.value = fallbackCustomer;
    print('👤 Cliente fallback establecido: ${fallbackCustomer.displayName}');
    print('   - ID temporal: ${fallbackCustomer.id}');
    print(
      '   - Nota: Se reemplazará automáticamente cuando se encuentre el cliente real "$DEFAULT_CUSTOMER_NAME"',
    );
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

  /// Punto de entrada desde el POS: decide si mostrar selector de
  /// presentación (cartón / kilo / cajetilla / unidad) o agregar el producto
  /// directo. Solo abre el dialog cuando el producto tiene >1 presentación
  /// activa — productos con presentación única (factor=1, herencia del
  /// backfill) se comportan exactamente como antes.
  Future<void> handleProductSelection(
    Product product, {
    double quantity = 1,
  }) async {
    // Producto temporal: nunca tiene presentaciones, ruta legacy directa.
    final isTemporary =
        product.id.startsWith('temp_') ||
        product.id.startsWith('unregistered_') ||
        (product.metadata?['isTemporary'] == true);

    if (isTemporary) {
      addOrUpdateProductToInvoice(product, quantity: quantity);
      return;
    }

    List<ProductPresentation> active = [];
    try {
      // Defensa: si por algún motivo el usecase no fue registrado en el
      // InitialBinding (build viejo, hot-reload sucio), lo registramos
      // ahora antes de seguir. Idempotente.
      if (!Get.isRegistered<GetProductPresentationsUseCase>()) {
        ProductPresentationBinding.registerCore();
      }
      final useCase = Get.find<GetProductPresentationsUseCase>();
      final result = await useCase(
        GetProductPresentationsParams(productId: product.id),
      );
      result.fold(
        (failure) {
          // Si falla (offline sin cache, etc.), seguimos con flujo legacy.
          print('⚠️ No se pudieron cargar presentaciones: $failure');
        },
        (list) {
          active = list.where((p) => p.isActive).toList();
        },
      );
    } catch (e) {
      print('⚠️ GetProductPresentationsUseCase no registrado o falló: $e');
    }

    if (active.length <= 1) {
      // 0 o 1 presentación → comportamiento legacy (no enviamos presentationId).
      addOrUpdateProductToInvoice(product, quantity: quantity);
      return;
    }

    // >1 presentaciones activas → preguntar al usuario.
    final selected = await Get.dialog<ProductPresentation>(
      PresentationPickerDialog(product: product, presentations: active),
      barrierDismissible: true,
    );
    if (selected == null) return; // canceló

    addOrUpdateProductToInvoice(
      product,
      quantity: quantity,
      presentation: selected,
    );
  }

  void addOrUpdateProductToInvoice(
    Product product, {
    double quantity = 1,
    ProductPresentation? presentation,
  }) {
    final instanceId = hashCode;
    print(
      '🛒 Procesando producto: ${product.name} (cantidad: $quantity) (Instance: $instanceId)',
    );
    if (presentation != null) {
      print(
        '   📐 Presentación: ${presentation.name} (factor=${presentation.factor}, precio=${presentation.price})',
      );
    }
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

      // Solo validar stock si la preferencia está activa y no permite sobreventa
      if (shouldValidateStock && product.stock <= 0) {
        _showError('Sin Stock', '${product.name} no tiene stock disponible');
        AudioNotificationService.instance.announceOutOfStock();
        return;
      }
    }

    _ensureProductIsAvailable(product);

    // Si viene una presentación, su precio toma precedencia.
    // Si no, fallback al esquema actual: price1 → cualquier activo → sellingPrice.
    double unitPrice;
    if (presentation != null && presentation.price > 0) {
      unitPrice = presentation.price;
    } else {
      final defaultPrice = product.getPriceByType(PriceType.price1);
      unitPrice = defaultPrice?.finalAmount ?? 0;
      if (unitPrice <= 0) {
        final anyPrice = product.prices?.firstWhereOrNull(
          (p) => p.type != PriceType.cost && p.finalAmount > 0,
        );
        unitPrice = anyPrice?.finalAmount ?? product.sellingPrice ?? 0;
      }
    }

    if (unitPrice <= 0) {
      _showError('Sin Precio', '${product.name} no tiene precio de venta configurado');
      return;
    }

    // Si hay presentación, el match para "item existente" debe considerar
    // también la presentación: 2 cartones + 5 unidades sueltas son items distintos.
    final existingIndex = _invoiceItems.indexWhere(
      (item) =>
          item.productId == product.id &&
          item.presentationId == presentation?.id,
    );

    if (existingIndex != -1) {
      // ✅ MODIFICACIÓN: Actualizar producto existente SIN moverlo de posición
      final existingItem = _invoiceItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Solo validar stock si la preferencia está activa
      if (!isTemporary && shouldValidateStock && newQuantity > product.stock) {
        _showError(
          'Stock Insuficiente',
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        AudioNotificationService.instance.announceOutOfStock();
        return;
      }

      final updatedItem = existingItem.copyWith(quantity: newQuantity);

      // ✅ NUEVO: Actualizar en la misma posición, NO mover al inicio
      _invoiceItems[existingIndex] = updatedItem;

      print(
        '✅ Cantidad actualizada (mantiene posición): ${existingItem.description} -> $newQuantity (índice: $existingIndex)',
      );

      // ✅ NUEVO: Notificar que este item fue actualizado para selección automática
      _lastUpdatedItemIndex.value = existingIndex;
      _shouldHighlightUpdatedItem.value = true;

      // Limpiar el highlight después de un breve momento
      Future.delayed(const Duration(milliseconds: 300), () {
        _shouldHighlightUpdatedItem.value = false;
      });

      _showProductUpdatedMessage(product.name, newQuantity);
    } else {
      // Solo validar stock si la preferencia está activa
      if (!isTemporary && shouldValidateStock && quantity > product.stock) {
        _showError(
          'Stock Insuficiente',
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        AudioNotificationService.instance.announceOutOfStock();
        return;
      }

      // ✅ DETERMINAR EL IVA DEL PRODUCTO
      // 1. isTaxable debe ser true
      // 2. taxCategory NO puede ser NO_GRAVADO ni EXENTO
      // 3. taxRate debe ser mayor a 0
      double itemTaxPercentage = 0;
      final isNoGravado = product.taxCategory == TaxCategory.noGravado;
      final isExento = product.taxCategory == TaxCategory.exento;
      final hasTax = product.isTaxable && !isNoGravado && !isExento && product.taxRate > 0;

      if (hasTax) {
        itemTaxPercentage = product.taxRate;
        print('💰 Item CON IVA: ${product.name} - ${itemTaxPercentage}% (${product.taxCategory.displayName})');
      } else {
        print('📦 Item SIN IVA: ${product.name} (${product.taxCategory.displayName}, isTaxable: ${product.isTaxable}, taxRate: ${product.taxRate})');
      }

      final newItem = InvoiceItemFormData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: product.name,
        quantity: quantity,
        unitPrice: unitPrice,
        unit: presentation?.name ?? product.unit ?? 'pcs',
        productId: product.id,
        taxPercentage: itemTaxPercentage, // ✅ INCLUIR IVA INDIVIDUAL
        presentationId: presentation?.id,
        presentationName: presentation?.name,
        presentationFactor: presentation?.factor,
      );

      // ✅ MODIFICACIÓN: Agregar al inicio de la lista
      _invoiceItems.insert(0, newItem);

      // ✅ ACTUALIZAR EL IVA DE LA FACTURA (promedio ponderado para mostrar)
      _recalculateAverageTaxPercentage();

      // ✅ NUEVO: Notificar que se agregó un nuevo producto en el índice 0
      _lastUpdatedItemIndex.value = 0;
      _shouldHighlightUpdatedItem.value = true;

      // Limpiar el highlight después de un breve momento
      Future.delayed(const Duration(milliseconds: 300), () {
        _shouldHighlightUpdatedItem.value = false;
      });

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

  /// Normaliza texto para búsqueda: minúsculas y sin tildes
  String _normalizeSearch(String text) {
    const withAccents =    'áéíóúàèìòùäëïöüâêîôûãõñ';
    const withoutAccents = 'aeiouaeiouaeiouaeiouaon';
    var result = text.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  Future<List<Product>> searchProducts(String query) async {
    print('🔍 Búsqueda OFFLINE: "$query" '
        '(_availableProducts=${_availableProducts.length})');

    if (query.trim().isEmpty) return [];

    try {
      // ═══════════════════════════════════════════════════════════════════
      // FUENTE DE VERDAD: ISAR directo via `ProductOfflineRepository`.
      //
      // Por qué no `_availableProducts`: esa lista en memoria puede
      // estar incompleta cuando el `_loadProducts()` está corriendo
      // (cache-first + refresh API en background). Si el usuario busca
      // mientras eso pasa, vería sub-resultados. ISAR siempre tiene la
      // totalidad del catálogo sincronizado, así que es más confiable.
      //
      // Búsqueda nativa por nameContains/skuContains/barcodeContains/
      // descriptionContains, case-insensitive, sin caps.
      // ═══════════════════════════════════════════════════════════════════
      List<Product> results = const [];

      if (Get.isRegistered<ProductOfflineRepository>()) {
        final isarSearch = await Get.find<ProductOfflineRepository>()
            .searchProducts(query, limit: null);
        isarSearch.fold(
          (failure) => print('⚠️ ISAR search falló: ${failure.message}'),
          (list) => results = list,
        );
        print('📦 ISAR retornó ${results.length} matches');
      }

      // Fallback: si por alguna razón el offline repo no está registrado
      // o devolvió vacío, intentamos la búsqueda en memoria igual.
      if (results.isEmpty) {
        results = _searchInLocalProducts(query);
        print('💾 Fallback memoria: ${results.length} matches');
      }

      // Dedupe por id y filtrar SOLO activos. Los sin stock SÍ aparecen
      // (con `canSelect=false` en `_buildResultItem`); el cajero ve que
      // existen pero no puede venderlos si `shouldValidateStock=true`.
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        if (product.status == ProductStatus.active) {
          uniqueResults[product.id] = product;
        }
      }

      final finalResults = uniqueResults.values.toList();
      print('✅ Búsqueda devolvió ${finalResults.length} productos activos');
      return finalResults;
    } catch (e) {
      print('💥 Error inesperado en búsqueda: $e');
      return _searchInLocalProducts(query);
    }
  }

  /// Búsqueda local: nombre, SKU, descripción, código de barras
  /// Normaliza tildes y mayúsculas para match flexible
  List<Product> _searchInLocalProducts(String query) {
    final searchTerm = _normalizeSearch(query);

    return _availableProducts.where((product) {
      if (product.status != ProductStatus.active) return false;

      final name = _normalizeSearch(product.name);
      final sku = _normalizeSearch(product.sku);
      final desc = product.description != null
          ? _normalizeSearch(product.description!)
          : '';
      final barcode = product.barcode != null
          ? _normalizeSearch(product.barcode!)
          : '';

      return name.contains(searchTerm) ||
          sku.contains(searchTerm) ||
          desc.contains(searchTerm) ||
          barcode.contains(searchTerm) ||
          barcode == searchTerm ||
          sku == searchTerm;
    }).toList();
  }

  Future<void> _loadProducts() async {
    if (_getProductsUseCase == null) {
      print('⚠️ GetProductsUseCase no disponible - no se cargarán productos');
      // No limpiar — preservar lo que pueda haber de un load anterior.
      _isLoadingProducts.value = false;
      return;
    }

    _isLoadingProducts.value = true;

    // ═══════════════════════════════════════════════════════════════════
    // PASO 1 — CACHE-FIRST: poblar _availableProducts desde ISAR YA.
    // Si la app está offline, si el servidor está caído, o si el usuario
    // tiene red lenta, al menos tiene los productos cacheados en memoria
    // para que search/selectores funcionen de inmediato.
    // ═══════════════════════════════════════════════════════════════════
    await _loadProductsFromCacheFirst();

    // ═══════════════════════════════════════════════════════════════════
    // PASO 2 — Background refresh desde el servidor.
    // Si triunfa: actualiza con datos frescos.
    // Si falla (timeout, sin red, servidor caído): NO se limpia el cache.
    // ═══════════════════════════════════════════════════════════════════
    try {
      print('📦 Refrescando productos desde servidor (background)...');
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await _getProductsUseCase!(
            const GetProductsParams(
              page: 1,
              limit: 50,
              status: ProductStatus.active,
              includePrices: true,
            ),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⚠️ Timeout refrescando productos — usando cache');
              return Left(ServerFailure('Timeout al cargar productos'));
            },
          );

      await Future.delayed(const Duration(milliseconds: 10));

      result.fold(
        (failure) {
          // Cache-first ya pobló los productos; log y seguimos con lo que hay.
          print('❌ Remoto falló: ${failure.message} — conservando cache '
              '(${_availableProducts.length} productos en memoria)');
        },
        (paginatedResult) {
          _availableProducts.value = paginatedResult.data;
          print('✅ Productos refrescados: ${paginatedResult.data.length}');

          if (paginatedResult.data.length == 50 &&
              paginatedResult.meta.hasNextPage) {
            _loadMoreProductsSlowly(2);
          }
        },
      );
    } catch (e) {
      print('💥 Error refrescando productos: $e — conservando cache '
          '(${_availableProducts.length} productos)');
      // NO hacemos clear — el cache cargado en el paso 1 queda disponible.
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  /// Carga productos DIRECTO desde ISAR sin pasar por el UseCase (que tiene
  /// timeout a nivel de controller). Esto garantiza que el form arranque
  /// con los productos cacheados aunque la red esté caída o lenta.
  Future<void> _loadProductsFromCacheFirst() async {
    try {
      if (!Get.isRegistered<ProductRepository>()) {
        print('⚠️ ProductRepository no registrado — salto cache-first');
        return;
      }
      final repo = Get.find<ProductRepository>();
      // El repo expone getCachedProducts() que lee directo de ISAR/cache
      // sin tocar red — offline-first real, sin timeouts ni excepciones de red.
      final cacheResult = await repo.getCachedProducts();
      cacheResult.fold(
        (failure) {
          print('⚠️ Cache vacío o falló: ${failure.message}');
        },
        (products) {
          if (products.isNotEmpty) {
            // Solo productos activos (UX consistente con el search)
            final activos = products
                .where((p) => p.status == ProductStatus.active)
                .toList();
            _availableProducts.value = activos;
            print('✅ Cache-first: ${activos.length} productos disponibles '
                'offline inmediatamente');
          }
        },
      );
    } catch (e) {
      print('⚠️ Error cache-first: $e — continuará con remoto');
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
    print('🔍 Búsqueda clientes OFFLINE: "$query" '
        '(_availableCustomers=${_availableCustomers.length})');

    if (query.trim().isEmpty) return [];

    try {
      // Mismo patrón que productos: ISAR directo via offline repo. NO
      // golpea el API. Resultados idénticos online u offline, sin caps.
      List<Customer> results = const [];

      if (Get.isRegistered<CustomerOfflineRepository>()) {
        final isarSearch = await Get.find<CustomerOfflineRepository>()
            .searchCustomers(query, limit: null);
        isarSearch.fold(
          (failure) => print('⚠️ ISAR customer search falló: ${failure.message}'),
          (list) => results = list,
        );
        print('📦 ISAR retornó ${results.length} clientes');
      }

      // Fallback defensivo si por algún motivo el offline repo no está.
      if (results.isEmpty) {
        results = _searchInLocalCustomers(query);
        print('💾 Fallback memoria: ${results.length} clientes');
      }

      final filteredResults = results
          .where((customer) => customer.status == CustomerStatus.active)
          .toList();

      print('✅ Búsqueda devolvió ${filteredResults.length} clientes activos');
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
    _clearUpdatedItemSelection(); // ✅ NUEVO: Limpiar selección
    _recalculateTotals();
    print('🧹 Todos los items removidos');
  }

  // ✅ NUEVO: Método para limpiar la selección de item actualizado
  void _clearUpdatedItemSelection() {
    _lastUpdatedItemIndex.value = null;
    _shouldHighlightUpdatedItem.value = false;
  }

  // ==================== DATE MANAGEMENT ====================

  void setInvoiceDate(DateTime date) {
    // Preservar hora actual si el DatePicker devuelve solo fecha (hora 00:00:00)
    if (date.hour == 0 && date.minute == 0 && date.second == 0) {
      try {
        final dtService = Get.find<TenantDateTimeService>();
        final now = dtService.now();
        date = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
      } catch (_) {
        final now = DateTime.now();
        date = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
      }
    }
    _invoiceDate.value = date;
    final daysDifference = _dueDate.value.difference(_invoiceDate.value).inDays;
    if (daysDifference < 1) {
      _dueDate.value = DateTime(date.year, date.month, date.day).add(const Duration(days: 30));
    }
    print('📅 Fecha de factura: $date');
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
    // ✅ Recalcular IVA promedio cuando cambian los items
    _recalculateAverageTaxPercentage();
    update();
  }

  // ==================== PAYMENT & SAVE ====================

  // ✅ MÉTODO PRINCIPAL ACTUALIZADO CON IMPRESIÓN, CUENTA BANCARIA Y PAGOS MÚLTIPLES
  Future<bool> saveInvoiceWithPayment(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status,
    bool shouldPrint, {
    String? bankAccountId,
    List<MultiplePaymentData>? multiplePayments,
    bool createCreditForRemaining = false,
    double? balanceApplied,
    // Multi-moneda
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
  }) async {
    if (!_validateForm()) return false;

    // Phase 2: bloquear venta en efectivo si NO hay caja abierta.
    // Aplica si el método principal es cash O si entre los pagos
    // múltiples hay alguno en efectivo.
    final hasCashPayment = paymentMethod == PaymentMethod.cash ||
        (multiplePayments?.any((p) => p.method == PaymentMethod.cash) ??
            false);
    if (hasCashPayment) {
      final blocked = await _ensureCashRegisterOpenOrPrompt();
      if (blocked) return false;
    }

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
      print('   - Debe imprimir: $shouldPrint');
      print('   - Pagos múltiples: ${multiplePayments?.length ?? 0}');
      print('   - Crear crédito por saldo: $createCreditForRemaining');
      print('   - Saldo a favor aplicado: \${balanceApplied?.toStringAsFixed(2) ?? "0.00"}');

      _paymentMethod.value = paymentMethod;

      // ✅ CONSTRUIR NOTAS CON INFORMACIÓN DE PAGOS MÚLTIPLES
      final paymentInfo = multiplePayments != null && multiplePayments.isNotEmpty
          ? _buildMultiplePaymentNotes(multiplePayments, status, createCreditForRemaining)
          : _buildPaymentNotes(receivedAmount, change, status);
      notesController.text = paymentInfo;

      _adjustDueDateByPaymentMethod(paymentMethod, status);

      print('📅 Fecha de vencimiento ajustada: ${_dueDate.value}');
      print('📝 Notas generadas: ${paymentInfo.length} caracteres');
      if (bankAccountId != null) {
        print('🏦 Cuenta bancaria seleccionada: $bankAccountId');
      }
      if (multiplePayments != null && multiplePayments.isNotEmpty) {
        for (final payment in multiplePayments) {
          print('💳 Pago: ${payment.method.displayName} - \$${payment.amount.toStringAsFixed(2)}');
        }
      }

      Invoice? savedInvoice;

      if (isEditMode) {
        print('✏️ Actualizando factura existente...');
        savedInvoice = await _updateExistingInvoice(status);
      } else {
        print('➕ Creando nueva factura...');
        savedInvoice = await _createNewInvoice(
          status,
          bankAccountId: bankAccountId,
          multiplePayments: multiplePayments,
          createCreditForRemaining: createCreditForRemaining,
          balanceApplied: balanceApplied,
          paymentCurrency: paymentCurrency,
          paymentCurrencyAmount: paymentCurrencyAmount,
          exchangeRate: exchangeRate,
        );
      }

      // ✅ VALIDAR SI LA FACTURA SE GUARDÓ CORRECTAMENTE
      print('🔍 DEBUG: Validando si savedInvoice es null...');
      print('🔍 savedInvoice == null: ${savedInvoice == null}');
      print('🔍 savedInvoice: $savedInvoice');

      if (savedInvoice != null) {
        // ✅ NUEVA LÓGICA: IMPRIMIR SI SE SOLICITÓ
        if (shouldPrint) {
          print('🖨️ Iniciando impresión automática...');
          await _printInvoiceAutomatically(savedInvoice);
        }

        print('✅ === FACTURA GUARDADA EXITOSAMENTE ===');
        print('🎉 RETORNANDO TRUE - OPERACIÓN EXITOSA');

        // Phase 2: refrescar Caja Registradora si está abierta. La venta
        // en efectivo afecta el "esperado" del turno actual; el badge del
        // AppBar y la pantalla de caja deben reflejar el cambio inmediato
        // sin esperar al auto-refresh de 60s.
        try {
          if (Get.isRegistered<CashRegisterController>()) {
            Get.find<CashRegisterController>().loadCurrent(silent: true);
          }
        } catch (_) {}

        // ✅ NO MOSTRAR SNACKBAR AQUÍ - LA PANTALLA LO MOSTRARÁ
        return true; // ✅ ÉXITO
      } else {
        print('❌ === FACTURA NO GUARDADA - OPERACIÓN BLOQUEADA ===');
        print('🚫 RETORNANDO FALSE - OPERACIÓN FALLÓ');
        return false; // ✅ FALLÓ
      }
    } catch (e) {
      print('💥 Error inesperado al guardar: $e');
      _showError('Error inesperado', 'No se pudo procesar la venta');
      return false; // ✅ ERROR
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

      // ✅ NUEVO: Asegurar que la configuración de impresora esté cargada
      print('🔄 Verificando configuración de impresora antes de imprimir...');
      final printerConfigLoaded =
          await _thermalPrinterController.ensurePrinterConfigLoaded();

      if (!printerConfigLoaded) {
        print(
          '❌ No se pudo cargar configuración de impresora',
        );
        _showPrintError(
          'No hay impresora configurada. Configura una en Configuración > Impresoras.',
        );
        return;
      }

      // Usar el controlador de impresión térmica
      final success = await _thermalPrinterController.printInvoice(invoice);

      if (success) {
        print('✅ Impresión automática exitosa');
        //_showPrintSuccess('Factura impresa exitosamente');
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

      // Asegurar que la configuración de impresora esté cargada
      final printerConfigLoaded =
          await _thermalPrinterController.ensurePrinterConfigLoaded();
      if (!printerConfigLoaded) {
        _showPrintError(
          'No hay impresora configurada. Configura una en Configuración > Impresoras.',
        );
        return;
      }

      final success = await _thermalPrinterController.printInvoice(invoice);

      if (success) {
        //_showPrintSuccess('Factura impresa exitosamente');
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

  /// Ajusta la fecha de vencimiento según el método de pago y estado
  ///
  /// Reglas de negocio:
  /// - Borrador: +30 días
  /// - Pagos inmediatos (efectivo, tarjeta, transferencia): mismo día (fin del día)
  /// - Crédito: según términos del cliente o 30 días
  /// - Cheque: +15 días
  /// - Pago parcial: se ajustará en backend con +30 días para el saldo
  void _adjustDueDateByPaymentMethod(
    PaymentMethod method,
    InvoiceStatus status,
  ) {
    // Para borradores, siempre 30 días
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
      case PaymentMethod.clientBalance:
        // Para pagos inmediatos: mismo día (el backend ajustará al final del día)
        // Si hay pago parcial, el backend extenderá la fecha para el saldo
        _dueDate.value = _invoiceDate.value;
        break;

      case PaymentMethod.credit:
        // Crédito: usar términos del cliente o 30 días por defecto
        final creditDays = selectedCustomer?.paymentTerms ?? 30;
        _dueDate.value = _invoiceDate.value.add(Duration(days: creditDays));
        break;

      case PaymentMethod.check:
        // Cheque: 15 días para permitir cobro
        _dueDate.value = _invoiceDate.value.add(const Duration(days: 15));
        break;

      case PaymentMethod.other:
        // Otro: usar términos del cliente o 30 días
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
      buffer.writeln('IVA ($taxPercentage%): \$${format.format(taxAmount)}');
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

    buffer.writeln('Fecha: ${AppFormatters.formatDateTime(Get.find<TenantDateTimeService>().now())}');
    buffer.writeln('Cliente: ${selectedCustomer?.displayName ?? 'N/A'}');

    if (notesController.text.isNotEmpty &&
        !notesController.text.contains('INFORMACIÓN DE')) {
      buffer.writeln('\n=== NOTAS ADICIONALES ===');
      buffer.writeln(notesController.text);
    }

    return buffer.toString();
  }

  /// ✅ NUEVO: Construir notas para pagos múltiples
  String _buildMultiplePaymentNotes(
    List<MultiplePaymentData> payments,
    InvoiceStatus status,
    bool createCreditForRemaining,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Estado: ${status.displayName.toUpperCase()}');

    // Calcular totales de pagos
    double totalPaid = 0;
    for (final payment in payments) {
      totalPaid += payment.amount;
    }
    final remaining = total - totalPaid;

    buffer.writeln('=== PAGOS MÚLTIPLES ===');

    for (int i = 0; i < payments.length; i++) {
      final payment = payments[i];
      final bankInfo = payment.bankAccountName != null
          ? ' (${payment.bankAccountName})'
          : '';
      buffer.writeln(
        'Pago ${i + 1}: ${payment.method.displayName}$bankInfo - \$${format.format(payment.amount)}',
      );
    }

    buffer.writeln('------------------------');
    buffer.writeln('Subtotal sin IVA: \$${format.format(subtotalWithoutTax)}');

    if (totalDiscountAmount > 0) {
      buffer.writeln('Descuento: \$${totalDiscountAmount.toStringAsFixed(2)}');
    }

    if (taxAmount > 0) {
      buffer.writeln('IVA ($taxPercentage%): \$${format.format(taxAmount)}');
    }

    buffer.writeln('TOTAL FACTURA: \$${format.format(total)}');
    buffer.writeln('TOTAL PAGADO: \$${format.format(totalPaid)}');

    if (remaining > 0) {
      if (createCreditForRemaining) {
        buffer.writeln('CRÉDITO GENERADO: \$${format.format(remaining)}');
        buffer.writeln(
          'Vencimiento crédito: ${_dueDate.value.toString().split(' ')[0]}',
        );
      } else {
        buffer.writeln('SALDO PENDIENTE: \$${format.format(remaining)}');
      }
    } else if (remaining < 0) {
      buffer.writeln('CAMBIO: \$${format.format(remaining.abs())}');
    }

    buffer.writeln('------------------------');
    buffer.writeln('Fecha: ${AppFormatters.formatDateTime(Get.find<TenantDateTimeService>().now())}');
    buffer.writeln('Cliente: ${selectedCustomer?.displayName ?? 'N/A'}');

    if (notesController.text.isNotEmpty &&
        !notesController.text.contains('PAGOS MÚLTIPLES')) {
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

  // ✅ MODIFICADO: Retornar la factura creada con cuenta bancaria y pagos múltiples
  Future<Invoice?> _createNewInvoice(
    InvoiceStatus status, {
    String? bankAccountId,
    List<MultiplePaymentData>? multiplePayments,
    bool createCreditForRemaining = false,
    double? balanceApplied,
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
  }) async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    // Usa validación ASYNC que consulta ISAR si no hay datos en memoria (offline)
    final canCreate = await SubscriptionValidationService.canCreateInvoiceAsync();
    if (!canCreate) {
      print(
        '🚫 FRONTEND BLOCK: Suscripción expirada o sin datos - BLOQUEANDO creación de factura',
      );
      return null; // Bloquear operación
    }

    print(
      '✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con creación de factura',
    );

    // 🔍 VALIDAR Y RESOLVER CLIENTE ANTES DE CREAR FACTURA
    final validCustomer = await _ensureValidCustomer();
    if (validCustomer == null) {
      print('❌ No se pudo obtener un cliente válido para crear la factura');
      _showError(
        'Cliente "Consumidor Final" requerido',
        'Crea un cliente "Consumidor Final" con documento "222222222222" en la sección de clientes antes de crear facturas.',
      );
      return null;
    }

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
                presentationId: item.presentationId,
              ),
            )
            .toList();

    // ✅ CONSTRUIR METADATA CON INFORMACIÓN DE PAGOS MÚLTIPLES Y SALDO APLICADO
    Map<String, dynamic>? invoiceMetadata;

    // 💰 NUEVO: Incluir saldo a favor aplicado en metadata
    if (balanceApplied != null && balanceApplied > 0) {
      invoiceMetadata = {
        'clientBalanceApplied': balanceApplied,
        'clientId': validCustomer.id,
      };
      print('💰 Saldo a favor aplicado: \$${balanceApplied.toStringAsFixed(2)}');
    }

    // Incluir info de moneda del pago simple en metadata
    if (paymentCurrency != null && multiplePayments == null) {
      invoiceMetadata = {
        ...?invoiceMetadata,
        'paymentCurrency': paymentCurrency,
        'paymentCurrencyAmount': paymentCurrencyAmount,
        'exchangeRate': exchangeRate,
      };
      print('💱 Pago en moneda extranjera: $paymentCurrencyAmount $paymentCurrency (tasa: $exchangeRate)');
    }

    // Para facturas a crédito puro, señalar que se debe generar CustomerCredit
    if (paymentMethod == PaymentMethod.credit && status == InvoiceStatus.pending) {
      invoiceMetadata = {
        ...?invoiceMetadata,
        'createCreditForRemaining': true,
        'remainingBalance': total,
        'isPureCreditInvoice': true,
      };
      print('📝 Factura a crédito puro - metadata configurada para generar crédito por \$${total.toStringAsFixed(2)}');
    }

    if (multiplePayments != null && multiplePayments.isNotEmpty) {
      // Calcular total pagado y saldo restante
      double totalPaid = 0;
      for (final payment in multiplePayments) {
        totalPaid += payment.amount;
      }
      // ✅ Considerar el saldo aplicado para el cálculo del restante
      final effectiveTotal = total - (balanceApplied ?? 0);
      final remaining = effectiveTotal - totalPaid;

      invoiceMetadata = {
        ...?invoiceMetadata,
        'multiplePayments': multiplePayments.map((p) {
          return <String, dynamic>{
            'amount': p.amount,
            'method': p.method.value,
            'bankAccountId': p.bankAccountId,
            'bankAccountName': p.bankAccountName,
            if (p.paymentCurrency != null) 'paymentCurrency': p.paymentCurrency,
            if (p.paymentCurrencyAmount != null) 'paymentCurrencyAmount': p.paymentCurrencyAmount,
            if (p.exchangeRate != null) 'exchangeRate': p.exchangeRate,
          };
        }).toList(),
        'totalPaid': totalPaid,
        'remainingBalance': remaining > 0 ? remaining : 0,
        'createCreditForRemaining': createCreditForRemaining && remaining > 0,
        'isMultiplePayment': true,
      };
      print('💳 Metadata de pagos múltiples creada:');
      print('   - Total factura: \$${total.toStringAsFixed(2)}');
      print('   - Saldo aplicado: \$${balanceApplied?.toStringAsFixed(2) ?? "0.00"}');
      print('   - Total efectivo: \$${effectiveTotal.toStringAsFixed(2)}');
      print('   - Total pagado: \$${totalPaid.toStringAsFixed(2)}');
      print('   - Saldo restante: \$${remaining > 0 ? remaining.toStringAsFixed(2) : "0.00"}');
      print('   - Crear crédito: $createCreditForRemaining');
      print('   - Número de pagos: ${multiplePayments.length}');
      for (var i = 0; i < multiplePayments.length; i++) {
        final p = multiplePayments[i];
        print('   - Pago ${i + 1}: \$${p.amount.toStringAsFixed(2)} via ${p.method.name} (cuenta: ${p.bankAccountName ?? "N/A"})');
      }
    }

    final result = await _createInvoiceUseCase(
      CreateInvoiceParams(
        customerId: validCustomer.id,
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
        bankAccountId: bankAccountId, // 🏦 Cuenta bancaria para registrar el pago
        metadata: invoiceMetadata, // 💳 Información de pagos múltiples
      ),
    );

    return result.fold(
      (failure) {
        print('💥 _createNewInvoice FAILED: ${failure.message}');
        print('💥 Failure code: ${failure.code}');
        print('💥 Retornando NULL por error');

        // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
        final handled = SubscriptionErrorHandler.handleFailure(
          failure,
          context: 'crear factura',
        );

        if (!handled) {
          // Solo mostrar error genérico si no fue un error de suscripción
          _showError('Error al procesar venta', failure.message);
        }
        return null;
      },
      (invoice) async {
        print(
          '✅ _createNewInvoice SUCCESS: Factura creada con ID ${invoice.id}',
        );

        // ✅ PROCESAR INVENTARIO AUTOMÁTICAMENTE (si el servicio está disponible)
        if (_inventoryService != null) {
          try {
            final inventoryProcessed = await _inventoryService!
                .processInventoryForInvoice(invoice);
            if (inventoryProcessed) {
              print(
                '✅ Inventario procesado exitosamente para factura ${invoice.number}',
              );
            } else {
              print('⚠️ Inventario no procesado (configuración o error)');
            }
          } catch (e) {
            print('❌ Error procesando inventario: $e');
          }
        } else {
          print('ℹ️ Inventario no procesado (servicio no disponible)');
        }

        // 📊 Notificar al dashboard para que actualice sus datos
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().refreshAll();
          }
        } catch (_) {}

        print('✅ Preparando para nueva venta...');
        _prepareForNewSale();
        return invoice; // ✅ RETORNAR LA FACTURA CREADA
      },
    );
  }

  // ✅ MODIFICADO: Retornar la factura actualizada
  Future<Invoice?> _updateExistingInvoice(InvoiceStatus status) async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    // Usa validación ASYNC que consulta ISAR si no hay datos en memoria (offline)
    final canUpdate = await SubscriptionValidationService.canUpdateInvoiceAsync();
    if (!canUpdate) {
      print(
        '🚫 FRONTEND BLOCK: Suscripción expirada o sin datos - BLOQUEANDO actualización de factura',
      );
      return null; // Bloquear operación
    }

    print(
      '✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con actualización de factura',
    );

    // 🔍 VALIDAR Y RESOLVER CLIENTE ANTES DE ACTUALIZAR FACTURA
    final validCustomer = await _ensureValidCustomer();
    if (validCustomer == null) {
      print(
        '❌ No se pudo obtener un cliente válido para actualizar la factura',
      );
      _showError(
        'Cliente "Consumidor Final" requerido',
        'Crea un cliente "Consumidor Final" con documento "222222222222" en la sección de clientes antes de actualizar facturas.',
      );
      return null;
    }

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
                presentationId: item.presentationId,
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
        customerId: validCustomer.id,
        items: items,
      ),
    );

    return result.fold(
      (failure) {
        // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
        final handled = SubscriptionErrorHandler.handleFailure(
          failure,
          context: 'editar factura',
        );

        if (!handled) {
          // Solo mostrar error genérico si no fue un error de suscripción
          _showError('Error al actualizar factura', failure.message);
        }
        return null;
      },
      (invoice) {
        // Navegar primero, luego snackbar (se muestra en el listado)
        Get.back(result: invoice);
        _showSuccessWithStatus('Factura actualizada exitosamente', status);
        return invoice; // ✅ RETORNAR LA FACTURA ACTUALIZADA
      },
    );
  }

  void clearFormForNewSale() {
    _prepareForNewSale();
  }

  void _prepareForNewSale() {
    final dtService = Get.find<TenantDateTimeService>();
    _invoiceItems.clear();
    _loadDefaultCustomer();
    _invoiceDate.value = dtService.now();
    _dueDate.value = dtService.now();
    notesController.clear();
    termsController.text = 'Venta de contado';
    _taxPercentage.value = 0.0; // Se establecerá desde el primer producto agregado
    _discountPercentage.value = 0.0;
    _discountAmount.value = 0.0;
    _recalculateTotals();

    // ✅ Refresca _availableProducts desde ISAR fire-and-forget. La factura
    // recién creada descontó stock en ISAR (vía _processInventoryForOfflineInvoice
    // o backend al sincronizar online), pero la lista en memoria aún tenía
    // los stocks viejos cargados al inicio del POS. Sin este refresh, la
    // siguiente búsqueda muestra cantidades obsoletas.
    unawaited(_loadProductsFromCacheFirst());

    print('🔄 Formulario preparado para nueva venta');
  }

  void clearForm() {
    notesController.clear();
    termsController.text = _getDefaultTerms();

    final dtService = Get.find<TenantDateTimeService>();
    _selectedCustomer.value = null;
    _invoiceItems.clear();
    _invoiceDate.value = dtService.now();
    _dueDate.value = dtService.now().add(const Duration(days: 30));
    _paymentMethod.value = PaymentMethod.cash;
    _taxPercentage.value = 0.0; // Se establecerá desde el primer producto agregado
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
      '🎯 Producto Actualizado',
      '$productName → ${AppFormatters.formatStock(newQuantity)} unidades',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: Icon(Icons.trending_up, color: Colors.green.shade600, size: 24),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderColor: Colors.green.shade300,
      borderWidth: 1.5,
      borderRadius: 12,
      shouldIconPulse: true,
      animationDuration: const Duration(milliseconds: 400),
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

  /// Phase 2: bloqueo de ventas en efectivo cuando no hay caja abierta.
  ///
  /// Devuelve `true` si la operación debe abortar (no se permite),
  /// `false` si puede continuar (caja abierta o usuario decide ignorar
  /// — futuro setting `requireCashRegister`).
  ///
  /// Si la caja está cerrada, muestra un diálogo modal explicando la
  /// regla con un botón directo "Ir a abrir caja".
  Future<bool> _ensureCashRegisterOpenOrPrompt() async {
    // Si el tenant tiene el módulo de caja apagado en settings, no
    // exigimos caja abierta — facturación con efectivo funciona normal,
    // los pagos cash se registran en `payments` igual. Esto es lo que
    // permite que clientes "sin caja" facturen sin restricciones.
    if (Get.isRegistered<OrganizationController>() &&
        !Get.find<OrganizationController>().isCashRegisterEnabled) {
      return false;
    }

    if (!Get.isRegistered<CashRegisterController>()) return false;
    final ctrl = Get.find<CashRegisterController>();
    // Refrescar el estado por si está stale (silencioso, sin loading visible).
    await ctrl.loadCurrent(silent: true);
    if (ctrl.hasOpenRegister) return false; // OK, hay caja abierta

    // Caja CERRADA — dialog con opción de abrir INLINE (sin navegar),
    // para no perder los ítems del carrito si el usuario eligió abrir.
    final shouldOpen = await Get.dialog<bool>(
      AlertDialog(
        icon: Icon(Icons.point_of_sale_rounded,
            color: Colors.amber.shade700, size: 36),
        title: const Text('Caja cerrada'),
        content: const Text(
          'No hay una caja abierta en este momento. Para registrar ventas '
          'en efectivo necesitas abrir la caja primero (declarar el saldo '
          'inicial del turno).\n\n'
          'Si pagas con tarjeta o transferencia, puedes guardar la factura '
          'sin caja — solo se bloquean los pagos en efectivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text('Abrir caja ahora'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (shouldOpen == true) {
      // Abrir dialog INLINE — no navega, no perdemos los ítems del
      // carrito. Si el usuario completa la apertura, retornamos false
      // (no bloqueado) y el flujo de procesar venta sigue.
      final ctx = Get.context;
      if (ctx != null) {
        final opened = await showOpenCashRegisterDialog(ctx);
        if (opened) return false; // caja recién abierta → continuar
      }
    }
    return true; // bloquea el guardado
  }
}
