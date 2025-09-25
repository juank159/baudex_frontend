// lib/features/inventory/presentation/widgets/kardex_entries_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/kardex_report.dart';
import '../controllers/kardex_controller.dart';

class KardexEntriesList extends GetView<KardexController> {
  const KardexEntriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    
    return Obx(() {
      if (!controller.hasEntries) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Sin entradas de kardex', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('No se encontraron movimientos en el período seleccionado.', textAlign: TextAlign.center),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.all(isLargeScreen ? 16 : 16),
        itemCount: controller.kardexEntries.length,
        separatorBuilder: (context, index) => SizedBox(height: isLargeScreen ? 4 : 8),
        itemBuilder: (context, index) {
          final movement = controller.kardexEntries[index];
          return _buildKardexEntryCard(movement, isLargeScreen: isLargeScreen);
        },
      );
    });
  }

  Widget _buildKardexEntryCard(KardexMovement movement, {required bool isLargeScreen}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => controller.goToMovementDetail(movement.movementNumber),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: controller.getMovementColor(movement).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with date and document - más compacto
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: controller.getMovementColor(movement).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        controller.getMovementIcon(movement),
                        color: controller.getMovementColor(movement),
                        size: isLargeScreen ? 14 : 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.formatDate(movement.date),
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isLargeScreen ? 13 : 14,
                            ),
                          ),
                          Text(
                            '${movement.displayType} - ${movement.referenceNumber ?? movement.movementNumber}',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isLargeScreen ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 6 : 8,
                        vertical: isLargeScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: controller.getMovementColor(movement).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        movement.displayType,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: controller.getMovementColor(movement),
                          fontWeight: FontWeight.w600,
                          fontSize: isLargeScreen ? 10 : 11,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isLargeScreen ? 6 : 12),

                // Description - más compacto
                Text(
                  movement.description,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontSize: isLargeScreen ? 12 : 13,
                  ),
                  maxLines: isLargeScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: isLargeScreen ? 6 : 12),

              // Quantities and costs - layout responsivo
              isLargeScreen 
                ? Row(
                    children: [
                      _buildDataColumn(
                        label: 'Cant.',
                        value: movement.isEntry 
                          ? '+${movement.entryQuantity.toInt()}'
                          : '-${movement.exitQuantity.toInt()}',
                        color: controller.getMovementColor(movement),
                        isCompact: true,
                      ),
                      const SizedBox(width: 12),
                      _buildDataColumn(
                        label: 'C. Unit.',
                        value: controller.formatCurrency(movement.unitCost),
                        isCompact: true,
                      ),
                      const SizedBox(width: 12),
                      _buildDataColumn(
                        label: 'Valor Mov.',
                        value: controller.formatCurrency(
                          movement.isEntry 
                            ? movement.entryCost 
                            : movement.exitCost
                        ),
                        color: movement.isEntry ? Colors.green : Colors.red,
                        isCompact: true,
                      ),
                      const SizedBox(width: 12),
                      _buildDataColumn(
                        label: 'Saldo',
                        value: '${movement.balance.toInt()}',
                        alignment: CrossAxisAlignment.end,
                        isBold: true,
                        isCompact: true,
                      ),
                      const SizedBox(width: 12),
                      _buildDataColumn(
                        label: 'Valor Saldo',
                        value: controller.formatCurrency(movement.balanceValue),
                        alignment: CrossAxisAlignment.end,
                        color: AppColors.primary,
                        isBold: true,
                        isCompact: true,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          _buildDataColumn(
                            label: 'Cantidad',
                            value: movement.isEntry 
                              ? '+${movement.entryQuantity.toInt()}'
                              : '-${movement.exitQuantity.toInt()}',
                            color: controller.getMovementColor(movement),
                          ),
                          _buildDataColumn(
                            label: 'Costo Unitario',
                            value: controller.formatCurrency(movement.unitCost),
                          ),
                          _buildDataColumn(
                            label: 'Saldo',
                            value: '${movement.balance.toInt()}',
                            alignment: CrossAxisAlignment.end,
                            isBold: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Valor del movimiento y saldo
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: movement.isEntry 
                                  ? Colors.green.withOpacity(0.1) 
                                  : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor Movimiento:',
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.formatCurrency(
                                      movement.isEntry 
                                        ? movement.entryCost 
                                        : movement.exitCost
                                    ),
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: movement.isEntry ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor Saldo:',
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.formatCurrency(movement.balanceValue),
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // Notes if available - solo en mobile
                if (!isLargeScreen && movement.notes?.isNotEmpty == true) ...[
                  SizedBox(height: isLargeScreen ? 6 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 6 : 8,
                      vertical: isLargeScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.note,
                          size: isLargeScreen ? 12 : 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            movement.notes!,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: isLargeScreen ? 10 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn({
    required String label,
    required String value,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
    Color? color,
    bool isBold = false,
    bool isCompact = false,
  }) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
          SizedBox(height: isCompact ? 1 : 2),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}