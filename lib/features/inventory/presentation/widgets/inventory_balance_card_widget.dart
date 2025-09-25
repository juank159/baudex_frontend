// lib/features/inventory/presentation/widgets/inventory_balance_card_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_balance.dart';

class InventoryBalanceCardWidget extends StatelessWidget {
  final InventoryBalance balance;

  const InventoryBalanceCardWidget({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 5),
      child: Padding(
        padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.productName,
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStockStatus(),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Stock info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.inventory_2,
                      label: 'Stock',
                      value: '${balance.totalQuantity}',
                      color: _getStockColor(),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.attach_money,
                      label: 'Valor Total',
                      value: AppFormatters.formatCurrency(balance.totalValue),
                      color: Get.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.trending_up,
                      label: 'Costo Promedio',
                      value: AppFormatters.formatCurrency(balance.averageCost),
                      color: Get.theme.colorScheme.secondary,
                    ),
                  ),
                  if (balance.categoryName != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.category,
                        label: 'Categoría',
                        value: balance.categoryName!,
                        color: Get.theme.colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
              
              // Warnings
              if (_hasWarnings()) ...[
                const SizedBox(height: 10),
                _buildWarnings(),
              ],
              
              // FIFO lots summary
              if (balance.fifoLots.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildFifoSummary(),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildStockStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (balance.isOutOfStock) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Sin stock';
    } else if (balance.isLowStock) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Stock bajo';
    } else if (balance.isOverStock) {
      statusColor = Colors.blue;
      statusIcon = Icons.info;
      statusText = 'Sobre stock';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 3),
          Text(
            statusText,
            style: Get.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasWarnings() {
    return balance.hasExpiredLots || balance.hasNearExpiryLots;
  }

  Widget _buildWarnings() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (balance.hasExpiredLots)
            Row(
              children: [
                const Icon(Icons.dangerous, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Productos vencidos: ${balance.expiredQuantity}',
                  style: Get.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],
            ),
          if (balance.hasNearExpiryLots)
            Row(
              children: [
                const Icon(Icons.warning, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Próximos a vencer: ${balance.nearExpiryQuantity}',
                  style: Get.textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFifoSummary() {
    final activeLots = balance.fifoLots.where((lot) => lot.quantity > 0).length;
    final oldestLot = balance.fifoLots.isNotEmpty ? balance.fifoLots.first : null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIFO - Lotes activos: $activeLots',
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Get.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (oldestLot != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lote más antiguo: ${AppFormatters.formatDate(oldestLot.entryDate)} - ${oldestLot.quantity} unidades',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStockColor() {
    if (balance.isOutOfStock) return Colors.red;
    if (balance.isLowStock) return Colors.orange;
    if (balance.isOverStock) return Colors.blue;
    return Colors.green;
  }
}