// lib/features/products/presentation/controllers/product_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
// ✅ NUEVOS IMPORTS PARA CATEGORÍAS
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../categories/domain/usecases/create_category_usecase.dart';
// ✅ IMPORT PARA CALCULADORA DE PRECIOS
import '../widgets/price_calculator_dialog.dart';
import '../../../../app/core/utils/formatters.dart';
// ✅ IMPORT PARA MANEJO GLOBAL DE ERRORES DE SUSCRIPCIÓN
import '../../../../app/shared/utils/subscription_error_handler.dart';
import '../../../../app/shared/services/subscription_validation_service.dart';
// ✅ IMPORT PARA CONTROLLERS QUE NECESITAN REFRESH
import 'products_controller.dart';
// ✅ IMPORT PARA UNIDADES DE MEDIDA
import '../widgets/unit_selector_widget.dart';
// ✅ IMPORT PARA SECURE STORAGE
import '../../../../app/core/storage/secure_storage_service.dart';
// ✅ IMPORT PARA FACTURACIÓN ELECTRÓNICA
import '../../domain/entities/tax_enums.dart';

class ProductFormController extends GetxController {
  // Dependencies
  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final GetProductByIdUseCase _getProductByIdUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final CreateCategoryUseCase _createCategoryUseCase;
  final SecureStorageService _secureStorageService;
  final ProductRepository _productRepository;

  // ✅ CONSTRUCTOR CORREGIDO
  ProductFormController({
    required CreateProductUseCase createProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required GetProductByIdUseCase getProductByIdUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required CreateCategoryUseCase createCategoryUseCase,
    required SecureStorageService secureStorageService,
    required ProductRepository productRepository,
  }) : _createProductUseCase = createProductUseCase,
       _updateProductUseCase = updateProductUseCase,
       _getProductByIdUseCase = getProductByIdUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       _createCategoryUseCase = createCategoryUseCase,
       _secureStorageService = secureStorageService,
       _productRepository = productRepository {
    print('🎮 ProductFormController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isEditing = false.obs;
  final _isLoadingCategories = false.obs; // ✅ NUEVO
  final _isDisposing = false.obs; // ✅ NUEVO: Control de disposal

  // Datos
  final Rxn<Product> _originalProduct = Rxn<Product>();
  final _selectedCategoryId = Rxn<String>();
  final _selectedCategoryName =
      Rxn<String>(); // ✅ NUEVO: Para mostrar el nombre
  final _productType = ProductType.product.obs;
  final _productStatus = ProductStatus.active.obs;
  final _selectedUnit = Rxn<MeasurementUnit>(); // ✅ NUEVO: Unidad de medida

  // ✅ NUEVO: Lista de categorías disponibles
  final _availableCategories = <Category>[].obs;

  // ========== FACTURACIÓN ELECTRÓNICA ==========
  final _selectedTaxCategory = TaxCategory.noGravado.obs;
  final _isTaxable = false.obs;
  final _hasRetention = false.obs;
  final _selectedRetentionCategory = Rxn<RetentionCategory>();
  // ========== FIN FACTURACIÓN ELECTRÓNICA ==========

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Text Controllers - Información básica
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController skuController;
  late final TextEditingController barcodeController;

  // Text Controllers - Stock y medidas
  late final TextEditingController stockController;
  late final TextEditingController minStockController;
  late final TextEditingController unitController;
  late final TextEditingController weightController;
  late final TextEditingController lengthController;
  late final TextEditingController widthController;
  late final TextEditingController heightController;

  // Text Controllers - Precios
  late final TextEditingController price1Controller;
  late final TextEditingController price2Controller;
  late final TextEditingController price3Controller;
  late final TextEditingController specialPriceController;
  late final TextEditingController costPriceController;

  // Text Controllers - Facturación electrónica
  late final TextEditingController taxRateController;
  late final TextEditingController taxDescriptionController;
  late final TextEditingController retentionRateController;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isEditing => _isEditing.value;
  bool get isLoadingCategories => _isLoadingCategories.value; // ✅ NUEVO
  bool get isDisposing => _isDisposing.value; // ✅ NUEVO

  Product? get originalProduct => _originalProduct.value;
  String? get selectedCategoryId => _selectedCategoryId.value;
  String? get selectedCategoryName => _selectedCategoryName.value; // ✅ NUEVO
  ProductType get productType => _productType.value;
  ProductStatus get productStatus => _productStatus.value;
  List<Category> get availableCategories => _availableCategories; // ✅ NUEVO
  MeasurementUnit? get selectedUnit => _selectedUnit.value; // ✅ NUEVO

  // Getters para facturación electrónica
  TaxCategory get selectedTaxCategory => _selectedTaxCategory.value;
  bool get isTaxable => _isTaxable.value;
  bool get hasRetention => _hasRetention.value;
  RetentionCategory? get selectedRetentionCategory =>
      _selectedRetentionCategory.value;

  String get productId => Get.parameters['id'] ?? '';
  bool get isEditMode => productId.isNotEmpty;
  String get pageTitle => isEditMode ? 'Editar Producto' : 'Crear Producto';
  String get saveButtonText => isEditMode ? 'Actualizar' : 'Crear';

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 ProductFormController: Inicializando...');
    print(
      '🔍 ProductFormController: isEditMode = $isEditMode, productId = "$productId"',
    );

    // ✅ SOLUCIÓN: Mover la carga asíncrona fuera de onInit
    _initializeForm();
  }

  @override
  void onClose() {
    print('🔚 ProductFormController: Iniciando liberación de recursos...');

    // Marcar como en proceso de disposal
    _isDisposing.value = true;

    // ✅ SOLUCIÓN MEJORADA: Disposer inmediatamente para evitar errores de navegación
    try {
      _disposeControllers();
      print('✅ ProductFormController: Todos los controladores liberados');
    } catch (e) {
      print('⚠️ ProductFormController: Error al liberar recursos: $e');
    }

    print('✅ ProductFormController: Recursos liberados exitosamente');
    super.onClose();
  }

  // ==================== PRIVATE INITIALIZATION ====================

  /// Inicialización sin bloqueos
  void _initializeForm() {
    print('⚙️ ProductFormController: Configurando formulario...');

    // Configurar valores por defecto inmediatamente (síncronos)
    _setDefaultValues();

    // Cargar categorías primero, luego producto (coordinado)
    Future.microtask(() => _loadDataSequentially());

    print('✅ ProductFormController: Inicialización completada');
  }

  /// Cargar datos en orden: categorías primero, luego producto
  Future<void> _loadDataSequentially() async {
    await _loadAvailableCategories();

    if (isClosed) return;

    if (isEditMode) {
      print(
        '📝 ProductFormController: Modo edición detectado, cargando producto...',
      );
      _isEditing.value = true;
      await loadProductForEditing();
    }
  }

  /// Configurar valores por defecto (operaciones síncronas únicamente)
  void _setDefaultValues() {
    // ✅ INICIALIZAR CONTROLADORES PRIMERO
    _initializeControllers();

    stockController.text = '0';
    minStockController.text = '0';
    // ✅ UNIDAD POR DEFECTO
    _selectedUnit.value = MeasurementUnit.pieces;

    // Configurar valores por defecto para los observables
    _productType.value = ProductType.product;
    _productStatus.value = ProductStatus.active;

    print('✅ ProductFormController: Valores por defecto configurados');
  }

  /// Inicializar todos los TextEditingController
  void _initializeControllers() {
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    skuController = TextEditingController();
    barcodeController = TextEditingController();
    stockController = TextEditingController();
    minStockController = TextEditingController();
    unitController = TextEditingController();
    weightController = TextEditingController();
    lengthController = TextEditingController();
    widthController = TextEditingController();
    heightController = TextEditingController();
    price1Controller = TextEditingController();
    price2Controller = TextEditingController();
    price3Controller = TextEditingController();
    specialPriceController = TextEditingController();
    costPriceController = TextEditingController();

    // Controladores de facturación electrónica
    taxRateController = TextEditingController(text: '0');
    taxDescriptionController = TextEditingController();
    retentionRateController = TextEditingController(text: '0');

    print('✅ ProductFormController: Controladores inicializados');
  }

  // ==================== ✅ NUEVOS MÉTODOS PARA CATEGORÍAS ====================

  /// Cargar categorías disponibles
  // ✅ Cache específico por tenant para evitar mezclar categorías de diferentes organizaciones
  static final Map<String, List<Category>> _categoriesCache = {};
  static final Map<String, DateTime> _cacheTimeMap = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Limpiar cache de categorías (útil cuando se crean/actualizan categorías)
  static void clearCategoriesCache([String? tenantSlug]) {
    if (tenantSlug != null) {
      _categoriesCache.remove(tenantSlug);
      _cacheTimeMap.remove(tenantSlug);
      print(
        '🗑️ ProductFormController: Cache de categorías limpiado para tenant: $tenantSlug',
      );
    } else {
      _categoriesCache.clear();
      _cacheTimeMap.clear();
      print('🗑️ ProductFormController: Todo el cache de categorías limpiado');
    }
  }

  /// Método público para cargar categorías si es necesario
  Future<void> loadAvailableCategoriesIfNeeded() async {
    if (_availableCategories.isEmpty) {
      await _loadAvailableCategories();
    }
  }

  Future<void> _loadAvailableCategories() async {
    // ✅ Obtener el tenant slug actual
    final tenantSlug = await _secureStorageService.getTenantSlug();
    if (tenantSlug == null || tenantSlug.isEmpty) {
      print('⚠️ ProductFormController: No hay tenant slug disponible');
      _showError(
        'Error de configuración',
        'No se pudo determinar la organización actual',
      );
      return;
    }

    // ✅ Verificar cache específico por tenant
    final cachedCategories = _categoriesCache[tenantSlug];
    final cacheTime = _cacheTimeMap[tenantSlug];

    if (cachedCategories != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _cacheExpiry) {
      print(
        '📂 ProductFormController: Usando categorías desde cache para tenant: $tenantSlug',
      );
      _availableCategories.value = cachedCategories;
      return;
    }

    print(
      '📂 ProductFormController: Cargando categorías desde API para tenant: $tenantSlug...',
    );
    _isLoadingCategories.value = true;

    try {
      final result = await _getCategoriesUseCase(
        const GetCategoriesParams(
          page: 1,
          limit: 100, // Suficientes categorías para el selector
          status: CategoryStatus.active, // Solo categorías activas
          onlyParents: true, // Solo categorías padre para simplificar
          sortBy: 'name',
          sortOrder: 'ASC',
        ),
      );

      result.fold(
        (failure) {
          print(
            '❌ ProductFormController: Error al cargar categorías - ${failure.message}',
          );
          _showError(
            'Error al cargar categorías',
            'No se pudieron cargar las categorías disponibles',
          );
        },
        (paginatedResult) async {
          // ✅ NUEVA LÓGICA: Si no hay categorías, crear categoría "General"
          if (paginatedResult.data.isEmpty) {
            print(
              '📂 ProductFormController: No se encontraron categorías para tenant: $tenantSlug',
            );
            print(
              '🆕 ProductFormController: Creando categoría "General" automáticamente...',
            );

            await _createDefaultCategory(tenantSlug);
          } else {
            _availableCategories.value = paginatedResult.data;
            // ✅ Actualizar cache específico por tenant
            _categoriesCache[tenantSlug] = paginatedResult.data;
            _cacheTimeMap[tenantSlug] = DateTime.now();
            print(
              '✅ ProductFormController: ${paginatedResult.data.length} categorías cargadas y almacenadas en cache para tenant: $tenantSlug',
            );
          }
        },
      );
    } catch (e) {
      print(
        '💥 ProductFormController: Error inesperado al cargar categorías - $e',
      );
      _showError(
        'Error inesperado',
        'No se pudieron cargar las categorías: $e',
      );
    } finally {
      _isLoadingCategories.value = false;
    }
  }

  /// Crear categoría "General" por defecto cuando no hay categorías
  Future<void> _createDefaultCategory(String tenantSlug) async {
    try {
      print(
        '🔄 ProductFormController: Iniciando creación de categoría "General"...',
      );

      final result = await _createCategoryUseCase(
        CreateCategoryParams(
          name: 'General',
          description: 'Categoría general creada automáticamente',
          slug: 'general',
          status: CategoryStatus.active,
          sortOrder: 0,
        ),
      );

      result.fold(
        (failure) {
          print(
            '❌ ProductFormController: Error al crear categoría "General" - ${failure.message}',
          );
          _showError(
            'Error al crear categoría',
            'No se pudo crear la categoría por defecto: ${failure.message}',
          );
        },
        (category) async {
          print(
            '✅ ProductFormController: Categoría "General" creada exitosamente - ID: ${category.id}',
          );

          // Limpiar cache para este tenant
          _categoriesCache.remove(tenantSlug);
          _cacheTimeMap.remove(tenantSlug);

          // Recargar categorías para mostrar la recién creada
          print('🔄 ProductFormController: Recargando categorías...');
          await _loadAvailableCategories();

          _showInfo(
            'Categoría creada',
            'Se ha creado la categoría "General" automáticamente',
          );
        },
      );
    } catch (e) {
      print(
        '💥 ProductFormController: Error inesperado al crear categoría "General" - $e',
      );
      _showError(
        'Error inesperado',
        'No se pudo crear la categoría por defecto: $e',
      );
    }
  }

  /// Establecer categoría seleccionada con ID y nombre
  void setCategorySelection(String categoryId, String categoryName) {
    _selectedCategoryId.value = categoryId;
    _selectedCategoryName.value = categoryName;
    print(
      '📂 ProductFormController: Categoría seleccionada - $categoryName ($categoryId)',
    );
  }

  /// Limpiar selección de categoría
  void clearCategorySelection() {
    _selectedCategoryId.value = null;
    _selectedCategoryName.value = null;
    print('🧹 ProductFormController: Selección de categoría limpiada');
  }

  /// Obtener nombre de categoría por ID (para casos donde solo tenemos el ID)
  String? getCategoryNameById(String categoryId) {
    try {
      final category = _availableCategories.firstWhere(
        (cat) => cat.id == categoryId,
      );
      return category.name;
    } catch (e) {
      print(
        '⚠️ ProductFormController: Categoría no encontrada para ID: $categoryId',
      );
      return null;
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar producto para edición (ahora completamente asíncrono)
  Future<void> loadProductForEditing() async {
    print(
      '📥 ProductFormController: Iniciando carga de producto para edición...',
    );
    _isLoading.value = true;

    try {
      final result = await _getProductByIdUseCase(
        GetProductByIdParams(id: productId),
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          print(
            '❌ ProductFormController: Error al cargar producto - ${failure.message}',
          );
          if (!isClosed) {
            _showError('Error al cargar producto', failure.message);
            Get.back();
          }
        },
        (product) {
          print(
            '✅ ProductFormController: Producto cargado exitosamente - ${product.name}',
          );
          if (!isClosed) {
            _originalProduct.value = product;
            _populateForm(product);
          }
        },
      );
    } catch (e) {
      print(
        '💥 ProductFormController: Error inesperado al cargar producto - $e',
      );
      if (!isClosed) {
        _showError('Error inesperado', 'No se pudo cargar el producto: $e');
        Get.back();
      }
    } finally {
      _isLoading.value = false;
      print('🏁 ProductFormController: Carga de producto finalizada');
    }
  }

  /// Guardar producto (crear o actualizar)
  Future<void> saveProduct() async {
    // Protección contra doble-click
    if (_isSaving.value) return;

    print('💾 ProductFormController: Iniciando guardado de producto...');

    if (!await _validateForm()) {
      print('❌ ProductFormController: Validación de formulario falló');
      return;
    }

    _isSaving.value = true;

    try {
      if (isEditMode) {
        print('🔄 ProductFormController: Actualizando producto existente...');
        await _updateProduct();
      } else {
        print('🆕 ProductFormController: Creando nuevo producto...');
        await _createProduct();
      }
    } catch (e) {
      print('💥 ProductFormController: Error inesperado al guardar - $e');
      _showError('Error inesperado', 'No se pudo guardar el producto: $e');
    } finally {
      _isSaving.value = false;
      print('🏁 ProductFormController: Guardado finalizado');
    }
  }

  /// Validar formulario
  Future<bool> validateForm() async {
    return await _validateForm();
  }

  /// Limpiar formulario
  void clearForm() {
    print('🧹 ProductFormController: Limpiando formulario...');

    formKey.currentState?.reset();
    _clearControllers();
    _selectedCategoryId.value = null;
    _selectedCategoryName.value = null; // ✅ NUEVO
    _productType.value = ProductType.product;
    _productStatus.value = ProductStatus.active;

    print('✅ ProductFormController: Formulario limpiado');
  }

  // ==================== FORM METHODS ====================

  /// Establecer categoría seleccionada (método legacy para compatibilidad)
  void setCategory(String categoryId) {
    final categoryName = getCategoryNameById(categoryId);
    if (categoryName != null) {
      setCategorySelection(categoryId, categoryName);
    } else {
      _selectedCategoryId.value = categoryId;
      print(
        '⚠️ ProductFormController: Categoría seleccionada sin nombre - $categoryId',
      );
    }
  }

  /// Cambiar tipo de producto
  void setProductType(ProductType type) {
    _productType.value = type;
    print('🏷️ ProductFormController: Tipo de producto - ${type.name}');
  }

  /// Cambiar estado de producto
  void setProductStatus(ProductStatus status) {
    _productStatus.value = status;
    print('🔄 ProductFormController: Estado de producto - ${status.name}');
    update(['status_selector']); // ✅ Actualizar específicamente el selector
  }

  // ==================== MÉTODOS PARA FACTURACIÓN ELECTRÓNICA ====================

  /// Cambiar categoría de impuesto
  void setTaxCategory(TaxCategory category) {
    _selectedTaxCategory.value = category;
    // Auto-actualizar la tasa según la categoría
    taxRateController.text = category.defaultRate.toString();
    print(
      '💰 ProductFormController: Categoría de impuesto - ${category.displayName}',
    );
    print(
      '💰 ProductFormController: Tasa por defecto - ${category.defaultRate}%',
    );
    update(['tax_selector']);
  }

  /// Cambiar estado gravable
  void setTaxable(bool value) {
    _isTaxable.value = value;
    print('💰 ProductFormController: Producto gravable - $value');
    update(['tax_section']);
  }

  /// Cambiar estado de retención
  void setHasRetention(bool value) {
    _hasRetention.value = value;
    if (!value) {
      // Si desactiva la retención, limpiar la categoría
      _selectedRetentionCategory.value = null;
      retentionRateController.text = '0';
    }
    print('💰 ProductFormController: Tiene retención - $value');
    update(['retention_section']);
  }

  /// Cambiar categoría de retención
  void setRetentionCategory(RetentionCategory? category) {
    _selectedRetentionCategory.value = category;
    if (category != null) {
      // Auto-actualizar la tasa según la categoría
      retentionRateController.text = category.defaultRate.toString();
      _hasRetention.value = true;
      print(
        '💰 ProductFormController: Categoría de retención - ${category.displayName}',
      );
      print(
        '💰 ProductFormController: Tasa por defecto - ${category.defaultRate}%',
      );
    }
    update(['retention_selector']);
  }

  /// Generar SKU automático
  void generateSku() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    final name = nameController.text.trim().toUpperCase();
    final prefix = name.isNotEmpty
        ? name.substring(0, name.length.clamp(0, 3))
        : 'PRD';
    skuController.text = '$prefix$timestamp';
    print('🎲 ProductFormController: SKU generado - ${skuController.text}');
  }

  /// Calcular margen de ganancia
  double calculateMargin(double costPrice, double sellPrice) {
    if (costPrice <= 0) return 0;
    return ((sellPrice - costPrice) / costPrice) * 100;
  }

  /// Redondear precio al múltiplo de 100 más cercano
  int _roundToNearest100(double price) {
    if (price <= 0) return 0;
    return ((price / 100).round() * 100);
  }

  /// Validar código de barras
  bool validateBarcode(String barcode) {
    // Validación básica de código de barras
    if (barcode.isEmpty) return true; // Opcional
    return barcode.length >= 8 && barcode.length <= 18;
  }

  // ==================== UI HELPERS ====================

  /// Mostrar selector de categoría (método actualizado)
  void showCategorySelector() {
    if (_availableCategories.isEmpty && !_isLoadingCategories.value) {
      _showError(
        'Sin categorías',
        'No hay categorías disponibles. Crea una categoría primero.',
      );
      return;
    }

    print('🎯 ProductFormController: Mostrando selector de categorías');
    // El widget CategorySelectorWidget manejará la lógica del selector
  }

  /// Mostrar calculadora de precios
  void showPriceCalculator() {
    // Usar el widget mejorado PriceCalculatorDialog
    Get.dialog(
      PriceCalculatorDialog(
        initialCost: costPriceController.text,
        onCalculate: (calculatedPrices) {
          print('🧮 ProductFormController: Recibiendo precios calculados...');
          print('🧮 ProductFormController: Datos recibidos: $calculatedPrices');

          // Aplicar los precios calculados a los controladores con redondeo a múltiplos de 100
          price1Controller.text = AppFormatters.formatNumber(
            _roundToNearest100(calculatedPrices['price1'] ?? 0),
          );
          price2Controller.text = AppFormatters.formatNumber(
            _roundToNearest100(calculatedPrices['price2'] ?? 0),
          );
          price3Controller.text = AppFormatters.formatNumber(
            _roundToNearest100(calculatedPrices['price3'] ?? 0),
          );
          specialPriceController.text = AppFormatters.formatNumber(
            _roundToNearest100(calculatedPrices['special'] ?? 0),
          );

          // Aplicar también el precio de costo (sin redondeo porque es el valor base)
          if (calculatedPrices['cost'] != null) {
            costPriceController.text = AppFormatters.formatNumber(
              calculatedPrices['cost']!.round(),
            );
            print(
              '🧮 ProductFormController: Precio de costo aplicado: ${costPriceController.text}',
            );
          }

          print('🧮 ProductFormController: Precios aplicados a controladores');

          // Actualizar la UI
          update();

          print('🧮 ProductFormController: UI actualizada');

          // Mostrar mensaje de éxito
          Get.snackbar(
            'Éxito',
            'Precios calculados y aplicados correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          print('🧮 ProductFormController: Callback completado');
        },
      ),
    );
  }

  /// Previsualizar producto
  Future<void> previewProduct() async {
    if (!await _validateForm()) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Previsualización'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nombre: ${nameController.text}'),
              Text('SKU: ${skuController.text}'),
              Text('Tipo: ${_productType.value.name}'),
              Text('Estado: ${_productStatus.value.name}'),
              Text('Stock: ${stockController.text}'),
              Text(
                'Categoría: ${_selectedCategoryName.value ?? "No seleccionada"}',
              ), // ✅ NUEVO
              if (price1Controller.text.isNotEmpty)
                Text('Precio 1: \${price1Controller.text}'),
              if (costPriceController.text.isNotEmpty)
                Text('Costo: \${costPriceController.text}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
          TextButton(
            onPressed: () {
              Get.back();
              saveProduct();
            },
            child: Text(saveButtonText),
          ),
        ],
      ),
    );
  }

  Future<void> _createProduct() async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    if (!await SubscriptionValidationService.canCreateProductAsync()) {
      print(
        '🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO creación de producto',
      );
      return; // Bloquear operación
    }

    print(
      '✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con creación de producto',
    );

    final prices = _buildPricesList();

    final result = await _createProductUseCase(
      CreateProductParams(
        name: nameController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        sku: skuController.text.trim(),
        barcode:
            barcodeController.text.trim().isEmpty
                ? null
                : barcodeController.text.trim(),
        type: _productType.value,
        status: _productStatus.value,
        stock: AppFormatters.parseNumber(stockController.text) ?? 0,
        minStock: AppFormatters.parseNumber(minStockController.text) ?? 0,
        unit: _selectedUnit.value?.shortName,
        weight: AppFormatters.parseNumber(weightController.text),
        length: AppFormatters.parseNumber(lengthController.text),
        width: AppFormatters.parseNumber(widthController.text),
        height: AppFormatters.parseNumber(heightController.text),
        categoryId: _selectedCategoryId.value!,
        prices: prices,
        // Campos de facturación electrónica
        taxCategory: _selectedTaxCategory.value,
        taxRate: AppFormatters.parseNumber(taxRateController.text) ?? 19.0,
        isTaxable: _isTaxable.value,
        taxDescription:
            taxDescriptionController.text.trim().isEmpty
                ? null
                : taxDescriptionController.text.trim(),
        retentionCategory: _selectedRetentionCategory.value,
        retentionRate:
            _hasRetention.value
                ? AppFormatters.parseNumber(retentionRateController.text) ?? 0
                : null,
        hasRetention: _hasRetention.value,
      ),
    );

    result.fold(
      (failure) {
        // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
        final handled = SubscriptionErrorHandler.handleFailure(
          failure,
          context: 'crear producto',
        );

        if (!handled) {
          // Solo mostrar error genérico si no fue un error de suscripción
          _showError('Error al crear producto', failure.message);
        }
      },
      (product) {
        print(
          '✅ ProductFormController: Producto creado exitosamente - ${product.name}',
        );
        _showSuccess('Producto creado exitosamente');
        _navigateBackToProductList();
      },
    );
  }

  Future<void> _updateProduct() async {
    try {
      // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
      if (!await SubscriptionValidationService.canUpdateProductAsync()) {
        print(
          '🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO actualización de producto',
        );
        return; // Bloquear operación
      }

      print(
        '✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con actualización de producto',
      );
      print('🔄 ProductFormController: Actualizando producto existente...');

      // ✅ PASO 1: Construir precios para actualización con más debug
      final prices = _buildPricesListForUpdateAsCreateParams();

      print(
        '🏷️ ProductFormController: Construidos ${prices.length} precios para actualización',
      );
      for (final price in prices) {
        final hasId = price.notes?.startsWith('ID:') == true;
        final extractedId = hasId ? price.notes!.substring(3) : 'NUEVO';
        print(
          '   - Tipo: ${price.type.name}, ID: $extractedId, Cantidad: \$${price.amount}',
        );
      }

      // ✅ PASO 2: Validar que tenemos precios si es necesario
      if (prices.isEmpty) {
        print(
          '⚠️ ProductFormController: No se encontraron precios para enviar',
        );
      }

      // ✅ PASO 3: Crear el request con TODOS los campos incluyendo prices y tax fields
      final result = await _updateProductUseCase(
        UpdateProductParams(
          id: productId,
          name: nameController.text.trim(),
          description:
              descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
          sku: skuController.text.trim(),
          barcode:
              barcodeController.text.trim().isEmpty
                  ? null
                  : barcodeController.text.trim(),
          type: _productType.value,
          status: _productStatus.value,
          stock: AppFormatters.parseNumber(stockController.text) ?? 0,
          minStock: AppFormatters.parseNumber(minStockController.text) ?? 0,
          unit: _selectedUnit.value?.shortName,
          weight: AppFormatters.parseNumber(weightController.text),
          length: AppFormatters.parseNumber(lengthController.text),
          width: AppFormatters.parseNumber(widthController.text),
          height: AppFormatters.parseNumber(heightController.text),
          categoryId: _selectedCategoryId.value!,
          prices: prices, // ✅ CRÍTICO: Incluir precios procesados
          // Campos de facturación electrónica
          taxCategory: _selectedTaxCategory.value,
          taxRate: AppFormatters.parseNumber(taxRateController.text) ?? 19.0,
          isTaxable: _isTaxable.value,
          taxDescription:
              taxDescriptionController.text.trim().isEmpty
                  ? null
                  : taxDescriptionController.text.trim(),
          retentionCategory: _selectedRetentionCategory.value,
          retentionRate:
              _hasRetention.value
                  ? AppFormatters.parseNumber(retentionRateController.text) ?? 0
                  : null,
          hasRetention: _hasRetention.value,
        ),
      );

      result.fold(
        (failure) {
          // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
          final handled = SubscriptionErrorHandler.handleFailure(
            failure,
            context: 'editar producto',
          );

          if (!handled) {
            // Solo mostrar error genérico si no fue un error de suscripción
            _showError('Error al actualizar producto', failure.message);
          }
        },
        (product) {
          print(
            '✅ ProductFormController: Producto actualizado exitosamente - ${product.name}',
          );

          // ✅ VERIFICAR QUE EL PRODUCTO ACTUALIZADO TENGA PRECIOS
          if (product.prices != null && product.prices!.isNotEmpty) {
            print(
              '💰 Precios actualizados recibidos: ${product.prices!.length}',
            );
            for (final price in product.prices!) {
              print(
                '   - ${price.type.name}: \$${price.amount} (ID: ${price.id})',
              );
            }
          } else {
            print('⚠️ El producto actualizado NO tiene precios');
          }

          _showSuccess('Producto actualizado exitosamente');
          _navigateBackToProductList();
        },
      );
    } catch (e, stackTrace) {
      print('❌ ProductFormController: Error inesperado en _updateProduct: $e');
      print('🔍 StackTrace: $stackTrace');
      _showError('Error inesperado', 'No se pudo actualizar el producto: $e');
    }
  }

  /// Validar formulario (ahora async para validar duplicados)
  Future<bool> _validateForm() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      print('❌ ProductFormController: Validación de campos falló');
      return false;
    }

    // ✅ NUEVO: Auto-seleccionar categoría si solo hay una disponible
    if (_selectedCategoryId.value == null) {
      if (_availableCategories.length == 1) {
        final onlyCategory = _availableCategories.first;
        _selectedCategoryId.value = onlyCategory.id;
        _selectedCategoryName.value = onlyCategory.name;
        print(
          '✅ ProductFormController: Auto-seleccionada única categoría disponible: ${onlyCategory.name}',
        );
      } else {
        print('❌ ProductFormController: Categoría no seleccionada');
        _showError('Error de validación', 'Selecciona una categoría');
        return false;
      }
    }

    if (skuController.text.trim().isEmpty) {
      generateSku();
      print('🎲 ProductFormController: SKU vacío, generado automáticamente: ${skuController.text}');
    }

    // ==================== ✅ VALIDACIÓN DE DUPLICADOS ====================

    final productName = nameController.text.trim();
    final productSku = skuController.text.trim();
    final productBarcode = barcodeController.text.trim();
    final excludeId = isEditMode ? productId : null;

    print('🔍 ProductFormController: Validando duplicados...');
    print('   isEditMode: $isEditMode');
    print('   productId: "$productId"');
    print('   excludeId: $excludeId');
    print('   Nombre: "$productName"');
    print('   SKU: "$productSku"');

    // ✅ IMPORTANTE: Solo validar si el valor cambió respecto al original
    final originalProductName = _originalProduct.value?.name;
    final originalProductSku = _originalProduct.value?.sku;
    final originalProductBarcode = _originalProduct.value?.barcode;

    // Validar nombre duplicado (solo si cambió)
    if (!isEditMode || productName != originalProductName) {
      final nameExistsResult = await _productRepository.existsByName(productName, excludeId: excludeId);
      final nameExists = nameExistsResult.fold(
        (failure) => false, // Si falla la validación, permitir continuar
        (exists) => exists,
      );

      if (nameExists) {
        print('❌ ProductFormController: Nombre de producto duplicado - "$productName"');
        _showError('Producto duplicado', 'Ya existe un producto con el nombre "$productName"');
        return false;
      }
    } else {
      print('✅ Nombre no cambió, omitiendo validación');
    }

    // Validar SKU duplicado (solo si cambió)
    if (!isEditMode || productSku != originalProductSku) {
      final skuExistsResult = await _productRepository.existsBySku(productSku, excludeId: excludeId);
      final skuExists = skuExistsResult.fold(
        (failure) => false,
        (exists) => exists,
      );

      if (skuExists) {
        print('❌ ProductFormController: SKU duplicado - "$productSku"');
        _showError('SKU duplicado', 'Ya existe un producto con el SKU "$productSku"');
        return false;
      }
    } else {
      print('✅ SKU no cambió, omitiendo validación');
    }

    // Validar código de barras duplicado (solo si se proporcionó Y si cambió)
    if (productBarcode.isNotEmpty && (!isEditMode || productBarcode != originalProductBarcode)) {
      final barcodeExistsResult = await _productRepository.existsByBarcode(productBarcode, excludeId: excludeId);
      final barcodeExists = barcodeExistsResult.fold(
        (failure) => false,
        (exists) => exists,
      );

      if (barcodeExists) {
        print('❌ ProductFormController: Código de barras duplicado - "$productBarcode"');
        _showError('Código de barras duplicado', 'Ya existe un producto con el código de barras "$productBarcode"');
        return false;
      }
    } else if (isEditMode && productBarcode == originalProductBarcode) {
      print('✅ Código de barras no cambió, omitiendo validación');
    }

    print('✅ ProductFormController: Validación exitosa (sin duplicados)');
    return true;
  }

  /// Poblar formulario con datos del producto
  void _populateForm(Product product) {
    print(
      '📝 ProductFormController: Poblando formulario con datos del producto...',
    );

    nameController.text = product.name;
    descriptionController.text = product.description ?? '';
    skuController.text = product.sku;
    barcodeController.text = product.barcode ?? '';
    stockController.text = AppFormatters.formatNumber(product.stock);
    minStockController.text = AppFormatters.formatNumber(product.minStock);

    // ✅ CARGAR UNIDAD DE MEDIDA
    _loadUnitFromProduct(product);

    weightController.text = product.weight?.toString() ?? '';
    lengthController.text = product.length?.toString() ?? '';
    widthController.text = product.width?.toString() ?? '';
    heightController.text = product.height?.toString() ?? '';

    // ✅ ACTUALIZADO: Configurar categoría con ID y nombre
    final categoryName =
        getCategoryNameById(product.categoryId!) ??
        product.category?.name ??
        'Categoría desconocida';
    setCategorySelection(product.categoryId!, categoryName);

    _productType.value = product.type;
    _productStatus.value = product.status;

    print('🔧 ProductFormController: Estado configurado - ${product.status}');
    print('🔧 ProductFormController: Tipo configurado - ${product.type}');

    // ✅ FORZAR actualización de la UI para que refleje los cambios
    update(); // Notifica a todos los GetBuilder
    update([
      'status_selector',
    ]); // Notifica específicamente al selector de estado

    // Poblar precios si existen - con formateo automático
    if (product.prices != null) {
      for (final price in product.prices!) {
        switch (price.type) {
          case PriceType.price1:
            price1Controller.text = AppFormatters.formatNumber(price.amount);
            break;
          case PriceType.price2:
            price2Controller.text = AppFormatters.formatNumber(price.amount);
            break;
          case PriceType.price3:
            price3Controller.text = AppFormatters.formatNumber(price.amount);
            break;
          case PriceType.special:
            specialPriceController.text = AppFormatters.formatNumber(
              price.amount,
            );
            break;
          case PriceType.cost:
            costPriceController.text = AppFormatters.formatNumber(price.amount);
            break;
        }
      }
    }

    // ✅ NUEVO: Poblar campos de facturación electrónica
    _selectedTaxCategory.value = product.taxCategory;
    taxRateController.text = product.taxRate.toString();
    _isTaxable.value = product.isTaxable;
    taxDescriptionController.text = product.taxDescription ?? '';
    _selectedRetentionCategory.value = product.retentionCategory;
    retentionRateController.text = product.retentionRate?.toString() ?? '0';
    _hasRetention.value = product.hasRetention;

    print('✅ ProductFormController: Formulario poblado exitosamente');
    print(
      '💰 Impuestos cargados: ${product.taxCategory.displayName} (${product.taxRate}%)',
    );
    if (product.hasRetention && product.retentionCategory != null) {
      print(
        '💰 Retención cargada: ${product.retentionCategory!.displayName} (${product.retentionRate}%)',
      );
    }
  }

  /// Construir lista de precios
  List<CreateProductPriceParams> _buildPricesList() {
    final prices = <CreateProductPriceParams>[];

    if (price1Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price1Controller.text);
      if (amount != null && amount > 0) {
        prices.add(
          CreateProductPriceParams(
            type: PriceType.price1,
            name: 'Precio al público',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    if (price2Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price2Controller.text);
      if (amount != null && amount > 0) {
        prices.add(
          CreateProductPriceParams(
            type: PriceType.price2,
            name: 'Precio mayorista',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    if (price3Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price3Controller.text);
      if (amount != null && amount > 0) {
        prices.add(
          CreateProductPriceParams(
            type: PriceType.price3,
            name: 'Precio distribuidor',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    if (specialPriceController.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(specialPriceController.text);
      if (amount != null && amount > 0) {
        prices.add(
          CreateProductPriceParams(
            type: PriceType.special,
            name: 'Precio especial',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    if (costPriceController.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(costPriceController.text);
      if (amount != null && amount > 0) {
        prices.add(
          CreateProductPriceParams(
            type: PriceType.cost,
            name: 'Precio de costo',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    return prices;
  }

  List<CreateProductPriceParams> _buildPricesListForUpdateAsCreateParams() {
    final prices = <CreateProductPriceParams>[];
    final originalPrices = _originalProduct.value?.prices ?? [];

    print(
      '🏗️ ProductFormController: Construyendo precios para actualización...',
    );
    print('📊 Precios originales disponibles: ${originalPrices.length}');

    // Mostrar precios originales para debug
    for (final originalPrice in originalPrices) {
      print(
        '   Original: ${originalPrice.type.name} - \$${originalPrice.amount} (ID: ${originalPrice.id})',
      );
    }

    // Helper function para encontrar precio original por tipo
    String? findOriginalPriceId(PriceType type) {
      try {
        final originalPrice = originalPrices.firstWhere(
          (price) => price.type == type,
        );
        print(
          '🔍 Encontrado precio original para ${type.name}: ID ${originalPrice.id}',
        );
        return originalPrice.id;
      } catch (e) {
        print('🔍 No se encontró precio original para ${type.name}');
        return null;
      }
    }

    // ✅ PROCESAMIENTO MEJORADO DE CADA TIPO DE PRECIO

    // Precio 1 (Público)
    if (price1Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price1Controller.text);
      if (amount != null && amount > 0) {
        final priceId = findOriginalPriceId(PriceType.price1);
        final price = CreateProductPriceParams(
          type: PriceType.price1,
          name: 'Precio al público',
          amount: amount,
          currency: 'COP',
          notes: priceId != null ? 'ID:$priceId' : null,
        );
        prices.add(price);
        print(
          '✅ Agregado price1: \$$amount ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
        );
      }
    }

    // Precio 2 (Mayorista)
    if (price2Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price2Controller.text);
      if (amount != null && amount > 0) {
        final priceId = findOriginalPriceId(PriceType.price2);
        final price = CreateProductPriceParams(
          type: PriceType.price2,
          name: 'Precio mayorista',
          amount: amount,
          currency: 'COP',
          notes: priceId != null ? 'ID:$priceId' : null,
        );
        prices.add(price);
        print(
          '✅ Agregado price2: \$$amount ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
        );
      }
    }

    // Precio 3 (Distribuidor)
    if (price3Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price3Controller.text);
      if (amount != null && amount > 0) {
        final priceId = findOriginalPriceId(PriceType.price3);
        final price = CreateProductPriceParams(
          type: PriceType.price3,
          name: 'Precio distribuidor',
          amount: amount,
          currency: 'COP',
          notes: priceId != null ? 'ID:$priceId' : null,
        );
        prices.add(price);
        print(
          '✅ Agregado price3: \$$amount ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
        );
      }
    }

    // Precio Especial
    if (specialPriceController.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(specialPriceController.text);
      if (amount != null && amount > 0) {
        final priceId = findOriginalPriceId(PriceType.special);
        final price = CreateProductPriceParams(
          type: PriceType.special,
          name: 'Precio especial',
          amount: amount,
          currency: 'COP',
          notes: priceId != null ? 'ID:$priceId' : null,
        );
        prices.add(price);
        print(
          '✅ Agregado special: \$$amount ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
        );
      }
    }

    // Precio de Costo
    if (costPriceController.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(costPriceController.text);
      if (amount != null && amount > 0) {
        final priceId = findOriginalPriceId(PriceType.cost);
        final price = CreateProductPriceParams(
          type: PriceType.cost,
          name: 'Precio de costo',
          amount: amount,
          currency: 'COP',
          notes: priceId != null ? 'ID:$priceId' : null,
        );
        prices.add(price);
        print(
          '✅ Agregado cost: \$$amount ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
        );
      }
    }

    print(
      '🏁 ProductFormController: Total de precios construidos: ${prices.length}',
    );

    // ✅ VERIFICACIÓN FINAL
    if (prices.isEmpty) {
      print(
        '⚠️ ADVERTENCIA: No se construyeron precios. Verificar controladores:',
      );
      print('   price1Controller.text: "${price1Controller.text}"');
      print('   price2Controller.text: "${price2Controller.text}"');
      print('   price3Controller.text: "${price3Controller.text}"');
      print('   specialPriceController.text: "${specialPriceController.text}"');
      print('   costPriceController.text: "${costPriceController.text}"');
    }

    return prices;
  }

  /// Limpiar controladores
  void _clearControllers() {
    nameController.clear();
    descriptionController.clear();
    skuController.clear();
    barcodeController.clear();
    stockController.clear();
    minStockController.clear();
    unitController.clear();
    weightController.clear();
    lengthController.clear();
    widthController.clear();
    heightController.clear();
    price1Controller.clear();
    price2Controller.clear();
    price3Controller.clear();
    specialPriceController.clear();
    costPriceController.clear();

    // Limpiar controladores de facturación electrónica
    taxRateController.text = '19';
    taxDescriptionController.clear();
    retentionRateController.text = '0';

    // Restablecer valores por defecto
    _selectedTaxCategory.value = TaxCategory.iva;
    _isTaxable.value = true;
    _hasRetention.value = false;
    _selectedRetentionCategory.value = null;
  }

  /// Flag para controlar disposal múltiple
  bool _controllersDisposed = false;

  /// Disponer controladores de forma segura
  void _disposeControllers() {
    if (_controllersDisposed) {
      print(
        '⚠️ ProductFormController: Controladores ya liberados, omitiendo...',
      );
      return;
    }

    try {
      _controllersDisposed = true;
      final controllers = [
        nameController,
        descriptionController,
        skuController,
        barcodeController,
        stockController,
        minStockController,
        unitController,
        weightController,
        lengthController,
        widthController,
        heightController,
        price1Controller,
        price2Controller,
        price3Controller,
        specialPriceController,
        costPriceController,
        // Controladores de facturación electrónica
        taxRateController,
        taxDescriptionController,
        retentionRateController,
      ];

      for (final controller in controllers) {
        try {
          // ✅ CORREGIDO: Verificación segura usando acceso a propiedades
          final _ =
              controller.text; // Esto lanzará excepción si ya está dispuesto
          controller.dispose();
        } catch (e) {
          // Si el controller ya está dispuesto o hay otro error, simplemente continuar
          print('⚠️ Controller ya dispuesto o error: $e');
        }
      }

      print('✅ ProductFormController: Todos los controladores liberados');
    } catch (e) {
      print('⚠️ ProductFormController: Error al liberar controladores: $e');
    }
  }

  /// Mostrar mensaje de error
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  /// Mostrar mensaje de éxito
  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  /// Navegar de vuelta al listado de productos
  /// Usa Get.until() para volver siempre al listado, sin importar
  /// si el usuario llegó desde Lista→Editar o Lista→Detalle→Editar
  void _navigateBackToProductList() {
    try {
      Get.until((route) => route.settings.name == '/products');
    } catch (e) {
      print('⚠️ Error en Get.until: $e, usando Get.back()');
      try {
        Get.back();
      } catch (_) {}
    }

    // Refrescar la lista después de la navegación
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        if (Get.isRegistered<ProductsController>()) {
          final productsController = Get.find<ProductsController>();
          print(
            '🔄 ProductFormController: Refrescando lista de productos',
          );
          productsController.clearFiltersAndRefresh();
        }
      } catch (e) {
        print('⚠️ Error al refrescar lista: $e');
      }
    });
  }

  /// Mostrar mensaje de información
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

  // ==================== UNIDAD DE MEDIDA ====================

  /// Establecer unidad de medida seleccionada
  void setSelectedUnit(MeasurementUnit? unit) {
    _selectedUnit.value = unit;
    print(
      '🎯 ProductFormController: Unidad seleccionada: ${unit?.displayName}',
    );
    update();
  }

  /// Obtener el texto de la unidad para mostrar en campos
  String get unitDisplayText {
    return _selectedUnit.value?.shortName ?? 'pcs';
  }

  /// Cargar unidad desde el producto existente
  void _loadUnitFromProduct(Product product) {
    if (product.unit != null) {
      final unit = getMeasurementUnitFromShortName(product.unit!);
      if (unit != null) {
        _selectedUnit.value = unit;
        print(
          '🔧 ProductFormController: Unidad cargada desde producto: ${unit.displayName}',
        );
      } else {
        // Si no se encuentra la unidad, mantener el texto original en el controller
        unitController.text = product.unit!;
        print(
          '⚠️ ProductFormController: Unidad no reconocida: ${product.unit}',
        );
      }
    }
  }
}
