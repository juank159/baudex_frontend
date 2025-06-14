// lib/features/products/presentation/screens/product_stats_screen.dart
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_stats_widget.dart';
import '../../domain/entities/product_stats.dart';

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
      title: const Text('Estadísticas de Productos'),
      elevation: 0,
      actions: [
        // Refrescar estadísticas
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadStats,
          tooltip: 'Actualizar estadísticas',
        ),

        // Filtrar por periodo
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: () => _showPeriodSelector(context),
          tooltip: 'Seleccionar período',
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
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
      padding: context.responsivePadding,
      child: Column(
        children: [
          // Resumen general compacto
          _buildOverviewCard(context),
          SizedBox(height: context.verticalSpacing),

          // Widget principal de estadísticas
          ProductStatsWidget(stats: controller.stats!, isCompact: false),
          SizedBox(height: context.verticalSpacing),

          // Acciones rápidas
          _buildQuickActions(context),
          SizedBox(height: context.verticalSpacing),

          // Alertas y recomendaciones
          _buildAlertsSection(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 1000,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),

            // Resumen en cards horizontales
            _buildOverviewCards(context),
            SizedBox(height: context.verticalSpacing),

            // Estadísticas principales en dos columnas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ProductStatsWidget(
                    stats: controller.stats!,
                    isCompact: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopProductsCard(context),
                      const SizedBox(height: 16),
                      _buildAlertsSection(context),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Acciones
            _buildActions(context),
            SizedBox(height: context.verticalSpacing),
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Cards de resumen
                _buildOverviewCards(context),
                const SizedBox(height: 24),

                // Estadísticas principales
                ProductStatsWidget(stats: controller.stats!, isCompact: false),
                const SizedBox(height: 24),

                // Gráficos adicionales
                _buildAdditionalCharts(context),
              ],
            ),
          ),
        ),

        // Panel lateral derecho
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                    Text(
                      'Panel de Control',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del panel
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTopProductsCard(context),
                      const SizedBox(height: 16),
                      _buildAlertsSection(context),
                      const SizedBox(height: 16),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStatCard(
                'Total',
                stats.total.toString(),
                Icons.inventory_2,
                Colors.blue,
                context,
              ),
              const SizedBox(width: 12),
              _buildMiniStatCard(
                'Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
                context,
              ),
              const SizedBox(width: 12),
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
        const SizedBox(width: 16),
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
        const SizedBox(width: 16),
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
        const SizedBox(width: 16),
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
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ADDITIONAL SECTIONS ====================

  Widget _buildTopProductsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Productos Destacados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.toNamed('/products'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProductListItem(
            'Producto más vendido',
            'No disponible',
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(height: 8),
          _buildProductListItem(
            'Mayor valor en stock',
            'No disponible',
            Icons.attach_money,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildProductListItem(
            'Último agregado',
            'No disponible',
            Icons.new_releases,
            Colors.blue,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notification_important, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Alertas y Notificaciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stock bajo
          if (stats.lowStock > 0)
            _buildAlertItem(
              'Stock Bajo',
              '${stats.lowStock} productos requieren reposición',
              Icons.warning,
              Colors.orange,
              () => controller.loadLowStockProducts(),
            ),

          // Sin stock
          if (stats.outOfStock > 0) ...[
            if (stats.lowStock > 0) const SizedBox(height: 8),
            _buildAlertItem(
              'Sin Stock',
              '${stats.outOfStock} productos agotados',
              Icons.error,
              Colors.red,
              () => controller.applyStockFilter(inStock: false),
            ),
          ],

          // Productos inactivos
          if (stats.inactive > 0) ...[
            if (stats.lowStock > 0 || stats.outOfStock > 0)
              const SizedBox(height: 8),
            _buildAlertItem(
              'Productos Inactivos',
              '${stats.inactive} productos desactivados',
              Icons.pause_circle,
              Colors.grey,
              () => controller.applyStatusFilter(ProductStatus.inactive),
            ),
          ],

          // Si no hay alertas
          if (stats.lowStock == 0 &&
              stats.outOfStock == 0 &&
              stats.inactive == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Todo está en orden. No hay alertas pendientes.',
                      style: TextStyle(
                        fontSize: 14,
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
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

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
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Agregar Producto',
                  icon: Icons.add,
                  onPressed: () => Get.toNamed('/products/create'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Stock Bajo',
                  icon: Icons.warning,
                  type: ButtonType.outline,
                  onPressed: controller.loadLowStockProducts,
                ),
              ),
              const SizedBox(width: 12),
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
      ),
    );
  }

  Widget _buildAdditionalCharts(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tendencias',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Gráfico de tendencias\n(Próximamente)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Análisis por Categoría',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Análisis por categorías\n(Próximamente)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Generar Reporte',
          icon: Icons.analytics,
          onPressed: () => _showReportOptions(context),
        ),
        const SizedBox(width: 16),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.verticalSpacing),
          Text(
            'No hay estadísticas disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'Agrega algunos productos para ver las estadísticas',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Agregar Primer Producto',
            icon: Icons.add,
            onPressed: () => Get.toNamed('/products/create'),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
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
