// lib/features/invoices/presentation/widgets/payment_history_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
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
        if (showSummary) _buildPaymentSummary(),
        if (showSummary) const SizedBox(height: 20),
        _buildPaymentTimeline(),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final totalPaid = invoice.totalPaidFromPayments;
    final remainingBalance = invoice.remainingBalance;
    final progressPercentage = invoice.total > 0 ? (totalPaid / invoice.total) : 0.0;

    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: ElegantLightTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Resumen de Pagos',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: ElegantLightTheme.backgroundColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 20),
          
          ResponsiveBuilder(
            mobile: _buildSummaryMobile(totalPaid, remainingBalance),
            tablet: _buildSummaryDesktop(totalPaid, remainingBalance),
            desktop: _buildSummaryDesktop(totalPaid, remainingBalance),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMobile(double totalPaid, double remainingBalance) {
    return Column(
      children: [
        _buildSummaryItem('Total Factura', invoice.total, Icons.receipt),
        const SizedBox(height: 16),
        _buildSummaryItem('Total Pagado', totalPaid, Icons.check_circle, 
          color: Colors.green),
        const SizedBox(height: 16),
        _buildSummaryItem('Saldo Pendiente', remainingBalance, Icons.schedule,
          color: remainingBalance > 0 ? Colors.orange : Colors.green),
      ],
    );
  }

  Widget _buildSummaryDesktop(double totalPaid, double remainingBalance) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem('Total Factura', invoice.total, Icons.receipt),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSummaryItem('Total Pagado', totalPaid, Icons.check_circle, 
            color: Colors.green),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSummaryItem('Saldo Pendiente', remainingBalance, Icons.schedule,
            color: remainingBalance > 0 ? Colors.orange : Colors.green),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              color: color ?? ElegantLightTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTimeline() {
    if (!invoice.hasPayments) {
      return _buildEmptyState();
    }

    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: ElegantLightTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Historial de Pagos',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${invoice.payments.length} pago${invoice.payments.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: ElegantLightTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          ...invoice.sortedPayments.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            final isLast = index == invoice.sortedPayments.length - 1;
            
            return _buildPaymentTimelineItem(payment, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentTimelineItem(InvoicePayment payment, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Payment content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ElegantLightTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ResponsiveBuilder(
                mobile: _buildPaymentItemMobile(payment),
                tablet: _buildPaymentItemDesktop(payment),
                desktop: _buildPaymentItemDesktop(payment),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItemMobile(InvoicePayment payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              payment.paymentMethod.icon,
              color: ElegantLightTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                payment.paymentMethodDisplayName,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              AppFormatters.formatCurrency(payment.amount),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        if (payment.reference?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            'Ref: ${payment.reference}',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (payment.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            payment.notes!,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentItemDesktop(InvoicePayment payment) {
    return Row(
      children: [
        Icon(
          payment.paymentMethod.icon,
          color: ElegantLightTheme.primaryBlue,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.paymentMethodDisplayName,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
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
                fontSize: 14,
              ),
            ),
          ),
        Text(
          AppFormatters.formatCurrency(payment.amount),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment_outlined,
                color: ElegantLightTheme.primaryBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pagos registrados',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los pagos realizados aparecerán aquí',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}