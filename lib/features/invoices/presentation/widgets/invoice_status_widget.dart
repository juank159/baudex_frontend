// lib/features/invoices/presentation/widgets/invoice_status_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../domain/entities/invoice.dart';

class InvoiceStatusWidget extends StatelessWidget {
  final Invoice invoice;
  final bool showDescription;
  final bool isCompact;

  const InvoiceStatusWidget({
    super.key,
    required this.invoice,
    this.showDescription = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 4.0 : 12.0),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child:
          isCompact
              ? _buildCompactContent(context)
              : _buildFullContent(context),
    );
  }

  // Widget _buildCompactContent(BuildContext context) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Icon(_getStatusIcon(), color: _getStatusColor(), size: 16),
  //       const SizedBox(width: 4),
  //       Text(
  //         invoice.statusDisplayName,
  //         style: TextStyle(
  //           color: _getStatusColor(),
  //           fontWeight: FontWeight.w600,
  //           fontSize: 12,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCompactContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getStatusIcon(), color: _getStatusColor(), size: 12),
        const SizedBox(width: 2),
        Flexible(
          // ✅ CAMBIO: Row -> Flexible para evitar overflow
          child: Text(
            _getCompactStatusText(), // ✅ CAMBIO: usar texto más corto
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
            maxLines: 1, // ✅ AÑADIDO: maxLines
            overflow: TextOverflow.ellipsis, // ✅ AÑADIDO: overflow
          ),
        ),
      ],
    );
  }

  String _getCompactStatusText() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return 'BORRADOR';
      case InvoiceStatus.pending:
        return invoice.isOverdue ? 'VENCIDA' : 'PENDIENTE';
      case InvoiceStatus.paid:
        return 'PAGADA';
      case InvoiceStatus.overdue:
        return 'VENCIDA';
      case InvoiceStatus.cancelled:
        return 'CANCELADA';
      case InvoiceStatus.partiallyPaid:
        return 'PARCIAL'; // ✅ TEXTO MÁS CORTO para evitar overflow
    }
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      children: [
        IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: isCompact ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      invoice.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: TextStyle(
                          color: _getStatusColor().withValues(alpha: 0.8),
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (invoice.isOverdue) ...[
                const SizedBox(width: 8),
                _buildOverdueBadge(context),
              ],
            ],
          ),
        ),

        if (invoice.isPartiallyPaid && !isCompact) ...[
          const SizedBox(height: 12),
          _buildPaymentProgress(context),
        ],
      ],
    );
  }

  Widget _buildOverdueBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${invoice.daysOverdue} días',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: Text(
                'Progreso de Pago',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
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
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: Text(
                'Pagado: \$${invoice.paidAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                'Pendiente: \$${invoice.balanceDue.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return invoice.isOverdue ? Colors.red : Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.partiallyPaid:
        return invoice.isOverdue ? Colors.red : Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.pending:
        return invoice.isOverdue ? Icons.warning : Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.error;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.partiallyPaid:
        return Icons.pie_chart;
    }
  }

  String _getStatusDescription() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return 'Factura en borrador, lista para confirmar';
      case InvoiceStatus.pending:
        if (invoice.isOverdue) {
          return 'Factura vencida hace ${invoice.daysOverdue} días';
        }
        return 'Factura pendiente de pago';
      case InvoiceStatus.paid:
        return 'Factura pagada completamente';
      case InvoiceStatus.overdue:
        return 'Factura vencida hace ${invoice.daysOverdue} días';
      case InvoiceStatus.cancelled:
        return 'Factura cancelada';
      case InvoiceStatus.partiallyPaid:
        if (invoice.isOverdue) {
          return 'Pago parcial, vencida hace ${invoice.daysOverdue} días';
        }
        return 'Pago parcial recibido';
    }
  }
}
