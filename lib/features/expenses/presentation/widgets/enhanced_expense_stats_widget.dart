// lib/features/expenses/presentation/widgets/enhanced_expense_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/expense_stats.dart';

class EnhancedExpenseStatsWidget extends StatelessWidget {
  final ExpenseStats stats;
  final bool compact;

  const EnhancedExpenseStatsWidget({
    super.key,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactStats(context);
    }

    return ResponsiveHelper.isMobile(context)
        ? _buildMobileStats(context)
        : _buildDesktopStats(context);
  }

  Widget _buildCompactStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Hoy',
            _getDailyAmount(),
            Icons.today,
            Colors.blue,
            compact: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildStatCard(
            context,
            'Semana',
            _getWeeklyAmount(),
            Icons.date_range,
            Colors.green,
            compact: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildStatCard(
            context,
            'Mes',
            stats.formattedMonthlyAmount,
            Icons.calendar_month,
            Colors.orange,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStats(BuildContext context) {
    return Column(
      children: [
        // Primera fila: Hoy, Semana, Mes
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Hoy',
                _getDailyAmount(),
                Icons.today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Semana',
                _getWeeklyAmount(),
                Icons.date_range,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: Mes
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Mes',
                stats.formattedMonthlyAmount,
                Icons.calendar_month,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Promedio',
                _getDailyAverage(),
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Column(
      children: [
        // Primera fila: Estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Hoy',
                _getDailyAmount(),
                Icons.today,
                Colors.blue,
                subtitle: '${_getDailyCount()} gastos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Semana',
                _getWeeklyAmount(),
                Icons.date_range,
                Colors.green,
                subtitle: '${_getWeeklyCount()} gastos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: Estadísticas mensuales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Mes',
                stats.formattedMonthlyAmount,
                Icons.calendar_month,
                Colors.orange,
                subtitle: '${stats.monthlyCount} gastos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Promedio',
                _getDailyAverage(),
                Icons.trending_up,
                Colors.purple,
                subtitle: 'Este mes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tercera fila: Comparativa
        _buildComparativeCard(context),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool compact = false,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: compact ? 16 : 20,
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (subtitle != null && !compact) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparativeCard(BuildContext context) {
    final previousMonth = _getPreviousMonthAmount();
    final currentMonth = stats.monthlyAmount;
    final difference = currentMonth - previousMonth;
    final percentage = previousMonth > 0 
        ? (difference / previousMonth * 100) 
        : (currentMonth > 0 ? 100.0 : 0.0);

    final isIncrease = difference > 0;
    final color = isIncrease ? Colors.red : Colors.green;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparación Mensual',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${percentage.abs().toStringAsFixed(1)}% ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        isIncrease ? 'más que el mes anterior' : 'menos que el mes anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(difference.abs()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para calcular estadísticas adicionales
  String _getDailyAmount() {
    // Por ahora retornamos un placeholder, esto se calculará en el controlador
    return AppFormatters.formatCurrency(stats.dailyAmount ?? 0);
  }

  String _getWeeklyAmount() {
    // Por ahora retornamos un placeholder, esto se calculará en el controlador
    return AppFormatters.formatCurrency(stats.weeklyAmount ?? 0);
  }

  String _getDailyAverage() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;
    final average = stats.monthlyAmount / currentDay;
    return AppFormatters.formatCurrency(average);
  }

  int _getDailyCount() {
    return stats.dailyCount ?? 0;
  }

  int _getWeeklyCount() {
    return stats.weeklyCount ?? 0;
  }

  double _getPreviousMonthAmount() {
    // Por ahora retornamos un placeholder, esto se calculará en el controlador
    return stats.previousMonthAmount ?? 0;
  }
}