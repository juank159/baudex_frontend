// lib/features/customer_credits/presentation/widgets/client_balance_dialogs.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../data/models/customer_credit_model.dart';
import '../controllers/customer_credit_controller.dart';

/// Dialogo para ver el detalle y transacciones de un saldo a favor
class ClientBalanceDetailDialog extends StatefulWidget {
  final ClientBalanceModel balance;

  const ClientBalanceDetailDialog({super.key, required this.balance});

  @override
  State<ClientBalanceDetailDialog> createState() => _ClientBalanceDetailDialogState();
}

class _ClientBalanceDetailDialogState extends State<ClientBalanceDetailDialog> {
  final controller = Get.find<CustomerCreditController>();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await controller.loadBalanceTransactions(widget.balance.customerId);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.balance.customerName ?? 'Cliente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saldo: ${AppFormatters.formatCurrency(widget.balance.balance)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Transactions list
            Flexible(
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Obx(() {
                      final transactions = controller.currentBalanceTransactions;

                      if (transactions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No hay transacciones registradas',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _TransactionTile(transaction: tx);
                        },
                      );
                    }),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final ClientBalanceTransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.type == BalanceTransactionType.deposit ||
        transaction.type == BalanceTransactionType.adjustment;
    final color = isPositive ? Colors.green : Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getIconForType(transaction.type),
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.type.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.description,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
            style: TextStyle(
              color: ElegantLightTheme.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : '-'}${AppFormatters.formatCurrency(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            'Saldo: ${AppFormatters.formatCurrency(transaction.balanceAfter)}',
            style: TextStyle(
              color: ElegantLightTheme.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(BalanceTransactionType type) {
    switch (type) {
      case BalanceTransactionType.deposit:
        return Icons.add_circle;
      case BalanceTransactionType.usage:
        return Icons.remove_circle;
      case BalanceTransactionType.refund:
        return Icons.money_off;
      case BalanceTransactionType.adjustment:
        return Icons.tune;
    }
  }
}

/// Dialogo para reembolsar saldo a favor
class RefundBalanceDialog extends StatefulWidget {
  final ClientBalanceModel balance;

  const RefundBalanceDialog({super.key, required this.balance});

  @override
  State<RefundBalanceDialog> createState() => _RefundBalanceDialogState();
}

class _RefundBalanceDialogState extends State<RefundBalanceDialog> {
  final controller = Get.find<CustomerCreditController>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPaymentMethod = 'efectivo';

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'efectivo', 'label': 'Efectivo'},
    {'value': 'transferencia', 'label': 'Transferencia'},
    {'value': 'cheque', 'label': 'Cheque'},
    {'value': 'otro', 'label': 'Otro'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.balance.balance.toStringAsFixed(0);
    _descriptionController.text = 'Reembolso de saldo a favor';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.money_off, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reembolsar Saldo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.balance.customerName ?? 'Cliente',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Available balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Saldo disponible: '),
                    Text(
                      AppFormatters.formatCurrency(widget.balance.balance),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Monto a reembolsar',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  final amount = double.tryParse(value) ?? 0;
                  if (amount <= 0) {
                    return 'El monto debe ser mayor a 0';
                  }
                  if (amount > widget.balance.balance) {
                    return 'El monto excede el saldo disponible';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment method
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Metodo de pago',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripcion',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una descripcion';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton.icon(
                        onPressed: controller.isProcessing.value ? null : _submitRefund,
                        icon: controller.isProcessing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Reembolsar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ElegantLightTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);

    final success = await controller.refundBalance(
      customerId: widget.balance.customerId,
      amount: amount,
      description: _descriptionController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
    );

    if (success) {
      Get.back();
    }
  }
}

/// Dialogo para ajustar saldo manualmente
class AdjustBalanceDialog extends StatefulWidget {
  final ClientBalanceModel balance;

  const AdjustBalanceDialog({super.key, required this.balance});

  @override
  State<AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<AdjustBalanceDialog> {
  final controller = Get.find<CustomerCreditController>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isIncrease = true;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.orange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ajustar Saldo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.balance.customerName ?? 'Cliente',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Current balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Saldo actual: '),
                    Text(
                      AppFormatters.formatCurrency(widget.balance.balance),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Adjustment type
              Row(
                children: [
                  Expanded(
                    child: _AdjustTypeButton(
                      label: 'Aumentar',
                      icon: Icons.add_circle,
                      color: Colors.green,
                      isSelected: _isIncrease,
                      onTap: () => setState(() => _isIncrease = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdjustTypeButton(
                      label: 'Reducir',
                      icon: Icons.remove_circle,
                      color: Colors.red,
                      isSelected: !_isIncrease,
                      onTap: () => setState(() => _isIncrease = false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Monto del ajuste',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  final amount = double.tryParse(value) ?? 0;
                  if (amount <= 0) {
                    return 'El monto debe ser mayor a 0';
                  }
                  if (!_isIncrease && amount > widget.balance.balance) {
                    return 'El monto excede el saldo disponible';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripcion del ajuste',
                  hintText: 'Ej: Correccion por error en pago...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una descripcion';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton.icon(
                        onPressed: controller.isProcessing.value ? null : _submitAdjust,
                        icon: controller.isProcessing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Aplicar Ajuste'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAdjust() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final adjustAmount = _isIncrease ? amount : -amount;

    final success = await controller.adjustBalance(
      customerId: widget.balance.customerId,
      amount: adjustAmount,
      description: _descriptionController.text.trim(),
    );

    if (success) {
      Get.back();
    }
  }
}

class _AdjustTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdjustTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
