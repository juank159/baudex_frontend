// lib/features/inventory/presentation/controllers/warehouses_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../domain/entities/warehouse_with_stats.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/usecases/get_warehouse_stats_usecase.dart';
import '../../domain/usecases/delete_warehouse_usecase.dart';
import '../services/warehouses_export_service.dart';
import '../services/warehouse_network_service.dart';
import '../services/warehouse_performance_service.dart';

class WarehousesController extends GetxController {
  // Casos de uso
  final GetWarehousesUseCase _getWarehousesUseCase;
  final GetWarehouseStatsUseCase _getWarehouseStatsUseCase;
  final DeleteWarehouseUseCase _deleteWarehouseUseCase;

  WarehousesController({
    required GetWarehousesUseCase getWarehousesUseCase,
    required GetWarehouseStatsUseCase getWarehouseStatsUseCase,
    required DeleteWarehouseUseCase deleteWarehouseUseCase,
  })  : _getWarehousesUseCase = getWarehousesUseCase,
        _getWarehouseStatsUseCase = getWarehouseStatsUseCase,
        _deleteWarehouseUseCase = deleteWarehouseUseCase;

  // ==================== OBSERVABLES ====================

  final _warehouses = <WarehouseWithStats>[].obs;
  final _filteredWarehouses = <WarehouseWithStats>[].obs;
  final _isLoading = false.obs;
  final _error = ''.obs;
  final _showFilters = false.obs;

  // Filtros básicos
  final _searchQuery = ''.obs;
  final _selectedStatus = Rx<bool?>(null); // null = todos, true = activos, false = inactivos
  final _sortBy = 'name'.obs; // name, code, createdAt
  final _sortOrder = 'asc'.obs; // asc, desc
  
  // Filtros avanzados
  final _dateFrom = Rx<DateTime?>(null);
  final _dateTo = Rx<DateTime?>(null);
  final _filterWithDescription = false.obs;
  final _filterWithAddress = false.obs;
  final _filterRecent = false.obs;

  // ==================== GETTERS ====================

  List<WarehouseWithStats> get warehouses => _filteredWarehouses;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  RxBool get showFilters => _showFilters;
  String get searchQuery => _searchQuery.value;
  bool? get selectedStatus => _selectedStatus.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  
  // Getters para filtros avanzados
  DateTime? get dateFrom => _dateFrom.value;
  DateTime? get dateTo => _dateTo.value;
  bool get filterWithDescription => _filterWithDescription.value;
  bool get filterWithAddress => _filterWithAddress.value;
  bool get filterRecent => _filterRecent.value;
  bool get hasWarehouses => _warehouses.isNotEmpty;

  // ==================== LIFECYCLE ====================

  // Workers de los listeners de filtros — rastreados para poder disposarlos
  // en onClose y evitar leaks si el controller se recrea (fenix).
  final List<Worker> _filterWorkers = [];

  @override
  void onInit() {
    super.onInit();
    loadWarehouses();

    // Listeners de filtros básicos y avanzados (todos llaman _applyFiltersAsync).
    _filterWorkers.addAll([
      ever(_searchQuery, (_) => _applyFiltersAsync()),
      ever(_selectedStatus, (_) => _applyFiltersAsync()),
      ever(_sortBy, (_) => _applyFiltersAsync()),
      ever(_sortOrder, (_) => _applyFiltersAsync()),
      ever(_dateFrom, (_) => _applyFiltersAsync()),
      ever(_dateTo, (_) => _applyFiltersAsync()),
      ever(_filterWithDescription, (_) => _applyFiltersAsync()),
      ever(_filterWithAddress, (_) => _applyFiltersAsync()),
      ever(_filterRecent, (_) => _applyFiltersAsync()),
    ]);
  }

  @override
  void onClose() {
    // Disposar todos los workers de filtros antes de limpiar el resto.
    for (final w in _filterWorkers) {
      w.dispose();
    }
    _filterWorkers.clear();
    WarehousePerformanceService.dispose();
    super.onClose();
  }

  // ==================== PUBLIC METHODS ====================

  /// Recargar almacenes (método público para actualizar desde otros controladores)
  Future<void> refreshWarehouses() async {
    // Limpiar cache para forzar recarga completa
    WarehousePerformanceService.clearCache();
    await loadWarehouses();
  }

  /// Cargar almacenes desde la API con manejo avanzado de errores
  Future<void> loadWarehouses() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Ejecutar con reintentos automáticos y manejo de red
      await WarehouseNetworkService.executeWithRetry(
        () async {
          final result = await _getWarehousesUseCase();
          
          result.fold(
            (failure) {
              final errorMessage = WarehouseNetworkService.handleNetworkError(failure);
              _error.value = errorMessage;
              throw Exception(errorMessage);
            },
            (warehouses) async {
              // Cargar estadísticas para cada almacén activo
              final warehousesWithStats = <WarehouseWithStats>[];
              
              for (final warehouse in warehouses) {
                if (warehouse.isActive) {
                  // Intentar cargar estadísticas
                  final statsResult = await _getWarehouseStatsUseCase(warehouse.id);
                  
                  statsResult.fold(
                    (failure) {
                      // Si falla, agregar el almacén sin estadísticas
                      print('⚠️ No se pudieron cargar estadísticas para ${warehouse.name}: ${failure.message}');
                      warehousesWithStats.add(WarehouseWithStats(warehouse: warehouse));
                    },
                    (stats) {
                      // Agregar almacén con estadísticas
                      warehousesWithStats.add(WarehouseWithStats(warehouse: warehouse, stats: stats));
                    },
                  );
                } else {
                  // Para almacenes inactivos, no cargar estadísticas
                  warehousesWithStats.add(WarehouseWithStats(warehouse: warehouse));
                }
              }
              
              _warehouses.value = warehousesWithStats;
              _applyFiltersAsync();
            },
          );
        },
        operationName: 'Cargar almacenes',
        showProgress: true,
      );

    } catch (e) {
      final errorMessage = WarehouseNetworkService.handleNetworkError(e);
      _error.value = errorMessage;
      
      // Solo mostrar snackbar si no es un error de red ya manejado
      if (!WarehouseNetworkService.isRetrying) {
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () {
              Get.back();
              retryLoadWarehouses();
            },
            child: const Text('Reintentar', style: TextStyle(color: Colors.red)),
          ),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reintentar carga manual
  Future<void> retryLoadWarehouses() async {
    await loadWarehouses();
  }

  /// Alternar visibilidad de filtros
  void toggleFilters() {
    _showFilters.value = !_showFilters.value;
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _searchQuery.value = '';
  }

  /// Verificar si hay filtros activos
  bool get hasActiveFilters {
    return _selectedStatus.value != null ||
           _dateFrom.value != null ||
           _dateTo.value != null ||
           _filterWithDescription.value ||
           _filterWithAddress.value ||
           _filterRecent.value;
  }

  /// Establecer campo de ordenamiento
  void setSortBy(String field) {
    if (_sortBy.value == field) {
      // Si es el mismo campo, cambiar orden
      _sortOrder.value = _sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      // Si es campo diferente, establecer ascendente
      _sortBy.value = field;
      _sortOrder.value = 'asc';
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a crear almacén
  void goToCreateWarehouse() async {
    final result = await Get.toNamed(AppRoutes.warehousesCreate);
    
    // Si se creó un almacén, refrescar la lista y mostrar confirmación
    if (result != null && result is Map && result['action'] == 'created') {
      await refreshWarehouses();
      Get.snackbar(
        'Éxito',
        'Almacén creado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check, color: Colors.green),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Navegar a editar almacén
  void goToEditWarehouse(String warehouseId) async {
    final result = await Get.toNamed(
      AppRoutes.warehouseEdit(warehouseId),
      arguments: {'warehouseId': warehouseId},
    );
    
    // Si se actualizó un almacén, refrescar la lista y mostrar confirmación
    if (result != null && result is Map && result['action'] == 'updated') {
      print('🔄 Refrescando lista de almacenes después de actualización...');
      await refreshWarehouses();
      print('✅ Lista de almacenes refrescada. Total: ${_warehouses.length}, Filtrados: ${_filteredWarehouses.length}');
      Get.snackbar(
        'Éxito',
        'Almacén actualizado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check, color: Colors.green),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Navegar a detalle de almacén
  void goToWarehouseDetail(String warehouseId) async {
    final result = await Get.toNamed(
      AppRoutes.warehouseDetail(warehouseId),
      arguments: {'warehouseId': warehouseId},
    );
    
    // Si se eliminó un almacén desde el detalle, refrescar la lista
    if (result != null && result is Map && result['action'] == 'deleted') {
      await refreshWarehouses();
    }
  }

  // ==================== FILTER METHODS ====================

  /// Actualizar query de búsqueda con debounce
  void updateSearchQuery(String query) {
    WarehousePerformanceService.debounceOperation(
      'search_${query.hashCode}',
      () {
        _searchQuery.value = query;
      },
    );
  }

  /// Limpiar query de búsqueda
  void clearSearchQuery() {
    _searchQuery.value = '';
  }

  /// Actualizar filtro de estado
  void updateStatusFilter(bool? status) {
    _selectedStatus.value = status;
  }

  /// Actualizar orden
  void updateSort(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
  }

  /// Limpiar todos los filtros
  void clearAllFilters() {
    _searchQuery.value = '';
    _selectedStatus.value = null;
    _sortBy.value = 'name';
    _sortOrder.value = 'asc';
    // Limpiar filtros avanzados
    _dateFrom.value = null;
    _dateTo.value = null;
    _filterWithDescription.value = false;
    _filterWithAddress.value = false;
    _filterRecent.value = false;
  }
  
  // ==================== ADVANCED FILTER METHODS ====================
  
  /// Establecer filtro de rango de fechas
  void setDateFilter(DateTime from, DateTime to) {
    _dateFrom.value = from;
    _dateTo.value = to;
  }
  
  /// Limpiar filtro de fechas
  void clearDateFilter() {
    _dateFrom.value = null;
    _dateTo.value = null;
  }
  
  /// Verificar si hay filtro de fechas activo
  bool hasDateFilter() {
    return _dateFrom.value != null && _dateTo.value != null;
  }
  
  /// Obtener texto del rango de fechas
  String getDateRangeText() {
    if (!hasDateFilter()) {
      return 'Filtrar por fecha de creación';
    }
    
    final from = _dateFrom.value!;
    final to = _dateTo.value!;
    return '${_formatDate(from)} - ${_formatDate(to)}';
  }
  
  /// Alternar filtro de descripción
  void toggleDescriptionFilter(bool? value) {
    _filterWithDescription.value = value ?? false;
  }
  
  /// Alternar filtro de dirección
  void toggleAddressFilter(bool? value) {
    _filterWithAddress.value = value ?? false;
  }
  
  /// Alternar filtro de recientes
  void toggleRecentFilter(bool? value) {
    _filterRecent.value = value ?? false;
  }
  
  /// Limpiar criterios múltiples
  void clearMultipleCriteria() {
    _filterWithDescription.value = false;
    _filterWithAddress.value = false;
    _filterRecent.value = false;
  }
  
  /// Verificar si hay criterios múltiples activos
  bool hasMultipleCriteria() {
    return _filterWithDescription.value || 
           _filterWithAddress.value || 
           _filterRecent.value;
  }
  
  /// Obtener texto de criterios múltiples
  String getMultipleCriteriaText() {
    if (!hasMultipleCriteria()) {
      return 'Filtros adicionales';
    }
    
    List<String> criteria = [];
    if (_filterWithDescription.value) criteria.add('Con descripción');
    if (_filterWithAddress.value) criteria.add('Con dirección');
    if (_filterRecent.value) criteria.add('Recientes');
    
    return criteria.join(', ');
  }
  
  // ==================== EXPORT METHODS ====================
  
  /// Exportar a Excel
  Future<void> exportToExcel() async {
    if (_filteredWarehouses.isEmpty) {
      Get.snackbar(
        'Sin datos',
        'No hay almacenes para exportar',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      // Extraer solo los warehouses para la exportación
      final warehousesOnly = _filteredWarehouses.map((w) => w.warehouse).toList();
      await WarehousesExportService.exportToExcel(warehousesOnly);
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar a Excel: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
  
  /// Exportar a CSV
  Future<void> exportToCsv() async {
    if (_filteredWarehouses.isEmpty) {
      Get.snackbar(
        'Sin datos',
        'No hay almacenes para exportar',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      // Extraer solo los warehouses para la exportación
      final warehousesOnly = _filteredWarehouses.map((w) => w.warehouse).toList();
      await WarehousesExportService.exportToCsv(warehousesOnly);
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar a CSV: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
  
  /// Exportar a PDF
  Future<void> exportToPdf() async {
    if (_filteredWarehouses.isEmpty) {
      Get.snackbar(
        'Sin datos',
        'No hay almacenes para exportar',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      // Extraer solo los warehouses para la exportación
      final warehousesOnly = _filteredWarehouses.map((w) => w.warehouse).toList();
      await WarehousesExportService.exportToPdf(warehousesOnly);
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar a PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
  
  /// Imprimir almacenes
  Future<void> printWarehouses() async {
    if (_filteredWarehouses.isEmpty) {
      Get.snackbar(
        'Sin datos',
        'No hay almacenes para imprimir',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      // Extraer solo los warehouses para la impresión
      final warehousesOnly = _filteredWarehouses.map((w) => w.warehouse).toList();
      await WarehousesExportService.printWarehouses(warehousesOnly);
    } catch (e) {
      Get.snackbar(
        'Error de Impresión',
        'No se pudo imprimir: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  // ==================== CRUD METHODS ====================

  /// Eliminar almacén
  Future<void> deleteWarehouse(String warehouseId) async {
    final warehouse = _warehouses.firstWhere((w) => w.id == warehouseId);
    
    // Confirmar eliminación
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro que deseas eliminar el almacén "${warehouse.name}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _isLoading.value = true;

      final result = await _deleteWarehouseUseCase(warehouseId);
      
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
          // Remover de la lista local
          _warehouses.removeWhere((w) => w.id == warehouseId);
          _applyFilters();
          
          Get.snackbar(
            'Éxito',
            'Almacén eliminado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check, color: Colors.green),
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

  // ==================== PRIVATE METHODS ====================

  /// Wrapper para llamar _applyFilters de forma asíncrona
  void _applyFiltersAsync() {
    _applyFilters();
  }

  /// Aplicar filtros y ordenamiento simplificado
  Future<void> _applyFilters() async {
    try {
      List<WarehouseWithStats> filtered = List.from(_warehouses);

      // Filtro por búsqueda
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        filtered = filtered.where((warehouseWithStats) {
          final warehouse = warehouseWithStats.warehouse;
          return warehouse.name.toLowerCase().contains(query) ||
                 warehouse.code.toLowerCase().contains(query) ||
                 (warehouse.description?.toLowerCase().contains(query) ?? false) ||
                 (warehouse.address?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Filtro por estado
      if (_selectedStatus.value != null) {
        filtered = filtered.where((warehouseWithStats) {
          return warehouseWithStats.warehouse.isActive == _selectedStatus.value;
        }).toList();
      }

      // Filtro por descripción
      if (_filterWithDescription.value) {
        filtered = filtered.where((warehouseWithStats) {
          final warehouse = warehouseWithStats.warehouse;
          return warehouse.description != null && warehouse.description!.trim().isNotEmpty;
        }).toList();
      }
      
      // Filtro por dirección
      if (_filterWithAddress.value) {
        filtered = filtered.where((warehouseWithStats) {
          final warehouse = warehouseWithStats.warehouse;
          return warehouse.address != null && warehouse.address!.trim().isNotEmpty;
        }).toList();
      }

      // Ordenamiento
      filtered.sort((a, b) {
        int comparison = 0;
        
        switch (_sortBy.value) {
          case 'name':
            comparison = a.warehouse.name.compareTo(b.warehouse.name);
            break;
          case 'code':
            comparison = a.warehouse.code.compareTo(b.warehouse.code);
            break;
          default:
            comparison = a.warehouse.name.compareTo(b.warehouse.name);
        }

        return _sortOrder.value == 'asc' ? comparison : -comparison;
      });

      _filteredWarehouses.value = filtered;
      _filteredWarehouses.refresh(); // Forzar notificación a observers
      print('🔍 Filtros aplicados: ${filtered.length} almacenes mostrados de ${_warehouses.length} totales');
      
    } catch (e) {
      print('❌ Error aplicando filtros: $e');
      _applyFiltersFallback();
    }
  }

  /// Filtrado de respaldo (síncrono) para casos de error
  void _applyFiltersFallback() {
    List<WarehouseWithStats> filtered = List.from(_warehouses);

    // Filtro por búsqueda
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((warehouseWithStats) {
        final warehouse = warehouseWithStats.warehouse;
        return warehouse.name.toLowerCase().contains(query) ||
               warehouse.code.toLowerCase().contains(query) ||
               (warehouse.description?.toLowerCase().contains(query) ?? false) ||
               (warehouse.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtro por estado
    if (_selectedStatus.value != null) {
      filtered = filtered.where((warehouseWithStats) {
        return warehouseWithStats.warehouse.isActive == _selectedStatus.value;
      }).toList();
    }

    // Filtro por descripción
    if (_filterWithDescription.value) {
      filtered = filtered.where((warehouseWithStats) {
        final warehouse = warehouseWithStats.warehouse;
        return warehouse.description != null && warehouse.description!.trim().isNotEmpty;
      }).toList();
    }
    
    // Filtro por dirección
    if (_filterWithAddress.value) {
      filtered = filtered.where((warehouseWithStats) {
        final warehouse = warehouseWithStats.warehouse;
        return warehouse.address != null && warehouse.address!.trim().isNotEmpty;
      }).toList();
    }

    // Ordenamiento simple
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy.value) {
        case 'name':
          comparison = a.warehouse.name.compareTo(b.warehouse.name);
          break;
        case 'code':
          comparison = a.warehouse.code.compareTo(b.warehouse.code);
          break;
        default:
          comparison = a.warehouse.name.compareTo(b.warehouse.name);
      }

      return _sortOrder.value == 'asc' ? comparison : -comparison;
    });

    _filteredWarehouses.value = filtered;
    _filteredWarehouses.refresh(); // Forzar notificación a observers
  }
  
  /// Formatear fecha para mostrar
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ==================== STATISTICS METHODS ====================

  /// Obtener estadísticas de almacenes
  Map<String, dynamic> getWarehousesStats() {
    return {
      'total': _warehouses.length,
      'active': _warehouses.where((w) => w.warehouse.isActive).length,
      'inactive': _warehouses.where((w) => !w.warehouse.isActive).length,
      'filtered': _filteredWarehouses.length,
    };
  }

  // ==================== DEBUGGING METHODS ====================

  /// Información de debug
  void printDebugInfo() {
    print('🏪 WarehousesController Debug Info:');
    print('   Total warehouses: ${_warehouses.length}');
    print('   Filtered warehouses: ${_filteredWarehouses.length}');
    print('   Search query: "$_searchQuery"');
    print('   Status filter: $_selectedStatus');
    print('   Sort: $_sortBy $_sortOrder');
    print('   Loading: $_isLoading');
    print('   Error: "$_error"');
  }
}