// lib/features/customers/presentation/widgets/modern_customer_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/customer.dart';

class ModernCustomerCardWidget extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ModernCustomerCardWidget({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isMobile(context)
        ? _buildMobileCard(context)
        : _buildDesktopCard(context);
  }

  Widget _buildMobileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header compacto
                Row(
                  children: [
                    // Avatar con gradiente circular
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient(),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        customer.companyName != null ? Icons.business : Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info principal compacta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ElegantLightTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Badge de estado con gradiente
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient().scale(0.3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info adicional ultra compacta
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.credit_card,
                        _formatCurrency(customer.creditLimit),
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.shopping_cart,
                        '${customer.totalOrders}',
                        ElegantLightTheme.accentOrange,
                      ),
                    ),
                    if (customer.currentBalance > 0) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildCompactInfoChip(
                          Icons.account_balance_wallet,
                          _formatCurrency(customer.currentBalance),
                          customer.currentBalance > customer.creditLimit * 0.8
                              ? Colors.red.shade600
                              : ElegantLightTheme.accentOrange,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Acciones compactas con gradiente
                Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: _buildActionButton(
                          'Editar',
                          Icons.edit,
                          ElegantLightTheme.primaryBlue,
                          onEdit!,
                        ),
                      ),
                    if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      Expanded(
                        child: _buildActionButton(
                          'Eliminar',
                          Icons.delete,
                          Colors.red.shade600,
                          onDelete!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar con gradiente
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    customer.companyName != null ? Icons.business : Icons.person,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),

                // Info principal
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ElegantLightTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: _getStatusGradient().scale(0.3),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor().withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: ElegantLightTheme.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ElegantLightTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.badge, size: 14, color: ElegantLightTheme.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            customer.formattedDocument,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Info adicional compacta
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopInfoRow(
                        Icons.credit_card,
                        'Crédito',
                        _formatCurrency(customer.creditLimit),
                        ElegantLightTheme.primaryBlue,
                      ),
                      const SizedBox(height: 4),
                      _buildDesktopInfoRow(
                        Icons.shopping_cart,
                        'Órdenes',
                        '${customer.totalOrders}',
                        ElegantLightTheme.accentOrange,
                      ),
                      if (customer.currentBalance > 0) ...[
                        const SizedBox(height: 4),
                        _buildDesktopInfoRow(
                          Icons.account_balance_wallet,
                          'Balance',
                          _formatCurrency(customer.currentBalance),
                          customer.currentBalance > customer.creditLimit * 0.8
                              ? Colors.red.shade600
                              : ElegantLightTheme.accentOrange,
                        ),
                      ],
                    ],
                  ),
                ),

                // Acciones con gradiente
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      Tooltip(
                        message: 'Editar cliente',
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: ElegantLightTheme.glowShadow,
                          ),
                          child: IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 18),
                            color: ElegantLightTheme.primaryBlue,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    if (onDelete != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      Tooltip(
                        message: 'Eliminar cliente',
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.errorGradient.scale(0.2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade600.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red.shade600,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
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

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    final gradient = color == ElegantLightTheme.primaryBlue
        ? ElegantLightTheme.primaryGradient
        : ElegantLightTheme.errorGradient;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient.scale(0.2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (customer.status) {
      case CustomerStatus.active:
        return Colors.green.shade600;
      case CustomerStatus.inactive:
        return ElegantLightTheme.accentOrange;
      case CustomerStatus.suspended:
        return Colors.red.shade600;
    }
  }

  LinearGradient _getStatusGradient() {
    switch (customer.status) {
      case CustomerStatus.active:
        return ElegantLightTheme.successGradient;
      case CustomerStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case CustomerStatus.suspended:
        return ElegantLightTheme.errorGradient;
    }
  }

  String _getStatusText() {
    switch (customer.status) {
      case CustomerStatus.active:
        return 'ACTIVO';
      case CustomerStatus.inactive:
        return 'INACTIVO';
      case CustomerStatus.suspended:
        return 'SUSPENDIDO';
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '\$0';
    }

    final absoluteAmount = amount.abs();
    final isNegative = amount < 0;
    String result;

    if (absoluteAmount >= 1000000) {
      result = '\$${(absoluteAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absoluteAmount >= 1000) {
      result = '\$${(absoluteAmount / 1000).toStringAsFixed(1)}K';
    } else {
      result = '\$${absoluteAmount.toStringAsFixed(0)}';
    }

    return isNegative ? '-$result' : result;
  }
}