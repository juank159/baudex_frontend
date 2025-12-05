// lib/features/customer_credits/presentation/controllers/customer_credit_controller.dart

import 'package:get/get.dart';
import '../../../invoices/presentation/controllers/invoice_list_controller.dart';
import '../../data/models/customer_credit_model.dart';
import '../../data/repositories/customer_credit_repository_impl.dart';
import '../../domain/entities/customer_credit.dart';

/// Controlador para gestión de créditos de clientes
class CustomerCreditController extends GetxController {
  final CustomerCreditRepository repository;

  CustomerCreditController({
    required this.repository,
  });

  // Estados observables - Créditos
  final RxList<CustomerCredit> credits = <CustomerCredit>[].obs;
  final Rx<CustomerCredit?> selectedCredit = Rx<CustomerCredit?>(null);
  final Rx<CreditStats?> stats = Rx<CreditStats?>(null);
  final RxList<CreditPayment> currentCreditPayments = <CreditPayment>[].obs;
  final RxList<CreditTransactionModel> currentCreditTransactions = <CreditTransactionModel>[].obs;

  // Estados observables - Saldos a Favor
  final RxList<ClientBalanceModel> clientBalances = <ClientBalanceModel>[].obs;
  final Rx<ClientBalanceModel?> selectedClientBalance = Rx<ClientBalanceModel?>(null);
  final RxList<ClientBalanceTransactionModel> currentBalanceTransactions = <ClientBalanceTransactionModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingStats = false.obs;
  final RxBool isLoadingBalances = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString errorMessage = ''.obs;

  // Filtros
  final Rx<String?> selectedCustomerId = Rx<String?>(null);
  final Rx<CreditStatus?> selectedStatus = Rx<CreditStatus?>(null);
  final RxBool showOverdueOnly = false.obs;
  final RxBool includeCancelled = false.obs;

  // Búsqueda
  final RxString searchQuery = ''.obs;

  // Flag para saber si ya se cargaron los datos iniciales
  bool _initialLoadDone = false;

  @override
  void onInit() {
    super.onInit();
    // Carga inicial de datos
    _initialLoad();
  }

  @override
  void onReady() {
    super.onReady();
    // Si por alguna razón no se cargaron en onInit, cargar en onReady
    if (!_initialLoadDone && credits.isEmpty) {
      _initialLoad();
    }
  }

  /// Carga inicial de datos (créditos y estadísticas en paralelo)
  Future<void> _initialLoad() async {
    if (_initialLoadDone && credits.isNotEmpty) return;

    _initialLoadDone = true;
    await Future.wait([
      loadCredits(),
      loadStats(),
    ]);
  }

  /// Refresca todos los datos (para usar cuando la página vuelve a ser visible)
  Future<void> refreshAllData() async {
    await Future.wait([
      loadCredits(),
      loadStats(),
    ]);
  }

  /// Asegura que los datos estén cargados (llamar desde las páginas)
  Future<void> ensureDataLoaded() async {
    if (credits.isEmpty && !isLoading.value) {
      await refreshAllData();
    }
  }

  /// Carga todos los créditos con los filtros actuales
  Future<void> loadCredits() async {
    isLoading.value = true;
    errorMessage.value = '';

    final query = CustomerCreditQueryParams(
      customerId: selectedCustomerId.value,
      status: selectedStatus.value?.value,
      overdueOnly: showOverdueOnly.value ? true : null,
      includeCancelled: includeCancelled.value ? true : null,
    );

    final result = await repository.getCredits(query);

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        credits.clear();
      },
      (data) {
        credits.assignAll(data);
        // Recalcular estadísticas si no tenemos datos del API
        _updateStatsFromCredits();
      },
    );

    isLoading.value = false;
  }

  /// Carga las estadísticas de créditos
  Future<void> loadStats() async {
    isLoadingStats.value = true;

    final result = await repository.getCreditStats();

    result.fold(
      (failure) {
        // Si falla la API, calcular estadísticas localmente desde los créditos cargados
        _calculateLocalStats();
      },
      (data) {
        stats.value = data;
      },
    );

    isLoadingStats.value = false;
  }

  /// Calcula estadísticas localmente desde la lista de créditos cargados
  void _calculateLocalStats() {
    double totalPending = 0;
    double totalOverdue = 0;
    double totalPaid = 0;
    int countPending = 0;
    int countOverdue = 0;

    for (final credit in credits) {
      // Sumar siempre lo que ya se ha pagado
      totalPaid += credit.paidAmount;

      // Clasificar por estado
      if (credit.status == CreditStatus.paid) {
        // Crédito completamente pagado - no hay saldo pendiente
        continue;
      } else if (credit.status == CreditStatus.cancelled) {
        // Crédito cancelado - ignorar
        continue;
      } else if (credit.status == CreditStatus.overdue || credit.isOverdue) {
        // Crédito vencido
        totalOverdue += credit.balanceDue;
        countOverdue++;
      } else {
        // Crédito pendiente o parcialmente pagado (no vencido)
        totalPending += credit.balanceDue;
        countPending++;
      }
    }

    stats.value = CreditStats(
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      countPending: countPending,
      countOverdue: countOverdue,
      totalPaid: totalPaid,
    );
  }

  /// Recalcula estadísticas después de cargar créditos
  void _updateStatsFromCredits() {
    // Siempre recalcular las estadísticas locales para mantenerlas sincronizadas
    _calculateLocalStats();
  }

  /// Carga los créditos de un cliente específico
  Future<void> loadCreditsByCustomer(String customerId) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await repository.getCreditsByCustomer(customerId);

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        credits.clear();
      },
      (data) {
        credits.assignAll(data);
      },
    );

    isLoading.value = false;
  }

  /// Carga los créditos pendientes de un cliente
  Future<void> loadPendingCreditsByCustomer(String customerId) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await repository.getPendingCreditsByCustomer(customerId);

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        credits.clear();
      },
      (data) {
        credits.assignAll(data);
      },
    );

    isLoading.value = false;
  }

  /// Obtiene un crédito por ID
  Future<CustomerCredit?> getCreditById(String id) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await repository.getCreditById(id);

    CustomerCredit? credit;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
      },
      (data) {
        selectedCredit.value = data;
        credit = data;
      },
    );

    isLoading.value = false;
    return credit;
  }

  /// Crea un nuevo crédito
  /// El saldo a favor se aplica AUTOMÁTICAMENTE por defecto.
  /// Si [skipAutoBalance] es true, NO se aplicará el saldo automáticamente.
  /// [useClientBalance] está deprecated - el saldo ahora se aplica automáticamente.
  Future<CustomerCredit?> createCredit({
    required String customerId,
    required double amount,
    String? dueDate,
    String? description,
    String? notes,
    String? invoiceId,
    @Deprecated('El saldo ahora se aplica automáticamente. Usa skipAutoBalance para evitarlo.')
    bool useClientBalance = false,
    bool skipAutoBalance = false,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = CreateCustomerCreditDto(
      customerId: customerId,
      originalAmount: amount,
      dueDate: dueDate,
      description: description,
      notes: notes,
      invoiceId: invoiceId,
      skipAutoBalance: skipAutoBalance,
    );

    final result = await repository.createCredit(dto);

    CustomerCredit? newCredit;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        newCredit = data;
        String message = 'Se creó un crédito por \$${amount.toStringAsFixed(0)}';
        if (data.paidAmount > 0) {
          message += '. Se aplicó saldo a favor: \$${data.paidAmount.toStringAsFixed(0)}';
        }
        Get.snackbar(
          'Crédito creado',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isProcessing.value = false;

    // Si fue exitoso, recargar datos en segundo plano (sin bloquear)
    if (newCredit != null) {
      Future.wait([
        loadCredits(),
        loadStats(),
        loadClientBalances(),
      ]);
    }

    return newCredit;
  }

  /// Agrega un pago a un crédito
  /// NOTA: El backend YA sincroniza automáticamente con la factura asociada
  /// NO debemos duplicar el pago desde el frontend
  Future<bool> addPayment({
    required String creditId,
    required double amount,
    required String paymentMethod,
    String? paymentDate,
    String? reference,
    String? notes,
    String? bankAccountId,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    // Guardar el invoiceId del crédito antes de procesar el pago
    final creditBeforePayment = credits.firstWhereOrNull((c) => c.id == creditId);
    final String? invoiceId = creditBeforePayment?.invoiceId;

    final dto = AddCreditPaymentDto(
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      bankAccountId: bankAccountId,
    );

    final result = await repository.addPayment(creditId, dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedCredit.value = data;
      },
    );

    // Si fue exitoso, recargar datos completos para sincronización
    if (success) {
      await Future.wait([
        loadCredits(),
        loadStats(),
      ]);
      // Notificar factura si tiene una asociada
      if (invoiceId != null) {
        _notifyInvoiceUpdate(invoiceId);
      }
    }

    isProcessing.value = false;
    return success;
  }

  /// Notifica que una factura debe actualizarse después de un pago de crédito
  /// El backend ya sincronizó el pago, solo marcamos para refrescar la UI
  void _notifyInvoiceUpdate(String invoiceId) {
    InvoiceListController.markInvoiceRefreshNeeded();
  }

  /// Obtiene los pagos de un crédito
  Future<void> loadCreditPayments(String creditId) async {
    final result = await repository.getCreditPayments(creditId);

    result.fold(
      (failure) {
        currentCreditPayments.clear();
      },
      (data) {
        currentCreditPayments.assignAll(data);
      },
    );
  }

  /// Cancela un crédito
  Future<bool> cancelCredit(String creditId) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final result = await repository.cancelCredit(creditId);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        if (selectedCredit.value?.id == creditId) {
          selectedCredit.value = data;
        }
        Get.snackbar(
          'Crédito cancelado',
          'El crédito ha sido cancelado exitosamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    // Si fue exitoso, recargar datos completos
    if (success) {
      await Future.wait([
        loadCredits(),
        loadStats(),
      ]);
    }

    isProcessing.value = false;
    return success;
  }

  /// Elimina un crédito (soft delete)
  Future<bool> deleteCredit(String creditId) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final result = await repository.deleteCredit(creditId);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (_) {
        success = true;
        if (selectedCredit.value?.id == creditId) {
          selectedCredit.value = null;
        }
        Get.snackbar(
          'Crédito eliminado',
          'El crédito ha sido eliminado exitosamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    // Si fue exitoso, recargar datos completos
    if (success) {
      await Future.wait([
        loadCredits(),
        loadStats(),
      ]);
    }

    isProcessing.value = false;
    return success;
  }

  /// Marca los créditos vencidos
  Future<int> markOverdueCredits() async {
    isProcessing.value = true;

    final result = await repository.markOverdueCredits();

    int count = 0;
    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        count = data;
        if (data > 0) {
          loadCredits();
          loadStats();
          Get.snackbar(
            'Créditos actualizados',
            'Se marcaron $data créditos como vencidos',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );

    isProcessing.value = false;
    return count;
  }

  // ==================== Métodos de filtrado ====================

  /// Aplica filtro por cliente
  void filterByCustomer(String? customerId) {
    selectedCustomerId.value = customerId;
    loadCredits();
  }

  /// Aplica filtro por estado (mutuamente excluyente con showOverdueOnly)
  void filterByStatus(CreditStatus? status) {
    // Limpiar filtro de vencidos para que sea mutuamente excluyente
    showOverdueOnly.value = false;
    selectedStatus.value = status;
    loadCredits();
  }

  /// Activa filtro de solo vencidos (mutuamente excluyente con selectedStatus)
  void filterByOverdue() {
    // Limpiar filtro de estado para que sea mutuamente excluyente
    selectedStatus.value = null;
    showOverdueOnly.value = true;
    loadCredits();
  }

  /// Activa/desactiva filtro de solo vencidos (legacy - usar filterByOverdue preferiblemente)
  void toggleOverdueOnly() {
    if (showOverdueOnly.value) {
      // Si ya estaba activo, limpiar todos los filtros
      clearFilters();
    } else {
      filterByOverdue();
    }
  }

  /// Activa/desactiva inclusión de cancelados
  void toggleIncludeCancelled() {
    includeCancelled.value = !includeCancelled.value;
    loadCredits();
  }

  /// Limpia todos los filtros
  void clearFilters() {
    selectedCustomerId.value = null;
    selectedStatus.value = null;
    showOverdueOnly.value = false;
    includeCancelled.value = false;
    loadCredits();
  }

  /// Verifica si hay algún filtro activo
  bool get hasActiveFilters =>
      selectedStatus.value != null || showOverdueOnly.value || selectedCustomerId.value != null;

  // ==================== Getters computados ====================

  /// Créditos filtrados por búsqueda
  List<CustomerCredit> get filteredCredits {
    if (searchQuery.value.isEmpty) {
      return credits;
    }
    final query = searchQuery.value.toLowerCase();
    return credits.where((credit) {
      final customerName = credit.customerName?.toLowerCase() ?? '';
      final description = credit.description?.toLowerCase() ?? '';
      final invoiceNumber = credit.invoiceNumber?.toLowerCase() ?? '';
      return customerName.contains(query) ||
          description.contains(query) ||
          invoiceNumber.contains(query);
    }).toList();
  }

  /// Contador de todos los créditos
  int get allCreditsCount => credits.length;

  /// Contador de créditos pendientes (incluye pendientes y parcialmente pagados)
  int get pendingCreditsCount =>
      credits.where((c) => c.status == CreditStatus.pending || c.status == CreditStatus.partiallyPaid).length;

  /// Contador de créditos pagados
  int get paidCreditsCount =>
      credits.where((c) => c.status == CreditStatus.paid).length;

  /// Contador de créditos vencidos
  int get overdueCreditsCount =>
      credits.where((c) => c.status == CreditStatus.overdue || c.isOverdue).length;

  /// Créditos pendientes
  List<CustomerCredit> get pendingCredits =>
      credits.where((c) => c.status == CreditStatus.pending || c.status == CreditStatus.partiallyPaid).toList();

  /// Créditos vencidos
  List<CustomerCredit> get overdueCredits =>
      credits.where((c) => c.status == CreditStatus.overdue || c.isOverdue).toList();

  /// Total de saldo pendiente
  double get totalPendingBalance =>
      credits.where((c) => c.canReceivePayment).fold(0.0, (sum, c) => sum + c.balanceDue);

  /// Número de créditos activos
  int get activeCreditsCount =>
      credits.where((c) => c.canReceivePayment).length;

  /// Actualiza el término de búsqueda
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Limpia la búsqueda
  void clearSearch() {
    searchQuery.value = '';
  }

  // ==================== Métodos de Transacciones de Crédito ====================

  /// Carga las transacciones de un crédito específico
  Future<void> loadCreditTransactions(String creditId) async {
    final result = await repository.getCreditTransactions(creditId);

    result.fold(
      (failure) {
        currentCreditTransactions.clear();
      },
      (data) {
        currentCreditTransactions.assignAll(data);
      },
    );
  }

  /// Agrega monto a un crédito existente (aumentar deuda)
  Future<bool> addAmountToCredit({
    required String creditId,
    required double amount,
    required String description,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = AddAmountToCreditDto(
      amount: amount,
      description: description,
    );

    final result = await repository.addAmountToCredit(creditId, dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedCredit.value = data;
        Get.snackbar(
          'Monto agregado',
          'Se agregó \$${amount.toStringAsFixed(0)} al crédito',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isProcessing.value = false;

    // Si fue exitoso, recargar datos en segundo plano (sin bloquear)
    if (success) {
      Future.wait([
        loadCredits(),
        loadStats(),
      ]);
    }

    return success;
  }

  /// Aplica saldo a favor a un crédito existente
  Future<bool> applyBalanceToCredit({
    required String creditId,
    double? amount,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = ApplyBalanceToCreditDto(amount: amount);

    final result = await repository.applyBalanceToCredit(creditId, dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedCredit.value = data;
        Get.snackbar(
          'Saldo aplicado',
          'Se aplicó saldo a favor al crédito',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    // Si fue exitoso, recargar datos completos
    if (success) {
      await Future.wait([
        loadCredits(),
        loadStats(),
        loadClientBalances(),
      ]);
    }

    isProcessing.value = false;
    return success;
  }

  // ==================== Métodos de Saldo a Favor ====================

  /// Carga todos los saldos a favor
  Future<void> loadClientBalances() async {
    isLoadingBalances.value = true;

    final result = await repository.getAllClientBalances();

    result.fold(
      (failure) {
        clientBalances.clear();
      },
      (data) {
        clientBalances.assignAll(data);
      },
    );

    isLoadingBalances.value = false;
  }

  /// Obtiene el saldo a favor de un cliente específico
  Future<ClientBalanceModel?> getClientBalance(String customerId) async {
    final result = await repository.getClientBalance(customerId);

    ClientBalanceModel? balance;
    result.fold(
      (failure) {
        selectedClientBalance.value = null;
      },
      (data) {
        selectedClientBalance.value = data;
        balance = data;
      },
    );

    return balance;
  }

  /// Carga las transacciones de saldo de un cliente
  Future<void> loadBalanceTransactions(String customerId) async {
    final result = await repository.getClientBalanceTransactions(customerId);

    result.fold(
      (failure) {
        currentBalanceTransactions.clear();
      },
      (data) {
        currentBalanceTransactions.assignAll(data);
      },
    );
  }

  /// Deposita saldo a favor de un cliente
  Future<bool> depositBalance({
    required String customerId,
    required double amount,
    required String description,
    String? relatedCreditId,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = DepositBalanceDto(
      customerId: customerId,
      amount: amount,
      description: description,
      relatedCreditId: relatedCreditId,
    );

    final result = await repository.depositBalance(dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedClientBalance.value = data;
        loadClientBalances();
        Get.snackbar(
          'Saldo depositado',
          'Se depositó \$${amount.toStringAsFixed(0)} como saldo a favor',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isProcessing.value = false;
    return success;
  }

  /// Reembolsa saldo a favor (devolver dinero al cliente)
  Future<bool> refundBalance({
    required String customerId,
    required double amount,
    required String description,
    required String paymentMethod,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = RefundBalanceDto(
      clientId: customerId,
      amount: amount,
      description: description,
      paymentMethod: paymentMethod,
    );

    final result = await repository.refundBalance(dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedClientBalance.value = data;
        loadClientBalances();
        Get.snackbar(
          'Saldo reembolsado',
          'Se reembolsó \$${amount.toStringAsFixed(0)} al cliente',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isProcessing.value = false;
    return success;
  }

  /// Ajusta saldo manualmente (corrección administrativa)
  Future<bool> adjustBalance({
    required String customerId,
    required double amount,
    required String description,
  }) async {
    isProcessing.value = true;
    errorMessage.value = '';

    final dto = AdjustBalanceDto(
      clientId: customerId,
      amount: amount,
      description: description,
    );

    final result = await repository.adjustBalance(dto);

    bool success = false;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (data) {
        success = true;
        selectedClientBalance.value = data;
        loadClientBalances();
        final action = amount > 0 ? 'aumentó' : 'redujo';
        Get.snackbar(
          'Saldo ajustado',
          'Se $action el saldo en \$${amount.abs().toStringAsFixed(0)}',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isProcessing.value = false;
    return success;
  }

  // ==================== Getters computados - Saldos ====================

  /// Total de saldos a favor
  double get totalClientBalances =>
      clientBalances.fold(0.0, (sum, b) => sum + b.balance);

  /// Número de clientes con saldo a favor
  int get clientsWithBalanceCount => clientBalances.length;

  // ==================== Cuenta Corriente del Cliente ====================

  /// Estado observable para cuenta corriente
  final Rx<CustomerAccountModel?> customerAccount = Rx<CustomerAccountModel?>(null);
  final RxBool isLoadingAccount = false.obs;

  /// Obtiene la cuenta corriente consolidada de un cliente
  Future<CustomerAccountModel?> getCustomerAccount(String customerId) async {
    isLoadingAccount.value = true;
    errorMessage.value = '';

    final result = await repository.getCustomerAccount(customerId);

    CustomerAccountModel? account;
    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        customerAccount.value = null;
      },
      (data) {
        customerAccount.value = data;
        account = data;
      },
    );

    isLoadingAccount.value = false;
    return account;
  }

  /// Refresca los datos de la cuenta corriente
  Future<void> refreshCustomerAccount() async {
    if (customerAccount.value != null) {
      await getCustomerAccount(customerAccount.value!.customer.id);
    }
  }

  /// Limpia la cuenta corriente seleccionada
  void clearCustomerAccount() {
    customerAccount.value = null;
  }

  // ==================== Agrupación por Cliente ====================

  /// Agrupa los créditos por cliente para mostrar una card por cliente
  List<CustomerCreditSummary> get creditsByCustomer {
    // Agrupar créditos por customerId
    final Map<String, List<CustomerCreditModel>> grouped = {};

    for (final credit in credits) {
      final customerId = credit.customerId;
      if (!grouped.containsKey(customerId)) {
        grouped[customerId] = [];
      }
      grouped[customerId]!.add(credit as CustomerCreditModel);
    }

    // Convertir a lista de CustomerCreditSummary
    final summaries = grouped.entries
        .map((entry) => CustomerCreditSummary.fromCredits(entry.value))
        .toList();

    // Ordenar por saldo pendiente (mayor primero) y luego por nombre
    summaries.sort((a, b) {
      // Primero los que tienen deuda pendiente
      if (a.totalBalanceDue > 0 && b.totalBalanceDue <= 0) return -1;
      if (b.totalBalanceDue > 0 && a.totalBalanceDue <= 0) return 1;

      // Luego por monto pendiente (mayor primero)
      final byBalance = b.totalBalanceDue.compareTo(a.totalBalanceDue);
      if (byBalance != 0) return byBalance;

      // Finalmente por nombre
      return a.customerName.compareTo(b.customerName);
    });

    return summaries;
  }

  /// Créditos agrupados filtrados por búsqueda (para la lista principal)
  /// NOTA: El filtro por tipo de crédito (Directos/Facturas) se maneja
  /// localmente en CustomerAccountUnifiedPage, NO aquí
  List<CustomerCreditSummary> get filteredCreditsByCustomer {
    // Solo filtrar por búsqueda - muestra TODOS los créditos de cada cliente
    if (searchQuery.value.isEmpty) {
      return creditsByCustomer;
    }

    final query = searchQuery.value.toLowerCase();
    return creditsByCustomer.where((summary) {
      return summary.customerName.toLowerCase().contains(query);
    }).toList();
  }

  /// Obtiene el resumen de créditos de un cliente específico
  CustomerCreditSummary? getCustomerCreditSummary(String customerId) {
    final customerCredits = credits
        .where((c) => c.customerId == customerId)
        .map((c) => c as CustomerCreditModel)
        .toList();

    if (customerCredits.isEmpty) return null;
    return CustomerCreditSummary.fromCredits(customerCredits);
  }

  /// Obtiene el crédito directo pendiente de un cliente (sin factura asociada)
  /// Retorna null si no tiene ninguno
  Future<CustomerCredit?> getPendingDirectCreditByCustomer(String customerId) async {
    // Primero buscar en la lista local
    final localCredit = credits.firstWhereOrNull(
      (c) =>
          c.customerId == customerId &&
          c.invoiceId == null &&
          c.canReceivePayment,
    );

    if (localCredit != null) {
      return localCredit;
    }

    // Si no está en local, buscar en el servidor
    final result = await repository.getPendingCreditsByCustomer(customerId);

    return result.fold(
      (failure) => null,
      (credits) {
        // Buscar crédito directo (sin factura)
        final directCredit = credits.firstWhereOrNull(
          (c) => c.invoiceId == null && c.canReceivePayment,
        );
        return directCredit;
      },
    );
  }

  /// Número de clientes con créditos
  int get customersWithCreditsCount => creditsByCustomer.length;

  /// Número de clientes con deuda pendiente
  int get customersWithPendingDebtCount =>
      creditsByCustomer.where((s) => s.totalBalanceDue > 0).length;
}
