// lib/features/invoices/presentation/widgets/invoice_payment_form_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/invoice_detail_controller.dart';
import '../../domain/entities/invoice.dart';

class InvoicePaymentFormWidget extends StatelessWidget {
  final InvoiceDetailController controller;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const InvoicePaymentFormWidget({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildPaymentMethodSelector(context),
          const SizedBox(height: 16),
          _buildAmountField(context),
          const SizedBox(height: 16),
          _buildReferenceField(context),
          const SizedBox(height: 16),
          _buildNotesField(context),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payment,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Agregar Pago',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Pendiente: \$${controller.remainingBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    if (controller.invoice?.total != null)
                      Text(
                        'Total de la factura: \$${controller.invoice!.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              PaymentMethod.values.map((method) {
                final isSelected = controller.selectedPaymentMethod == method;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPaymentMethodIcon(method),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(method.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => controller.setPaymentMethod(method),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return CustomTextField(
      controller: controller.paymentAmountController,
      label: 'Monto del Pago',
      hint: 'Ingresa el monto a pagar',
      prefixIcon: Icons.attach_money,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: controller.validatePaymentAmount,
      suffixIcon: Icons.calculate,
      onSuffixIconPressed: () => _showQuickAmounts(context),
    );
  }

  Widget _buildReferenceField(BuildContext context) {
    return CustomTextField(
      controller: controller.paymentReferenceController,
      label: 'Referencia (Opcional)',
      hint: 'Número de transacción, cheque, etc.',
      prefixIcon: Icons.receipt_long,
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return CustomTextField(
      controller: controller.paymentNotesController,
      label: 'Notas (Opcional)',
      hint: 'Notas adicionales sobre el pago...',
      prefixIcon: Icons.note,
      maxLines: 2,
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            type: ButtonType.outline,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: GetBuilder<InvoiceDetailController>(
            builder:
                (controller) => CustomButton(
                  text:
                      controller.isProcessing
                          ? 'Procesando...'
                          : 'Agregar Pago',
                  icon: Icons.add_card,
                  onPressed: controller.isProcessing ? null : onSubmit,
                  isLoading: controller.isProcessing,
                ),
          ),
        ),
      ],
    );
  }

  void _showQuickAmounts(BuildContext context) {
    final remainingBalance = controller.remainingBalance;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Montos Rápidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: context.isMobile ? 2 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    _buildQuickAmountButton(
                      context,
                      'Saldo Completo',
                      remainingBalance,
                    ),
                    _buildQuickAmountButton(
                      context,
                      '50%',
                      remainingBalance * 0.5,
                    ),
                    _buildQuickAmountButton(
                      context,
                      '25%',
                      remainingBalance * 0.25,
                    ),
                    _buildQuickAmountButton(context, '\$100', 100),
                    _buildQuickAmountButton(context, '\$500', 500),
                    _buildQuickAmountButton(context, '\$1,000', 1000),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickAmountButton(
    BuildContext context,
    String label,
    double amount,
  ) {
    final isValid = amount > 0 && amount <= controller.remainingBalance;

    return CustomButton(
      text: label,
      type: ButtonType.outline,
      onPressed:
          isValid
              ? () {
                controller.paymentAmountController.text = amount
                    .toStringAsFixed(2);
                Navigator.of(context).pop();
              }
              : null,
      backgroundColor: isValid ? null : Colors.grey.shade200,
      textColor: isValid ? null : Colors.grey.shade500,
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt;
      case PaymentMethod.credit:
        return Icons.account_balance_wallet;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }
}

// Widget para mostrar el formulario en un diálogo
class InvoicePaymentDialog extends StatelessWidget {
  final InvoiceDetailController controller;

  const InvoicePaymentDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: context.isMobile ? double.infinity : 500,
        padding: const EdgeInsets.all(24),
        child: InvoicePaymentFormWidget(
          controller: controller,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: () {
            controller.addPayment();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
