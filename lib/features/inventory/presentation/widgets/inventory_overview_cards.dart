// lib/features/inventory/presentation/widgets/inventory_overview_cards.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_controller.dart';
import '../screens/inventory_dashboard_screen.dart';

class InventoryOverviewCards extends GetView<InventoryController> {
  const InventoryOverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive grid configuration
    final screenWidth = MediaQuery.of(context).size.width;
    
    int getCrossAxisCount() {
      if (screenWidth >= 1200) return 4;
      if (screenWidth >= 600) return 2;
      return 2; // Mobile
    }

    double getChildAspectRatio() {
      if (screenWidth >= 1200) return 2.8; // AUMENTADO - cards más grandes para mejor legibilidad
      if (screenWidth >= 600) return 2.6; // También reducidas para tablet  
      return 1.6; // Mobile - mantener compacto
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: getCrossAxisCount(),
          crossAxisSpacing: screenWidth < 600 ? 8 : 12, // Reducido spacing para desktop
          mainAxisSpacing: screenWidth < 600 ? 8 : 12, // Reducido spacing para desktop
          childAspectRatio: getChildAspectRatio(),
          children: _buildOverviewCards(context),
        )),
      ],
    );
  }

  List<Widget> _buildOverviewCards(BuildContext context) {
    final stats = controller.inventoryStats.value;
    
    return [
      _buildOverviewCard(
        context: context,
        title: 'Total Productos',
        value: stats?.totalProducts.toString() ?? '0',
        subtitle: 'en inventario',
        icon: Icons.inventory_2,
        color: Colors.blue,
      ),
      _buildOverviewCard(
        context: context,
        title: 'Valor Total',
        value: AppFormatters.formatCurrency(stats?.totalValue ?? 0.0),
        subtitle: 'valoración actual',
        icon: Icons.monetization_on,
        color: Colors.green,
      ),
      _buildOverviewCard(
        context: context,
        title: 'Movimientos Hoy',
        value: stats?.movementsToday.toString() ?? '0',
        subtitle: 'entradas y salidas',
        icon: Icons.swap_horiz,
        color: Colors.orange,
      ),
      _buildOverviewCard(
        context: context,
        title: 'Alertas',
        value: ((stats?.lowStockCount ?? 0) + (stats?.expiredCount ?? 0)).toString(),
        subtitle: 'requieren atención',
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 8 : 10), // AUMENTADO: desktop 6→10 para mejor espacio
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : isTablet ? 5 : 4), // ULTRA REDUCIDO: tablet 7→5, desktop 6→4
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isMobile ? 16 : isTablet ? 14 : 16, // AUMENTADO: desktop 12→16 para mejor visibilidad
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 4), // ULTRA REDUCIDO: desktop/tablet 6→4
                  Expanded(
                    child: Text(
                      title,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: UnifiedTypography.getCardTitleSize(screenWidth), // Sistema unificado
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 6 : isTablet ? 4 : 6), // AUMENTADO: desktop 3→6 para mejor espacio
              Text(
                value,
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: UnifiedTypography.getCardValueSize(screenWidth),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : isTablet ? 2 : 3), // AUMENTADO: desktop 1→3 para mejor espacio
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: UnifiedTypography.getCardSubtitleSize(screenWidth),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

}