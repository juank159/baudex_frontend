import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_text.dart';
import '../../../../app/shared/animations/stats_animations.dart';
import '../controllers/dashboard_controller.dart';

class DashboardChartsSection extends StatelessWidget {
  const DashboardChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Obx(() {
      final stats = dashboardController.dashboardStats;
      
      if (dashboardController.isLoading) {
        return Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader(),
              const SizedBox(height: 20),
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        );
      }

      final totalSales = stats?.sales.totalAmount ?? 0;
      final totalExpenses = stats?.expenses.totalAmount ?? 0;
      final maxValue = math.max(totalSales, totalExpenses);
      
      if (maxValue <= 0) {
        return Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader(),
              const SizedBox(height: 20),
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Sin datos',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 20),
            _buildChart(totalSales, totalExpenses, maxValue, isMobile),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader() {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bar_chart,
              color: AppColors.primary,
              size: ResponsiveText.getIconSize(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gráfico de Barras',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: ResponsiveText.getTitleLargeSize(context),
                ),
              ),
              Text(
                'Comparación de Ingresos vs Gastos',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveText.getBodySmallSize(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(double totalSales, double totalExpenses, double maxValue, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return _buildMobileChart(totalSales, totalExpenses, maxValue);
        } else {
          return _buildDesktopChart(totalSales, totalExpenses, maxValue);
        }
      },
    );
  }

  Widget _buildMobileChart(double totalSales, double totalExpenses, double maxValue) {
    final controller = Get.find<DashboardController>();
    // ✅ Usar la ganancia bruta real calculada correctamente
    final netProfit = controller.realGrossProfit;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Valores en la parte superior - más compactos
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactMetricCard(
                    'Ingresos',
                    AppFormatters.formatCurrency(totalSales.toInt()),
                    AppColors.success,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactMetricCard(
                    'Gastos',
                    AppFormatters.formatCurrency(totalExpenses.toInt()),
                    AppColors.error,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactMetricCard(
                    netProfit >= 0 ? 'Ganancia Bruta' : 'Pérdida Bruta',
                    AppFormatters.formatCurrency(netProfit.abs().toInt()),
                    netProfit >= 0 ? AppColors.success : AppColors.error,
                    netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Gráfico de barras
          _buildBarChart(totalSales, totalExpenses, maxValue),
        ],
      ),
    );
  }

  Widget _buildDesktopChart(double totalSales, double totalExpenses, double maxValue) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 500,
        maxWidth: double.infinity,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Leyenda y estadísticas (lado izquierdo)
          Expanded(
            flex: 2,
            child: _buildChartLegend(totalSales, totalExpenses, maxValue),
          ),
          const SizedBox(width: 32),
          // Gráfico de barras (lado derecho)
          Expanded(
            flex: 3,
            child: _buildBarChart(totalSales, totalExpenses, maxValue),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: ResponsiveText.getSmallIconSize(context),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveText.getBodyMediumSize(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveText.getValueTextSize(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(double totalSales, double totalExpenses, double maxValue) {
    final percentage1 = maxValue > 0 ? (totalSales / maxValue) : 0;
    final percentage2 = maxValue > 0 ? (totalExpenses / maxValue) : 0;
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isMobile = screenWidth < 600;
    final maxBarHeight = isMobile ? 150.0 : 360.0; // Barras más cortas en móvil
    final barHeight1 = maxBarHeight * percentage1;
    final barHeight2 = maxBarHeight * percentage2;
    final minHeight = 4.0;
    final finalHeight1 = math.max(barHeight1, totalSales > 0 ? minHeight : 0.0);
    final finalHeight2 = math.max(barHeight2, totalExpenses > 0 ? minHeight : 0.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.1),
                        AppColors.success.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(totalSales.toInt()),
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                _build3DBar(finalHeight1, AppColors.success),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Ingresos',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error.withOpacity(0.1),
                        AppColors.error.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(totalExpenses.toInt()),
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                _build3DBar(finalHeight2, AppColors.error),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Gastos',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DBar(double height, Color baseColor) {
    // Asegurar altura mínima
    final safeHeight = math.max(height, 40.0);
    
    return Container(
      width: 85,
      height: safeHeight + 15,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Sombra en el suelo
          Positioned(
            bottom: 0,
            child: Container(
              width: 95,
              height: 12,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(47.5),
              ),
            ),
          ),
          // Base del cilindro
          Positioned(
            bottom: 3,
            child: Container(
              width: 80,
              height: 15,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    baseColor.withOpacity(0.7),
                    baseColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // Cuerpo principal del cilindro con perspectiva
          Positioned(
            bottom: 10,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspectiva
                ..rotateY(0.1), // Ligera rotación para mostrar volumen
              child: Container(
                width: 70,
                height: safeHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      baseColor.withOpacity(0.5), // Sombra izquierda más pronunciada
                      baseColor.withOpacity(0.8), 
                      baseColor, // Centro brillante
                      baseColor.withOpacity(0.9),
                      baseColor.withOpacity(0.4), // Sombra derecha más pronunciada
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(-4, 2),
                    ),
                    BoxShadow(
                      color: baseColor.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(2, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Reflejo lateral con perspectiva
          Positioned(
            top: 12,
            left: 18,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(0.1),
              child: Container(
                width: 20,
                height: safeHeight * 0.7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(double totalSales, double totalExpenses, double maxValue) {
    final controller = Get.find<DashboardController>();
    
    final total = totalSales + totalExpenses;
    final salesPercentage = total > 0 ? (totalSales / total * 100) : 0;
    final expensesPercentage = total > 0 ? (totalExpenses / total * 100) : 0;
    
    // ✅ Usar los getters del controller que calculan correctamente
    final netProfit = controller.realGrossProfit;
    final totalCOGS = controller.totalCOGS;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Título de la leyenda
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Análisis Financiero',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Indicador de Ingresos
        _buildLegendItem(
          'Ingresos',
          AppFormatters.formatCurrency(totalSales.toInt()),
          '${salesPercentage.toStringAsFixed(1)}%',
          AppColors.success,
          Icons.trending_up_rounded,
        ),
        const SizedBox(height: 16),
        
        // Indicador de Gastos
        _buildLegendItem(
          'Gastos',
          AppFormatters.formatCurrency(totalExpenses.toInt()),
          '${expensesPercentage.toStringAsFixed(1)}%',
          AppColors.error,
          Icons.trending_down_rounded,
        ),
        const SizedBox(height: 16),
        
        // ✅ Indicador de Costo de Productos Vendidos (COGS) - Siempre mostrar
        _buildLegendItem(
          'Costo de Productos (FIFO)',
          AppFormatters.formatCurrency(totalCOGS.toInt()),
          '${totalSales > 0 ? (totalCOGS / totalSales * 100).toStringAsFixed(1) : "0.0"}%',
          AppColors.warning,
          Icons.inventory_rounded,
        ),
        const SizedBox(height: 16),
        
        // Separador elegante
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.textSecondary.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Ganancia neta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: netProfit >= 0 
                ? [
                    AppColors.success.withOpacity(0.1),
                    AppColors.success.withOpacity(0.05),
                  ]
                : [
                    AppColors.error.withOpacity(0.1),
                    AppColors.error.withOpacity(0.05),
                  ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: netProfit >= 0 
                ? AppColors.success.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    netProfit >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: netProfit >= 0 ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    netProfit >= 0 ? 'Ganancia Bruta' : 'Pérdida Bruta',
                    style: TextStyle(
                      color: netProfit >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.formatCurrency(netProfit.abs().toInt()),
                style: TextStyle(
                  color: netProfit >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, String percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de color circular
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        percentage,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}