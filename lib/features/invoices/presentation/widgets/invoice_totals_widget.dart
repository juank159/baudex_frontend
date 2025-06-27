// lib/features/invoices/presentation/widgets/invoice_totals_widget.dart
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';

class InvoiceTotalsWidget extends StatelessWidget {
  final InvoiceFormController controller;
  final bool isReadOnly;
  final bool showConfigurable;

  const InvoiceTotalsWidget({
    super.key,
    required this.controller,
    this.isReadOnly = false,
    this.showConfigurable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvoiceFormController>(
      builder:
          (controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showConfigurable && !isReadOnly) ...[
                _buildConfigurableSection(context, controller),
                const SizedBox(height: 16),
              ],
              _buildTotalsSection(context, controller),
            ],
          ),
    );
  }

  Widget _buildConfigurableSection(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de Totales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),

        // Impuestos
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(
                  text: controller.taxPercentage.toString(),
                ),
                label: 'Impuesto (%)',
                hint: '19',
                prefixIcon: Icons.percent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final tax = double.tryParse(value) ?? 19;
                  this.controller.setTaxPercentage(tax);
                },
                validator: (value) {
                  final tax = double.tryParse(value ?? '');
                  if (tax == null || tax < 0 || tax > 100) {
                    return 'Entre 0 y 100';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Impuesto',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                  Text(
                    '\$${controller.taxAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Descuentos
        Text(
          'Descuentos Generales',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(
                  text: controller.discountPercentage.toString(),
                ),
                label: 'Descuento (%)',
                hint: '0',
                prefixIcon: Icons.percent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final discount = double.tryParse(value) ?? 0;
                  controller.setDiscountPercentage(discount);
                },
                validator: (value) {
                  final discount = double.tryParse(value ?? '');
                  if (discount != null && (discount < 0 || discount > 100)) {
                    return 'Entre 0 y 100';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: TextEditingController(
                  text: controller.discountAmount.toString(),
                ),
                label: 'Descuento (\$)',
                hint: '0.00',
                prefixIcon: Icons.money_off,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final discount = double.tryParse(value) ?? 0;
                  controller.setDiscountAmount(discount);
                },
                validator: (value) {
                  final discount = double.tryParse(value ?? '');
                  if (discount != null && discount < 0) {
                    return 'Mayor o igual a 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        if (controller.totalDiscountAmount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Descuento total aplicado: \$${controller.totalDiscountAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalsSection(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de Totales',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items count
          _buildInfoRow(
            'Cantidad de Items:',
            '${controller.invoiceItems.length}',
            icon: Icons.inventory_2,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 8),

          // Subtotal
          _buildTotalRow(
            'Subtotal:',
            controller.subtotal,
            color: Colors.grey.shade700,
          ),

          // Descuentos aplicados
          if (controller.totalDiscountAmount > 0) ...[
            _buildTotalRow(
              'Descuentos:',
              -controller.totalDiscountAmount,
              color: Colors.orange.shade600,
              showMinus: false,
            ),
          ],

          // Impuestos
          _buildTotalRow(
            'Impuestos (${controller.taxPercentage}%):',
            controller.taxAmount,
            color: Colors.grey.shade700,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 2),
          ),

          // Total final
          _buildTotalRow(
            'TOTAL:',
            controller.total,
            isTotal: true,
            color: Theme.of(context).primaryColor,
          ),

          // Información adicional
          if (controller.invoiceItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAdditionalInfo(context, controller),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(color: color ?? Colors.grey.shade700, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
    bool showMinus = true,
  }) {
    final displayAmount = amount < 0 && showMinus ? amount : amount.abs();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            '${amount < 0 && showMinus ? "-" : ""}\$${displayAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Promedio por item
          _buildDetailRow(
            'Promedio por item:',
            '\$${(controller.subtotal / controller.invoiceItems.length).toStringAsFixed(2)}',
          ),

          // Item más costoso
          if (controller.invoiceItems.isNotEmpty) ...[
            _buildDetailRow(
              'Item más costoso:',
              '\$${controller.invoiceItems.map((i) => i.subtotal).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
            ),
          ],

          // Total de descuentos en items
          () {
            final itemDiscounts = controller.invoiceItems
                .map(
                  (item) =>
                      item.quantity *
                          item.unitPrice *
                          item.discountPercentage /
                          100 +
                      item.discountAmount,
                )
                .fold(0.0, (a, b) => a + b);
            if (itemDiscounts > 0) {
              return _buildDetailRow(
                'Descuentos en items:',
                '\$${itemDiscounts.toStringAsFixed(2)}',
              );
            }
            return const SizedBox.shrink();
          }(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget simplificado para mostrar solo totales (para usar en detail screen)
class InvoiceTotalsDisplayWidget extends StatelessWidget {
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double discountPercentage;
  final double discountAmount;
  final double total;
  final double? paidAmount;
  final double? balanceDue;
  final bool showPaymentInfo;

  const InvoiceTotalsDisplayWidget({
    super.key,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.total,
    this.paidAmount,
    this.balanceDue,
    this.showPaymentInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Totales',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18),
            ),
          ),
          const SizedBox(height: 16),

          _buildTotalRow('Subtotal:', subtotal),

          if (discountAmount > 0 || discountPercentage > 0) ...[
            if (discountPercentage > 0)
              _buildTotalRow(
                'Descuento (${discountPercentage}%):',
                -discountAmount,
                color: Colors.orange.shade600,
              ),
            if (discountAmount > 0 && discountPercentage == 0)
              _buildTotalRow(
                'Descuento:',
                -discountAmount,
                color: Colors.orange.shade600,
              ),
          ],

          _buildTotalRow('Impuestos (${taxPercentage}%):', taxAmount),

          const Divider(),

          _buildTotalRow(
            'TOTAL:',
            total,
            isTotal: true,
            color: Theme.of(context).primaryColor,
          ),

          if (showPaymentInfo && paidAmount != null) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              'Pagado:',
              paidAmount!,
              color: Colors.green.shade600,
            ),
            if (balanceDue != null)
              _buildTotalRow(
                'Saldo Pendiente:',
                balanceDue!,
                color:
                    balanceDue! > 0
                        ? Colors.red.shade600
                        : Colors.green.shade600,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
