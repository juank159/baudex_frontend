// lib/features/products/presentation/widgets/product_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/product_stats.dart';

class ProductStatsWidget extends StatelessWidget {
  final ProductStats stats;
  final bool isCompact;

  const ProductStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactLayout(context);
    } else {
      return _buildFullLayout(context);
    }
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          children: [
            Text(
              'Resumen de Inventario',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 16,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            ResponsiveHelper.isMobile(context)
                ? _buildMobileStatsColumn(context)
                : _buildStatsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStatsColumn(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Total',
                stats.total.toString(),
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
            Expanded(
              child: _buildStatItem(
                context,
                'Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Stock Bajo',
                stats.lowStock.toString(),
                Icons.warning,
                Colors.orange,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
            Expanded(
              child: _buildStatItem(
                context,
                'Sin Stock',
                stats.outOfStock.toString(),
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            'Total',
            stats.total.toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        Container(width: 1, height: 40, color: Colors.grey.shade300),
        Expanded(
          child: _buildStatItem(
            context,
            'Activos',
            stats.active.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        Container(width: 1, height: 40, color: Colors.grey.shade300),
        Expanded(
          child: _buildStatItem(
            context,
            'Stock Bajo',
            stats.lowStock.toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        Container(width: 1, height: 40, color: Colors.grey.shade300),
        Expanded(
          child: _buildStatItem(
            context,
            'Sin Stock',
            stats.outOfStock.toString(),
            Icons.error,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas del Inventario',
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

        // Estadísticas generales
        _buildStatsGrid(context),

        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

        // Gráfico de estado del stock
        _buildStockChart(context),

        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

        // Información adicional
        _buildAdditionalInfo(context),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final inStock = stats.total - stats.lowStock - stats.outOfStock;

    final statsData = [
      _StatData(
        'Total de Productos',
        stats.total.toString(),
        Icons.inventory_2,
        Colors.blue,
      ),
      _StatData(
        'Productos Activos',
        stats.active.toString(),
        Icons.check_circle,
        Colors.green,
      ),
      _StatData(
        'Productos Inactivos',
        stats.inactive.toString(),
        Icons.cancel,
        Colors.grey,
      ),
      _StatData(
        'En Stock',
        inStock.toString(),
        Icons.check,
        Colors.green,
      ),
      _StatData(
        'Stock Bajo',
        stats.lowStock.toString(),
        Icons.warning,
        stats.lowStock > 0 ? Colors.orange : Colors.grey.shade400,
      ),
      _StatData(
        'Sin Stock',
        stats.outOfStock.toString(),
        Icons.error,
        stats.outOfStock > 0 ? Colors.red : Colors.grey.shade400,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3,
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.5,
        crossAxisSpacing: ResponsiveHelper.getHorizontalSpacing(context),
        mainAxisSpacing: ResponsiveHelper.getVerticalSpacing(context),
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return _buildStatCard(context, stat);
      },
    );
  }

  Widget _buildStatCard(BuildContext context, _StatData stat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat.icon,
                  color: stat.color,
                  size: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                stat.value,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 22,
                  ),
                  fontWeight: FontWeight.bold,
                  color: stat.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                stat.label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 9,
                    tablet: 10,
                    desktop: 11,
                  ),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(BuildContext context) {
    final inStock = stats.total - stats.lowStock - stats.outOfStock;
    final total = stats.total;

    if (total == 0) return const SizedBox.shrink();

    final inStockPercentage = (inStock / total * 100);
    final lowStockPercentage = (stats.lowStock / total * 100);
    final outOfStockPercentage = (stats.outOfStock / total * 100);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución del Stock',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

            // Barra de progreso visual
            Container(
              height: ResponsiveHelper.getHeight(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: Row(
                children: [
                  if (inStockPercentage > 0)
                    Expanded(
                      flex: inStock,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(10),
                            right: lowStockPercentage == 0 && outOfStockPercentage == 0
                                ? const Radius.circular(10)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                  if (lowStockPercentage > 0)
                    Expanded(
                      flex: stats.lowStock,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.horizontal(
                            right: outOfStockPercentage == 0
                                ? const Radius.circular(10)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                  if (outOfStockPercentage > 0)
                    Expanded(
                      flex: stats.outOfStock,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

            // Leyenda
            ResponsiveHelper.isMobile(context)
                ? _buildMobileLegend(inStockPercentage, lowStockPercentage, outOfStockPercentage)
                : _buildDesktopLegend(inStockPercentage, lowStockPercentage, outOfStockPercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLegend(double inStockPercentage, double lowStockPercentage, double outOfStockPercentage) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                'En Stock',
                Colors.green,
                '${inStockPercentage.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLegendItem(
                'Stock Bajo',
                Colors.orange,
                '${lowStockPercentage.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Sin Stock',
          Colors.red,
          '${outOfStockPercentage.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildDesktopLegend(double inStockPercentage, double lowStockPercentage, double outOfStockPercentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          'En Stock',
          Colors.green,
          '${inStockPercentage.toStringAsFixed(1)}%',
        ),
        _buildLegendItem(
          'Stock Bajo',
          Colors.orange,
          '${lowStockPercentage.toStringAsFixed(1)}%',
        ),
        _buildLegendItem(
          'Sin Stock',
          Colors.red,
          '${outOfStockPercentage.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($percentage)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            _buildInfoRow('Valor Total del Inventario', 'Calculando...'),
            _buildInfoRow('Productos Más Vendidos', 'Ver detalles'),
            _buildInfoRow('Última Actualización', 'Hace 5 minutos'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: ResponsiveHelper.getFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
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
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatData(this.label, this.value, this.icon, this.color);
}