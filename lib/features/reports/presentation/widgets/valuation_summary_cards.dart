// lib/features/reports/presentation/widgets/valuation_summary_cards.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_valuation_report.dart';

class ValuationSummaryCards extends StatelessWidget {
  final InventoryValuationSummary summary;

  const ValuationSummaryCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen Ejecutivo',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Main metrics row
        Row(
          children: [
            Expanded(
              child: _buildMainCard(
                title: 'Valor Total',
                value: AppFormatters.formatCurrency(summary.totalInventoryValue),
                subtitle: 'Inventario completo',
                icon: Icons.account_balance_wallet,
                color: AppColors.primary,
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMainCard(
                title: 'Productos',
                value: summary.totalProducts.toString(),
                subtitle: 'Referencias únicas',
                icon: Icons.inventory_2,
                color: Colors.blue,
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMainCard(
                title: 'Unidades',
                value: summary.totalQuantity.toStringAsFixed(0),
                subtitle: 'Total en stock',
                icon: Icons.format_list_numbered,
                color: Colors.green,
                trend: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMainCard(
                title: 'Costo Promedio',
                value: AppFormatters.formatCurrency(summary.averageCostPerUnit),
                subtitle: 'Por unidad',
                icon: Icons.attach_money,
                color: Colors.orange,
                trend: null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Additional metrics if available
        if (summary.categorySummaries.isNotEmpty)
          _buildCategoryMetrics(),

        if (summary.warehouseBreakdown.isNotEmpty)
          const SizedBox(height: 16),

        if (summary.warehouseBreakdown.isNotEmpty)
          _buildWarehouseMetrics(),
      ],
    );
  }

  Widget _buildMainCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMetrics() {
    final categories = summary.categorySummaries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valoración por Categorías',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Categoría',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Productos',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Valor Total',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '% Total',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category rows
                ...categories.take(5).map((category) => _buildCategoryRow(category, summary.totalInventoryValue)),
                
                if (categories.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () => _showAllCategories(categories, summary.totalInventoryValue),
                      child: Text('Ver todas (${categories.length})'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(CategoryValuationSummary category, double totalInventoryValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category.categoryId),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: Get.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              category.productCount.toString(),
              style: Get.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppFormatters.formatCurrency(category.totalValue),
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '${(totalInventoryValue > 0 ? (category.totalValue / totalInventoryValue) * 100 : 0).toStringAsFixed(1)}%',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseMetrics() {
    final warehouses = summary.warehouseBreakdown;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valoración por Almacenes',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: warehouses.take(4).map((warehouse) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildWarehouseCard(warehouse),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWarehouseCard(WarehouseValuationBreakdown warehouse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warehouse,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warehouse.warehouseName,
                    style: Get.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppFormatters.formatCurrency(warehouse.totalValue),
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${warehouse.productCount} productos',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${warehouse.percentageOfTotalValue.toStringAsFixed(1)}% del total',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[categoryId.hashCode % colors.length];
  }

  void _showAllCategories(List<CategoryValuationSummary> categories, double totalInventoryValue) {
    Get.dialog(
      AlertDialog(
        title: const Text('Todas las Categorías'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category.categoryId),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                title: Text(category.categoryName),
                subtitle: Text('${category.productCount} productos'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(category.totalValue),
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(totalInventoryValue > 0 ? (category.totalValue / totalInventoryValue) * 100 : 0).toStringAsFixed(1)}%',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
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
}