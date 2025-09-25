// lib/features/dashboard/presentation/widgets/dashboard_charts_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_text.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';

class DashboardChartsSection extends GetView<DashboardController> {
  const DashboardChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildProfessionalFinancialChart(),
      tablet: _buildProfessionalFinancialChart(),
      desktop: _buildProfessionalFinancialChart(),
    );
  }

  // Gráfico financiero profesional unificado con stats integradas
  Widget _buildProfessionalFinancialChart() {
    return Obx(() {
      if (controller.isLoadingStats) {
        return _buildLoadingCard();
      }

      final totalSales = controller.totalRevenue;
      final totalExpenses = controller.totalExpenses;
      final profit = totalSales - totalExpenses;
      final maxValue = math.max(math.max(totalSales, totalExpenses), 1.0);

      return Container(
        constraints: const BoxConstraints(
          minHeight: 500,
          maxHeight: 580,
        ),
        decoration: _buildCardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChartTitle(),
              const SizedBox(height: 20),
              // Stats unificadas con las cards principales
              _buildUnifiedStatsSection(totalSales, totalExpenses, profit),
              const SizedBox(height: 24),
              // Gráfico de barras comparativo
              Expanded(
                child: _buildCleanBarChart(totalSales, totalExpenses, maxValue),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Título del gráfico limpio y profesional con tipografía responsiva
  Widget _buildChartTitle() {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: ResponsiveText.getIconSize(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen Financiero',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: ResponsiveText.getTitleLargeSize(context),
                ),
              ),
              Text(
                'Comparativo de ingresos vs gastos del período',
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

  // Sección unificada que combina stats principales con métricas detalladas
  Widget _buildUnifiedStatsSection(double totalSales, double totalExpenses, double profit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          children: [
            // Stats principales como cards individuales (reemplaza DashboardStatsGrid parcialmente)
            isMobile 
              ? _buildMobileStatsCards(totalSales, totalExpenses, profit)
              : _buildDesktopStatsCards(totalSales, totalExpenses, profit),
            
            const SizedBox(height: 16),
            
            // Métricas resumidas para el gráfico
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.08)),
              ),
              child: isMobile 
                ? _buildMobileMetricsLayout(totalSales, totalExpenses, profit)
                : _buildDesktopMetricsLayout(totalSales, totalExpenses, profit),
            ),
          ],
        );
      },
    );
  }

  // Layout para móviles (2x2 grid)
  Widget _buildMobileMetricsLayout(double totalSales, double totalExpenses, double profit) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                'Ingresos',
                totalSales,
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactMetric(
                'Gastos',
                totalExpenses,
                AppColors.error,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                profit >= 0 ? 'Ganancia' : 'Pérdida',
                profit.abs(),
                profit >= 0 ? AppColors.success : AppColors.error,
                profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()), // Espacio vacío para mantener simetría
          ],
        ),
      ],
    );
  }

  // Layout para desktop (horizontal)
  Widget _buildDesktopMetricsLayout(double totalSales, double totalExpenses, double profit) {
    return Row(
      children: [
        Expanded(
          child: _buildCleanMetric(
            'Ingresos',
            totalSales,
            AppColors.success,
            Icons.trending_up,
          ),
        ),
        Container(
          width: 1,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.primary.withOpacity(0.15),
        ),
        Expanded(
          child: _buildCleanMetric(
            'Gastos',
            totalExpenses,
            AppColors.error,
            Icons.trending_down,
          ),
        ),
        Container(
          width: 1,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.primary.withOpacity(0.15),
        ),
        Expanded(
          child: _buildCleanMetric(
            profit >= 0 ? 'Ganancia' : 'Pérdida',
            profit.abs(),
            profit >= 0 ? AppColors.success : AppColors.error,
            profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  // Métrica individual limpia y bien organizada con tipografía responsiva
  Widget _buildCleanMetric(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Builder(
      builder: (context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: color, 
                size: ResponsiveText.getSmallIconSize(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveText.getBodyMediumSize(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.formatCurrency(value),
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveText.getLargeValueSize(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Métrica compacta para móviles con tipografía responsiva
  Widget _buildCompactMetric(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Builder(
      builder: (context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: color, 
                size: ResponsiveText.getCaptionSize(context) + 6, // Un poco más grande que caption
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveText.getCaptionSize(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.formatCurrency(value),
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveText.getValueTextSize(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Gráfico de barras limpio y profesional
  Widget _buildCleanBarChart(
    double totalSales,
    double totalExpenses,
    double maxValue,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Eje Y con valores
              SizedBox(
                width: 70,
                child: _buildYAxis(maxValue),
              ),
              // Área de barras
              Expanded(
                child: _buildBarsArea(
                  totalSales,
                  totalExpenses,
                  maxValue,
                  constraints.maxHeight - 60,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Eje Y con valores organizados
  Widget _buildYAxis(double maxValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(6, (index) {
        final value = (maxValue * (5 - index) / 5);
        return Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              AppFormatters.formatCurrency(value),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }

  // Área de barras con alineación perfecta de ejes
  Widget _buildBarsArea(
    double totalSales,
    double totalExpenses,
    double maxValue,
    double availableHeight,
  ) {
    return Column(
      children: [
        // Contenedor principal con grid y barras alineadas
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20), // Padding uniforme
            child: Stack(
              children: [
                // Grid lines horizontales perfectamente alineadas
                ...List.generate(6, (index) {
                  final y = (availableHeight * index / 5);
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    child: Container(
                      height: 0.5, // Líneas más finas y elegantes
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.textSecondary.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                // Líneas verticales sutiles para mejor alineación
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 0.5,
                    color: AppColors.textSecondary.withOpacity(0.1),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 0.5,
                    color: AppColors.textSecondary.withOpacity(0.1),
                  ),
                ),
                
                // Barras centradas y perfectamente alineadas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Espaciador para mejor alineación
                    const SizedBox(width: 20),
                    Expanded(
                      child: Center(
                        child: _buildCleanBar(
                          'Ingresos',
                          totalSales,
                          maxValue,
                          AppColors.success,
                          availableHeight - 10, // Espacio para evitar overflow
                        ),
                      ),
                    ),
                    // Separador visual sutil
                    Container(
                      width: 1,
                      height: availableHeight * 0.8,
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.textSecondary.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildCleanBar(
                          'Gastos',
                          totalExpenses,
                          maxValue,
                          AppColors.error,
                          availableHeight - 10, // Espacio para evitar overflow
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                
                // Línea base inferior más visible
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.textSecondary.withOpacity(0.3),
                          AppColors.textSecondary.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Eje X con labels mejorados y alineados
        Container(
          padding: const EdgeInsets.only(top: 12, bottom: 4), // Reducido bottom padding
          child: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Ingresos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveText.getBodyMediumSize(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 60), // Espacio entre labels
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Gastos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveText.getBodyMediumSize(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  // Barra individual con animaciones espectaculares
  Widget _buildCleanBar(
    String label,
    double value,
    double maxValue,
    Color color,
    double maxHeight,
  ) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0;
    final targetHeight = (maxHeight * percentage * 0.80).clamp(0.0, math.max(8.0, maxHeight)).toDouble(); // Reducido a 0.80

    return _AnimatedBar(
      label: label,
      value: value,
      targetHeight: targetHeight,
      color: color,
      percentage: percentage.toDouble(),
    );
  }

  // Card de carga limpio
  Widget _buildLoadingCard() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 400,
        maxHeight: 460,
      ),
      decoration: _buildCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando resumen financiero...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cards principales unificadas para móvil
  Widget _buildMobileStatsCards(double totalSales, double totalExpenses, double profit) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildUnifiedStatCard(
                'Ingresos',
                totalSales,
                AppColors.success,
                Icons.trending_up,
                '${controller.dashboardStats?.sales.totalSales ?? 0} ventas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUnifiedStatCard(
                'Gastos',
                totalExpenses,
                AppColors.error,
                Icons.trending_down,
                '${controller.dashboardStats?.expenses.totalExpenses ?? 0} gastos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildUnifiedStatCard(
                'Facturas',
                controller.totalInvoices.toDouble(),
                controller.pendingInvoices > 0 ? AppColors.warning : AppColors.info,
                Icons.receipt_long,
                controller.pendingInvoices > 0 
                  ? '${controller.pendingInvoices} pendientes'
                  : 'Todas al día',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUnifiedStatCard(
                'Productos',
                controller.totalProducts.toDouble(),
                controller.lowStockProducts > 0 ? AppColors.error : AppColors.primary,
                Icons.inventory_2,
                controller.lowStockProducts > 0
                  ? '${controller.lowStockProducts} bajo stock'
                  : 'Stock normal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Cards principales unificadas para desktop
  Widget _buildDesktopStatsCards(double totalSales, double totalExpenses, double profit) {
    return Row(
      children: [
        Expanded(
          child: _buildUnifiedStatCard(
            'Ingresos',
            totalSales,
            AppColors.success,
            Icons.trending_up,
            '${controller.dashboardStats?.sales.totalSales ?? 0} ventas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildUnifiedStatCard(
            'Gastos',
            totalExpenses,
            AppColors.error,
            Icons.trending_down,
            '${controller.dashboardStats?.expenses.totalExpenses ?? 0} gastos',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildUnifiedStatCard(
            'Facturas',
            controller.totalInvoices.toDouble(),
            controller.pendingInvoices > 0 ? AppColors.warning : AppColors.info,
            Icons.receipt_long,
            controller.pendingInvoices > 0 
              ? '${controller.pendingInvoices} pendientes'
              : 'Todas al día',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildUnifiedStatCard(
            'Productos',
            controller.totalProducts.toDouble(),
            controller.lowStockProducts > 0 ? AppColors.error : AppColors.primary,
            Icons.inventory_2,
            controller.lowStockProducts > 0
              ? '${controller.lowStockProducts} bajo stock'
              : 'Stock normal',
          ),
        ),
      ],
    );
  }

  // Card estadística unificada que combina información de DashboardStatsGrid
  Widget _buildUnifiedStatCard(
    String title,
    double value,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Builder(
      builder: (context) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _getCardTapAction(title),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono y título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: ResponsiveText.getCaptionSize(context) + 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveText.getCaptionSize(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Valor principal
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title == 'Facturas' || title == 'Productos'
                        ? value.toInt().toString()
                        : AppFormatters.formatCurrency(value),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveText.getValueTextSize(context),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtítulo
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: math.max(ResponsiveText.getCaptionSize(context) - 1, 8.0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Acciones de tap para las cards unificadas
  VoidCallback? _getCardTapAction(String title) {
    switch (title) {
      case 'Ingresos':
        return controller.navigateToSales;
      case 'Gastos':
        return controller.navigateToExpenses;
      case 'Facturas':
        return controller.navigateToInvoices;
      case 'Productos':
        return controller.navigateToProducts;
      default:
        return null;
    }
  }

  // Decoración consistente para las cards
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
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
    );
  }
}

// Clase para barras animadas espectaculares
class _AnimatedBar extends StatefulWidget {
  final String label;
  final double value;
  final double targetHeight;
  final Color color;
  final double percentage;

  const _AnimatedBar({
    required this.label,
    required this.value,
    required this.targetHeight,
    required this.color,
    required this.percentage,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with TickerProviderStateMixin {
  late AnimationController _heightController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _heightAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación principal de altura (crecimiento)
    _heightController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animación de brillo/glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animación de pulso continuo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: widget.targetHeight,
    ).animate(CurvedAnimation(
      parent: _heightController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animaciones con delay escalonado
    Future.delayed(Duration(milliseconds: widget.label == 'Ingresos' ? 100 : 300), () {
      if (mounted) {
        _heightController.forward();
      }
    });
    
    Future.delayed(Duration(milliseconds: widget.label == 'Ingresos' ? 600 : 900), () {
      if (mounted) {
        _glowController.forward();
      }
    });

    // Pulso continuo solo si hay valor
    if (widget.value > 0) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _pulseController.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_heightAnimation, _glowAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Valor encima de la barra con animación de aparición
              if (widget.value > 0)
                AnimatedOpacity(
                  opacity: _glowAnimation.value,
                  duration: const Duration(milliseconds: 500),
                  child: Transform.translate(
                    offset: Offset(0, -5 * _glowAnimation.value),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 8 * _glowAnimation.value,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AppFormatters.formatCurrency(widget.value),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Barra principal con efectos espectaculares
              Flexible(
                child: Container(
                  width: 70, // Reducido para evitar overflow
                  height: _heightAnimation.value.clamp(0.0, double.infinity),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withOpacity(0.9),
                      widget.color,
                      widget.color.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(2),
                  ),
                  boxShadow: [
                    // Sombra principal
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    // Efecto glow dinámico
                    BoxShadow(
                      color: widget.color.withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      offset: const Offset(0, 0),
                    ),
                    // Luz superior
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1 * _glowAnimation.value),
                      blurRadius: 4 * _glowAnimation.value,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Reflejo brillante en la parte superior
                    if (_glowAnimation.value > 0.5)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20 * (_glowAnimation.value - 0.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    
                    // Efectos de partículas (simulados con pequeños puntos)
                    if (_glowAnimation.value > 0.8)
                      ...List.generate(3, (index) {
                        return Positioned(
                          top: 10.0 + (index * 15),
                          right: 5 + (index * 2.0),
                          child: AnimatedOpacity(
                            opacity: (_pulseAnimation.value - 0.5).clamp(0.0, 1.0),
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}