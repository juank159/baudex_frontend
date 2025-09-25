// lib/features/invoices/presentation/controllers/invoice_list_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/search_invoices_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';
import '../../domain/usecases/confirm_invoice_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/thermal_printer_controller.dart';
import '../controllers/invoice_stats_controller.dart';

class InvoiceListController extends GetxController {
  // Dependencies
  final GetInvoicesUseCase _getInvoicesUseCase;
  final SearchInvoicesUseCase _searchInvoicesUseCase;
  final DeleteInvoiceUseCase _deleteInvoiceUseCase;
  final ConfirmInvoiceUseCase _confirmInvoiceUseCase;
  final CancelInvoiceUseCase _cancelInvoiceUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;

  InvoiceListController({
    required GetInvoicesUseCase getInvoicesUseCase,
    required SearchInvoicesUseCase searchInvoicesUseCase,
    required DeleteInvoiceUseCase deleteInvoiceUseCase,
    required ConfirmInvoiceUseCase confirmInvoiceUseCase,
    required CancelInvoiceUseCase cancelInvoiceUseCase,
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
  }) : _getInvoicesUseCase = getInvoicesUseCase,
       _searchInvoicesUseCase = searchInvoicesUseCase,
       _deleteInvoiceUseCase = deleteInvoiceUseCase,
       _confirmInvoiceUseCase = confirmInvoiceUseCase,
       _cancelInvoiceUseCase = cancelInvoiceUseCase,
       _getInvoiceByIdUseCase = getInvoiceByIdUseCase {
    print('🎮 InvoiceListController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isRefreshing = false.obs;
  final _isPrinting = false.obs;

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

  // Controllers - USANDO SAFE CONTROLLERS PARA PREVENIR ERRORES DISPOSED
  final searchController = SafeTextEditingController(
    debugLabel: 'InvoiceListSearch',
  );
  
  // ✅ SOLUCIÓN RADICAL: ScrollController se creará dinámicamente
  ScrollController? _scrollController;

  // ✅ NUEVO: Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isPrinting => _isPrinting.value;

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

  // ✅ PAGINACIÓN PROFESIONAL: Getters mejorados con validaciones
  bool get hasNextPage {
    final meta = _paginationMeta.value;
    if (meta == null) return false;
    
    // ✅ Doble verificación: hasNextPage Y currentPage < totalPages
    return meta.hasNextPage && meta.page < meta.totalPages;
  }
  
  bool get hasPreviousPage => _paginationMeta.value?.hasPreviousPage ?? false;
  int get currentPage => _paginationMeta.value?.page ?? 1;
  int get totalPages => _paginationMeta.value?.totalPages ?? 1;
  int get totalItems => _paginationMeta.value?.totalItems ?? 0;
  
  // ✅ NUEVOS: Getters de utilidad para paginación
  String get paginationInfo => 'Página $currentPage de $totalPages ($totalItems facturas)';
  double get loadingProgress => totalPages > 0 ? currentPage / totalPages : 0.0;
  bool get isLastPage => currentPage >= totalPages;
  bool get canLoadMore => hasNextPage && !_isLoadingMore.value && !_isLoading.value;

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

    // ✅ CREAR ScrollController ÚNICO y FRESCO
    _createFreshScrollController();
    _setupScrollListener();
    _setupSearchListener();
    loadInvoices();
    _loadInvoiceStatsIfAvailable();
  }

  @override
  void onReady() {
    super.onReady();
    print(
      '✅ InvoiceListController: Ready state - controlador completamente inicializado',
    );

    // Verificar si necesitamos refrescar datos después de navegar
    if (_invoices.isEmpty) {
      print('📋 Lista vacía en onReady, cargando facturas...');
      loadInvoices();
    }
  }

  @override
  void onClose() {
    print('🔚 InvoiceListController: Liberando recursos...');

    try {
      // ✅ CRÍTICO: Cancelar timer de debounce antes de liberar recursos
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = null;

      // ✅ CRÍTICO: Remover listeners de forma segura usando SafeController
      if (searchController.canSafelyAccess()) {
        try {
          searchController.removeListener(_onSearchChanged);
          print('✅ Search listener removido exitosamente');
        } catch (e) {
          print('⚠️ Error removiendo search listener: $e');
        }
      }

      // ✅ DISPOSE SEGURO de controllers
      try {
        searchController
            .dispose(); // SafeController maneja dispose de forma segura
        print('✅ SafeSearchController disposed exitosamente');
      } catch (e) {
        print('⚠️ Error al liberar searchController: $e');
      }

      // ✅ SOLUCIÓN RADICAL: Disposal ultra-seguro
      try {
        if (_scrollListener != null && _scrollController?.hasClients == true) {
          _scrollController!.removeListener(_scrollListener!);
          _scrollListener = null;
          print('✅ ScrollController listener removido exitosamente');
        }
      } catch (e) {
        print('⚠️ Error removiendo scroll listener: $e');
      }

      // ✅ DISPOSE SEGURO del ScrollController dinámico
      try {
        _scrollController?.dispose();
        _scrollController = null;
        print('✅ ScrollController disposed exitosamente');
      } catch (e) {
        print('⚠️ Error al liberar scrollController: $e');
      }

      print('✅ InvoiceListController: Recursos marcados para liberación');
    } catch (e) {
      print('❌ Error durante onClose: $e');
    }

    super.onClose();
  }

  // ==================== CORE METHODS ====================

  /// ✅ PAGINACIÓN PROFESIONAL: Cargar facturas con manejo de errores mejorado
  Future<void> loadInvoices({bool showLoading = true}) async {
    try {
      if (showLoading) _isLoading.value = true;

      print('📋 CARGA INICIAL: Cargando primera página de facturas...');

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: 1, // ✅ Siempre empezar desde la página 1
          limit: 20, // ✅ Límite estándar
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _getServerFilterStatus(),
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
          
          // ✅ Limpiar datos en caso de error
          _invoices.clear();
          _filteredInvoices.clear();
          _paginationMeta.value = null;
        },
        (paginatedResult) {
          print('✅ CARGA INICIAL EXITOSA:');
          print('   - Facturas recibidas: ${paginatedResult.data.length}');
          print('   - Página actual: ${paginatedResult.meta.page}');
          print('   - Total páginas: ${paginatedResult.meta.totalPages}');
          print('   - Total facturas: ${paginatedResult.meta.totalItems}');
          print('   - Tiene siguiente: ${paginatedResult.meta.hasNextPage}');

          // ✅ Asignar datos iniciales
          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;

          // ✅ Aplicar filtros locales
          _applyLocalFilters();

          print('✅ FILTRADO COMPLETADO:');
          print('   - Facturas sin filtrar: ${_invoices.length}');
          print('   - Facturas filtradas: ${_filteredInvoices.length}');

          // ✅ FORZAR ACTUALIZACIÓN DE UI
          update();
        },
      );
    } catch (e, stackTrace) {
      print('💥 Error inesperado al cargar facturas: $e');
      print('📍 Stack trace: $stackTrace');
      _showError('Error inesperado', 'No se pudieron cargar las facturas: ${e.toString()}');
      
      // ✅ Limpiar datos en caso de error crítico
      _invoices.clear();
      _filteredInvoices.clear();
      _paginationMeta.value = null;
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
          status: _getServerFilterStatus(),
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
          // ✅ DEBUGGING: Estado antes de agregar
          print('🔍 ANTES DE AGREGAR:');
          print('   - Facturas actuales: ${_invoices.length}');
          print('   - Facturas filtradas: ${_filteredInvoices.length}');
          print('   - Nuevas facturas recibidas: ${paginatedResult.data.length}');
          
          // ✅ Evitar duplicados verificando IDs existentes
          final existingIds = _invoices.map((inv) => inv.id).toSet();
          final newInvoices = paginatedResult.data.where((inv) => !existingIds.contains(inv.id)).toList();
          
          print('🔍 FILTRADO DE DUPLICADOS:');
          print('   - Facturas realmente nuevas: ${newInvoices.length}');
          
          if (newInvoices.isEmpty) {
            print('⚠️ Todas las facturas ya existían (duplicados)');
            _showError('Datos duplicados', 'Los datos de esta página ya fueron cargados');
            return;
          }
          
          // ✅ Agregar solo facturas nuevas
          _invoices.addAll(newInvoices);
          _paginationMeta.value = paginatedResult.meta;
          _applyLocalFilters();
          
          print('✅ DESPUÉS DE AGREGAR:');
          print('   - Total facturas: ${_invoices.length}');
          print('   - Total filtradas: ${_filteredInvoices.length}');
          print('   - Página actual: ${paginatedResult.meta.page}');
          print('   - Tiene más páginas: ${paginatedResult.meta.hasNextPage}');
          
          // ✅ Forzar actualización de UI
          update();
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

  /// Obtener el estado a enviar al servidor
  /// Para "pending" no enviamos filtro al servidor, lo manejamos localmente
  InvoiceStatus? _getServerFilterStatus() {
    if (_selectedStatus.value == InvoiceStatus.pending) {
      // No filtrar en el servidor para poder obtener tanto pending como partiallyPaid
      return null;
    }
    return _selectedStatus.value;
  }

  /// Aplicar filtro de estado
  void filterByStatus(InvoiceStatus? status) {
    _selectedStatus.value = status;
    print('🔧 Filtro estado: ${status?.displayName ?? "Todos"}');

    // Si se selecciona "pending", incluir también "partiallyPaid"
    if (status == InvoiceStatus.pending) {
      print('🔧 Filtro extendido: Incluyendo facturas parcialmente pagadas');
    }

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

      // ✅ CRÍTICO: Usar SafeController para limpiar de forma segura
      if (searchController.canSafelyAccess()) {
        searchController.safeClear();
      } else {
        print(
          '⚠️ InvoiceListController: SearchController no seguro, recreando...',
        );
        _recreateSafeSearchController();
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
    Get.toNamed('/invoices/tabs');
  }

  /// Navegar a editar factura
  void goToEditInvoice(String invoiceId) {
    Get.toNamed('/invoices/edit/$invoiceId');
  }

  /// Navegar a detalles de factura
  void goToInvoiceDetail(String invoiceId) {
    try {
      print('🚀 Navegando a detalle de factura: $invoiceId');
      print('🔍 Ruta actual antes de navegación: ${Get.currentRoute}');

      // ✅ VERIFICACIÓN: Asegurarse de que la navegación es segura
      if (invoiceId.isEmpty) {
        _showError('Error', 'ID de factura no válido');
        return;
      }

      // ✅ NAVEGACIÓN SEGURA: Usar Future para evitar conflictos
      Future.microtask(() {
        try {
          Get.toNamed('/invoices/detail/$invoiceId');
          print('✅ Navegación iniciada exitosamente');
        } catch (navError) {
          print('❌ Error en navegación microtask: $navError');
          _showError('Error de navegación', 'No se pudo abrir el detalle');
        }
      });
    } catch (e) {
      print('❌ Error navegando a detalle: $e');
      _showError(
        'Error de navegación',
        'No se pudo abrir el detalle de la factura',
      );
    }
  }

  /// Imprimir factura directamente usando la impresora predeterminada
  Future<void> printInvoice(String invoiceId) async {
    try {
      _isPrinting.value = true;
      print('🖨️ === INICIANDO IMPRESIÓN DESDE LISTADO ===');
      print('   - Invoice ID: $invoiceId');

      // Obtener la factura completa
      final result = await _getInvoiceByIdUseCase(
        GetInvoiceByIdParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          print('❌ Error al obtener factura: ${failure.message}');
          _showError('Error', 'No se pudo cargar la factura para imprimir');
        },
        (invoice) async {
          print('✅ Factura obtenida: ${invoice.number}');
          print('   - Cliente: ${invoice.customerName}');
          print('   - Total: \$${invoice.total.toStringAsFixed(2)}');

          // ✅ NUEVO ENFOQUE: Usar ThermalPrinterController mejorado
          try {
            // Obtener el ThermalPrinterController
            final thermalController = Get.find<ThermalPrinterController>();
            
            // ✅ CLAVE: Asegurar que la configuración de impresora esté cargada
            print('🔄 Verificando configuración de impresora antes de imprimir...');
            final printerConfigLoaded = await thermalController.ensurePrinterConfigLoaded();
            
            if (!printerConfigLoaded) {
              print('❌ No se pudo cargar configuración de impresora');
              _showError(
                'Error de configuración', 
                'No hay impresora configurada. Configura una en Configuración > Impresoras.'
              );
              return;
            }
            
            print('✅ Configuración de impresora verificada exitosamente');
            
            // Imprimir la factura
            final success = await thermalController.printInvoice(invoice);

            if (success) {
              print('✅ Impresión exitosa desde listado');
              _showSuccess('Factura ${invoice.number} impresa exitosamente');
            } else {
              print('❌ Error en impresión desde listado');
              final error = thermalController.lastError ?? "Error desconocido";
              _showError(
                'Error de impresión',
                'No se pudo imprimir la factura: $error',
              );
            }
            
          } catch (e) {
            print('❌ Error en el proceso de impresión: $e');
            _showError(
              'Error de impresión',
              'No se pudo completar la impresión. Verifica la configuración de la impresora.'
            );
          }
        },
      );
    } catch (e) {
      print('💥 Error inesperado al imprimir: $e');
      _showError('Error inesperado', 'No se pudo imprimir la factura');
    } finally {
      _isPrinting.value = false;
    }
  }

  /// Navegar a imprimir factura
  void goToPrintInvoice(String invoiceId) {
    Get.toNamed('/invoices/print/$invoiceId');
  }

  // ==================== HELPER METHODS ====================

  // Variable para guardar la referencia del listener
  VoidCallback? _scrollListener;

  /// ✅ SOLUCIÓN RADICAL: Scroll listener con validación exhaustiva
  void _setupScrollListener() {
    if (_isControllerSafe()) {
      try {
        // ✅ SOLUCIÓN: Remover listener existente antes de agregar nuevo
        if (_scrollListener != null && _scrollController != null) {
          try {
            _scrollController!.removeListener(_scrollListener!);
            print('🧹 Listener anterior removido');
          } catch (e) {
            print('⚠️ Error removiendo listener anterior: $e');
          }
        }
        
        // ✅ Throttling para evitar múltiples llamadas
        DateTime? lastScrollCall;
        const scrollThrottleMs = 150; // Límite de llamadas cada 150ms
        
        // Crear el listener como una función separada para poder removerla después
        _scrollListener = () {
          try {
            final now = DateTime.now();
            if (lastScrollCall != null && 
                now.difference(lastScrollCall!).inMilliseconds < scrollThrottleMs) {
              return; // Ignorar si es muy pronto desde la última llamada
            }
            lastScrollCall = now;
            
            // ✅ OBTENER CONTROLADOR DINÁMICO
            final controller = _scrollController;
            if (controller == null) {
              print('⚠️ ScrollController es null, saltando scroll event');
              return;
            }
            
            // ✅ VALIDAR ESTADO DEL CONTROLADOR ANTES DE USAR
            if (!controller.hasClients) {
              print('⚠️ ScrollController no tiene clients, saltando scroll event');
              return;
            }
            
            // ✅ VALIDAR QUE SOLO HAY UNA POSICIÓN ACTIVA
            if (controller.positions.length != 1) {
              print('❌ CONFLICTO: ScrollController tiene ${controller.positions.length} posiciones');
              print('🔧 Removiendo listener para evitar conflictos');
              controller.removeListener(_scrollListener!);
              _scrollListener = null;
              return;
            }
            
            final position = controller.position;
            final threshold = position.maxScrollExtent - 300; // ✅ Umbral más grande para mejor UX
            
            // ✅ Verificaciones múltiples antes de activar paginación
            if (position.pixels >= threshold && 
                hasNextPage && 
                !_isLoadingMore.value && 
                !_isLoading.value) {
              
              print('📜 SCROLL TRIGGER: Activando paginación');
              print('   - Posición actual: ${position.pixels.round()}');
              print('   - Umbral: ${threshold.round()}');
              print('   - Página actual: $currentPage/$totalPages');
              
              loadMoreInvoices();
            }
          } catch (e) {
            print('❌ Error en scroll listener: $e');
            // Remover listener problemático
            try {
              _scrollController?.removeListener(_scrollListener!);
              _scrollListener = null;
            } catch (removeError) {
              print('❌ Error removiendo listener problemático: $removeError');
            }
          }
        };
        
        // ✅ USAR EL SCROLL CONTROLLER DINÁMICO
        final controller = mainScrollController;
        
        // ✅ VALIDAR ANTES DE AGREGAR LISTENER
        if (controller.positions.length > 1) {
          print('❌ No se puede agregar listener: ScrollController ya tiene ${controller.positions.length} posiciones');
          return;
        }
        
        // ✅ AGREGAR LISTENER CON VALIDACIÓN
        controller.addListener(_scrollListener!);
        print('✅ PAGINACIÓN: Scroll listener configurado con validación exhaustiva');
        
      } catch (e) {
        print('❌ Error configurando scroll listener: $e');
        _scrollListener = null;
      }
    } else {
      print('⚠️ Controller no es seguro, saltando configuración de scroll listener');
    }
  }
  
  /// ✅ SOLUCIÓN RADICAL: Crear ScrollController fresco cada vez
  void _createFreshScrollController() {
    try {
      // ✅ Limpiar controlador anterior si existe
      if (_scrollController != null) {
        if (_scrollListener != null && _scrollController!.hasClients) {
          _scrollController!.removeListener(_scrollListener!);
        }
        _scrollController!.dispose();
        print('🧹 ScrollController anterior limpiado');
      }
      
      // ✅ Crear nuevo ScrollController fresco
      _scrollController = ScrollController();
      print('🆕 Nuevo ScrollController creado');
      
    } catch (e) {
      print('❌ Error creando ScrollController fresco: $e');
      _scrollController = ScrollController(); // Fallback
    }
  }
  
  /// ✅ GETTER SEGURO para el ScrollController
  ScrollController get mainScrollController {
    if (_scrollController == null) {
      print('⚠️ ScrollController es null, creando uno nuevo');
      _createFreshScrollController();
    }
    return _scrollController!;
  }
  
  // ==================== MÉTODOS DE PAGINACIÓN MANUAL ====================
  
  /// ✅ PAGINACIÓN PROFESIONAL: Ir a una página específica
  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages) {
      _showError('Página inválida', 'La página debe estar entre 1 y $totalPages');
      return;
    }
    
    if (pageNumber == currentPage) {
      print('⚠️ Ya estamos en la página $pageNumber');
      return;
    }
    
    try {
      _isLoading.value = true;
      print('📄 Navegando a página $pageNumber...');
      
      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: pageNumber,
          limit: 20,
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _getServerFilterStatus(),
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
          print('❌ Error al ir a página $pageNumber: ${failure.message}');
          _showError('Error de navegación', failure.message);
        },
        (paginatedResult) {
          // ✅ Reemplazar datos completamente para navegación directa
          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;
          _applyLocalFilters();
          
          print('✅ Navegación exitosa a página $pageNumber');
          print('   - Facturas cargadas: ${paginatedResult.data.length}');
          
          // ✅ Scroll al inicio de la lista
          final controller = mainScrollController;
          if (controller.hasClients) {
            controller.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
          
          update();
        },
      );
    } catch (e) {
      print('💥 Error inesperado navegando a página: $e');
      _showError('Error inesperado', 'No se pudo navegar a la página $pageNumber');
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// ✅ Ir a la primera página
  Future<void> goToFirstPage() async {
    await goToPage(1);
  }
  
  /// ✅ Ir a la última página
  Future<void> goToLastPage() async {
    await goToPage(totalPages);
  }
  
  /// ✅ Ir a la página siguiente
  Future<void> goToNextPage() async {
    if (hasNextPage) {
      await goToPage(currentPage + 1);
    }
  }
  
  /// ✅ Ir a la página anterior
  Future<void> goToPreviousPage() async {
    if (hasPreviousPage) {
      await goToPage(currentPage - 1);
    }
  }
  
  /// ✅ RESETEAR PAGINACIÓN: Volver al estado inicial
  Future<void> resetPagination() async {
    print('🔄 Reseteando paginación a estado inicial...');
    _invoices.clear();
    _filteredInvoices.clear();
    _paginationMeta.value = null;
    await loadInvoices();
  }

  /// ✅ MÉTODO ULTRA-SEGURO: Manejo de cambios de búsqueda con SafeController
  void _onSearchChanged() {
    // Verificación: Estado del SafeController
    if (!searchController.canSafelyAccess()) {
      print(
        '⚠️ InvoiceListController: SafeSearchController no accesible, cancelando búsqueda',
      );
      _searchDebounceTimer?.cancel();
      return;
    }

    // Verificación de estado del GetxController
    if (!isClosed) {
      try {
        final query = searchController.safeText(); // Uso de método seguro
        if (query != _searchQuery.value) {
          // Cancelar timer anterior si existe
          _searchDebounceTimer?.cancel();

          // Crear nuevo timer con debounce de 500ms
          _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
            // Triple verificación antes de ejecutar búsqueda
            if (!isClosed && searchController.canSafelyAccess()) {
              final currentQuery = searchController.safeText();
              if (currentQuery == query) {
                searchInvoices(query);
              }
            } else {
              print(
                '⚠️ Controlador cerrado o unsafe durante timer de búsqueda',
              );
            }
          });
        }
      } catch (e) {
        print('⚠️ Error en _onSearchChanged: $e');
        // Si hay error, cancelar timer para evitar futuros problemas
        _searchDebounceTimer?.cancel();
        _searchDebounceTimer = null;
      }
    } else {
      print('⚠️ GetxController cerrado, ignorando cambio de búsqueda');
      _searchDebounceTimer?.cancel();
    }
  }

  /// Configurar listener de búsqueda con SafeController
  void _setupSearchListener() {
    if (searchController.canSafelyAccess()) {
      try {
        searchController.addListener(_onSearchChanged);
        print('✅ InvoiceListController: Search listener agregado exitosamente');
      } catch (e) {
        print('❌ Error configurando search listener: $e');
        _recreateSafeSearchController();
      }
    } else {
      print(
        '⚠️ SearchController no seguro en _setupSearchListener, recreando...',
      );
      _recreateSafeSearchController();
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
          // Filtro especial: Si se selecciona "pending", incluir también "partiallyPaid"
          if (_selectedStatus.value == InvoiceStatus.pending) {
            return invoice.status == InvoiceStatus.pending ||
                invoice.status == InvoiceStatus.partiallyPaid;
          }

          // Para otros estados, aplicar filtro normal
          if (_selectedStatus.value != null) {
            return invoice.status == _selectedStatus.value;
          }

          // Sin filtro de estado, mostrar todo
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
        print(
          '📊 InvoiceListController: Cargando estadísticas automáticamente',
        );

        // Cargar estadísticas en el siguiente frame para evitar conflictos
        Future.microtask(() {
          statsController.refreshAllData();
        });
      } else {
        print(
          '⚠️ InvoiceListController: Controlador de estadísticas no encontrado',
        );
      }
    } catch (e) {
      print('💥 Error al cargar estadísticas automáticamente: $e');
      // No mostrar error al usuario ya que es una funcionalidad secundaria
    }
  }

  /// Refrescar datos incluyendo estadísticas
  Future<void> refreshAllData() async {
    // ✅ RECREAR ScrollController para evitar conflictos
    _createFreshScrollController();
    _setupScrollListener();
    
    await refreshInvoices();
    _loadInvoiceStatsIfAvailable();
  }
  
  /// ✅ MÉTODO PÚBLICO: Recrear ScrollController si hay problemas
  void recreateScrollController() {
    print('🔄 Recreando ScrollController por solicitud externa');
    _createFreshScrollController();
    _setupScrollListener();
  }

  /// ✅ MÉTODO SIMPLIFICADO: Verificar estado usando SafeController
  bool _isControllerSafe() {
    return searchController.canSafelyAccess();
  }

  /// ✅ NUEVO: Recrear SafeSearchController de forma segura
  void _recreateSafeSearchController() {
    try {
      print('🔧 InvoiceListController: Recreando SafeSearchController...');

      // Cancelar cualquier timer pendiente
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = null;

      // Como searchController es final, necesitamos reinicializar internamente
      // El SafeController ya maneja esto de forma segura
      if (searchController.canSafelyAccess()) {
        searchController.removeListener(_onSearchChanged);
      }

      // Volver a configurar el listener
      _setupSearchListener();

      print('✅ SafeSearchController recreado exitosamente');
    } catch (e) {
      print('❌ Error recreando SafeSearchController: $e');
    }
  }
}
