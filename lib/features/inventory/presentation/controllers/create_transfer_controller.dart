// lib/features/inventory/presentation/controllers/create_transfer_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/create_inventory_transfer_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/usecases/get_inventory_balance_by_product_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';
import 'inventory_transfers_controller.dart';

// UI Transfer Item with additional data for display
class UITransferItem {
  final String productId;
  final Product product;
  final int quantity;
  final double availableStock;
  final String? notes;

  const UITransferItem({
    required this.productId,
    required this.product,
    required this.quantity,
    required this.availableStock,
    this.notes,
  });

  TransferItem toTransferItem() {
    return TransferItem(
      productId: productId,
      quantity: quantity,
      notes: notes,
    );
  }
}

class CreateTransferController extends GetxController {
  final CreateInventoryTransferUseCase createTransferUseCase;
  final GetWarehousesUseCase getWarehousesUseCase;
  final SearchProductsUseCase searchProductsUseCase;
  final GetInventoryBalanceByProductUseCase getInventoryBalanceByProductUseCase;

  CreateTransferController({
    required this.createTransferUseCase,
    required this.getWarehousesUseCase,
    required this.searchProductsUseCase,
    required this.getInventoryBalanceByProductUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isLoadingWarehouses = false.obs;
  final RxBool isValidatingStock = false.obs;
  
  // Form state
  final RxBool isFormValid = false.obs;
  final RxString error = ''.obs;
  
  // Form controllers
  final productController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  
  // Selected values
  final RxString selectedFromWarehouseId = ''.obs;
  final RxString selectedToWarehouseId = ''.obs;
  
  // Data
  final RxList<Warehouse> warehouses = <Warehouse>[].obs;
  final RxList<Product> searchResults = <Product>[].obs;
  
  // Transfer items list (multiple products)
  final RxList<UITransferItem> transferItems = <UITransferItem>[].obs;
  
  // Legacy properties for backward compatibility with existing widgets
  final RxString selectedProductId = ''.obs;
  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final RxDouble availableStock = 0.0.obs;
  final RxDouble requestedQuantity = 0.0.obs;
  
  // Mapas para almacenar información de stock por producto
  final RxMap<String, double> productStockMap = <String, double>{}.obs;
  
  // Validation messages
  final RxString productError = ''.obs;
  final RxString quantityError = ''.obs;
  final RxString warehouseError = ''.obs;
  final RxString transferError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeForm();
    _loadWarehouses();
    _setupValidation();
  }

  @override
  void onClose() {
    productController.dispose();
    quantityController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeForm() {
    // Set default notes
    notesController.text = 'Transferencia entre almacenes';
    
    // Listen to quantity changes
    quantityController.addListener(_onQuantityChanged);
  }

  void _setupValidation() {
    // Real-time validation
    ever(selectedFromWarehouseId, (_) => _validateForm());
    ever(selectedToWarehouseId, (_) => _validateForm());
    ever(transferItems, (_) => _validateForm());
  }

  void _onQuantityChanged() {
    final text = quantityController.text;
    if (text.isNotEmpty) {
      final quantity = double.tryParse(text) ?? 0.0;
      requestedQuantity.value = quantity;
    } else {
      requestedQuantity.value = 0.0;
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadWarehouses() async {
    try {
      isLoadingWarehouses.value = true;
      error.value = '';
      
      final result = await getWarehousesUseCase();
      
      result.fold(
        (failure) => error.value = 'Error al cargar almacenes: ${failure.message}',
        (warehousesList) => warehouses.value = warehousesList,
      );
    } catch (e) {
      error.value = 'Error inesperado al cargar almacenes: $e';
    } finally {
      isLoadingWarehouses.value = false;
    }
  }

  Future<void> searchProducts(String query) async {
    // No buscar si no están ambos almacenes seleccionados
    if (selectedFromWarehouseId.value.isEmpty || selectedToWarehouseId.value.isEmpty) {
      searchResults.clear();
      return;
    }

    if (query.trim().isEmpty) {
      searchResults.clear();
      productError.value = '';
      return;
    }

    try {
      isLoading.value = true;
      productError.value = '';

      // Buscar productos que tengan stock en el almacén de origen
      final result = await searchProductsUseCase(SearchProductsParams(
        searchTerm: query,
        limit: 20,
      ));
      
      result.fold(
        (failure) => productError.value = 'Error al buscar productos: ${failure.message}',
        (products) async {
          // Filtrar productos que tienen stock en el almacén de origen
          final productsWithStock = <Product>[];
          
          for (final product in products) {
            try {
              final stockResult = await getInventoryBalanceByProductUseCase(
                product.id,
                warehouseId: selectedFromWarehouseId.value,
              );
              
              stockResult.fold(
                (failure) => print('❌ Error getting stock for ${product.name}: ${failure.message}'),
                (balance) {
                  final availableQty = balance.availableQuantity.toDouble();
                  if (availableQty > 0) {
                    productsWithStock.add(product);
                    // Almacenar la cantidad disponible para este producto
                    productStockMap[product.id] = availableQty;
                  }
                },
              );
            } catch (e) {
              print('❌ Error checking stock for ${product.name}: $e');
            }
          }
          
          searchResults.value = productsWithStock;
          
          // Simplemente mostrar los resultados sin mensajes de error
          // if (productsWithStock.isEmpty && products.isNotEmpty) {
          //   productError.value = 'No se encontraron productos con stock disponible en ${getWarehouseName(selectedFromWarehouseId.value)}';
          // }
        },
      );
    } catch (e) {
      productError.value = 'Error inesperado en búsqueda: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== FORM ACTIONS ====================

  void addProductToTransfer(Product product, int quantity) {
    // Verificar si el producto ya está en la lista
    final existingIndex = transferItems.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      // Actualizar cantidad si ya existe
      final existingItem = transferItems[existingIndex];
      final newItem = UITransferItem(
        productId: existingItem.productId,
        product: existingItem.product,
        quantity: existingItem.quantity + quantity,
        availableStock: existingItem.availableStock,
        notes: existingItem.notes,
      );
      transferItems[existingIndex] = newItem;
    } else {
      // Agregar nuevo producto
      final availableStock = productStockMap[product.id] ?? 0.0;
      final newItem = UITransferItem(
        productId: product.id,
        product: product,
        quantity: quantity,
        availableStock: availableStock,
      );
      transferItems.add(newItem);
    }
    
    // Limpiar formulario de búsqueda
    productController.clear();
    quantityController.clear();
    searchResults.clear();
    productError.value = '';
    quantityError.value = '';
    
    print('✅ Producto agregado a transferencia: ${product.name} x$quantity');
  }

  void removeProductFromTransfer(String productId) {
    transferItems.removeWhere((item) => item.productId == productId);
    print('🗑️ Producto removido de transferencia: $productId');
  }

  void updateProductQuantity(String productId, int newQuantity) {
    final index = transferItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      final existingItem = transferItems[index];
      if (newQuantity <= 0) {
        transferItems.removeAt(index);
      } else {
        final updatedItem = UITransferItem(
          productId: existingItem.productId,
          product: existingItem.product,
          quantity: newQuantity,
          availableStock: existingItem.availableStock,
          notes: existingItem.notes,
        );
        transferItems[index] = updatedItem;
      }
    }
  }

  void selectProduct(Product product) {
    selectedProduct.value = product;
    selectedProductId.value = product.id;
    productController.text = '${product.name} (${product.sku})';
    searchResults.clear();
    
    // Check stock for selected product in from warehouse
    if (selectedFromWarehouseId.value.isNotEmpty) {
      _checkAvailableStock();
    }
    
    // Clear previous errors
    productError.value = '';
  }

  void selectFromWarehouse(String warehouseId) {
    if (warehouseId == selectedToWarehouseId.value) {
      warehouseError.value = 'El almacén de origen no puede ser igual al de destino';
      return;
    }
    
    // Si hay productos en la lista, mostrar diálogo de confirmación
    if (transferItems.isNotEmpty) {
      _showWarehouseChangeConfirmation(
        'Cambiar Almacén de Origen',
        'Al cambiar el almacén de origen, se vaciará la lista de productos seleccionados. ¿Deseas continuar?',
        () => _confirmFromWarehouseChange(warehouseId),
      );
      return;
    }
    
    _confirmFromWarehouseChange(warehouseId);
  }
  
  void _confirmFromWarehouseChange(String warehouseId) {
    selectedFromWarehouseId.value = warehouseId;
    warehouseError.value = '';
    
    // Limpiar todo cuando cambie el almacén de origen
    transferItems.clear();
    clearProduct();
    searchResults.clear();
    productStockMap.clear();
    productError.value = '';
    transferError.value = '';
    
    print('✅ Almacén de origen seleccionado: ${getWarehouseName(warehouseId)}');
  }

  void selectToWarehouse(String warehouseId) {
    if (warehouseId == selectedFromWarehouseId.value) {
      warehouseError.value = 'El almacén de destino no puede ser igual al de origen';
      return;
    }
    
    // Si hay productos en la lista, mostrar diálogo de confirmación
    if (transferItems.isNotEmpty) {
      _showWarehouseChangeConfirmation(
        'Cambiar Almacén de Destino',
        'Al cambiar el almacén de destino, se vaciará la lista de productos seleccionados. ¿Deseas continuar?',
        () => _confirmToWarehouseChange(warehouseId),
      );
      return;
    }
    
    _confirmToWarehouseChange(warehouseId);
  }
  
  void _confirmToWarehouseChange(String warehouseId) {
    selectedToWarehouseId.value = warehouseId;
    warehouseError.value = '';
    
    // Limpiar lista de productos cuando cambie el almacén de destino
    transferItems.clear();
    transferError.value = '';
    
    print('✅ Almacén de destino seleccionado: ${getWarehouseName(warehouseId)}');
  }

  void _showWarehouseChangeConfirmation(String title, String message, VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void clearProduct() {
    selectedProduct.value = null;
    selectedProductId.value = '';
    productController.clear();
    searchResults.clear();
    availableStock.value = 0.0;
    requestedQuantity.value = 0.0;
    quantityController.clear();
    productError.value = '';
    quantityError.value = '';
    
    print('🧹 Producto limpiado - listo para nueva búsqueda');
  }

  // ==================== STOCK VALIDATION ====================

  Future<void> _checkAvailableStock() async {
    if (selectedProductId.value.isEmpty || selectedFromWarehouseId.value.isEmpty) {
      return;
    }

    try {
      isValidatingStock.value = true;
      
      final result = await getInventoryBalanceByProductUseCase(
        selectedProductId.value,
        warehouseId: selectedFromWarehouseId.value,
      );
      
      result.fold(
        (failure) {
          availableStock.value = 0.0;
          print('❌ Error getting stock: ${failure.message}');
        },
        (balance) {
          availableStock.value = balance.availableQuantity.toDouble();
          print('✅ Available stock: ${balance.availableQuantity}');
        },
      );
    } catch (e) {
      availableStock.value = 0.0;
      print('❌ Error checking stock: $e');
    } finally {
      isValidatingStock.value = false;
    }
  }

  // ==================== VALIDATION ====================

  void _validateForm() {
    _validateWarehouses();
    _validateTransferItems();
    
    isFormValid.value = warehouseError.value.isEmpty &&
                       transferError.value.isEmpty &&
                       selectedFromWarehouseId.value.isNotEmpty &&
                       selectedToWarehouseId.value.isNotEmpty &&
                       transferItems.isNotEmpty;
  }

  void _validateTransferItems() {
    if (transferItems.isEmpty) {
      transferError.value = 'Debe agregar al menos un producto a la transferencia';
      return;
    }
    
    // Validar que todos los items tengan stock suficiente
    for (final item in transferItems) {
      if (item.quantity > item.availableStock) {
        transferError.value = 'Stock insuficiente para ${item.product.name}. Disponible: ${item.availableStock}';
        return;
      }
    }
    
    transferError.value = '';
  }

  void _validateWarehouses() {
    if (selectedFromWarehouseId.value.isEmpty) {
      warehouseError.value = 'Debe seleccionar almacén de origen';
      return;
    }
    
    if (selectedToWarehouseId.value.isEmpty) {
      warehouseError.value = 'Debe seleccionar almacén de destino';
      return;
    }
    
    if (selectedFromWarehouseId.value == selectedToWarehouseId.value) {
      warehouseError.value = 'Los almacenes de origen y destino deben ser diferentes';
      return;
    }
    
    warehouseError.value = '';
  }

  void validateQuantity() {
    if (requestedQuantity.value <= 0) {
      quantityError.value = 'La cantidad debe ser mayor a 0';
      return;
    }
    
    if (requestedQuantity.value > availableStock.value) {
      quantityError.value = 'Stock insuficiente. Disponible: ${AppFormatters.formatNumber(availableStock.value)}';
      return;
    }
    
    quantityError.value = '';
  }

  // ==================== CREATE TRANSFER ====================

  Future<void> createTransfer() async {
    if (!isFormValid.value) {
      _validateForm();
      return;
    }

    try {
      isCreating.value = true;
      error.value = '';

      final params = CreateInventoryTransferParams(
        items: transferItems.map((item) => item.toTransferItem()).toList(),
        fromWarehouseId: selectedFromWarehouseId.value,
        toWarehouseId: selectedToWarehouseId.value,
        notes: notesController.text.trim().isNotEmpty 
            ? notesController.text.trim() 
            : null,
      );

      final result = await createTransferUseCase(params);
      
      result.fold(
        (failure) => error.value = 'Error al crear transferencia: ${failure.message}',
        (transfer) {
          FuturisticNotifications.showSuccess(
            '✅ Transferencia Creada',
            'Transferencia creada exitosamente',
          );
          
          // Navigate to transfers list and refresh data
          Get.offNamed('/inventory/transfers');
          
          // Ensure the transfers controller refreshes its data
          try {
            final transfersController = Get.find<InventoryTransfersController>();
            transfersController.refreshData();
          } catch (e) {
            print('⚠️ TransfersController not found, data will be refreshed on screen entry');
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isCreating.value = false;
    }
  }

  // ==================== UI HELPERS ====================

  String get formTitle => 'Nueva Transferencia';
  
  double getProductStock(String productId) {
    return productStockMap[productId] ?? 0.0;
  }
  
  bool get canSubmit => isFormValid.value && !isCreating.value;
  
  String get submitButtonText => isCreating.value ? 'Creando...' : 'Crear Transferencia';
  
  Warehouse? getWarehouseById(String id) {
    try {
      return warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  String getWarehouseName(String id) {
    final warehouse = getWarehouseById(id);
    return warehouse?.name ?? 'Almacén desconocido';
  }

  void resetForm() {
    transferItems.clear();
    selectedFromWarehouseId.value = '';
    selectedToWarehouseId.value = '';
    productController.clear();
    quantityController.clear();
    searchResults.clear();
    productStockMap.clear();
    notesController.text = 'Transferencia entre almacenes';
    error.value = '';
    productError.value = '';
    quantityError.value = '';
    warehouseError.value = '';
    transferError.value = '';
  }
}