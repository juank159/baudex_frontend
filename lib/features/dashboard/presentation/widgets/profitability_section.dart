// lib/features/dashboard/presentation/widgets/profitability_section.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../controllers/dashboard_controller.dart';

/// Sección de rentabilidad para el dashboard
/// Muestra métricas precisas de margen bruto y costos de ventas
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

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: ElegantLightTheme.glassDecoration(
              borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
              gradient: ElegantLightTheme.glassGradient,
            ),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(),
                const SizedBox(height: 20),
                _buildProfitabilityMetrics(profitability, context),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6), // Violet
                Color(0xFF7C3AED), // Violet dark
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análisis de Rentabilidad',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Métricas de rentabilidad FIFO',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitabilityMetrics(ProfitabilityStats profitability, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildMobileMetrics(profitability);
    } else {
      return _buildDesktopMetrics(profitability);
    }
  }

  Widget _buildMobileMetrics(ProfitabilityStats profitability) {
    return Column(
      children: [
        // Primera fila - 2 métricas
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Margen Bruto',
                value: '${profitability.grossMarginPercentage.toStringAsFixed(1)}%',
                subtitle: AppFormatters.formatCurrency(profitability.grossProfit),
                color: const Color(0xFF8B5CF6),
                icon: Icons.pie_chart_rounded,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'COGS',
                value: AppFormatters.formatCurrency(profitability.totalCOGS),
                subtitle: 'Costo Ventas',
                color: const Color(0xFFF59E0B),
                icon: Icons.inventory_rounded,
                isMobile: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Segunda fila - 2 métricas
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Ganancia Neta',
                value: AppFormatters.formatCurrency(profitability.netProfit),
                subtitle: '${profitability.netMarginPercentage.toStringAsFixed(1)}% neto',
                color: profitability.netProfit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                icon: Icons.account_balance_wallet_rounded,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Promedio/Venta',
                value: '${profitability.averageMarginPerSale.toStringAsFixed(1)}%',
                subtitle: profitability.trend.isImproving ? 'Mejorando' : 'Estable',
                color: const Color(0xFF3B82F6),
                icon: Icons.trending_up_rounded,
                isMobile: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMetrics(ProfitabilityStats profitability) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Margen Bruto',
            value: '${profitability.grossMarginPercentage.toStringAsFixed(1)}%',
            subtitle: AppFormatters.formatCurrency(profitability.grossProfit),
            color: const Color(0xFF8B5CF6),
            icon: Icons.pie_chart_rounded,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'COGS Total',
            value: AppFormatters.formatCurrency(profitability.totalCOGS),
            subtitle: 'Costo de Ventas',
            color: const Color(0xFFF59E0B),
            icon: Icons.inventory_rounded,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'Ganancia Neta',
            value: AppFormatters.formatCurrency(profitability.netProfit),
            subtitle: '${profitability.netMarginPercentage.toStringAsFixed(1)}% neto',
            color: profitability.netProfit >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            icon: Icons.account_balance_wallet_rounded,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'Promedio/Venta',
            value: '${profitability.averageMarginPerSale.toStringAsFixed(1)}%',
            subtitle: profitability.trend.isImproving ? 'Mejorando ↑' : 'Estable →',
            color: const Color(0xFF3B82F6),
            icon: Icons.trending_up_rounded,
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isMobile,
  }) {
    // Tamaños MUCHO más compactos para reducir altura
    final iconSize = isMobile ? 18.0 : 22.0;  // Reducido de 24/32
    final titleSize = isMobile ? 10.0 : 11.0;  // Reducido de 11/12
    final valueSize = isMobile ? 14.0 : 16.0;  // Reducido de 16/20
    final subtitleSize = isMobile ? 9.0 : 10.0;  // Reducido de 10/11
    final padding = isMobile ? 8.0 : 10.0;  // Reducido de 12/16

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),  // Reducido de 12/14
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,  // Reducido de 8
            offset: const Offset(0, 2),  // Reducido de (0, 3)
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono con badge circular
          Container(
            padding: EdgeInsets.all(isMobile ? 5 : 6),  // Reducido de 8/10
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,  // Reducido de 2
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          SizedBox(height: isMobile ? 5 : 6),  // Reducido de 8/12
          // Título
          Text(
            title,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 3 : 4),  // Reducido de 6/8
          // Valor principal
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: valueSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 3),  // Reducido de 4/6
          // Subtítulo
          Text(
            subtitle,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary.withOpacity(0.8),
              fontSize: subtitleSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 200,
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            gradient: ElegantLightTheme.glassGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: ElegantLightTheme.primaryBlue,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando análisis de rentabilidad...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 200,
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            gradient: ElegantLightTheme.glassGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: const Color(0xFFEF4444),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos de rentabilidad',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshAll(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ElegantLightTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
