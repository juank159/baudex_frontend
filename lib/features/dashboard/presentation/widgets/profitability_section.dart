// lib/features/dashboard/presentation/widgets/profitability_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_text.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../controllers/dashboard_controller.dart';

/// Sección de rentabilidad FIFO para el dashboard
/// Muestra métricas precisas de margen bruto basadas en costos FIFO reales
class ProfitabilitySection extends GetWidget<DashboardController> {
  const ProfitabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profitability = controller.profitabilityStats;
      
      if (profitability == null) {
        if (controller.isLoadingProfitability) {
          return _buildLoadingState();
        }
        return _buildErrorState();
      }

      return Container(
        decoration: _buildCardDecoration(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 20),
            _buildProfitabilityMetrics(profitability),
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
              Icons.analytics_outlined,
              color: AppColors.primary,
              size: ResponsiveText.getIconSize(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análisis de Rentabilidad FIFO',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: ResponsiveText.getTitleLargeSize(context),
                ),
              ),
              Text(
                'Costos reales basados en método FIFO',
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

  Widget _buildProfitabilityMetrics(ProfitabilityStats profitability) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la pantalla es muy pequeña (móvil), usar diseño vertical
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return _buildMobileMetrics(profitability);
        } else {
          return _buildDesktopMetrics(profitability);
        }
      },
    );
  }

  Widget _buildMobileMetrics(ProfitabilityStats profitability) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Primera fila - 2 métricas
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  'Margen Bruto',
                  '${profitability.grossMarginPercentage.toStringAsFixed(1)}%',
                  AppColors.primary,
                  Icons.percent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactMetric(
                  'COGS',
                  AppFormatters.formatCurrency(profitability.totalCOGS),
                  AppColors.warning,
                  Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segunda fila - 2 métricas
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  'Ganancia Neta',
                  AppFormatters.formatCurrency(profitability.netProfit),
                  profitability.netProfit >= 0 ? AppColors.success : AppColors.error,
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactMetric(
                  'Promedio/Venta',
                  '${profitability.averageMarginPerSale.toStringAsFixed(1)}%',
                  AppColors.info,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMetrics(ProfitabilityStats profitability) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricColumn(
              'Margen Bruto',
              '${profitability.grossMarginPercentage.toStringAsFixed(1)}%',
              AppFormatters.formatCurrency(profitability.grossProfit),
              AppColors.primary,
              Icons.percent,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.primary.withOpacity(0.15),
          ),
          Expanded(
            child: _buildMetricColumn(
              'COGS Total',
              AppFormatters.formatCurrency(profitability.totalCOGS),
              'Método FIFO',
              AppColors.warning,
              Icons.inventory_2_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.primary.withOpacity(0.15),
          ),
          Expanded(
            child: _buildMetricColumn(
              'Ganancia Neta',
              AppFormatters.formatCurrency(profitability.netProfit),
              '${profitability.netMarginPercentage.toStringAsFixed(1)}% neto',
              profitability.netProfit >= 0 ? AppColors.success : AppColors.error,
              Icons.account_balance_wallet_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.primary.withOpacity(0.15),
          ),
          Expanded(
            child: _buildMetricColumn(
              'Promedio/Venta',
              '${profitability.averageMarginPerSale.toStringAsFixed(1)}%',
              _getTrendText(profitability.trend.isImproving),
              AppColors.info,
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    String title,
    String value,
    String subtitle,
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
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveText.getBodySmallSize(context),
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
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveText.getValueTextSize(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: ResponsiveText.getCaptionSize(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Métrica compacta para móviles con tipografía responsiva
  Widget _buildCompactMetric(
    String title,
    String value,
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
                size: ResponsiveText.getCaptionSize(context) + 4,
              ),
              const SizedBox(width: 4),
              Expanded(
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
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveText.getBodyMediumSize(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrendText(bool isImproving) {
    return isImproving ? 'Mejorando' : 'Estable';
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: _buildCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando análisis de rentabilidad...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: _buildCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos de rentabilidad',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => controller.refreshAll(),
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

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