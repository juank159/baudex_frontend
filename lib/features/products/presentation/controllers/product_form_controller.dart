// lib/features/products/presentation/controllers/product_form_controller.dart
import 'package:baudex_desktop/features/products/data/models/update_product_request_model.dart';
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
// ✅ IMPORT PARA CALCULADORA DE PRECIOS
import '../widgets/price_calculator_dialog.dart';
import '../../../../app/core/utils/formatters.dart';
// ✅ IMPORT PARA CONTROLLERS QUE NECESITAN REFRESH
import 'products_controller.dart';
import 'product_detail_controller.dart';

class ProductFormController extends GetxController {
  // Dependencies
  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final GetProductByIdUseCase _getProductByIdUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  // ✅ CONSTRUCTOR CORREGIDO
  ProductFormController({
    required CreateProductUseCase createProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required GetProductByIdUseCase getProductByIdUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  }) : _createProductUseCase = createProductUseCase,
       _updateProductUseCase = updateProductUseCase,
       _getProductByIdUseCase = getProductByIdUseCase,
       _getCategoriesUseCase = getCategoriesUseCase {
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

  // ✅ NUEVO: Lista de categorías disponibles
  final _availableCategories = <Category>[].obs;

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
    _isDisposing.value = true;

    // ✅ SOLUCIÓN: Retrasar el disposal para evitar conflictos con Flutter
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _disposeControllers();
        print('✅ ProductFormController: Recursos liberados exitosamente');
      } catch (e) {
        print('⚠️ ProductFormController: Error al liberar recursos: $e');
      }
    });

    super.onClose();
  }

  // ==================== PRIVATE INITIALIZATION ====================

  /// ✅ Inicialización sin bloqueos
  void _initializeForm() {
    print('⚙️ ProductFormController: Configurando formulario...');

    // Configurar valores por defecto inmediatamente (síncronos)
    _setDefaultValues();

    // ✅ NUEVO: Cargar categorías disponibles
    Future.microtask(() => _loadAvailableCategories());

    // Si es modo edición, cargar datos de forma asíncrona SIN AWAIT
    if (isEditMode) {
      print(
        '📝 ProductFormController: Modo edición detectado, cargando producto...',
      );
      _isEditing.value = true;

      // ✅ CLAVE: Usar Future.microtask para no bloquear onInit
      Future.microtask(() => loadProductForEditing());
    }

    print('✅ ProductFormController: Inicialización completada');
  }

  /// Configurar valores por defecto (operaciones síncronas únicamente)
  void _setDefaultValues() {
    // ✅ INICIALIZAR CONTROLADORES PRIMERO
    _initializeControllers();

    stockController.text = '0';
    minStockController.text = '0';
    unitController.text = 'pcs';

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

    print('✅ ProductFormController: Controladores inicializados');
  }

  // ==================== ✅ NUEVOS MÉTODOS PARA CATEGORÍAS ====================

  /// Cargar categorías disponibles
  // ✅ Cache estático para evitar recargar categorías innecesariamente
  static List<Category>? _cachedCategories;
  static DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Limpiar cache de categorías (útil cuando se crean/actualizan categorías)
  static void clearCategoriesCache() {
    _cachedCategories = null;
    _cacheTime = null;
    print('🗑️ ProductFormController: Cache de categorías limpiado');
  }

  /// Método público para cargar categorías si es necesario
  Future<void> loadAvailableCategoriesIfNeeded() async {
    if (_availableCategories.isEmpty) {
      await _loadAvailableCategories();
    }
  }

  Future<void> _loadAvailableCategories() async {
    // ✅ Verificar cache primero
    if (_cachedCategories != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
      print('📂 ProductFormController: Usando categorías desde cache');
      _availableCategories.value = _cachedCategories!;
      return;
    }

    print('📂 ProductFormController: Cargando categorías desde API...');
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
        (paginatedResult) {
          _availableCategories.value = paginatedResult.data;
          // ✅ Actualizar cache
          _cachedCategories = paginatedResult.data;
          _cacheTime = DateTime.now();
          print(
            '✅ ProductFormController: ${paginatedResult.data.length} categorías cargadas y almacenadas en cache',
          );
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

      result.fold(
        (failure) {
          print(
            '❌ ProductFormController: Error al cargar producto - ${failure.message}',
          );
          _showError('Error al cargar producto', failure.message);
          // En caso de error, volver a la lista
          Get.back();
        },
        (product) {
          print(
            '✅ ProductFormController: Producto cargado exitosamente - ${product.name}',
          );
          _originalProduct.value = product;
          _populateForm(product);
        },
      );
    } catch (e) {
      print(
        '💥 ProductFormController: Error inesperado al cargar producto - $e',
      );
      _showError('Error inesperado', 'No se pudo cargar el producto: $e');
      Get.back();
    } finally {
      _isLoading.value = false;
      print('🏁 ProductFormController: Carga de producto finalizada');
    }
  }

  /// Guardar producto (crear o actualizar)
  Future<void> saveProduct() async {
    print('💾 ProductFormController: Iniciando guardado de producto...');

    if (!_validateForm()) {
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
  bool validateForm() {
    return _validateForm();
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

  /// Generar SKU automático
  void generateSku() {
    if (nameController.text.isNotEmpty) {
      final name = nameController.text.toUpperCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(8);
      final generatedSku =
          '${name.substring(0, name.length.clamp(0, 3))}$timestamp';
      skuController.text = generatedSku;

      print('🎲 ProductFormController: SKU generado - $generatedSku');
    }
  }

  /// Validar SKU único
  Future<bool> validateSku(String sku) async {
    // TODO: Implementar validación de SKU único
    return true;
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
          price1Controller.text = AppFormatters.formatNumber(_roundToNearest100(calculatedPrices['price1'] ?? 0));
          price2Controller.text = AppFormatters.formatNumber(_roundToNearest100(calculatedPrices['price2'] ?? 0));
          price3Controller.text = AppFormatters.formatNumber(_roundToNearest100(calculatedPrices['price3'] ?? 0));
          specialPriceController.text = AppFormatters.formatNumber(_roundToNearest100(calculatedPrices['special'] ?? 0));
          
          // Aplicar también el precio de costo (sin redondeo porque es el valor base)
          if (calculatedPrices['cost'] != null) {
            costPriceController.text = AppFormatters.formatNumber(calculatedPrices['cost']!.round());
            print('🧮 ProductFormController: Precio de costo aplicado: ${costPriceController.text}');
          }
          
          print('🧮 ProductFormController: Precios aplicados a controladores');
          
          // Actualizar la UI
          update();
          
          print('🧮 ProductFormController: UI actualizada');
          
          // Mostrar mensaje de éxito
          Get.snackbar(
            'Éxito',
            'Precios calculados y aplicados correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
          
          print('🧮 ProductFormController: Callback completado');
        },
      ),
    );
  }

  /// Previsualizar producto
  void previewProduct() {
    if (!_validateForm()) return;

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

  // ==================== PRIVATE METHODS ====================

  /// Crear nuevo producto
  // Future<void> _createProduct() async {
  //   final prices = _buildPricesList();

  //   final result = await _createProductUseCase(
  //     CreateProductParams(
  //       name: nameController.text.trim(),
  //       description:
  //           descriptionController.text.trim().isEmpty
  //               ? null
  //               : descriptionController.text.trim(),
  //       sku: skuController.text.trim(),
  //       barcode:
  //           barcodeController.text.trim().isEmpty
  //               ? null
  //               : barcodeController.text.trim(),
  //       type: _productType.value,
  //       status: _productStatus.value,
  //       stock: AppFormatters.parseNumber(stockController.text) ?? 0,
  //       minStock: AppFormatters.parseNumber(minStockController.text) ?? 0,
  //       unit:
  //           unitController.text.trim().isEmpty
  //               ? null
  //               : unitController.text.trim(),
  //       weight: AppFormatters.parseNumber(weightController.text),
  //       length: AppFormatters.parseNumber(lengthController.text),
  //       width: AppFormatters.parseNumber(widthController.text),
  //       height: AppFormatters.parseNumber(heightController.text),
  //       categoryId: _selectedCategoryId.value!,
  //       prices: prices,
  //     ),
  //   );

  //   result.fold(
  //     (failure) {
  //       print(
  //         '❌ ProductFormController: Error al crear producto - ${failure.message}',
  //       );
  //       _showError('Error al crear producto', failure.message);
  //     },
  //     (product) {
  //       print(
  //         '✅ ProductFormController: Producto creado exitosamente - ${product.name}',
  //       );
  //       _showSuccess('Producto creado exitosamente');
  //       Get.back(); // Volver a la lista
  //     },
  //   );
  // }

  Future<void> _createProduct() async {
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
        unit:
            unitController.text.trim().isEmpty
                ? null
                : unitController.text.trim(),
        weight: AppFormatters.parseNumber(weightController.text),
        length: AppFormatters.parseNumber(lengthController.text),
        width: AppFormatters.parseNumber(widthController.text),
        height: AppFormatters.parseNumber(heightController.text),
        categoryId: _selectedCategoryId.value!,
        prices: prices,
      ),
    );

    result.fold(
      (failure) {
        print(
          '❌ ProductFormController: Error al crear producto - ${failure.message}',
        );
        _showError('Error al crear producto', failure.message);
      },
      (product) {
        print(
          '✅ ProductFormController: Producto creado exitosamente - ${product.name}',
        );
        _showSuccess('Producto creado exitosamente');

        // ✅ CAMBIO: Navegar a la lista de productos y refrescar datos
        if (Get.currentRoute.contains('/products/create')) {
          // Si estamos en crear producto, ir a la lista y refrescar
          Get.offAllNamed('/products');
          // Forzar refresh inmediato de la lista después de la navegación
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              // Verificar si el controller ya existe antes de buscarlo
              if (Get.isRegistered<ProductsController>()) {
                final productsController = Get.find<ProductsController>();
                print('🔄 ProductFormController: Forzando refresh después de crear producto');
                productsController.refreshProducts();
              } else {
                print('⚠️ ProductsController no registrado aún, el refresh se hará automáticamente en onInit');
              }
            } catch (e) {
              print('⚠️ Error al refrescar lista: $e');
            }
          });
        } else {
          // Si estamos en otra ruta (ej: editar), mantener el comportamiento anterior
          Get.back();
        }
      },
    );
  }

  // Future<void> _updateProduct() async {
  //   // ✅ PASO 1: Construir precios para actualización
  //   final prices = _buildPricesListForUpdateAsCreateParams();

  //   print(
  //     '🏷️ ProductFormController: Construyendo actualización con ${prices.length} precios',
  //   );
  //   for (final price in prices) {
  //     final hasId = price.notes?.startsWith('ID:') == true;
  //     print(
  //       '   - Tipo: ${price.type.name}, ${hasId ? "ACTUALIZAR" : "CREAR"}, Cantidad: ${price.amount}',
  //     );
  //   }

  //   // ✅ PASO 2: Crear el request con TODOS los campos incluyendo prices
  //   final result = await _updateProductUseCase(
  //     UpdateProductParams(
  //       id: productId,
  //       name: nameController.text.trim(),
  //       description:
  //           descriptionController.text.trim().isEmpty
  //               ? null
  //               : descriptionController.text.trim(),
  //       sku: skuController.text.trim(),
  //       barcode:
  //           barcodeController.text.trim().isEmpty
  //               ? null
  //               : barcodeController.text.trim(),
  //       type: _productType.value,
  //       status: _productStatus.value,
  //       stock: AppFormatters.parseNumber(stockController.text) ?? 0,
  //       minStock: AppFormatters.parseNumber(minStockController.text) ?? 0,
  //       unit:
  //           unitController.text.trim().isEmpty
  //               ? null
  //               : unitController.text.trim(),
  //       weight: AppFormatters.parseNumber(weightController.text),
  //       length: AppFormatters.parseNumber(lengthController.text),
  //       width: AppFormatters.parseNumber(widthController.text),
  //       height: AppFormatters.parseNumber(heightController.text),
  //       categoryId: _selectedCategoryId.value!,
  //       prices: prices, // ✅ ESTA LÍNEA ES CRÍTICA - AQUÍ ESTÁN LOS PRECIOS
  //     ),
  //   );

  //   result.fold(
  //     (failure) {
  //       print(
  //         '❌ ProductFormController: Error al actualizar producto - ${failure.message}',
  //       );
  //       _showError('Error al actualizar producto', failure.message);
  //     },
  //     (product) {
  //       print(
  //         '✅ ProductFormController: Producto actualizado exitosamente - ${product.name}',
  //       );
  //       _showSuccess('Producto actualizado exitosamente');
  //       Get.offAllNamed('/products/detail/${product.id}');
  //     },
  //   );
  // }

  Future<void> _updateProduct() async {
    try {
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

      // ✅ PASO 3: Crear el request con TODOS los campos incluyendo prices
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
          unit:
              unitController.text.trim().isEmpty
                  ? null
                  : unitController.text.trim(),
          weight: AppFormatters.parseNumber(weightController.text),
          length: AppFormatters.parseNumber(lengthController.text),
          width: AppFormatters.parseNumber(widthController.text),
          height: AppFormatters.parseNumber(heightController.text),
          categoryId: _selectedCategoryId.value!,
          prices: prices, // ✅ CRÍTICO: Incluir precios procesados
        ),
      );

      result.fold(
        (failure) {
          print(
            '❌ ProductFormController: Error al actualizar producto - ${failure.message}',
          );
          _showError('Error al actualizar producto', failure.message);
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
          Get.offAllNamed('/products/detail/${product.id}');
          // Forzar refresh del detalle después de la navegación
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              final productDetailController = Get.find<ProductDetailController>();
              productDetailController.refreshData();
            } catch (e) {
              print('🔄 No se pudo refrescar automáticamente, cargará al acceder');
            }
          });
        },
      );
    } catch (e, stackTrace) {
      print('❌ ProductFormController: Error inesperado en _updateProduct: $e');
      print('🔍 StackTrace: $stackTrace');
      _showError('Error inesperado', 'No se pudo actualizar el producto: $e');
    }
  }

  /// Validar formulario
  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      print('❌ ProductFormController: Validación de campos falló');
      return false;
    }

    if (_selectedCategoryId.value == null) {
      print('❌ ProductFormController: Categoría no seleccionada');
      _showError('Error de validación', 'Selecciona una categoría');
      return false;
    }

    if (skuController.text.trim().isEmpty) {
      print('❌ ProductFormController: SKU vacío');
      _showError('Error de validación', 'El SKU es requerido');
      return false;
    }

    print('✅ ProductFormController: Validación exitosa');
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
    unitController.text = product.unit ?? '';
    weightController.text = product.weight?.toString() ?? '';
    lengthController.text = product.length?.toString() ?? '';
    widthController.text = product.width?.toString() ?? '';
    heightController.text = product.height?.toString() ?? '';

    // ✅ ACTUALIZADO: Configurar categoría con ID y nombre
    if (product.categoryId != null) {
      final categoryName =
          getCategoryNameById(product.categoryId!) ??
          product.category?.name ??
          'Categoría desconocida';
      setCategorySelection(product.categoryId!, categoryName);
    }

    _productType.value = product.type;
    _productStatus.value = product.status;
    
    print('🔧 ProductFormController: Estado configurado - ${product.status}');
    print('🔧 ProductFormController: Tipo configurado - ${product.type}');
    
    // ✅ FORZAR actualización de la UI para que refleje los cambios
    update(); // Notifica a todos los GetBuilder
    update(['status_selector']); // Notifica específicamente al selector de estado

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
            specialPriceController.text = AppFormatters.formatNumber(price.amount);
            break;
          case PriceType.cost:
            costPriceController.text = AppFormatters.formatNumber(price.amount);
            break;
        }
      }
    }

    print('✅ ProductFormController: Formulario poblado exitosamente');
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

  /// Construir lista de precios para actualización (con IDs)
  List<UpdateProductPriceRequestModel> _buildPricesListForUpdate() {
    final prices = <UpdateProductPriceRequestModel>[];
    final originalPrices = _originalProduct.value?.prices ?? [];

    // Helper function para encontrar precio original por tipo
    String? findOriginalPriceId(PriceType type) {
      try {
        final originalPrice = originalPrices.firstWhere(
          (price) => price.type == type,
        );
        return originalPrice.id;
      } catch (e) {
        return null; // No existe precio original de este tipo
      }
    }

    if (price1Controller.text.isNotEmpty) {
      final amount = AppFormatters.parseNumber(price1Controller.text);
      if (amount != null && amount > 0) {
        prices.add(
          UpdateProductPriceRequestModel(
            id: findOriginalPriceId(
              PriceType.price1,
            ), // ID existente o null para crear
            type: PriceType.price1.name,
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
          UpdateProductPriceRequestModel(
            id: findOriginalPriceId(PriceType.price2),
            type: PriceType.price2.name,
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
          UpdateProductPriceRequestModel(
            id: findOriginalPriceId(PriceType.price3),
            type: PriceType.price3.name,
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
          UpdateProductPriceRequestModel(
            id: findOriginalPriceId(PriceType.special),
            type: PriceType.special.name,
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
          UpdateProductPriceRequestModel(
            id: findOriginalPriceId(PriceType.cost),
            type: PriceType.cost.name,
            name: 'Precio de costo',
            amount: amount,
            currency: 'COP',
          ),
        );
      }
    }

    print(
      '🏷️ ProductFormController: Construidos ${prices.length} precios para actualización',
    );
    for (final price in prices) {
      print(
        '   - Tipo: ${price.type}, ID: ${price.id ?? "NUEVO"}, Cantidad: ${price.amount}',
      );
    }

    return prices;
  }

  // List<CreateProductPriceParams> _buildPricesListForUpdateAsCreateParams() {
  //   final prices = <CreateProductPriceParams>[];
  //   final originalPrices = _originalProduct.value?.prices ?? [];

  //   // Helper function para encontrar precio original por tipo
  //   String? findOriginalPriceId(PriceType type) {
  //     try {
  //       final originalPrice = originalPrices.firstWhere(
  //         (price) => price.type == type,
  //       );
  //       return originalPrice.id;
  //     } catch (e) {
  //       return null;
  //     }
  //   }

  //   // ✅ PROCESAR TODOS LOS PRECIOS
  //   if (price1Controller.text.isNotEmpty) {
  //     final amount = AppFormatters.parseNumber(price1Controller.text);
  //     if (amount != null && amount > 0) {
  //       final priceId = findOriginalPriceId(PriceType.price1);
  //       prices.add(
  //         CreateProductPriceParams(
  //           type: PriceType.price1,
  //           name: 'Precio al público',
  //           amount: amount,
  //           currency: 'COP',
  //           notes: priceId != null ? 'ID:$priceId' : null,
  //         ),
  //       );
  //     }
  //   }

  //   if (price2Controller.text.isNotEmpty) {
  //     final amount = AppFormatters.parseNumber(price2Controller.text);
  //     if (amount != null && amount > 0) {
  //       final priceId = findOriginalPriceId(PriceType.price2);
  //       prices.add(
  //         CreateProductPriceParams(
  //           type: PriceType.price2,
  //           name: 'Precio mayorista',
  //           amount: amount,
  //           currency: 'COP',
  //           notes: priceId != null ? 'ID:$priceId' : null,
  //         ),
  //       );
  //     }
  //   }

  //   if (price3Controller.text.isNotEmpty) {
  //     final amount = AppFormatters.parseNumber(price3Controller.text);
  //     if (amount != null && amount > 0) {
  //       final priceId = findOriginalPriceId(PriceType.price3);
  //       prices.add(
  //         CreateProductPriceParams(
  //           type: PriceType.price3,
  //           name: 'Precio distribuidor',
  //           amount: amount,
  //           currency: 'COP',
  //           notes: priceId != null ? 'ID:$priceId' : null,
  //         ),
  //       );
  //     }
  //   }

  //   if (specialPriceController.text.isNotEmpty) {
  //     final amount = AppFormatters.parseNumber(specialPriceController.text);
  //     if (amount != null && amount > 0) {
  //       final priceId = findOriginalPriceId(PriceType.special);
  //       prices.add(
  //         CreateProductPriceParams(
  //           type: PriceType.special,
  //           name: 'Precio especial',
  //           amount: amount,
  //           currency: 'COP',
  //           notes: priceId != null ? 'ID:$priceId' : null,
  //         ),
  //       );
  //     }
  //   }

  //   if (costPriceController.text.isNotEmpty) {
  //     final amount = AppFormatters.parseNumber(costPriceController.text);
  //     if (amount != null && amount > 0) {
  //       final priceId = findOriginalPriceId(PriceType.cost);
  //       prices.add(
  //         CreateProductPriceParams(
  //           type: PriceType.cost,
  //           name: 'Precio de costo',
  //           amount: amount,
  //           currency: 'COP',
  //           notes: priceId != null ? 'ID:$priceId' : null,
  //         ),
  //       );
  //     }
  //   }

  //   print(
  //     '🏷️ ProductFormController: Construidos ${prices.length} precios para actualización',
  //   );
  //   for (final price in prices) {
  //     final hasId = price.notes?.startsWith('ID:') == true;
  //     print(
  //       '   - Tipo: ${price.type.name}, ${hasId ? "ACTUALIZAR" : "CREAR"}, Cantidad: ${price.amount}',
  //     );
  //   }

  //   return prices;
  // }

  // Reemplaza el método _buildPricesListForUpdateAsCreateParams en tu ProductFormController:

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
          '✅ Agregado price1: \$${amount} ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
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
          '✅ Agregado price2: \$${amount} ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
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
          '✅ Agregado price3: \$${amount} ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
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
          '✅ Agregado special: \$${amount} ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
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
          '✅ Agregado cost: \$${amount} ${priceId != null ? "(UPDATE)" : "(CREATE)"}',
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

  /// Verificar si hay cambios en los precios
  bool _hasPriceChanges() {
    if (_originalProduct.value?.prices == null) return false;

    final originalPrices = _originalProduct.value!.prices!;
    final currentPrices = _buildPricesList();

    // Comparar si hay diferencias
    for (final currentPrice in currentPrices) {
      try {
        final originalPrice = originalPrices.firstWhere(
          (price) => price.type == currentPrice.type,
        );

        if (originalPrice.amount != currentPrice.amount) {
          return true;
        }
      } catch (e) {
        // No existe precio original de este tipo, es un precio nuevo
        return true;
      }
    }

    return false;
  }

  /// Calcular precios sugeridos
  void _calculateSuggestedPrices() {
    final costText = costPriceController.text;
    if (costText.isEmpty) return;

    final cost = AppFormatters.parseNumber(costText);
    if (cost == null || cost <= 0) return;

    price1Controller.text = (cost * 1.30).toStringAsFixed(2); // +30%
    price2Controller.text = (cost * 1.20).toStringAsFixed(2); // +20%
    price3Controller.text = (cost * 1.15).toStringAsFixed(2); // +15%
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
  }

  /// Disponer controladores de forma segura
  void _disposeControllers() {
    if (_isDisposing.value) {
      print('⚠️ ProductFormController: Disposal ya en progreso, saltando...');
      return;
    }

    try {
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
      ];

      for (final controller in controllers) {
        try {
          controller.dispose();
        } catch (e) {
          print('⚠️ Error disposing individual controller: $e');
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
}
