// lib/features/bank_accounts/presentation/widgets/bank_account_movement_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_account_movement.dart';
import '../controllers/bank_account_movements_controller.dart';

/// Dialog para registrar un movimiento manual (depósito o retiro) en una
/// cuenta bancaria. Funciona offline-first: si hay red, va al server; si no,
/// se guarda localmente y se sincroniza cuando vuelva conexión.
class BankAccountMovementDialog extends StatefulWidget {
  final BankAccount account;
  final BankAccountMovementType type;

  const BankAccountMovementDialog({
    super.key,
    required this.account,
    required this.type,
  });

  static Future<bool?> showDeposit(BuildContext context, BankAccount account) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BankAccountMovementDialog(
        account: account,
        type: BankAccountMovementType.deposit,
      ),
    );
  }

  static Future<bool?> showWithdrawal(BuildContext context, BankAccount account) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BankAccountMovementDialog(
        account: account,
        type: BankAccountMovementType.withdrawal,
      ),
    );
  }

  @override
  State<BankAccountMovementDialog> createState() => _BankAccountMovementDialogState();
}

class _BankAccountMovementDialogState extends State<BankAccountMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;

  bool get _isDeposit => widget.type == BankAccountMovementType.deposit;
  Color get _accentColor =>
      _isDeposit ? Colors.green.shade700 : Colors.orange.shade700;
  IconData get _icon =>
      _isDeposit ? Icons.add_circle_outline : Icons.remove_circle_outline;
  String get _title => _isDeposit ? 'Depósito manual' : 'Retiro manual';
  String get _actionLabel => _isDeposit ? 'Depositar' : 'Retirar';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _submitting = true);

    final controller = Get.find<BankAccountMovementsController>();
    final desc = _descriptionCtrl.text.trim().isEmpty
        ? null
        : _descriptionCtrl.text.trim();

    final ok = _isDeposit
        ? await controller.submitDeposit(amount: amount, description: desc)
        : await controller.submitWithdrawal(amount: amount, description: desc);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      Get.snackbar(
        _isDeposit ? '¡Depósito registrado!' : '¡Retiro registrado!',
        '\$${amount.toStringAsFixed(2)} en ${widget.account.name}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: _accentColor.withOpacity(0.95),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(_icon, color: _accentColor, size: 36),
      title: Text(_title),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info de la cuenta + saldo actual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.account.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saldo actual: ${AppFormatters.formatCurrency(widget.account.currentBalance)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _accentColor, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final n = double.tryParse(v.replaceAll(',', ''));
                  if (n == null || n <= 0) {
                    return 'El monto debe ser mayor a cero';
                  }
                  if (!_isDeposit && n > widget.account.currentBalance) {
                    return 'Saldo insuficiente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Recarga inicial, retiro caja chica...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(_icon),
          label: Text(_submitting ? 'Procesando...' : _actionLabel),
          style: FilledButton.styleFrom(backgroundColor: _accentColor),
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
