// // lib/features/products/presentation/controllers/product_detail_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../domain/entities/product.dart';
// import '../../domain/usecases/get_product_by_id_usecase.dart';
// import '../../domain/usecases/update_product_stock_usecase.dart';
// import '../../domain/usecases/delete_product_usecase.dart';

// class ProductDetailController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   // Dependencies
//   final GetProductByIdUseCase _getProductByIdUseCase;
//   final UpdateProductStockUseCase _updateProductStockUseCase;
//   final DeleteProductUseCase _deleteProductUseCase;

//   ProductDetailController(
//     find, {
//     required GetProductByIdUseCase getProductByIdUseCase,
//     required UpdateProductStockUseCase updateProductStockUseCase,
//     required DeleteProductUseCase deleteProductUseCase,
//   }) : _getProductByIdUseCase = getProductByIdUseCase,
//        _updateProductStockUseCase = updateProductStockUseCase,
//        _deleteProductUseCase = deleteProductUseCase;

//   // ==================== OBSERVABLES ====================

//   // Estados de carga
//   final _isLoading = false.obs;
//   final _isUpdatingStock = false.obs;
//   final _isDeleting = false.obs;

//   // Datos
//   final Rxn<Product> _product = Rxn<Product>();

//   // UI Controllers
//   late TabController tabController;
//   final stockController = TextEditingController();

//   // ==================== GETTERS ====================

//   bool get isLoading => _isLoading.value;
//   bool get isUpdatingStock => _isUpdatingStock.value;
//   bool get isDeleting => _isDeleting.value;

//   Product? get product => _product.value;
//   bool get hasProduct => _product.value != null;

//   String get productId => Get.parameters['id'] ?? '';

//   // Información derivada del producto
//   String get productName => product?.name ?? '';
//   String get productSku => product?.sku ?? '';
//   bool get isActive => product?.isActive ?? false;
//   bool get isInStock => product?.isInStock ?? false;
//   bool get isLowStock => product?.isLowStock ?? false;
//   double get currentStock => product?.stock ?? 0;
//   double get minStock => product?.minStock ?? 0;
//   String? get primaryImage => product?.primaryImage;

//   // ==================== LIFECYCLE ====================

//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 3, vsync: this);

//     if (productId.isNotEmpty) {
//       loadProductDetails();
//     } else {
//       _showError('Error', 'ID de producto no válido');
//     }
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     stockController.dispose();
//     super.onClose();
//   }

//   // ==================== PUBLIC METHODS ====================

//   /// Cargar detalles del producto
//   Future<void> loadProductDetails() async {
//     _isLoading.value = true;

//     try {
//       final result = await _getProductByIdUseCase(
//         GetProductByIdParams(id: productId),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al cargar producto', failure.message);
//         },
//         (product) {
//           _product.value = product;
//         },
//       );
//     } finally {
//       _isLoading.value = false;
//     }
//   }

//   /// Refrescar datos
//   Future<void> refreshData() async {
//     await loadProductDetails();
//   }

//   /// Actualizar stock del producto
//   Future<void> updateStock(double quantity, String operation) async {
//     if (!hasProduct) return;

//     _isUpdatingStock.value = true;

//     try {
//       final result = await _updateProductStockUseCase(
//         UpdateProductStockParams(
//           id: productId,
//           quantity: quantity,
//           operation: operation,
//         ),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al actualizar stock', failure.message);
//         },
//         (updatedProduct) {
//           _product.value = updatedProduct;
//           _showSuccess('Stock actualizado exitosamente');
//           stockController.clear();
//         },
//       );
//     } finally {
//       _isUpdatingStock.value = false;
//     }
//   }

//   /// Eliminar producto
//   Future<void> deleteProduct() async {
//     if (!hasProduct) return;

//     _isDeleting.value = true;

//     try {
//       final result = await _deleteProductUseCase(
//         DeleteProductParams(id: productId),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al eliminar producto', failure.message);
//         },
//         (_) {
//           _showSuccess('Producto eliminado exitosamente');
//           Get.back(); // Volver a la lista de productos
//         },
//       );
//     } finally {
//       _isDeleting.value = false;
//     }
//   }

//   // ==================== UI ACTIONS ====================

//   /// Ir a editar producto
//   void goToEditProduct() {
//     if (!hasProduct) return;
//     Get.toNamed('/products/edit/$productId');
//   }

//   /// Mostrar diálogo para actualizar stock
//   void showStockDialog() {
//     if (!hasProduct) return;

//     stockController.clear();

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Actualizar Stock'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Stock actual: ${currentStock.toStringAsFixed(2)}'),
//             const SizedBox(height: 16),
//             TextField(
//               controller: stockController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Cantidad',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               final quantity = double.tryParse(stockController.text);
//               if (quantity != null && quantity > 0) {
//                 Get.back();
//                 updateStock(quantity, 'subtract');
//               }
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.orange),
//             child: const Text('Restar'),
//           ),
//           TextButton(
//             onPressed: () {
//               final quantity = double.tryParse(stockController.text);
//               if (quantity != null && quantity > 0) {
//                 Get.back();
//                 updateStock(quantity, 'add');
//               }
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.green),
//             child: const Text('Sumar'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Confirmar eliminación
//   void confirmDelete() {
//     if (!hasProduct) return;

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Eliminar Producto'),
//         content: Text(
//           '¿Estás seguro que deseas eliminar el producto "${productName}"?\n\n'
//           'Esta acción no se puede deshacer.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               deleteProduct();
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Eliminar'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Mostrar diálogo de estado
//   void showStatusDialog() {
//     if (!hasProduct) return;

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Cambiar Estado'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Estado actual: ${isActive ? "Activo" : "Inactivo"}'),
//             const SizedBox(height: 16),
//             Text(
//               '¿Deseas ${isActive ? "desactivar" : "activar"} este producto?',
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               // TODO: Implementar cambio de estado
//               _showInfo(
//                 'Funcionalidad pendiente',
//                 'Cambio de estado pendiente de implementar',
//               );
//             },
//             child: Text(isActive ? 'Desactivar' : 'Activar'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Ir a la categoría padre
//   void goToParentCategory() {
//     if (product?.category != null) {
//       Get.toNamed('/categories/detail/${product!.category!.id}');
//     }
//   }

//   /// Compartir producto
//   void shareProduct() {
//     if (!hasProduct) return;

//     final shareText = '''
// Producto: ${productName}
// SKU: ${productSku}
// Stock: ${currentStock.toStringAsFixed(2)}
// Estado: ${isActive ? "Activo" : "Inactivo"}
// ''';

//     // TODO: Implementar funcionalidad de compartir
//     Get.snackbar(
//       'Compartir',
//       'Funcionalidad de compartir pendiente de implementar',
//       snackPosition: SnackPosition.TOP,
//     );
//   }

//   /// Imprimir etiqueta
//   void printLabel() {
//     if (!hasProduct) return;

//     // TODO: Implementar funcionalidad de impresión
//     _showInfo(
//       'Imprimir',
//       'Funcionalidad de impresión pendiente de implementar',
//     );
//   }

//   /// Generar reporte
//   void generateReport() {
//     if (!hasProduct) return;

//     // TODO: Implementar generación de reportes
//     _showInfo('Reporte', 'Generación de reportes pendiente de implementar');
//   }

//   // ==================== HELPER METHODS ====================

//   /// Obtener color según el estado del stock
//   Color getStockStatusColor() {
//     if (!hasProduct) return Colors.grey;

//     if (!isInStock) return Colors.red;
//     if (isLowStock) return Colors.orange;
//     return Colors.green;
//   }

//   /// Obtener texto del estado del stock
//   String getStockStatusText() {
//     if (!hasProduct) return 'Sin datos';

//     if (!isInStock) return 'Sin stock';
//     if (isLowStock) return 'Stock bajo';
//     return 'Stock normal';
//   }

//   /// Obtener precio por tipo
//   double? getPriceByType(String priceType) {
//     if (!hasProduct || product!.prices == null) return null;

//     for (final price in product!.prices!) {
//       if (price.type.name == priceType && price.isActive) {
//         return price.finalAmount;
//       }
//     }
//     return null;
//   }

//   /// Obtener precio formateado
//   String getFormattedPrice(String priceType) {
//     final price = getPriceByType(priceType);
//     if (price == null) return 'No disponible';

//     return '\${price.toStringAsFixed(2)}';
//   }

//   /// Verificar si tiene descuento
//   bool hasDiscount(String priceType) {
//     if (!hasProduct || product!.prices == null) return false;

//     for (final price in product!.prices!) {
//       if (price.type.name == priceType && price.isActive) {
//         return price.hasDiscount;
//       }
//     }
//     return false;
//   }

//   // ==================== PRIVATE METHODS ====================

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

// lib/features/products/presentation/controllers/product_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/update_product_stock_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';

class ProductDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Dependencies
  final GetProductByIdUseCase _getProductByIdUseCase;
  final UpdateProductStockUseCase _updateProductStockUseCase;
  final DeleteProductUseCase _deleteProductUseCase;

  // ✅ CONSTRUCTOR COMPLETAMENTE CORREGIDO
  ProductDetailController({
    required GetProductByIdUseCase getProductByIdUseCase,
    required UpdateProductStockUseCase updateProductStockUseCase,
    required DeleteProductUseCase deleteProductUseCase,
  }) : _getProductByIdUseCase = getProductByIdUseCase,
       _updateProductStockUseCase = updateProductStockUseCase,
       _deleteProductUseCase = deleteProductUseCase {
    print('🎮 ProductDetailController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================
  final _isLoading = false.obs;
  final _isUpdatingStock = false.obs;
  final _isDeleting = false.obs;
  final Rxn<Product> _product = Rxn<Product>();

  // UI Controllers
  late TabController tabController;
  final stockController = TextEditingController();

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading.value;
  bool get isUpdatingStock => _isUpdatingStock.value;
  bool get isDeleting => _isDeleting.value;
  Product? get product => _product.value;
  bool get hasProduct => _product.value != null;
  String get productId => Get.parameters['id'] ?? '';
  String get productName => product?.name ?? '';
  String get productSku => product?.sku ?? '';
  bool get isActive => product?.isActive ?? false;
  bool get isInStock => product?.isInStock ?? false;
  bool get isLowStock => product?.isLowStock ?? false;
  double get currentStock => product?.stock ?? 0;
  double get minStock => product?.minStock ?? 0;
  String? get primaryImage => product?.primaryImage;

  // ==================== LIFECYCLE ====================
  @override
  void onInit() {
    super.onInit();
    print('🚀 ProductDetailController: Inicializando con ID: $productId');

    tabController = TabController(length: 3, vsync: this);

    if (productId.isNotEmpty) {
      loadProductDetails();
    } else {
      _showError('Error', 'ID de producto no válido');
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    stockController.dispose();
    super.onClose();
    print('🔚 ProductDetailController: Recursos liberados');
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar detalles del producto
  Future<void> loadProductDetails() async {
    print('📥 Cargando detalles del producto: $productId');
    _isLoading.value = true;

    try {
      final result = await _getProductByIdUseCase(
        GetProductByIdParams(id: productId),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar producto: ${failure.message}');
          _showError('Error al cargar producto', failure.message);
        },
        (product) {
          print('✅ Producto cargado exitosamente: ${product.name}');
          _product.value = product;
        },
      );
    } catch (e) {
      print('💥 Error inesperado: $e');
      _showError('Error inesperado', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refrescar datos
  Future<void> refreshData() async {
    await loadProductDetails();
  }

  /// Actualizar stock del producto
  Future<void> updateStock(double quantity, String operation) async {
    if (!hasProduct) return;

    _isUpdatingStock.value = true;

    try {
      final result = await _updateProductStockUseCase(
        UpdateProductStockParams(
          id: productId,
          quantity: quantity,
          operation: operation,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al actualizar stock', failure.message);
        },
        (updatedProduct) {
          _product.value = updatedProduct;
          _showSuccess('Stock actualizado exitosamente');
          stockController.clear();
        },
      );
    } finally {
      _isUpdatingStock.value = false;
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct() async {
    if (!hasProduct) return;

    _isDeleting.value = true;

    try {
      final result = await _deleteProductUseCase(
        DeleteProductParams(id: productId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar producto', failure.message);
        },
        (_) {
          _showSuccess('Producto eliminado exitosamente');
          Get.back();
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  // ==================== UI ACTIONS ====================

  void goToEditProduct() {
    if (!hasProduct) return;
    Get.toNamed('/products/edit/$productId');
  }

  void showStockDialog() {
    if (!hasProduct) return;

    stockController.clear();

    Get.dialog(
      AlertDialog(
        title: const Text('Actualizar Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actual: ${currentStock.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final quantity = double.tryParse(stockController.text);
              if (quantity != null && quantity > 0) {
                Get.back();
                updateStock(quantity, 'subtract');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Restar'),
          ),
          TextButton(
            onPressed: () {
              final quantity = double.tryParse(stockController.text);
              if (quantity != null && quantity > 0) {
                Get.back();
                updateStock(quantity, 'add');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Sumar'),
          ),
        ],
      ),
    );
  }

  void confirmDelete() {
    if (!hasProduct) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro que deseas eliminar el producto "${productName}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteProduct();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void showStatusDialog() {
    if (!hasProduct) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Estado actual: ${isActive ? "Activo" : "Inactivo"}'),
            const SizedBox(height: 16),
            Text(
              '¿Deseas ${isActive ? "desactivar" : "activar"} este producto?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showInfo(
                'Funcionalidad pendiente',
                'Cambio de estado pendiente de implementar',
              );
            },
            child: Text(isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }

  void goToParentCategory() {
    if (product?.category != null) {
      Get.toNamed('/categories/detail/${product!.category!.id}');
    }
  }

  void shareProduct() {
    if (!hasProduct) return;
    Get.snackbar(
      'Compartir',
      'Funcionalidad de compartir pendiente de implementar',
      snackPosition: SnackPosition.TOP,
    );
  }

  void printLabel() {
    if (!hasProduct) return;
    _showInfo(
      'Imprimir',
      'Funcionalidad de impresión pendiente de implementar',
    );
  }

  void generateReport() {
    if (!hasProduct) return;
    _showInfo('Reporte', 'Generación de reportes pendiente de implementar');
  }

  // ==================== HELPER METHODS ====================

  Color getStockStatusColor() {
    if (!hasProduct) return Colors.grey;
    if (!isInStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  String getStockStatusText() {
    if (!hasProduct) return 'Sin datos';
    if (!isInStock) return 'Sin stock';
    if (isLowStock) return 'Stock bajo';
    return 'Stock normal';
  }

  double? getPriceByType(String priceType) {
    if (!hasProduct || product!.prices == null) return null;

    for (final price in product!.prices!) {
      if (price.type.name == priceType && price.isActive) {
        return price.finalAmount;
      }
    }
    return null;
  }

  String getFormattedPrice(String priceType) {
    final price = getPriceByType(priceType);
    if (price == null) return 'No disponible';
    return '\${price.toStringAsFixed(2)}';
  }

  bool hasDiscount(String priceType) {
    if (!hasProduct || product!.prices == null) return false;

    for (final price in product!.prices!) {
      if (price.type.name == priceType && price.isActive) {
        return price.hasDiscount;
      }
    }
    return false;
  }

  // ==================== PRIVATE METHODS ====================

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
