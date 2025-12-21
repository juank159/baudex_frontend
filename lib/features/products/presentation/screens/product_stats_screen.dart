// lib/features/products/presentation/screens/product_stats_screen.dart
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_stats_widget.dart';

class ProductStatsScreen extends GetView<ProductsController> {
  const ProductStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildElegantAppBar(context),
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando estadísticas...');
        }

        if (controller.stats == null) {
          return _buildEmptyState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
    );
  }

  // ==================== ELEGANT APP BAR ====================

  PreferredSizeWidget _buildElegantAppBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: isMobile ? 18 : 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estadísticas de Productos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Panel de análisis e inventario',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: controller.loadInitialData,
          tooltip: 'Actualizar estadísticas',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          itemBuilder: (context) => [
            _buildElegantPopupMenuItem('refresh', Icons.refresh, 'Actualizar', ElegantLightTheme.primaryGradient),
            _buildElegantPopupMenuItem('period', Icons.date_range, 'Seleccionar Período', ElegantLightTheme.infoGradient),
            const PopupMenuDivider(),
            _buildElegantPopupMenuItem('export_pdf', Icons.picture_as_pdf, 'Exportar PDF', ElegantLightTheme.errorGradient),
            _buildElegantPopupMenuItem('export_excel', Icons.table_chart, 'Exportar Excel', ElegantLightTheme.successGradient),
            const PopupMenuDivider(),
            _buildElegantPopupMenuItem('detailed_report', Icons.analytics, 'Reporte Detallado', ElegantLightTheme.warningGradient),
            _buildElegantPopupMenuItem('share', Icons.share, 'Compartir', ElegantLightTheme.primaryGradient),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildElegantPopupMenuItem(
    String value,
    IconData icon,
    String label,
    LinearGradient gradient,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => controller.loadInitialData(),
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildStatsHeader(context),
            const SizedBox(height: 12),
            _buildQuickMetricsRow(context),
            const SizedBox(height: 12),
            ProductStatsWidget(stats: controller.stats!, isCompact: true),
            const SizedBox(height: 12),
            _buildAlertsSection(context),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => controller.loadInitialData(),
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                _buildStatsHeader(context),
                const SizedBox(height: 16),
                _buildQuickMetricsRow(context),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ProductStatsWidget(stats: controller.stats!, isCompact: false),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildAlertsSection(context),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => controller.loadInitialData(),
            color: ElegantLightTheme.primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsHeader(context),
                  const SizedBox(height: 14),
                  _buildQuickMetricsRow(context),
                  const SizedBox(height: 14),
                  ProductStatsWidget(stats: controller.stats!, isCompact: false),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.cardColor,
                ElegantLightTheme.backgroundColor,
              ],
            ),
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarHeader(context),
                      const SizedBox(height: 12),
                      _buildQuickSummary(context),
                      const SizedBox(height: 12),
                      _buildStockDistribution(context),
                      const SizedBox(height: 12),
                      _buildAlertsSection(context),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),
                      const SizedBox(height: 12),
                      _buildQuickFilters(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== STATS HEADER ====================

  Widget _buildStatsHeader(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : (isDesktop ? 12 : 16),
        vertical: isMobile ? 12 : (isDesktop ? 10 : 14),
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : (isDesktop ? 8 : 10)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: isMobile ? 20 : (isDesktop ? 20 : 22),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Panel de Estadísticas',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : (isDesktop ? 15 : 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Análisis completo del inventario y productos',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : (isDesktop ? 10 : 11),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Panel de Control',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK METRICS ROW ====================

  Widget _buildQuickMetricsRow(BuildContext context) {
    final stats = controller.stats!;
    final isMobile = context.isMobile;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Productos',
            stats.total.toString(),
            Icons.inventory_2,
            ElegantLightTheme.primaryBlue,
            isMobile,
            context,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildMetricCard(
            'Valor Inventario',
            '\$${(stats.totalValue / 1000).toStringAsFixed(1)}K',
            Icons.attach_money,
            const Color(0xFF10B981),
            isMobile,
            context,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildMetricCard(
            'Activos',
            stats.active.toString(),
            Icons.check_circle,
            const Color(0xFF3B82F6),
            isMobile,
            context,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildMetricCard(
            'Alertas',
            (stats.lowStock + stats.outOfStock).toString(),
            Icons.warning_rounded,
            const Color(0xFFF59E0B),
            isMobile,
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
    BuildContext context,
  ) {
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : (isDesktop ? 10 : 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : (isDesktop ? 8 : 9)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 20 : (isDesktop ? 22 : 24),
            ),
          ),
          SizedBox(height: isMobile ? 8 : (isDesktop ? 10 : 12)),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : (isDesktop ? 19 : 20),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10.5 : (isDesktop ? 11 : 11.5),
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== ALERTS SECTION ====================

  Widget _buildAlertsSection(BuildContext context) {
    final stats = controller.stats!;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : (isDesktop ? 14 : 16)),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 7 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notification_important,
                  color: Colors.white,
                  size: isMobile ? 16 : (isDesktop ? 17 : 18),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Text(
                  'Alertas y Notificaciones',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : (isDesktop ? 15.5 : 16),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : (isDesktop ? 14 : 16)),
          if (stats.lowStock > 0)
            _buildAlertItem(
              'Stock Bajo',
              '${stats.lowStock} productos requieren reposición',
              Icons.warning_rounded,
              const Color(0xFFF59E0B),
              () => controller.applyStockFilter(lowStock: true),
              context,
            ),
          if (stats.outOfStock > 0) ...[
            if (stats.lowStock > 0) const SizedBox(height: 12),
            _buildAlertItem(
              'Sin Stock',
              '${stats.outOfStock} productos agotados',
              Icons.error_rounded,
              const Color(0xFFEF4444),
              () => controller.applyStockFilter(inStock: false),
              context,
            ),
          ],
          if (stats.inactive > 0) ...[
            if (stats.lowStock > 0 || stats.outOfStock > 0) const SizedBox(height: 12),
            _buildAlertItem(
              'Productos Inactivos',
              '${stats.inactive} productos desactivados',
              Icons.pause_circle_rounded,
              const Color(0xFF6B7280),
              () => controller.applyStatusFilter(ProductStatus.inactive),
              context,
            ),
          ],
          if (stats.lowStock == 0 && stats.outOfStock == 0 && stats.inactive == 0)
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Todo está en orden. No hay alertas pendientes.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
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

  Widget _buildAlertItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
            ),
            SizedBox(width: isMobile ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: ElegantLightTheme.textSecondary,
                    ),
                    maxLines: isMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: isMobile ? 12 : 14,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================

  Widget _buildQuickActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final spacing = ResponsiveHelper.getHorizontalSpacing(context) * 0.75;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : (isDesktop ? 14 : 16)),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 7 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: isMobile ? 16 : (isDesktop ? 17 : 18),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: isMobile ? 15 : (isDesktop ? 15.5 : 16),
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : (isDesktop ? 14 : 16)),
          if (isMobile) ...[
            CustomButton(
              text: 'Ver Productos',
              icon: Icons.inventory_2,
              type: ButtonType.primary,
              onPressed: () => Get.toNamed('/products'),
              width: double.infinity,
            ),
            SizedBox(height: spacing * 0.75),
            CustomButton(
              text: 'Agregar Producto',
              icon: Icons.add,
              type: ButtonType.primary,
              onPressed: () => Get.toNamed('/products/create'),
              width: double.infinity,
            ),
            SizedBox(height: spacing * 0.75),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Stock Bajo',
                    icon: Icons.warning,
                    type: ButtonType.outline,
                    onPressed: () => controller.applyStockFilter(lowStock: true),
                  ),
                ),
                SizedBox(width: spacing * 0.75),
                Expanded(
                  child: CustomButton(
                    text: 'Actualizar',
                    icon: Icons.refresh,
                    type: ButtonType.outline,
                    onPressed: controller.refreshProducts,
                  ),
                ),
              ],
            ),
          ] else ...[
            CustomButton(
              text: 'Ver Productos',
              icon: Icons.inventory_2,
              type: ButtonType.primary,
              backgroundColor: ElegantLightTheme.primaryBlue,
              onPressed: () => Get.toNamed('/products'),
              width: double.infinity,
            ),
            SizedBox(height: spacing),
            CustomButton(
              text: 'Agregar Producto',
              icon: Icons.add,
              type: ButtonType.primary,
              backgroundColor: const Color(0xFF10B981),
              onPressed: () => Get.toNamed('/products/create'),
              width: double.infinity,
            ),
            SizedBox(height: spacing),
            CustomButton(
              text: 'Stock Bajo',
              icon: Icons.warning,
              type: ButtonType.outline,
              backgroundColor: const Color(0xFFF59E0B),
              onPressed: () => controller.applyStockFilter(lowStock: true),
              width: double.infinity,
            ),
            SizedBox(height: spacing),
            CustomButton(
              text: 'Actualizar',
              icon: Icons.refresh,
              type: ButtonType.outline,
              backgroundColor: const Color(0xFF3B82F6),
              onPressed: controller.refreshProducts,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  // ==================== QUICK SUMMARY ====================

  Widget _buildQuickSummary(BuildContext context) {
    final stats = controller.stats!;
    final inStock = stats.total - stats.lowStock - stats.outOfStock;
    final stockPercentage = stats.total > 0 ? (inStock / stats.total * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.insights, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                'Resumen Rápido',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryItem('Total Productos', stats.total.toString(), Icons.inventory_2, ElegantLightTheme.primaryBlue),
          const SizedBox(height: 8),
          _buildSummaryItem('Disponibilidad', '$stockPercentage%', Icons.pie_chart, const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildSummaryItem('Valor Total', '\$${(stats.totalValue / 1000).toStringAsFixed(1)}K', Icons.attach_money, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== STOCK DISTRIBUTION ====================

  Widget _buildStockDistribution(BuildContext context) {
    final stats = controller.stats!;
    final inStock = stats.total - stats.lowStock - stats.outOfStock;

    final total = stats.total > 0 ? stats.total : 1;
    final inStockPercent = (inStock / total);
    final lowStockPercent = (stats.lowStock / total);
    final outStockPercent = (stats.outOfStock / total);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ElegantLightTheme.backgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                'Distribución de Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de distribución
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (inStockPercent > 0)
                    Expanded(
                      flex: (inStockPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF10B981).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (lowStockPercent > 0)
                    Expanded(
                      flex: (lowStockPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B),
                              const Color(0xFFF59E0B).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (outStockPercent > 0)
                    Expanded(
                      flex: (outStockPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEF4444),
                              const Color(0xFFEF4444).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda
          _buildLegendItem('En Stock', inStock.toString(), const Color(0xFF10B981)),
          const SizedBox(height: 6),
          _buildLegendItem('Stock Bajo', stats.lowStock.toString(), const Color(0xFFF59E0B)),
          const SizedBox(height: 6),
          _buildLegendItem('Sin Stock', stats.outOfStock.toString(), const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== QUICK FILTERS ====================

  Widget _buildQuickFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.filter_list, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filtros Rápidos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterChip('Todos', Icons.inventory_2, ElegantLightTheme.primaryBlue, () {
            Get.toNamed('/products');
          }),
          const SizedBox(height: 6),
          _buildFilterChip('Activos', Icons.check_circle, const Color(0xFF10B981), () {
            Get.toNamed('/products');
          }),
          const SizedBox(height: 6),
          _buildFilterChip('Stock Bajo', Icons.warning, const Color(0xFFF59E0B), () {
            Get.toNamed('/products');
          }),
          const SizedBox(height: 6),
          _buildFilterChip('Sin Stock', Icons.error, const Color(0xFFEF4444), () {
            Get.toNamed('/products');
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 10, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
          ),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay estadísticas disponibles',
              style: TextStyle(
                fontSize: 20,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega algunos productos para ver las estadísticas',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Agregar Primer Producto',
              icon: Icons.add,
              onPressed: () => Get.toNamed('/products/create'),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'refresh':
        controller.loadInitialData();
        break;
      case 'period':
        _showPeriodSelector(context);
        break;
      case 'export_pdf':
        _showExportOptions(context, format: 'PDF');
        break;
      case 'export_excel':
        _showExportOptions(context, format: 'Excel');
        break;
      case 'detailed_report':
        _showReportOptions(context);
        break;
      case 'share':
        _showShareOptions(context);
        break;
    }
  }

  void _showPeriodSelector(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Seleccionar Período'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtrar estadísticas por período:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, {String? format}) {
    Get.dialog(
      AlertDialog(
        title: Text('Exportar ${format ?? "Datos"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exportar estadísticas en formato ${format ?? "seleccionado"}:'),
            const SizedBox(height: 16),
            const Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Exportar', 'Funcionalidad pendiente de implementar', snackPosition: SnackPosition.TOP);
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showReportOptions(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Generar Reporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el tipo de reporte:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Reporte', 'Funcionalidad pendiente de implementar', snackPosition: SnackPosition.TOP);
            },
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Compartir Estadísticas'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Compartir resumen de estadísticas:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Compartir', 'Funcionalidad pendiente de implementar', snackPosition: SnackPosition.TOP);
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }
}
