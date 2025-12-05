// lib/features/invoices/presentation/widgets/invoice_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
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
    // ✅ USAR LAYOUT RESPONSIVE ORIGINAL PERO CORREGIDO
    return ResponsiveLayout(
      mobile: _buildMobileCard(context),
      tablet: _buildMobileCard(context), // Usar mobile para tablet también
      desktop: _buildMobileCard(
        context,
      ), // Usar mobile para desktop también por ahora
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient:
            isSelected
                ? LinearGradient(
                  colors: [
                    ElegantLightTheme.primaryGradient.colors.first.withValues(
                      alpha: 0.15,
                    ),
                    ElegantLightTheme.primaryGradient.colors.last.withValues(
                      alpha: 0.05,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected
                  ? ElegantLightTheme.primaryGradient.colors.first.withValues(
                    alpha: 0.5,
                  )
                  : ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: ElegantLightTheme.primaryGradient.colors.first
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
                : ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con número, estado y checkbox
                Row(
                  children: [
                    if (isMultiSelectMode) ...[
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onTap?.call(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.number,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.grey.shade900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatDate(invoice.date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InvoiceStatusWidget(invoice: invoice, isCompact: true),
                  ],
                ),
                const SizedBox(height: 3),

                // Cliente con icono elegante
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(
                        alpha: 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.infoGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantLightTheme.infoGradient.colors.first
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          invoice.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Total y método de pago con diseño mejorado
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoChip(
                        AppFormatters.formatCurrency(invoice.total),
                        Icons.attach_money,
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildCompactInfoChip(
                        invoice.shortPaymentMethodName,
                        invoice.paymentMethodIcon,
                        _getPaymentMethodColor(invoice.paymentMethod),
                      ),
                    ),
                  ],
                ),

                // Información de vencimiento con diseño mejorado
                if (invoice.isOverdue || _isDueSoon()) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            invoice.isOverdue
                                ? [Colors.red.shade50, Colors.red.shade100]
                                : [
                                  Colors.orange.shade50,
                                  Colors.orange.shade100,
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            invoice.isOverdue
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            invoice.isOverdue
                                ? Icons.error_outline
                                : Icons.warning_amber,
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            invoice.isOverdue
                                ? 'Vencida hace ${invoice.daysOverdue} días'
                                : 'Vence en ${_daysUntilDue()} días',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  invoice.isOverdue
                                      ? Colors.red.shade800
                                      : Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Progreso de pago
                if (invoice.isPartiallyPaid) ...[
                  const SizedBox(height: 4),
                  _buildPaymentProgress(context),
                ],

                // Acciones rápidas
                if (!isMultiSelectMode) ...[
                  const SizedBox(height: 3),
                  _buildQuickActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.06)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                if (isMultiSelectMode) ...[
                  Transform.scale(
                    scale: 1.05,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap?.call(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Información principal
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.number,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.grey.shade900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InvoiceStatusWidget(
                            invoice: invoice,
                            isCompact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              invoice.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(invoice.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fechas y vencimiento
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          invoice.isOverdue
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            invoice.isOverdue
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vencimiento',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(invoice.dueDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade700
                                    : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (invoice.isOverdue)
                          Text(
                            '${invoice.daysOverdue} días vencida',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Total y método de pago
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          AppFormatters.formatCurrency(invoice.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (invoice.isPartiallyPaid) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 12,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              AppFormatters.formatCurrency(invoice.paidAmount),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              AppFormatters.formatCurrency(invoice.balanceDue),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentMethodColor(
                            invoice.paymentMethod,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getPaymentMethodColor(
                              invoice.paymentMethod,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              invoice.paymentMethodIcon,
                              size: 12,
                              color: _getPaymentMethodColor(
                                invoice.paymentMethod,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              invoice.shortPaymentMethodName,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getPaymentMethodColor(
                                  invoice.paymentMethod,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Acciones
                if (!isMultiSelectMode) ...[
                  const SizedBox(width: 12),
                  _buildActionMenu(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.04)
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
          width: isSelected ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (isMultiSelectMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 12),
                ],

                // Número y estado
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.number,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            InvoiceStatusWidget(
                              invoice: invoice,
                              isCompact: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Cliente con icono y método de pago debajo
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 10,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                invoice.customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPaymentMethodColor(
                              invoice.paymentMethod,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getPaymentMethodColor(
                                invoice.paymentMethod,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                invoice.paymentMethodIcon,
                                size: 8,
                                color: _getPaymentMethodColor(
                                  invoice.paymentMethod,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                invoice.shortPaymentMethodName,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: _getPaymentMethodColor(
                                    invoice.paymentMethod,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fecha de emisión
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emisión',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(invoice.date),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Vencimiento con indicador visual
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          invoice.isOverdue
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            invoice.isOverdue
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vence',
                          style: TextStyle(
                            fontSize: 8,
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade600
                                    : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(invoice.dueDate),
                          style: TextStyle(
                            color:
                                invoice.isOverdue
                                    ? Colors.red.shade700
                                    : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (invoice.isOverdue)
                          Text(
                            '+${invoice.daysOverdue}d',
                            style: TextStyle(
                              fontSize: 7,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 28),
                // Total destacado
                SizedBox(
                  width: 100,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(invoice.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (invoice.isPartiallyPaid) ...[
                          const SizedBox(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 8,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 1),
                              Text(
                                AppFormatters.formatCurrency(
                                  invoice.paidAmount,
                                ),
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Acciones
                if (!isMultiSelectMode) ...[
                  const SizedBox(width: 8),
                  _buildActionMenu(context),
                ],
              ],
            ),
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
    final percentage = (progress * 100).clamp(0.0, 100.0);

    // Color basado en progreso
    final Color progressColor;
    if (percentage >= 75) {
      progressColor = Colors.green;
    } else if (percentage >= 50) {
      progressColor = Colors.blue;
    } else if (percentage >= 25) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.shade400;
    }

    // ✅ VERSIÓN COMPACTA Y ELEGANTE para todas las pantallas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withValues(alpha: 0.08),
            progressColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea 1: Barra de progreso con porcentaje integrado
          Row(
            children: [
              // Barra de progreso expandible
              Expanded(
                child: _buildCompactAnimatedProgressBar(
                  progress: progress,
                  color: progressColor,
                  height: 8,
                ),
              ),
              const SizedBox(width: 8),
              // Porcentaje compacto animado
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [progressColor, progressColor.withValues(alpha: 0.85)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withValues(alpha: 0.35),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${animatedValue.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Línea 2: Montos en formato completo
          Row(
            children: [
              Icon(Icons.check_circle, size: 10, color: Colors.green.shade600),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  AppFormatters.formatCurrency(invoice.paidAmount),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 1,
                height: 10,
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 6),
              Icon(Icons.schedule, size: 10, color: Colors.orange.shade600),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  AppFormatters.formatCurrency(invoice.balanceDue),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra de progreso compacta animada con shimmer
  Widget _buildCompactAnimatedProgressBar({
    required double progress,
    required Color color,
    double height = 6,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color,
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: _ShimmerEffect(color: color, height: height),
              ),
            ),
          );
        },
      ),
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
    final gradient = LinearGradient(
      colors: [color, color.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryGradient.colors.first.withValues(
              alpha: 0.2,
            ),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) => onActionTap?.call(value),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.transparent,
        elevation: 0,
        itemBuilder:
            (context) => [
              if (invoice.canBeEdited)
                PopupMenuItem(
                  value: 'edit',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Editar',
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              PopupMenuItem(
                value: 'print',
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade600,
                              Colors.grey.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.print,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Imprimir',
                        style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (invoice.status == InvoiceStatus.draft)
                PopupMenuItem(
                  value: 'confirm',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.successGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Confirmar',
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (invoice.canBeCancelled)
                PopupMenuItem(
                  value: 'cancel',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.warningGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.cancel,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (invoice.canBeEdited)
                PopupMenuItem(
                  value: 'delete',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.errorGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
      ),
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
      case PaymentMethod.clientBalance:
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
        (invoice.status == InvoiceStatus.pending ||
            invoice.status == InvoiceStatus.partiallyPaid);
  }

  int _daysUntilDue() {
    return invoice.dueDate.difference(DateTime.now()).inDays;
  }

  // ==================== MÉTODOS DE UI ELEGANTES ====================

  /// Construye un chip de información elegante para las cards móviles
  // Nueva función ultra-compacta
  Widget _buildCompactInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Nuevas funciones auxiliares
  String _getShortPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'T.Crédito';
      case PaymentMethod.debitCard:
        return 'T.Débito';
      case PaymentMethod.bankTransfer:
        return 'Transfer';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.credit:
        return 'Crédito';
      case PaymentMethod.clientBalance:
        return 'Saldo a Favor';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.creditCard:
        return Colors.blue;
      case PaymentMethod.debitCard:
        return Colors.indigo;
      case PaymentMethod.bankTransfer:
        return Colors.purple;
      case PaymentMethod.check:
        return Colors.teal;
      case PaymentMethod.credit:
        return Colors.orange; // Naranja como pendiente
      case PaymentMethod.clientBalance:
        return Colors.teal; // Verde azulado para saldo a favor
      case PaymentMethod.other:
        return Colors.grey;
    }
  }

  // ==================== MÉTODOS PARA INFORMACIÓN DE PAGO EN EFECTIVO ====================

  /// Verifica si la factura tiene información de pago en efectivo (dinero recibido y cambio)
  bool _hasPaymentDetails() {
    if (invoice.paymentMethod != PaymentMethod.cash) return false;
    if (invoice.notes == null || invoice.notes!.isEmpty) return false;

    return invoice.notes!.contains('Recibido:') &&
        invoice.notes!.contains('Cambio:');
  }

  /// Extrae el monto recibido de las notas de la factura
  double _getReceivedAmount() {
    if (!_hasPaymentDetails()) return 0.0;

    try {
      final notes = invoice.notes!;
      // RegExp más robusto que maneja números con y sin formato de miles (punto como separador)
      final recibidoMatch = RegExp(
        r'Recibido:\s*\$?\s*([\d.,]+)',
      ).firstMatch(notes);

      if (recibidoMatch != null) {
        String amountStr = recibidoMatch.group(1)!;
        // Limpiar formato de miles colombiano (puntos) pero preservar decimales (comas)
        amountStr = amountStr.replaceAll(
          RegExp(r'\.(?=\d{3})'),
          '',
        ); // Remover puntos de miles
        amountStr = amountStr.replaceAll(
          ',',
          '.',
        ); // Convertir comas decimales a puntos
        return double.tryParse(amountStr) ?? 0.0;
      }
    } catch (e) {
      // Silencioso en producción, pero útil para debug
      // print('Error extrayendo monto recibido: $e');
    }

    return 0.0;
  }

  /// Extrae el monto del cambio de las notas de la factura
  double _getChangeAmount() {
    if (!_hasPaymentDetails()) return 0.0;

    try {
      final notes = invoice.notes!;
      // RegExp más robusto que maneja números con y sin formato de miles (punto como separador)
      final cambioMatch = RegExp(
        r'Cambio:\s*\$?\s*([\d.,]+)',
      ).firstMatch(notes);

      if (cambioMatch != null) {
        String amountStr = cambioMatch.group(1)!;
        // Limpiar formato de miles colombiano (puntos) pero preservar decimales (comas)
        amountStr = amountStr.replaceAll(
          RegExp(r'\.(?=\d{3})'),
          '',
        ); // Remover puntos de miles
        amountStr = amountStr.replaceAll(
          ',',
          '.',
        ); // Convertir comas decimales a puntos
        return double.tryParse(amountStr) ?? 0.0;
      }
    } catch (e) {
      // Silencioso en producción, pero útil para debug
      // print('Error extrayendo cambio: $e');
    }

    return 0.0;
  }

  /// Widget para mostrar información de pago en efectivo (versión móvil completa)
  Widget _buildCashPaymentDetails(BuildContext context) {
    final receivedAmount = _getReceivedAmount();
    final changeAmount = _getChangeAmount();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.money, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'Pago en Efectivo',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recibido:',
                style: TextStyle(fontSize: 10, color: Colors.green.shade700),
              ),
              Text(
                AppFormatters.formatCurrency(receivedAmount),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (changeAmount > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambio:',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
                Text(
                  AppFormatters.formatCurrency(changeAmount),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Widget compacto para mostrar información de pago en efectivo (versiones tablet/desktop)
  Widget _buildCashPaymentDetailsCompact() {
    final receivedAmount = _getReceivedAmount();
    final changeAmount = _getChangeAmount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rec: ${AppFormatters.formatCurrency(receivedAmount)}',
          style: TextStyle(
            fontSize: 9,
            color: Colors.green.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (changeAmount > 0)
          Text(
            'Cambio: ${AppFormatters.formatCurrency(changeAmount)}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  // ✅ LAYOUT UNIFICADO QUE FUNCIONA EN TODAS LAS PANTALLAS
  Widget _buildUnifiedCard(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final isTablet =
        MediaQuery.of(context).size.width > 650 &&
        MediaQuery.of(context).size.width <= 1100;

    return Container(
      margin: EdgeInsets.only(
        bottom:
            isDesktop
                ? 3
                : isTablet
                ? 10
                : 2,
      ),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withOpacity(
                  isDesktop
                      ? 0.04
                      : isTablet
                      ? 0.06
                      : 0.08,
                )
                : Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop
              ? 8
              : isTablet
              ? 12
              : 8,
        ),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
          width:
              isSelected
                  ? (isDesktop
                      ? 1.2
                      : isTablet
                      ? 1.5
                      : 2)
                  : (isDesktop ? 0.8 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDesktop
                  ? 0.02
                  : isTablet
                  ? 0.03
                  : 0.04,
            ),
            blurRadius:
                isDesktop
                    ? 4
                    : isTablet
                    ? 6
                    : 8,
            offset: Offset(0, isDesktop ? 1 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 8
                : isTablet
                ? 12
                : 8,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isDesktop
                      ? 12
                      : isTablet
                      ? 18
                      : 16,
              vertical:
                  isDesktop
                      ? 8
                      : isTablet
                      ? 18
                      : 16,
            ),
            child: Row(
              children: [
                if (isMultiSelectMode) ...[
                  Transform.scale(
                    scale: isTablet ? 1.05 : 1.0,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap?.call(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      visualDensity: isDesktop ? VisualDensity.compact : null,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 16),
                ],

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Número de factura
                          Expanded(
                            child: Text(
                              invoice.number,
                              style: TextStyle(
                                fontSize:
                                    isDesktop
                                        ? 13
                                        : isTablet
                                        ? 15
                                        : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // Estado de la factura
                          InvoiceStatusWidget(
                            invoice: invoice,
                            isCompact: true,
                          ),
                        ],
                      ),

                      SizedBox(
                        height:
                            isDesktop
                                ? 4
                                : isTablet
                                ? 6
                                : 8,
                      ),

                      // Cliente y fecha
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.customerName,
                              style: TextStyle(
                                fontSize:
                                    isDesktop
                                        ? 11
                                        : isTablet
                                        ? 13
                                        : 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          Text(
                            AppFormatters.formatDate(invoice.createdAt),
                            style: TextStyle(
                              fontSize:
                                  isDesktop
                                      ? 10
                                      : isTablet
                                      ? 11
                                      : 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height:
                            isDesktop
                                ? 4
                                : isTablet
                                ? 6
                                : 8,
                      ),

                      // Monto y vencimiento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Monto
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 9
                                          : isTablet
                                          ? 10
                                          : 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                AppFormatters.formatCurrency(invoice.total),
                                style: TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 12
                                          : isTablet
                                          ? 14
                                          : 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),

                          // Fecha de vencimiento
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Vence',
                                style: TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 9
                                          : isTablet
                                          ? 10
                                          : 11,
                                  color:
                                      invoice.isOverdue
                                          ? Colors.red.shade600
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                AppFormatters.formatDate(invoice.dueDate!),
                                style: TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 11
                                          : isTablet
                                          ? 12
                                          : 13,
                                  color:
                                      invoice.isOverdue
                                          ? Colors.red.shade700
                                          : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ✅ ACCIONES RÁPIDAS (incluyendo imprimir)
                if (!isMultiSelectMode) ...[
                  SizedBox(
                    height:
                        isDesktop
                            ? 8
                            : isTablet
                            ? 12
                            : 8,
                  ),
                  _buildQuickActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de efecto shimmer animado para barras de progreso
class _ShimmerEffect extends StatefulWidget {
  final Color color;
  final double height;

  const _ShimmerEffect({
    required this.color,
    required this.height,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
