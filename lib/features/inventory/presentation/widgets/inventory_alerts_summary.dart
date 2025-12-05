// lib/features/inventory/presentation/widgets/inventory_alerts_summary.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';

class InventoryAlertsSummary extends GetView<InventoryController> {
  const InventoryAlertsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final alerts = [
        {
          'title': 'Stock Bajo',
          'count': controller.lowStockProducts.length,
          'color': Colors.orange,
          'icon': Icons.warning,
          'action':
              () => Get.toNamed(
                '/inventory/balances',
                arguments: {'filter': 'low_stock'},
              ),
        },
        {
          'title': 'Sin Stock',
          'count': controller.outOfStockProducts.length,
          'color': Colors.red,
          'icon': Icons.error,
          'action':
              () => Get.toNamed(
                '/inventory/balances',
                arguments: {'filter': 'out_of_stock'},
              ),
        },
        {
          'title': 'Por Vencer',
          'count': controller.nearExpiryProducts.length,
          'color': Colors.amber,
          'icon': Icons.schedule,
          'action':
              () => Get.toNamed(
                '/inventory/balances',
                arguments: {'filter': 'near_expiry'},
              ),
        },
        {
          'title': 'Vencidos',
          'count': controller.expiredProducts.length,
          'color': Colors.red.shade800,
          'icon': Icons.dangerous,
          'action':
              () => Get.toNamed(
                '/inventory/balances',
                arguments: {'filter': 'expired'},
              ),
        },
      ];

      final totalAlerts = alerts.fold<int>(
        0,
        (sum, alert) => sum + (alert['count'] as int),
      );

      if (totalAlerts == 0) {
        return Container(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MediaQuery.of(context).size.width < 600
                          ? 'Todo en orden'
                          : 'Todo está en orden',
                      style: (MediaQuery.of(context).size.width < 600
                              ? Get.textTheme.titleSmall
                              : Get.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                    ),
                    if (MediaQuery.of(context).size.width >= 600) ...[
                      const SizedBox(height: 4),
                      Text(
                        'No hay alertas de inventario pendientes.',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600 ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: Colors.red.shade700,
                    size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MediaQuery.of(context).size.width < 600
                            ? 'Alertas'
                            : 'Alertas de Inventario',
                        style: (MediaQuery.of(context).size.width < 600
                                ? Get.textTheme.titleSmall
                                : Get.textTheme.titleMedium)
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                      ),
                      if (MediaQuery.of(context).size.width >= 600) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$totalAlerts ${totalAlerts == 1 ? 'producto requiere' : 'productos requieren'} atención inmediata.',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 12 : 16),
            _buildAlertButtons(context, alerts),
          ],
        ),
      );
    });
  }

  Widget _buildAlertButtons(
    BuildContext context,
    List<Map<String, dynamic>> alerts,
  ) {
    final alertsWithCounts =
        alerts.where((alert) => (alert['count'] as int) > 0).toList();

    if (MediaQuery.of(context).size.width < 600) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.0,
        ),
        itemCount: alertsWithCounts.length,
        itemBuilder: (context, index) {
          final alert = alertsWithCounts[index];
          return _buildAlertButton(
            context: context,
            title: alert['title'] as String,
            count: alert['count'] as int,
            color: alert['color'] as Color,
            icon: alert['icon'] as IconData,
            onTap: alert['action'] as VoidCallback,
          );
        },
      );
    } else {
      return Row(
        children:
            alertsWithCounts.map((alert) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildAlertButton(
                    context: context,
                    title: alert['title'] as String,
                    count: alert['count'] as int,
                    color: alert['color'] as Color,
                    icon: alert['icon'] as IconData,
                    onTap: alert['action'] as VoidCallback,
                  ),
                ),
              );
            }).toList(),
      );
    }
  }

  Widget _buildAlertButton({
    required BuildContext context,
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 8 : 12,
          horizontal: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isMobile ? 18 : 20),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              '$count',
              style: (isMobile
                      ? Get.textTheme.titleSmall
                      : Get.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: isMobile ? 1 : 2),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
