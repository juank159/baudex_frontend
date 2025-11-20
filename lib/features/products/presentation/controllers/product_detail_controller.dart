// lib/features/products/presentation/controllers/product_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports de entidades del dominio
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

// Imports de use cases (que contienen los parámetros correctos)
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/update_product_stock_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';

// Import del tema elegante
import '../../../../app/core/theme/elegant_light_theme.dart';

/// Controller para manejar la pantalla de detalles del producto
///
/// Responsabilidades:
/// - Cargar y mostrar detalles del producto
/// - Gestionar actualizaciones de stock
/// - Manejar eliminación del producto
/// - Controlar navegación entre pestañas (Detalles, Precios, Movimientos)
/// - Proporcionar helpers para la UI
class ProductDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ==================== DEPENDENCIES ====================

  final GetProductByIdUseCase _getProductByIdUseCase;
  final UpdateProductStockUseCase _updateProductStockUseCase;
  final DeleteProductUseCase _deleteProductUseCase;

  /// Constructor con inyección de dependencias
  ///
  /// Todas las dependencias son requeridas para el funcionamiento correcto
  ProductDetailController({
    required GetProductByIdUseCase getProductByIdUseCase,
    required UpdateProductStockUseCase updateProductStockUseCase,
    required DeleteProductUseCase deleteProductUseCase,
  }) : _getProductByIdUseCase = getProductByIdUseCase,
       _updateProductStockUseCase = updateProductStockUseCase,
       _deleteProductUseCase = deleteProductUseCase {
    print('🎮 ProductDetailController: Instancia creada correctamente');
  }
  // ==================== OBSERVABLES Y ESTADO ====================

  // Estados de carga - Privados para encapsulación
  final _isLoading = false.obs;
  final _isUpdatingStock = false.obs;
  final _isDeleting = false.obs;

  // Datos principales - Nullable porque puede no estar cargado
  final Rxn<Product> _product = Rxn<Product>();

  // Controllers de UI - Inicializados en onInit()
  late TabController tabController;
  final stockController = TextEditingController();

  // ==================== GETTERS PÚBLICOS ====================

  // Estados de carga - Solo lectura para la UI
  bool get isLoading => _isLoading.value;
  bool get isUpdatingStock => _isUpdatingStock.value;
  bool get isDeleting => _isDeleting.value;

  // Datos del producto - Acceso seguro
  Product? get product => _product.value;
  bool get hasProduct => _product.value != null;

  // Información básica del producto - Con fallbacks seguros
  String get productId => Get.parameters['id'] ?? '';
  String get productName => product?.name ?? '';
  String get productSku => product?.sku ?? '';

  // Estados computados del producto - Usando getters de la entidad
  bool get isActive => product?.isActive ?? false;
  bool get isInStock => product?.isInStock ?? false;
  bool get isLowStock => product?.isLowStock ?? false;

  // Información numérica - Con valores por defecto
  double get currentStock => product?.stock ?? 0.0;
  double get minStock => product?.minStock ?? 0.0;

  // Información adicional - Nullable apropiadamente
  String? get primaryImage => product?.primaryImage;
  // ==================== LIFECYCLE METHODS ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 ProductDetailController: Inicializando con ID: $productId');

    // Inicializar TabController para 3 pestañas: Detalles, Precios, Movimientos
    tabController = TabController(length: 3, vsync: this);

    // Validar que tenemos un ID válido antes de cargar
    if (productId.isNotEmpty) {
      // Cargar datos del producto de forma asíncrona
      loadProductDetails();
    } else {
      // Mostrar error si no hay ID válido
      _showError('Error', 'ID de producto no válido');
      print('❌ ProductDetailController: ID de producto vacío o inválido');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ AÑADIDO: Refrescar datos cuando el controller está listo
    // Esto asegura que los datos se actualicen al navegar de vuelta a la pantalla
    if (productId.isNotEmpty) {
      print('🔄 ProductDetailController: onReady - Refrescando datos del producto');
      refreshData();
    }
  }

  @override
  void onClose() {
    print('🔚 ProductDetailController: Liberando recursos...');

    // Liberar recursos de UI
    tabController.dispose();
    stockController.dispose();

    // Llamar al método padre
    super.onClose();

    print('✅ ProductDetailController: Recursos liberados correctamente');
  }
  // ==================== MÉTODOS DE CARGA DE DATOS ====================

  /// Cargar detalles del producto desde el servidor
  ///
  /// Este método maneja toda la lógica de carga:
  /// - Indicadores de estado de carga
  /// - Llamada al use case
  /// - Validación de datos recibidos
  /// - Manejo de errores robusto
  Future<void> loadProductDetails() async {
    print('📥 Cargando detalles del producto: $productId');

    // Activar indicador de carga
    _isLoading.value = true;

    try {
      // Llamada al use case usando los parámetros correctos
      final result = await _getProductByIdUseCase(
        GetProductByIdParams(id: productId),
      );

      // Manejar el resultado usando fold pattern
      result.fold(
        // Caso de error
        (failure) {
          print('❌ Error al cargar producto: ${failure.message}');
          _showError('Error al cargar producto', failure.message);

          // Limpiar producto actual en caso de error
          _product.value = null;
        },
        // Caso de éxito
        (product) {
          print('✅ Producto cargado exitosamente: ${product.name}');

          // Validar integridad de los datos antes de asignar
          if (_validateProductData(product)) {
            _product.value = product;
            print('✅ Producto asignado correctamente al estado');
          } else {
            print('⚠️ Datos del producto incompletos o inválidos');
            _showError(
              'Error de datos',
              'Los datos del producto están incompletos',
            );
            _product.value = null;
          }
        },
      );
    } catch (e, stackTrace) {
      // Manejo de errores inesperados
      print('💥 Error inesperado en loadProductDetails: $e');
      print('🔍 StackTrace: $stackTrace');

      _showError('Error inesperado', 'Ocurrió un error al cargar el producto');
      _product.value = null;
    } finally {
      // Siempre desactivar el indicador de carga
      _isLoading.value = false;
    }
  }

  /// Refrescar datos del producto
  ///
  /// Método simple que recarga los datos sin mostrar indicadores adicionales
  Future<void> refreshData() async {
    print('🔄 Refrescando datos del producto: $productId');
    await loadProductDetails();
  }

  /// Validar que los datos del producto están completos y son válidos
  ///
  /// Realiza validaciones esenciales para evitar errores en la UI:
  /// - Campos obligatorios presentes
  /// - Precios válidos si existen
  /// - Estructura de datos consistente
  bool _validateProductData(Product product) {
    try {
      // Validar campos básicos obligatorios
      if (product.id.isEmpty) {
        print('❌ Producto sin ID');
        return false;
      }

      if (product.name.isEmpty) {
        print('❌ Producto sin nombre');
        return false;
      }

      if (product.sku.isEmpty) {
        print('❌ Producto sin SKU');
        return false;
      }

      // Validar lista de precios si existe
      if (product.prices != null) {
        for (int i = 0; i < product.prices!.length; i++) {
          if (product.prices![i] == null) {
            print('❌ Precio null encontrado en posición $i');
            return false;
          }
        }
      }

      // Validar valores numéricos básicos
      if (product.stock < 0) {
        print('⚠️ Stock negativo detectado: ${product.stock}');
        // No es error crítico, pero se logea
      }

      print('✅ Datos del producto validados correctamente');
      return true;
    } catch (e) {
      print('❌ Error durante validación de datos del producto: $e');
      return false;
    }
  }
  // ==================== MÉTODOS DE ACTUALIZACIÓN ====================

  /// Actualizar stock del producto
  ///
  /// Parámetros:
  /// - [quantity]: Cantidad a sumar o restar
  /// - [operation]: 'add' para sumar, 'subtract' para restar
  Future<void> updateStock(double quantity, String operation) async {
    // Validar que hay producto cargado
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado para actualizar');
      return;
    }

    // Validar parámetros de entrada
    if (quantity <= 0) {
      _showError('Error', 'La cantidad debe ser mayor a 0');
      return;
    }

    if (operation != 'add' && operation != 'subtract') {
      _showError('Error', 'Operación inválida. Use "add" o "subtract"');
      return;
    }

    print(
      '📦 Actualizando stock: $operation $quantity para producto $productId',
    );

    // Activar indicador de carga
    _isUpdatingStock.value = true;

    try {
      // Llamada al use case con parámetros validados
      final result = await _updateProductStockUseCase(
        UpdateProductStockParams(
          id: productId,
          quantity: quantity,
          operation: operation,
        ),
      );

      // Manejar resultado
      result.fold(
        // Caso de error
        (failure) {
          print('❌ Error al actualizar stock: ${failure.message}');
          _showError('Error al actualizar stock', failure.message);
        },
        // Caso de éxito
        (updatedProduct) {
          print('✅ Stock actualizado exitosamente');
          print('📊 Nuevo stock: ${updatedProduct.stock}');

          // Actualizar el producto en el estado
          _product.value = updatedProduct;

          // Mostrar mensaje de éxito
          _showSuccess('Stock actualizado exitosamente');

          // Limpiar el campo de entrada
          stockController.clear();
        },
      );
    } catch (e) {
      print('💥 Error inesperado al actualizar stock: $e');
      _showError('Error inesperado', 'No se pudo actualizar el stock');
    } finally {
      // Siempre desactivar indicador de carga
      _isUpdatingStock.value = false;
    }
  }

  /// Eliminar producto
  ///
  /// Realiza eliminación lógica (soft delete) del producto
  Future<void> deleteProduct() async {
    // Validar que hay producto cargado
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado para eliminar');
      return;
    }

    print('🗑️ Eliminando producto: $productId ($productName)');

    // Activar indicador de carga
    _isDeleting.value = true;

    try {
      // Llamada al use case de eliminación
      final result = await _deleteProductUseCase(
        DeleteProductParams(id: productId),
      );

      // Manejar resultado
      result.fold(
        // Caso de error
        (failure) {
          print('❌ Error al eliminar producto: ${failure.message}');
          _showError('Error al eliminar producto', failure.message);
        },
        // Caso de éxito
        (_) {
          print('✅ Producto eliminado exitosamente');

          // Mostrar mensaje de éxito
          _showSuccess('Producto eliminado exitosamente');

          // Volver a la lista de productos después de un delay
          Future.delayed(const Duration(seconds: 1), () {
            Get.back();
          });
        },
      );
    } catch (e) {
      print('💥 Error inesperado al eliminar producto: $e');
      _showError('Error inesperado', 'No se pudo eliminar el producto');
    } finally {
      // Siempre desactivar indicador de carga
      _isDeleting.value = false;
    }
  }
  // ==================== MÉTODOS DE UI Y NAVEGACIÓN ====================

  /// Navegar a la pantalla de edición del producto
  void goToEditProduct() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    print('📝 Navegando a editar producto: $productId');
    Get.toNamed('/products/edit/$productId');
  }

  /// Mostrar diálogo para actualizar stock
  ///
  /// Presenta un diálogo con:
  /// - Stock actual
  /// - Campo para ingresar cantidad
  /// - Botones para sumar o restar
  void showStockDialog() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    // Limpiar campo de texto
    stockController.clear();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: ElegantLightTheme.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Actualizar Stock',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Producto: $productName',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock actual: ${currentStock.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    labelStyle: TextStyle(color: ElegantLightTheme.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ElegantLightTheme.primaryBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ElegantLightTheme.primaryBlue, width: 2),
                    ),
                    hintText: 'Ingrese la cantidad',
                    prefixIcon: Icon(Icons.numbers, color: ElegantLightTheme.primaryBlue),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ElegantLightTheme.textTertiary, width: 2),
                        color: Colors.white,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: ElegantLightTheme.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: ElegantLightTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElegantButton(
                      text: 'Restar',
                      icon: Icons.remove,
                      gradient: ElegantLightTheme.warningGradient,
                      onPressed: () => _handleStockUpdate('subtract'),
                    ),
                    const SizedBox(width: 12),
                    ElegantButton(
                      text: 'Sumar',
                      icon: Icons.add,
                      gradient: ElegantLightTheme.successGradient,
                      onPressed: () => _handleStockUpdate('add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Manejar actualización de stock desde el diálogo
  ///
  /// Valida la entrada y ejecuta la actualización
  void _handleStockUpdate(String operation) {
    final quantityText = stockController.text.trim();

    if (quantityText.isEmpty) {
      _showError('Error', 'Ingrese una cantidad');
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Error', 'Ingrese una cantidad válida mayor a 0');
      return;
    }

    // Cerrar diálogo y actualizar stock
    Get.back();
    updateStock(quantity, operation);
  }

  /// Mostrar diálogo de confirmación para eliminar producto
  void confirmDelete() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Eliminar Producto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Estás seguro que deseas eliminar el producto "$productName"?',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta acción no se puede deshacer.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SKU: $productSku',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ElegantLightTheme.textTertiary, width: 2),
                        color: Colors.white,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: ElegantLightTheme.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: ElegantLightTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElegantButton(
                      text: 'Eliminar',
                      icon: Icons.delete,
                      gradient: ElegantLightTheme.errorGradient,
                      onPressed: () {
                        Get.back();
                        deleteProduct();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar diálogo de cambio de estado (funcionalidad futura)
  void showStatusDialog() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: ElegantLightTheme.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cambiar Estado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Estado actual: ${isActive ? "Activo" : "Inactivo"}',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Deseas ${isActive ? "desactivar" : "activar"} este producto?',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ElegantLightTheme.textTertiary, width: 2),
                        color: Colors.white,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, color: ElegantLightTheme.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: ElegantLightTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElegantButton(
                      text: isActive ? 'Desactivar' : 'Activar',
                      icon: isActive ? Icons.toggle_off : Icons.toggle_on,
                      gradient: isActive ? ElegantLightTheme.warningGradient : ElegantLightTheme.successGradient,
                      onPressed: () {
                        Get.back();
                        _showInfo(
                          'Funcionalidad pendiente',
                          'Cambio de estado pendiente de implementar',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ==================== MÉTODOS HELPER PARA PRECIOS ====================

  /// Obtener precio por tipo de forma segura
  ///
  /// Parámetros:
  /// - [priceType]: Tipo de precio como string ('price1', 'price2', etc.)
  ///
  /// Retorna:
  /// - double?: El precio final si existe y está activo, null si no
  double? getPriceByType(String priceType) {
    try {
      // Validar precondiciones
      if (!hasProduct || product!.prices == null || product!.prices!.isEmpty) {
        return null;
      }

      // Buscar precio activo del tipo solicitado
      for (final price in product!.prices!) {
        final currentPriceType = _priceTypeToString(price.type);

        if (currentPriceType == priceType && price.isActive) {
          return _safeParseDouble(price.finalAmount);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener precio por tipo "$priceType": $e');
      return null;
    }
  }

  /// Obtener precio formateado como string
  ///
  /// Retorna el precio en formato moneda o mensaje apropiado
  String getFormattedPrice(String priceType) {
    try {
      final price = getPriceByType(priceType);

      if (price == null) {
        return 'No disponible';
      }

      return '\$${price.toStringAsFixed(2)}';
    } catch (e) {
      print('❌ Error al formatear precio "$priceType": $e');
      return 'Error';
    }
  }

  /// Verificar si un precio tiene descuento aplicado
  ///
  /// Retorna true si el precio tiene descuento por porcentaje o cantidad
  bool hasDiscount(String priceType) {
    try {
      if (!hasProduct || product!.prices == null) {
        return false;
      }

      for (final price in product!.prices!) {
        final currentPriceType = _priceTypeToString(price.type);

        if (currentPriceType == priceType && price.isActive) {
          final discountPercentage = _safeParseDouble(price.discountPercentage);
          final discountAmount = _safeParseDouble(price.discountAmount);

          return (discountPercentage > 0) || (discountAmount > 0);
        }
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar descuento "$priceType": $e');
      return false;
    }
  }

  /// Obtener precio original (sin descuentos aplicados)
  double? getOriginalPriceByType(String priceType) {
    try {
      if (!hasProduct || product!.prices == null) {
        return null;
      }

      for (final price in product!.prices!) {
        final currentPriceType = _priceTypeToString(price.type);

        if (currentPriceType == priceType && price.isActive) {
          return _safeParseDouble(price.amount);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener precio original "$priceType": $e');
      return null;
    }
  }

  /// Obtener porcentaje de descuento aplicado
  double getDiscountPercentageByType(String priceType) {
    try {
      if (!hasProduct || product!.prices == null) {
        return 0.0;
      }

      for (final price in product!.prices!) {
        final currentPriceType = _priceTypeToString(price.type);

        if (currentPriceType == priceType && price.isActive) {
          return _safeParseDouble(price.discountPercentage);
        }
      }

      return 0.0;
    } catch (e) {
      print('❌ Error al obtener porcentaje de descuento "$priceType": $e');
      return 0.0;
    }
  }

  /// Verificar si el producto tiene precios válidos
  ///
  /// Un precio es válido si:
  /// - La lista de precios no es null
  /// - Tiene al menos un precio
  /// - Al menos un precio está activo
  bool get hasValidPrices {
    try {
      return hasProduct &&
          product!.prices != null &&
          product!.prices!.isNotEmpty &&
          product!.prices!.any((price) => price.isActive);
    } catch (e) {
      print('❌ Error al verificar precios válidos: $e');
      return false;
    }
  }

  /// Obtener lista de precios activos
  ///
  /// Retorna solo los precios que están marcados como activos
  List<ProductPrice> get activeProductPrices {
    try {
      if (!hasProduct || product!.prices == null) {
        return [];
      }

      return product!.prices!.where((price) => price.isActive).toList();
    } catch (e) {
      print('❌ Error al obtener precios activos: $e');
      return [];
    }
  }

  /// Obtener cantidad mínima requerida para un tipo de precio
  double getMinQuantityByType(String priceType) {
    try {
      if (!hasProduct || product!.prices == null) {
        return 1.0;
      }

      for (final price in product!.prices!) {
        final currentPriceType = _priceTypeToString(price.type);

        if (currentPriceType == priceType && price.isActive) {
          return _safeParseDouble(price.minQuantity);
        }
      }

      return 1.0;
    } catch (e) {
      print('❌ Error al obtener cantidad mínima "$priceType": $e');
      return 1.0;
    }
  }
  // ==================== MÉTODOS HELPER DE ESTADO Y UI ====================

  /// Obtener color apropiado según el estado del stock
  ///
  /// Colores:
  /// - Rojo: Sin stock
  /// - Naranja: Stock bajo
  /// - Verde: Stock normal
  /// - Gris: Sin datos
  Color getStockStatusColor() {
    if (!hasProduct) return Colors.grey;

    if (!isInStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  /// Obtener texto descriptivo del estado del stock
  ///
  /// Textos posibles:
  /// - 'Sin stock': Producto sin inventario
  /// - 'Stock bajo': Stock por debajo del mínimo
  /// - 'Stock normal': Stock adecuado
  /// - 'Sin datos': No hay producto cargado
  String getStockStatusText() {
    if (!hasProduct) return 'Sin datos';

    if (!isInStock) return 'Sin stock';
    if (isLowStock) return 'Stock bajo';
    return 'Stock normal';
  }

  // ==================== MÉTODOS DE ACCIONES ADICIONALES ====================

  /// Navegar a la categoría padre del producto
  void goToParentCategory() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    if (product!.category != null) {
      print('📂 Navegando a categoría: ${product!.category!.name}');
      Get.toNamed('/categories/detail/${product!.category!.id}');
    } else {
      _showInfo('Sin categoría', 'Este producto no tiene categoría asignada');
    }
  }

  /// Compartir información del producto
  ///
  /// Genera texto con información básica del producto para compartir
  void shareProduct() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    // Generar texto para compartir
    final shareText = '''
🏷️ Producto: $productName
📋 SKU: $productSku
📦 Stock: ${currentStock.toStringAsFixed(2)} ${product!.unit ?? 'unidades'}
✅ Estado: ${isActive ? "Activo" : "Inactivo"}
📊 Estado Stock: ${getStockStatusText()}
''';

    print('📤 Compartiendo producto: $shareText');

    // TODO: Implementar funcionalidad de compartir real con share_plus
    _showInfo(
      'Compartir',
      'Funcionalidad de compartir pendiente de implementar\n\nContenido:\n$shareText',
    );
  }

  /// Imprimir etiqueta del producto
  ///
  /// Funcionalidad futura para imprimir etiquetas con código de barras
  void printLabel() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    print('🖨️ Imprimiendo etiqueta para: $productName (SKU: $productSku)');

    // TODO: Implementar funcionalidad de impresión real
    _showInfo(
      'Imprimir Etiqueta',
      'Funcionalidad de impresión pendiente de implementar.\n\nSe imprimirá etiqueta para:\n• $productName\n• SKU: $productSku',
    );
  }

  /// Generar reporte del producto
  ///
  /// Funcionalidad futura para generar reportes detallados
  void generateReport() {
    if (!hasProduct) {
      _showError('Error', 'No hay producto cargado');
      return;
    }

    print('📊 Generando reporte para: $productName');

    // TODO: Implementar generación de reportes real
    _showInfo(
      'Generar Reporte',
      'Funcionalidad de reportes pendiente de implementar.\n\nReporte incluirá:\n• Información general\n• Historial de stock\n• Estadísticas de ventas',
    );
  }

  // ==================== MÉTODOS HELPER PRIVADOS ====================

  /// Convertir enum PriceType a String
  ///
  /// Mapeo seguro de enum a string para comparaciones
  String _priceTypeToString(PriceType priceType) {
    switch (priceType) {
      case PriceType.price1:
        return 'price1';
      case PriceType.price2:
        return 'price2';
      case PriceType.price3:
        return 'price3';
      case PriceType.special:
        return 'special';
      case PriceType.cost:
        return 'cost';
    }
  }

  /// Convertir String a enum PriceType
  ///
  /// Mapeo con valor por defecto para casos no reconocidos
  PriceType _stringToPriceType(String priceTypeString) {
    switch (priceTypeString.toLowerCase()) {
      case 'price1':
        return PriceType.price1;
      case 'price2':
        return PriceType.price2;
      case 'price3':
        return PriceType.price3;
      case 'special':
        return PriceType.special;
      case 'cost':
        return PriceType.cost;
      default:
        print(
          '⚠️ Tipo de precio no reconocido: $priceTypeString, usando price1',
        );
        return PriceType.price1;
    }
  }

  /// Parsear valor dinámico a double de forma segura
  ///
  /// Maneja conversiones desde diferentes tipos:
  /// - double: retorna directamente
  /// - int: convierte a double
  /// - String: intenta parsear
  /// - null/otros: retorna 0.0
  double _safeParseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }

      print(
        '⚠️ Tipo no reconocido para conversión a double: ${value.runtimeType}',
      );
      return 0.0;
    } catch (e) {
      print('❌ Error al parsear double desde "$value": $e');
      return 0.0;
    }
  }
  // ==================== MÉTODOS DE MENSAJES Y NOTIFICACIONES ====================

  /// Mostrar mensaje de error con estilo consistente
  ///
  /// Parámetros:
  /// - [title]: Título del mensaje de error
  /// - [message]: Descripción detallada del error
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      shouldIconPulse: true,
    );
  }

  /// Mostrar mensaje de éxito con estilo consistente
  ///
  /// Parámetros:
  /// - [message]: Mensaje de éxito a mostrar
  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      shouldIconPulse: true,
    );
  }

  /// Mostrar mensaje de información con estilo consistente
  ///
  /// Parámetros:
  /// - [title]: Título del mensaje informativo
  /// - [message]: Contenido del mensaje
  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      shouldIconPulse: false,
    );
  }

  // ==================== MÉTODOS DE DEBUG Y UTILIDADES ====================

  /// Imprimir información completa del producto para debugging
  ///
  /// Útil durante desarrollo para verificar el estado del controller
  void debugProductInfo() {
    if (!hasProduct) {
      print('🐛 DEBUG: No hay producto cargado');
      return;
    }

    print('🐛 ===== DEBUG: Información del producto =====');
    print('   📋 ID: $productId');
    print('   🏷️ Nombre: $productName');
    print('   📄 SKU: $productSku');
    print('   📦 Stock actual: $currentStock');
    print('   ⚠️ Stock mínimo: $minStock');
    print('   ✅ Estado activo: $isActive');
    print('   📊 En stock: $isInStock');
    print('   🔶 Stock bajo: $isLowStock');
    print('   💰 Precios válidos: $hasValidPrices');
    print('   🔢 Cantidad de precios: ${activeProductPrices.length}');
    print('   🖼️ Imagen principal: ${primaryImage ?? "Sin imagen"}');
    print('   📂 Categoría: ${product!.category?.name ?? "Sin categoría"}');
    print('   👤 Creado por: ${product!.createdBy?.fullName ?? "Desconocido"}');
    print('🐛 ===============================================');
  }

  /// Obtener resumen del estado actual del controller
  ///
  /// Retorna un mapa con información útil para debugging
  Map<String, dynamic> getControllerState() {
    return {
      'hasProduct': hasProduct,
      'isLoading': isLoading,
      'isUpdatingStock': isUpdatingStock,
      'isDeleting': isDeleting,
      'productId': productId,
      'productName': productName,
      'hasValidPrices': hasValidPrices,
      'activeProductPrices': activeProductPrices.length,
      'stockStatus': getStockStatusText(),
    };
  }

  /// Validar estado del controller
  ///
  /// Verifica que el controller esté en un estado consistente
  bool validateControllerState() {
    try {
      // Verificar que el productId es válido
      if (productId.isEmpty) {
        print('❌ Estado inválido: productId vacío');
        return false;
      }

      // Si hay producto, verificar que sea válido
      if (hasProduct) {
        if (!_validateProductData(product!)) {
          print('❌ Estado inválido: datos de producto inconsistentes');
          return false;
        }
      }

      // Verificar que no hay estados de carga conflictivos
      if (isLoading && isUpdatingStock) {
        print('⚠️ Estados de carga múltiples activos simultáneamente');
      }

      print('✅ Estado del controller validado correctamente');
      return true;
    } catch (e) {
      print('❌ Error al validar estado del controller: $e');
      return false;
    }
  }

  // ==================== MÉTODOS DE LIMPIEZA ADICIONALES ====================

  /// Limpiar estado del producto (útil para testing o reset)
  void clearProductState() {
    print('🧹 Limpiando estado del producto...');

    _product.value = null;
    _isLoading.value = false;
    _isUpdatingStock.value = false;
    _isDeleting.value = false;

    stockController.clear();

    print('✅ Estado del producto limpiado');
  }

  /// Verificar si hay operaciones en progreso
  bool get hasOperationsInProgress {
    return isLoading || isUpdatingStock || isDeleting;
  }

  /// Obtener mensaje de estado actual
  String get currentStatusMessage {
    if (isLoading) return 'Cargando producto...';
    if (isUpdatingStock) return 'Actualizando stock...';
    if (isDeleting) return 'Eliminando producto...';
    if (!hasProduct) return 'Sin producto cargado';
    return 'Producto cargado correctamente';
  }
}
