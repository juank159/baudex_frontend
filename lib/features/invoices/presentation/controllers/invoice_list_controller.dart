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
  final scrollController = ScrollController();

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

      try {
        scrollController.dispose();
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

          // ✅ FORZAR ACTUALIZACIÓN DE UI
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

          // Obtener el SettingsController para acceder a la impresora predeterminada
          try {
            final settingsController = Get.find<SettingsController>();
            final defaultPrinter = settingsController.defaultPrinter;
            
            if (defaultPrinter == null) {
              print('❌ No hay impresora predeterminada configurada');
              _showError(
                'Error de configuración', 
                'No hay impresora predeterminada configurada. Configura una en Configuración > Impresoras.'
              );
              return;
            }
            
            print('🖨️ Usando impresora predeterminada: ${defaultPrinter.name}');
            print('   - Tipo: ${defaultPrinter.connectionType}');
            print('   - IP: ${defaultPrinter.ipAddress}');
            print('   - Puerto: ${defaultPrinter.port}');
            
            // Obtener el ThermalPrinterController
            final thermalController = Get.find<ThermalPrinterController>();
            
            // Configurar temporalmente la impresora predeterminada
            await thermalController.setTempPrinterConfig(defaultPrinter);
            
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
            print('❌ Error accediendo a SettingsController: $e');
            _showError(
              'Error de configuración',
              'No se pudo acceder a la configuración de impresoras. Verifica que el sistema esté correctamente configurado.'
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
    await refreshInvoices();
    _loadInvoiceStatsIfAvailable();
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
