// lib/features/dashboard/presentation/widgets/dashboard_stats_grid.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../app/shared/widgets/shimmer_loading.dart';

class DashboardStatsGrid extends GetView<DashboardController> {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingStats && controller.dashboardStats == null) {
        return _buildShimmerGrid();
      }

      if (controller.statsError != null && controller.dashboardStats == null) {
        return _buildErrorState();
      }

      return ResponsiveBuilder(
        mobile: _buildMobileGrid(),
        tablet: _buildTabletGrid(),
        desktop: _buildDesktopGrid(),
      );
    });
  }

  Widget _buildMobileGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRevenueCard()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildInvoicesCard()),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Expanded(child: _buildProductsCard()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildExpensesCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletGrid() {
    return Row(
      children: [
        Expanded(child: _buildRevenueCard()),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildInvoicesCard()),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildProductsCard()),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildExpensesCard()),
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return Row(
      children: [
        Expanded(child: _buildRevenueCard()),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildInvoicesCard()),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildProductsCard()),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildExpensesCard()),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return _StatCard(
      title: 'Ingresos',
      value: AppFormatters.formatCurrency(controller.totalRevenue),
      subtitle:
          controller.dashboardStats?.sales.totalSales != null
              ? '${controller.dashboardStats!.sales.totalSales} ventas'
              : null,
      icon: Icons.trending_up,
      color: AppColors.success,
      onTap: controller.navigateToSales,
    );
  }

  Widget _buildInvoicesCard() {
    return _StatCard(
      title: 'Facturas',
      value: controller.totalInvoices.toString(),
      subtitle:
          controller.pendingInvoices > 0
              ? '${controller.pendingInvoices} pendientes'
              : 'Todas al día',
      icon: Icons.receipt_long,
      color:
          controller.pendingInvoices > 0 ? AppColors.warning : AppColors.info,
      onTap: controller.navigateToInvoices,
    );
  }

  Widget _buildProductsCard() {
    return _StatCard(
      title: 'Productos',
      value: controller.totalProducts.toString(),
      subtitle:
          controller.lowStockProducts > 0
              ? '${controller.lowStockProducts} bajo stock'
              : 'Stock normal',
      icon: Icons.inventory_2,
      color:
          controller.lowStockProducts > 0 ? AppColors.error : AppColors.primary,
      onTap: controller.navigateToProducts,
    );
  }

  Widget _buildExpensesCard() {
    return _StatCard(
      title: 'Gastos',
      value: AppFormatters.formatCurrency(controller.totalExpenses),
      subtitle:
          controller.dashboardStats?.expenses.totalExpenses != null
              ? '${controller.dashboardStats!.expenses.totalExpenses} gastos'
              : null,
      icon: Icons.money_off,
      color: AppColors.error,
      onTap: controller.navigateToExpenses,
    );
  }

  Widget _buildShimmerGrid() {
    return ResponsiveBuilder(
      mobile: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(child: _buildShimmerCard()),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Row(
            children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(child: _buildShimmerCard()),
            ],
          ),
        ],
      ),
      tablet: Row(
        children: [
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(child: _buildShimmerCard()),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(child: _buildShimmerCard()),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerContainer(width: 60, height: 16),
            SizedBox(height: 12),
            ShimmerContainer(width: 100, height: 24),
            Spacer(),
            ShimmerContainer(width: 80, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                'Error al cargar estadísticas',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: controller.refreshStats,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'Reintentar',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
