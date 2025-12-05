// lib/features/bank_accounts/presentation/controllers/bank_accounts_controller.dart
import 'package:get/get.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/bank_account_repository.dart';

/// Controlador para la gestión de cuentas bancarias
class BankAccountsController extends GetxController {
  final BankAccountRepository repository;

  BankAccountsController({required this.repository});

  // ==================== STATE ====================

  final RxList<BankAccount> bankAccounts = <BankAccount>[].obs;
  final Rx<BankAccount?> selectedAccount = Rx<BankAccount?>(null);
  final Rx<BankAccount?> defaultAccount = Rx<BankAccount?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Filtros
  final Rx<BankAccountType?> filterType = Rx<BankAccountType?>(null);
  final RxBool showInactive = false.obs;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    loadBankAccounts();
  }

  // ==================== GETTERS ====================

  /// Cuentas filtradas
  List<BankAccount> get filteredAccounts {
    var filtered = bankAccounts.toList();

    // Filtrar por tipo
    if (filterType.value != null) {
      filtered = filtered.where((a) => a.type == filterType.value).toList();
    }

    // Filtrar por activo
    if (!showInactive.value) {
      filtered = filtered.where((a) => a.isActive).toList();
    }

    return filtered;
  }

  /// Cuentas activas solamente
  List<BankAccount> get activeAccounts =>
      bankAccounts.where((a) => a.isActive).toList();

  /// Tiene cuentas
  bool get hasAccounts => bankAccounts.isNotEmpty;

  /// Tiene cuenta predeterminada
  bool get hasDefaultAccount => defaultAccount.value != null;

  // ==================== METHODS ====================

  /// Cargar todas las cuentas bancarias
  Future<void> loadBankAccounts({bool refresh = false}) async {
    if (isLoading.value && !refresh) return;

    isLoading.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.getBankAccounts(
      includeInactive: showInactive.value,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
      },
      (accounts) {
        bankAccounts.value = accounts;
        // Actualizar cuenta predeterminada
        defaultAccount.value = accounts.where((a) => a.isDefault).firstOrNull;
      },
    );

    isLoading.value = false;
  }

  /// Cargar cuentas activas
  Future<void> loadActiveAccounts() async {
    isLoading.value = true;

    final result = await repository.getActiveBankAccounts();

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
      },
      (accounts) {
        bankAccounts.value = accounts;
        defaultAccount.value = accounts.where((a) => a.isDefault).firstOrNull;
      },
    );

    isLoading.value = false;
  }

  /// Crear nueva cuenta bancaria
  Future<bool> createBankAccount({
    required String name,
    required BankAccountType type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool isActive = true,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
  }) async {
    isCreating.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.createBankAccount(
      name: name,
      type: type,
      bankName: bankName,
      accountNumber: accountNumber,
      holderName: holderName,
      icon: icon,
      isActive: isActive,
      isDefault: isDefault,
      sortOrder: sortOrder,
      description: description,
    );

    isCreating.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
        return false;
      },
      (account) {
        bankAccounts.add(account);
        if (account.isDefault) {
          // Quitar isDefault de las demás en la lista local
          bankAccounts.value = bankAccounts.map((a) {
            if (a.id != account.id && a.isDefault) {
              return a.copyWith(isDefault: false);
            }
            return a;
          }).toList();
          defaultAccount.value = account;
        }
        return true;
      },
    );
  }

  /// Actualizar cuenta bancaria
  Future<bool> updateBankAccount({
    required String id,
    String? name,
    BankAccountType? type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    String? description,
  }) async {
    isUpdating.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.updateBankAccount(
      id: id,
      name: name,
      type: type,
      bankName: bankName,
      accountNumber: accountNumber,
      holderName: holderName,
      icon: icon,
      isActive: isActive,
      isDefault: isDefault,
      sortOrder: sortOrder,
      description: description,
    );

    isUpdating.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
        return false;
      },
      (updatedAccount) {
        final index = bankAccounts.indexWhere((a) => a.id == id);
        if (index != -1) {
          bankAccounts[index] = updatedAccount;
        }
        if (updatedAccount.isDefault) {
          // Actualizar defaultAccount y quitar flag de otras
          bankAccounts.value = bankAccounts.map((a) {
            if (a.id != id && a.isDefault) {
              return a.copyWith(isDefault: false);
            }
            return a;
          }).toList();
          defaultAccount.value = updatedAccount;
        }
        return true;
      },
    );
  }

  /// Eliminar cuenta bancaria
  Future<bool> deleteBankAccount(String id) async {
    isDeleting.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.deleteBankAccount(id);

    isDeleting.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
        return false;
      },
      (_) {
        bankAccounts.removeWhere((a) => a.id == id);
        if (defaultAccount.value?.id == id) {
          defaultAccount.value =
              bankAccounts.where((a) => a.isDefault).firstOrNull;
        }
        return true;
      },
    );
  }

  /// Establecer cuenta como predeterminada
  Future<bool> setDefaultAccount(String id) async {
    isUpdating.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.setDefaultBankAccount(id);

    isUpdating.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
        return false;
      },
      (account) {
        // Actualizar todas las cuentas en la lista
        bankAccounts.value = bankAccounts.map((a) {
          if (a.id == id) {
            return account;
          } else if (a.isDefault) {
            return a.copyWith(isDefault: false);
          }
          return a;
        }).toList();
        defaultAccount.value = account;
        return true;
      },
    );
  }

  /// Activar/desactivar cuenta
  Future<bool> toggleAccountActive(String id) async {
    isUpdating.value = true;
    errorMessage.value = '';
    hasError.value = false;

    final result = await repository.toggleBankAccountActive(id);

    isUpdating.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        hasError.value = true;
        return false;
      },
      (account) {
        final index = bankAccounts.indexWhere((a) => a.id == id);
        if (index != -1) {
          bankAccounts[index] = account;
        }
        return true;
      },
    );
  }

  /// Seleccionar cuenta
  void selectAccount(BankAccount? account) {
    selectedAccount.value = account;
  }

  /// Limpiar selección
  void clearSelection() {
    selectedAccount.value = null;
  }

  /// Actualizar filtro de tipo
  void setFilterType(BankAccountType? type) {
    filterType.value = type;
  }

  /// Actualizar mostrar inactivos
  void setShowInactive(bool show) {
    showInactive.value = show;
    loadBankAccounts();
  }

  /// Limpiar error
  void clearError() {
    errorMessage.value = '';
    hasError.value = false;
  }

  /// Refrescar datos
  @override
  Future<void> refresh() => loadBankAccounts(refresh: true);
}
