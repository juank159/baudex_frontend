// lib/features/customer_credits/presentation/widgets/credit_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer_credit_model.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';
import '../pages/add_credit_payment_page.dart';
import 'add_amount_dialog.dart';

/// Diálogo para ver detalle de un crédito
class CreditDetailDialog extends StatefulWidget {
  final String creditId;

  const CreditDetailDialog({
    super.key,
    required this.creditId,
  });

  @override
  State<CreditDetailDialog> createState() => _CreditDetailDialogState();
}

class _CreditDetailDialogState extends State<CreditDetailDialog> {
  bool _isLoading = true;
  CustomerCredit? _credit;
  List<CreditTransactionModel> _transactions = [];

  final currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$ ',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final controller = Get.find<CustomerCreditController>();
    final credit = await controller.getCreditById(widget.creditId);

    if (credit != null) {
      await controller.loadCreditTransactions(widget.creditId);
    }

    if (!mounted) return;

    setState(() {
      _credit = credit;
      _transactions = controller.currentCreditTransactions.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _credit == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('No se pudo cargar el crédito'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final credit = _credit!;
    final statusColor = _getStatusColor(credit.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encabezado
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Icon(
                  Icons.credit_card,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.customerName ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (credit.invoiceNumber != null)
                      Text(
                        'Factura: ${credit.invoiceNumber}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        credit.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Contenido
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Montos
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountCard(
                        'Monto Original',
                        credit.originalAmount,
                        Colors.grey,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountCard(
                        'Abonado',
                        credit.paidAmount,
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountCard(
                        'Saldo',
                        credit.balanceDue,
                        credit.isOverdue ? Colors.red : Colors.orange,
                        Icons.account_balance,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Barra de progreso
                const Text(
                  'Progreso de pago',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: credit.paidPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      credit.status == CreditStatus.paid ? Colors.green : statusColor,
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${credit.paidPercentage.toStringAsFixed(1)}% pagado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),

                const SizedBox(height: 24),

                // Información adicional
                _buildInfoSection(credit),

                const SizedBox(height: 24),

                // Historial de movimientos (transacciones)
                _buildTransactionsSection(),
              ],
            ),
          ),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              if (credit.canBeCancelled)
                OutlinedButton.icon(
                  onPressed: () => _confirmCancelCredit(),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              const Spacer(),
              if (credit.canReceivePayment) ...[
                OutlinedButton.icon(
                  onPressed: () => _showAddAmountDialog(),
                  icon: const Icon(Icons.trending_up, size: 18),
                  label: const Text('Agregar Deuda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Agregar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(CustomerCredit credit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Fecha de creación', DateFormat('dd/MM/yyyy HH:mm').format(credit.createdAt)),
        if (credit.dueDate != null)
          _buildInfoRow(
            'Fecha de vencimiento',
            DateFormat('dd/MM/yyyy').format(credit.dueDate!),
            valueColor: credit.isOverdue ? Colors.red : null,
          ),
        if (credit.description != null)
          _buildInfoRow('Descripción', credit.description!),
        if (credit.notes != null)
          _buildInfoRow('Notas', credit.notes!),
        if (credit.createdByName != null)
          _buildInfoRow('Creado por', credit.createdByName!),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    // Ordenar transacciones por fecha (más recientes primero)
    final sortedTransactions = List<CreditTransactionModel>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Historial de Movimientos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sortedTransactions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sortedTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No hay movimientos registrados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedTransactions.map((transaction) => _buildTransactionItem(transaction)),
      ],
    );
  }

  Widget _buildTransactionItem(CreditTransactionModel transaction) {
    final isPayment = transaction.type == CreditTransactionType.payment ||
        transaction.type == CreditTransactionType.balanceUsed;
    final isCharge = transaction.type == CreditTransactionType.charge;
    final isDebtIncrease = transaction.type == CreditTransactionType.debtIncrease;

    Color transactionColor;
    IconData transactionIcon;
    String transactionLabel;
    String transactionSign;

    if (isPayment) {
      transactionColor = Colors.green;
      transactionIcon = transaction.type == CreditTransactionType.balanceUsed
          ? Icons.account_balance_wallet
          : Icons.payment;
      transactionLabel = transaction.type == CreditTransactionType.balanceUsed
          ? 'Saldo a Favor Aplicado'
          : 'Pago';
      transactionSign = '-';
    } else if (isCharge) {
      transactionColor = Colors.blue;
      transactionIcon = Icons.receipt_long;
      transactionLabel = 'Deuda Inicial';
      transactionSign = '+';
    } else if (isDebtIncrease) {
      transactionColor = Colors.orange;
      transactionIcon = Icons.trending_up;
      transactionLabel = 'Aumento de Deuda';
      transactionSign = '+';
    } else {
      transactionColor = Colors.grey;
      transactionIcon = Icons.swap_horiz;
      transactionLabel = 'Movimiento';
      transactionSign = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: transactionColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: transactionColor.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transactionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transactionIcon,
              color: transactionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transactionSign,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transactionColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      currencyFormat.format(transaction.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transactionColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  transactionLabel,
                  style: TextStyle(
                    color: transactionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (transaction.description != null && transaction.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Saldo después: ${currencyFormat.format(transaction.balanceAfter)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return Colors.orange;
      case CreditStatus.partiallyPaid:
        return Colors.blue;
      case CreditStatus.paid:
        return Colors.green;
      case CreditStatus.cancelled:
        return Colors.grey;
      case CreditStatus.overdue:
        return Colors.red;
    }
  }

  void _showAddPaymentDialog() async {
    Get.back(); // Cerrar este diálogo
    final result = await Get.to<bool>(
      () => AddCreditPaymentPage(credit: _credit!),
      transition: Transition.rightToLeft,
    );
    // Si se registró el pago exitosamente, recargar los datos
    if (result == true) {
      final controller = Get.find<CustomerCreditController>();
      controller.loadCredits();
      controller.loadStats();
    }
  }

  void _showAddAmountDialog() {
    Get.back(); // Cerrar este diálogo
    Get.dialog(
      AddAmountDialog(credit: _credit!),
      barrierDismissible: false,
    );
  }

  void _confirmCancelCredit() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Crédito'),
        content: Text(
          '¿Está seguro de cancelar este crédito de ${currencyFormat.format(_credit!.originalAmount)}?\n\nEsta acción restaurará el saldo pendiente al cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<CustomerCreditController>();
              final success = await controller.cancelCredit(_credit!.id);
              if (success) {
                Get.back(); // Cerrar el diálogo de detalle
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}
