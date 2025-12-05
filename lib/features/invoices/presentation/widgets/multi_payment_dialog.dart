// lib/features/invoices/presentation/widgets/multi_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../../data/models/add_payment_request_model.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';

/// Modelo para un ítem de pago en el diálogo
class PaymentEntry {
  final String id;
  double amount;
  PaymentMethod paymentMethod;
  BankAccount? bankAccount;
  String? reference;
  final TextEditingController amountController;
  final TextEditingController referenceController;

  PaymentEntry({
    required this.id,
    this.amount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.bankAccount,
    this.reference,
  })  : amountController = TextEditingController(),
        referenceController = TextEditingController(text: reference ?? '');

  void dispose() {
    amountController.dispose();
    referenceController.dispose();
  }

  PaymentItemModel toModel() {
    return PaymentItemModel(
      amount: amount,
      paymentMethod: paymentMethod.value,
      bankAccountId: bankAccount?.id,
      reference: reference?.isNotEmpty == true ? reference : null,
    );
  }
}

/// Diálogo para registrar múltiples pagos a una factura
/// Permite agregar varios métodos de pago (Ej: $100,000 Nequi + $200,000 Efectivo)
class MultiPaymentDialog extends StatefulWidget {
  final double total;
  final double balanceDue;
  final Function(List<PaymentItemModel> payments, bool createCredit) onConfirm;
  final VoidCallback onCancel;

  const MultiPaymentDialog({
    super.key,
    required this.total,
    required this.balanceDue,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<MultiPaymentDialog> createState() => _MultiPaymentDialogState();
}

class _MultiPaymentDialogState extends State<MultiPaymentDialog> {
  final List<PaymentEntry> _payments = [];
  bool _createCreditForRemaining = false;
  bool _isProcessing = false;

  BankAccountsController? _bankAccountsController;

  @override
  void initState() {
    super.initState();
    // Agregar un pago inicial
    _addPayment(initialAmount: widget.balanceDue);

    // Intentar obtener el controlador de cuentas bancarias
    try {
      _bankAccountsController = Get.find<BankAccountsController>();
    } catch (e) {
      // El controlador no está registrado, lo ignoramos
      print('⚠️ BankAccountsController no disponible: $e');
    }
  }

  @override
  void dispose() {
    for (final payment in _payments) {
      payment.dispose();
    }
    super.dispose();
  }

  void _addPayment({double initialAmount = 0}) {
    setState(() {
      final entry = PaymentEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: initialAmount,
        paymentMethod: PaymentMethod.cash,
      );
      if (initialAmount > 0) {
        entry.amountController.text = AppFormatters.formatNumber(initialAmount.round());
      }
      _payments.add(entry);
    });
  }

  void _removePayment(String id) {
    setState(() {
      final index = _payments.indexWhere((p) => p.id == id);
      if (index != -1) {
        _payments[index].dispose();
        _payments.removeAt(index);
      }
    });
  }

  double get _totalPaid {
    return _payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _remaining {
    return widget.balanceDue - _totalPaid;
  }

  bool get _canProcess {
    if (_payments.isEmpty) return false;
    if (_payments.any((p) => p.amount <= 0)) return false;

    // Si el total pagado es menor que el saldo, debe aceptar crear crédito
    if (_totalPaid < widget.balanceDue && !_createCreditForRemaining) {
      return false;
    }

    // Si el total pagado excede el saldo, no permitir (a menos que sea a favor)
    if (_totalPaid > widget.balanceDue) {
      return false;
    }

    return true;
  }

  void _updatePaymentAmount(PaymentEntry entry, String value) {
    final parsed = AppFormatters.parseNumber(value) ?? 0.0;
    setState(() {
      entry.amount = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dialogWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.95
        : 600.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 40,
        vertical: 24,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(context),
                    const SizedBox(height: 20),
                    _buildPaymentsList(context),
                    const SizedBox(height: 16),
                    _buildAddPaymentButton(context),
                    if (_remaining > 0) ...[
                      const SizedBox(height: 16),
                      _buildCreditOption(context),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payments,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pagos Múltiples',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Agrega varios métodos de pago',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final isPaid = _remaining <= 0;
    final isPartial = _remaining > 0 && _totalPaid > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ]
              : [
                  ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  ElegantLightTheme.primaryBlue.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF10B981).withOpacity(0.3)
              : ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Pendiente:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(widget.balanceDue),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pagos (${_payments.length}):',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(_totalPaid),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPaid ? const Color(0xFF10B981) : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPaid ? 'Pagado:' : 'Restante:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                ),
              ),
              Text(
                isPaid
                    ? AppFormatters.formatCurrency(_totalPaid)
                    : AppFormatters.formatCurrency(_remaining),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                ),
              ),
            ],
          ),
          if (isPartial && !_createCreditForRemaining) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Activa "Crear crédito" para procesar pagos parciales',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.list_alt, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Métodos de Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_payments.length, (index) {
          return _buildPaymentItem(context, _payments[index], index);
        }),
      ],
    );
  }

  Widget _buildPaymentItem(BuildContext context, PaymentEntry entry, int index) {
    final bankAccounts = _bankAccountsController?.activeAccounts ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número y botón eliminar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pago ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (_payments.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removePayment(entry.id),
                  tooltip: 'Eliminar pago',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Monto
          TextField(
            controller: entry.amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CurrencyInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Monto',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.attach_money, color: Colors.white, size: 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) => _updatePaymentAmount(entry, value),
          ),
          const SizedBox(height: 12),

          // Método de pago
          DropdownButtonFormField<PaymentMethod>(
            value: entry.paymentMethod,
            decoration: InputDecoration(
              labelText: 'Método de Pago',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getPaymentMethodIcon(entry.paymentMethod),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Row(
                  children: [
                    Icon(_getPaymentMethodIcon(method), size: 18),
                    const SizedBox(width: 8),
                    Text(method.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  entry.paymentMethod = value;
                  // Limpiar cuenta bancaria si cambia el método
                  entry.bankAccount = null;
                });
              }
            },
          ),

          // Cuenta bancaria (si hay cuentas disponibles)
          if (bankAccounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<BankAccount?>(
              value: entry.bankAccount,
              decoration: InputDecoration(
                labelText: 'Cuenta de Destino (Opcional)',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sin cuenta específica'),
                ),
                ...bankAccounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Row(
                      children: [
                        Icon(account.type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(account.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  entry.bankAccount = value;
                });
              },
            ),
          ],

          // Referencia (opcional)
          const SizedBox(height: 12),
          TextField(
            controller: entry.referenceController,
            decoration: InputDecoration(
              labelText: 'Referencia (Opcional)',
              hintText: 'Ej: Nequi-12345',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.tag, color: Colors.grey.shade600, size: 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (value) {
              entry.reference = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentButton(BuildContext context) {
    return InkWell(
      onTap: () => _addPayment(),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: ElegantLightTheme.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Agregar Otro Método de Pago',
              style: TextStyle(
                color: ElegantLightTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditOption(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _createCreditForRemaining = !_createCreditForRemaining;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: _createCreditForRemaining
              ? LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.15),
                    Colors.orange.withOpacity(0.08),
                  ],
                )
              : null,
          color: _createCreditForRemaining ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _createCreditForRemaining
                ? Colors.orange
                : Colors.grey.shade200,
            width: _createCreditForRemaining ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: _createCreditForRemaining
                    ? const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFF8C00)],
                      )
                    : null,
                border: Border.all(
                  color: _createCreditForRemaining
                      ? Colors.transparent
                      : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: _createCreditForRemaining
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_score, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear crédito por el saldo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'El cliente quedará debiendo ${AppFormatters.formatCurrency(_remaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProcess && !_isProcessing
                  ? () => _confirmPayments()
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmar ${_payments.length} Pago${_payments.length > 1 ? "s" : ""}',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayments() {
    if (!_canProcess) return;

    setState(() => _isProcessing = true);

    final paymentModels = _payments.map((p) => p.toModel()).toList();

    widget.onConfirm(paymentModels, _createCreditForRemaining);
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.credit:
        return Icons.schedule;
      case PaymentMethod.clientBalance:
        return Icons.account_balance_wallet;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }
}

// Formateador de input para moneda
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      return const TextEditingValue(text: '');
    }

    int value = int.parse(cleaned);
    String formatted = AppFormatters.formatNumber(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
