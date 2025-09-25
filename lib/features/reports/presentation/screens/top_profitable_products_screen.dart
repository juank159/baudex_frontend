// lib/features/reports/presentation/screens/top_profitable_products_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/date_range_picker_widget.dart';

class TopProfitableProductsScreen extends GetView<ReportsController> {
  const TopProfitableProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlsSection(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProfitability.value) {
                return const LoadingWidget(message: 'Cargando productos más rentables...');
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.topProfitableProducts.isEmpty) {
                return _buildEmptyState();
              }

              return _buildContentSection();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Configuración de Ranking',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => DateRangePickerWidget(
                  startDate: controller.startDate.value,
                  endDate: controller.endDate.value,
                  onDateRangeChanged: controller.setDateRange,
                  label: 'Período de Análisis',
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLimitDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSortByDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitDropdown() {
    return Obx(() => DropdownButtonFormField<int>(
      value: controller.topProductsLimit.value,
      decoration: const InputDecoration(
        labelText: 'Cantidad de Productos',
        prefixIcon: Icon(Icons.format_list_numbered),
        border: OutlineInputBorder(),
      ),
      items: [5, 10, 15, 20, 25, 50].map((limit) {
        return DropdownMenuItem<int>(
          value: limit,
          child: Text('Top $limit'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.setTopProductsLimit(value);
        }
      },
    ));
  }

  Widget _buildSortByDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.profitabilitySortBy.value,
      decoration: const InputDecoration(
        labelText: 'Ordenar por',
        prefixIcon: Icon(Icons.sort),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: 'grossProfit',
          child: Text('Ganancia Bruta'),
        ),
        const DropdownMenuItem(
          value: 'profitMargin',
          child: Text('Margen %'),
        ),
        const DropdownMenuItem(
          value: 'totalRevenue',
          child: Text('Ingresos'),
        ),
        const DropdownMenuItem(
          value: 'rotationRate',
          child: Text('Rotación'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          controller.setProfitabilitySortBy(value);
        }
      },
    ));
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderStats(),
          const SizedBox(height: 24),
          _buildRankingList(),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Obx(() {
      final products = controller.topProfitableProducts;
      final totalProfit = products.fold(0.0, (sum, p) => sum + p.grossProfit);
      final avgMargin = products.isNotEmpty 
          ? products.fold(0.0, (sum, p) => sum + p.profitMargin) / products.length
          : 0.0;
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events,
                size: 32,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top ${products.length} Productos Más Rentables',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ganancia Total: ${controller.formatCurrency(totalProfit)}',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.amber.shade600,
                    ),
                  ),
                  Text(
                    'Margen Promedio: ${avgMargin.toStringAsFixed(1)}%',
                    style: Get.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRankingList() {
    return Obx(() {
      final products = controller.topProfitableProducts;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranking de Rentabilidad',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final rank = index + 1;
              final medal = _getMedalIcon(rank);
              final isPositive = product.profitMargin > 0;
              final marginColor = isPositive ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: rank <= 3 ? 4 : 2,
                child: Container(
                  decoration: rank <= 3 
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              _getRankColor(rank).withOpacity(0.1),
                              _getRankColor(rank).withOpacity(0.05),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Ranking number/medal
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getRankColor(rank).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: _getRankColor(rank).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: rank <= 3
                                ? Icon(medal, color: _getRankColor(rank), size: 24)
                                : Text(
                                    '$rank',
                                    style: Get.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getRankColor(rank),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Product info
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'SKU: ${product.productSku}',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (product.categoryName != null)
                                Text(
                                  product.categoryName!,
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Metrics
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                controller.formatCurrency(product.grossProfit),
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: marginColor,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    size: 16,
                                    color: marginColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.profitMargin.toStringAsFixed(1)}%',
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      color: marginColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${product.quantitySold} vendidas',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action button
                        IconButton(
                          onPressed: () => _showProductDetails(product),
                          icon: const Icon(Icons.visibility),
                          tooltip: 'Ver detalles',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  IconData _getMedalIcon(int rank) {
    switch (rank) {
      case 1: return Icons.emoji_events; // Gold
      case 2: return Icons.emoji_events; // Silver  
      case 3: return Icons.emoji_events; // Bronze
      default: return Icons.star;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber; // Gold
      case 2: return Colors.grey; // Silver
      case 3: return Colors.brown; // Bronze
      default: return AppColors.primary;
    }
  }

  void _showProductDetails(product) {
    Get.dialog(
      AlertDialog(
        title: Text('Detalles de ${product.productName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SKU', product.productSku),
              _buildDetailRow('Categoría', product.categoryName ?? 'Sin categoría'),
              const Divider(),
              _buildDetailRow('Ingresos Totales', controller.formatCurrency(product.totalRevenue)),
              _buildDetailRow('Costos Totales', controller.formatCurrency(product.totalCost)),
              _buildDetailRow('Ganancia Bruta', controller.formatCurrency(product.grossProfit)),
              _buildDetailRow('Margen %', '${product.profitMargin.toStringAsFixed(2)}%'),
              const Divider(),
              _buildDetailRow('Unidades Vendidas', product.quantitySold.toString()),
              _buildDetailRow('Precio Promedio', controller.formatCurrency(product.averageSellingPrice)),
              _buildDetailRow('Rotación', '${product.rotationRate.toStringAsFixed(2)}x'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Get.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar los datos',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshProfitabilityReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos rentables',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar Filtros'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Top Productos Rentables'),
      actions: [
        IconButton(
          onPressed: controller.exportProfitabilityReport,
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar',
        ),
        IconButton(
          onPressed: controller.refreshProfitabilityReports,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}