// lib/features/invoices/presentation/widgets/payment_dialog_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';

class PaymentDialogWidget extends StatefulWidget {
  final double total;
  final Function(double receivedAmount, double change) onPaymentConfirmed;
  final VoidCallback onCancel;

  const PaymentDialogWidget({
    super.key,
    required this.total,
    required this.onPaymentConfirmed,
    required this.onCancel,
  });

  @override
  State<PaymentDialogWidget> createState() => _PaymentDialogWidgetState();
}

class _PaymentDialogWidgetState extends State<PaymentDialogWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _receivedController = TextEditingController();
  final FocusNode _receivedFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  double get receivedAmount => double.tryParse(_receivedController.text) ?? 0;
  double get change => receivedAmount - widget.total;
  bool get isValidPayment => receivedAmount >= widget.total;

  // Valores predefinidos comunes
  final List<double> _quickAmounts = [10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Inicializar con el total exacto
    _receivedController.text = widget.total.toStringAsFixed(0);
    _receivedController.addListener(_onAmountChanged);

    // Iniciar animación
    _animationController.forward();

    // Auto focus al campo de cantidad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _receivedFocusNode.requestFocus();
      _receivedController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _receivedController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _receivedController.dispose();
    _receivedFocusNode.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildDialogContent(context),
          );
        },
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildContent(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Procesar Pago',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total a pagar: \$${widget.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de cantidad recibida
          CustomTextField(
            controller: _receivedController,
            label: 'Cantidad Recibida',
            hint: 'Ingresa el monto recibido',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la cantidad recibida';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < widget.total) {
                return 'La cantidad debe ser mayor o igual al total';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Botones de cantidades rápidas
          Text(
            'Cantidades Rápidas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _quickAmounts.map((amount) {
                  return _buildQuickAmountChip(context, amount);
                }).toList(),
          ),
          const SizedBox(height: 20),

          // Resumen del pago
          _buildPaymentSummary(context),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, double amount) {
    final isSelected = receivedAmount == amount;
    return GestureDetector(
      onTap: () {
        _receivedController.text = amount.toStringAsFixed(0);
        _receivedController.selection = TextSelection.fromPosition(
          TextPosition(offset: _receivedController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValidPayment ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValidPayment ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total a pagar:',
            '\${widget.total.toStringAsFixed(2)}',
            Colors.grey.shade700,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Cantidad recibida:',
            '\${receivedAmount.toStringAsFixed(2)}',
            Colors.grey.shade700,
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            change >= 0 ? 'Cambio:' : 'Faltante:',
            '\${change.abs().toStringAsFixed(2)}',
            isValidPayment ? Colors.green.shade700 : Colors.red.shade700,
            isTotal: true,
          ),

          // Mensaje de estado
          if (!isValidPayment && receivedAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La cantidad recibida es menor al total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isValidPayment && change > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entregar cambio al cliente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isValidPayment && change == 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pago exacto - Sin cambio',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              type: ButtonType.outline,
              onPressed: widget.onCancel,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isValidPayment ? 'Confirmar Pago' : 'Cantidad Insuficiente',
              icon: isValidPayment ? Icons.check : Icons.error,
              onPressed:
                  isValidPayment
                      ? () => widget.onPaymentConfirmed(receivedAmount, change)
                      : null,
              backgroundColor: isValidPayment ? null : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
