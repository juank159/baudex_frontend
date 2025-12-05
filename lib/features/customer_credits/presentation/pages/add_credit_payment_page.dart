// lib/features/customer_credits/presentation/pages/add_credit_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';

/// Página para agregar un abono a un crédito
class AddCreditPaymentPage extends StatefulWidget {
  final CustomerCredit credit;

  const AddCreditPaymentPage({
    super.key,
    required this.credit,
  });

  @override
  State<AddCreditPaymentPage> createState() => _AddCreditPaymentPageState();
}

class _AddCreditPaymentPageState extends State<AddCreditPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  bool _payFullAmount = true;
  bool _allowOverpayment = false;

  // 🏦 Cuentas bancarias
  late BankAccountsController _bankAccountsController;
  BankAccount? _selectedBankAccount;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$ ',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.credit.balanceDue.toStringAsFixed(0);
    _initBankAccountsController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 🏦 Inicializar controlador de cuentas bancarias
  void _initBankAccountsController() {
    // Primero asegurarnos de que el binding esté inicializado
    if (!Get.isRegistered<BankAccountsController>()) {
      BankAccountsBinding().dependencies();
    }

    _bankAccountsController = Get.find<BankAccountsController>();

    // Cargar cuentas si están vacías
    if (_bankAccountsController.bankAccounts.isEmpty) {
      _bankAccountsController.loadBankAccounts();
    }
  }

  /// Obtener el método de pago basado en el tipo de cuenta
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Abono'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info del cliente y crédito
              _buildCreditInfoCard(),

              const SizedBox(height: 20),

              // Opción de pagar todo
              _buildPayFullAmountCard(),

              // Monto del abono (si no paga todo)
              if (!_payFullAmount) ...[
                const SizedBox(height: 16),
                _buildAmountCard(),
              ],

              const SizedBox(height: 20),

              // Selector de cuenta bancaria / método de pago
              _buildBankAccountCard(),

              const SizedBox(height: 16),

              // Fecha de pago
              _buildDatePickerCard(),

              const SizedBox(height: 16),

              // Referencia y Notas
              _buildAdditionalInfoCard(),

              const SizedBox(height: 24),

              // Botón de acción
              _buildSubmitButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCreditInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    (widget.credit.customerName ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.credit.customerName ?? 'Cliente',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.credit.description ?? 'Crédito',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Total', widget.credit.originalAmount, Colors.blue),
                _buildInfoColumn('Pagado', widget.credit.paidAmount, Colors.green),
                _buildInfoColumn('Saldo', widget.credit.balanceDue, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayFullAmountCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: const Text(
          'Pagar saldo completo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          currencyFormat.format(widget.credit.balanceDue),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.green,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
        value: _payFullAmount,
        activeColor: Colors.green,
        onChanged: (value) {
          setState(() {
            _payFullAmount = value ?? true;
            if (_payFullAmount) {
              _amountController.text = widget.credit.balanceDue.toStringAsFixed(0);
            }
          });
        },
      ),
    );
  }

  Widget _buildAmountCard() {
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;
    final overpayment = enteredAmount - widget.credit.balanceDue;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monto del Abono',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                helperText: _allowOverpayment
                    ? 'Puede exceder el saldo pendiente'
                    : 'Máximo: ${currencyFormat.format(widget.credit.balanceDue)}',
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el monto del abono';
                }
                final amount = double.tryParse(value) ?? 0;
                if (amount <= 0) {
                  return 'El monto debe ser mayor a cero';
                }
                if (!_allowOverpayment && amount > widget.credit.balanceDue) {
                  return 'El monto excede el saldo. Active "Permitir sobrepago"';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Opción de sobrepago
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Permitir sobrepago',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'El exceso se acreditará como saldo a favor',
                style: TextStyle(fontSize: 12),
              ),
              value: _allowOverpayment,
              activeColor: Colors.green,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _allowOverpayment = value ?? false;
                });
              },
            ),

            // Info de sobrepago
            if (_allowOverpayment && overpayment > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo a favor generado',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Se acreditará al cliente',
                            style: TextStyle(color: Colors.green[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(overpayment),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 16,
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

  Widget _buildBankAccountCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Método de Pago',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Usar Obx para reactividad
            Obx(() {
              final isLoading = _bankAccountsController.isLoading.value;
              final accounts = _bankAccountsController.activeAccounts;

              if (isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (accounts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay cuentas bancarias registradas. El pago se registrará como efectivo.',
                          style: TextStyle(color: Colors.orange[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Dropdown con cuentas bancarias
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedBankAccount != null
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _selectedBankAccount != null ? 2 : 1,
                      ),
                    ),
                    child: DropdownButtonFormField<BankAccount?>(
                      value: _selectedBankAccount,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedBankAccount != null
                                ? _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedBankAccount?.type.icon ?? Icons.money,
                            color: _selectedBankAccount != null
                                ? _getAccountColor(_selectedBankAccount!.type)
                                : Colors.green,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text('Seleccionar cuenta o método'),
                      isExpanded: true,
                      items: [
                        // Opción de efectivo (sin cuenta)
                        DropdownMenuItem<BankAccount?>(
                          value: null,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.money, size: 18, color: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Efectivo',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cuentas bancarias del tenant
                        ...accounts.map((account) {
                          final accountDisplay = account.accountNumber != null &&
                                  account.accountNumber!.length > 4
                              ? '${account.name} ****${account.accountNumber!.substring(account.accountNumber!.length - 4)}'
                              : account.name;

                          return DropdownMenuItem<BankAccount?>(
                            value: account,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _getAccountColor(account.type).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    account.type.icon,
                                    size: 18,
                                    color: _getAccountColor(account.type),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        accountDisplay,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (account.bankName != null)
                                        Text(
                                          account.bankName!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (account.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Principal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
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
                  ),

                  // Info de la cuenta seleccionada
                  if (_selectedBankAccount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getAccountColor(_selectedBankAccount!.type).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
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
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getAccountColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Colors.green;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return Colors.blue;
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

  Widget _buildDatePickerCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_today, color: Colors.indigo),
        ),
        title: const Text(
          'Fecha del Pago',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('EEEE, d MMMM yyyy', 'es').format(_paymentDate),
          style: const TextStyle(fontSize: 15),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _paymentDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
            locale: const Locale('es'),
          );
          if (date != null) {
            setState(() {
              _paymentDate = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Adicional',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Referencia (opcional)',
                hintText: 'Ej: Transferencia #12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.tag),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Observaciones del pago',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Registrar Abono de ${currencyFormat.format(double.tryParse(_amountController.text) ?? widget.credit.balanceDue)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;

    // Si hay sobrepago, confirmar
    if (amount > widget.credit.balanceDue) {
      final overpayment = amount - widget.credit.balanceDue;
      final confirmed = await _showOverpaymentConfirmation(overpayment);
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Get.find<CustomerCreditController>();
    final paymentMethod = _getPaymentMethodFromAccount(_selectedBankAccount);

    final success = await controller.addPayment(
      creditId: widget.credit.id,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: _paymentDate.toIso8601String(),
      reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      bankAccountId: _selectedBankAccount?.id,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Get.back(result: true);
    }
  }

  Future<bool> _showOverpaymentConfirmation(double overpayment) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Sobrepago Detectado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El monto ingresado es mayor al saldo pendiente:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo pendiente:'),
                Text(
                  currencyFormat.format(widget.credit.balanceDue),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monto a pagar:'),
                Text(
                  currencyFormat.format(double.tryParse(_amountController.text) ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo a favor:'),
                Text(
                  currencyFormat.format(overpayment),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'El exceso de ${currencyFormat.format(overpayment)} se guardará como saldo a favor del cliente.',
                style: TextStyle(color: Colors.green[700], fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    ) ?? false;
  }
}
