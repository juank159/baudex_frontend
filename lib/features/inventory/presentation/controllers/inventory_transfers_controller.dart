// lib/features/inventory/presentation/controllers/inventory_transfers_controller.dart
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/create_inventory_transfer_usecase.dart';
import '../../domain/usecases/confirm_inventory_transfer_usecase.dart';
import '../../domain/usecases/get_inventory_movements_usecase.dart';
import '../../domain/usecases/cancel_inventory_movement_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_export_service.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

class InventoryTransfersController extends GetxController {
  final CreateInventoryTransferUseCase createTransferUseCase;
  final ConfirmInventoryTransferUseCase confirmTransferUseCase;
  final GetInventoryMovementsUseCase getMovementsUseCase;
  final CancelInventoryMovementUseCase cancelInventoryMovementUseCase;
  final GetWarehousesUseCase getWarehousesUseCase;
  final SearchProductsUseCase searchProductsUseCase;
  final GetInventoryBalanceByProductUseCase getInventoryBalanceByProductUseCase;

  InventoryTransfersController({
    required this.createTransferUseCase,
    required this.confirmTransferUseCase,
    required this.getMovementsUseCase,
    required this.cancelInventoryMovementUseCase,
    required this.getWarehousesUseCase,
    required this.searchProductsUseCase,
    required this.getInventoryBalanceByProductUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxList<InventoryMovement> transfers = <InventoryMovement>[].obs;
  final RxList<Warehouse> warehouses = <Warehouse>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isLoadingWarehouses = false.obs;
  final RxString error = ''.obs;

  // Transfer form
  final fromWarehouseController = TextEditingController();
  final toWarehouseController = TextEditingController();
  final productController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  final RxString selectedFromWarehouseId = ''.obs;
  final RxString selectedToWarehouseId = ''.obs;
  final RxString selectedProductId = ''.obs;
  final RxBool showForm = false.obs;

  // Multiple products support
  final RxList<TransferItem> transferItems = <TransferItem>[].obs;

  // Filters
  final RxString filterWarehouseId = ''.obs;
  final RxString filterStatus = ''.obs;
  final Rx<DateTime?> filterDateFrom = Rx<DateTime?>(null);
  final Rx<DateTime?> filterDateTo = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadTransfers();
    loadWarehouses();
  }
  
  @override
  void onReady() {
    super.onReady();
    // Refresh data when coming back to this controller
    refreshData();
  }
  
  // Public method to refresh data - useful when navigating from creation
  Future<void> refreshData() async {
    await loadTransfers();
    await loadWarehouses();
  }

  @override
  void onClose() {
    fromWarehouseController.dispose();
    toWarehouseController.dispose();
    productController.dispose();
    quantityController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ==================== DATA LOADING ====================

  Future<void> loadTransfers() async {
    isLoading.value = true;
    error.value = '';

    try {
      // Para transferencias necesitamos buscar tanto transfer_in como transfer_out
      final transferInParams = InventoryMovementQueryParams(
        page: 1,
        limit: 50, // Revertido a valor original
        type: InventoryMovementType.transferIn,
        warehouseId:
            filterWarehouseId.value.isNotEmpty ? filterWarehouseId.value : null,
        status: _getFilterStatus(),
        startDate: filterDateFrom.value,
        endDate: filterDateTo.value,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final transferOutParams = InventoryMovementQueryParams(
        page: 1,
        limit: 50, // Revertido a valor original
        type: InventoryMovementType.transferOut,
        warehouseId:
            filterWarehouseId.value.isNotEmpty ? filterWarehouseId.value : null,
        status: _getFilterStatus(),
        startDate: filterDateFrom.value,
        endDate: filterDateTo.value,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      final transferInResult = await getMovementsUseCase(transferInParams);
      final transferOutResult = await getMovementsUseCase(transferOutParams);

      List<InventoryMovement> allTransfers = [];

      transferInResult.fold(
        (failure) => print('Transfer_in query failed: ${failure.message}'),
        (paginatedResult) => allTransfers.addAll(paginatedResult.data),
      );

      transferOutResult.fold(
        (failure) => print('Transfer_out query failed: ${failure.message}'),
        (paginatedResult) => allTransfers.addAll(paginatedResult.data),
      );

      // Ordenar por fecha de creación descendente
      allTransfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      transfers.value = allTransfers;

      // DEBUG: Información detallada de conteo
      final transferOutCount = allTransfers.where((t) => t.type == InventoryMovementType.transferOut).length;
      final transferInCount = allTransfers.where((t) => t.type == InventoryMovementType.transferIn).length;
      final grouped = _groupRelatedTransfers(allTransfers);
      
      print('✅ TRANSFERENCIAS CARGADAS:');
      print('   • Total raw: ${allTransfers.length}');
      print('   • TransferOut: $transferOutCount');
      print('   • TransferIn: $transferInCount');
      print('   • Grupos únicos: ${grouped.length}');
      print('   • Total agrupado: ${totalTransfers}');
      print('   • Hoy agrupado: ${todayTransfers}');
    } catch (e) {
      print('❌ Error cargando transferencias: $e');
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error al cargar transferencias',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== WAREHOUSE LOADING ====================

  Future<void> loadWarehouses() async {
    try {
      isLoadingWarehouses.value = true;

      final result = await getWarehousesUseCase();

      result.fold(
        (failure) {
          print('❌ Error cargando almacenes: ${failure.message}');
        },
        (warehousesList) {
          warehouses.value = warehousesList;
          print('✅ Almacenes cargados: ${warehousesList.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando almacenes: $e');
    } finally {
      isLoadingWarehouses.value = false;
    }
  }

  // ==================== TRANSFER CREATION ====================

  Future<void> createTransfer() async {
    if (!_validateTransfer()) return;

    try {
      isCreating.value = true;

      print('🔍 DEBUG: Creando transferencia con ${transferItems.length} productos:');
      for (int i = 0; i < transferItems.length; i++) {
        final item = transferItems[i];
        print('   ${i + 1}. Producto ID: ${item.productId}, Cantidad: ${item.quantity}');
      }
      
      final request = CreateInventoryTransferParams(
        items: transferItems.toList(),
        fromWarehouseId: selectedFromWarehouseId.value,
        toWarehouseId: selectedToWarehouseId.value,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      final result = await createTransferUseCase(request);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error al crear transferencia',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (transfer) {
          final productCount = transferItems.length;
          Get.snackbar(
            'Transferencia creada',
            productCount == 1 
              ? 'La transferencia fue creada exitosamente'
              : 'Se crearon $productCount transferencias exitosamente (una por producto)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
          _clearForm();
          loadTransfers();
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error al crear transferencia',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> confirmTransfer(String transferId) async {
    try {
      final result = await confirmTransferUseCase(transferId);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error al confirmar transferencia',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (transfer) {
          Get.snackbar(
            'Transferencia confirmada',
            'La transferencia fue confirmada exitosamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
          loadTransfers();
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error al confirmar transferencia',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // ==================== MULTIPLE PRODUCTS MANAGEMENT ====================

  void addProductToTransfer() {
    if (!_validateProductForm()) return;

    // Check if product already exists in transfer
    final existingIndex = transferItems.indexWhere(
      (item) => item.productId == selectedProductId.value,
    );

    if (existingIndex != -1) {
      // Update existing product quantity
      final existingItem = transferItems[existingIndex];
      final newQuantity =
          existingItem.quantity + int.parse(quantityController.text);

      transferItems[existingIndex] = TransferItem(
        productId: existingItem.productId,
        quantity: newQuantity,
        notes: existingItem.notes,
      );

      Get.snackbar(
        'Producto actualizado',
        'Cantidad actualizada para este producto',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
      );
    } else {
      // Add new product
      transferItems.add(
        TransferItem(
          productId: selectedProductId.value,
          quantity: int.parse(quantityController.text),
          notes: null,
        ),
      );

      Get.snackbar(
        'Producto agregado',
        'Producto agregado a la transferencia',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    }

    // Clear product form fields
    _clearProductForm();
  }

  void removeProductFromTransfer(int index) {
    if (index >= 0 && index < transferItems.length) {
      transferItems.removeAt(index);
      Get.snackbar(
        'Producto eliminado',
        'Producto eliminado de la transferencia',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  void updateProductQuantity(int index, int newQuantity) {
    if (index >= 0 && index < transferItems.length && newQuantity > 0) {
      final item = transferItems[index];
      transferItems[index] = TransferItem(
        productId: item.productId,
        quantity: newQuantity,
        notes: item.notes,
      );
    }
  }

  // ==================== FORM MANAGEMENT ====================

  bool _validateTransfer() {
    if (selectedFromWarehouseId.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona el almacén de origen');
      return false;
    }

    if (selectedToWarehouseId.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona el almacén de destino');
      return false;
    }

    if (selectedFromWarehouseId.value == selectedToWarehouseId.value) {
      Get.snackbar(
        'Error',
        'Los almacenes de origen y destino deben ser diferentes',
      );
      return false;
    }

    if (transferItems.isEmpty) {
      Get.snackbar('Error', 'Agrega al menos un producto a la transferencia');
      return false;
    }

    return true;
  }

  bool _validateProductForm() {
    if (selectedFromWarehouseId.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona el almacén de origen');
      return false;
    }

    if (selectedToWarehouseId.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona el almacén de destino');
      return false;
    }

    if (selectedFromWarehouseId.value == selectedToWarehouseId.value) {
      Get.snackbar(
        'Error',
        'Los almacenes de origen y destino deben ser diferentes',
      );
      return false;
    }

    if (selectedProductId.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona un producto');
      return false;
    }

    if (quantityController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Ingresa la cantidad a transferir');
      return false;
    }

    final quantity = int.tryParse(quantityController.text);
    if (quantity == null || quantity <= 0) {
      Get.snackbar('Error', 'La cantidad debe ser un número mayor a 0');
      return false;
    }

    return true;
  }

  void _clearProductForm() {
    productController.clear();
    quantityController.clear();
    selectedProductId.value = '';
  }

  void _clearForm() {
    fromWarehouseController.clear();
    toWarehouseController.clear();
    productController.clear();
    quantityController.clear();
    notesController.clear();
    selectedFromWarehouseId.value = '';
    selectedToWarehouseId.value = '';
    selectedProductId.value = '';
    transferItems.clear();
    showForm.value = false;
  }

  // ==================== UI HELPERS ====================

  void toggleForm() {
    showForm.value = !showForm.value;
    if (!showForm.value) {
      _clearForm();
    }
  }

  Future<void> refreshTransfers() async {
    await loadTransfers();
  }

  Future<void> cancelTransfer(String transferId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await cancelInventoryMovementUseCase(transferId);

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
        (success) {
          Get.snackbar(
            'Éxito',
            'Transferencia cancelada correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
          // Reload transfers to reflect the cancellation
          loadTransfers();
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

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatDateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  Color getStatusColor(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return Colors.orange;
      case InventoryMovementStatus.confirmed:
        return Colors.green;
      case InventoryMovementStatus.cancelled:
        return Colors.red;
    }
  }

  IconData getStatusIcon(InventoryMovementStatus status) {
    switch (status) {
      case InventoryMovementStatus.pending:
        return Icons.schedule;
      case InventoryMovementStatus.confirmed:
        return Icons.check_circle;
      case InventoryMovementStatus.cancelled:
        return Icons.cancel;
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasTransfers => transfers.isNotEmpty;
  bool get hasError => error.value.isNotEmpty;
  
  // CONTADORES CORREGIDOS: usar datos agrupados para consistencia con las cards
  int get totalTransfers {
    if (transfers.isEmpty) return 0;
    try {
      final grouped = _groupRelatedTransfers(transfers);
      return grouped.length;
    } catch (e) {
      print('❌ Error en totalTransfers: $e');
      return transfers.length; // Fallback al conteo original
    }
  }

  List<InventoryMovement> get pendingTransfers =>
      transfers
          .where((t) => t.status == InventoryMovementStatus.pending)
          .toList();

  List<InventoryMovement> get confirmedTransfers =>
      transfers
          .where((t) => t.status == InventoryMovementStatus.confirmed)
          .toList();

  List<InventoryMovement> get cancelledTransfers =>
      transfers
          .where((t) => t.status == InventoryMovementStatus.cancelled)
          .toList();

  String get displayTitle => 'Transferencias de Inventario';

  // Filter properties and methods for futuristic UI
  final RxString currentFilter = 'all'.obs;

  int get todayTransfers {
    if (transfers.isEmpty) return 0;
    try {
      final todayTransfersList = transfers.where((t) => _isToday(t.createdAt)).toList();
      final grouped = _groupRelatedTransfers(todayTransfersList);
      return grouped.length;
    } catch (e) {
      print('❌ Error en todayTransfers: $e');
      return transfers.where((t) => _isToday(t.createdAt)).length; // Fallback
    }
  }

  int get weekTransfers {
    if (transfers.isEmpty) return 0;
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final weekTransfersList = transfers.where((t) => t.createdAt.isAfter(startOfWeekDay)).toList();
      final grouped = _groupRelatedTransfers(weekTransfersList);
      
      print('📋 TRANSFERENCIAS SCREEN - Esta semana:');
      print('   • Desde: ${startOfWeekDay.toIso8601String()}');
      print('   • Hasta: ${now.toIso8601String()}');
      print('   • Transfers raw: ${transfers.length}');
      print('   • Week transfers raw: ${weekTransfersList.length}');
      print('   • Grupos únicos: ${grouped.length}');
      
      return grouped.length;
    } catch (e) {
      print('❌ Error en weekTransfers: $e');
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return transfers.where((t) => t.createdAt.isAfter(startOfWeekDay)).length; // Fallback
    }
  }

  int get monthTransfers {
    if (transfers.isEmpty) return 0;
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final monthTransfersList = transfers.where((t) => t.createdAt.isAfter(startOfMonth)).toList();
      final grouped = _groupRelatedTransfers(monthTransfersList);
      return grouped.length;
    } catch (e) {
      print('❌ Error en monthTransfers: $e');
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return transfers.where((t) => t.createdAt.isAfter(startOfMonth)).length; // Fallback
    }
  }

  List<dynamic> get filteredTransfers {
    List<InventoryMovement> filtered = transfers;
    
    // Aplicar filtro por rango de fechas
    switch (currentFilter.value) {
      case 'today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
        filtered = transfers.where((t) => 
          t.createdAt.isAfter(startOfDay) && t.createdAt.isBefore(endOfDay)
        ).toList();
        break;
      case 'week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        filtered = transfers.where((t) => t.createdAt.isAfter(startOfWeekDay)).toList();
        break;
      case 'month':
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        filtered = transfers.where((t) => t.createdAt.isAfter(startOfMonth)).toList();
        break;
      case 'all':
      default:
        filtered = transfers;
        break;
    }
    
    // Agrupar transferencias relacionadas (múltiples productos)
    return _groupRelatedTransfers(filtered);
  }
  
  List<dynamic> _groupRelatedTransfers(List<InventoryMovement> transfers) {
    // FILTRAR SOLO TRANSFER_OUT para evitar duplicar cantidades
    final outTransfers = transfers.where((t) => 
      t.type == InventoryMovementType.transferOut
    ).toList();
    
    final Map<String, List<InventoryMovement>> groupedTransfers = {};
    
    for (final transfer in outTransfers) {
      // Crear clave de agrupación basada en almacenes, fecha y notas
      final groupKey = _generateTransferGroupKey(transfer);
      
      if (!groupedTransfers.containsKey(groupKey)) {
        groupedTransfers[groupKey] = [];
      }
      groupedTransfers[groupKey]!.add(transfer);
    }
    
    // Convertir grupos a formato para la vista
    return groupedTransfers.entries.map((entry) {
      final groupTransfers = entry.value;
      final mainTransfer = groupTransfers.first; // Usar el primer transfer como principal
      
      // Calcular totales del grupo
      final totalQuantity = groupTransfers.fold<int>(
        0, (sum, t) => sum + t.quantity,
      );
      
      // Recopilar y unificar detalles de productos (agrupar productos iguales)
      final Map<String, Map<String, dynamic>> unifiedProducts = {};
      
      for (final transfer in groupTransfers) {
        final productKey = '${transfer.productId}_${transfer.productSku}'; // Clave única por producto
        
        if (unifiedProducts.containsKey(productKey)) {
          // Producto ya existe, sumar cantidad
          unifiedProducts[productKey]!['quantity'] += transfer.quantity;
        } else {
          // Nuevo producto
          unifiedProducts[productKey] = {
            'name': transfer.productName,
            'sku': transfer.productSku,
            'quantity': transfer.quantity,
            'id': transfer.id,
            'productId': transfer.productId,
          };
        }
      }
      
      final productDetails = unifiedProducts.values.toList();
      
      // Debug log para verificar unificación
      print('🔍 AGRUPAMIENTO DEBUG:');
      print('   • Transfer_out agrupados: ${groupTransfers.length}');
      print('   • Productos únicos: ${unifiedProducts.length}');
      print('   • Cantidad total: $totalQuantity');
      for (final product in productDetails) {
        print('   • ${product['name']}: ${product['quantity']} unidades');
      }
      
      return {
        'id': mainTransfer.id,
        'groupKey': entry.key, // Para identificar el grupo
        'status': mainTransfer.status.name,
        'createdAt': mainTransfer.createdAt.toIso8601String(),
        'fromWarehouse': {'name': _getWarehouseNameFromTransfer(mainTransfer, isOrigin: true)},
        'toWarehouse': {'name': _getWarehouseNameFromTransfer(mainTransfer, isOrigin: false)},
        'totalProducts': unifiedProducts.length, // Número real de productos únicos
        'totalQuantity': totalQuantity, // Suma de todas las cantidades
        'productDetails': productDetails, // Lista de todos los productos
        'notes': mainTransfer.notes,
        'allTransfers': groupTransfers, // Para referencia completa
      };
    }).toList();
  }
  
  String _generateTransferGroupKey(InventoryMovement transfer) {
    // Agrupar por: almacenes + ventana de tiempo (mismo minuto) + notas similares
    final fromWarehouse = _getWarehouseNameFromTransfer(transfer, isOrigin: true);
    final toWarehouse = _getWarehouseNameFromTransfer(transfer, isOrigin: false);
    final timeWindow = transfer.createdAt.millisecondsSinceEpoch ~/ 60000; // Ventana de 1 minuto
    final notesKey = transfer.notes?.contains('Transfer between warehouses') == true
        ? 'batch_transfer' // Agrupar transferencias automáticas
        : transfer.notes ?? 'no_notes';
    
    return '${fromWarehouse}_${toWarehouse}_${timeWindow}_${notesKey}';
  }

  void setFilter(String filter) {
    currentFilter.value = filter;
    // Los filtros se aplican automáticamente en filteredTransfers getter
    // Forzar actualización de la UI
    update();
  }

  String _getWarehouseNameFromTransfer(InventoryMovement transfer, {required bool isOrigin}) {
    try {
      // Primero intentar usar el warehouseName directo si está disponible
      if (isOrigin && transfer.warehouseName != null && transfer.warehouseName!.isNotEmpty) {
        return transfer.warehouseName!;
      }

      // Si hay metadatos, extraer el ID del almacén
      String? warehouseId;
      if (transfer.metadata != null) {
        if (isOrigin) {
          warehouseId = transfer.metadata!['originWarehouse'] as String?;
        } else {
          warehouseId = transfer.metadata!['destinationWarehouse'] as String?;
        }
      }

      // Si no hay metadata, usar el warehouseId del transfer para origen
      if (warehouseId == null && isOrigin) {
        warehouseId = transfer.warehouseId;
      }

      // Buscar en la lista de almacenes
      if (warehouseId != null && warehouses.isNotEmpty) {
        final warehouse = warehouses.firstWhereOrNull((w) => w.id == warehouseId);
        if (warehouse != null) {
          return warehouse.name;
        }
      }

      // Fallback
      return isOrigin ? 'Almacén de origen' : 'Almacén de destino';
    } catch (e) {
      print('❌ Error obteniendo nombre de almacén: $e');
      return isOrigin ? 'Almacén de origen' : 'Almacén de destino';
    }
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // ==================== EXPORT METHODS ====================

  Future<void> exportTransfersToExcel() async {
    try {
      final filteredData = _getFilteredTransfersForExport();
      
      if (filteredData.isEmpty) {
        Get.snackbar('Sin datos', 'No hay transferencias para compartir con el filtro aplicado');
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportMovementsToExcel(filteredData);
      Get.snackbar('Éxito', 'Transferencias compartidas correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo Excel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadTransfersToExcel() async {
    try {
      final filteredData = _getFilteredTransfersForExport();
      
      if (filteredData.isEmpty) {
        Get.snackbar('Sin datos', 'No hay transferencias para descargar con el filtro aplicado');
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadMovementsToExcel(filteredData, warehouses: warehouses);

      final fileName = filePath.split('/').last;
      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando Excel: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportTransfersToPdf() async {
    try {
      final filteredData = _getFilteredTransfersForExport();
      
      if (filteredData.isEmpty) {
        Get.snackbar('Sin datos', 'No hay transferencias para compartir con el filtro aplicado');
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportMovementsToPDF(filteredData);
      Get.snackbar('Éxito', 'Transferencias compartidas correctamente');
    } catch (e) {
      Get.snackbar('Error', 'Error compartiendo PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadTransfersToPdf() async {
    try {
      final filteredData = _getFilteredTransfersForExport();
      
      if (filteredData.isEmpty) {
        Get.snackbar('Sin datos', 'No hay transferencias para descargar con el filtro aplicado');
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadMovementsToPDF(filteredData, warehouses: warehouses);

      final fileName = filePath.split('/').last;
      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando PDF: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<InventoryMovement> _getFilteredTransfersForExport() {
    List<InventoryMovement> filtered = transfers;
    
    // Aplicar filtro por rango de fechas
    switch (currentFilter.value) {
      case 'today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
        filtered = transfers.where((t) => 
          t.createdAt.isAfter(startOfDay) && t.createdAt.isBefore(endOfDay)
        ).toList();
        break;
      case 'week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        filtered = transfers.where((t) => t.createdAt.isAfter(startOfWeekDay)).toList();
        break;
      case 'month':
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        filtered = transfers.where((t) => t.createdAt.isAfter(startOfMonth)).toList();
        break;
      case 'all':
      default:
        filtered = transfers;
        break;
    }
    
    return filtered;
  }

  void showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Transferencias',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: const Text('Exportar a PDF'),
                    subtitle: const Text('Formato para impresión'),
                    onTap: () {
                      Get.back();
                      exportTransfersToPdf();
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('Exportar a Excel'),
                    subtitle: const Text('Formato para análisis'),
                    onTap: () {
                      Get.back();
                      exportTransfersToExcel();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==================== FILTER METHODS ====================

  InventoryMovementStatus? _getFilterStatus() {
    if (filterStatus.value.isEmpty) return null;
    return InventoryMovementStatus.values.firstWhere(
      (status) => status.name == filterStatus.value,
    );
  }

  void updateWarehouseFilter(String? warehouseId) {
    filterWarehouseId.value = warehouseId ?? '';
    loadTransfers();
  }

  void updateStatusFilter(String? status) {
    filterStatus.value = status ?? '';
    loadTransfers();
  }

  void updateDateRangeFilter(DateTime? dateFrom, DateTime? dateTo) {
    filterDateFrom.value = dateFrom;
    filterDateTo.value = dateTo;
    loadTransfers();
  }

  void clearFilters() {
    filterWarehouseId.value = '';
    filterStatus.value = '';
    filterDateFrom.value = null;
    filterDateTo.value = null;
    loadTransfers();
  }

  bool get hasFiltersApplied =>
      filterWarehouseId.value.isNotEmpty ||
      filterStatus.value.isNotEmpty ||
      filterDateFrom.value != null ||
      filterDateTo.value != null;

  // ==================== PRODUCT SEARCH ====================

  Future<List<Product>> searchProducts(String query) async {
    try {
      final params = SearchProductsParams(searchTerm: query, limit: 20);

      final result = await searchProductsUseCase(params);

      return result.fold(
        (failure) {
          print('❌ Error searching products: ${failure.message}');
          return <Product>[];
        },
        (products) {
          print('✅ Found ${products.length} products for query: $query');
          return products;
        },
      );
    } catch (e) {
      print('❌ Error searching products: $e');
      return <Product>[];
    }
  }

  // ==================== INVENTORY BALANCE ====================

  Future<int> getProductStock(String productId, String warehouseId) async {
    try {
      final result = await getInventoryBalanceByProductUseCase(
        productId,
        warehouseId: warehouseId,
      );

      return result.fold(
        (failure) {
          print('❌ Error getting product stock: ${failure.message}');
          return 0;
        },
        (balance) {
          print(
            '✅ Stock for product $productId in warehouse $warehouseId: ${balance.availableQuantity}',
          );
          return balance.availableQuantity;
        },
      );
    } catch (e) {
      print('❌ Error getting product stock: $e');
      return 0;
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  List<Product> get selectedProducts {
    // This would need to be implemented to get product details from IDs
    return [];
  }

  int get totalProductsInTransfer => transferItems.length;

  int get totalQuantityInTransfer =>
      transferItems.fold(0, (sum, item) => sum + item.quantity);
}
