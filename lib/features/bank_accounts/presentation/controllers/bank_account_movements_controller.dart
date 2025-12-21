// lib/features/bank_accounts/presentation/controllers/bank_account_movements_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_account_transaction.dart';
import '../../domain/repositories/bank_account_repository.dart';

/// Controlador para la pantalla de movimientos de cuentas bancarias
class BankAccountMovementsController extends GetxController {
  final BankAccountRepository repository;

  BankAccountMovementsController({required this.repository});

  // ==================== STATE ====================

  /// Cuenta bancaria actual
  final Rx<BankAccount?> account = Rx<BankAccount?>(null);

  /// Información de la cuenta en las transacciones
  final Rx<TransactionAccountInfo?> accountInfo = Rx<TransactionAccountInfo?>(null);

  /// Lista de transacciones
  final RxList<BankAccountTransaction> transactions = <BankAccountTransaction>[].obs;

  /// Resumen de transacciones
  final Rx<TransactionsSummary?> summary = Rx<TransactionsSummary?>(null);

  /// Paginación
  final Rx<TransactionsPagination?> pagination = Rx<TransactionsPagination?>(null);

  /// Estados de carga
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  /// Errores
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Filtros
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 20.obs;

  // ==================== GETTERS ====================

  /// Tiene más páginas para cargar
  bool get hasMorePages => pagination.value?.hasNextPage ?? false;

  /// Tiene transacciones
  bool get hasTransactions => transactions.isNotEmpty;

  /// Total de transacciones
  int get totalTransactions => pagination.value?.total ?? 0;

  /// Filtros activos
  bool get hasActiveFilters =>
      startDate.value != null || endDate.value != null || searchQuery.value.isNotEmpty;

  // ==================== INITIALIZATION ====================

  /// Inicializar con ID de cuenta
  Future<void> init(String accountId) async {
    // Cargar información de la cuenta primero
    final accountResult = await repository.getBankAccountById(accountId);
    accountResult.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
      },
      (acc) {
        account.value = acc;
        // Cargar transacciones
        loadTransactions(refresh: true);
      },
    );
  }

  // ==================== METHODS ====================

  /// Cargar transacciones
  Future<void> loadTransactions({bool refresh = false}) async {
    if (account.value == null) return;
    if (isLoading.value && !refresh) return;

    if (refresh) {
      currentPage.value = 1;
      transactions.clear();
    }

    isLoading.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.getBankAccountTransactions(
      account.value!.id,
      startDate: startDate.value != null
          ? DateFormat('yyyy-MM-dd').format(startDate.value!)
          : null,
      endDate: endDate.value != null
          ? DateFormat('yyyy-MM-dd').format(endDate.value!)
          : null,
      page: currentPage.value,
      limit: pageSize.value,
      search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
      },
      (response) {
        accountInfo.value = response.account;

        if (refresh) {
          transactions.value = response.transactions;
        } else {
          transactions.addAll(response.transactions);
        }

        pagination.value = response.pagination;
        summary.value = response.summary;
      },
    );

    isLoading.value = false;
  }

  /// Cargar más transacciones (scroll infinito)
  Future<void> loadMore() async {
    if (!hasMorePages || isLoadingMore.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    await loadTransactions(refresh: false);

    isLoadingMore.value = false;
  }

  /// Aplicar filtros
  Future<void> applyFilters({
    DateTime? newStartDate,
    DateTime? newEndDate,
    String? newSearch,
  }) async {
    startDate.value = newStartDate;
    endDate.value = newEndDate;

    if (newSearch != null) {
      searchQuery.value = newSearch;
    }

    await loadTransactions(refresh: true);
  }

  /// Limpiar filtros
  Future<void> clearFilters() async {
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    await loadTransactions(refresh: true);
  }

  /// Refrescar datos
  Future<void> refresh() async {
    await loadTransactions(refresh: true);
  }

  /// Buscar transacciones
  void searchTransactions(String query) {
    searchQuery.value = query;
    // Debounce: esperar 500ms antes de ejecutar la búsqueda
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == query) {
        loadTransactions(refresh: true);
      }
    });
  }

  /// Filtrar por rango de fechas
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    startDate.value = start;
    endDate.value = end;
    await loadTransactions(refresh: true);
  }

  /// Establecer filtros predefinidos
  Future<void> setPresetFilter(String preset) async {
    final now = DateTime.now();

    switch (preset) {
      case 'today':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        startDate.value = now.subtract(Duration(days: now.weekday - 1));
        endDate.value = now;
        break;
      case 'month':
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = now;
        break;
      case 'year':
        startDate.value = DateTime(now.year, 1, 1);
        endDate.value = now;
        break;
      case 'all':
      default:
        startDate.value = null;
        endDate.value = null;
    }

    await loadTransactions(refresh: true);
  }

  // ==================== CLEANUP ====================

  @override
  void onClose() {
    transactions.clear();
    super.onClose();
  }
}
