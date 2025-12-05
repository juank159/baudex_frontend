// lib/features/inventory/presentation/widgets/inventory_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/inventory_stats.dart';

class InventoryStatsWidget extends StatelessWidget {
  final InventoryStats stats;

  const InventoryStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // General stats
        _buildGeneralStats(),

        const SizedBox(height: 24),

        // Movement stats
        _buildMovementStats(),
      ],
    );
  }

  Widget _buildGeneralStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Resumen General de Inventario',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(stats.inventoryStatus),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.inventory_2,
                  title: 'Total Productos',
                  value: '${stats.totalProducts}',
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  icon: Icons.batch_prediction,
                  title: 'Total Lotes',
                  value: '${stats.totalBatches}',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Icons.swap_vert,
                  title: 'Total Movimientos',
                  value: '${stats.totalMovements}',
                  color: Colors.blue,
                ),
                _buildStatCard(
                  icon: Icons.attach_money,
                  title: 'Valor Total',
                  value: AppFormatters.formatCurrency(stats.totalValue),
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementStats() {
    if (stats.movementsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Movimientos por Tipo',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Movement types
            ...stats.movementsByType.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getMovementTypeColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getMovementTypeName(entry.key),
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMovementTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PURCHASE':
        return Colors.green;
      case 'SALE':
        return Colors.red;
      case 'ADJUSTMENT':
        return Colors.orange;
      case 'TRANSFER':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getMovementTypeName(String type) {
    switch (type.toUpperCase()) {
      case 'PURCHASE':
        return 'Compras';
      case 'SALE':
        return 'Ventas';
      case 'ADJUSTMENT':
        return 'Ajustes';
      case 'TRANSFER':
        return 'Transferencias';
      default:
        return type;
    }
  }
}
