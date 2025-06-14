// // lib/features/products/presentation/controllers/product_form_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../domain/entities/product.dart';
// import '../../domain/entities/product_price.dart';
// import '../../domain/repositories/product_repository.dart';
// import '../../domain/usecases/create_product_usecase.dart';
// import '../../domain/usecases/update_product_usecase.dart';
// import '../../domain/usecases/get_product_by_id_usecase.dart';

// class ProductFormController extends GetxController {
//   // Dependencies
//   final CreateProductUseCase _createProductUseCase;
//   final UpdateProductUseCase _updateProductUseCase;
//   final GetProductByIdUseCase _getProductByIdUseCase;

//   ProductFormController({
//     required CreateProductUseCase createProductUseCase,
//     required UpdateProductUseCase updateProductUseCase,
//     required GetProductByIdUseCase getProductByIdUseCase,
//   }) : _createProductUseCase = createProductUseCase,
//        _updateProductUseCase = updateProductUseCase,
//        _getProductByIdUseCase = getProductByIdUseCase {
//     print('🎮 ProductFormController: Instancia creada correctamente');
//   }

//   // ==================== OBSERVABLES ====================

//   // Estados
//   final _isLoading = false.obs;
//   final _isSaving = false.obs;
//   final _isEditing = false.obs;

//   // Datos
//   final Rxn<Product> _originalProduct = Rxn<Product>();
//   final _selectedCategoryId = Rxn<String>();
//   final _productType = ProductType.product.obs;
//   final _productStatus = ProductStatus.active.obs;

//   // Form Key
//   final formKey = GlobalKey<FormState>();

//   // Text Controllers - Información básica
//   final nameController = TextEditingController();
//   final descriptionController = TextEditingController();
//   final skuController = TextEditingController();
//   final barcodeController = TextEditingController();

//   // Text Controllers - Stock y medidas
//   final stockController = TextEditingController();
//   final minStockController = TextEditingController();
//   final unitController = TextEditingController();
//   final weightController = TextEditingController();
//   final lengthController = TextEditingController();
//   final widthController = TextEditingController();
//   final heightController = TextEditingController();

//   // Text Controllers - Precios
//   final price1Controller = TextEditingController();
//   final price2Controller = TextEditingController();
//   final price3Controller = TextEditingController();
//   final specialPriceController = TextEditingController();
//   final costPriceController = TextEditingController();

//   // ==================== GETTERS ====================

//   bool get isLoading => _isLoading.value;
//   bool get isSaving => _isSaving.value;
//   bool get isEditing => _isEditing.value;

//   Product? get originalProduct => _originalProduct.value;
//   String? get selectedCategoryId => _selectedCategoryId.value;
//   ProductType get productType => _productType.value;
//   ProductStatus get productStatus => _productStatus.value;

//   String get productId => Get.parameters['id'] ?? '';
//   bool get isEditMode => productId.isNotEmpty;
//   String get pageTitle => isEditMode ? 'Editar Producto' : 'Crear Producto';
//   String get saveButtonText => isEditMode ? 'Actualizar' : 'Crear';

//   // ==================== LIFECYCLE ====================

//   @override
//   void onInit() {
//     super.onInit();
//     print('🚀 ProductFormController: Inicializando...');
//     print(
//       '🔍 ProductFormController: isEditMode = $isEditMode, productId = "$productId"',
//     );

//     // ✅ SOLUCIÓN: Mover la carga asíncrona fuera de onInit
//     _initializeForm();
//   }

//   @override
//   void onClose() {
//     print('🔚 ProductFormController: Liberando recursos...');
//     _disposeControllers();
//     super.onClose();
//   }

//   // ==================== PRIVATE INITIALIZATION ====================

//   /// ✅ Inicialización sin bloqueos
//   void _initializeForm() {
//     print('⚙️ ProductFormController: Configurando formulario...');

//     // Configurar valores por defecto inmediatamente (síncronos)
//     _setDefaultValues();

//     // Si es modo edición, cargar datos de forma asíncrona SIN AWAIT
//     if (isEditMode) {
//       print(
//         '📝 ProductFormController: Modo edición detectado, cargando producto...',
//       );
//       _isEditing.value = true;

//       // ✅ CLAVE: Usar Future.microtask para no bloquear onInit
//       Future.microtask(() => loadProductForEditing());
//     }

//     print('✅ ProductFormController: Inicialización completada');
//   }

//   /// Configurar valores por defecto (operaciones síncronas únicamente)
//   void _setDefaultValues() {
//     stockController.text = '0';
//     minStockController.text = '0';
//     unitController.text = 'pcs';

//     // Configurar valores por defecto para los observables
//     _productType.value = ProductType.product;
//     _productStatus.value = ProductStatus.active;

//     print('✅ ProductFormController: Valores por defecto configurados');
//   }

//   // ==================== PUBLIC METHODS ====================

//   /// Cargar producto para edición (ahora completamente asíncrono)
//   Future<void> loadProductForEditing() async {
//     print(
//       '📥 ProductFormController: Iniciando carga de producto para edición...',
//     );
//     _isLoading.value = true;

//     try {
//       final result = await _getProductByIdUseCase(
//         GetProductByIdParams(id: productId),
//       );

//       result.fold(
//         (failure) {
//           print(
//             '❌ ProductFormController: Error al cargar producto - ${failure.message}',
//           );
//           _showError('Error al cargar producto', failure.message);
//           // En caso de error, volver a la lista
//           Get.back();
//         },
//         (product) {
//           print(
//             '✅ ProductFormController: Producto cargado exitosamente - ${product.name}',
//           );
//           _originalProduct.value = product;
//           _populateForm(product);
//         },
//       );
//     } catch (e) {
//       print(
//         '💥 ProductFormController: Error inesperado al cargar producto - $e',
//       );
//       _showError('Error inesperado', 'No se pudo cargar el producto: $e');
//       Get.back();
//     } finally {
//       _isLoading.value = false;
//       print('🏁 ProductFormController: Carga de producto finalizada');
//     }
//   }

//   /// Guardar producto (crear o actualizar)
//   Future<void> saveProduct() async {
//     print('💾 ProductFormController: Iniciando guardado de producto...');

//     if (!_validateForm()) {
//       print('❌ ProductFormController: Validación de formulario falló');
//       return;
//     }

//     _isSaving.value = true;

//     try {
//       if (isEditMode) {
//         print('🔄 ProductFormController: Actualizando producto existente...');
//         await _updateProduct();
//       } else {
//         print('🆕 ProductFormController: Creando nuevo producto...');
//         await _createProduct();
//       }
//     } catch (e) {
//       print('💥 ProductFormController: Error inesperado al guardar - $e');
//       _showError('Error inesperado', 'No se pudo guardar el producto: $e');
//     } finally {
//       _isSaving.value = false;
//       print('🏁 ProductFormController: Guardado finalizado');
//     }
//   }

//   /// Validar formulario
//   bool validateForm() {
//     return _validateForm();
//   }

//   /// Limpiar formulario
//   void clearForm() {
//     print('🧹 ProductFormController: Limpiando formulario...');

//     formKey.currentState?.reset();
//     _clearControllers();
//     _selectedCategoryId.value = null;
//     _productType.value = ProductType.product;
//     _productStatus.value = ProductStatus.active;

//     print('✅ ProductFormController: Formulario limpiado');
//   }

//   // ==================== FORM METHODS ====================

//   /// Establecer categoría seleccionada
//   void setCategory(String categoryId) {
//     _selectedCategoryId.value = categoryId;
//     print('📂 ProductFormController: Categoría seleccionada - $categoryId');
//   }

//   /// Cambiar tipo de producto
//   void setProductType(ProductType type) {
//     _productType.value = type;
//     print('🏷️ ProductFormController: Tipo de producto - ${type.name}');
//   }

//   /// Cambiar estado de producto
//   void setProductStatus(ProductStatus status) {
//     _productStatus.value = status;
//     print('🔄 ProductFormController: Estado de producto - ${status.name}');
//   }

//   /// Generar SKU automático
//   void generateSku() {
//     if (nameController.text.isNotEmpty) {
//       final name = nameController.text.toUpperCase();
//       final timestamp = DateTime.now().millisecondsSinceEpoch
//           .toString()
//           .substring(8);
//       final generatedSku =
//           '${name.substring(0, name.length.clamp(0, 3))}$timestamp';
//       skuController.text = generatedSku;

//       print('🎲 ProductFormController: SKU generado - $generatedSku');
//     }
//   }

//   /// Validar SKU único
//   Future<bool> validateSku(String sku) async {
//     // TODO: Implementar validación de SKU único
//     return true;
//   }

//   /// Calcular margen de ganancia
//   double calculateMargin(double costPrice, double sellPrice) {
//     if (costPrice <= 0) return 0;
//     return ((sellPrice - costPrice) / costPrice) * 100;
//   }

//   /// Validar código de barras
//   bool validateBarcode(String barcode) {
//     // Validación básica de código de barras
//     if (barcode.isEmpty) return true; // Opcional
//     return barcode.length >= 8 && barcode.length <= 18;
//   }

//   // ==================== UI HELPERS ====================

//   /// Mostrar selector de categoría
//   void showCategorySelector() {
//     // TODO: Implementar selector de categoría
//     _showInfo('Selector', 'Selector de categorías pendiente de implementar');
//   }

//   /// Mostrar calculadora de precios
//   void showPriceCalculator() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Calculadora de Precios'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Calcular precios basado en el costo'),
//             const SizedBox(height: 16),
//             TextField(
//               controller: costPriceController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Precio de Costo',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text('Márgenes sugeridos:'),
//             const Text('Precio 1: +30%'),
//             const Text('Precio 2: +20%'),
//             const Text('Precio 3: +15%'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               _calculateSuggestedPrices();
//               Get.back();
//             },
//             child: const Text('Calcular'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Previsualizar producto
//   void previewProduct() {
//     if (!_validateForm()) return;

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Previsualización'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Nombre: ${nameController.text}'),
//               Text('SKU: ${skuController.text}'),
//               Text('Tipo: ${_productType.value.name}'),
//               Text('Estado: ${_productStatus.value.name}'),
//               Text('Stock: ${stockController.text}'),
//               if (price1Controller.text.isNotEmpty)
//                 Text('Precio 1: \$${price1Controller.text}'),
//               if (costPriceController.text.isNotEmpty)
//                 Text('Costo: \$${costPriceController.text}'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               saveProduct();
//             },
//             child: Text(saveButtonText),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== PRIVATE METHODS ====================

//   /// Crear nuevo producto
//   Future<void> _createProduct() async {
//     final prices = _buildPricesList();

//     final result = await _createProductUseCase(
//       CreateProductParams(
//         name: nameController.text.trim(),
//         description:
//             descriptionController.text.trim().isEmpty
//                 ? null
//                 : descriptionController.text.trim(),
//         sku: skuController.text.trim(),
//         barcode:
//             barcodeController.text.trim().isEmpty
//                 ? null
//                 : barcodeController.text.trim(),
//         type: _productType.value,
//         status: _productStatus.value,
//         stock: double.tryParse(stockController.text) ?? 0,
//         minStock: double.tryParse(minStockController.text) ?? 0,
//         unit:
//             unitController.text.trim().isEmpty
//                 ? null
//                 : unitController.text.trim(),
//         weight: double.tryParse(weightController.text),
//         length: double.tryParse(lengthController.text),
//         width: double.tryParse(widthController.text),
//         height: double.tryParse(heightController.text),
//         categoryId: _selectedCategoryId.value!,
//         prices: prices,
//       ),
//     );

//     result.fold(
//       (failure) {
//         print(
//           '❌ ProductFormController: Error al crear producto - ${failure.message}',
//         );
//         _showError('Error al crear producto', failure.message);
//       },
//       (product) {
//         print(
//           '✅ ProductFormController: Producto creado exitosamente - ${product.name}',
//         );
//         _showSuccess('Producto creado exitosamente');
//         Get.back(); // Volver a la lista
//       },
//     );
//   }

//   /// Actualizar producto existente
//   Future<void> _updateProduct() async {
//     final result = await _updateProductUseCase(
//       UpdateProductParams(
//         id: productId,
//         name: nameController.text.trim(),
//         description:
//             descriptionController.text.trim().isEmpty
//                 ? null
//                 : descriptionController.text.trim(),
//         sku: skuController.text.trim(),
//         barcode:
//             barcodeController.text.trim().isEmpty
//                 ? null
//                 : barcodeController.text.trim(),
//         type: _productType.value,
//         status: _productStatus.value,
//         stock: double.tryParse(stockController.text) ?? 0,
//         minStock: double.tryParse(minStockController.text) ?? 0,
//         unit:
//             unitController.text.trim().isEmpty
//                 ? null
//                 : unitController.text.trim(),
//         weight: double.tryParse(weightController.text),
//         length: double.tryParse(lengthController.text),
//         width: double.tryParse(widthController.text),
//         height: double.tryParse(heightController.text),
//         categoryId: _selectedCategoryId.value!,
//       ),
//     );

//     result.fold(
//       (failure) {
//         print(
//           '❌ ProductFormController: Error al actualizar producto - ${failure.message}',
//         );
//         _showError('Error al actualizar producto', failure.message);
//       },
//       (product) {
//         print(
//           '✅ ProductFormController: Producto actualizado exitosamente - ${product.name}',
//         );
//         _showSuccess('Producto actualizado exitosamente');
//         Get.back(); // Volver a los detalles o lista
//       },
//     );
//   }

//   /// Validar formulario
//   bool _validateForm() {
//     if (!formKey.currentState!.validate()) {
//       print('❌ ProductFormController: Validación de campos falló');
//       return false;
//     }

//     if (_selectedCategoryId.value == null) {
//       print('❌ ProductFormController: Categoría no seleccionada');
//       _showError('Error de validación', 'Selecciona una categoría');
//       return false;
//     }

//     if (skuController.text.trim().isEmpty) {
//       print('❌ ProductFormController: SKU vacío');
//       _showError('Error de validación', 'El SKU es requerido');
//       return false;
//     }

//     print('✅ ProductFormController: Validación exitosa');
//     return true;
//   }

//   /// Poblar formulario con datos del producto
//   void _populateForm(Product product) {
//     print(
//       '📝 ProductFormController: Poblando formulario con datos del producto...',
//     );

//     nameController.text = product.name;
//     descriptionController.text = product.description ?? '';
//     skuController.text = product.sku;
//     barcodeController.text = product.barcode ?? '';
//     stockController.text = product.stock.toString();
//     minStockController.text = product.minStock.toString();
//     unitController.text = product.unit ?? '';
//     weightController.text = product.weight?.toString() ?? '';
//     lengthController.text = product.length?.toString() ?? '';
//     widthController.text = product.width?.toString() ?? '';
//     heightController.text = product.height?.toString() ?? '';

//     _selectedCategoryId.value = product.categoryId;
//     _productType.value = product.type;
//     _productStatus.value = product.status;

//     // Poblar precios si existen
//     if (product.prices != null) {
//       for (final price in product.prices!) {
//         switch (price.type) {
//           case PriceType.price1:
//             price1Controller.text = price.amount.toString();
//             break;
//           case PriceType.price2:
//             price2Controller.text = price.amount.toString();
//             break;
//           case PriceType.price3:
//             price3Controller.text = price.amount.toString();
//             break;
//           case PriceType.special:
//             specialPriceController.text = price.amount.toString();
//             break;
//           case PriceType.cost:
//             costPriceController.text = price.amount.toString();
//             break;
//         }
//       }
//     }

//     print('✅ ProductFormController: Formulario poblado exitosamente');
//   }

//   /// Construir lista de precios
//   List<CreateProductPriceParams> _buildPricesList() {
//     final prices = <CreateProductPriceParams>[];

//     if (price1Controller.text.isNotEmpty) {
//       final amount = double.tryParse(price1Controller.text);
//       if (amount != null && amount > 0) {
//         prices.add(
//           CreateProductPriceParams(
//             type: PriceType.price1,
//             name: 'Precio al público',
//             amount: amount,
//             currency: 'COP',
//           ),
//         );
//       }
//     }

//     if (price2Controller.text.isNotEmpty) {
//       final amount = double.tryParse(price2Controller.text);
//       if (amount != null && amount > 0) {
//         prices.add(
//           CreateProductPriceParams(
//             type: PriceType.price2,
//             name: 'Precio mayorista',
//             amount: amount,
//             currency: 'COP',
//           ),
//         );
//       }
//     }

//     if (price3Controller.text.isNotEmpty) {
//       final amount = double.tryParse(price3Controller.text);
//       if (amount != null && amount > 0) {
//         prices.add(
//           CreateProductPriceParams(
//             type: PriceType.price3,
//             name: 'Precio distribuidor',
//             amount: amount,
//             currency: 'COP',
//           ),
//         );
//       }
//     }

//     if (specialPriceController.text.isNotEmpty) {
//       final amount = double.tryParse(specialPriceController.text);
//       if (amount != null && amount > 0) {
//         prices.add(
//           CreateProductPriceParams(
//             type: PriceType.special,
//             name: 'Precio especial',
//             amount: amount,
//             currency: 'COP',
//           ),
//         );
//       }
//     }

//     if (costPriceController.text.isNotEmpty) {
//       final amount = double.tryParse(costPriceController.text);
//       if (amount != null && amount > 0) {
//         prices.add(
//           CreateProductPriceParams(
//             type: PriceType.cost,
//             name: 'Precio de costo',
//             amount: amount,
//             currency: 'COP',
//           ),
//         );
//       }
//     }

//     return prices;
//   }

//   /// Calcular precios sugeridos
//   void _calculateSuggestedPrices() {
//     final costText = costPriceController.text;
//     if (costText.isEmpty) return;

//     final cost = double.tryParse(costText);
//     if (cost == null || cost <= 0) return;

//     price1Controller.text = (cost * 1.30).toStringAsFixed(2); // +30%
//     price2Controller.text = (cost * 1.20).toStringAsFixed(2); // +20%
//     price3Controller.text = (cost * 1.15).toStringAsFixed(2); // +15%
//   }

//   /// Limpiar controladores
//   void _clearControllers() {
//     nameController.clear();
//     descriptionController.clear();
//     skuController.clear();
//     barcodeController.clear();
//     stockController.clear();
//     minStockController.clear();
//     unitController.clear();
//     weightController.clear();
//     lengthController.clear();
//     widthController.clear();
//     heightController.clear();
//     price1Controller.clear();
//     price2Controller.clear();
//     price3Controller.clear();
//     specialPriceController.clear();
//     costPriceController.clear();
//   }

//   /// Disponer controladores
//   void _disposeControllers() {
//     nameController.dispose();
//     descriptionController.dispose();
//     skuController.dispose();
//     barcodeController.dispose();
//     stockController.dispose();
//     minStockController.dispose();
//     unitController.dispose();
//     weightController.dispose();
//     lengthController.dispose();
//     widthController.dispose();
//     heightController.dispose();
//     price1Controller.dispose();
//     price2Controller.dispose();
//     price3Controller.dispose();
//     specialPriceController.dispose();
//     costPriceController.dispose();
//   }

//   /// Mostrar mensaje de error
//   void _showError(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.red.shade100,
//       colorText: Colors.red.shade800,
//       icon: const Icon(Icons.error, color: Colors.red),
//       duration: const Duration(seconds: 4),
//     );
//   }

//   /// Mostrar mensaje de éxito
//   void _showSuccess(String message) {
//     Get.snackbar(
//       'Éxito',
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.shade100,
//       colorText: Colors.green.shade800,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 3),
//     );
//   }

//   /// Mostrar mensaje de información
//   void _showInfo(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.blue.shade100,
//       colorText: Colors.blue.shade800,
//       icon: const Icon(Icons.info, color: Colors.blue),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

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
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final skuController = TextEditingController();
  final barcodeController = TextEditingController();

  // Text Controllers - Stock y medidas
  final stockController = TextEditingController();
  final minStockController = TextEditingController();
  final unitController = TextEditingController();
  final weightController = TextEditingController();
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();

  // Text Controllers - Precios
  final price1Controller = TextEditingController();
  final price2Controller = TextEditingController();
  final price3Controller = TextEditingController();
  final specialPriceController = TextEditingController();
  final costPriceController = TextEditingController();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isEditing => _isEditing.value;
  bool get isLoadingCategories => _isLoadingCategories.value; // ✅ NUEVO

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
    print('🔚 ProductFormController: Liberando recursos...');
    _disposeControllers();
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
    stockController.text = '0';
    minStockController.text = '0';
    unitController.text = 'pcs';

    // Configurar valores por defecto para los observables
    _productType.value = ProductType.product;
    _productStatus.value = ProductStatus.active;

    print('✅ ProductFormController: Valores por defecto configurados');
  }

  // ==================== ✅ NUEVOS MÉTODOS PARA CATEGORÍAS ====================

  /// Cargar categorías disponibles
  Future<void> _loadAvailableCategories() async {
    print('📂 ProductFormController: Cargando categorías disponibles...');
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
          print(
            '✅ ProductFormController: ${paginatedResult.data.length} categorías cargadas',
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
    Get.dialog(
      AlertDialog(
        title: const Text('Calculadora de Precios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Calcular precios basado en el costo'),
            const SizedBox(height: 16),
            TextField(
              controller: costPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio de Costo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Márgenes sugeridos:'),
            const Text('Precio 1: +30%'),
            const Text('Precio 2: +20%'),
            const Text('Precio 3: +15%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _calculateSuggestedPrices();
              Get.back();
            },
            child: const Text('Calcular'),
          ),
        ],
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
        stock: double.tryParse(stockController.text) ?? 0,
        minStock: double.tryParse(minStockController.text) ?? 0,
        unit:
            unitController.text.trim().isEmpty
                ? null
                : unitController.text.trim(),
        weight: double.tryParse(weightController.text),
        length: double.tryParse(lengthController.text),
        width: double.tryParse(widthController.text),
        height: double.tryParse(heightController.text),
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
        Get.back(); // Volver a la lista
      },
    );
  }

  /// Actualizar producto existente
  Future<void> _updateProduct() async {
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
        stock: double.tryParse(stockController.text) ?? 0,
        minStock: double.tryParse(minStockController.text) ?? 0,
        unit:
            unitController.text.trim().isEmpty
                ? null
                : unitController.text.trim(),
        weight: double.tryParse(weightController.text),
        length: double.tryParse(lengthController.text),
        width: double.tryParse(widthController.text),
        height: double.tryParse(heightController.text),
        categoryId: _selectedCategoryId.value!,
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
        _showSuccess('Producto actualizado exitosamente');
        Get.back(); // Volver a los detalles o lista
      },
    );
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
    stockController.text = product.stock.toString();
    minStockController.text = product.minStock.toString();
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

    // Poblar precios si existen
    if (product.prices != null) {
      for (final price in product.prices!) {
        switch (price.type) {
          case PriceType.price1:
            price1Controller.text = price.amount.toString();
            break;
          case PriceType.price2:
            price2Controller.text = price.amount.toString();
            break;
          case PriceType.price3:
            price3Controller.text = price.amount.toString();
            break;
          case PriceType.special:
            specialPriceController.text = price.amount.toString();
            break;
          case PriceType.cost:
            costPriceController.text = price.amount.toString();
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
      final amount = double.tryParse(price1Controller.text);
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
      final amount = double.tryParse(price2Controller.text);
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
      final amount = double.tryParse(price3Controller.text);
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
      final amount = double.tryParse(specialPriceController.text);
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
      final amount = double.tryParse(costPriceController.text);
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

  /// Calcular precios sugeridos
  void _calculateSuggestedPrices() {
    final costText = costPriceController.text;
    if (costText.isEmpty) return;

    final cost = double.tryParse(costText);
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

  /// Disponer controladores
  void _disposeControllers() {
    nameController.dispose();
    descriptionController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    stockController.dispose();
    minStockController.dispose();
    unitController.dispose();
    weightController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    price1Controller.dispose();
    price2Controller.dispose();
    price3Controller.dispose();
    specialPriceController.dispose();
    costPriceController.dispose();
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
