// lib/features/invoices/presentation/widgets/invoice_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../widgets/invoice_status_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceCardWidget extends StatelessWidget {
  final Invoice invoice;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String)? onActionTap;

  const InvoiceCardWidget({
    super.key,
    required this.invoice,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onTap,
    this.onLongPress,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileCard(context),
      tablet: _buildTabletCard(context),
      desktop: _buildDesktopCard(context),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      border:
          isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con número y estado
              Row(
                children: [
                  if (isMultiSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap?.call(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.number,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(invoice.date),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InvoiceStatusWidget(invoice: invoice, isCompact: true),
                ],
              ),
              const SizedBox(height: 12),

              // Cliente
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      invoice.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total y método de pago
              Row(
                children: [
                  _buildInfoChip(
                    '\$${invoice.total.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    invoice.paymentMethodDisplayName,
                    _getPaymentMethodIcon(invoice.paymentMethod),
                    Colors.blue,
                  ),
                ],
              ),

              // Información de vencimiento
              if (invoice.isOverdue || _isDueSoon()) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        invoice.isOverdue
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          invoice.isOverdue
                              ? Colors.red.shade200
                              : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        invoice.isOverdue ? Icons.error : Icons.warning,
                        color:
                            invoice.isOverdue
                                ? Colors.red.shade600
                                : Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          invoice.isOverdue
                              ? 'Vencida hace ${invoice.daysOverdue} días'
                              : 'Vence en ${_daysUntilDue()} días',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Progreso de pago para facturas parcialmente pagadas
              if (invoice.isPartiallyPaid) ...[
                const SizedBox(height: 8),
                _buildPaymentProgress(context),
              ],

              // Acciones rápidas
              if (!isMultiSelectMode) ...[
                const SizedBox(height: 12),
                _buildQuickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletCard(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      border:
          isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isMultiSelectMode) ...[
                Checkbox(value: isSelected, onChanged: (_) => onTap?.call()),
                const SizedBox(width: 12),
              ],

              // Información principal
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          invoice.number,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InvoiceStatusWidget(invoice: invoice, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      _formatDate(invoice.date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Fechas
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vencimiento',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatDate(invoice.dueDate),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            invoice.isOverdue
                                ? Colors.red.shade600
                                : Colors.grey.shade800,
                      ),
                    ),
                    if (invoice.isOverdue)
                      Text(
                        '${invoice.daysOverdue} días vencida',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              // Total
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${invoice.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (invoice.isPartiallyPaid) ...[
                      Text(
                        'Pagado: \$${invoice.paidAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        'Pendiente: \$${invoice.balanceDue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones
              if (!isMultiSelectMode) _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 4),
      backgroundColor:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      border:
          isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isMultiSelectMode) ...[
                Checkbox(value: isSelected, onChanged: (_) => onTap?.call()),
                const SizedBox(width: 12),
              ],

              // Número e indicador
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    InvoiceStatusWidget(invoice: invoice, isCompact: true),
                  ],
                ),
              ),

              // Cliente
              Expanded(
                flex: 2,
                child: Text(
                  invoice.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Fecha
              SizedBox(
                width: 100,
                child: Text(
                  _formatDate(invoice.date),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),

              // Vencimiento
              SizedBox(
                width: 100,
                child: Text(
                  _formatDate(invoice.dueDate),
                  style: TextStyle(
                    color:
                        invoice.isOverdue
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                    fontWeight:
                        invoice.isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),

              // Método de pago
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Icon(
                      _getPaymentMethodIcon(invoice.paymentMethod),
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        invoice.paymentMethodDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Total
              SizedBox(
                width: 100,
                child: Text(
                  '\$${invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              // Acciones
              if (!isMultiSelectMode) _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgress(BuildContext context) {
    final progress =
        invoice.total > 0 ? invoice.paidAmount / invoice.total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de Pago',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        if (invoice.canBeEdited) ...[
          _buildActionButton(
            'Editar',
            Icons.edit,
            Colors.blue,
            () => onActionTap?.call('edit'),
          ),
          const SizedBox(width: 8),
        ],
        if (invoice.status == InvoiceStatus.draft) ...[
          _buildActionButton(
            'Confirmar',
            Icons.check_circle,
            Colors.green,
            () => onActionTap?.call('confirm'),
          ),
          const SizedBox(width: 8),
        ],
        _buildActionButton(
          'Imprimir',
          Icons.print,
          Colors.grey,
          () => onActionTap?.call('print'),
        ),
        const Spacer(),
        _buildActionMenu(context),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => onActionTap?.call(value),
      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
      itemBuilder:
          (context) => [
            if (invoice.canBeEdited)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 16),
                  SizedBox(width: 8),
                  Text('Imprimir'),
                ],
              ),
            ),
            if (invoice.status == InvoiceStatus.draft)
              const PopupMenuItem(
                value: 'confirm',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Confirmar'),
                  ],
                ),
              ),
            if (invoice.canBeCancelled)
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text('Cancelar'),
                  ],
                ),
              ),
            if (invoice.canBeEdited)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
          ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isDueSoon() {
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 3 &&
        daysUntilDue > 0 &&
        invoice.status == InvoiceStatus.pending;
  }

  int _daysUntilDue() {
    return invoice.dueDate.difference(DateTime.now()).inDays;
  }
}
