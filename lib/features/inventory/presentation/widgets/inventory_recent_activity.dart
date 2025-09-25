// lib/features/inventory/presentation/widgets/inventory_recent_activity.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../domain/entities/inventory_movement.dart';
import '../controllers/inventory_controller.dart';
import '../screens/inventory_dashboard_screen.dart';

class InventoryRecentActivity extends GetView<InventoryController> {
  const InventoryRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    const int maxItems = 4; // Mostrar solo 4 tarjetas para mejor balance
    
    return Container(
      height: 400, // Altura fija igual a quick actions
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.recentMovements.isEmpty) {
          return Container(
            height: 200,
            child: const Center(child: LoadingWidget()),
          );
        }

        if (controller.recentMovements.isEmpty) {
          return _buildEmptyState(isDesktop);
        }

        return Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lista de movimientos usando Expanded para distribución uniforme
              ...controller.recentMovements.take(maxItems).map((movement) =>
                Expanded(child: _buildMovementTile(movement, screenWidth))),
              
              // Botón para ver más si hay más movimientos (ajustado para desktop/tablet)
              if (controller.recentMovements.length > maxItems) ...[
                SizedBox(height: isDesktop ? 20 : 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: isDesktop ? 0.25 : 0.2),
                        blurRadius: isDesktop ? 8 : 6,
                        spreadRadius: isDesktop ? 2 : 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.toNamed('/inventory/movements'),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 14 : 10, // Mayor padding vertical para desktop/tablet
                          horizontal: isDesktop ? 16 : 12
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined, 
                              color: Colors.white, 
                              size: isDesktop ? 20 : 16
                            ),
                            SizedBox(width: isDesktop ? 10 : 8),
                            Text(
                              'Ver todos los movimientos',
                              style: Get.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : 6),
                            Icon(
                              Icons.arrow_forward_ios, 
                              color: Colors.white, 
                              size: isDesktop ? 16 : 14
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.timeline,
                size: isDesktop ? 48 : 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isDesktop ? 20 : 16),
            Text(
              'Sin actividad reciente',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay movimientos registrados recientemente',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(InventoryMovement movement, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMovementColor(movement).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed('/inventory/movements/detail/${movement.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono del tipo de movimiento
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: _getMovementGradient(movement),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getMovementColor(movement).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getMovementIcon(movement),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                
                const SizedBox(width: 12),
            
                // Detalles del movimiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Solo el nombre del producto
                      Text(
                        movement.productName,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: UnifiedTypography.getListItemTitleSize(screenWidth),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Información secundaria en una sola línea
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              movement.displayReason,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: UnifiedTypography.getListItemSubtitleSize(screenWidth),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Quantity tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getMovementColor(movement).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movement.displayQuantity,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: _getMovementColor(movement),
                                fontWeight: FontWeight.bold,
                                fontSize: UnifiedTypography.getQuantityTagSize(screenWidth),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMovementColor(InventoryMovement movement) {
    switch (movement.type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        return Colors.green;
      case InventoryMovementType.outbound:
      case InventoryMovementType.transferOut:
        return Colors.red;
      case InventoryMovementType.adjustment:
        return Colors.orange;
      case InventoryMovementType.transfer:
        return Colors.blue;
    }
  }

  IconData _getMovementIcon(InventoryMovement movement) {
    switch (movement.type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        return Icons.arrow_downward;
      case InventoryMovementType.outbound:
      case InventoryMovementType.transferOut:
        return Icons.arrow_upward;
      case InventoryMovementType.adjustment:
        return Icons.tune;
      case InventoryMovementType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getStatusColor(InventoryMovement movement) {
    switch (movement.status) {
      case InventoryMovementStatus.pending:
        return Colors.orange;
      case InventoryMovementStatus.confirmed:
        return Colors.green;
      case InventoryMovementStatus.cancelled:
        return Colors.red;
    }
  }

  LinearGradient _getMovementGradient(InventoryMovement movement) {
    switch (movement.type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        return ElegantLightTheme.successGradient;
      case InventoryMovementType.outbound:
      case InventoryMovementType.transferOut:
        return ElegantLightTheme.errorGradient;
      case InventoryMovementType.adjustment:
        return ElegantLightTheme.warningGradient;
      case InventoryMovementType.transfer:
        return ElegantLightTheme.infoGradient;
    }
  }

}