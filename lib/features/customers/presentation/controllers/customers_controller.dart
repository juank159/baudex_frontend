// lib/features/customers/presentation/controllers/customers_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/mixins/cache_first_mixin.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/search_customers_usecase.dart';

class CustomersController extends GetxController
    with CacheFirstMixin<Customer>, SyncAutoRefreshMixin {
  // Dependencies
  final GetCustomersUseCase _getCustomersUseCase;
  final DeleteCustomerUseCase _deleteCustomerUseCase;
  final SearchCustomersUseCase _searchCustomersUseCase;

  CustomersController({
    required GetCustomersUseCase getCustomersUseCase,
    required DeleteCustomerUseCase deleteCustomerUseCase,
    required SearchCustomersUseCase searchCustomersUseCase,
  }) : _getCustomersUseCase = getCustomersUseCase,
       _deleteCustomerUseCase = deleteCustomerUseCase,
       _searchCustomersUseCase = searchCustomersUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isDeleting = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final _customers = <Customer>[].obs;
  final _searchResults = <Customer>[].obs;

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;
  final _hasPreviousPage = false.obs;

  // Filtros y búsqueda
  final _currentStatus = Rxn<CustomerStatus>();
  final _currentDocumentType = Rxn<DocumentType>();
  final _searchTerm = ''.obs;
  final _selectedCity = ''.obs;
  final _selectedState = ''.obs;
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;

  // UI Controllers - Igual que credit notes
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // Configuración
  static const int _pageSize = 20;

  // Control de llamadas duplicadas
  bool _isInitialized = false;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isDeleting => _isDeleting.value;
  bool get isRefreshing => _isRefreshing.value;

  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;

  CustomerStatus? get currentStatus => _currentStatus.value;
  DocumentType? get currentDocumentType => _currentDocumentType.value;
  String get searchTerm => _searchTerm.value;
  String get selectedCity => _selectedCity.value;
  String get selectedState => _selectedState.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;

  bool get hasCustomers => _customers.isNotEmpty;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _setupSearchListener();
    _setupScrollListener();
    setupSyncListener();
    print('🎯 CustomersController onInit() llamado');
  }

  @override
  Future<void> onSyncCompleted() async {
    invalidateCache();
    await _refreshInBackground();
  }

  @override
  void onReady() {
    super.onReady();
    print('🎯 CustomersController onReady() llamado - Cargando clientes...');
    _initializeData();
  }

  @override
  void onClose() {
    // Solo cancelar el timer, NO disponer los controllers
    // porque este controller es permanente
    _searchDebounceTimer?.cancel();
    // NO llamar dispose en searchController y scrollController
    // porque el controller es permanente y se reutiliza
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  /// Inicializar datos de forma optimizada
  Future<void> _initializeData() async {
    if (_isInitialized) {
      print('⚠️ CustomersController ya inicializado, omitiendo...');
      return;
    }

    try {
      print('🚀 Inicializando CustomersController...');

      // ✅ CARGAR CLIENTES AUTOMÁTICAMENTE al entrar a la pantalla
      await loadCustomers();

      _isInitialized = true;
      print(
        '✅ CustomersController inicializado correctamente con clientes cargados',
      );
    } catch (e) {
      print('❌ Error al inicializar CustomersController: $e');
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar clientes
  Future<void> loadCustomers({bool showLoading = true, bool forceRefresh = false}) async {
    // Evitar múltiples llamadas simultáneas
    if (_isLoading.value) return;

    // Cache-first: mostrar datos inmediatos si disponibles
    if (tryLoadFromCache(
      onHit: (items) { _customers.value = List.from(items); },
      hasFilters: _hasActiveFilters(),
      isFirstPage: _currentPage.value == 1,
      isSearching: _searchTerm.value.isNotEmpty,
      forceRefresh: forceRefresh,
    )) {
      _isLoading.value = false;
      refreshInBackground(() => _fetchCustomers());
      return;
    }

    if (showLoading) _isLoading.value = true;

    try {
      await _fetchCustomers();
    } catch (e) {
      print('❌ Error inesperado al cargar clientes: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchCustomers() async {
    final result = await _getCustomersUseCase(
      GetCustomersParams(
        page: 1,
        limit: _pageSize,
        search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
        status: _currentStatus.value,
        documentType: _currentDocumentType.value,
        city: _selectedCity.value.isEmpty ? null : _selectedCity.value,
        state: _selectedState.value.isEmpty ? null : _selectedState.value,
        sortBy: _sortBy.value,
        sortOrder: _sortOrder.value,
      ),
    );

    result.fold(
      (failure) {
        _showError('Error al cargar clientes', failure.message);
      },
      (paginatedResult) {
        _customers.value = paginatedResult.data;
        _updatePaginationInfo(paginatedResult.meta);
        // Actualizar cache si es página 1 sin filtros
        if (_currentPage.value == 1 && !_hasActiveFilters()) {
          updateCache(paginatedResult.data);
        }
      },
    );
  }

  bool _hasActiveFilters() {
    return _currentStatus.value != null ||
        _currentDocumentType.value != null ||
        _selectedCity.value.isNotEmpty ||
        _selectedState.value.isNotEmpty;
  }

  Future<void> _refreshInBackground() async {
    refreshInBackground(() => _fetchCustomers());
  }

  /// Cargar más clientes (paginación)
  Future<void> loadMoreCustomers() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _isLoadingMore.value = true;

    try {
      print('📄 Cargando más clientes (página ${_currentPage.value + 1})...');

      final result = await _getCustomersUseCase(
        GetCustomersParams(
          page: _currentPage.value + 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value,
          documentType: _currentDocumentType.value,
          city: _selectedCity.value.isEmpty ? null : _selectedCity.value,
          state: _selectedState.value.isEmpty ? null : _selectedState.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar más clientes', failure.message);
        },
        (paginatedResult) {
          _customers.addAll(paginatedResult.data);
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Más clientes cargados: ${paginatedResult.data.length}');
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar clientes
  Future<void> refreshCustomers() async {
    if (_isRefreshing.value) return;

    _isRefreshing.value = true;
    _currentPage.value = 1;
    invalidateCache();

    try {
      await loadCustomers(showLoading: false, forceRefresh: true);
    } catch (e) {
      print('❌ Error durante el refresco: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Buscar clientes
  Future<void> searchCustomers(String query) async {
    if (query.trim().length < 2) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      print('🔍 Buscando clientes: "$query"');

      final result = await _searchCustomersUseCase(
        SearchCustomersParams(searchTerm: query.trim(), limit: 50),
      );

      result.fold(
        (failure) {
          _showError('Error en búsqueda', failure.message);
          _searchResults.clear();
        },
        (results) {
          _searchResults.value = results;
          print('✅ Búsqueda completada: ${results.length} resultados');
        },
      );
    } finally {
      _isSearching.value = false;
    }
  }

  /// Eliminar cliente
  Future<void> deleteCustomer(String customerId) async {
    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando cliente: $customerId');

      final result = await _deleteCustomerUseCase(
        DeleteCustomerParams(id: customerId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          _showSuccess('Cliente eliminado exitosamente');
          _customers.removeWhere((customer) => customer.id == customerId);
          _searchResults.removeWhere((customer) => customer.id == customerId);
          invalidateCache();
          refreshCustomers();
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  // ==================== FILTER & SORT METHODS ====================

  /// Aplicar filtro por estado
  void applyStatusFilter(CustomerStatus? status) {
    if (_currentStatus.value == status) return;

    _currentStatus.value = status;
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Aplicar filtro por tipo de documento
  void applyDocumentTypeFilter(DocumentType? documentType) {
    if (_currentDocumentType.value == documentType) return;

    _currentDocumentType.value = documentType;
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Aplicar filtro por ciudad
  void applyCityFilter(String city) {
    if (_selectedCity.value == city) return;

    _selectedCity.value = city;
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Aplicar filtro por estado/departamento
  void applyStateFilter(String state) {
    if (_selectedState.value == state) return;

    _selectedState.value = state;
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Cambiar ordenamiento
  void changeSorting(String sortBy, String sortOrder) {
    if (_sortBy.value == sortBy && _sortOrder.value == sortOrder) return;

    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Limpiar filtros
  void clearFilters() {
    _currentStatus.value = null;
    _currentDocumentType.value = null;
    _selectedCity.value = '';
    _selectedState.value = '';
    _searchTerm.value = '';
    searchController.clear();
    _searchResults.clear();
    _currentPage.value = 1;
    loadCustomers();
  }

  /// Actualizar búsqueda
  void updateSearch(String value) {
    _searchTerm.value = value;
    if (value.trim().isEmpty) {
      _searchResults.clear();
      loadCustomers();
    } else if (value.trim().length >= 2) {
      searchCustomers(value);
    }
  }

  // ==================== UI HELPERS ====================

  /// Ir a crear cliente
  void goToCreateCustomer() {
    Get.toNamed('/customers/create')?.then((result) {
      if (result != null) {
        // Cliente fue creado, recargar lista
        refreshCustomers();
      }
    });
  }

  /// Ir a editar cliente
  void goToEditCustomer(String customerId) {
    Get.toNamed('/customers/edit/$customerId')?.then((result) {
      if (result != null) {
        // Cliente fue actualizado, recargar lista
        refreshCustomers();
      }
    });
  }

  /// Mostrar detalles de cliente
  void showCustomerDetails(String customerId) {
    Get.toNamed('/customers/detail/$customerId')?.then((result) {
      if (result == 'deleted') {
        // Cliente fue eliminado, recargar lista
        refreshCustomers();
      }
    });
  }

  /// Ir a estadísticas de clientes
  void goToCustomerStats() {
    Get.toNamed('/customers/stats');
  }

  /// Confirmar eliminación
  void confirmDelete(Customer customer) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text(
          '¿Estás seguro que deseas eliminar el cliente "${customer.displayName}"?\n\n'
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
              deleteCustomer(customer.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ==================== BATCH OPERATIONS ====================

  /// Eliminar múltiples clientes
  Future<void> deleteMultipleCustomers(List<String> customerIds) async {
    if (customerIds.isEmpty) return;

    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando ${customerIds.length} clientes...');

      int deletedCount = 0;
      int errorCount = 0;

      for (String customerId in customerIds) {
        final result = await _deleteCustomerUseCase(
          DeleteCustomerParams(id: customerId),
        );

        result.fold(
          (failure) {
            errorCount++;
            print(
              '❌ Error al eliminar cliente $customerId: ${failure.message}',
            );
          },
          (_) {
            deletedCount++;
            // Remover de las listas locales
            _customers.removeWhere((customer) => customer.id == customerId);
            _searchResults.removeWhere((customer) => customer.id == customerId);
          },
        );
      }

      if (deletedCount > 0) {
        _showSuccess('$deletedCount cliente(s) eliminado(s) exitosamente');
      }

      if (errorCount > 0) {
        _showError(
          'Error',
          '$errorCount cliente(s) no pudieron ser eliminados',
        );
      }

      // Recargar para actualizar contadores
      refreshCustomers();
      print(
        '✅ Operación batch completada: $deletedCount eliminados, $errorCount errores',
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Actualizar estado de múltiples clientes
  Future<void> updateMultipleCustomerStatus(
    List<String> customerIds,
    CustomerStatus newStatus,
  ) async {
    if (customerIds.isEmpty) return;

    try {
      print(
        '🔄 Actualizando estado de ${customerIds.length} clientes a ${newStatus.name}...',
      );

      // TODO: Implementar usecase para actualización batch
      // Por ahora simulamos la operación
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess(
        '${customerIds.length} cliente(s) actualizados a ${_getStatusLabel(newStatus)}',
      );

      // Recargar lista
      refreshCustomers();
    } catch (e) {
      print('❌ Error en actualización batch: $e');
      _showError('Error', 'No se pudieron actualizar los clientes');
    }
  }

  // ==================== EXPORT METHODS ====================

  /// Exportar clientes a CSV
  Future<void> exportCustomersToCSV() async {
    try {
      print('📄 Exportando clientes a CSV...');

      // TODO: Implementar exportación real
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess('Clientes exportados a CSV exitosamente');
    } catch (e) {
      print('❌ Error al exportar a CSV: $e');
      _showError('Error', 'No se pudo exportar a CSV');
    }
  }

  /// Importar clientes desde CSV
  Future<void> importCustomersFromCSV() async {
    try {
      print('📥 Importando clientes desde CSV...');

      // TODO: Implementar importación real
      await Future.delayed(const Duration(seconds: 2));

      _showSuccess('Clientes importados exitosamente');
      refreshCustomers();
    } catch (e) {
      print('❌ Error al importar desde CSV: $e');
      _showError('Error', 'No se pudo importar el archivo');
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Configurar listener de búsqueda con debounce - IGUAL que credit notes
  void _setupSearchListener() {
    searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _searchTerm.value = searchController.text;
        _currentPage.value = 1;
        loadCustomers();
      });
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore.value && _hasNextPage.value) {
          loadMoreCustomers();
        }
      }
    });
  }

  /// Actualizar información de paginación
  void _updatePaginationInfo(PaginationMeta meta) {
    _currentPage.value = meta.page;
    _totalPages.value = meta.totalPages;
    _totalItems.value = meta.totalItems;
    _hasNextPage.value = meta.hasNextPage;
    _hasPreviousPage.value = meta.hasPreviousPage;
  }

  /// Obtener label del estado
  String _getStatusLabel(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
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

  // ==================== DEBUGGING METHODS ====================

  /// Obtener información de estado para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading.value,
      'isRefreshing': _isRefreshing.value,
      'customersCount': _customers.length,
      'currentPage': _currentPage.value,
      'totalItems': _totalItems.value,
      'searchTerm': _searchTerm.value,
      'currentStatus': _currentStatus.value?.name,
      'sortBy': _sortBy.value,
      'sortOrder': _sortOrder.value,
    };
  }

  /// Imprimir información de debugging
  void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 CustomersController Debug Info:');
    info.forEach((key, value) {
      print('   $key: $value');
    });
  }
}
