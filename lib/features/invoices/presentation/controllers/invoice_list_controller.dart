// lib/features/invoices/presentation/controllers/invoice_list_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/search_invoices_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';
import '../../domain/usecases/confirm_invoice_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../controllers/thermal_printer_controller.dart';
import '../controllers/invoice_stats_controller.dart';

class InvoiceListController extends GetxController
    with SyncAutoRefreshMixin {
  // Dependencies
  final GetInvoicesUseCase _getInvoicesUseCase;
  final SearchInvoicesUseCase _searchInvoicesUseCase;
  final DeleteInvoiceUseCase _deleteInvoiceUseCase;
  final ConfirmInvoiceUseCase _confirmInvoiceUseCase;
  final CancelInvoiceUseCase _cancelInvoiceUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;

  // ==================== CACHÉ ESTÁTICO ====================
  // Caché estático para persistir datos entre recreaciones del controlador
  static List<Invoice>? _cachedInvoices;
  static PaginationMeta? _cachedMeta;
  static DateTime? _lastCacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  /// Verificar si el caché es válido
  static bool _isCacheValid() {
    if (_cachedInvoices == null || _lastCacheTime == null) return false;
    final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
    return timeSinceCache < _cacheValidityDuration;
  }

  /// Actualizar el caché con nuevos datos
  static void _updateCache(List<Invoice> invoices, PaginationMeta? meta) {
    _cachedInvoices = List.from(invoices);
    _cachedMeta = meta;
    _lastCacheTime = DateTime.now();
    // print('💾 Caché de facturas actualizado: ${invoices.length} items');
  }

  /// Invalidar el caché (llamar después de operaciones CRUD)
  static void invalidateCache() {
    _cachedInvoices = null;
    _cachedMeta = null;
    _lastCacheTime = null;
    _needsRefreshOnNextVisit = true;
  }

  /// Flag para forzar refresh en la próxima visita (después de CRUD)
  static bool _needsRefreshOnNextVisit = false;

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
    // print('🎮 InvoiceListController: Instancia creada correctamente');
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
  final _selectedBankAccountId = Rxn<String>(); // Filtro por ID de cuenta bancaria (legacy)
  final _selectedBankAccountName = Rxn<String>(); // ✅ NUEVO: Filtro por NOMBRE de método de pago (Nequi, Bancolombia, etc.)
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();
  final _minAmount = Rxn<double>();
  final _maxAmount = Rxn<double>();
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;

  // UI
  final _selectedInvoices = <String>[].obs;
  final _isMultiSelectMode = false.obs;

  // Controllers - TextEditingController normal (el controller es permanente)
  final searchController = TextEditingController();

  // ✅ NOTA IMPORTANTE: El ScrollController ahora es manejado por InvoiceListScreen (StatefulWidget)
  // Esto garantiza un lifecycle correcto y evita el error "attached to more than one ScrollPosition"
  // Las variables _scrollController y _scrollListener se mantienen solo por compatibilidad pero NO se usan
  @Deprecated('ScrollController ahora es manejado por InvoiceListScreen')
  ScrollController? _scrollController;

  // ✅ NUEVO: Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // ✅ AUTO-REFRESH: Timestamp del último refresh para control optimizado
  DateTime? _lastRefreshTime;

  // ✅ AUTO-REFRESH: Intervalo mínimo entre refreshes (30 segundos)
  static const _minRefreshInterval = Duration(seconds: 30);

  // ✅ GUARD: Prevenir llamadas concurrentes a loadInvoices
  bool _isLoadInProgress = false;

  // ✅ AUTO-REFRESH: Worker para monitorear cambios de ruta
  Worker? _routeWorker;

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
  String? get selectedBankAccountId => _selectedBankAccountId.value; // Getter para cuenta bancaria (legacy)
  String? get selectedBankAccountName => _selectedBankAccountName.value; // ✅ NUEVO: Getter para nombre de método de pago
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
  String get paginationInfo =>
      'Página $currentPage de $totalPages ($totalItems facturas)';
  double get loadingProgress => totalPages > 0 ? currentPage / totalPages : 0.0;
  bool get isLastPage => currentPage >= totalPages;
  bool get canLoadMore =>
      hasNextPage && !_isLoadingMore.value && !_isLoading.value;

  bool get hasFilters =>
      _selectedStatus.value != null ||
      _selectedPaymentMethod.value != null ||
      _selectedBankAccountId.value != null ||
      _selectedBankAccountName.value != null || // ✅ Incluir filtro de nombre de método de pago
      _startDate.value != null ||
      _endDate.value != null ||
      _minAmount.value != null ||
      _maxAmount.value != null;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();

    _setupSearchListener();
    loadInvoices();
    _loadInvoiceStatsIfAvailable();
  }

  @override
  Future<void> onSyncCompleted() async {
    invalidateCache();
    _isLoadInProgress = false;
    _refreshInBackground();
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ NO llamar loadInvoices() aquí - ya se llama en onInit()
    // Solo verificar si necesitamos refrescar datos (ej: volviendo de otra pantalla)
    // La carga duplicada desde onInit+onReady causaba múltiples requests concurrentes al servidor

    // ✅ AUTO-REFRESH: Configurar listener de navegación
    _setupRouteListener();
  }

  /// ✅ AUTO-REFRESH: Configurar listener para detectar cuando volvemos a esta pantalla
  void _setupRouteListener() {
    // Simplemente verificamos cada vez que se llama onReady
    // El auto-refresh real se maneja en checkAndRefreshIfNeeded() que se llama desde la UI
    // print('✅ Auto-refresh configurado. Se verificará en cada visita a la pantalla.');
  }

  /// ✅ AUTO-REFRESH: Método público para verificar y refrescar si es necesario
  /// Este método debe ser llamado cada vez que la pantalla se vuelve visible
  Future<void> checkAndRefreshIfNeeded() async {
    if (!isClosed) {
      _handleScreenResumed();
    }
  }

  /// ✅ AUTO-REFRESH: Manejar cuando el usuario regresa a esta pantalla
  void _handleScreenResumed() {
    // print('🔄 InvoiceListScreen: Pantalla reanudada, verificando necesidad de refresh...');

    // ✅ SINCRONIZACIÓN CON CRÉDITOS: Verificar si hay pagos de créditos que afectan facturas
    if (_checkCreditPaymentPending()) {
      // print('✅ Ejecutando refresh por pago de crédito con factura asociada...');
      refreshAllData();
      return;
    }

    // Verificar si ha pasado suficiente tiempo desde el último refresh
    if (_shouldAutoRefresh()) {
      // print('✅ Ejecutando auto-refresh de datos...');
      refreshAllData();
    } else {
      final secondsSinceLastRefresh =
          _lastRefreshTime != null
              ? DateTime.now().difference(_lastRefreshTime!).inSeconds
              : 0;
      // print('⏭️  Saltando refresh (último hace $secondsSinceLastRefresh segundos)');
    }
  }

  /// ✅ SINCRONIZACIÓN: Verificar si hay pagos de créditos pendientes que afectan facturas
  bool _checkCreditPaymentPending() {
    final hasPending = _hasPendingCreditPaymentRefresh;
    if (hasPending) {
      _clearPendingCreditRefresh();
    }
    return hasPending;
  }

  // ✅ Flag estático para comunicación entre controladores
  static bool _hasPendingCreditPaymentRefresh = false;

  /// ✅ Método estático para que otros controladores marquen refresh pendiente
  static void markInvoiceRefreshNeeded() {
    _hasPendingCreditPaymentRefresh = true;
    // print('📌 InvoiceListController: Marcado refresh pendiente por pago de crédito');
  }

  /// ✅ Limpiar flag después de refresh
  void _clearPendingCreditRefresh() {
    _hasPendingCreditPaymentRefresh = false;
  }

  /// ✅ AUTO-REFRESH: Determinar si debemos hacer auto-refresh
  bool _shouldAutoRefresh() {
    // Si el caché fue invalidado (después de CRUD), forzar refresh
    if (_needsRefreshOnNextVisit) {
      _needsRefreshOnNextVisit = false;
      return true;
    }

    // Si nunca se ha hecho refresh, hacerlo
    if (_lastRefreshTime == null) {
      return true;
    }

    // Si ha pasado el intervalo mínimo, hacerlo
    final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceLastRefresh >= _minRefreshInterval;
  }

  @override
  void onClose() {
    // Solo cancelar el timer y worker, NO disponer el searchController
    // porque este controller es permanente y se reutiliza
    _routeWorker?.dispose();
    _routeWorker = null;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;
    // NO llamar dispose en searchController porque el controller es permanente
    super.onClose();
  }

  // ==================== CORE METHODS ====================

  /// ✅ PAGINACIÓN PROFESIONAL: Cargar facturas con manejo de errores mejorado
  Future<void> loadInvoices({bool showLoading = true, bool forceRefresh = false}) async {
    // ✅ GUARD: Prevenir llamadas concurrentes duplicadas
    if (_isLoadInProgress && !forceRefresh) {
      print('⏭️ loadInvoices: Carga ya en progreso, saltando...');
      return;
    }
    _isLoadInProgress = true;

    try {
      // ✅ CACHÉ: Si hay caché válido y no es refresh forzado, usar caché
      if (!forceRefresh && _isCacheValid() && _searchQuery.value.isEmpty && !hasFilters) {
        // print('⚡ Usando caché de facturas (${_cachedInvoices!.length} items)');
        _invoices.value = List.from(_cachedInvoices!);
        _paginationMeta.value = _cachedMeta;
        _applyLocalFilters();
        _lastRefreshTime = DateTime.now();

        // Refrescar en background para mantener datos actualizados
        _refreshInBackground();
        return;
      }

      if (showLoading) _isLoading.value = true;

      // print('📋 CARGA INICIAL: Cargando primera página de facturas...');

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: 1, // ✅ Siempre empezar desde la página 1
          limit: 20, // ✅ Límite estándar
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _getServerFilterStatus(),
          paymentMethod: _selectedPaymentMethod.value,
          bankAccountId: _selectedBankAccountId.value,
          bankAccountName: _selectedBankAccountName.value, // ✅ NUEVO: Filtro por nombre de método de pago
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
          // print('❌ Error al cargar facturas: ${failure.message}');
          // No limpiar datos si ya tenemos facturas en caché (offline-first)
          if (_invoices.isEmpty) {
            _showError('Error al cargar facturas', failure.message);
            _filteredInvoices.clear();
            _paginationMeta.value = null;
          }
        },
        (paginatedResult) {
          // print('✅ CARGA INICIAL EXITOSA:');
          // print('   - Facturas recibidas: ${paginatedResult.data.length}');
          // print('   - Página actual: ${paginatedResult.meta.page}');
          // print('   - Total páginas: ${paginatedResult.meta.totalPages}');
          // print('   - Total facturas: ${paginatedResult.meta.totalItems}');
          // print('   - Tiene siguiente: ${paginatedResult.meta.hasNextPage}');

          // ✅ Asignar datos iniciales
          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;

          // ✅ CACHÉ: Guardar en caché si no hay filtros de búsqueda
          if (_searchQuery.value.isEmpty && !hasFilters) {
            _updateCache(paginatedResult.data, paginatedResult.meta);
          }

          // ✅ Aplicar filtros locales
          _applyLocalFilters();

          // print('✅ FILTRADO COMPLETADO:');
          // print('   - Facturas sin filtrar: ${_invoices.length}');
          // print('   - Facturas filtradas: ${_filteredInvoices.length}');

          // ✅ AUTO-REFRESH: Actualizar timestamp de último refresh exitoso
          _lastRefreshTime = DateTime.now();

          // ✅ FORZAR ACTUALIZACIÓN DE UI
          update();
        },
      );
    } catch (e, stackTrace) {
      // print('💥 Error inesperado al cargar facturas: $e');
      // print('📍 Stack trace: $stackTrace');
      // No limpiar datos si ya tenemos facturas en caché (offline-first)
      if (_invoices.isEmpty) {
        _showError(
          'Error inesperado',
          'No se pudieron cargar las facturas: ${e.toString()}',
        );
        _filteredInvoices.clear();
        _paginationMeta.value = null;
      }
    } finally {
      if (showLoading) _isLoading.value = false;
      _isLoadInProgress = false;
    }
  }

  /// Cargar más facturas (paginación)
  Future<void> loadMoreInvoices() async {
    if (_isLoadingMore.value || !hasNextPage) return;

    try {
      _isLoadingMore.value = true;
      // print('📋 InvoiceListController: Cargando más facturas...');

      final nextPage = currentPage + 1;

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: nextPage,
          limit: 20,
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
          status: _getServerFilterStatus(),
          paymentMethod: _selectedPaymentMethod.value,
          bankAccountId: _selectedBankAccountId.value,
          bankAccountName: _selectedBankAccountName.value, // ✅ NUEVO: Filtro por nombre de método de pago
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
          // print('❌ Error al cargar más facturas: ${failure.message}');
          _showError('Error al cargar más facturas', failure.message);
        },
        (paginatedResult) {
          // ✅ DEBUGGING: Estado antes de agregar
          // print('🔍 ANTES DE AGREGAR:');
          // print('   - Facturas actuales: ${_invoices.length}');
          // print('   - Facturas filtradas: ${_filteredInvoices.length}');
          // print('   - Nuevas facturas recibidas: ${paginatedResult.data.length}');

          // ✅ Evitar duplicados verificando IDs existentes
          final existingIds = _invoices.map((inv) => inv.id).toSet();
          final newInvoices =
              paginatedResult.data
                  .where((inv) => !existingIds.contains(inv.id))
                  .toList();

          // print('🔍 FILTRADO DE DUPLICADOS:');
          // print('   - Facturas realmente nuevas: ${newInvoices.length}');

          if (newInvoices.isEmpty) {
            // print('⚠️ Todas las facturas ya existían (duplicados)');
            _showError(
              'Datos duplicados',
              'Los datos de esta página ya fueron cargados',
            );
            return;
          }

          // ✅ Agregar solo facturas nuevas
          _invoices.addAll(newInvoices);
          _paginationMeta.value = paginatedResult.meta;
          _applyLocalFilters();

          // print('✅ DESPUÉS DE AGREGAR:');
          // print('   - Total facturas: ${_invoices.length}');
          // print('   - Total filtradas: ${_filteredInvoices.length}');
          // print('   - Página actual: ${paginatedResult.meta.page}');
          // print('   - Tiene más páginas: ${paginatedResult.meta.hasNextPage}');

          // ✅ Forzar actualización de UI
          update();
        },
      );
    } catch (e) {
      // print('💥 Error inesperado al cargar más facturas: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar facturas
  Future<void> refreshInvoices({bool showSuccessMessage = true}) async {
    try {
      _isRefreshing.value = true;
      // print('🔄 InvoiceListController: Refrescando facturas...');

      // ✅ Forzar refresh desde el servidor
      await loadInvoices(showLoading: false, forceRefresh: true);

      // ✅ Solo mostrar mensaje si se solicita explícitamente (manual refresh)
      if (showSuccessMessage) {
        _showSuccess('Facturas actualizadas');
      }
    } catch (e) {
      // print('💥 Error al refrescar facturas: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// ✅ CACHÉ: Refrescar datos en background sin bloquear la UI
  Future<void> _refreshInBackground() async {
    // Esperar un momento para no afectar la UI inicial
    await Future.delayed(const Duration(milliseconds: 500));

    if (isClosed) return;

    try {
      // print('🔄 Refrescando facturas en background...');

      final result = await _getInvoicesUseCase(
        GetInvoicesParams(
          page: 1,
          limit: 20,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          // print('⚠️ Error en refresh background: ${failure.message}');
        },
        (paginatedResult) {
          // Verificar si los datos cambiaron
          final hasChanges = _cachedInvoices == null ||
              _cachedInvoices!.length != paginatedResult.data.length ||
              (paginatedResult.data.isNotEmpty &&
                  _cachedInvoices!.isNotEmpty &&
                  paginatedResult.data.first.id != _cachedInvoices!.first.id);

          if (hasChanges) {
            // print('✅ Datos actualizados en background');
            _invoices.value = paginatedResult.data;
            _paginationMeta.value = paginatedResult.meta;
            _updateCache(paginatedResult.data, paginatedResult.meta);
            _applyLocalFilters();
            update();
          } else {
            // print('ℹ️ Sin cambios detectados en background');
            // Actualizar solo el timestamp del caché
            _lastCacheTime = DateTime.now();
          }
        },
      );
    } catch (e) {
      // print('⚠️ Error en refresh background: $e');
    }
  }

  /// Buscar facturas
  Future<void> searchInvoices(String query) async {
    try {
      _isSearching.value = true;
      _searchQuery.value = query;

      // print('🔍 InvoiceListController: Buscando facturas: "$query"');

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
          // print('❌ Error en búsqueda: ${failure.message}');
          _showError('Error en búsqueda', failure.message);
        },
        (searchResults) {
          _invoices.value = searchResults;
          _applyLocalFilters();
          // print('✅ ${searchResults.length} facturas encontradas');
        },
      );
    } catch (e) {
      // print('💥 Error inesperado en búsqueda: $e');
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
    // print('🔧 Filtro estado: ${status?.displayName ?? "Todos"}');

    // Si se selecciona "pending", incluir también "partiallyPaid"
    if (status == InvoiceStatus.pending) {
      // print('🔧 Filtro extendido: Incluyendo facturas parcialmente pagadas');
    }

    loadInvoices();
  }

  /// Aplicar filtro de método de pago
  void filterByPaymentMethod(PaymentMethod? paymentMethod) {
    _selectedPaymentMethod.value = paymentMethod;
    // print('🔧 Filtro método pago: ${paymentMethod?.displayName ?? "Todos"}');
    loadInvoices();
  }

  /// Aplicar filtro de cuenta bancaria por ID (legacy)
  void filterByBankAccount(String? bankAccountId) {
    _selectedBankAccountId.value = bankAccountId;
    // print('🔧 Filtro cuenta bancaria (ID): ${bankAccountId ?? "Todas"}');
    loadInvoices();
  }

  /// Aplicar filtro por nombre de método de pago (Nequi, Bancolombia, Efectivo, etc.)
  /// Si [reload] es false, no recarga las facturas (útil para aplicar múltiples filtros)
  void filterByBankAccountName(String? bankAccountName, {bool reload = true}) {
    _selectedBankAccountName.value = bankAccountName;
    // print('🔧 Filtro método de pago: ${bankAccountName ?? "Todos"}');
    if (reload) loadInvoices();
  }

  /// Aplicar filtro de fechas
  /// Si [reload] es false, no recarga las facturas (útil para aplicar múltiples filtros)
  void filterByDateRange(DateTime? start, DateTime? end, {bool reload = true}) {
    _startDate.value = start;
    _endDate.value = end;
    // print('🔧 Filtro fechas: ${start?.toString()} - ${end?.toString()}');
    if (reload) loadInvoices();
  }

  /// Aplicar múltiples filtros de una sola vez (optimizado - una sola llamada al servidor)
  void applyFilters({
    InvoiceStatus? status,
    String? bankAccountName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // print('🔧 Aplicando filtros múltiples...');

    // Actualizar todos los valores sin recargar
    _selectedStatus.value = status;
    _selectedBankAccountName.value = bankAccountName;
    _startDate.value = startDate;
    _endDate.value = endDate;

    // print('   - Estado: ${status?.displayName ?? "Todos"}');
    // print('   - Método de pago: ${bankAccountName ?? "Todos"}');
    // print('   - Fecha inicio: ${startDate?.toString() ?? "N/A"}');
    // print('   - Fecha fin: ${endDate?.toString() ?? "N/A"}');

    // Una sola llamada al servidor
    loadInvoices();
  }

  /// Aplicar filtro de montos
  void filterByAmountRange(double? min, double? max) {
    _minAmount.value = min;
    _maxAmount.value = max;
    // print('🔧 Filtro montos: $min - $max');
    loadInvoices();
  }

  /// Cambiar ordenamiento
  void changeSort(String newSortBy, String newSortOrder) {
    _sortBy.value = newSortBy;
    _sortOrder.value = newSortOrder;
    // print('🔧 Ordenamiento: $newSortBy $newSortOrder');
    loadInvoices();
  }

  /// Limpiar todos los filtros
  void clearFilters() {
    try {
      _selectedStatus.value = null;
      _selectedPaymentMethod.value = null;
      _selectedBankAccountId.value = null;
      _selectedBankAccountName.value = null; // ✅ Limpiar filtro de nombre de método de pago
      _startDate.value = null;
      _endDate.value = null;
      _minAmount.value = null;
      _maxAmount.value = null;
      _searchQuery.value = '';

      // Limpiar el campo de búsqueda
      searchController.clear();

      loadInvoices();
    } catch (e) {
      // print('⚠️ Error al limpiar filtros: $e');
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
      // print('✅ Confirmando factura: $invoiceId');

      final result = await _confirmInvoiceUseCase(
        ConfirmInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al confirmar factura', failure.message);
        },
        (updatedInvoice) {
          _updateInvoiceInList(updatedInvoice);
          invalidateCache(); // ✅ Invalidar caché después de confirmar
          _showSuccess('Factura confirmada exitosamente');
        },
      );
    } catch (e) {
      // print('💥 Error al confirmar factura: $e');
      _showError('Error inesperado', 'No se pudo confirmar la factura');
    }
  }

  /// Cancelar factura
  Future<void> cancelInvoice(String invoiceId) async {
    try {
      // print('❌ Cancelando factura: $invoiceId');

      final result = await _cancelInvoiceUseCase(
        CancelInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al cancelar factura', failure.message);
        },
        (updatedInvoice) {
          _updateInvoiceInList(updatedInvoice);
          invalidateCache(); // ✅ Invalidar caché después de cancelar
          _showSuccess('Factura cancelada exitosamente');
        },
      );
    } catch (e) {
      // print('💥 Error al cancelar factura: $e');
      _showError('Error inesperado', 'No se pudo cancelar la factura');
    }
  }

  /// Eliminar factura
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      // print('🗑️ Eliminando factura: $invoiceId');

      final result = await _deleteInvoiceUseCase(
        DeleteInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar factura', failure.message);
        },
        (_) {
          _removeInvoiceFromList(invoiceId);
          invalidateCache(); // ✅ Invalidar caché después de eliminar
          _showSuccess('Factura eliminada exitosamente');
        },
      );
    } catch (e) {
      // print('💥 Error al eliminar factura: $e');
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
    // print('🔧 Modo selección múltiple: ${_isMultiSelectMode.value}');
  }

  /// Seleccionar/deseleccionar factura
  void toggleInvoiceSelection(String invoiceId) {
    if (_selectedInvoices.contains(invoiceId)) {
      _selectedInvoices.remove(invoiceId);
    } else {
      _selectedInvoices.add(invoiceId);
    }
    // print('🎯 Facturas seleccionadas: ${_selectedInvoices.length}');
  }

  /// Seleccionar todas las facturas visibles
  void selectAllVisibleInvoices() {
    _selectedInvoices.value =
        _filteredInvoices.map((invoice) => invoice.id).toList();
    // print('✅ Todas las facturas visibles seleccionadas');
  }

  /// Deseleccionar todas las facturas
  void clearSelection() {
    _selectedInvoices.clear();
    // print('🧹 Selección limpiada');
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
      // print('🚀 Navegando a detalle de factura: $invoiceId');
      // print('🔍 Ruta actual antes de navegación: ${Get.currentRoute}');

      // ✅ VERIFICACIÓN: Asegurarse de que la navegación es segura
      if (invoiceId.isEmpty) {
        _showError('Error', 'ID de factura no válido');
        return;
      }

      // ✅ NAVEGACIÓN SEGURA: Usar Future para evitar conflictos
      Future.microtask(() {
        try {
          Get.toNamed('/invoices/detail/$invoiceId');
          // print('✅ Navegación iniciada exitosamente');
        } catch (navError) {
          // print('❌ Error en navegación microtask: $navError');
          _showError('Error de navegación', 'No se pudo abrir el detalle');
        }
      });
    } catch (e) {
      // print('❌ Error navegando a detalle: $e');
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
      print('🖨️ [LIST] Iniciando impresión de factura: $invoiceId');

      // Obtener la factura completa
      final result = await _getInvoiceByIdUseCase(
        GetInvoiceByIdParams(id: invoiceId),
      );

      // Extraer invoice del Either sin callback async (evita race condition)
      Invoice? invoice;
      result.fold(
        (failure) {
          print('❌ [LIST] Error obteniendo factura: ${failure.message}');
          _showError('Error', 'No se pudo cargar la factura para imprimir');
        },
        (inv) {
          invoice = inv;
          print('✅ [LIST] Factura obtenida: ${inv.number}');
        },
      );

      if (invoice == null) {
        print('❌ [LIST] Invoice es null, abortando impresión');
        return;
      }

      // Obtener el ThermalPrinterController
      ThermalPrinterController thermalController;
      try {
        thermalController = Get.find<ThermalPrinterController>();
        print('✅ [LIST] ThermalPrinterController encontrado');
      } catch (e) {
        print('❌ [LIST] ThermalPrinterController NO encontrado: $e');
        _showError(
          'Error de impresión',
          'Controlador de impresión no disponible. Reinicia la app.',
        );
        return;
      }

      // Asegurar que la configuración de impresora esté cargada
      final printerConfigLoaded =
          await thermalController.ensurePrinterConfigLoaded();
      print('🔧 [LIST] Configuración de impresora cargada: $printerConfigLoaded');

      if (!printerConfigLoaded) {
        _showError(
          'Error de configuración',
          'No hay impresora configurada. Configura una en Configuración > Impresoras.',
        );
        return;
      }

      // Imprimir la factura
      print('🖨️ [LIST] Enviando a imprimir...');
      final success = await thermalController.printInvoice(invoice!);
      print('🖨️ [LIST] Resultado de impresión: $success');

      if (success) {
        _showSuccess('Factura ${invoice!.number} impresa exitosamente');
      } else {
        final error = thermalController.lastError ?? "Error desconocido";
        print('❌ [LIST] Error de impresión: $error');
        _showError(
          'Error de impresión',
          'No se pudo imprimir la factura: $error',
        );
      }
    } catch (e) {
      print('💥 [LIST] Error inesperado en impresión: $e');
      _showError(
        'Error de impresión',
        'No se pudo completar la impresión. Verifica la configuración de la impresora.',
      );
    } finally {
      _isPrinting.value = false;
    }
  }

  /// Navegar a imprimir factura
  void goToPrintInvoice(String invoiceId) {
    Get.toNamed('/invoices/print/$invoiceId');
  }

  // ==================== HELPER METHODS ====================

  // Variable para guardar la referencia del listener (deprecado)
  @Deprecated('ScrollController ahora es manejado por InvoiceListScreen')
  VoidCallback? _scrollListener;

  /// @deprecated El ScrollController ahora es manejado por InvoiceListScreen
  @Deprecated('ScrollController ahora es manejado por InvoiceListScreen. NO usar.')
  void _setupScrollListener() {
    // Método deprecado - no hacer nada
  }

  /// @deprecated El ScrollController ahora es manejado por InvoiceListScreen
  @Deprecated('ScrollController ahora es manejado por InvoiceListScreen. NO usar.')
  void _createFreshScrollController() {
    // Método deprecado - no hacer nada
  }

  /// @deprecated El ScrollController ahora es manejado por InvoiceListScreen (StatefulWidget)
  /// Este getter se mantiene solo por compatibilidad pero NO debe usarse
  @Deprecated('ScrollController ahora es manejado por InvoiceListScreen. NO usar este getter.')
  ScrollController get mainScrollController {
    // ⚠️ ADVERTENCIA: Este getter está deprecado
    // El ScrollController real está en InvoiceListScreen._scrollController
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  // ==================== MÉTODOS DE PAGINACIÓN MANUAL ====================

  /// ✅ PAGINACIÓN PROFESIONAL: Ir a una página específica
  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages) {
      _showError(
        'Página inválida',
        'La página debe estar entre 1 y $totalPages',
      );
      return;
    }

    if (pageNumber == currentPage) {
      // print('⚠️ Ya estamos en la página $pageNumber');
      return;
    }

    try {
      _isLoading.value = true;
      // print('📄 Navegando a página $pageNumber...');

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
          // print('❌ Error al ir a página $pageNumber: ${failure.message}');
          _showError('Error de navegación', failure.message);
        },
        (paginatedResult) {
          // ✅ Reemplazar datos completamente para navegación directa
          _invoices.value = paginatedResult.data;
          _paginationMeta.value = paginatedResult.meta;
          _applyLocalFilters();

          // print('✅ Navegación exitosa a página $pageNumber');
          // print('   - Facturas cargadas: ${paginatedResult.data.length}');

          // ✅ NOTA: El scroll al inicio ahora debe ser manejado por el widget
          // El ScrollController es propiedad del StatefulWidget (InvoiceListScreen)

          update();
        },
      );
    } catch (e) {
      // print('💥 Error inesperado navegando a página: $e');
      _showError(
        'Error inesperado',
        'No se pudo navegar a la página $pageNumber',
      );
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
    // print('🔄 Reseteando paginación a estado inicial...');
    _invoices.clear();
    _filteredInvoices.clear();
    _paginationMeta.value = null;
    await loadInvoices();
  }

  /// Configurar listener de búsqueda con debounce - IGUAL que credit notes
  void _setupSearchListener() {
    searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _searchQuery.value = searchController.text;
        loadInvoices();
      });
    });
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
    // print('🔍 DEBUG: _applyLocalFilters() - Iniciando filtrado');
    // print('🔍 DEBUG: _invoices.length: ${_invoices.length}');

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

    // print('🔍 DEBUG: _filteredInvoices.length después del filtrado: ${_filteredInvoices.length}');
    // print('🔍 DEBUG: _applyLocalFilters() - Filtrado completado');
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
        // print('📊 InvoiceListController: Cargando estadísticas automáticamente');

        // Cargar estadísticas en el siguiente frame para evitar conflictos
        Future.microtask(() {
          // ✅ Auto-refresh silencioso de estadísticas
          statsController.refreshAllData(showSuccessMessage: false);
        });
      } else {
        // print('⚠️ InvoiceListController: Controlador de estadísticas no encontrado');
      }
    } catch (e) {
      // print('💥 Error al cargar estadísticas automáticamente: $e');
      // No mostrar error al usuario ya que es una funcionalidad secundaria
    }
  }

  /// Refrescar datos incluyendo estadísticas
  Future<void> refreshAllData({bool showSuccessMessage = false}) async {
    // ✅ NOTA: El ScrollController ahora es manejado por el StatefulWidget (InvoiceListScreen)
    // No es necesario recrearlo aquí - el widget gestiona su propio lifecycle

    // ✅ Auto-refresh silencioso por defecto, solo mostrar mensaje si es manual
    await refreshInvoices(showSuccessMessage: showSuccessMessage);
    _loadInvoiceStatsIfAvailable();
  }

}
