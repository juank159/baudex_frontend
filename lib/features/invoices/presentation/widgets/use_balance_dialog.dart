// lib/features/invoices/presentation/widgets/use_balance_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';

/// Formateador de input para moneda
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

/// Dialog para usar saldo a favor del cliente en una factura
/// Este dialog se muestra cuando el cliente tiene saldo a favor
/// y desea usarlo para pagar total o parcialmente una factura.
class UseBalanceDialog extends StatefulWidget {
  final Invoice invoice;
  final double availableBalance;
  final String customerName;
  final Function(double amountToUse) onConfirm;
  final VoidCallback onCancel;

  const UseBalanceDialog({
    super.key,
    required this.invoice,
    required this.availableBalance,
    required this.customerName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<UseBalanceDialog> createState() => _UseBalanceDialogState();
}

class _UseBalanceDialogState extends State<UseBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _useFullBalance = true;
  bool _isProcessing = false;

  double get _balanceDue => widget.invoice.balanceDue;
  double get _availableBalance => widget.availableBalance;
  double get _maxUsable => _balanceDue < _availableBalance ? _balanceDue : _availableBalance;

  @override
  void initState() {
    super.initState();
    // Por defecto usar el máximo posible
    _amountController.text = AppFormatters.formatNumber(_maxUsable.toInt());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.isEmpty ? 0 : double.parse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Info del cliente y saldo
                  _buildBalanceInfo(),
                  const SizedBox(height: 20),

                  // Info de la factura
                  _buildInvoiceInfo(),
                  const SizedBox(height: 20),

                  // Selector de monto
                  _buildAmountSelector(),
                  const SizedBox(height: 24),

                  // Resumen
                  _buildSummary(),
                  const SizedBox(height: 24),

                  // Botones
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
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
                'Usar Saldo a Favor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aplicar saldo disponible a esta factura',
                style: TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onCancel,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ElegantLightTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                color: ElegantLightTheme.textTertiary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF10B981).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Saldo disponible: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(_availableBalance),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: ElegantLightTheme.primaryBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura ${widget.invoice.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saldo pendiente: ${AppFormatters.formatCurrency(_balanceDue)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payments_rounded,
              size: 18,
              color: ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            const Text(
              'Monto a aplicar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Opción: Usar todo el saldo posible
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _useFullBalance = true;
                _amountController.text = AppFormatters.formatNumber(_maxUsable.toInt());
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _useFullBalance
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _useFullBalance
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _useFullBalance
                            ? const Color(0xFF10B981)
                            : ElegantLightTheme.textTertiary,
                        width: 2,
                      ),
                      color: _useFullBalance
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                    ),
                    child: _useFullBalance
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usar máximo disponible',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _useFullBalance
                                ? const Color(0xFF047857)
                                : ElegantLightTheme.textPrimary,
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(_maxUsable),
                          style: TextStyle(
                            fontSize: 12,
                            color: ElegantLightTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Opción: Monto personalizado
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _useFullBalance = false;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: !_useFullBalance
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_useFullBalance
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !_useFullBalance
                            ? const Color(0xFF10B981)
                            : ElegantLightTheme.textTertiary,
                        width: 2,
                      ),
                      color: !_useFullBalance
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                    ),
                    child: !_useFullBalance
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Monto personalizado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Campo de monto personalizado
        if (!_useFullBalance) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: ElegantLightTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF10B981),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_CurrencyInputFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese un monto';
              }
              final amount = _parseAmount(value);
              if (amount <= 0) {
                return 'El monto debe ser mayor a 0';
              }
              if (amount > _maxUsable) {
                return 'Máximo disponible: ${AppFormatters.formatCurrency(_maxUsable)}';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    final amountToUse = _useFullBalance
        ? _maxUsable
        : _parseAmount(_amountController.text);
    final remainingBalance = _availableBalance - amountToUse;
    final remainingDebt = _balanceDue - amountToUse;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow('Saldo a aplicar', amountToUse, isBold: true, color: const Color(0xFF10B981)),
          const Divider(height: 20),
          _summaryRow('Saldo restante cliente', remainingBalance),
          const SizedBox(height: 8),
          _summaryRow('Deuda restante factura', remainingDebt > 0 ? remainingDebt : 0,
              color: remainingDebt > 0 ? Colors.orange : const Color(0xFF10B981)),
          if (remainingDebt <= 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'La factura quedará pagada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
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

  Widget _summaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        Text(
          AppFormatters.formatCurrency(value),
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isProcessing ? null : _handleConfirm,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
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
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Aplicar Saldo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final amountToUse = _useFullBalance
        ? _maxUsable
        : _parseAmount(_amountController.text);

    if (amountToUse <= 0) {
      Get.snackbar(
        'Error',
        'El monto debe ser mayor a 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    if (amountToUse > _maxUsable) {
      Get.snackbar(
        'Error',
        'El monto excede el máximo disponible',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    widget.onConfirm(amountToUse);
  }
}
