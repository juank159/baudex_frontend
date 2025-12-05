// lib/features/customers/presentation/widgets/modern_customer_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/utils/formatters.dart';
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header con avatar y info principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar elegante
                    _buildAvatar(size: 48),
                    const SizedBox(width: 14),

                    // Info principal
                    Expanded(
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
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: ElegantLightTheme.textTertiary,
                              ),
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
                            ],
                          ),
                          if (customer.phone != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: ElegantLightTheme.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  customer.phone!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: ElegantLightTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider sutil
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
              ),

              // Métricas elegantes
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.credit_card_rounded,
                        label: 'Crédito',
                        value: _formatCurrency(customer.creditLimit),
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.shopping_bag_rounded,
                        label: 'Órdenes',
                        value: '${customer.totalOrders}',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Balance',
                        value: _formatCurrency(customer.currentBalance),
                        color: customer.currentBalance > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones
              if (onEdit != null || onDelete != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      if (onEdit != null)
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Editar',
                            color: ElegantLightTheme.primaryBlue,
                            onTap: onEdit!,
                          ),
                        ),
                      if (onEdit != null && onDelete != null)
                        const SizedBox(width: 10),
                      if (onDelete != null)
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: 'Eliminar',
                            color: const Color(0xFFEF4444),
                            onTap: onDelete!,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(size: 56),
                const SizedBox(width: 20),

                // Info principal
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y estado
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: ElegantLightTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Contacto
                      Row(
                        children: [
                          _buildContactChip(
                            icon: Icons.email_outlined,
                            value: customer.email,
                          ),
                          const SizedBox(width: 16),
                          _buildContactChip(
                            icon: Icons.badge_outlined,
                            value: customer.formattedDocument,
                          ),
                          if (customer.phone != null) ...[
                            const SizedBox(width: 16),
                            _buildContactChip(
                              icon: Icons.phone_outlined,
                              value: customer.phone!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Separador vertical
                Container(
                  width: 1,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                ),

                // Métricas
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDesktopMetric(
                          icon: Icons.credit_card_rounded,
                          label: 'Crédito',
                          value: _formatCurrency(customer.creditLimit),
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDesktopMetric(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Órdenes',
                          value: '${customer.totalOrders}',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDesktopMetric(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Balance',
                          value: _formatCurrency(customer.currentBalance),
                          color: customer.currentBalance > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

                // Separador vertical
                Container(
                  width: 1,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                ),

                // Acciones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      _buildDesktopAction(
                        icon: Icons.edit_rounded,
                        color: ElegantLightTheme.primaryBlue,
                        tooltip: 'Editar cliente',
                        onTap: onEdit!,
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 10),
                    if (onDelete != null)
                      _buildDesktopAction(
                        icon: Icons.delete_rounded,
                        color: const Color(0xFFEF4444),
                        tooltip: 'Eliminar cliente',
                        onTap: onDelete!,
                      ),
                    const SizedBox(width: 8),
                    // Flecha indicadora
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: ElegantLightTheme.textTertiary,
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

  // ==================== WIDGETS COMPARTIDOS ====================

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _getStatusGradient(),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ElegantLightTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ElegantLightTheme.textTertiary),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _getInitials() {
    final parts = customer.displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return customer.displayName.substring(0, 2).toUpperCase();
  }

  Color _getStatusColor() {
    switch (customer.status) {
      case CustomerStatus.active:
        return const Color(0xFF10B981);
      case CustomerStatus.inactive:
        return const Color(0xFFF59E0B);
      case CustomerStatus.suspended:
        return const Color(0xFFEF4444);
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
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '\$0';
    }
    return AppFormatters.formatCompactCurrency(amount);
  }
}
