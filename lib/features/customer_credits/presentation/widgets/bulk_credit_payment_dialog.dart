// lib/features/customer_credits/presentation/widgets/bulk_credit_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../data/models/customer_credit_model.dart';
import '../controllers/customer_credit_controller.dart';

/// Dialog para aplicar un PAGO MASIVO a todos los créditos de una
/// sección del cliente (todos directos, o todos los de facturas).
///
/// El monto se distribuye **FIFO** entre los créditos pendientes (más
/// antiguo primero) llamando `addPayment` por cada uno. Cada crédito
/// conserva su propio historial: payments, transacciones y la
/// sincronización con la factura asociada quedan intactas (el backend
/// las maneja por crédito individual, no aquí).
///
/// Si el cajero digita un monto MENOR al total pendiente, el dinero
/// alcanza para liquidar los créditos más viejos por orden y el último
/// queda parcialmente pagado.
class BulkCreditPaymentDialog extends StatefulWidget {
  /// Lista de créditos a pagar. Sólo se toman en cuenta los que tienen
  /// `balanceDue > 0`. Se ordenan FIFO al ejecutar el pago.
  final List<CustomerCreditModel> credits;

  /// Etiqueta de la sección para el header ("Directos" / "Facturas").
  final String sectionLabel;

  /// Nombre del cliente para mostrar en el header.
  final String customerName;

  const BulkCreditPaymentDialog({
    super.key,
    required this.credits,
    required this.sectionLabel,
    required this.customerName,
  });

  @override
  State<BulkCreditPaymentDialog> createState() =>
      _BulkCreditPaymentDialogState();
}

class _BulkCreditPaymentDialogState extends State<BulkCreditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _notesCtrl = TextEditingController();

  BankAccountsController? _bankAccountsCtrl;
  BankAccount? _selectedAccount;
  bool _loadingAccounts = true;
  bool _submitting = false;

  late final double _totalPending;
  late final int _pendingCount;

  final _money = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final pendientes = widget.credits.where((c) => c.balanceDue > 0).toList();
    _pendingCount = pendientes.length;
    _totalPending = pendientes.fold<double>(0, (s, c) => s + c.balanceDue);

    _amountCtrl = TextEditingController(
      text: AppFormatters.formatNumber(_totalPending.toInt()),
    );
    _initBankAccounts();
  }

  Future<void> _initBankAccounts() async {
    try {
      if (!Get.isRegistered<BankAccountsController>()) {
        BankAccountsBinding().dependencies();
      }
      _bankAccountsCtrl = Get.find<BankAccountsController>();
      if (_bankAccountsCtrl!.bankAccounts.isEmpty) {
        await _bankAccountsCtrl!.loadBankAccounts();
      }
    } catch (_) {/* sin bank accounts: igual se puede pagar en efectivo */}
    if (!mounted) return;
    setState(() => _loadingAccounts = false);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Mapea la cuenta seleccionada al payment_method que espera el backend.
  /// Si NO hay cuenta seleccionada → 'cash' (entra a la caja del día).
  String _resolvePaymentMethod() {
    final account = _selectedAccount;
    if (account == null) return 'cash';
    switch (account.type) {
      case BankAccountType.cash:
        return 'cash';
      case BankAccountType.savings:
      case BankAccountType.checking:
        return 'bank_transfer';
      case BankAccountType.digitalWallet:
        return 'bank_transfer';
      case BankAccountType.creditCard:
        return 'credit_card';
      case BankAccountType.debitCard:
        return 'debit_card';
      case BankAccountType.other:
        return 'other';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = AppFormatters.parseNumber(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      _snack('Monto inválido', isError: true);
      return;
    }
    final ctrl = Get.find<CustomerCreditController>();
    setState(() => _submitting = true);

    final result = await ctrl.payAllInSection(
      credits: widget.credits,
      totalAmountToApply: amount,
      paymentMethod: _resolvePaymentMethod(),
      bankAccountId: _selectedAccount?.id,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.applied == 0) {
      _snack(
        'No se aplicó ningún pago',
        message: result.errors.isNotEmpty ? result.errors.first : null,
        isError: true,
      );
      return;
    }

    Navigator.of(context).pop(true);

    // Feedback al cajero — claro y con la plata real movida.
    final hasErrors = result.errors.isNotEmpty;
    _snack(
      hasErrors
          ? 'Aplicado a ${result.applied} créditos · ${result.errors.length} fallaron'
          : '✅ Aplicado ${_money.format(result.total)} a ${result.applied} '
                'crédito${result.applied == 1 ? '' : 's'} ${widget.sectionLabel.toLowerCase()}',
      isError: hasErrors,
    );
  }

  void _snack(String title, {String? message, required bool isError}) {
    Get.snackbar(
      title,
      message ?? '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError
          ? ElegantLightTheme.errorRed.withValues(alpha: 0.95)
          : ElegantLightTheme.successGreen.withValues(alpha: 0.95),
      colorText: Colors.white,
      duration: Duration(milliseconds: isError ? 3500 : 2500),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 14),
                          _buildAmountField(),
                          const SizedBox(height: 14),
                          _buildAccountSelector(),
                          const SizedBox(height: 14),
                          _buildNotesField(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pagar créditos ${widget.sectionLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.customerName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingCount crédito${_pendingCount == 1 ? '' : 's'} pendiente${_pendingCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _money.format(_totalPending),
                  style: TextStyle(
                    fontSize: 19,
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Se aplicará del más antiguo al más reciente',
                  style: TextStyle(
                    fontSize: 11,
                    color: ElegantLightTheme.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      autofocus: true,
      inputFormatters: [PriceInputFormatter()],
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 17,
      ),
      decoration: InputDecoration(
        labelText: 'Monto a aplicar *',
        prefixText: '\$ ',
        prefixStyle: TextStyle(
          color: ElegantLightTheme.successGreen,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        helperText: 'Si es menor que el total, se cubre primero lo más viejo',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
        final n = AppFormatters.parseNumber(v);
        if (n == null || n <= 0) return 'Monto inválido';
        return null;
      },
    );
  }

  Widget _buildAccountSelector() {
    if (_loadingAccounts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final accounts = _bankAccountsCtrl?.bankAccounts
            .where((a) => a.isActive)
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta / Método',
          style: TextStyle(
            fontSize: 12.5,
            color: ElegantLightTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BankAccount?>(
              value: _selectedAccount,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 18, color: ElegantLightTheme.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Efectivo (entra a la caja del día)'),
                ],
              ),
              items: [
                const DropdownMenuItem<BankAccount?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, size: 18),
                      SizedBox(width: 8),
                      Text('Efectivo'),
                    ],
                  ),
                ),
                ...accounts.map(
                  (a) => DropdownMenuItem<BankAccount?>(
                    value: a,
                    child: Row(
                      children: [
                        Icon(
                          _iconForAccountType(a.type),
                          size: 18,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedAccount = v),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Icons.attach_money;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return Icons.account_balance;
      case BankAccountType.digitalWallet:
        return Icons.phone_iphone;
      case BankAccountType.creditCard:
        return Icons.credit_card;
      case BankAccountType.debitCard:
        return Icons.payment;
      case BankAccountType.other:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Notas (opcional)',
        hintText: 'Ej: Abono masivo del cierre del mes',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed:
                  _submitting ? null : () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: ElegantLightTheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle, size: 18),
              label: Text(
                _submitting ? 'Aplicando...' : 'Pagar y registrar',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
