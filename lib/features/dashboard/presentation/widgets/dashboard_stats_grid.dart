// lib/features/dashboard/presentation/widgets/dashboard_stats_grid.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
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

  bool get _hasReceivables =>
      (controller.dashboardStats?.sales.accountsReceivable ?? 0) > 0;

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
        if (_hasReceivables) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          _buildReceivablesCard(),
        ],
      ],
    );
  }

  Widget _buildTabletGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRevenueCard()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildInvoicesCard()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildProductsCard()),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildExpensesCard()),
          ],
        ),
        if (_hasReceivables) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          Row(
            children: [
              Expanded(child: _buildReceivablesCard()),
              const Spacer(flex: 3),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRevenueCard()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildInvoicesCard()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildProductsCard()),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(child: _buildExpensesCard()),
          ],
        ),
        if (_hasReceivables) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Expanded(child: _buildReceivablesCard()),
              const Spacer(flex: 3),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRevenueCard() {
    final collected = controller.totalCollected;
    final billed = controller.totalBilled;
    // El subtítulo muestra el facturado solo si difiere (hay ventas a crédito sin cobrar).
    final hasPending = billed > collected + 1; // tolerancia de 1 peso
    final subtitle = hasPending
        ? 'de ${AppFormatters.formatCurrency(billed)} facturado'
        : '${controller.dashboardStats?.sales.totalSales ?? 0} ventas';

    return _StatCard(
      title: 'Ingresos Cobrados',
      value: AppFormatters.formatCurrency(collected),
      subtitle: subtitle,
      icon: Icons.trending_up,
      color: AppColors.success,
      onTap: controller.navigateToSales,
      tooltip:
          'Dinero que realmente entró a caja en el período. "Facturado" incluye ventas a crédito que aún no se cobran.',
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

  Widget _buildReceivablesCard() {
    // Preferimos el breakdown nuevo; fallback al legacy si el backend viejo.
    final rec = controller.dashboardStats?.receivables;
    final total = rec?.total ??
        controller.dashboardStats?.sales.accountsReceivable ??
        0;
    final count = rec?.count ??
        controller.dashboardStats?.sales.receivableCount ??
        0;

    // Color semáforo: rojo si hay vencidas, amarillo si por vencer, ámbar neutro si al día.
    Color color = const Color(0xFFF59E0B);
    String statusSuffix = '';
    if (rec != null) {
      if (rec.hasOverdue) {
        color = const Color(0xFFEF4444);
        statusSuffix = ' · ${rec.overdue.count} vencida${rec.overdue.count == 1 ? '' : 's'}';
      } else if (rec.hasDueSoon) {
        color = const Color(0xFFF59E0B);
        statusSuffix = ' · ${rec.dueSoon.count} por vencer';
      } else if (rec.hasAny) {
        color = const Color(0xFF10B981);
      }
    }

    return _StatCard(
      title: 'Cuentas por Cobrar',
      value: AppFormatters.formatCurrency(total),
      subtitle: '$count factura${count == 1 ? '' : 's'} pendiente${count == 1 ? '' : 's'}$statusSuffix',
      icon: Icons.account_balance_wallet_outlined,
      color: color,
      onTap: controller.navigateToInvoices,
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
            Text(
              'Error al cargar estadísticas',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: controller.refreshStats,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: Text('Reintentar', style: AppTextStyles.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  /// Texto que aparece al tocar el ícono ⓘ junto al título.
  /// Si es null, no se renderiza el ícono de ayuda.
  final String? tooltip;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.tooltip,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_rotationAnimation.value)
                    ..rotateY(_rotationAnimation.value * 0.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 150, // Aumentado para evitar overflow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: ElegantLightTheme.glassGradient,
                      border: Border.all(
                        color: widget.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        ...ElegantLightTheme.glassShadow,
                        // Efecto glow cuando hover
                        if (_glowAnimation.value > 0)
                          BoxShadow(
                            color: widget.color.withOpacity(
                              _glowAnimation.value * 0.4,
                            ),
                            blurRadius: 25 * _glowAnimation.value,
                            offset: const Offset(0, 5),
                            spreadRadius: 3 * _glowAnimation.value,
                          ),
                      ],
                    ),
                    child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    overlayColor: WidgetStateProperty.all(
                      widget.color.withOpacity(0.05),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        // Gradiente sutil para dar profundidad
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con icono y título
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icono con efecto glassmórfico
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          widget.color.withOpacity(0.3),
                                          widget.color.withOpacity(0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.color.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      color: widget.color,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Título con animación de brillos
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: ShaderMask(
                                        shaderCallback:
                                            (bounds) => LinearGradient(
                                              colors: [
                                                AppColors.textSecondary,
                                                AppColors.textSecondary.withOpacity(0.8),
                                              ],
                                            ).createShader(bounds),
                                        child: Text(
                                          widget.title,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (widget.tooltip != null) ...[
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        message: widget.tooltip!,
                                        preferBelow: false,
                                        triggerMode: TooltipTriggerMode.tap,
                                        showDuration: const Duration(seconds: 6),
                                        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          size: 13,
                                          color: widget.color.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Valor principal con efecto de brillo
                          ShaderMask(
                            shaderCallback:
                                (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.textPrimary,
                                    AppColors.textPrimary.withOpacity(0.8),
                                  ],
                                ).createShader(bounds),
                            child: Text(
                              widget.value,
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Subtitle con indicador visual
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Pequeño indicador de color
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: widget.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.subtitle!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
