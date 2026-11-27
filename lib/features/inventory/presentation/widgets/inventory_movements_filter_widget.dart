// lib/features/inventory/presentation/widgets/inventory_movements_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/inventory_movements_controller.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class InventoryMovementsFilterWidget extends GetView<InventoryMovementsController> {
  const InventoryMovementsFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with active filters count
            _buildFilterHeader(),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Filter sections - Stack vertically on small screens
            Column(
              children: [
                _buildTypeFilter(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildStatusFilter(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildDateRangeFilter(),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            Icons.tune,
            color: ElegantLightTheme.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar Movimientos',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Obx(() {
                final activeFilters = controller.activeFiltersCount;
                if (activeFilters['count'] > 0) {
                  return Text(
                    '${activeFilters['count']} filtros aplicados',
                    style: TextStyle(
                      color: ElegantLightTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return Text(
                  'Personaliza tu búsqueda',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                size: 18,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Tipo de Movimiento',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InventoryMovementType.values.map((type) {
              final isSelected = controller.typeFilter.value == type;
              return FilterChip(
                label: Text(
                  type.displayType,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: ElegantLightTheme.primaryBlue,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textTertiary.withOpacity(0.3),
                ),
                onSelected: (selected) {
                  controller.typeFilter.value = selected ? type : null;
                },
              );
            }).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Estado',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InventoryMovementStatus.values.map((status) {
              final isSelected = controller.statusFilter.value == status;
              return FilterChip(
                label: Text(
                  status.displayStatus,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: ElegantLightTheme.primaryBlue,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textTertiary.withOpacity(0.3),
                ),
                onSelected: (selected) {
                  controller.statusFilter.value = selected ? status : null;
                },
              );
            }).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 18,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Rango de Fechas',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Fecha inicial
          InkWell(
            onTap: () => _selectStartDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Obx(() => Text(
                      controller.startDateFilter.value != null
                          ? controller.formatDate(controller.startDateFilter.value!)
                          : 'Fecha inicial',
                      style: TextStyle(
                        color: controller.startDateFilter.value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: controller.startDateFilter.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingSmall),
          
          // Fecha final
          InkWell(
            onTap: () => _selectEndDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Obx(() => Text(
                      controller.endDateFilter.value != null
                          ? controller.formatDate(controller.endDateFilter.value!)
                          : 'Fecha final',
                      style: TextStyle(
                        color: controller.endDateFilter.value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: controller.endDateFilter.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Obx(() {
            final activeFilters = controller.activeFiltersCount;
            return CustomButton(
              text: activeFilters['count'] > 0 
                  ? 'Aplicar ${activeFilters['count']} Filtros'
                  : 'Aplicar Filtros',
              onPressed: controller.applyFilters,
              type: ButtonType.primary,
              icon: Icons.search,
            );
          }),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Limpiar Filtros',
            onPressed: controller.clearFilters,
            type: ButtonType.outline,
            icon: Icons.clear_all,
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: controller.startDateFilter.value ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: controller.endDateFilter.value ?? DateTime.now(),
    );
    
    if (date != null) {
      controller.startDateFilter.value = date;
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: controller.endDateFilter.value ?? DateTime.now(),
      firstDate: controller.startDateFilter.value ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      controller.endDateFilter.value = date;
    }
  }
}