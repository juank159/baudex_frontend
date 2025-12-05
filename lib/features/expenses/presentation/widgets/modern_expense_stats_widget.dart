// lib/features/expenses/presentation/widgets/modern_expense_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense_stats.dart';

class ModernExpenseStatsWidget extends StatelessWidget {
  final ExpenseStats stats;
  final bool isCompact;
  final String? periodLabel; // ✅ NUEVO: etiqueta del período activo

  const ModernExpenseStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ NUEVO: Todos usan el mismo diseño compacto si isCompact = true
    if (isCompact) {
      return _buildCompactBanner(context);
    }

    return ResponsiveHelper.isMobile(context)
        ? _buildMobileStats(context)
        : _buildDesktopStats(context);
  }

  // ✅ Banner compacto universal para todas las pantallas
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
          // Período compacto
          if (periodLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 11, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    periodLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Total y contador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 15, color: Colors.white),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        stats.formattedTotalAmount,
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
                  '${stats.totalExpenses} ${stats.totalExpenses == 1 ? 'gasto' : 'gastos'}',
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
                _buildMiniStat(stats.approvedExpenses, Icons.check_circle, Colors.white),
                const SizedBox(width: 8),
                _buildMiniStat(stats.pendingExpenses, Icons.pending_actions, Colors.white.withOpacity(0.85)),
                const SizedBox(width: 8),
                _buildMiniStat(stats.paidExpenses, Icons.payment, Colors.white.withOpacity(0.85)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context) {

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
                'Estadísticas de Gastos',
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
                  stats.formattedTotalAmount,
                  'Total',
                  Icons.attach_money,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.totalExpenses}',
                  'Gastos',
                  Icons.receipt_long,
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
                  '${stats.pendingExpenses}',
                  'Pendientes',
                  Icons.pending_actions,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.approvedExpenses}',
                  'Aprobados',
                  Icons.check_circle,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),

          // Métricas adicionales compactas
          if (stats.monthlyAmount > 0) ...[
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
                      'Este Mes',
                      stats.formattedMonthlyAmount,
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                  _buildVerticalDivider(),
                  Expanded(
                    child: _buildFinancialMetric(
                      'Promedio',
                      stats.formattedAverageAmount,
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
          // ✅ NUEVO: Banner de período si está disponible
          if (periodLabel != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chip de período
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          periodLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Total de Gastos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stats.formattedTotalAmount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalExpenses} gastos registrados',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Header elegante con gradiente (solo si no hay período)
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
          ],

          // Grid principal de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildDesktopStatCard(
                  stats.formattedTotalAmount,
                  'Total',
                  '${stats.totalExpenses} gastos',
                  Icons.attach_money,
                  ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.pendingExpenses}',
                  'Pendientes',
                  _formatCurrency(stats.pendingAmount),
                  Icons.pending_actions,
                  ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.approvedExpenses}',
                  'Aprobados',
                  _formatCurrency(stats.approvedAmount),
                  Icons.check_circle,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.paidExpenses}',
                  'Pagados',
                  _formatCurrency(stats.paidAmount),
                  Icons.payment,
                  Colors.blue.shade600,
                ),
              ),
            ],
          ),

          // Métricas adicionales (si existen)
          if (stats.monthlyAmount > 0) ...[
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
                        child: Icon(
                          Icons.calendar_month,
                          color: ElegantLightTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Métricas del Período',
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
                          'Este Mes',
                          stats.formattedMonthlyAmount,
                          Icons.calendar_today,
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildElegantMetricCard(
                          'Promedio',
                          stats.formattedAverageAmount,
                          Icons.show_chart,
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
          // Ícono con gradiente
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
    } else if (color == ElegantLightTheme.accentOrange || color == Colors.orange.shade600) {
      return ElegantLightTheme.warningGradient;
    } else if (color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else if (color == Colors.blue.shade600) {
      return ElegantLightTheme.infoGradient;
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
                  style: TextStyle(
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

  Widget _buildFinancialBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
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

  // ✅ NUEVO: Mini stat para versión ultra compacta
  Widget _buildMiniStat(int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
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
