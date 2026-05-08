// lib/features/bank_accounts/presentation/controllers/bank_account_movements_controller.dart
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_account_movement.dart';
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

  /// Cargar transacciones desde la tabla `bank_account_movements` (real).
  ///
  /// Antes leía Payment + CreditPayment calculados on-the-fly. Ahora usa
  /// los movements auditables (incluye depósitos manuales, retiros,
  /// transferencias, refunds, ajustes, etc).
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

    final result = await repository.listMovements(
      account.value!.id,
      startDate: startDate.value,
      endDate: endDate.value,
      page: currentPage.value,
      limit: pageSize.value,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
      },
      (page) {
        // Mapear movements → BankAccountTransaction para reusar la UI existente.
        // Filtrado por search en cliente (el endpoint del backend aún no lo soporta).
        final mapped = page.items
            .map(_movementToTransaction)
            .where((tx) {
              final q = searchQuery.value.trim().toLowerCase();
              if (q.isEmpty) return true;
              return tx.description.toLowerCase().contains(q) ||
                  (tx.notes?.toLowerCase().contains(q) ?? false);
            })
            .toList();

        if (refresh) {
          transactions.value = mapped;
        } else {
          transactions.addAll(mapped);
        }

        // Actualizar info de cuenta + paginación + summary.
        final acc = account.value!;
        accountInfo.value = TransactionAccountInfo(
          id: acc.id,
          name: acc.name,
          type: acc.type.value,
          currentBalance: acc.currentBalance,
          bankName: acc.bankName,
          accountNumber: acc.accountNumber,
        );

        pagination.value = TransactionsPagination(
          page: page.page,
          limit: page.limit,
          total: page.total,
          totalPages:
              page.limit > 0 ? ((page.total + page.limit - 1) ~/ page.limit) : 1,
        );

        // Summary: total income = suma de inflows (depósitos + invoice/credit
        // payment + transfer in). Promedio sobre transactions visibles.
        final totalIncome = mapped
            .where((tx) => tx.amount > 0)
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);
        summary.value = TransactionsSummary(
          totalIncome: totalIncome,
          transactionCount: mapped.length,
          periodStart: startDate.value,
          periodEnd: endDate.value,
          averageTransaction:
              mapped.isNotEmpty ? totalIncome / mapped.length : 0.0,
        );
      },
    );

    isLoading.value = false;
  }

  /// Convierte un movement de la BD nueva al formato legacy de la UI.
  /// Los campos `customer` e `invoice` se quedan en null porque el endpoint
  /// de movements no los hidrata; cuando el usuario quiera detalle de la
  /// factura puede tocar el item y abrir esa pantalla.
  BankAccountTransaction _movementToTransaction(BankAccountMovement m) {
    final isInflow = m.signedAmount > 0;
    final signedAmount = m.signedAmount;

    String description;
    TransactionType txType;
    switch (m.type) {
      case BankAccountMovementType.invoicePayment:
        description = m.description ?? 'Pago de factura';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.creditPayment:
        description = m.description ?? 'Abono a crédito';
        txType = TransactionType.creditPayment;
        break;
      case BankAccountMovementType.deposit:
        description = m.description ?? 'Depósito manual';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.withdrawal:
        description = m.description ?? 'Retiro manual';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.transferIn:
        description = m.description ?? 'Transferencia entrada';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.transferOut:
        description = m.description ?? 'Transferencia salida';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.expensePayment:
        description = m.description ?? 'Pago de gasto';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.refund:
        description = m.description ?? 'Reembolso';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.adjustment:
        description = m.description ?? 'Ajuste manual';
        txType = TransactionType.invoicePayment;
        break;
      case BankAccountMovementType.initialBalance:
        description = m.description ?? 'Saldo inicial';
        txType = TransactionType.invoicePayment;
        break;
    }

    return BankAccountTransaction(
      id: m.id,
      date: m.movementDate,
      type: txType,
      amount: signedAmount,
      paymentMethod: m.type.displayName,
      description: description,
      notes: 'Saldo: \$${m.balanceAfter.toStringAsFixed(2)}'
          '${isInflow ? '' : ''}',
    );
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

  // ==================== MANUAL MOVEMENT ACTIONS ====================

  /// Registrar un depósito manual en la cuenta actual.
  /// Devuelve true si se registró (online o offline). Si falla, llena
  /// `errorMessage` con detalle.
  Future<bool> submitDeposit({
    required double amount,
    String? description,
    DateTime? movementDate,
  }) async {
    if (account.value == null) return false;
    final result = await repository.depositManual(
      bankAccountId: account.value!.id,
      amount: amount,
      description: description,
      movementDate: movementDate,
    );
    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: const Color(0xFFFFFFFF),
        );
        return false;
      },
      (_) {
        // Refrescar saldo de la cuenta + lista de movements.
        _refreshAccount();
        loadTransactions(refresh: true);
        return true;
      },
    );
  }

  /// Registrar un retiro manual de la cuenta actual.
  Future<bool> submitWithdrawal({
    required double amount,
    String? description,
    DateTime? movementDate,
  }) async {
    if (account.value == null) return false;
    final result = await repository.withdrawManual(
      bankAccountId: account.value!.id,
      amount: amount,
      description: description,
      movementDate: movementDate,
    );
    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: const Color(0xFFFFFFFF),
        );
        return false;
      },
      (_) {
        _refreshAccount();
        loadTransactions(refresh: true);
        return true;
      },
    );
  }

  /// Re-leer la cuenta para reflejar el saldo nuevo en la pantalla.
  Future<void> _refreshAccount() async {
    if (account.value == null) return;
    final result = await repository.getBankAccountById(account.value!.id);
    result.fold((_) {}, (acc) => account.value = acc);
  }

  // ==================== CLEANUP ====================

  @override
  void onClose() {
    transactions.clear();
    super.onClose();
  }
}
