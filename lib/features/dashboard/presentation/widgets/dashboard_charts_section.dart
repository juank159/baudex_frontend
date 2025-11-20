// lib/features/dashboard/presentation/widgets/dashboard_charts_section.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
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
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            ...ElegantLightTheme.elevatedShadow,
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFuturisticSectionHeader(),
            const SizedBox(height: 14),
            Flexible(
              child: _buildChart(totalSales, totalExpenses, maxValue, isMobile),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader() {
    return Builder(
      builder:
          (context) => Row(
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

  Widget _buildFuturisticSectionHeader() {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: Icon(
              Icons.analytics,
              color: Colors.white,
              size: ResponsiveText.getIconSize(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis Financiero',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: ResponsiveText.getTitleLargeSize(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comparación de Ingresos vs Gastos en Tiempo Real',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: ResponsiveText.getBodySmallSize(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.successGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    double totalSales,
    double totalExpenses,
    double maxValue,
    bool isMobile,
  ) {
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

  Widget _buildMobileChart(
    double totalSales,
    double totalExpenses,
    double maxValue,
  ) {
    final controller = Get.find<DashboardController>();
    // ✅ Usar la ganancia bruta real calculada correctamente
    final netProfit = controller.realGrossProfit;

    return Container(
      padding: const EdgeInsets.all(12), // Reducido de 20 a 12 para vista más compacta
      decoration: BoxDecoration(
        color: Colors.transparent, // Sin fondo gris, fondo transparente
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Valores en la parte superior - optimizados para mejor legibilidad
          SizedBox(
            height: 88, // Aumentado de 85 a 88 para evitar overflow de 1px
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
                const SizedBox(width: 10), // Reducido de 12 a 10 para más espacio
                Expanded(
                  child: _buildCompactMetricCard(
                    'Gastos',
                    AppFormatters.formatCurrency(totalExpenses.toInt()),
                    AppColors.error,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 10), // Reducido de 12 a 10 para más espacio
                Expanded(
                  child: _buildCompactMetricCard(
                    netProfit >= 0 ? 'Ganancia' : 'Pérdida',
                    AppFormatters.formatCurrency(netProfit.abs().toInt()),
                    netProfit >= 0 ? AppColors.success : AppColors.error,
                    netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // Reducido de 20 a 12 para vista más compacta
          // Gráfico de barras
          _buildBarChart(totalSales, totalExpenses, maxValue),
        ],
      ),
    );
  }

  Widget _buildDesktopChart(
    double totalSales,
    double totalExpenses,
    double maxValue,
  ) {
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

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Builder(
      builder:
          (context) => Container(
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

  Widget _buildCompactMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    // Mapear colores tradicionales a gradientes futurísticos
    LinearGradient gradient;
    if (color == AppColors.success) {
      gradient = ElegantLightTheme.successGradient;
    } else if (color == AppColors.error) {
      gradient = ElegantLightTheme.errorGradient;
    } else {
      gradient = ElegantLightTheme.primaryGradient;
    }

    return Container(
      padding: const EdgeInsets.all(10), // Reducido de 12 a 10
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withValues(alpha: 0.15),
            gradient.colors.last.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5), // Reducido de 6 a 5
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14), // Reducido de 16 a 14
          ),
          const SizedBox(height: 5), // Reducido de 6 a 5 para evitar overflow
          Text(
            title,
            style: TextStyle(
              color: gradient.colors.first,
              fontWeight: FontWeight.w600,
              fontSize: 9, // Reducido de 10 a 9
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Reducido de 3 a 2 para evitar overflow
          // Usar FittedBox para escalar automáticamente el texto sin truncar
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: gradient.colors.first,
                fontWeight: FontWeight.w800,
                fontSize: 11, // Reducido de 12 a 11 pero se escalará automáticamente
                letterSpacing: 0.2, // Reducido espaciado
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    double totalSales,
    double totalExpenses,
    double maxValue,
  ) {
    final percentage1 = maxValue > 0 ? (totalSales / maxValue) : 0;
    final percentage2 = maxValue > 0 ? (totalExpenses / maxValue) : 0;
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isMobile = screenWidth < 600;
    final maxBarHeight = isMobile ? 120.0 : 360.0; // Barras más cortas en móvil para vista compacta
    final barHeight1 = maxBarHeight * percentage1;
    final barHeight2 = maxBarHeight * percentage2;
    final minHeight = 4.0;
    final finalHeight1 = math.max(barHeight1, totalSales > 0 ? minHeight : 0.0);
    final finalHeight2 = math.max(
      barHeight2,
      totalExpenses > 0 ? minHeight : 0.0,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 4, isMobile ? 12 : 20, isMobile ? 12 : 20), // Padding más compacto en móvil
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                SizedBox(height: isMobile ? 0 : 8), // Espacio adicional en desktop entre valor y barra
                _build3DBar(finalHeight1, AppColors.success, isMobile),
                SizedBox(height: isMobile ? 0 : 6), // Espacio adicional en desktop entre barra y etiqueta
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                SizedBox(height: isMobile ? 0 : 8), // Espacio adicional en desktop entre valor y barra
                _build3DBar(finalHeight2, AppColors.error, isMobile),
                SizedBox(height: isMobile ? 0 : 6), // Espacio adicional en desktop entre barra y etiqueta
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
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

  Widget _build3DBar(double height, Color baseColor, bool isMobile) {
    // Usar la altura real sin forzar mínimos para alineación correcta
    final safeHeight = height;
    
    // Mapear colores a gradientes futurísticos
    LinearGradient gradient;
    if (baseColor == AppColors.success) {
      gradient = ElegantLightTheme.successGradient;
    } else if (baseColor == AppColors.error) {
      gradient = ElegantLightTheme.errorGradient;
    } else {
      gradient = ElegantLightTheme.primaryGradient;
    }

    // Usar altura fija del contenedor para garantizar alineación (ajustada para evitar overflow)
    final double fixedContainerHeight = isMobile ? 140.0 : 340.0; // Altura más compacta en móvil

    return SizedBox(
      width: 85,
      height: fixedContainerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Sombra PERFECTAMENTE SUAVE sin esquinas cuadradas
          Positioned(
            bottom: -1,
            left: 12.5,
            child: Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(30), // COMPLETAMENTE REDONDEADO - sin esquinas cuadradas
              ),
            ),
          ),
          // Base del cilindro futurística
          Positioned(
            bottom: 5, // Posición fija desde el fondo
            child: Container(
              width: 80,
              height: 15,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    gradient.colors.first.withValues(alpha: 0.7), 
                    gradient.colors.last
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                // Eliminadas boxShadow que interfieren con la sombra principal
              ),
            ),
          ),
          // Cuerpo principal del cilindro con perspectiva futurística
          Positioned(
            bottom: 15, // Posición fija desde el fondo para alineación consistente
            child: Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
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
                      gradient.colors.first.withValues(alpha: 0.6), // Sombra izquierda
                      gradient.colors.first.withValues(alpha: 0.8),
                      gradient.colors.last, // Centro brillante
                      gradient.colors.first.withValues(alpha: 0.9),
                      gradient.colors.first.withValues(alpha: 0.5), // Sombra derecha
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Reflejo lateral con perspectiva
          Positioned(
            bottom: 15 + (safeHeight * 0.3), // Posicionado relativo a la altura de la barra
            left: 18,
            child: Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
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
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
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

  Widget _buildChartLegend(
    double totalSales,
    double totalExpenses,
    double maxValue,
  ) {
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
        // Indicador de Ingresos
        _buildLegendItem(
          'Ingresos',
          AppFormatters.formatCurrency(totalSales.toInt()),
          '${salesPercentage.toStringAsFixed(1)}%',
          AppColors.success,
          Icons.trending_up_rounded,
        ),
        const SizedBox(height: 12),

        // Indicador de Gastos
        _buildLegendItem(
          'Gastos',
          AppFormatters.formatCurrency(totalExpenses.toInt()),
          '${expensesPercentage.toStringAsFixed(1)}%',
          AppColors.error,
          Icons.trending_down_rounded,
        ),
        const SizedBox(height: 12),

        // ✅ Indicador de Costo de Productos Vendidos (COGS) - Siempre mostrar
        _buildLegendItem(
          'COGS',
          AppFormatters.formatCurrency(totalCOGS.toInt()),
          '${totalSales > 0 ? (totalCOGS / totalSales * 100).toStringAsFixed(1) : "0.0"}%',
          AppColors.warning,
          Icons.inventory_rounded,
        ),
        const SizedBox(height: 12),

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
        const SizedBox(height: 16),

        // Ganancia neta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  netProfit >= 0
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
              color:
                  netProfit >= 0
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
                    netProfit >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: netProfit >= 0 ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    netProfit >= 0 ? 'Ganancia' : 'Pérdida',
                    style: TextStyle(
                      color:
                          netProfit >= 0 ? AppColors.success : AppColors.error,
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

  Widget _buildLegendItem(
    String label,
    String value,
    String percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
