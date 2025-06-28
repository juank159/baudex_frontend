// lib/features/invoices/presentation/controllers/invoice_form_controller.dart
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

// Presentation models
import 'package:baudex_desktop/features/invoices/data/models/invoice_form_models.dart';

class InvoiceFormController extends GetxController {
  // ==================== DEPENDENCIES ====================

  final CreateInvoiceUseCase _createInvoiceUseCase;
  final UpdateInvoiceUseCase _updateInvoiceUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;
  final GetCustomersUseCase? _getCustomersUseCase;
  final SearchCustomersUseCase? _searchCustomersUseCase;
  final GetProductsUseCase? _getProductsUseCase;
  final SearchProductsUseCase? _searchProductsUseCase;
  final GetCustomerByIdUseCase? _getCustomerByIdUseCase;

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
  }
  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isLoadingCustomers = false.obs;
  final _isLoadingProducts = false.obs;

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
      // El precio unitario ya tiene IVA, calculamos el valor sin IVA
      final priceWithoutTax = item.unitPrice / (1 + (taxPercentage / 100));
      final itemSubtotal = item.quantity * priceWithoutTax;

      // Aplicar descuentos al subtotal sin IVA
      final percentageDiscount = (itemSubtotal * item.discountPercentage) / 100;
      final totalDiscount = percentageDiscount + item.discountAmount;

      return sum + (itemSubtotal - totalDiscount);
    });
  }

  double get subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.subtotal);
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
    print('🚀 InvoiceFormController: Inicializando punto de venta...');
    _initializeForm();
    _loadInitialData();
  }

  @override
  void onClose() {
    print('🔚 InvoiceFormController: Liberando recursos...');
    _disposeControllers();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeForm() {
    // ✅ Cargar cliente final real desde la base de datos
    _loadDefaultCustomer();

    // Fechas automáticas
    _invoiceDate.value = DateTime.now();
    _dueDate.value = DateTime.now(); // Venta inmediata

    // Términos por defecto simples
    termsController.text = 'Venta de contado';

    // Verificar si es modo edición
    final invoiceId = Get.parameters['id'];
    if (invoiceId != null && invoiceId.isNotEmpty) {
      _isEditMode.value = true;
      _editingInvoiceId.value = invoiceId;
      _loadInvoiceForEdit(invoiceId);
    }
  }

  void debugPriceCalculations() {
    print('🧮 DEBUG Cálculos de Precios:');
    print('   - Subtotal con IVA: \$${subtotal.toStringAsFixed(2)}');
    print('   - Subtotal sin IVA: \$${subtotalWithoutTax.toStringAsFixed(2)}');
    print('   - Descuentos: \$${totalDiscountAmount.toStringAsFixed(2)}');
    print('   - Monto gravable: \$${taxableAmount.toStringAsFixed(2)}');
    print('   - IVA (${taxPercentage}%): \$${taxAmount.toStringAsFixed(2)}');
    print('   - TOTAL: \$${total.toStringAsFixed(2)}');
  }

  /// ✅ CARGAR CLIENTE FINAL REAL DESDE BASE DE DATOS
  Future<void> _loadDefaultCustomer() async {
    try {
      print('🔍 Cargando cliente final desde BD: $DEFAULT_CUSTOMER_ID');

      if (_getCustomerByIdUseCase != null) {
        print('✅ GetCustomerByIdUseCase disponible, realizando consulta...');

        final result = await _getCustomerByIdUseCase!(
          GetCustomerByIdParams(id: DEFAULT_CUSTOMER_ID),
        );

        result.fold(
          (failure) {
            print('❌ Error cargando cliente final: ${failure.toString()}');
            print('🔄 Usando cliente fallback...');
            _setFallbackDefaultCustomer();
          },
          (customer) {
            _selectedCustomer.value = customer;
            print('✅ Cliente final cargado exitosamente:');
            print('   - ID: ${customer.id}');
            print('   - Nombre: ${customer.displayName}');
            print('   - Email: ${customer.email}');
          },
        );
      } else {
        print('❌ GetCustomerByIdUseCase NO disponible');
        print('🔄 Usando cliente fallback...');
        _setFallbackDefaultCustomer();
      }
    } catch (e) {
      print('💥 Error inesperado cargando cliente final: $e');
      print('🔄 Usando cliente fallback...');
      _setFallbackDefaultCustomer();
    }
  }

  void _setFallbackDefaultCustomer() {
    // ✅ USAR EL MISMO ID DEL CLIENTE REAL COMO FALLBACK
    final fallbackCustomer = Customer(
      id: DEFAULT_CUSTOMER_ID, // ✅ CAMBIO IMPORTANTE: Usar el ID real
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

  Future<void> _loadInitialData() async {
    await Future.wait([_loadCustomers(), _loadProducts()]);
  }

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
    // Información básica
    _invoiceDate.value = invoice.date;
    _dueDate.value = invoice.dueDate;
    _paymentMethod.value = invoice.paymentMethod;
    _taxPercentage.value = invoice.taxPercentage;
    _discountPercentage.value = invoice.discountPercentage;
    _discountAmount.value = invoice.discountAmount;
    notesController.text = invoice.notes ?? '';
    termsController.text = invoice.terms ?? '';

    // Cliente
    _selectedCustomer.value = invoice.customer;

    // Items
    _invoiceItems.value =
        invoice.items
            .map((item) => InvoiceItemFormData.fromEntity(item))
            .toList();
  }
  // ==================== PRODUCTOS - FUNCIONALIDAD PRINCIPAL ====================

  void addOrUpdateProductToInvoice(Product product, {double quantity = 1}) {
    print('🛒 Procesando producto: ${product.name} (cantidad: $quantity)');

    // Verificar stock antes de agregar
    if (product.stock <= 0) {
      _showError('Sin Stock', '${product.name} no tiene stock disponible');
      return;
    }

    // ✅ ASEGURAR QUE EL PRODUCTO ESTÉ EN LA LISTA DE DISPONIBLES
    _ensureProductIsAvailable(product);

    // ✅ OBTENER PRECIO AL PÚBLICO (PRICE1) POR DEFECTO
    final defaultPrice = product.getPriceByType(PriceType.price1);
    final unitPrice = defaultPrice?.finalAmount ?? product.sellingPrice ?? 0;

    if (unitPrice <= 0) {
      _showError('Sin Precio', '${product.name} no tiene precio configurado');
      return;
    }

    // Buscar si el producto ya existe en la factura
    final existingIndex = _invoiceItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // PRODUCTO EXISTENTE: Sumar cantidades
      final existingItem = _invoiceItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Verificar que no exceda el stock disponible
      if (newQuantity > product.stock) {
        _showError(
          'Stock Insuficiente',
          'Solo hay ${product.stock} unidades disponibles de ${product.name}',
        );
        return;
      }

      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      _invoiceItems[existingIndex] = updatedItem;

      print(
        '✅ Cantidad actualizada: ${existingItem.description} -> $newQuantity',
      );
      _showProductUpdatedMessage(product.name, newQuantity);
    } else {
      // PRODUCTO NUEVO: Agregar a la lista
      if (quantity > product.stock) {
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
        unitPrice: unitPrice, // ✅ Precio al público por defecto
        unit: product.unit ?? 'pcs',
        productId: product.id,
      );

      _invoiceItems.add(newItem);
      print(
        '➕ Producto agregado: ${product.name} - Precio: \$${unitPrice.toStringAsFixed(2)}',
      );
      _showProductAddedMessage(product.name);
    }

    _recalculateTotals();
  }

  void _ensureProductIsAvailable(Product product) {
    final existingIndex = _availableProducts.indexWhere(
      (p) => p.id == product.id,
    );

    if (existingIndex == -1) {
      // Si no está en la lista, agregarlo
      _availableProducts.add(product);
      print('📦 Producto agregado a lista disponible: ${product.name}');
    } else {
      // Si está pero puede estar desactualizado, actualizarlo
      _availableProducts[existingIndex] = product;
      print('📦 Producto actualizado en lista disponible: ${product.name}');
    }
  }

  /// Búsqueda mejorada: Por código de barras y nombre
  Future<List<Product>> searchProducts(String query) async {
    print('🔍 Iniciando búsqueda de productos: "$query"');

    if (query.trim().isEmpty) return [];

    try {
      List<Product> results = [];

      // 1. Primero buscar por código de barras exacto
      final barcodeMatch = await _searchByBarcode(query);
      if (barcodeMatch != null) {
        results.add(barcodeMatch);
        print('✅ Encontrado por código de barras: ${barcodeMatch.name}');
      }

      // 2. Buscar por SKU exacto
      final skuMatch = await _searchBySku(query);
      if (skuMatch != null && !results.any((p) => p.id == skuMatch.id)) {
        results.add(skuMatch);
        print('✅ Encontrado por SKU: ${skuMatch.name}');
      }

      // 3. Búsqueda general por nombre si no hay coincidencias exactas
      if (results.isEmpty) {
        if (_searchProductsUseCase != null) {
          final searchResult = await _searchProductsUseCase!(
            SearchProductsParams(searchTerm: query, limit: 20),
          );

          searchResult.fold(
            (failure) {
              print('❌ Error en búsqueda de productos: ${failure.message}');
              // Fallback a búsqueda local
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
          print('⚠️ SearchProductsUseCase no disponible');
          // Fallback a búsqueda local
          results.addAll(_searchInLocalProducts(query));
        }
      }

      // Eliminar duplicados y filtrar solo productos activos con stock
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
      return [];
    }
  }

  /// Búsqueda por código de barras exacto
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

  /// Búsqueda por SKU exacto
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

  /// Búsqueda local en productos cargados
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
      return;
    }

    try {
      _isLoadingProducts.value = true;
      print('📦 Cargando productos desde la base de datos...');

      final result = await _getProductsUseCase!(
        const GetProductsParams(
          page: 1,
          limit: 100,
          status: ProductStatus.active,
          includePrices: true,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar productos: ${failure.message}');
          _showError('Error al cargar productos', failure.message);
          _availableProducts.clear();
        },
        (paginatedResult) {
          _availableProducts.value = paginatedResult.data;
          print('✅ Productos cargados: ${paginatedResult.data.length}');

          // Si hay más productos disponibles, cargar más páginas
          if (paginatedResult.data.length == 100 &&
              paginatedResult.meta.hasNextPage) {
            _loadMoreProducts(2);
          }
        },
      );
    } catch (e) {
      print('💥 Error al cargar productos: $e');
      _showError('Error inesperado', 'No se pudieron cargar los productos');
      _availableProducts.clear();
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  Future<void> _loadMoreProducts(int page) async {
    if (_getProductsUseCase == null) return;

    try {
      final result = await _getProductsUseCase!(
        GetProductsParams(
          page: page,
          limit: 100,
          status: ProductStatus.active,
          includePrices: true,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error cargando página $page: ${failure.message}');
        },
        (paginatedResult) {
          // Agregar productos a la lista existente
          _availableProducts.addAll(paginatedResult.data);
          print(
            '✅ Productos página $page cargados: ${paginatedResult.data.length}',
          );

          // Continuar cargando si hay más páginas (máximo 5 páginas = 500 productos)
          if (page < 5 && paginatedResult.meta.hasNextPage) {
            _loadMoreProducts(page + 1);
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
      return;
    }

    try {
      _isLoadingCustomers.value = true;
      print('👥 Cargando clientes desde la base de datos...');

      final result = await _getCustomersUseCase!(
        const GetCustomersParams(
          page: 1,
          limit: 200,
          status: CustomerStatus.active,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar clientes: ${failure.message}');
          _showError('Error al cargar clientes', failure.message);
          _availableCustomers.clear();
        },
        (paginatedResult) {
          _availableCustomers.value = paginatedResult.data;
          print('✅ Clientes cargados: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('💥 Error al cargar clientes: $e');
      _showError('Error inesperado', 'No se pudieron cargar los clientes');
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
            // Fallback a búsqueda local
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
        // Búsqueda local
        results = _searchInLocalCustomers(query);
      }

      // Filtrar solo clientes activos
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

    // Actualizar términos de pago basados en el cliente
    if (customer.paymentTerms > 0) {
      _dueDate.value = _invoiceDate.value.add(
        Duration(days: customer.paymentTerms),
      );
    } else {
      _dueDate.value = _invoiceDate.value; // Venta de contado
    }
  }

  void clearCustomer() {
    _loadDefaultCustomer();
    print('🔄 Cliente vuelto a consumidor final');
  }
  // ==================== ITEM MANAGEMENT ====================

  void addItem(InvoiceItemFormData item) {
    _invoiceItems.add(item);
    _recalculateTotals();
    print('➕ Item agregado: ${item.description}');
  }

  void updateItem(int index, InvoiceItemFormData updatedItem) {
    if (index >= 0 && index < _invoiceItems.length) {
      _invoiceItems[index] = updatedItem;
      _recalculateTotals();
      print('✏️ Item actualizado en posición $index');
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
    // Actualizar fecha de vencimiento manteniendo los días de diferencia
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
    update(); // Fuerza actualización de UI
  }
  // ==================== PAYMENT & SAVE ====================

  // ✅ MÉTODO ACTUALIZADO CON DEBUGGING
  Future<void> saveInvoiceWithPayment(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status, // ✅ NUEVO PARÁMETRO
  ) async {
    if (!_validateForm()) return;

    try {
      _isSaving.value = true;

      print('🚀 === INICIANDO GUARDADO DE FACTURA ===');
      print('💾 Datos recibidos:');
      print('   - Método: ${paymentMethod.displayName}');
      print('   - Estado: ${status.displayName}');
      print('   - Total: \$${total.toStringAsFixed(2)}');
      print('   - Recibido: \$${receivedAmount.toStringAsFixed(2)}');
      print('   - Cambio: \$${change.toStringAsFixed(2)}');
      print('   - Es edición: $isEditMode');

      // ✅ Establecer método de pago en el controlador
      _paymentMethod.value = paymentMethod;

      // ✅ AGREGAR INFORMACIÓN DE PAGO A LAS NOTAS
      final paymentInfo = _buildPaymentNotes(receivedAmount, change, status);
      notesController.text = paymentInfo;

      // ✅ AJUSTAR FECHA DE VENCIMIENTO SEGÚN MÉTODO DE PAGO
      _adjustDueDateByPaymentMethod(paymentMethod, status);

      print('📅 Fecha de vencimiento ajustada: ${_dueDate.value}');
      print('📝 Notas generadas: ${paymentInfo.length} caracteres');

      if (isEditMode) {
        print('✏️ Actualizando factura existente...');
        await _updateExistingInvoice(status);
      } else {
        print('➕ Creando nueva factura...');
        await _createNewInvoice(status);
      }

      print('✅ === FACTURA GUARDADA EXITOSAMENTE ===');
    } catch (e) {
      print('💥 Error inesperado al guardar: $e');
      _showError('Error inesperado', 'No se pudo procesar la venta');
    } finally {
      _isSaving.value = false;
    }
  }

  void _adjustDueDateByPaymentMethod(
    PaymentMethod method,
    InvoiceStatus status,
  ) {
    // Si es borrador, mantener fecha actual o agregar tiempo para revisión
    if (status == InvoiceStatus.draft) {
      _dueDate.value = _invoiceDate.value.add(
        const Duration(days: 30),
      ); // Tiempo para revisión
      print(
        '📅 Borrador - Fecha de vencimiento: ${_dueDate.value.toString().split(' ')[0]}',
      );
      return;
    }

    // Lógica normal para otros estados
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
    buffer.writeln('=== INFORMACIÓN DE FACTURA ===');
    buffer.writeln('Estado: ${status.displayName.toUpperCase()}');

    if (status == InvoiceStatus.draft) {
      buffer.writeln('PENDIENTE DE REVISIÓN Y APROBACIÓN');
      buffer.writeln(
        'Creado por: [Usuario actual]',
      ); // Aquí puedes agregar el usuario actual
      buffer.writeln('Requiere aprobación de supervisor');
    } else {
      buffer.writeln('Método de Pago: ${paymentMethod.displayName}');
    }

    buffer.writeln('Subtotal: \$${subtotal.toStringAsFixed(2)}');

    if (totalDiscountAmount > 0) {
      buffer.writeln('Descuento: \$${totalDiscountAmount.toStringAsFixed(2)}');
    }

    if (taxAmount > 0) {
      buffer.writeln(
        'IVA (${taxPercentage}%): \$${taxAmount.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('TOTAL: \$${total.toStringAsFixed(2)}');

    if (status != InvoiceStatus.draft) {
      // ✅ INFORMACIÓN ESPECÍFICA SEGÚN MÉTODO DE PAGO (solo si no es borrador)
      switch (paymentMethod) {
        case PaymentMethod.cash:
          buffer.writeln('Recibido: \$${receivedAmount.toStringAsFixed(2)}');
          buffer.writeln('Cambio: \$${change.toStringAsFixed(2)}');
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

      // ✅ DEFINIR ESTADO POR DEFECTO CUANDO SE GUARDA SIN DIÁLOGO DE PAGO
      const defaultStatus = InvoiceStatus.draft; // Siempre como borrador

      if (isEditMode) {
        await _updateExistingInvoice(defaultStatus); // ✅ PASAR STATUS
      } else {
        await _createNewInvoice(defaultStatus); // ✅ PASAR STATUS
      }
    } catch (e) {
      print('💥 Error inesperado al guardar: $e');
      _showError('Error inesperado', 'No se pudo guardar la factura');
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _createNewInvoice(InvoiceStatus status) async {
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
        number: null, // AUTO-GENERADO
        date: invoiceDate,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status, // ✅ AGREGAR ESTADO
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        terms: termsController.text.isNotEmpty ? termsController.text : null,
      ),
    );

    result.fold(
      (failure) {
        _showError('Error al procesar venta', failure.message);
      },
      (invoice) {
        _showSuccessWithStatus('¡Venta procesada exitosamente!', status);
        _prepareForNewSale();
      },
    );
  }

  Future<void> _updateExistingInvoice(InvoiceStatus status) async {
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
        number: null, // Mantener número existente
        date: invoiceDate,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status, // ✅ AGREGAR ESTADO
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        terms: termsController.text.isNotEmpty ? termsController.text : null,
        customerId: selectedCustomer?.id,
        items: items,
      ),
    );

    result.fold(
      (failure) {
        _showError('Error al actualizar factura', failure.message);
      },
      (invoice) {
        _showSuccessWithStatus('Factura actualizada exitosamente', status);
        Get.offAndToNamed('/invoices/detail/${invoice.id}');
      },
    );
  }

  /// Limpiar para nueva venta
  void clearFormForNewSale() {
    _prepareForNewSale();
    _showSuccess('Lista para nueva venta');
  }

  void _prepareForNewSale() {
    // Limpiar items
    _invoiceItems.clear();

    // Restablecer cliente por defecto
    _loadDefaultCustomer();

    // Restablecer fechas
    _invoiceDate.value = DateTime.now();
    _dueDate.value = DateTime.now();

    // Limpiar notas
    notesController.clear();

    // Restablecer términos
    termsController.text = 'Venta de contado';

    // Restablecer descuentos
    _discountPercentage.value = 0.0;
    _discountAmount.value = 0.0;

    // Restablecer totales
    _recalculateTotals();

    print('🔄 Formulario preparado para nueva venta');
  }

  void clearForm() {
    // Limpiar todos los campos
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

    // TODO: Implementar vista previa
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

      // Aquí implementarías la lógica para cambiar de draft a pending/paid
      // Necesitarías un nuevo UseCase: ConfirmInvoiceUseCase

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

  void _showProductAddedMessage(String productName) {
    Get.snackbar(
      'Producto Agregado',
      productName,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(8),
    );
  }

  void _showProductUpdatedMessage(String productName, double newQuantity) {
    Get.snackbar(
      'Cantidad Actualizada',
      '$productName (${newQuantity.toInt()} unidades)',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.add_circle, color: Colors.blue),
      duration: const Duration(seconds: 1),
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
  }
}
