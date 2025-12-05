// lib/app/shared/widgets/bank_account_selector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/bank_accounts/domain/entities/bank_account.dart';
import '../../../features/bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../../features/bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import '../../core/theme/elegant_light_theme.dart';
import '../../core/utils/responsive.dart';

/// Widget reutilizable para seleccionar cuentas bancarias del tenant
/// Muestra un dropdown con las cuentas registradas (nombre + últimos 4 dígitos)
class BankAccountSelector extends StatefulWidget {
  /// Cuenta seleccionada actualmente
  final BankAccount? selectedAccount;

  /// Callback cuando se selecciona una cuenta
  final ValueChanged<BankAccount?> onAccountSelected;

  /// Filtrar por tipos de cuenta específicos (null = todos)
  final List<BankAccountType>? filterByTypes;

  /// Si mostrar solo cuentas activas
  final bool onlyActive;

  /// Si mostrar opción "Sin cuenta específica"
  final bool showNoneOption;

  /// Texto del placeholder
  final String? hintText;

  /// Si el campo es requerido (para validación)
  final bool isRequired;

  const BankAccountSelector({
    super.key,
    this.selectedAccount,
    required this.onAccountSelected,
    this.filterByTypes,
    this.onlyActive = true,
    this.showNoneOption = false,
    this.hintText,
    this.isRequired = true,
  });

  @override
  State<BankAccountSelector> createState() => _BankAccountSelectorState();
}

class _BankAccountSelectorState extends State<BankAccountSelector> {
  BankAccountsController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // Registrar binding si no existe
    if (!Get.isRegistered<BankAccountsController>()) {
      BankAccountsBinding().dependencies();
    }

    // Obtener el controlador
    if (Get.isRegistered<BankAccountsController>()) {
      _controller = Get.find<BankAccountsController>();

      // Si ya terminó de cargar y hay cuentas, seleccionar la default
      if (!_controller!.isLoading.value && _controller!.bankAccounts.isNotEmpty) {
        _selectDefaultIfNeeded();
      }
    }
  }

  void _selectDefaultIfNeeded() {
    if (widget.selectedAccount == null && _filteredAccounts.isNotEmpty) {
      final defaultAccount = _filteredAccounts.where((a) => a.isDefault).firstOrNull;
      if (defaultAccount != null) {
        // Usar addPostFrameCallback para evitar setState durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onAccountSelected(defaultAccount);
          }
        });
      }
    }
  }

  List<BankAccount> get _filteredAccounts {
    if (_controller == null) return [];

    List<BankAccount> accounts = widget.onlyActive
        ? _controller!.activeAccounts
        : _controller!.bankAccounts;

    if (widget.filterByTypes != null && widget.filterByTypes!.isNotEmpty) {
      accounts = accounts.where((a) => widget.filterByTypes!.contains(a.type)).toList();
    }

    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_controller == null) {
      return _buildErrorState(isMobile, 'Controlador no disponible');
    }

    // Usar Obx para reactividad con el controlador
    return Obx(() {
      // Estado de carga
      if (_controller!.isLoading.value) {
        return _buildLoadingIndicator(isMobile);
      }

      // Estado de error
      if (_controller!.hasError.value) {
        return _buildErrorState(isMobile, _controller!.errorMessage.value);
      }

      final accounts = _filteredAccounts;

      // Sin cuentas
      if (accounts.isEmpty) {
        return _buildEmptyState(isMobile);
      }

      // Seleccionar cuenta por defecto si no hay seleccionada
      if (widget.selectedAccount == null) {
        _selectDefaultIfNeeded();
      }

      return _buildDropdown(accounts, isMobile);
    });
  }

  Widget _buildLoadingIndicator(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Cargando cuentas...',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isMobile, String message) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: isMobile ? 18 : 20,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.isNotEmpty ? message : 'Error cargando cuentas',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: Colors.red.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _controller?.loadBankAccounts(refresh: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: isMobile ? 18 : 20,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No hay cuentas registradas',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<BankAccount> accounts, bool isMobile) {
    final fontSize = isMobile ? 13.0 : 14.0;
    final iconSize = isMobile ? 18.0 : 20.0;

    return DropdownButtonFormField<BankAccount?>(
      value: widget.selectedAccount,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: ElegantLightTheme.textSecondary,
        size: iconSize + 4,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
      hint: Text(
        widget.hintText ?? 'Seleccionar cuenta',
        style: TextStyle(
          fontSize: fontSize,
          color: ElegantLightTheme.textTertiary,
        ),
      ),
      items: [
        if (widget.showNoneOption)
          DropdownMenuItem<BankAccount?>(
            value: null,
            child: Row(
              children: [
                Icon(
                  Icons.money_off,
                  size: iconSize,
                  color: ElegantLightTheme.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sin cuenta específica',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ...accounts.map((account) {
          final accountDisplay = _buildAccountDisplayText(account);
          final accountColor = _getAccountColor(account);

          return DropdownMenuItem<BankAccount?>(
            value: account,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accountColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getAccountIcon(account),
                    size: iconSize - 2,
                    color: accountColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    accountDisplay,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (account.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: isMobile ? 10 : 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        widget.onAccountSelected(value);
      },
      validator: widget.isRequired
          ? (value) {
              if (value == null && !widget.showNoneOption) {
                return 'Seleccione una cuenta de pago';
              }
              return null;
            }
          : null,
      dropdownColor: Colors.white,
      menuMaxHeight: 300,
    );
  }

  String _buildAccountDisplayText(BankAccount account) {
    if (account.accountNumber != null && account.accountNumber!.length >= 4) {
      final lastFour = account.accountNumber!.substring(account.accountNumber!.length - 4);
      return '${account.name} ****$lastFour';
    }
    return account.name;
  }

  IconData _getAccountIcon(BankAccount account) {
    final name = account.name.toLowerCase();
    if (name.contains('nequi')) return Icons.phone_android;
    if (name.contains('daviplata')) return Icons.smartphone;
    if (name.contains('bancolombia')) return Icons.account_balance;
    if (name.contains('efecty')) return Icons.store;
    return account.type.icon;
  }

  Color _getAccountColor(BankAccount account) {
    final name = account.name.toLowerCase();
    if (name.contains('nequi')) return const Color(0xFF00C9B7);
    if (name.contains('daviplata')) return const Color(0xFFE4002B);
    if (name.contains('bancolombia')) return const Color(0xFFFDDA24);
    if (name.contains('efecty')) return const Color(0xFFFFD100);

    switch (account.type) {
      case BankAccountType.cash:
        return Colors.green;
      case BankAccountType.savings:
        return Colors.blue;
      case BankAccountType.checking:
        return Colors.indigo;
      case BankAccountType.digitalWallet:
        return Colors.teal;
      case BankAccountType.creditCard:
        return Colors.purple;
      case BankAccountType.debitCard:
        return Colors.orange;
      case BankAccountType.other:
        return ElegantLightTheme.primaryBlue;
    }
  }
}

/// Extensión para obtener el PaymentMethod desde un BankAccount
extension BankAccountPaymentMethod on BankAccount {
  String get paymentMethodValue {
    switch (type) {
      case BankAccountType.cash:
        return 'cash';
      case BankAccountType.creditCard:
        return 'credit_card';
      case BankAccountType.debitCard:
        return 'debit_card';
      case BankAccountType.digitalWallet:
      case BankAccountType.savings:
      case BankAccountType.checking:
        return 'bank_transfer';
      case BankAccountType.other:
        return 'other';
    }
  }
}
