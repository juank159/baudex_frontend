// lib/features/invoices/presentation/widgets/invoice_status_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
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
        return 'PARCIAL';
      case InvoiceStatus.credited:
        return 'ACREDITADA';
      case InvoiceStatus.partiallyCredited:
        return 'NC PARCIAL';
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
              ] else if (invoice.isDueSoon) ...[
                const SizedBox(width: 8),
                _buildDueSoonBadge(context),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '${invoice.daysOverdue} día${invoice.daysOverdue == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueSoonBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '${invoice.daysUntilDue} día${invoice.daysUntilDue == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgress(BuildContext context) {
    final progress =
        invoice.total > 0 ? invoice.paidAmount / invoice.total : 0.0;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Tamaños responsivos
    final labelSize = isMobile ? 11.0 : (isTablet ? 12.0 : 11.0);
    final valueSize = isMobile ? 10.0 : (isTablet ? 11.0 : 10.0);
    final percentSize = isMobile ? 12.0 : (isTablet ? 13.0 : 12.0);
    final progressHeight = isMobile ? 6.0 : (isTablet ? 7.0 : 6.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: isMobile ? 14 : 16,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Progreso de Pago',
                        style: TextStyle(
                          fontSize: labelSize,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: isMobile ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: percentSize,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(progressHeight / 2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              minHeight: progressHeight,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.successGradient.colors.first,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Pagado: ${AppFormatters.formatCurrency(invoice.paidAmount)}',
                        style: TextStyle(
                          fontSize: valueSize,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.warningGradient.colors.first,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Pendiente: ${AppFormatters.formatCurrency(invoice.balanceDue)}',
                        style: TextStyle(
                          fontSize: valueSize,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
      case InvoiceStatus.credited:
        return Colors.purple; // Morado para facturas totalmente acreditadas
      case InvoiceStatus.partiallyCredited:
        return Colors.deepPurple; // Morado oscuro para NC parcial
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
      case InvoiceStatus.credited:
        return Icons.receipt_long; // Icono de nota de crédito
      case InvoiceStatus.partiallyCredited:
        return Icons.receipt; // Icono de NC parcial
    }
  }

  String _getStatusDescription() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return 'Factura en borrador, lista para confirmar';

      case InvoiceStatus.pending:
        if (invoice.isOverdue) {
          return 'Factura vencida hace ${invoice.daysOverdue} día${invoice.daysOverdue == 1 ? '' : 's'}';
        }
        if (invoice.isDueSoon) {
          return 'Vence en ${invoice.daysUntilDue} día${invoice.daysUntilDue == 1 ? '' : 's'}';
        }
        if (invoice.daysUntilDue > 0) {
          return 'Vence en ${invoice.daysUntilDue} días';
        }
        return 'Factura pendiente de pago';

      case InvoiceStatus.paid:
        return 'Factura pagada completamente';

      case InvoiceStatus.overdue:
        return 'Factura vencida hace ${invoice.daysOverdue} día${invoice.daysOverdue == 1 ? '' : 's'}';

      case InvoiceStatus.cancelled:
        return 'Factura cancelada';

      case InvoiceStatus.partiallyPaid:
        if (invoice.isOverdue) {
          return 'Pago parcial, saldo vencido hace ${invoice.daysOverdue} día${invoice.daysOverdue == 1 ? '' : 's'}';
        }
        if (invoice.isDueSoon) {
          return 'Pago parcial, saldo vence en ${invoice.daysUntilDue} día${invoice.daysUntilDue == 1 ? '' : 's'}';
        }
        if (invoice.daysUntilDue > 0) {
          return 'Pago parcial, saldo vence en ${invoice.daysUntilDue} días';
        }
        return 'Pago parcial recibido';

      case InvoiceStatus.credited:
        return 'Factura anulada por nota de crédito';

      case InvoiceStatus.partiallyCredited:
        return 'Factura con nota de crédito parcial aplicada';
    }
  }
}
