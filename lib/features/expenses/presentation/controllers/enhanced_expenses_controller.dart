// lib/features/expenses/presentation/controllers/enhanced_expenses_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_stats_usecase.dart';
import '../../domain/usecases/approve_expense_usecase.dart';
import '../../domain/usecases/submit_expense_usecase.dart';

class EnhancedExpensesController extends GetxController {
  // Dependencies
  final GetExpensesUseCase _getExpensesUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final GetExpenseStatsUseCase _getExpenseStatsUseCase;
  final ApproveExpenseUseCase _approveExpenseUseCase;
  final SubmitExpenseUseCase _submitExpenseUseCase;

  EnhancedExpensesController({
    required GetExpensesUseCase getExpensesUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required GetExpenseStatsUseCase getExpenseStatsUseCase,
    required ApproveExpenseUseCase approveExpenseUseCase,
    required SubmitExpenseUseCase submitExpenseUseCase,
  }) : _getExpensesUseCase = getExpensesUseCase,
       _deleteExpenseUseCase = deleteExpenseUseCase,
       _getExpenseStatsUseCase = getExpenseStatsUseCase,
       _approveExpenseUseCase = approveExpenseUseCase,
       _submitExpenseUseCase = submitExpenseUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isRefreshing = false.obs;
  final _isDeleting = false.obs;
  final _isApproving = false.obs;
  final _isSubmitting = false.obs;

  // Datos principales
  final _expenses = <Expense>[].obs;
  final Rxn<ExpenseStats> _stats = Rxn<ExpenseStats>();

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;

  // Filtros y búsqueda
  final _currentStatus = Rxn<ExpenseStatus>();
  final _currentType = Rxn<ExpenseType>();
  final _selectedCategoryId = Rxn<String>();
  final _searchTerm = ''.obs;
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();

  // ✅ NUEVO: Filtro por período predefinido - Cambiado a 'all' por defecto
  final _currentPeriod = 'all'.obs; // today, week, month, all

  // ✅ NUEVO: Indicador de búsqueda en progreso
  final _isSearching = false.obs;

  // UI Controllers - TextEditingController normal (el controller es permanente)
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Configuración
  static const int _pageSize = 20;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isDeleting => _isDeleting.value;
  bool get isApproving => _isApproving.value;
  bool get isSubmitting => _isSubmitting.value;

  List<Expense> get expenses => _expenses;
  ExpenseStats? get stats => _stats.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasExpenses => _expenses.isNotEmpty;

  ExpenseStatus? get currentStatus => _currentStatus.value;
  ExpenseType? get currentType => _currentType.value;
  String? get selectedCategoryId => _selectedCategoryId.value;
  String get searchTerm => _searchTerm.value;
  bool get isSearching => _isSearching.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;
  String get currentPeriod => _currentPeriod.value;

  // ✅ NUEVO: Getter para verificar si hay filtros activos
  bool get hasActiveFilters =>
      _currentStatus.value != null ||
      _currentType.value != null ||
      _selectedCategoryId.value != null ||
      _searchTerm.value.isNotEmpty ||
      _currentPeriod.value != 'all';

  @override
  void onInit() {
    super.onInit();
    print('🧮 EnhancedExpensesController: Inicializando...');

    // ✅ Configurar scroll infinito
    _setupScrollListener();

    // ✅ Cargar datos iniciales automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void onClose() {
    // Solo cancelar el timer, NO disponer los controllers
    // porque este controller es permanente y se reutiliza
    _searchTimer?.cancel();
    _searchTimer = null;
    // NO llamar dispose en searchController y scrollController
    super.onClose();
  }

  // ==================== CONFIGURACIÓN INICIAL ====================

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore.value && _hasNextPage.value) {
          _loadMoreExpenses();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    print('🧮 Cargando datos iniciales...');

    // ✅ IMPORTANTE: _loadExpenses ahora llama a _loadStats() internamente después de asignar datos
    await _loadExpenses(reset: true);

    print('✅ Datos iniciales cargados correctamente');
  }

  // ==================== CARGA DE DATOS ====================

  Future<void> _loadExpenses({bool reset = false}) async {
    if (reset) {
      _isLoading.value = true;
      _currentPage.value = 1;
      _expenses.clear();
    } else {
      _isLoadingMore.value = true;
    }

    try {
      print('🔍 Cargando gastos - Página: ${_currentPage.value}');

      // ✅ Calcular fechas según el período seleccionado
      final dateRange = _getDateRangeForPeriod(_currentPeriod.value);

      final result = await _getExpensesUseCase.call(
        GetExpensesParams(
          page: _currentPage.value,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value?.name,
          type: _currentType.value?.name,
          categoryId: _selectedCategoryId.value,
          startDate: dateRange['start'],
          endDate: dateRange['end'],
          orderBy: _sortBy.value,
          orderDirection: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          print('❌ Error cargando gastos: ${failure.message}');
          Get.snackbar(
            'Error',
            'No se pudieron cargar los gastos: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (response) {
          print('✅ Gastos cargados: ${response.data.length} items');

          if (reset) {
            _expenses.assignAll(response.data);
          } else {
            _expenses.addAll(response.data);
          }

          // ✅ Actualizar metadatos de paginación
          _updatePaginationMetadata(response.meta);

          // ✅ IMPORTANTE: Calcular estadísticas DESPUÉS de asignar datos
          _loadStats();
        },
      );
    } catch (e) {
      print('💥 Error inesperado cargando gastos: $e');
      Get.snackbar(
        'Error',
        'Error inesperado al cargar gastos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isLoading.value = false;
      _isLoadingMore.value = false;
      _isRefreshing.value = false;
    }
  }

  Future<void> _loadStats() async {
    try {
      print('📊 Calculando estadísticas desde gastos filtrados...');

      // ✅ NUEVO: Calcular estadísticas LOCALMENTE desde los gastos ya filtrados
      // Esto garantiza 100% consistencia con lo que se muestra en pantalla
      _stats.value = _calculateStatsFromFilteredExpenses();

      print('✅ Estadísticas calculadas localmente:');
      print('   Total: ${_stats.value?.totalAmount}');
      print('   Cantidad: ${_stats.value?.totalExpenses}');
      print('   Aprobados: ${_stats.value?.approvedExpenses}');
      print('   Pendientes: ${_stats.value?.pendingExpenses}');
      print('   Pagados: ${_stats.value?.paidExpenses}');
    } catch (e) {
      print('💥 Error calculando estadísticas: $e');
    }
  }

  // ✅ NUEVO: Calcular estadísticas desde los gastos filtrados localmente
  ExpenseStats _calculateStatsFromFilteredExpenses() {
    print('🔍 Calculando estadísticas desde ${_expenses.length} gastos en memoria');

    if (_expenses.isEmpty) {
      print('⚠️ No hay gastos filtrados, retornando estadísticas vacías');
      return ExpenseStats(
        totalExpenses: 0,
        totalAmount: 0.0,
        approvedExpenses: 0,
        approvedAmount: 0.0,
        pendingExpenses: 0,
        pendingAmount: 0.0,
        rejectedExpenses: 0,
        rejectedAmount: 0.0,
        paidExpenses: 0,
        paidAmount: 0.0,
        monthlyAmount: 0.0,
        weeklyAmount: 0.0,
        dailyAmount: 0.0,
        averageExpenseAmount: 0.0,
        expensesByCategory: {},
        expensesByType: {},
        expensesByStatus: {},
        monthlyTrends: [],
        monthlyCount: 0,
      );
    }

    // Calcular totales
    final totalExpenses = _expenses.length;
    final totalAmount = _expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final averageAmount = totalExpenses > 0 ? totalAmount / totalExpenses : 0.0;

    print('💰 Total calculado: \$${totalAmount.toStringAsFixed(2)} desde $totalExpenses gastos');
    if (totalExpenses > 0 && totalExpenses <= 5) {
      for (var i = 0; i < _expenses.length; i++) {
        print('   Gasto ${i + 1}: \$${_expenses[i].amount} - ${_expenses[i].description}');
      }
    }

    // Filtrar por estado
    final approved = _expenses.where((e) => e.status == ExpenseStatus.approved).toList();
    final pending = _expenses.where((e) => e.status == ExpenseStatus.pending).toList();
    final rejected = _expenses.where((e) => e.status == ExpenseStatus.rejected).toList();
    final paid = _expenses.where((e) => e.isPaid).toList();

    final approvedExpenses = approved.length;
    final approvedAmount = approved.fold<double>(0.0, (sum, e) => sum + e.amount);

    final pendingExpenses = pending.length;
    final pendingAmount = pending.fold<double>(0.0, (sum, e) => sum + e.amount);

    final rejectedExpenses = rejected.length;
    final rejectedAmount = rejected.fold<double>(0.0, (sum, e) => sum + e.amount);

    final paidExpenses = paid.length;
    final paidAmount = paid.fold<double>(0.0, (sum, e) => sum + e.amount);

    // Agrupar por categoría (usando categoryId ya que no tenemos el objeto completo)
    final expensesByCategory = <String, double>{};
    for (final expense in _expenses) {
      final categoryId = expense.categoryId;
      expensesByCategory[categoryId] = (expensesByCategory[categoryId] ?? 0) + expense.amount;
    }

    // Agrupar por tipo
    final expensesByType = <String, double>{};
    for (final expense in _expenses) {
      final typeName = expense.type.displayName;
      expensesByType[typeName] = (expensesByType[typeName] ?? 0) + expense.amount;
    }

    // Contar por estado
    final expensesByStatus = <String, int>{
      'approved': approvedExpenses,
      'pending': pendingExpenses,
      'rejected': rejectedExpenses,
    };

    return ExpenseStats(
      totalExpenses: totalExpenses,
      totalAmount: totalAmount,
      approvedExpenses: approvedExpenses,
      approvedAmount: approvedAmount,
      pendingExpenses: pendingExpenses,
      pendingAmount: pendingAmount,
      rejectedExpenses: rejectedExpenses,
      rejectedAmount: rejectedAmount,
      paidExpenses: paidExpenses,
      paidAmount: paidAmount,
      monthlyAmount: totalAmount,
      weeklyAmount: totalAmount,
      dailyAmount: totalAmount,
      averageExpenseAmount: averageAmount,
      expensesByCategory: expensesByCategory,
      expensesByType: expensesByType,
      expensesByStatus: expensesByStatus,
      monthlyTrends: [],
      monthlyCount: totalExpenses,
    );
  }

  Future<void> _loadMoreExpenses() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _currentPage.value++;
    await _loadExpenses();
  }

  // ==================== FILTROS Y BÚSQUEDA ====================

  void updateSearch(String term) {
    print('🔍 Actualizando búsqueda: "$term"');
    _searchTerm.value = term;
    _debounceSearch();
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();

    // Mostrar indicador de búsqueda si hay texto
    if (_searchTerm.value.isNotEmpty) {
      _isSearching.value = true;
    } else {
      _isSearching.value = false;
    }

    // ✅ Debounce de 800ms - suficiente tiempo para usuarios que escriben lento
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      _loadExpenses(reset: true).then((_) {
        _isSearching.value = false;
      });
    });
  }

  void setPeriodFilter(String period) {
    print('📅 Cambiando período a: $period');
    _currentPeriod.value = period;
    _loadExpenses(reset: true);
    _loadStats(); // ✅ Recargar estadísticas con nuevo período
  }

  void setPeriod(String period) {
    setPeriodFilter(period);
  }

  void setDateRange({DateTime? start, DateTime? end}) {
    print('📅 Estableciendo rango de fechas: ${start?.toString()} - ${end?.toString()}');

    // ✅ Si hay fecha de inicio, asegurarse de que sea a las 00:00:00
    if (start != null) {
      _startDate.value = DateTime(start.year, start.month, start.day, 0, 0, 0);
      print('   ✅ Fecha inicio ajustada: ${_startDate.value}');
    }

    // ✅ Si hay fecha de fin, asegurarse de que incluya TODO el día (23:59:59.999)
    if (end != null) {
      _endDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      print('   ✅ Fecha fin ajustada: ${_endDate.value}');
    }

    // Si se establece un rango personalizado, cambiar período a 'custom'
    if (start != null || end != null) {
      _currentPeriod.value = 'custom';
    }

    _loadExpenses(reset: true);
    // ✅ _loadStats() se llama automáticamente dentro de _loadExpenses
  }

  void clearDateFilters() {
    print('🗑️ Limpiando filtros de fecha');
    _startDate.value = null;
    _endDate.value = null;
    _currentPeriod.value = 'all';
    _loadExpenses(reset: true);
    // ✅ _loadStats() se llama automáticamente dentro de _loadExpenses
  }

  void applyStatusFilter(ExpenseStatus? status) {
    print('📋 Aplicando filtro de estado: ${status?.displayName ?? "Todos"}');
    _currentStatus.value = status;
    _loadExpenses(reset: true);
  }

  void applyTypeFilter(ExpenseType? type) {
    print('🏷️ Aplicando filtro de tipo: ${type?.displayName ?? "Todos"}');
    _currentType.value = type;
    _loadExpenses(reset: true);
  }

  void applyCategoryFilter(String? categoryId) {
    print('📂 Aplicando filtro de categoría: $categoryId');
    _selectedCategoryId.value = categoryId;
    _loadExpenses(reset: true);
  }

  void applyDateFilter(DateTime? start, DateTime? end) {
    print('📅 Aplicando filtro de fecha: $start - $end');
    _startDate.value = start;
    _endDate.value = end;
    _currentPeriod.value = 'custom'; // ✅ Cambiar a período personalizado
    _loadExpenses(reset: true);
  }

  void changeSorting(String sortBy, String sortOrder) {
    print('🔄 Cambiando ordenamiento: $sortBy $sortOrder');
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _loadExpenses(reset: true);
  }

  void clearFilters() {
    print('🧹 Limpiando todos los filtros...');

    _currentStatus.value = null;
    _currentType.value = null;
    _selectedCategoryId.value = null;
    _startDate.value = null;
    _endDate.value = null;
    _currentPeriod.value = 'all';

    searchController.clear();
    _searchTerm.value = '';

    _loadExpenses(reset: true);
    _loadStats();
  }

  // ==================== ACCIONES DE GASTOS ====================

  Future<void> refreshExpenses() async {
    // Diferir al siguiente event loop para evitar setState durante build phase
    // Esto previene el error "setState() called during build" cuando se llama
    // desde bindings, routes, o cualquier contexto dentro del build del widget tree
    await Future.delayed(Duration.zero);
    print('🔄 Refrescando gastos...');
    _isRefreshing.value = true;
    await _loadInitialData();
  }

  void showExpenseDetails(String expenseId) {
    print('👀 Mostrando detalles del gasto: $expenseId');
    Get.toNamed('/expenses/detail/$expenseId');
  }

  void goToCreateExpense() {
    print('➕ Navegando a crear gasto...');
    Get.toNamed('/expenses/create');
  }

  void goToEditExpense(String expenseId) {
    print('✏️ Navegando a editar gasto: $expenseId');
    Get.toNamed('/expenses/edit/$expenseId');
  }

  void goToExpenseAnalytics() {
    print('📊 Navegando a análisis de gastos...');
    Get.toNamed('/expenses/analytics');
  }

  Future<void> confirmDelete(Expense expense) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el gasto "${expense.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExpense(expense.id);
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando gasto: $expenseId');

      final result = await _deleteExpenseUseCase.call(
        DeleteExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          print('❌ Error eliminando gasto: ${failure.message}');
          Get.snackbar(
            'Error',
            'No se pudo eliminar el gasto: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (_) {
          print('✅ Gasto eliminado correctamente');

          // ✅ Remover de la lista local
          _expenses.removeWhere((expense) => expense.id == expenseId);
          _totalItems.value--;

          // ✅ Recargar estadísticas
          _loadStats();

          Get.snackbar(
            'Éxito',
            'Gasto eliminado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        },
      );
    } catch (e) {
      print('💥 Error inesperado eliminando gasto: $e');
      Get.snackbar(
        'Error',
        'Error inesperado al eliminar el gasto',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  Future<void> confirmApprove(Expense expense) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Aprobación'),
        content: Text(
          '¿Aprobar el gasto "${expense.description}" por ${expense.formattedAmount}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _approveExpense(expense.id);
    }
  }

  Future<void> _approveExpense(String expenseId) async {
    _isApproving.value = true;

    try {
      print('✅ Aprobando gasto: $expenseId');

      final result = await _approveExpenseUseCase.call(
        ApproveExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          print('❌ Error aprobando gasto: ${failure.message}');
          Get.snackbar(
            'Error',
            'No se pudo aprobar el gasto: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (updatedExpense) {
          print('✅ Gasto aprobado correctamente');

          // ✅ Actualizar en la lista local
          final index = _expenses.indexWhere(
            (expense) => expense.id == expenseId,
          );
          if (index != -1) {
            _expenses[index] = updatedExpense;
          }

          // ✅ Recargar estadísticas
          _loadStats();

          Get.snackbar(
            'Éxito',
            'Gasto aprobado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        },
      );
    } catch (e) {
      print('💥 Error inesperado aprobando gasto: $e');
      Get.snackbar(
        'Error',
        'Error inesperado al aprobar el gasto',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isApproving.value = false;
    }
  }

  Future<void> submitExpense(String expenseId) async {
    _isSubmitting.value = true;

    try {
      print('📤 Enviando gasto para aprobación: $expenseId');

      final result = await _submitExpenseUseCase.call(
        SubmitExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          print('❌ Error enviando gasto: ${failure.message}');
          Get.snackbar(
            'Error',
            'No se pudo enviar el gasto: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (updatedExpense) {
          print('✅ Gasto enviado correctamente');

          // ✅ Actualizar en la lista local
          final index = _expenses.indexWhere(
            (expense) => expense.id == expenseId,
          );
          if (index != -1) {
            _expenses[index] = updatedExpense;
          }

          // ✅ Recargar estadísticas
          _loadStats();

          Get.snackbar(
            'Éxito',
            'Gasto enviado para aprobación',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.blue.shade100,
            colorText: Colors.blue.shade800,
          );
        },
      );
    } catch (e) {
      print('💥 Error inesperado enviando gasto: $e');
      Get.snackbar(
        'Error',
        'Error inesperado al enviar el gasto',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ==================== EXPORTACIÓN ====================

  Future<void> exportToPdf() async {
    print('📄 Exportando a PDF...');
    // ✅ Implementar exportación a PDF
    Get.snackbar(
      'Próximamente',
      'La exportación a PDF estará disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> exportToExcel() async {
    print('📊 Exportando a Excel...');
    // ✅ Implementar exportación a Excel
    Get.snackbar(
      'Próximamente',
      'La exportación a Excel estará disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> shareExpensesSummary() async {
    print('📤 Compartiendo resumen...');
    // ✅ Implementar compartir resumen
    Get.snackbar(
      'Próximamente',
      'Compartir resumen estará disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  // ==================== MÉTODOS AUXILIARES ====================

  void _updatePaginationMetadata(PaginationMeta meta) {
    _totalPages.value = meta.totalPages;
    _totalItems.value = meta.total;
    _hasNextPage.value = meta.hasNext;

    print(
      '📄 Paginación actualizada: ${meta.page}/${meta.totalPages} (${meta.total} total)',
    );
  }

  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();

    // ✅ PRIMERO: Si hay fechas personalizadas (_startDate o _endDate), usarlas
    if (_startDate.value != null || _endDate.value != null) {
      print('🔍 Usando rango personalizado: ${_startDate.value} - ${_endDate.value}');
      return {'start': _startDate.value, 'end': _endDate.value};
    }

    // ✅ SEGUNDO: Usar período predefinido
    switch (period) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        print('🔍 Filtrando por HOY: $today - $endOfDay');
        return {'start': today, 'end': endOfDay};

      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOfWeek = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        print('🔍 Filtrando por ESTA SEMANA: $start - $endOfWeek');
        return {'start': start, 'end': endOfWeek};

      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        print('🔍 Filtrando por ESTE MES: $startOfMonth - $endOfMonth');
        return {'start': startOfMonth, 'end': endOfMonth};

      default: // 'all'
        print('🔍 Mostrando TODOS los gastos (sin filtro de fecha)');
        return {'start': null, 'end': null};
    }
  }

  ExpenseStats _enrichStatsWithCalculatedData(ExpenseStats originalStats) {
    final now = DateTime.now();

    // ✅ Calcular datos adicionales usando los gastos cargados
    final dailyCount = _calculateDailyCount();
    final weeklyCount = _calculateWeeklyCount();
    final monthlyCount = _calculateMonthlyCount();
    final dailyAmount = _calculateDailyAmount();
    final weeklyAmount = _calculateWeeklyAmount();
    final monthlyAmount = _calculateMonthlyAmount();
    final previousMonthAmount = _calculatePreviousMonthAmount();

    return ExpenseStats(
      totalExpenses: originalStats.totalExpenses,
      totalAmount: originalStats.totalAmount,
      monthlyAmount: monthlyAmount, // ✅ Usar valor calculado localmente
      weeklyAmount: weeklyAmount, // ✅ Usar valor calculado localmente
      dailyAmount: dailyAmount, // ✅ Usar valor calculado localmente
      pendingExpenses: originalStats.pendingExpenses,
      pendingAmount: originalStats.pendingAmount,
      approvedExpenses: originalStats.approvedExpenses,
      approvedAmount: originalStats.approvedAmount,
      paidExpenses: originalStats.paidExpenses,
      paidAmount: originalStats.paidAmount,
      rejectedExpenses: originalStats.rejectedExpenses,
      rejectedAmount: originalStats.rejectedAmount,
      averageExpenseAmount: originalStats.averageExpenseAmount,
      expensesByCategory: originalStats.expensesByCategory,
      expensesByType: originalStats.expensesByType,
      expensesByStatus: originalStats.expensesByStatus,
      monthlyTrends: originalStats.monthlyTrends,
      dailyCount: dailyCount,
      weeklyCount: weeklyCount,
      monthlyCount: monthlyCount,
      previousMonthAmount: previousMonthAmount,
    );
  }

  int _calculateDailyCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDate.isAtSameMomentAs(today);
    }).length;
  }

  int _calculateWeeklyCount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = start.add(const Duration(days: 7));

    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return (expenseDate.isAtSameMomentAs(start) ||
              expenseDate.isAfter(start)) &&
          expenseDate.isBefore(end);
    }).length;
  }

  int _calculateMonthlyCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return (expenseDate.isAtSameMomentAs(startOfMonth) ||
              expenseDate.isAfter(startOfMonth)) &&
          expenseDate.isBefore(endOfMonth);
    }).length;
  }

  double _calculateDailyAmount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _expenses
        .where((expense) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          return expenseDate.isAtSameMomentAs(today);
        })
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateWeeklyAmount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = start.add(const Duration(days: 7));

    return _expenses
        .where((expense) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          return (expenseDate.isAtSameMomentAs(start) ||
                  expenseDate.isAfter(start)) &&
              expenseDate.isBefore(end);
        })
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateMonthlyAmount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _expenses
        .where((expense) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          return (expenseDate.isAtSameMomentAs(startOfMonth) ||
                  expenseDate.isAfter(startOfMonth)) &&
              expenseDate.isBefore(endOfMonth);
        })
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculatePreviousMonthAmount() {
    final now = DateTime.now();
    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPreviousMonth = DateTime(now.year, now.month, 1);

    return _expenses
        .where((expense) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          return (expenseDate.isAtSameMomentAs(startOfPreviousMonth) ||
                  expenseDate.isAfter(startOfPreviousMonth)) &&
              expenseDate.isBefore(endOfPreviousMonth);
        })
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
