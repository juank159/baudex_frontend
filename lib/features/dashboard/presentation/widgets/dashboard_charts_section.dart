// lib/features/dashboard/presentation/widgets/dashboard_charts_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';

class DashboardChartsSection extends GetView<DashboardController> {
  const DashboardChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Análisis y Tendencias',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        
        // Gráficos responsivos
        ResponsiveBuilder(
          mobile: _buildMobileCharts(),
          tablet: _buildTabletCharts(),
          desktop: _buildDesktopCharts(),
        ),
      ],
    );
  }

  Widget _buildMobileCharts() {
    return Column(
      children: [
        _buildFinancialOverviewChart(),
        const SizedBox(height: AppDimensions.spacingMedium),
        Row(
          children: [
            Expanded(child: _buildExpensesDonutChart()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildProfitChart()),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletCharts() {
    return Column(
      children: [
        _buildFinancialOverviewChart(),
        const SizedBox(height: AppDimensions.spacingMedium),
        Row(
          children: [
            Expanded(flex: 2, child: _buildSalesVsExpensesChart()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildExpensesDonutChart()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopCharts() {
    return Column(
      children: [
        SizedBox(height: 320, child: _buildFinancialOverviewChart()),
        const SizedBox(height: AppDimensions.spacingMedium),
        Row(
          children: [
            Expanded(flex: 2, child: _buildSalesVsExpensesChart()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildExpensesDonutChart()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildProfitChart()),
          ],
        ),
      ],
    );
  }

  // Gráfico principal de resumen financiero
  Widget _buildFinancialOverviewChart() {
    return Obx(() {
      if (controller.isLoadingStats) {
        return _buildChartPlaceholder('Resumen Financiero');
      }

      final totalSales = controller.totalRevenue;
      final totalExpenses = controller.totalExpenses;
      final maxValue = [totalSales, totalExpenses].reduce((a, b) => a > b ? a : b);
      
      return Container(
        height: 280,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                Icon(Icons.trending_up, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Resumen Financiero',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.2 : 100000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => AppColors.textPrimary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label = group.x == 0 ? 'Ventas' : 'Gastos';
                        return BarTooltipItem(
                          '$label\n${AppFormatters.formatCurrency(rod.toY)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == 0) {
                            return Text('Ventas', style: AppTextStyles.bodySmall);
                          } else if (value == 1) {
                            return Text('Gastos', style: AppTextStyles.bodySmall);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            AppFormatters.formatCurrency(value).replaceAll('\$ ', '\$'),
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: totalSales,
                          color: AppColors.primary,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: totalExpenses,
                          color: AppColors.error,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Gráfico de donut para distribución de gastos
  Widget _buildExpensesDonutChart() {
    return Obx(() {
      if (controller.isLoadingStats) {
        return _buildChartPlaceholder('Distribución de Gastos');
      }

      final totalExpenses = controller.totalExpenses;
      final operationalExpenses = totalExpenses * 0.6; // 60% operativos
      final administrativeExpenses = totalExpenses * 0.3; // 30% administrativos  
      final otherExpenses = totalExpenses * 0.1; // 10% otros

      return Container(
        height: 200,
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                Icon(Icons.donut_small, color: AppColors.error, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Distribución de Gastos',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            Expanded(
              child: totalExpenses > 0 ? PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.error,
                      value: operationalExpenses,
                      title: '60%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppColors.warning,
                      value: administrativeExpenses,
                      title: '30%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppColors.textSecondary,
                      value: otherExpenses,
                      title: '10%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ) : Center(
                child: Text(
                  'Sin datos de gastos',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Leyenda
            if (totalExpenses > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildLegendItem('Operativos', AppColors.error),
                  ),
                  Expanded(
                    child: _buildLegendItem('Admin', AppColors.warning),
                  ),
                  Expanded(
                    child: _buildLegendItem('Otros', AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  // Gráfico de comparación Ventas vs Gastos
  Widget _buildSalesVsExpensesChart() {
    return Obx(() {
      if (controller.isLoadingStats) {
        return _buildChartPlaceholder('Ventas vs Gastos');
      }

      final totalSales = controller.totalRevenue;
      final totalExpenses = controller.totalExpenses;
      
      return Container(
        height: 240,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                Icon(Icons.compare_arrows, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ventas vs Gastos',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Expanded(
              child: Row(
                children: [
                  // Ventas
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Ventas',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  flex: _calculateSafeFlex(totalSales, totalSales + totalExpenses),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.formatCurrency(totalSales),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMedium),
                  // Gastos
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Gastos',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  flex: _calculateSafeFlex(totalExpenses, totalSales + totalExpenses),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.formatCurrency(totalExpenses),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Gráfico de utilidad/ganancia
  Widget _buildProfitChart() {
    return Obx(() {
      if (controller.isLoadingStats) {
        return _buildChartPlaceholder('Rentabilidad');
      }

      final totalSales = controller.totalRevenue;
      final totalExpenses = controller.totalExpenses;
      final profit = totalSales - totalExpenses;
      final isProfit = profit >= 0;
      
      return Container(
        height: 240,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rentabilidad',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicador circular de rentabilidad
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _calculateSafeProgressValue(profit.abs(), totalSales),
                      strokeWidth: 8,
                      backgroundColor: isProfit 
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isProfit ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Text(
                    isProfit ? 'Ganancia' : 'Pérdida',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isProfit ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatCurrency(profit.abs()),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isProfit ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (totalSales > 0)
                    Text(
                      '${((profit / totalSales) * 100).toStringAsFixed(1)}% margen',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Helper para crear items de leyenda
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder(String title) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(
                Icons.analytics,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Text(
                    'Cargando datos...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
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

  int _calculateSafeFlex(double value, double total) {
    if (total <= 0 || value.isNaN || value.isInfinite) {
      return 5; // Valor mínimo por defecto
    }
    
    final percentage = (value / total) * 100;
    if (percentage.isNaN || percentage.isInfinite) {
      return 5;
    }
    
    return percentage.toInt().clamp(5, 100);
  }

  double _calculateSafeProgressValue(double value, double total) {
    if (total <= 0 || value.isNaN || value.isInfinite || total.isNaN || total.isInfinite) {
      return 0.0;
    }
    
    final progress = value / total;
    if (progress.isNaN || progress.isInfinite) {
      return 0.0;
    }
    
    return progress.clamp(0.0, 1.0);
  }
}
