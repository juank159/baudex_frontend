// lib/features/customer_credits/presentation/widgets/add_debt_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../data/models/customer_credit_model.dart';
import '../controllers/customer_credit_controller.dart';

/// Diálogo para agregar deuda a un crédito existente
class AddDebtDialog extends StatefulWidget {
  final CustomerCreditModel credit;

  const AddDebtDialog({
    super.key,
    required this.credit,
  });

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  InputDecoration _elegantInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: ElegantLightTheme.primaryBlue, size: 20)
          : null,
      labelStyle: const TextStyle(
        color: ElegantLightTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      filled: true,
      fillColor: ElegantLightTheme.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          color: ElegantLightTheme.primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
    );
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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
                const SizedBox(height: 20),

                // Info del crédito actual
                _buildCreditInfo(),
                const SizedBox(height: 20),

                // Campo monto
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _elegantInputDecoration(
                    labelText: 'Monto a agregar',
                    hintText: '0',
                    prefixIcon: Icons.attach_money,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el monto';
                    }
                    final amount = NumberInputFormatter.getNumericValue(value) ?? 0;
                    if (amount <= 0) {
                      return 'El monto debe ser mayor a cero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo descripción
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: _elegantInputDecoration(
                    labelText: '¿Qué está llevando?',
                    hintText: 'Ej: Mercancía adicional',
                    prefixIcon: Icons.description_outlined,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botones
                _buildActionButtons(),
              ],
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
            gradient: ElegantLightTheme.warningGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar Deuda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.credit.customerName ?? 'Cliente',
                style: TextStyle(
                  fontSize: 13,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ElegantLightTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                color: ElegantLightTheme.textTertiary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.08),
            Colors.orange.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo actual',
                style: TextStyle(
                  fontSize: 13,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(widget.credit.balanceDue),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total original',
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(widget.credit.originalAmount),
                style: TextStyle(
                  fontSize: 13,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
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
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _submit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Agregar Deuda',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = NumberInputFormatter.getNumericValue(_amountController.text) ?? 0;
    final description = _descriptionController.text.trim();

    final controller = Get.find<CustomerCreditController>();
    final success = await controller.addAmountToCredit(
      creditId: widget.credit.id,
      amount: amount,
      description: description,
    );

    if (success) {
      // Recargar los créditos para actualizar la lista
      await controller.loadCredits();

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Cerrar el diálogo y notificar éxito
      Get.back(result: true);

      // Mostrar mensaje de éxito
      Get.snackbar(
        'Deuda agregada',
        'Se agregó ${AppFormatters.formatCurrency(amount)} al crédito',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade800,
        icon: Icon(Icons.check_circle, color: Colors.green.shade600),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
