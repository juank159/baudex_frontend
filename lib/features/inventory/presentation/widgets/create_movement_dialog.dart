// lib/features/inventory/presentation/widgets/create_movement_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/keyboard_safe_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/inventory_movements_controller.dart';
import '../../domain/entities/inventory_movement.dart';
import 'product_search_widget.dart';

class CreateMovementDialog extends GetView<InventoryMovementsController> {
  const CreateMovementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_box, color: AppColors.primary),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    'Crear Movimiento de Inventario',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product selector
                    _buildProductSelector(),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Type and reason
                    _buildTypeAndReason(),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Quantity and cost (conditional)
                    _buildQuantityAndCost(),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // FIFO Preview (for outbound movements)
                    _buildFifoPreview(),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Notes
                    CustomTextField(
                      controller: controller.notesController,
                      label: 'Notas (Opcional)',
                      hint: 'Información adicional sobre el movimiento...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    onPressed: () => Get.back(),
                    type: ButtonType.outline,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Obx(
                    () => CustomButton(
                      text: 'Crear Movimiento',
                      onPressed:
                          controller.isFormValid
                              ? controller.createMovement
                              : null,
                      isLoading: controller.isCreating.value,
                      icon: Icons.add,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Producto *',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        ProductSearchWidget(
          hintText: 'Buscar producto por nombre o SKU...',
          onProductSelected: controller.selectProduct,
          searchFunction: controller.searchProducts,
        ),
        Obx(() {
          if (controller.selectedProductName.value.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: AppDimensions.paddingSmall),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    controller.selectedProductName.value,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTypeAndReason() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipo *',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Obx(
                () => DropdownButtonFormField<InventoryMovementType>(
                  value: controller.selectedType.value,
                  isExpanded: true, // Prevent overflow
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                  ),
                  items:
                      InventoryMovementType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min, // Prevent row from taking too much space
                            children: [
                              Icon(
                                _getTypeIcon(type),
                                size: 16,
                                color: _getTypeColor(type),
                              ),
                              const SizedBox(width: AppDimensions.paddingSmall),
                              Flexible(
                                child: Text(
                                  type.displayType,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // Prevent text overflow
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (type) {
                    if (type != null) {
                      controller.selectedType.value = type;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Razón *',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Obx(
                () => DropdownButtonFormField<InventoryMovementReason>(
                  value: controller.selectedReason.value,
                  isExpanded: true, // Prevent overflow
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                  ),
                  items:
                      InventoryMovementReason.values.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(
                            reason.displayReason,
                            overflow:
                                TextOverflow.ellipsis, // Prevent text overflow
                          ),
                        );
                      }).toList(),
                  onChanged: (reason) {
                    if (reason != null) {
                      controller.selectedReason.value = reason;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAndCost() {
    return Obx(() {
      final shouldShowUnitCost = _shouldShowUnitCost();

      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cantidad *',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                KeyboardSafeTextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    hintText: 'Cantidad',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    controller.quantity.value = int.tryParse(value) ?? 1;
                  },
                  initialValue: controller.quantity.value.toString(),
                ),
              ],
            ),
          ),
          if (shouldShowUnitCost) ...[
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getUnitCostLabel(),
                    style: Get.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  KeyboardSafeTextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      hintText: _getUnitCostHint(),
                      prefixIcon: const Icon(Icons.attach_money),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingSmall,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      controller.unitCost.value = double.tryParse(value) ?? 0.0;
                    },
                    initialValue:
                        controller.unitCost.value > 0
                            ? controller.unitCost.value.toString()
                            : '',
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  // Determine if unit cost field should be shown based on movement type and reason
  bool _shouldShowUnitCost() {
    final type = controller.selectedType.value;
    final reason = controller.selectedReason.value;

    switch (type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        // For inbound movements, show cost for purchases and some adjustments
        return reason == InventoryMovementReason.purchase ||
            reason == InventoryMovementReason.return_ ||
            reason == InventoryMovementReason.adjustment;

      case InventoryMovementType.adjustment:
        // For adjustments, only show cost for positive adjustments (increases)
        return true; // Let user decide if they want to set a cost

      case InventoryMovementType.outbound:
      case InventoryMovementType.transfer:
      case InventoryMovementType.transferOut:
        // For outbound and transfers, generally don't need unit cost
        return false;
    }
  }

  // Get appropriate label for unit cost field
  String _getUnitCostLabel() {
    final type = controller.selectedType.value;
    final reason = controller.selectedReason.value;

    if ((type == InventoryMovementType.inbound ||
            type == InventoryMovementType.transferIn) &&
        reason == InventoryMovementReason.purchase) {
      return 'Costo de Compra *';
    }

    return 'Costo Unitario';
  }

  // Get appropriate hint for unit cost field
  String _getUnitCostHint() {
    final type = controller.selectedType.value;
    final reason = controller.selectedReason.value;

    if ((type == InventoryMovementType.inbound ||
            type == InventoryMovementType.transferIn) &&
        reason == InventoryMovementReason.purchase) {
      return 'Precio pagado por unidad';
    }

    return 'Costo por unidad';
  }

  IconData _getTypeIcon(InventoryMovementType type) {
    switch (type) {
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

  Color _getTypeColor(InventoryMovementType type) {
    switch (type) {
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

  Widget _buildFifoPreview() {
    return Obx(() {
      if (!controller.shouldShowFifoButton) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa FIFO',
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proceso FIFO disponible',
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Ver cómo se consumen los lotes',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: CustomButton(
                  text: 'Ver FIFO',
                  onPressed: controller.showFifoPreviewDialog,
                  type: ButtonType.outline,
                  icon: Icons.visibility,
                  isLoading: controller.isCalculatingFifo.value,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
