// lib/features/invoices/presentation/controllers/invoice_list_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/search_invoices_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';
import '../../domain/usecases/confirm_invoice_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../controllers/invoice_stats_controller.dart';

class InvoiceListController extends GetxController {
  // Dependencies
  final GetInvoicesUseCase _getInvoicesUseCase;
  final SearchInvoicesUseCase _searchInvoicesUseCase;
  final DeleteInvoiceUseCase _deleteInvoiceUseCase;
  final ConfirmInvoiceUseCase _confirmInvoiceUseCase;
  final CancelInvoiceUseCase _cancelInvoiceUseCase;

  InvoiceListController({
    required GetInvoicesUseCase getInvoicesUseCase,
    required SearchInvoicesUseCase searchInvoicesUseCase,
    required DeleteInvoiceUseCase deleteInvoiceUseCase,
    required ConfirmInvoiceUseCase confirmInvoiceUseCase,
    required CancelInvoiceUseCase cancelInvoiceUseCase,
  }) : _getInvoicesUseCase = getInvoicesUseCase,
       _searchInvoicesUseCase = searchInvoicesUseCase,
       _deleteInvoiceUseCase = deleteInvoiceUseCase,
       _confirmInvoiceUseCase = confirmInvoiceUseCase,
       _cancelInvoiceUseCase = cancelInvoiceUseCase {
    print('🎮 InvoiceListController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final _invoices = <Invoice>[].obs;
  final _filteredInvoices = <Invoice>[].obs;
  final _paginationMeta = Rxn<PaginationMeta>();

  // Filtros y búsqueda
  final _searchQuery = ''.obs;
  final _selectedStatus = Rxn<InvoiceStatus>();
  final _selectedPaymentMethod = Rxn<PaymentMethod>();
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();
  final _minAmount = Rxn<double>();
  final _maxAmount = Rxn<double>();
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;

  // UI
  final _selectedInvoices = <String>[].obs;
  final _isMultiSelectMode = false.obs;

  // Controllers
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  
  // ✅ NUEVO: Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isRefreshing => _isRefreshing.value;

  List<Invoice> get invoices => _invoices;
  List<Invoice> get filteredInvoices => _filteredInvoices;
  PaginationMeta? get paginationMeta => _paginationMeta.value;

  String get searchQuery => _searchQuery.value;
  InvoiceStatus? get selectedStatus => _selectedStatus.value;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;
  double? get minAmount => _minAmount.value;
  double? get maxAmount => _maxAmount.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;

  List<String> get selectedInvoices => _selectedInvoices;
  bool get isMultiSelectMode => _isMultiSelectMode.value;
  bool get hasSelection => _selectedInvoices.isNotEmpty;

  bool get hasNextPage => _paginationMeta.value?.hasNextPage ?? false;
  bool get hasPreviousPage => _paginationMeta.value?.hasPreviousPage ?? false;
  int get currentPage => _paginationMeta.value?.page ?? 1;
  int get totalPages => _paginationMeta.value?.totalPages ?? 1;
  int get totalItems => _paginationMeta.value?.totalItems ?? 0;

  bool get hasFilters =>
      _selectedStatus.value != null ||
      _selectedPaymentMethod.value != null ||
      _startDate.value != null ||
      _endDate.value != null ||
      _minAmount.value != null ||
      _maxAmount.value != null;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 InvoiceListController: Inicializando...');

    _setupScrollListener();
    _setupSearchListener();
    loadInvoices();
    _loadInvoiceStatsIfAvailable();
  }

  @override
  void onClose() {
    print('🔚 InvoiceListController: Liberando recursos...');
    
    try {
      // ✅ CRÍTICO: Cancelar timer de debounce antes de liberar recursos
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = null;
      
      // ✅ CRÍTICO: Remover listeners antes de dispose para evitar errores
      // Solo remover si el controlador aún está activo
      if (_isControllerSafe()) {
        searchController.removeListener(_onSearchChanged);
      }
      
      // Liberar controladores de forma segura
      try {
        searchController.dispose();
      } catch (e) {
        print('⚠️ Error al liberar searchController: $e');
      }
      
      try {
        scrollController.dispose();
      } catch (e) {
        print('⚠️ Error al liberar scrollController: $e');
      }
      
      print('✅ InvoiceListController: Recursos liberados exitosamente');
    } catch (e) {
      print('❌ Error durante onClose: $e');
    }
    
    super.onClose();
  }

  // ==================== CORE METHODS ====================

  /// Cargar facturas
  Future<void> loadInvoices({bool showLoading = true}) async {
    try {
      if (showLoading) _isLoading.value = true;

      print('📋 InvoiceListController: Cargando facturas...');

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: 1,
          limit: 20,
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _selectedStatus.value,
          paymentMethod: _selectedPaymentMethod.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          minAmount: _minAmount.value,
          maxAmount: _maxAmount.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar facturas: ${failure.message}');
          _showError('Error al cargar facturas', failure.message);
        },
        (paginatedResult) {
          print('🔍 DEBUG: === RESULTADO DEL REPOSITORIO ===');
          print('🔍 DEBUG: Facturas recibidas: ${paginatedResult.data.length}');
          print('🔍 DEBUG: Meta: ${paginatedResult.meta}');
          print(
            '🔍 DEBUG: Primera factura (si existe): ${paginatedResult.data.isNotEmpty ? paginatedResult.data.first.number : 'N/A'}',
          );

          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;

          print(
            '🔍 DEBUG: _invoices.length después de asignar: ${_invoices.length}',
          );

          _applyLocalFilters();

          print(
            '🔍 DEBUG: _filteredInvoices.length después de filtrar: ${_filteredInvoices.length}',
          );
          print('🔍 DEBUG: === FIN DEBUG ===');
          print('✅ ${paginatedResult.data.length} facturas cargadas');
        },
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar facturas: ${failure.message}');
          _showError('Error al cargar facturas', failure.message);
        },
        (paginatedResult) {
          print('🔍 DEBUG: === RESULTADO DEL REPOSITORIO ===');
          print('🔍 DEBUG: Facturas recibidas: ${paginatedResult.data.length}');
          print('🔍 DEBUG: Meta: ${paginatedResult.meta}');
          print(
            '🔍 DEBUG: Primera factura (si existe): ${paginatedResult.data.isNotEmpty ? paginatedResult.data.first.number : 'N/A'}',
          );

          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;

          print(
            '🔍 DEBUG: _invoices.length después de asignar: ${_invoices.length}',
          );

          _applyLocalFilters();

          print(
            '🔍 DEBUG: _filteredInvoices.length después de filtrar: ${_filteredInvoices.length}',
          );
          print('🔍 DEBUG: === FIN DEBUG ===');
          print('✅ ${paginatedResult.data.length} facturas cargadas');

          // ✅ AGREGAR ESTA LÍNEA PARA FORZAR ACTUALIZACIÓN DE UI
          update();
        },
      );
    } catch (e) {
      print('💥 Error inesperado al cargar facturas: $e');
      _showError('Error inesperado', 'No se pudieron cargar las facturas');
    } finally {
      if (showLoading) _isLoading.value = false;
    }
  }

  /// Cargar más facturas (paginación)
  Future<void> loadMoreInvoices() async {
    if (_isLoadingMore.value || !hasNextPage) return;

    try {
      _isLoadingMore.value = true;
      print('📋 InvoiceListController: Cargando más facturas...');

      final nextPage = currentPage + 1;

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: nextPage,
          limit: 20,
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _selectedStatus.value,
          paymentMethod: _selectedPaymentMethod.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          minAmount: _minAmount.value,
          maxAmount: _maxAmount.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar más facturas: ${failure.message}');
          _showError('Error al cargar más facturas', failure.message);
        },
        (paginatedResult) {
          _invoices.addAll(paginatedResult.data);
          _paginationMeta.value = paginatedResult.meta;
          _applyLocalFilters();
          print(
            '✅ ${paginatedResult.data.length} facturas adicionales cargadas',
          );
        },
      );
    } catch (e) {
      print('💥 Error inesperado al cargar más facturas: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar facturas
  Future<void> refreshInvoices() async {
    try {
      _isRefreshing.value = true;
      print('🔄 InvoiceListController: Refrescando facturas...');

      await loadInvoices(showLoading: false);
      _showSuccess('Facturas actualizadas');
    } catch (e) {
      print('💥 Error al refrescar facturas: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Buscar facturas
  Future<void> searchInvoices(String query) async {
    try {
      _isSearching.value = true;
      _searchQuery.value = query;

      print('🔍 InvoiceListController: Buscando facturas: "$query"');

      if (query.isEmpty) {
        await loadInvoices();
        return;
      }

      // Buscar en el servidor
      final result = await _searchInvoicesUseCase(
        SearchInvoicesParams(searchTerm: query),
      );

      result.fold(
        (failure) {
          print('❌ Error en búsqueda: ${failure.message}');
          _showError('Error en búsqueda', failure.message);
        },
        (searchResults) {
          _invoices.value = searchResults;
          _applyLocalFilters();
          print('✅ ${searchResults.length} facturas encontradas');
        },
      );
    } catch (e) {
      print('💥 Error inesperado en búsqueda: $e');
    } finally {
      _isSearching.value = false;
    }
  }

  // ==================== FILTER METHODS ====================

  /// Aplicar filtro de estado
  void filterByStatus(InvoiceStatus? status) {
    _selectedStatus.value = status;
    print('🔧 Filtro estado: ${status?.displayName ?? "Todos"}');
    loadInvoices();
  }

  /// Aplicar filtro de método de pago
  void filterByPaymentMethod(PaymentMethod? paymentMethod) {
    _selectedPaymentMethod.value = paymentMethod;
    print('🔧 Filtro método pago: ${paymentMethod?.displayName ?? "Todos"}');
    loadInvoices();
  }

  /// Aplicar filtro de fechas
  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate.value = start;
    _endDate.value = end;
    print('🔧 Filtro fechas: ${start?.toString()} - ${end?.toString()}');
    loadInvoices();
  }

  /// Aplicar filtro de montos
  void filterByAmountRange(double? min, double? max) {
    _minAmount.value = min;
    _maxAmount.value = max;
    print('🔧 Filtro montos: $min - $max');
    loadInvoices();
  }

  /// Cambiar ordenamiento
  void changeSort(String newSortBy, String newSortOrder) {
    _sortBy.value = newSortBy;
    _sortOrder.value = newSortOrder;
    print('🔧 Ordenamiento: $newSortBy $newSortOrder');
    loadInvoices();
  }

  /// Limpiar todos los filtros
  void clearFilters() {
    try {
      _selectedStatus.value = null;
      _selectedPaymentMethod.value = null;
      _startDate.value = null;
      _endDate.value = null;
      _minAmount.value = null;
      _maxAmount.value = null;
      _searchQuery.value = '';
      
      // ✅ CRÍTICO: Verificar que el controlador esté activo antes de limpiar
      if (_isControllerSafe()) {
        searchController.clear();
      } else {
        print('⚠️ InvoiceListController: No se puede limpiar searchController (disposed)');
      }

      print('🧹 InvoiceListController: Filtros limpiados');
      loadInvoices();
    } catch (e) {
      print('⚠️ Error al limpiar filtros: $e');
      // Al menos limpiar los filtros observables
      _selectedStatus.value = null;
      _selectedPaymentMethod.value = null;
      _startDate.value = null;
      _endDate.value = null;
      _minAmount.value = null;
      _maxAmount.value = null;
      _searchQuery.value = '';
    }
  }

  // ==================== INVOICE ACTIONS ====================

  /// Confirmar factura
  Future<void> confirmInvoice(String invoiceId) async {
    try {
      print('✅ Confirmando factura: $invoiceId');

      final result = await _confirmInvoiceUseCase(
        ConfirmInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al confirmar factura', failure.message);
        },
        (updatedInvoice) {
          _updateInvoiceInList(updatedInvoice);
          _showSuccess('Factura confirmada exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al confirmar factura: $e');
      _showError('Error inesperado', 'No se pudo confirmar la factura');
    }
  }

  /// Cancelar factura
  Future<void> cancelInvoice(String invoiceId) async {
    try {
      print('❌ Cancelando factura: $invoiceId');

      final result = await _cancelInvoiceUseCase(
        CancelInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al cancelar factura', failure.message);
        },
        (updatedInvoice) {
          _updateInvoiceInList(updatedInvoice);
          _showSuccess('Factura cancelada exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al cancelar factura: $e');
      _showError('Error inesperado', 'No se pudo cancelar la factura');
    }
  }

  /// Eliminar factura
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      print('🗑️ Eliminando factura: $invoiceId');

      final result = await _deleteInvoiceUseCase(
        DeleteInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar factura', failure.message);
        },
        (_) {
          _removeInvoiceFromList(invoiceId);
          _showSuccess('Factura eliminada exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al eliminar factura: $e');
      _showError('Error inesperado', 'No se pudo eliminar la factura');
    }
  }

  // ==================== SELECTION METHODS ====================

  /// Activar/desactivar modo selección múltiple
  void toggleMultiSelectMode() {
    _isMultiSelectMode.value = !_isMultiSelectMode.value;
    if (!_isMultiSelectMode.value) {
      _selectedInvoices.clear();
    }
    print('🔧 Modo selección múltiple: ${_isMultiSelectMode.value}');
  }

  /// Seleccionar/deseleccionar factura
  void toggleInvoiceSelection(String invoiceId) {
    if (_selectedInvoices.contains(invoiceId)) {
      _selectedInvoices.remove(invoiceId);
    } else {
      _selectedInvoices.add(invoiceId);
    }
    print('🎯 Facturas seleccionadas: ${_selectedInvoices.length}');
  }

  /// Seleccionar todas las facturas visibles
  void selectAllVisibleInvoices() {
    _selectedInvoices.value =
        _filteredInvoices.map((invoice) => invoice.id).toList();
    print('✅ Todas las facturas visibles seleccionadas');
  }

  /// Deseleccionar todas las facturas
  void clearSelection() {
    _selectedInvoices.clear();
    print('🧹 Selección limpiada');
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a crear factura
  void goToCreateInvoice() {
    Get.toNamed('/invoices/create');
  }

  /// Navegar a editar factura
  void goToEditInvoice(String invoiceId) {
    Get.toNamed('/invoices/edit/$invoiceId');
  }

  /// Navegar a detalles de factura
  void goToInvoiceDetail(String invoiceId) {
    Get.toNamed('/invoices/detail/$invoiceId');
  }

  /// Navegar a imprimir factura
  void goToPrintInvoice(String invoiceId) {
    Get.toNamed('/invoices/print/$invoiceId');
  }

  // ==================== HELPER METHODS ====================

  /// Configurar listener del scroll para paginación infinita
  void _setupScrollListener() {
    if (_isControllerSafe()) {
      try {
        scrollController.addListener(() {
          if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
            if (hasNextPage && !_isLoadingMore.value) {
              loadMoreInvoices();
            }
          }
        });
        print('✅ InvoiceListController: Scroll listener agregado exitosamente');
      } catch (e) {
        print('❌ Error configurando scroll listener: $e');
      }
    }
  }

  /// ✅ NUEVO: Método seguro para manejar cambios de búsqueda
  void _onSearchChanged() {
    // Verificar que el controlador no haya sido disposed
    if (!_isControllerSafe()) {
      print('⚠️ InvoiceListController: SearchController disposed, cancelando búsqueda');
      return;
    }
    
    try {
      final query = searchController.text;
      if (query != _searchQuery.value) {
        // Cancelar timer anterior si existe
        _searchDebounceTimer?.cancel();
        
        // Crear nuevo timer con debounce de 500ms
        _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          // Verificar de nuevo que el controlador siga activo
          if (_isControllerSafe() && searchController.text == query) {
            searchInvoices(query);
          }
        });
      }
    } catch (e) {
      print('⚠️ Error en _onSearchChanged: $e');
      // Si hay error, cancelar timer para evitar futuros problemas
      _searchDebounceTimer?.cancel();
    }
  }

  /// Configurar listener de búsqueda con debounce seguro
  void _setupSearchListener() {
    if (_isControllerSafe()) {
      try {
        searchController.addListener(_onSearchChanged);
        print('✅ InvoiceListController: Search listener agregado exitosamente');
      } catch (e) {
        print('❌ Error configurando search listener: $e');
      }
    }
  }

  // //Aplicar filtros locales a la lista de facturas
  // void _applyLocalFilters() {
  //   _filteredInvoices.value =
  //       _invoices.where((invoice) {
  //         // Aquí puedes aplicar filtros adicionales que no se manejan en el servidor
  //         return true;
  //       }).toList();
  // }

  void _applyLocalFilters() {
    print('🔍 DEBUG: _applyLocalFilters() - Iniciando filtrado');
    print('🔍 DEBUG: _invoices.length: ${_invoices.length}');

    _filteredInvoices.value =
        _invoices.where((invoice) {
          // Aquí puedes aplicar filtros adicionales que no se manejan en el servidor
          return true;
        }).toList();

    print(
      '🔍 DEBUG: _filteredInvoices.length después del filtrado: ${_filteredInvoices.length}',
    );
    print('🔍 DEBUG: _applyLocalFilters() - Filtrado completado');
  }

  /// Actualizar factura en la lista
  void _updateInvoiceInList(Invoice updatedInvoice) {
    final index = _invoices.indexWhere(
      (invoice) => invoice.id == updatedInvoice.id,
    );
    if (index != -1) {
      _invoices[index] = updatedInvoice;
      _applyLocalFilters();
    }
  }

  /// Remover factura de la lista
  void _removeInvoiceFromList(String invoiceId) {
    _invoices.removeWhere((invoice) => invoice.id == invoiceId);
    _selectedInvoices.remove(invoiceId);
    _applyLocalFilters();
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

  /// Cargar estadísticas de invoices si el controlador está disponible
  void _loadInvoiceStatsIfAvailable() {
    try {
      // Intentar encontrar el controlador de estadísticas
      if (Get.isRegistered<InvoiceStatsController>()) {
        final statsController = Get.find<InvoiceStatsController>();
        print('📊 InvoiceListController: Cargando estadísticas automáticamente');
        
        // Cargar estadísticas en el siguiente frame para evitar conflictos
        Future.microtask(() {
          statsController.refreshAllData();
        });
      } else {
        print('⚠️ InvoiceListController: Controlador de estadísticas no encontrado');
      }
    } catch (e) {
      print('💥 Error al cargar estadísticas automáticamente: $e');
      // No mostrar error al usuario ya que es una funcionalidad secundaria
    }
  }

  /// Refrescar datos incluyendo estadísticas
  Future<void> refreshAllData() async {
    await refreshInvoices();
    _loadInvoiceStatsIfAvailable();
  }
  
  /// ✅ CRÍTICO: Verificar que el controller esté disponible y no disposed
  bool _isControllerSafe() {
    try {
      // Intentar acceder a una propiedad del controller para verificar si está disposed
      searchController.text;
      // También verificar que el listener no haya sido removido
      return true;
    } catch (e) {
      // Si hay una excepción, el controller fue disposed
      print('⚠️ InvoiceListController: SearchController disposed detectado - $e');
      return false;
    }
  }
}
