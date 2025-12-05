// lib/features/suppliers/presentation/widgets/supplier_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/supplier.dart';

class SupplierStatsWidget extends StatelessWidget {
  final SupplierStats stats;
  final bool isCompact;

  const SupplierStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactBanner(context);
    }

    return ResponsiveHelper.isMobile(context)
        ? _buildMobileStats(context)
        : _buildDesktopStats(context);
  }

  // Banner compacto universal para todas las pantallas
  Widget _buildCompactBanner(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        isMobile ? 12 : 16,
        isMobile ? 12 : 16,
        isMobile ? 8 : 12,
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ElegantLightTheme.primaryBlue,
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total de proveedores
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, size: 15, color: Colors.white),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        stats.totalSuppliers.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  stats.totalSuppliers == 1 ? 'proveedor' : 'proveedores',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Stats compactos
          if (!isMobile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniStat(
                  stats.activeSuppliers,
                  Icons.check_circle,
                  Colors.white,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  stats.inactiveSuppliers,
                  Icons.cancel,
                  Colors.white.withOpacity(0.85),
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  stats.suppliersWithCredit,
                  Icons.credit_card,
                  Colors.white.withOpacity(0.85),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context) {
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
                'Estadísticas de Proveedores',
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
                  stats.totalSuppliers.toString(),
                  'Total',
                  Icons.business,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  stats.activeSuppliers.toString(),
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
                  stats.inactiveSuppliers.toString(),
                  'Inactivos',
                  Icons.cancel,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  stats.suppliersWithCredit.toString(),
                  'Con Crédito',
                  Icons.credit_card,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),

          // Métricas adicionales compactas
          if (stats.totalCreditLimit > 0) ...[
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
                      'Crédito Total',
                      AppFormatters.formatCurrency(stats.totalCreditLimit),
                      Icons.account_balance,
                      Colors.blue,
                    ),
                  ),
                  _buildVerticalDivider(),
                  Expanded(
                    child: _buildFinancialMetric(
                      'Promedio',
                      AppFormatters.formatCurrency(stats.averageCreditLimit),
                      Icons.trending_up,
                      Colors.purple,
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
                  stats.totalSuppliers.toString(),
                  'Total',
                  'proveedores',
                  Icons.business,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  stats.activeSuppliers.toString(),
                  'Activos',
                  '${_getPercentage(stats.activeSuppliers, stats.totalSuppliers)}%',
                  Icons.check_circle,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  stats.inactiveSuppliers.toString(),
                  'Inactivos',
                  '${_getPercentage(stats.inactiveSuppliers, stats.totalSuppliers)}%',
                  Icons.cancel,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  stats.suppliersWithCredit.toString(),
                  'Con Crédito',
                  '${_getPercentage(stats.suppliersWithCredit, stats.totalSuppliers)}%',
                  Icons.credit_card,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),

          // Métricas adicionales (si existen)
          if (stats.totalCreditLimit > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ElegantLightTheme.primaryBlue.withOpacity(0.05),
                    ElegantLightTheme.primaryBlueLight.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: ElegantLightTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Métricas Financieras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildElegantMetricCard(
                          'Crédito Total',
                          AppFormatters.formatCurrency(stats.totalCreditLimit),
                          Icons.account_balance,
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildElegantMetricCard(
                          'Promedio',
                          AppFormatters.formatCurrency(
                            stats.averageCreditLimit,
                          ),
                          Icons.trending_up,
                          ElegantLightTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
          // Icono con gradiente
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
          // Valor principal
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
          // Título
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
          // Subtítulo
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

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == ElegantLightTheme.accentOrange ||
        color == Colors.orange.shade600) {
      return ElegantLightTheme.warningGradient;
    } else if (color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else if (color == Colors.purple.shade600) {
      return LinearGradient(
        colors: [Colors.purple.shade500, Colors.purple.shade700],
      );
    } else {
      return ElegantLightTheme.infoGradient;
    }
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

  Widget _buildElegantMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
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

  Widget _buildMiniStat(int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _getPercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(0);
  }
}
