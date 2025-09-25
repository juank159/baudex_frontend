// lib/features/products/presentation/screens/product_stats_screen.dart
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_stats_widget.dart';

class ProductStatsScreen extends GetView<ProductsController> {
  const ProductStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Estadísticas de Productos',
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
        ),
      ),
      elevation: 0,
      actions: [
        // Refrescar estadísticas - Solo en desktop/tablet
        if (!ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadInitialData,
            tooltip: 'Actualizar estadísticas',
          ),

        // Filtrar por periodo - Solo en desktop/tablet
        if (!ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showPeriodSelector(context),
            tooltip: 'Seleccionar período',
          ),

        // Menú de opciones - Siempre visible
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Actualizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'period',
                  child: Row(
                    children: [
                      Icon(Icons.date_range),
                      SizedBox(width: 8),
                      Text('Seleccionar Período'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Exportar PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 8),
                      Text('Exportar Excel'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'detailed_report',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Reporte Detallado'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getPadding(context),
      child: Column(
        children: [
          // Resumen general compacto
          _buildOverviewCard(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

          // Widget principal de estadísticas
          ProductStatsWidget(stats: controller.stats!, isCompact: true),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

          // Acciones rápidas
          _buildQuickActions(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

          // Alertas y recomendaciones
          _buildAlertsSection(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 2),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: ResponsiveHelper.isTablet(context) ? 1000 : 1200,
        child: Column(
          children: [
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

            // Resumen en cards horizontales
            _buildOverviewCards(context),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

            // Estadísticas principales en dos columnas
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: ProductStatsWidget(
                      stats: controller.stats!,
                      isCompact: false,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopProductsCard(context),
                        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                        _buildAlertsSection(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

            // Acciones
            _buildActions(context),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context) * 1.5),
            child: Column(
              children: [
                // Cards de resumen
                _buildOverviewCards(context),
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

                // Estadísticas principales
                ProductStatsWidget(stats: controller.stats!, isCompact: false),
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

                // Gráficos adicionales
                _buildAdditionalCharts(context),
              ],
            ),
          ),
        ),

        // Panel lateral derecho
        Container(
          width: MediaQuery.of(context).size.width * 0.25,
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context)),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Panel de Control',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del panel
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context)),
                  child: Column(
                    children: [
                      _buildTopProductsCard(context),
                      SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                      _buildAlertsSection(context),
                      SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                      _buildQuickActions(context),
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

  // ==================== OVERVIEW CARDS ====================

  Widget _buildOverviewCard(BuildContext context) {
    final stats = controller.stats!;

    return CustomCard(
      child: Column(
        children: [
          Text(
            'Resumen del Inventario',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 20,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          Row(
            children: [
              _buildMiniStatCard(
                'Total',
                stats.total.toString(),
                Icons.inventory_2,
                Colors.blue,
                context,
              ),
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.75),
              _buildMiniStatCard(
                'Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
                context,
              ),
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.75),
              _buildMiniStatCard(
                'Alertas',
                (stats.lowStock + stats.outOfStock).toString(),
                Icons.warning,
                Colors.orange,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    final stats = controller.stats!;
    final spacing = ResponsiveHelper.getHorizontalSpacing(context);

    if (ResponsiveHelper.isMobile(context)) {
      // En móvil: layout vertical con 2 columnas
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.total.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                  'Productos',
                  context,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                  'Valor',
                  '\$${stats.totalValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                  'Inventario',
                  context,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Activos',
                  stats.active.toString(),
                  Icons.check_circle,
                  Colors.teal,
                  '${((stats.active / stats.total) * 100).toStringAsFixed(1)}%',
                  context,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                  'Alertas',
                  (stats.lowStock + stats.outOfStock).toString(),
                  Icons.warning,
                  Colors.orange,
                  'Atención',
                  context,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // En tablet/desktop: layout horizontal
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total de Productos',
            stats.total.toString(),
            Icons.inventory_2,
            Colors.blue,
            'Productos registrados',
            context,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildStatCard(
            'Valor del Inventario',
            '\$${stats.totalValue.toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green,
            'Valor total estimado',
            context,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildStatCard(
            'Productos Activos',
            stats.active.toString(),
            Icons.check_circle,
            Colors.teal,
            '${((stats.active / stats.total) * 100).toStringAsFixed(1)}% del total',
            context,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildStatCard(
            'Alertas de Stock',
            (stats.lowStock + stats.outOfStock).toString(),
            Icons.warning,
            Colors.orange,
            'Requieren atención',
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    BuildContext context,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: color, 
                  size: isMobile ? 20 : 24,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 18,
                    tablet: 22,
                    desktop: 24,
                  ),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 16,
              ),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveHelper.isMobile(context) ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: color, 
              size: ResponsiveHelper.isMobile(context) ? 18 : 20,
            ),
            SizedBox(
              height: ResponsiveHelper.isMobile(context) ? 6 : 8,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 11,
                  tablet: 12,
                  desktop: 12,
                ),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

//   // ==================== ADDITIONAL SECTIONS ====================

  Widget _buildTopProductsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.5),
              Expanded(
                child: Text(
                  'Productos Destacados',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed('/products'),
                child: Text(
                  ResponsiveHelper.isMobile(context) ? 'Ver' : 'Ver todos',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          _buildProductListItem(
            'Producto más vendido',
            'No disponible',
            Icons.star,
            Colors.amber,
            context,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.5),
          _buildProductListItem(
            'Mayor valor en stock',
            'No disponible',
            Icons.attach_money,
            Colors.green,
            context,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.5),
          _buildProductListItem(
            'Último agregado',
            'No disponible',
            Icons.new_releases,
            Colors.blue,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon, 
              color: color, 
              size: ResponsiveHelper.isMobile(context) ? 14 : 16,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 11,
                      tablet: 12,
                      desktop: 12,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 10,
                      tablet: 11,
                      desktop: 11,
                    ),
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    final stats = controller.stats!;
    final spacing = ResponsiveHelper.getVerticalSpacing(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notification_important, color: Colors.orange),
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.5),
              Expanded(
                child: Text(
                  ResponsiveHelper.isMobile(context) 
                      ? 'Alertas' 
                      : 'Alertas y Notificaciones',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Stock bajo
          if (stats.lowStock > 0)
            _buildAlertItem(
              'Stock Bajo',
              '${stats.lowStock} productos requieren reposición',
              Icons.warning,
              Colors.orange,
              () => controller.applyStockFilter(lowStock: true),
              context,
            ),

          // Sin stock
          if (stats.outOfStock > 0) ...[
            if (stats.lowStock > 0) SizedBox(height: spacing * 0.5),
            _buildAlertItem(
              'Sin Stock',
              '${stats.outOfStock} productos agotados',
              Icons.error,
              Colors.red,
              () => controller.applyStockFilter(inStock: false),
              context,
            ),
          ],

          // Productos inactivos
          if (stats.inactive > 0) ...[
            if (stats.lowStock > 0 || stats.outOfStock > 0)
              SizedBox(height: spacing * 0.5),
            _buildAlertItem(
              'Productos Inactivos',
              '${stats.inactive} productos desactivados',
              Icons.pause_circle,
              Colors.grey,
              () => controller.applyStatusFilter(ProductStatus.inactive),
              context,
            ),
          ],

          // Si no hay alertas
          if (stats.lowStock == 0 &&
              stats.outOfStock == 0 &&
              stats.inactive == 0)
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.isMobile(context) ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context) * 0.5),
                  Expanded(
                    child: Text(
                      ResponsiveHelper.isMobile(context)
                          ? 'Todo está en orden.'
                          : 'Todo está en orden. No hay alertas pendientes.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 14,
                        ),
                        fontWeight: FontWeight.w500,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: color, 
              size: isMobile ? 18 : 20,
            ),
            SizedBox(width: isMobile ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 14,
                      ),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 11,
                        tablet: 12,
                        desktop: 12,
                      ),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: isMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios, 
              size: isMobile ? 12 : 14, 
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final spacing = ResponsiveHelper.getHorizontalSpacing(context);
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 16,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

          if (isMobile) ...[
            // En móvil: layout vertical compacto
            CustomButton(
              text: 'Ver Productos',
              icon: Icons.inventory_2,
              type: ButtonType.outline,
              onPressed: () => Get.toNamed('/products'),
              width: double.infinity,
            ),
            SizedBox(height: spacing * 0.75),
            CustomButton(
              text: 'Agregar Producto',
              icon: Icons.add,
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
            // En tablet/desktop: layout en grid 2x2
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Ver Productos',
                    icon: Icons.inventory_2,
                    type: ButtonType.outline,
                    onPressed: () => Get.toNamed('/products'),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: CustomButton(
                    text: 'Agregar Producto',
                    icon: Icons.add,
                    onPressed: () => Get.toNamed('/products/create'),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
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
                SizedBox(width: spacing),
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
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalCharts(BuildContext context) {
    final spacing = ResponsiveHelper.getHorizontalSpacing(context);
    
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tendencias',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                Container(
                  height: ResponsiveHelper.isMobile(context) ? 150 : 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Gráfico de tendencias\n(Próximamente)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis por Categoría',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
                Container(
                  height: ResponsiveHelper.isMobile(context) ? 150 : 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Análisis por categorías\n(Próximamente)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile) {
      return Column(
        children: [
          CustomButton(
            text: 'Generar Reporte',
            icon: Icons.analytics,
            onPressed: () => _showReportOptions(context),
            width: double.infinity,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.75),
          CustomButton(
            text: 'Exportar Datos',
            icon: Icons.download,
            type: ButtonType.outline,
            onPressed: () => _showExportOptions(context),
            width: double.infinity,
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Generar Reporte',
          icon: Icons.analytics,
          onPressed: () => _showReportOptions(context),
        ),
        SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
        CustomButton(
          text: 'Exportar Datos',
          icon: Icons.download,
          type: ButtonType.outline,
          onPressed: () => _showExportOptions(context),
        ),
      ],
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: ResponsiveHelper.isMobile(context) ? 80 : 100,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            Text(
              'No hay estadísticas disponibles',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 18,
                ),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 0.5),
            Text(
              'Agrega algunos productos para ver las estadísticas',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 14,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 2),
            CustomButton(
              text: 'Agregar Primer Producto',
              icon: Icons.add,
              onPressed: () => Get.toNamed('/products/create'),
              width: ResponsiveHelper.isMobile(context) ? double.infinity : null,
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
            Text(
              'Exportar estadísticas en formato ${format ?? "seleccionado"}:',
            ),
            const SizedBox(height: 16),
            const Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Exportar',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Reporte',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Compartir',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }
}
