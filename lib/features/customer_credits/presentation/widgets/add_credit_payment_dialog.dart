// lib/features/customer_credits/presentation/widgets/add_credit_payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';

/// Diálogo elegante para agregar un abono a un crédito
class AddCreditPaymentDialog extends StatefulWidget {
  final CustomerCredit credit;

  const AddCreditPaymentDialog({
    super.key,
    required this.credit,
  });

  @override
  State<AddCreditPaymentDialog> createState() => _AddCreditPaymentDialogState();
}

class _AddCreditPaymentDialogState extends State<AddCreditPaymentDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  bool _payFullAmount = false; // Por defecto NO seleccionado
  bool _allowOverpayment = false;

  // ✅ Getter para detectar si el monto ingresado excede el saldo pendiente
  double get _enteredAmount => NumberInputFormatter.getNumericValue(_amountController.text) ?? 0;
  double get _overpaymentAmount => _enteredAmount - widget.credit.balanceDue;
  bool get _hasOverpayment => _enteredAmount > widget.credit.balanceDue;

  // Cuentas bancarias
  BankAccountsController? _bankAccountsController;
  BankAccount? _selectedBankAccount;
  bool _loadingBankAccounts = true;

  @override
  void initState() {
    super.initState();
    // Campo vacío por defecto, el usuario ingresa el monto
    _amountController.text = '';

    // Animaciones
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );

    _animationController.forward();
    _initBankAccountsController();

    // Enfocar el campo de monto después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _initBankAccountsController() {
    try {
      if (Get.isRegistered<BankAccountsController>()) {
        _bankAccountsController = Get.find<BankAccountsController>();
        if (_bankAccountsController!.bankAccounts.isEmpty) {
          _bankAccountsController!.loadBankAccounts();
        }
        setState(() => _loadingBankAccounts = false);
      } else {
        _initBankAccountsBinding();
      }
    } catch (e) {
      _initBankAccountsBinding();
    }
  }

  void _initBankAccountsBinding() {
    try {
      BankAccountsBinding().dependencies();
      if (Get.isRegistered<BankAccountsController>()) {
        _bankAccountsController = Get.find<BankAccountsController>();
        _bankAccountsController!.loadBankAccounts();
      }
    } catch (e) {
      debugPrint('Error inicializando BankAccountsController: $e');
    }
    setState(() => _loadingBankAccounts = false);
  }

  String _getPaymentMethodFromAccount(BankAccount? account) {
    if (account == null) return 'cash';

    switch (account.type) {
      case BankAccountType.cash:
        return 'cash';
      case BankAccountType.savings:
      case BankAccountType.checking:
        return 'bank_transfer';
      case BankAccountType.digitalWallet:
        return 'nequi';
      case BankAccountType.creditCard:
        return 'credit_card';
      case BankAccountType.debitCard:
        return 'debit_card';
      case BankAccountType.other:
        return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              child: SafeArea(
                child: Container(
                  width: isMobile ? double.infinity : 480,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                  gradient: ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCreditInfo(),
                                const SizedBox(height: 14),
                                // Monto siempre visible primero
                                if (!_payFullAmount) ...[
                                  _buildAmountField(),
                                  // ✅ Solo mostrar saldo a favor cuando el monto excede el saldo
                                  if (_hasOverpayment) _buildPendingBalanceInfo(),
                                  const SizedBox(height: 12),
                                ],
                                _buildPayFullAmountOption(),
                                const SizedBox(height: 14),
                                _buildBankAccountSelector(),
                                const SizedBox(height: 12),
                                _buildDatePicker(),
                                const SizedBox(height: 12),
                                _buildReferenceField(),
                                const SizedBox(height: 12),
                                _buildNotesField(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Abono',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.credit.customerName ?? 'Cliente',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn(
            'Total',
            widget.credit.originalAmount,
            ElegantLightTheme.primaryBlue,
          ),
          Container(
            height: 36,
            width: 1,
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
          _buildInfoColumn(
            'Pagado',
            widget.credit.paidAmount,
            Colors.green,
          ),
          Container(
            height: 36,
            width: 1,
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
          _buildInfoColumn(
            'Saldo',
            widget.credit.balanceDue,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPayFullAmountOption() {
    return Container(
      decoration: BoxDecoration(
        gradient: _payFullAmount
            ? LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
              )
            : ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _payFullAmount
              ? Colors.green.withValues(alpha: 0.3)
              : ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _payFullAmount = !_payFullAmount;
              if (_payFullAmount) {
                _amountController.text = NumberInputFormatter.formatValueForDisplay(widget.credit.balanceDue);
              } else {
                _amountController.text = '';
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: _payFullAmount ? ElegantLightTheme.successGradient : null,
                    color: _payFullAmount ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _payFullAmount ? Colors.green : ElegantLightTheme.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: _payFullAmount
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  'Pagar saldo completo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _payFullAmount ? Colors.green.shade700 : ElegantLightTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(widget.credit.balanceDue),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _payFullAmount ? Colors.green : ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        focusNode: _amountFocusNode,
        decoration: InputDecoration(
          labelText: 'Monto del abono',
          labelStyle: TextStyle(
            color: ElegantLightTheme.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          floatingLabelStyle: TextStyle(
            color: ElegantLightTheme.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.attach_money, color: Colors.white, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          helperText: _allowOverpayment
              ? 'Puede exceder el saldo pendiente'
              : 'Máximo: ${AppFormatters.formatCurrency(widget.credit.balanceDue)}',
          helperStyle: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 11,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [PriceInputFormatter()],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ElegantLightTheme.primaryBlue,
        ),
        onChanged: (value) {
          setState(() {
            // ✅ Auto-detectar y habilitar sobrepago cuando el monto excede el saldo
            final amount = NumberInputFormatter.getNumericValue(value) ?? 0;
            if (amount > widget.credit.balanceDue) {
              _allowOverpayment = true; // Activar automáticamente
            } else {
              _allowOverpayment = false; // Desactivar si ya no excede
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingrese el monto del abono';
          }
          final amount = NumberInputFormatter.getNumericValue(value) ?? 0;
          if (amount <= 0) {
            return 'El monto debe ser mayor a cero';
          }
          if (!_allowOverpayment && amount > widget.credit.balanceDue) {
            return 'El monto excede el saldo. Active "Permitir sobrepago"';
          }
          return null;
        },
      ),
    );
  }

  /// ✅ Widget unificado para mostrar el saldo a favor que se generará
  Widget _buildPendingBalanceInfo() {
    if (_overpaymentAmount <= 0) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: ElegantLightTheme.normalAnimation,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.withValues(alpha: 0.12),
                    Colors.teal.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.teal.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo a favor a generar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Se acreditará al cliente al registrar',
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      AppFormatters.formatCurrency(_overpaymentAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankAccountSelector() {
    if (_loadingBankAccounts) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
        ),
      );
    }

    final accounts = _bankAccountsController?.activeAccounts ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Método de Pago',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay cuentas registradas. El pago se registrará como efectivo.',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          Obx(() {
            final activeAccounts = _bankAccountsController?.activeAccounts ?? [];

            return Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedBankAccount != null
                      ? _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.4)
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                  width: _selectedBankAccount != null ? 2 : 1,
                ),
                boxShadow: ElegantLightTheme.neuomorphicShadow,
              ),
              child: DropdownButtonFormField<BankAccount?>(
                value: _selectedBankAccount,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                hint: Text(
                  'Seleccionar cuenta o método',
                  style: TextStyle(
                    color: ElegantLightTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                items: [
                  // Opción efectivo
                  DropdownMenuItem<BankAccount?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.money, size: 20, color: Colors.green),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Efectivo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cuentas del tenant
                  ...activeAccounts.map((account) {
                    // Mostrar últimos 4 dígitos si tiene número de cuenta
                    final lastDigits = account.accountNumber != null &&
                            account.accountNumber!.length >= 4
                        ? ' ****${account.accountNumber!.substring(account.accountNumber!.length - 4)}'
                        : '';

                    return DropdownMenuItem<BankAccount?>(
                      value: account,
                      child: Row(
                        children: [
                          Icon(
                            account.type.icon,
                            size: 20,
                            color: _getAccountColor(account.type),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${account.name}$lastDigits',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBankAccount = value;
                  });
                },
              ),
            );
          }),

        if (_selectedBankAccount != null) ...[
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: ElegantLightTheme.fastAnimation,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.1),
                        _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _getAccountColor(_selectedBankAccount!.type),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El pago se registrará en "${_selectedBankAccount!.name}"',
                          style: TextStyle(
                            color: _getAccountColor(_selectedBankAccount!.type),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Color _getAccountColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Colors.green;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return ElegantLightTheme.primaryBlue;
      case BankAccountType.digitalWallet:
        return Colors.purple;
      case BankAccountType.creditCard:
        return Colors.orange;
      case BankAccountType.debitCard:
        return Colors.teal;
      case BankAccountType.other:
        return Colors.grey;
    }
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _paymentDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: ElegantLightTheme.primaryBlue,
                      onSurface: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _paymentDate = date;
              });
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha del pago',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_paymentDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceField() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: TextFormField(
        controller: _referenceController,
        decoration: InputDecoration(
          labelText: 'Referencia (opcional)',
          labelStyle: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          hintText: 'Ej: Transferencia #12345',
          hintStyle: TextStyle(color: ElegantLightTheme.textTertiary),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.shade700],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.tag, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: const TextStyle(
          fontSize: 15,
          color: ElegantLightTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'Notas (opcional)',
          labelStyle: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.note, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        maxLines: 2,
        style: const TextStyle(
          fontSize: 15,
          color: ElegantLightTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      )
                    : ElegantLightTheme.successGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _submitPayment,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Registrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final amount = NumberInputFormatter.getNumericValue(_amountController.text) ?? 0;
    final controller = Get.find<CustomerCreditController>();
    final paymentMethod = _getPaymentMethodFromAccount(_selectedBankAccount);

    try {
      final success = await controller.addPayment(
        creditId: widget.credit.id,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: _paymentDate.toIso8601String(),
        reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        bankAccountId: _selectedBankAccount?.id,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Cerrar el diálogo primero
        Navigator.of(context).pop(true);

        // Recargar datos del crédito y transacciones
        await controller.getCreditById(widget.credit.id);
        await controller.loadCreditTransactions(widget.credit.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Ocurrió un error al registrar el abono',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

