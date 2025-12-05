// lib/features/invoices/presentation/widgets/payment_history_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_payment.dart';

class PaymentHistoryWidget extends StatelessWidget {
  final Invoice invoice;
  final bool showSummary;

  const PaymentHistoryWidget({
    super.key,
    required this.invoice,
    this.showSummary = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummary) _buildPaymentSummary(context),
        if (showSummary) SizedBox(height: Responsive.isMobile(context) ? 12 : 16),
        _buildPaymentTimeline(context),
      ],
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final totalPaid = invoice.paidAmount;
    final remainingBalance = invoice.balanceDue;
    final progressPercentage = invoice.total > 0 ? (totalPaid / invoice.total) : 0.0;

    // Tamaños adaptativos
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final cardPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final titleFontSize = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final verticalSpacing = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: ElegantLightTheme.primaryBlue,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumen de Pagos',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
              // Badge de progreso compacto
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: progressPercentage >= 1.0
                      ? Colors.green.withValues(alpha: 0.1)
                      : ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: progressPercentage >= 1.0
                        ? Colors.green
                        : ElegantLightTheme.primaryBlue,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: verticalSpacing),

          // Progress Bar más compacto
          Container(
            height: isMobile ? 4 : 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: ElegantLightTheme.backgroundColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progressPercentage.clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercentage >= 1.0
                    ? Colors.green
                    : ElegantLightTheme.primaryBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),

          ResponsiveBuilder(
            mobile: _buildSummaryCompact(context, totalPaid, remainingBalance),
            tablet: _buildSummaryRow(context, totalPaid, remainingBalance),
            desktop: _buildSummaryRow(context, totalPaid, remainingBalance),
          ),
        ],
      ),
    );
  }

  // Versión compacta para móviles - todo en una fila horizontal
  Widget _buildSummaryCompact(BuildContext context, double totalPaid, double remainingBalance) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactSummaryItem(
            context,
            'Total',
            invoice.total,
            Icons.receipt,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildCompactSummaryItem(
            context,
            'Pagado',
            totalPaid,
            Icons.check_circle,
            color: Colors.green,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildCompactSummaryItem(
            context,
            'Saldo',
            remainingBalance,
            Icons.schedule,
            color: remainingBalance > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? ElegantLightTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.formatCurrency(amount),
              style: TextStyle(
                color: color ?? ElegantLightTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Versión en fila para tablets y desktop
  Widget _buildSummaryRow(BuildContext context, double totalPaid, double remainingBalance) {
    final isTablet = Responsive.isTablet(context);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            context,
            'Total Factura',
            invoice.total,
            Icons.receipt,
          ),
        ),
        SizedBox(width: isTablet ? 10 : 16),
        Expanded(
          child: _buildSummaryItem(
            context,
            'Total Pagado',
            totalPaid,
            Icons.check_circle,
            color: Colors.green,
          ),
        ),
        SizedBox(width: isTablet ? 10 : 16),
        Expanded(
          child: _buildSummaryItem(
            context,
            'Saldo Pendiente',
            remainingBalance,
            Icons.schedule,
            color: remainingBalance > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon, {
    Color? color,
  }) {
    final isTablet = Responsive.isTablet(context);
    final padding = isTablet ? 10.0 : 12.0;
    final iconSize = isTablet ? 16.0 : 18.0;
    final labelSize = isTablet ? 11.0 : 12.0;
    final amountSize = isTablet ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color ?? ElegantLightTheme.textSecondary,
                size: iconSize,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.formatCurrency(amount),
              style: TextStyle(
                color: color ?? ElegantLightTheme.textPrimary,
                fontSize: amountSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTimeline(BuildContext context) {
    if (!invoice.hasPayments) {
      return _buildEmptyState(context);
    }

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final cardPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final titleFontSize = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: ElegantLightTheme.primaryBlue,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historial de Pagos',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: isMobile ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${invoice.payments.length} pago${invoice.payments.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: ElegantLightTheme.primaryBlue,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),

          ...invoice.sortedPayments.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            final isLast = index == invoice.sortedPayments.length - 1;

            return _buildPaymentTimelineItem(context, payment, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentTimelineItem(BuildContext context, InvoicePayment payment, bool isLast) {
    final isMobile = Responsive.isMobile(context);
    final timelineHeight = isMobile ? 45.0 : 55.0;
    final dotSize = isMobile ? 8.0 : 10.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator más compacto
          Column(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: timelineHeight,
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Payment content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : (isMobile ? 8 : 12)),
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: ElegantLightTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ResponsiveBuilder(
                mobile: _buildPaymentItemCompact(context, payment),
                tablet: _buildPaymentItemRow(context, payment),
                desktop: _buildPaymentItemRow(context, payment),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Versión compacta para móviles
  Widget _buildPaymentItemCompact(BuildContext context, InvoicePayment payment) {
    return Row(
      children: [
        Icon(
          payment.paymentMethod.icon,
          color: ElegantLightTheme.primaryBlue,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.paymentMethodDisplayName,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yy HH:mm').format(payment.paymentDate),
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          AppFormatters.formatCurrency(payment.amount),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Versión en fila para tablets y desktop
  Widget _buildPaymentItemRow(BuildContext context, InvoicePayment payment) {
    final isTablet = Responsive.isTablet(context);

    return Row(
      children: [
        Icon(
          payment.paymentMethod.icon,
          color: ElegantLightTheme.primaryBlue,
          size: isTablet ? 20 : 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.paymentMethodDisplayName,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: isTablet ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: isTablet ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
        if (payment.reference?.isNotEmpty == true)
          Expanded(
            child: Text(
              'Ref: ${payment.reference}',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: isTablet ? 11 : 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Text(
          AppFormatters.formatCurrency(payment.amount),
          style: TextStyle(
            color: Colors.green,
            fontSize: isTablet ? 14 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isPaidWithoutRecords = invoice.paidAmount > 0 && invoice.payments.isEmpty;
    final isFullyPaid = invoice.status == InvoiceStatus.paid || invoice.balanceDue <= 0;

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final cardPadding = isMobile ? 20.0 : (isTablet ? 28.0 : 36.0);
    final iconContainerSize = isMobile ? 56.0 : (isTablet ? 64.0 : 72.0);
    final iconSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
    final titleSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final subtitleSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Center(
        child: Column(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: isPaidWithoutRecords
                    ? Colors.green.withValues(alpha: 0.1)
                    : ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaidWithoutRecords
                    ? invoice.paymentMethodIcon
                    : Icons.payment_outlined,
                color: isPaidWithoutRecords
                    ? Colors.green
                    : ElegantLightTheme.primaryBlue,
                size: iconSize,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              isPaidWithoutRecords
                  ? 'Pago realizado'
                  : 'No hay pagos registrados',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPaidWithoutRecords
                  ? 'Pagado con ${invoice.paymentMethodDisplayName}'
                  : isFullyPaid
                      ? 'La factura está pagada'
                      : 'Los pagos aparecerán aquí',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: subtitleSize,
              ),
              textAlign: TextAlign.center,
            ),
            if (isPaidWithoutRecords) ...[
              SizedBox(height: isMobile ? 10 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 5 : 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      invoice.paymentMethodIcon,
                      color: Colors.green,
                      size: isMobile ? 14 : 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppFormatters.formatCurrency(invoice.paidAmount),
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
