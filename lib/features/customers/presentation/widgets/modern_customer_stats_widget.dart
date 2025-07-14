// lib/features/customers/presentation/widgets/modern_customer_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
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
        padding: const EdgeInsets.all(12), // Ultra compacto
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.total}',
                'Total',
                Icons.people,
                Theme.of(context).primaryColor,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.active}',
                'Activos',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildUltraCompactStat(
                '${stats.customersWithOverdue}',
                'Riesgo',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    // Versión normal móvil (reducida en 65%)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compacto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estadísticas de Clientes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.active}',
                  'Activos',
                  Icons.check_circle,
                  Colors.green,
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
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  '${stats.customersWithOverdue}',
                  'En Riesgo',
                  Icons.warning,
                  Colors.red,
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
      padding: const EdgeInsets.all(16), // Reducido más para evitar overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header elegante
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Panel de Estadísticas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                  'Total ',
                  '',
                  Icons.people,
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 4), // Reducido el espacio
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.active}',
                  'Activos',
                  '${_calculatePercentage(stats.active, stats.total)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 4), // Reducido el espacio
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.inactive}',
                  'Inactivos',
                  '${_calculatePercentage(stats.inactive, stats.total)}% ',
                  Icons.pause_circle,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 4), // Reducido el espacio
              Expanded(
                child: _buildDesktopStatCard(
                  '${stats.customersWithOverdue}',
                  'Riesgo',
                  '${_calculatePercentage(stats.customersWithOverdue, stats.total)}% ',
                  Icons.warning,
                  Colors.red,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    return Container(
      padding: const EdgeInsets.all(12), // Reducido aún más
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reducido
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color), // Icono más pequeño
              ),
              const SizedBox(width: 6), // Espacio reducido
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14, // Reducido significativamente
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Espacio reducido
          Text(
            title,
            style: const TextStyle(
              fontSize: 7, // Reducido más
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9, // Reducido más
              color: Colors.grey.shade600,
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
