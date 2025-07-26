// lib/features/expenses/presentation/controllers/expenses_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/expense_repository.dart' show PaginationMeta;
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_stats_usecase.dart';
import '../../domain/usecases/approve_expense_usecase.dart';
import '../../domain/usecases/submit_expense_usecase.dart';

class ExpensesController extends GetxController {
  // Dependencies
  final GetExpensesUseCase _getExpensesUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final GetExpenseStatsUseCase _getExpenseStatsUseCase;
  final ApproveExpenseUseCase _approveExpenseUseCase;
  final SubmitExpenseUseCase _submitExpenseUseCase;

  ExpensesController({
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
  final _isDeleting = false.obs;
  final _isRefreshing = false.obs;
  final _isApproving = false.obs;
  final _isSubmitting = false.obs;

  // Datos
  final _expenses = <Expense>[].obs;
  final Rxn<ExpenseStats> _stats = Rxn<ExpenseStats>();

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;
  final _hasPreviousPage = false.obs;

  // Filtros y búsqueda
  final _currentStatus = Rxn<ExpenseStatus>();
  final _currentType = Rxn<ExpenseType>();
  final _selectedCategoryId = Rxn<String>();
  final _searchTerm = ''.obs;
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();

  // UI Controllers
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Configuración
  static const int _pageSize = 20;

  // Control de llamadas duplicadas
  bool _isInitialized = false;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isDeleting => _isDeleting.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isApproving => _isApproving.value;
  bool get isSubmitting => _isSubmitting.value;

  List<Expense> get expenses => _expenses;
  ExpenseStats? get stats => _stats.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;

  ExpenseStatus? get currentStatus => _currentStatus.value;
  ExpenseType? get currentType => _currentType.value;
  String? get selectedCategoryId => _selectedCategoryId.value;
  String get searchTerm => _searchTerm.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;

  bool get hasExpenses => _expenses.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    print('🎯 ExpensesController onInit() llamado');
  }

  @override
  void onReady() {
    super.onReady();
    print('🎯 ExpensesController onReady() llamado - Cargando gastos...');
    _initializeData();
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializeData() async {
    if (_isInitialized) {
      print('⚠️ ExpensesController ya inicializado, omitiendo...');
      return;
    }

    try {
      print('🚀 Inicializando ExpensesController...');

      await Future.wait([
        loadExpenses(),
        loadStats(),
      ]);

      _isInitialized = true;
      print('✅ ExpensesController inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar ExpensesController: $e');
    }
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> loadExpenses({bool showLoading = true}) async {
    if (_isLoading.value) {
      print('⚠️ Ya hay una carga en progreso, ignorando...');
      return;
    }

    if (showLoading) _isLoading.value = true;

    try {
      print('📦 Cargando gastos...');

      final result = await _getExpensesUseCase(
        GetExpensesParams(
          page: 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value?.name,
          type: _currentType.value?.name,
          categoryId: _selectedCategoryId.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          orderBy: _sortBy.value,
          orderDirection: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar gastos', failure.message);
          _expenses.clear();
        },
        (paginatedResult) {
          _expenses.value = paginatedResult.data;
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Gastos cargados: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado al cargar gastos: $e');
      _showError('Error inesperado', 'Error al cargar gastos');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMoreExpenses() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _isLoadingMore.value = true;

    try {
      print('📄 Cargando más gastos (página ${_currentPage.value + 1})...');

      final result = await _getExpensesUseCase(
        GetExpensesParams(
          page: _currentPage.value + 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value?.name,
          type: _currentType.value?.name,
          categoryId: _selectedCategoryId.value,
          startDate: _startDate.value,
          endDate: _endDate.value,
          orderBy: _sortBy.value,
          orderDirection: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar más gastos', failure.message);
        },
        (paginatedResult) {
          _expenses.addAll(paginatedResult.data);
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Más gastos cargados: ${paginatedResult.data.length}');
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<void> refreshExpenses() async {
    if (_isRefreshing.value) {
      print('⚠️ Ya hay un refresco en progreso, ignorando...');
      return;
    }

    print('🔄 Refrescando gastos...');
    _isRefreshing.value = true;
    _currentPage.value = 1;

    try {
      await Future.wait([
        loadExpenses(showLoading: false),
        loadStats(),
      ]);
      print('✅ Refresco completado exitosamente');
    } catch (e) {
      print('❌ Error durante el refresco: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando gasto: $expenseId');

      final result = await _deleteExpenseUseCase(
        DeleteExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          _showSuccess('Gasto eliminado exitosamente');
          _expenses.removeWhere((expense) => expense.id == expenseId);
          refreshExpenses();
          print('✅ Gasto eliminado exitosamente');
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  Future<void> approveExpense(String expenseId) async {
    _isApproving.value = true;

    try {
      print('✅ Aprobando gasto: $expenseId');

      final result = await _approveExpenseUseCase(
        ApproveExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          _showError('Error al aprobar', failure.message);
        },
        (updatedExpense) {
          _showSuccess('Gasto aprobado exitosamente');
          final index = _expenses.indexWhere((expense) => expense.id == expenseId);
          if (index != -1) {
            _expenses[index] = updatedExpense;
          }
          refreshExpenses();
          print('✅ Gasto aprobado exitosamente');
        },
      );
    } finally {
      _isApproving.value = false;
    }
  }

  Future<void> submitExpense(String expenseId) async {
    _isSubmitting.value = true;

    try {
      print('📤 Enviando gasto para aprobación: $expenseId');

      final result = await _submitExpenseUseCase(
        SubmitExpenseParams(id: expenseId),
      );

      result.fold(
        (failure) {
          _showError('Error al enviar', failure.message);
        },
        (updatedExpense) {
          _showSuccess('Gasto enviado para aprobación');
          final index = _expenses.indexWhere((expense) => expense.id == expenseId);
          if (index != -1) {
            _expenses[index] = updatedExpense;
          }
          refreshExpenses();
          print('✅ Gasto enviado para aprobación');
        },
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      print('📊 Cargando estadísticas...');

      final result = await _getExpenseStatsUseCase(GetExpenseStatsParams());

      result.fold(
        (failure) {
          print('⚠️ Error al cargar estadísticas: ${failure.message}');
        },
        (stats) {
          _stats.value = stats;
          print('✅ Estadísticas cargadas: total=\$${stats.totalAmount}');
        },
      );
    } catch (e) {
      print('⚠️ Error inesperado al cargar estadísticas: $e');
    }
  }

  // ==================== FILTER & SORT METHODS ====================

  void applyStatusFilter(ExpenseStatus? status) {
    if (_currentStatus.value == status) return;

    _currentStatus.value = status;
    _currentPage.value = 1;
    loadExpenses();
  }

  void applyTypeFilter(ExpenseType? type) {
    if (_currentType.value == type) return;

    _currentType.value = type;
    _currentPage.value = 1;
    loadExpenses();
  }

  void applyCategoryFilter(String? categoryId) {
    if (_selectedCategoryId.value == categoryId) return;

    _selectedCategoryId.value = categoryId;
    _currentPage.value = 1;
    loadExpenses();
  }

  void applyDateFilter(DateTime? startDate, DateTime? endDate) {
    _startDate.value = startDate;
    _endDate.value = endDate;
    _currentPage.value = 1;
    loadExpenses();
  }

  void changeSorting(String sortBy, String sortOrder) {
    if (_sortBy.value == sortBy && _sortOrder.value == sortOrder) return;

    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadExpenses();
  }

  void clearFilters() {
    _currentStatus.value = null;
    _currentType.value = null;
    _selectedCategoryId.value = null;
    _searchTerm.value = '';
    _startDate.value = null;
    _endDate.value = null;
    searchController.clear();
    _currentPage.value = 1;
    loadExpenses();
  }

  void updateSearch(String value) {
    _searchTerm.value = value;
    if (value.trim().isEmpty) {
      loadExpenses();
    } else if (value.trim().length >= 2) {
      _currentPage.value = 1;
      loadExpenses();
    }
  }

  // ==================== UI HELPERS ====================

  void goToCreateExpense() {
    Get.toNamed('/expenses/create')?.then((result) {
      if (result != null) {
        refreshExpenses();
      }
    });
  }

  void goToEditExpense(String expenseId) {
    Get.toNamed('/expenses/edit/$expenseId')?.then((result) {
      if (result != null) {
        refreshExpenses();
      }
    });
  }

  void showExpenseDetails(String expenseId) {
    Get.toNamed('/expenses/detail/$expenseId')?.then((result) {
      if (result == 'deleted') {
        refreshExpenses();
      }
    });
  }

  void goToExpenseStats() {
    Get.toNamed('/expenses/stats');
  }

  void confirmDelete(Expense expense) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro que deseas eliminar el gasto "${expense.description}"?\n\n'
          'Monto: ${expense.formattedAmount}\n'
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
              deleteExpense(expense.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void confirmApprove(Expense expense) {
    Get.dialog(
      AlertDialog(
        title: const Text('Aprobar Gasto'),
        content: Text(
          '¿Estás seguro que deseas aprobar el gasto "${expense.description}"?\n\n'
          'Monto: ${expense.formattedAmount}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              approveExpense(expense.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  // ==================== PRIVATE METHODS ====================

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore.value && _hasNextPage.value) {
          loadMoreExpenses();
        }
      }
    });
  }

  void _updatePaginationInfo(PaginationMeta meta) {
    _currentPage.value = meta.page;
    _totalPages.value = meta.totalPages;
    _totalItems.value = meta.total;
    _hasNextPage.value = meta.hasNext;
    _hasPreviousPage.value = meta.hasPrev;
  }

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
}