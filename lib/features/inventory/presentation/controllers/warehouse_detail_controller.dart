// lib/features/inventory/presentation/controllers/warehouse_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/get_warehouse_by_id_usecase.dart';
import '../../domain/usecases/delete_warehouse_usecase.dart';
import '../../domain/usecases/check_warehouse_has_movements_usecase.dart';
import '../../domain/usecases/get_active_warehouses_count_usecase.dart';

class WarehouseDetailController extends GetxController {
  // Casos de uso
  final GetWarehouseByIdUseCase _getWarehouseByIdUseCase;
  final DeleteWarehouseUseCase _deleteWarehouseUseCase;
  final CheckWarehouseHasMovementsUseCase _checkWarehouseHasMovementsUseCase;
  final GetActiveWarehousesCountUseCase _getActiveWarehousesCountUseCase;

  WarehouseDetailController({
    required GetWarehouseByIdUseCase getWarehouseByIdUseCase,
    required DeleteWarehouseUseCase deleteWarehouseUseCase,
    required CheckWarehouseHasMovementsUseCase
    checkWarehouseHasMovementsUseCase,
    required GetActiveWarehousesCountUseCase getActiveWarehousesCountUseCase,
  }) : _getWarehouseByIdUseCase = getWarehouseByIdUseCase,
       _deleteWarehouseUseCase = deleteWarehouseUseCase,
       _checkWarehouseHasMovementsUseCase = checkWarehouseHasMovementsUseCase,
       _getActiveWarehousesCountUseCase = getActiveWarehousesCountUseCase;

  // ==================== OBSERVABLES ====================

  final _warehouse = Rx<Warehouse?>(null);
  final _isLoading = false.obs;
  final _error = ''.obs;
  final _warehouseId = ''.obs;

  // Mock data para estadísticas (en un futuro se puede conectar con API real)
  final _totalProducts = 0.obs;
  final _totalMovements = 0.obs;
  final _lastMovementDate = Rx<DateTime?>(null);
  final _averageStock = 0.0.obs;

  // ==================== GETTERS ====================

  Warehouse? get warehouse => _warehouse.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get warehouseId => _warehouseId.value;

  // Estadísticas getters
  int get totalProducts => _totalProducts.value;
  int get totalMovements => _totalMovements.value;
  DateTime? get lastMovementDate => _lastMovementDate.value;
  double get averageStock => _averageStock.value;

  // Computed properties
  bool get hasWarehouse => _warehouse.value != null;
  bool get hasError => _error.value.isNotEmpty;
  String get warehouseName => _warehouse.value?.name ?? 'Almacén';
  String get warehouseCode => _warehouse.value?.code ?? '';
  bool get isActive => _warehouse.value?.isActive ?? false;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();

    // Obtener ID del warehouse desde los argumentos o parámetros
    final arguments = Get.arguments as Map<String, dynamic>?;

    if (arguments != null && arguments['warehouseId'] != null) {
      _warehouseId.value = arguments['warehouseId'] as String;
    } else if (Get.parameters['id'] != null &&
        Get.currentRoute.contains('warehouse')) {
      // Solo usar parámetro de ruta cuando estamos en una ruta de warehouse
      // (evita tomar el ID de otra entidad cuando se carga como dependencia indirecta)
      _warehouseId.value = Get.parameters['id']!;
    }

    if (_warehouseId.value.isNotEmpty) {
      loadWarehouseDetails();
      _loadWarehouseStats();
    }
  }

  // ==================== DATA LOADING ====================

  /// Cargar detalles del almacén
  Future<void> loadWarehouseDetails() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final result = await _getWarehouseByIdUseCase(_warehouseId.value);

      result.fold(
        (failure) {
          _error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (warehouse) {
          _warehouse.value = warehouse;
        },
      );
    } catch (e) {
      _error.value = 'Error inesperado: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refrescar datos del almacén
  Future<void> refreshWarehouse() async {
    await loadWarehouseDetails();
    await _loadWarehouseStats();
  }

  /// Cargar estadísticas del almacén (mock data por ahora)
  Future<void> _loadWarehouseStats() async {
    // Simular carga de estadísticas
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data - en el futuro se reemplazaría con calls reales a la API
    _totalProducts.value = 150 + (DateTime.now().millisecond % 100);
    _totalMovements.value = 45 + (DateTime.now().millisecond % 20);
    _lastMovementDate.value = DateTime.now().subtract(
      Duration(hours: DateTime.now().hour % 24),
    );
    _averageStock.value = 75.5 + (DateTime.now().millisecond % 25);
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a editar almacén
  void goToEditWarehouse() async {
    if (_warehouse.value == null) return;

    final result = await Get.toNamed(
      AppRoutes.warehouseEdit(_warehouseId.value),
      arguments: {'warehouseId': _warehouseId.value},
    );

    // Si se actualizó el almacén, refrescar los datos
    if (result != null && result is Map && result['action'] == 'updated') {
      await refreshWarehouse();
    }
  }

  /// Navegar de vuelta a la lista de almacenes
  void goBackToWarehouses() {
    Get.back();
  }

  /// Navegar a los movimientos de este almacén
  void goToWarehouseMovements() {
    // TODO: Implementar cuando exista la pantalla de movimientos por almacén
    Get.snackbar(
      'Próximamente',
      'Vista de movimientos por almacén en desarrollo',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
    );
  }

  /// Navegar al inventario de este almacén
  void goToWarehouseInventory() {
    // TODO: Implementar cuando exista la pantalla de inventario por almacén
    Get.snackbar(
      'Próximamente',
      'Vista de inventario por almacén en desarrollo',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
    );
  }

  // ==================== CRUD OPERATIONS ====================

  /// Eliminar almacén con validaciones de integridad
  Future<void> deleteWarehouse() async {
    if (_warehouse.value == null) return;

    final warehouse = _warehouse.value!;

    try {
      _isLoading.value = true;

      // 1. Verificar si es el único almacén activo
      if (warehouse.isActive) {
        final activeCountResult = await _getActiveWarehousesCountUseCase();
        final activeCount = activeCountResult.fold((l) => 0, (r) => r);

        if (activeCount <= 1) {
          Get.snackbar(
            'No se puede eliminar',
            'No puedes eliminar el único almacén activo del sistema',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.warning, color: Colors.orange),
          );
          return;
        }
      }

      // 2. Verificar si tiene movimientos de inventario
      final hasMovementsResult = await _checkWarehouseHasMovementsUseCase(
        _warehouseId.value,
      );
      final hasMovements = hasMovementsResult.fold((l) => false, (r) => r);

      String warningMessage =
          '¿Estás seguro que deseas eliminar el almacén "${warehouse.name}"?\n\n';

      if (hasMovements) {
        warningMessage +=
            '⚠️ ADVERTENCIA: Este almacén tiene movimientos de inventario asociados. '
            'Eliminar este almacén puede afectar la trazabilidad de los productos.\n\n';
      }

      warningMessage += 'Esta acción no se puede deshacer.';

      // 3. Confirmar eliminación con advertencias
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Row(
            children: [
              Icon(
                hasMovements ? Icons.warning : Icons.delete,
                color: hasMovements ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                hasMovements
                    ? 'Eliminar con precaución'
                    : 'Confirmar eliminación',
              ),
            ],
          ),
          content: Text(warningMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasMovements ? Colors.orange : Colors.red,
              ),
              child: Text(
                hasMovements ? 'Eliminar de todas formas' : 'Eliminar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 4. Proceder con la eliminación
      final result = await _deleteWarehouseUseCase(_warehouseId.value);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (success) {
          Get.snackbar(
            'Éxito',
            'Almacén eliminado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check, color: Colors.green),
          );

          // Regresar a la lista de almacenes
          Get.back(
            result: {'action': 'deleted', 'warehouseId': _warehouseId.value},
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Alternar estado activo/inactivo del almacén con validaciones
  Future<void> toggleWarehouseStatus() async {
    if (_warehouse.value == null) return;

    final newStatus = !_warehouse.value!.isActive;
    final statusText = newStatus ? 'activar' : 'desactivar';

    try {
      _isLoading.value = true;

      // Validación: No desactivar el último almacén activo
      if (!newStatus && _warehouse.value!.isActive) {
        final activeCountResult = await _getActiveWarehousesCountUseCase();
        final activeCount = activeCountResult.fold((l) => 0, (r) => r);

        if (activeCount <= 1) {
          Get.snackbar(
            'No se puede desactivar',
            'No puedes desactivar el único almacén activo del sistema',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.warning, color: Colors.orange),
          );
          return;
        }
      }

      String confirmMessage =
          '¿Estás seguro que deseas $statusText el almacén "${_warehouse.value!.name}"?';

      if (!newStatus) {
        // Verificar si tiene movimientos antes de desactivar
        final hasMovementsResult = await _checkWarehouseHasMovementsUseCase(
          _warehouseId.value,
        );
        final hasMovements = hasMovementsResult.fold((l) => false, (r) => r);

        if (hasMovements) {
          confirmMessage +=
              '\n\n⚠️ Este almacén tiene movimientos de inventario. '
              'Desactivarlo impedirá nuevas operaciones pero no afectará el historial.';
        }
      }

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Confirmar $statusText'),
          content: Text(confirmMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.orange,
              ),
              child: Text(
                statusText.capitalize!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // TODO: Implementar cuando exista el caso de uso para cambiar estado
      // Por ahora solo actualizamos localmente
      _warehouse.value = _warehouse.value!.copyWith(isActive: newStatus);
      _warehouse.refresh();

      Get.snackbar(
        'Éxito',
        'Estado del almacén actualizado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check, color: Colors.green),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cambiar estado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Obtener color basado en el estado del almacén
  Color getStatusColor() {
    if (_warehouse.value == null) return Colors.grey;
    return _warehouse.value!.isActive ? Colors.green : Colors.red;
  }

  /// Obtener texto del estado
  String getStatusText() {
    if (_warehouse.value == null) return 'Desconocido';
    return _warehouse.value!.isActive ? 'Activo' : 'Inactivo';
  }

  /// Obtener texto formateado de la última actualización
  String getLastUpdateText() {
    if (_warehouse.value?.updatedAt == null) return 'Desconocido';

    final now = DateTime.now();
    final updated = _warehouse.value!.updatedAt!;
    final difference = now.difference(updated);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }

  // ==================== DEBUGGING ====================

  void printDebugInfo() {
    print('🏪 WarehouseDetailController Debug Info:');
    print('   Warehouse ID: $_warehouseId');
    print('   Is loading: $isLoading');
    print('   Has warehouse: $hasWarehouse');
    print('   Has error: $hasError');
    print('   Error: "$error"');
    if (hasWarehouse) {
      print(
        '   Warehouse: ${_warehouse.value!.name} (${_warehouse.value!.code})',
      );
      print('   Is active: ${_warehouse.value!.isActive}');
    }
    print('   Stats - Products: $totalProducts, Movements: $totalMovements');
  }
}
