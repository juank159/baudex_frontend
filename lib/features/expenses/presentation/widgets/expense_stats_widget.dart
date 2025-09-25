// lib/features/expenses/presentation/widgets/expense_stats_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/expense_stats.dart';
import '../../../../app/core/utils/formatters.dart';

class ExpenseStatsWidget extends StatelessWidget {
  final ExpenseStats stats;
  final bool compact;
  final bool showTrends;

  const ExpenseStatsWidget({
    super.key,
    required this.stats,
    this.compact = false,
    this.showTrends = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactStats(context);
    }

    return _buildFullStats(context);
  }

  Widget _buildCompactStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Gastos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    stats.formattedTotalAmount,
                    Icons.account_balance_wallet,
                    Colors.blue,
                    '${stats.totalExpenses} gastos',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Este Mes',
                    stats.formattedMonthlyAmount,
                    Icons.calendar_month,
                    Colors.green,
                    'Promedio: ${stats.formattedAverageAmount}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reducido de 20 a 12

            // Primera fila - Totales principales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total General',
                    stats.formattedTotalAmount,
                    '${stats.totalExpenses} gastos',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8), // Reducido de 12 a 8
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Este Mes',
                    stats.formattedMonthlyAmount,
                    'Promedio: ${stats.formattedAverageAmount}',
                    Icons.calendar_month,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // Reducido de 12 a 8

            // Segunda fila - Estados
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pendientes',
                    AppFormatters.formatCurrency(stats.pendingAmount),
                    '${stats.pendingExpenses} gastos',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8), // Reducido de 12 a 8
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Aprobados',
                    AppFormatters.formatCurrency(stats.approvedAmount),
                    '${stats.approvedExpenses} gastos',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reducido de 16 a 12

            // Ratios de aprobación
            _buildApprovalRates(context),

            if (showTrends && stats.monthlyTrends.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTrendsSection(context),
            ],

            // Gastos por categoría
            if (stats.expensesByCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCategoryBreakdown(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8), // Reducido de 12 a 8
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Añadido para reducir altura
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16), // Reducido de 20 a 16
              const SizedBox(width: 6), // Reducido de 8 a 6
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith( // Cambiado de titleSmall a bodySmall
                    color: color,
                    fontWeight: FontWeight.w600, // Cambiado de w100 a w600
                    fontSize: 11, // Añadido tamaño específico
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Reducido de 8 a 4
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Cambiado de titleLarge a titleMedium
              fontWeight: FontWeight.bold, // Cambiado de w100 a bold
              color: color,
              fontSize: 16, // Añadido tamaño específico
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Reducido de 4 a 2
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: 10, // Añadido tamaño específico
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalRates(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratios de Aprobación',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Aprobación',
                  stats.approvalRate,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Rechazo',
                  stats.rejectionRate,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencia Mensual',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Row(
            children:
                stats.monthlyTrends.take(6).map((trend) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            trend.formattedAmount,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: _calculateBarHeight(trend.amount),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trend.monthName,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final topCategories =
        stats.expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Categorías',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        ...topCategories.take(5).map((entry) {
          final percentage = (entry.value / stats.totalAmount) * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  double _calculateBarHeight(double amount) {
    if (stats.monthlyTrends.isEmpty) return 0;

    final maxAmount = stats.monthlyTrends
        .map((trend) => trend.amount)
        .reduce((a, b) => a > b ? a : b);

    if (maxAmount == 0) return 0;

    return (amount / maxAmount) * 50; // Altura máxima de 50
  }
}
