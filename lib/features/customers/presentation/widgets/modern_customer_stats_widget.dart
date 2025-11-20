// lib/features/customers/presentation/widgets/modern_customer_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/customer_stats.dart';

class ModernCustomerStatsWidget extends StatelessWidget {
  final CustomerStats stats;
  final bool isCompact;

  const ModernCustomerStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isMobile(context)
        ? _buildMobileStats(context)
        : _buildDesktopStats(context);
  }

  Widget _buildMobileStats(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.total}',
                'Total',
                Icons.people,
                ElegantLightTheme.primaryBlue,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.active}',
                'Activos',
                Icons.check_circle,
                Colors.green.shade600,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.customersWithOverdue ?? 0}',
                'Riesgo',
                Icons.warning,
                Colors.red.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Versión normal móvil
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header compacto con gradiente
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.analytics,
                  color: ElegantLightTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estadísticas de Clientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de estadísticas 2x2
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.total}',
                  'Total Clientes',
                  Icons.people,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.active}',
                  'Activos',
                  Icons.check_circle,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.inactive}',
                  'Inactivos',
                  Icons.pause_circle,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.customersWithOverdue ?? 0}',
                  'En Riesgo',
                  Icons.warning,
                  Colors.red.shade600,
                ),
              ),
            ],
          ),

          // Métricas financieras compactas
          if (stats.totalBalance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetric(
                      'Balance',
                      _formatCurrency(stats.totalBalance),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  _buildVerticalDivider(),
                  Expanded(
                    child: _buildFinancialMetric(
                      'Promedio',
                      _formatCurrency(stats.averagePurchaseAmount),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header elegante con gradiente
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.analytics,
                  color: ElegantLightTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Panel de Estadísticas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid principal de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.total}',
                  'Total',
                  'Clientes',
                  Icons.people,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.active}',
                  'Activos',
                  '${_calculatePercentage(stats.active, stats.total)}%',
                  Icons.check_circle,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.inactive}',
                  'Inactivos',
                  '${_calculatePercentage(stats.inactive, stats.total)}%',
                  Icons.pause_circle,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.customersWithOverdue ?? 0}',
                  'Riesgo',
                  '${_calculatePercentage(stats.customersWithOverdue ?? 0, stats.total)}%',
                  Icons.warning,
                  Colors.red.shade600,
                ),
              ),
            ],
          ),

          // Métricas financieras (si existen)
          if (stats.totalBalance > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Métricas Financieras',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _buildFinancialBadge(
                    'Balance Total',
                    _formatCurrency(stats.totalBalance),
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildFinancialBadge(
                    'Compra Promedio',
                    _formatCurrency(stats.averagePurchaseAmount),
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUltraCompactStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildCompactStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final gradient = _getGradientForColor(color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == ElegantLightTheme.accentOrange) {
      return ElegantLightTheme.warningGradient;
    } else if (color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else {
      return ElegantLightTheme.infoGradient;
    }
  }

  // Widget _buildDesktopStatCard(
  //   String value,
  //   String title,
  //   String subtitle,
  //   IconData icon,
  //   Color color,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.all(12), // Reducido aún más
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.05),
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: color.withOpacity(0.2)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(6), // Reducido
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(6),
  //               ),
  //               child: Icon(icon, size: 16, color: color), // Icono más pequeño
  //             ),
  //             const SizedBox(width: 6), // Espacio reducido
  //             Expanded(
  //               child: Text(
  //                 value,
  //                 style: TextStyle(
  //                   fontSize: 14, // Reducido significativamente
  //                   fontWeight: FontWeight.w700,
  //                   color: color,
  //                 ),
  //                 textAlign: TextAlign.right,
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8), // Espacio reducido
  //         Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 7, // Reducido más
  //             fontWeight: FontWeight.w600,
  //             color: Colors.black87,
  //           ),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //         const SizedBox(height: 1),
  //         Text(
  //           subtitle,
  //           style: TextStyle(
  //             fontSize: 9, // Reducido más
  //             color: Colors.grey.shade600,
  //           ),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Construye una tarjeta de estadística para la vista de escritorio.
  ///
  /// Todos los elementos se muestran en una única columna vertical.
  Widget _buildDesktopStatCard(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final gradient = _getGradientForColor(color);

    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Ícono con gradiente
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              gradient: gradient.scale(0.3),
              borderRadius: BorderRadius.circular(6.0),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(height: 12.0),
          // 2. Valor principal
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8.0),
          // 3. Título
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2.0),
          // 4. Subtítulo
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: ElegantLightTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFinancialBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  String _calculatePercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
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
