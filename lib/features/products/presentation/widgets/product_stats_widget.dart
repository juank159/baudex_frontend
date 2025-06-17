// lib/features/products/presentation/widgets/product_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumen de Inventario',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas del Inventario',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Estadísticas generales
        _buildStatsGrid(context),

        const SizedBox(height: 16),

        // Gráfico de estado del stock
        _buildStockChart(context),

        const SizedBox(height: 16),

        // Información adicional
        _buildAdditionalInfo(context),
      ],
    );
  }

  // Widget _buildStatsGrid(BuildContext context) {
  //   final statsData = [
  //     _StatData(
  //       'Total de Productos',
  //       stats.total.toString(),
  //       Icons.inventory_2,
  //       Colors.blue,
  //     ),
  //     _StatData(
  //       'Productos Activos',
  //       stats.active.toString(),
  //       Icons.check_circle,
  //       Colors.green,
  //     ),
  //     _StatData(
  //       'Productos Inactivos',
  //       stats.inactive.toString(),
  //       Icons.cancel,
  //       Colors.grey,
  //     ),
  //     _StatData(
  //       'En Stock',
  //       stats.inStock.toString(),
  //       Icons.check,
  //       Colors.green,
  //     ),
  //     _StatData(
  //       'Stock Bajo',
  //       stats.lowStock.toString(),
  //       Icons.warning,
  //       Colors.orange,
  //     ),
  //     _StatData(
  //       'Sin Stock',
  //       stats.outOfStock.toString(),
  //       Icons.error,
  //       Colors.red,
  //     ),
  //   ];

  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: context.isMobile ? 2 : 3,
  //       childAspectRatio: context.isMobile ? 1.2 : 1.5,
  //       crossAxisSpacing: 12,
  //       mainAxisSpacing: 12,
  //     ),
  //     itemCount: statsData.length,
  //     itemBuilder: (context, index) {
  //       final stat = statsData[index];
  //       return _buildStatCard(context, stat);
  //     },
  //   );
  // }

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
        inStock.toString(), // ✅ CORREGIDO: Usar cálculo correcto
        Icons.check,
        Colors.green,
      ),
      _StatData(
        'Stock Bajo',
        stats.lowStock.toString(),
        Icons.warning,
        stats.lowStock > 0
            ? Colors.orange
            : Colors.grey.shade400, // ✅ Color dinámico
      ),
      _StatData(
        'Sin Stock',
        stats.outOfStock.toString(),
        Icons.error,
        stats.outOfStock > 0
            ? Colors.red
            : Colors.grey.shade400, // ✅ Color dinámico
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        childAspectRatio: context.isMobile ? 1.2 : 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stat.icon, color: stat.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStockChart(BuildContext context) {
  //   final total = stats.inStock + stats.lowStock + stats.outOfStock;
  //   if (total == 0) return const SizedBox.shrink();

  //   final inStockPercentage = (stats.inStock / total * 100);
  //   final lowStockPercentage = (stats.lowStock / total * 100);
  //   final outOfStockPercentage = (stats.outOfStock / total * 100);

  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Distribución del Stock',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.grey.shade800,
  //             ),
  //           ),
  //           const SizedBox(height: 16),

  //           // Barra de progreso visual
  //           Container(
  //             height: 20,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(10),
  //               color: Colors.grey.shade200,
  //             ),
  //             child: Row(
  //               children: [
  //                 if (inStockPercentage > 0)
  //                   Expanded(
  //                     flex: stats.inStock,
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: Colors.green,
  //                         borderRadius: BorderRadius.horizontal(
  //                           left: const Radius.circular(10),
  //                           right:
  //                               lowStockPercentage == 0 &&
  //                                       outOfStockPercentage == 0
  //                                   ? const Radius.circular(10)
  //                                   : Radius.zero,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 if (lowStockPercentage > 0)
  //                   Expanded(
  //                     flex: stats.lowStock,
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: Colors.orange,
  //                         borderRadius: BorderRadius.horizontal(
  //                           right:
  //                               outOfStockPercentage == 0
  //                                   ? const Radius.circular(10)
  //                                   : Radius.zero,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 if (outOfStockPercentage > 0)
  //                   Expanded(
  //                     flex: stats.outOfStock,
  //                     child: Container(
  //                       decoration: const BoxDecoration(
  //                         color: Colors.red,
  //                         borderRadius: BorderRadius.horizontal(
  //                           right: Radius.circular(10),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),

  //           const SizedBox(height: 12),

  //           // Leyenda
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _buildLegendItem(
  //                 'En Stock',
  //                 Colors.green,
  //                 '${inStockPercentage.toStringAsFixed(1)}%',
  //               ),
  //               _buildLegendItem(
  //                 'Stock Bajo',
  //                 Colors.orange,
  //                 '${lowStockPercentage.toStringAsFixed(1)}%',
  //               ),
  //               _buildLegendItem(
  //                 'Sin Stock',
  //                 Colors.red,
  //                 '${outOfStockPercentage.toStringAsFixed(1)}%',
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStockChart(BuildContext context) {
    // ✅ CORRECCIÓN: Calcular inStock correctamente
    final inStock = stats.total - stats.lowStock - stats.outOfStock;
    final total = stats.total;

    if (total == 0) return const SizedBox.shrink();

    final inStockPercentage = (inStock / total * 100);
    final lowStockPercentage = (stats.lowStock / total * 100);
    final outOfStockPercentage = (stats.outOfStock / total * 100);

    // ✅ AÑADIDO: Debug para verificar cálculos
    print(
      '📊 StockChart - Total: $total, InStock: $inStock, LowStock: ${stats.lowStock}, OutOfStock: ${stats.outOfStock}',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución del Stock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ MEJORADO: Solo mostrar barra si hay productos
            if (total > 0) ...[
              // Barra de progreso visual
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: Row(
                  children: [
                    if (inStock > 0)
                      Expanded(
                        flex: inStock,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.horizontal(
                              left: const Radius.circular(10),
                              right:
                                  stats.lowStock == 0 && stats.outOfStock == 0
                                      ? const Radius.circular(10)
                                      : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                    if (stats.lowStock > 0)
                      Expanded(
                        flex: stats.lowStock,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.horizontal(
                              right:
                                  stats.outOfStock == 0
                                      ? const Radius.circular(10)
                                      : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                    if (stats.outOfStock > 0)
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

              const SizedBox(height: 12),

              // Leyenda con valores absolutos y porcentajes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    'En Stock ($inStock)',
                    Colors.green,
                    '${inStockPercentage.toStringAsFixed(1)}%',
                  ),
                  _buildLegendItem(
                    'Stock Bajo (${stats.lowStock})',
                    Colors.orange,
                    '${lowStockPercentage.toStringAsFixed(1)}%',
                  ),
                  _buildLegendItem(
                    'Sin Stock (${stats.outOfStock})',
                    Colors.red,
                    '${outOfStockPercentage.toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ] else ...[
              // ✅ AÑADIDO: Estado cuando no hay productos
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay productos registrados',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Financiera',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem(
                    'Valor Total del Inventario',
                    '\$${stats.totalValue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialItem(
                    'Precio Promedio',
                    '\$${stats.averagePrice.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
