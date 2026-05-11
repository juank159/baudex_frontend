// lib/features/bank_accounts/presentation/widgets/bank_account_transfer_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/bank_account.dart';
import '../controllers/bank_account_movements_controller.dart';
import '../controllers/bank_accounts_controller.dart';

/// Dialog para registrar una transferencia entre dos cuentas bancarias.
///
/// Genera 2 movements atómicos en el backend (transfer_out + transfer_in)
/// cruzados por `counterpartyMovementId`. Funciona offline: si no hay red,
/// se generan los 2 movements localmente con tempIds y se sincronizan
/// como un solo `BankAccountTransfer` op cuando vuelva conexión.
class BankAccountTransferDialog extends StatefulWidget {
  /// Cuenta origen pre-seleccionada (la del contexto actual).
  final BankAccount fromAccount;

  const BankAccountTransferDialog({super.key, required this.fromAccount});

  static Future<bool?> show(BuildContext context, BankAccount fromAccount) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BankAccountTransferDialog(fromAccount: fromAccount),
    );
  }

  @override
  State<BankAccountTransferDialog> createState() =>
      _BankAccountTransferDialogState();
}

class _BankAccountTransferDialogState extends State<BankAccountTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;
  BankAccount? _toAccount;
  List<BankAccount> _availableTargets = const [];
  bool _loadingTargets = true;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    try {
      // Reusamos el BankAccountsController si está registrado para tener
      // las cuentas en memoria; si no, las cargamos directo del repo.
      List<BankAccount> all = const [];
      if (Get.isRegistered<BankAccountsController>()) {
        final ctrl = Get.find<BankAccountsController>();
        all = ctrl.bankAccounts.toList();
        if (all.isEmpty) {
          await ctrl.loadBankAccounts();
          all = ctrl.bankAccounts.toList();
        }
      } else {
        // Fallback: usar el repo a través del movements controller.
        final mctrl = Get.find<BankAccountMovementsController>();
        final result = await mctrl.repository.getActiveBankAccounts();
        result.fold((_) {}, (list) => all = list);
      }
      // Excluir la cuenta origen y las inactivas.
      final filtered = all
          .where((a) => a.id != widget.fromAccount.id && a.isActive)
          .toList();
      if (mounted) {
        setState(() {
          _availableTargets = filtered;
          _loadingTargets = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTargets = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_toAccount == null) {
      Get.snackbar(
        'Cuenta destino requerida',
        'Selecciona la cuenta a la que vas a transferir',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _submitting = true);

    final controller = Get.find<BankAccountMovementsController>();
    final desc = _descriptionCtrl.text.trim().isEmpty
        ? null
        : _descriptionCtrl.text.trim();

    final ok = await controller.submitTransfer(
      toAccountId: _toAccount!.id,
      amount: amount,
      description: desc,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      Get.snackbar(
        '¡Transferencia exitosa!',
        '\$${amount.toStringAsFixed(2)} de ${widget.fromAccount.name} → ${_toAccount!.name}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.indigo.shade700.withOpacity(0.95),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.indigo.shade700;

    return AlertDialog(
      icon: Icon(Icons.swap_horiz_rounded, color: accent, size: 36),
      title: const Text('Transferir entre cuentas'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAccountBlock(
                context,
                label: 'DE',
                accountName: widget.fromAccount.name,
                balance: widget.fromAccount.currentBalance,
                color: Colors.orange.shade700,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_downward_rounded,
                      color: accent, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              _buildToAccountSelector(context),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monto a transferir',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 2),
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
                  if (n > widget.fromAccount.currentBalance) {
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
                  hintText: 'Ej: Pago a proveedor, traslado fondos...',
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.swap_horiz_rounded),
          label: Text(_submitting ? 'Transfiriendo...' : 'Transferir'),
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildAccountBlock(
    BuildContext context, {
    required String label,
    required String accountName,
    required double balance,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  accountName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Saldo: ${AppFormatters.formatCurrency(balance)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToAccountSelector(BuildContext context) {
    if (_loadingTargets) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_availableTargets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay otras cuentas activas. Crea otra cuenta para poder transferir.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<BankAccount>(
      value: _toAccount,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Cuenta destino',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        prefixIcon: Icon(Icons.arrow_downward_rounded,
            color: Colors.green.shade700),
      ),
      items: _availableTargets.map((acc) {
        return DropdownMenuItem<BankAccount>(
          value: acc,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  acc.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                AppFormatters.formatCurrency(acc.currentBalance),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _toAccount = v),
      validator: (v) => v == null ? 'Selecciona la cuenta destino' : null,
    );
  }
}
