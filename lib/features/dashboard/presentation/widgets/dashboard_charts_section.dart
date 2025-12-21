// lib/features/dashboard/presentation/widgets/dashboard_charts_section.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_text.dart';
import '../controllers/dashboard_controller.dart';

class DashboardChartsSection extends StatefulWidget {
  const DashboardChartsSection({super.key});

  @override
  State<DashboardChartsSection> createState() => _DashboardChartsSectionState();
}

class _DashboardChartsSectionState extends State<DashboardChartsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _hoveredBarIndex = -1; // -1 = ninguno, 0 = ingresos, 1 = gastos

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setHoveredBar(int index) {
    if (_hoveredBarIndex != index) {
      setState(() {
        _hoveredBarIndex = index;
      });
    }
  }

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

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: ElegantLightTheme.glassDecoration(
              borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
              gradient: ElegantLightTheme.glassGradient,
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
          ),
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
      builder:
          (context) => Row(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 16),
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
      padding: const EdgeInsets.all(
        12,
      ), // Reducido de 20 a 12 para vista más compacta
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
                const SizedBox(
                  width: 10,
                ), // Reducido de 12 a 10 para más espacio
                Expanded(
                  child: _buildCompactMetricCard(
                    'Gastos',
                    AppFormatters.formatCurrency(totalExpenses.toInt()),
                    AppColors.error,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ), // Reducido de 12 a 10 para más espacio
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
          const SizedBox(
            height: 12,
          ), // Reducido de 20 a 12 para vista más compacta
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ), // Reducido de 16 a 14
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
                fontSize:
                    11, // Reducido de 12 a 11 pero se escalará automáticamente
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
    // Porcentajes para la altura de las barras (relativo al valor máximo)
    final percentage1 = maxValue > 0 ? (totalSales / maxValue) : 0;
    final percentage2 = maxValue > 0 ? (totalExpenses / maxValue) : 0;

    // Porcentajes reales para mostrar en el badge (relativo al total)
    final total = totalSales + totalExpenses;
    final double salesPercentage = total > 0 ? (totalSales / total * 100) : 0.0;
    final double expensesPercentage = total > 0 ? (totalExpenses / total * 100) : 0.0;

    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isMobile = screenWidth < 600;

    // Altura máxima de las barras: debe dejar espacio para el label superior
    // Container total: 160px (mobile) o 300px (desktop)
    // Espacio para label + padding superior: ~50px
    // Máxima altura de barra = Container - Espacio para label
    final maxBarHeight = isMobile ? 100.0 : 230.0;

    final barHeight1 = maxBarHeight * percentage1;
    final barHeight2 = maxBarHeight * percentage2;
    final minHeight = 4.0;
    final finalHeight1 = math.max(barHeight1, totalSales > 0 ? minHeight : 0.0);
    final finalHeight2 = math.max(
      barHeight2,
      totalExpenses > 0 ? minHeight : 0.0,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 20,
        4,
        isMobile ? 12 : 20,
        isMobile ? 12 : 20,
      ), // Padding más compacto en móvil
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: MouseRegion(
              onEnter: (_) => _setHoveredBar(0),
              onExit: (_) => _setHoveredBar(-1),
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
                  SizedBox(
                    height: isMobile ? 0 : 8,
                  ), // Espacio adicional en desktop entre valor y barra
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return _build3DBar(
                        finalHeight1 * _animation.value,
                        AppColors.success,
                        isMobile,
                        isHovered: _hoveredBarIndex == 0,
                        barIndex: 0,
                        totalValue: totalSales,
                        percentage: salesPercentage,
                        label: 'Ingresos',
                      );
                    },
                  ),
                  SizedBox(
                    height: isMobile ? 0 : 6,
                  ), // Espacio adicional en desktop entre barra y etiqueta
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
          ),
          const SizedBox(width: 16),
          Flexible(
            child: MouseRegion(
              onEnter: (_) => _setHoveredBar(1),
              onExit: (_) => _setHoveredBar(-1),
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
                  SizedBox(
                    height: isMobile ? 0 : 8,
                  ), // Espacio adicional en desktop entre valor y barra
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return _build3DBar(
                        finalHeight2 * _animation.value,
                        AppColors.error,
                        isMobile,
                        isHovered: _hoveredBarIndex == 1,
                        barIndex: 1,
                        totalValue: totalExpenses,
                        percentage: expensesPercentage,
                        label: 'Gastos',
                      );
                    },
                  ),
                  SizedBox(
                    height: isMobile ? 0 : 6,
                  ), // Espacio adicional en desktop entre barra y etiqueta
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
          ),
        ],
      ),
    );
  }

  Widget _build3DBar(
    double height,
    Color baseColor,
    bool isMobile, {
    bool isHovered = false,
    int barIndex = 0,
    double totalValue = 0,
    double percentage = 0,
    String label = '',
  }) {
    // Altura total del contenedor
    final double fixedContainerHeight = isMobile ? 160.0 : 300.0;

    // Espacio reservado para el label superior (padding + text + spacing)
    final double labelSpace = 50.0;

    // Altura máxima permitida para la barra visual
    final double maxAllowedBarHeight = fixedContainerHeight - labelSpace;

    // Aplicar límite estricto: la barra NUNCA puede exceder maxAllowedBarHeight
    final safeHeight = height.clamp(0.0, maxAllowedBarHeight);

    // Efectos de hover
    final double hoverScale = isHovered ? 1.05 : 1.0;
    final double hoverElevation = isHovered ? 10.0 : 0.0;
    final double glowIntensity = isHovered ? 0.6 : 0.3;

    // Mapear colores
    Color glowColor;
    if (baseColor == AppColors.success) {
      glowColor = const Color(0xFF10B981); // Green
    } else if (baseColor == AppColors.error) {
      glowColor = const Color(0xFFEF4444); // Red
    } else {
      glowColor = const Color(0xFF3B82F6); // Blue
    }

    final double barWidth = 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..scale(hoverScale)
        ..translate(0.0, -hoverElevation, 0.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // BARRA PRINCIPAL
          SizedBox(
            width: 90,
            height: fixedContainerHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // 1. SOMBRA DE GLOW GRANDE (intensificada con hover)
                Positioned(
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: barWidth + 20,
                    height: safeHeight + 40,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: 1.0,
                        colors: [
                          glowColor.withOpacity(glowIntensity),
                          glowColor.withOpacity(glowIntensity * 0.5),
                          glowColor.withOpacity(glowIntensity * 0.15),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

                // 2. SOMBRA BASE OSCURA
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: barWidth - 5,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

                // 3. CILINDRO PRINCIPAL GLASSMORPHIC
                Positioned(
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barWidth / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: barWidth,
                        height: safeHeight + 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              glowColor.withOpacity(0.2),
                              glowColor.withOpacity(0.5),
                              glowColor.withOpacity(0.8),
                              glowColor,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(barWidth / 2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(isHovered ? 0.6 : 0.4),
                              blurRadius: isHovered ? 35 : 25,
                              offset: const Offset(0, 4),
                              spreadRadius: isHovered ? 4 : 2,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(-5, -5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // REFLEJO LATERAL IZQUIERDO
                            if (safeHeight > 10)
                              Positioned(
                                left: 8,
                                top: safeHeight * 0.15,
                                child: Container(
                                  width: 20,
                                  height: safeHeight * 0.6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.7),
                                        Colors.white.withOpacity(0.4),
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BADGE FLOTANTE (solo desktop y cuando hover)
          if (isHovered && !isMobile)
            Positioned(
              // Posición adaptativa: encima de la barra si es grande, o en posición fija si es pequeña
              top: safeHeight > 80
                  ? fixedContainerHeight - safeHeight - 80
                  : fixedContainerHeight - 150, // Posición fija para barras pequeñas
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: glowColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatCurrency(totalValue.toInt()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
          0, // barIndex: sincronizar con la barra de Ingresos
        ),
        const SizedBox(height: 12),

        // Indicador de Gastos
        _buildLegendItem(
          'Gastos',
          AppFormatters.formatCurrency(totalExpenses.toInt()),
          '${expensesPercentage.toStringAsFixed(1)}%',
          AppColors.error,
          Icons.trending_down_rounded,
          1, // barIndex: sincronizar con la barra de Gastos
        ),
        const SizedBox(height: 12),

        // ✅ Indicador de Costo de Productos Vendidos (COGS) - Siempre mostrar
        _buildLegendItem(
          'COGS',
          AppFormatters.formatCurrency(totalCOGS.toInt()),
          '${totalSales > 0 ? (totalCOGS / totalSales * 100).toStringAsFixed(1) : "0.0"}%',
          AppColors.warning,
          Icons.inventory_rounded,
          -2, // barIndex: -2 = no tiene barra correspondiente
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
    int barIndex,
  ) {
    return _LegendItemCard(
      label: label,
      value: value,
      percentage: percentage,
      color: color,
      icon: icon,
      barIndex: barIndex,
      onHover: _setHoveredBar,
      isExternallyHovered: _hoveredBarIndex == barIndex,
    );
  }
}

// Widget animado para los items de la leyenda
class _LegendItemCard extends StatefulWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;
  final IconData icon;
  final int barIndex;
  final Function(int) onHover;
  final bool isExternallyHovered;

  const _LegendItemCard({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.barIndex,
    required this.onHover,
    required this.isExternallyHovered,
  });

  @override
  State<_LegendItemCard> createState() => _LegendItemCardState();
}

class _LegendItemCardState extends State<_LegendItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_LegendItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar animación con hover externo (desde las barras)
    if (widget.isExternallyHovered && !_isHovered) {
      _controller.forward();
    } else if (!widget.isExternallyHovered && !_isHovered) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bool isHighlighted = _isHovered || widget.isExternallyHovered;

        return MouseRegion(
          onEnter: (_) {
            setState(() => _isHovered = true);
            _controller.forward();
            widget.onHover(widget.barIndex); // Sincronizar con las barras
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _controller.reverse();
            widget.onHover(-1); // Quitar hover de las barras
          },
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHighlighted
                          ? widget.color.withOpacity(0.5)
                          : widget.color.withOpacity(0.2),
                      width: isHighlighted ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      ...ElegantLightTheme.glassShadow,
                      if (_glowAnimation.value > 0)
                        BoxShadow(
                          color: widget.color.withOpacity(
                            _glowAnimation.value * 0.4,
                          ),
                          blurRadius: 20 * _glowAnimation.value,
                          offset: const Offset(0, 4),
                          spreadRadius: 2 * _glowAnimation.value,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icono con glassmorfismo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.color.withOpacity(0.3),
                                  widget.color.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 18,
                            ),
                          ),
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
                                Expanded(
                                  child: Text(
                                    widget.label,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.color.withOpacity(0.2),
                                        widget.color.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.color.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.percentage,
                                    style: TextStyle(
                                      color: widget.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.value,
                              style: TextStyle(
                                color: widget.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
