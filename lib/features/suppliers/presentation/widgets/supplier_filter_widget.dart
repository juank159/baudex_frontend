// lib/features/suppliers/presentation/widgets/supplier_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_dropdown.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/suppliers_controller.dart';
import '../../domain/entities/supplier.dart';

class SupplierFilterWidget extends GetView<SuppliersController> {
  const SupplierFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(() {
                final filtersInfo = controller.activeFiltersCount;
                return TextButton(
                  onPressed: controller.clearFilters,
                  child: Text(
                    'Limpiar (${filtersInfo['count']})',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Filtros principales
          _buildMainFilters(),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Filtros adicionales (expandibles)
          _buildExpandableFilters(),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMainFilters() {
    return Row(
      children: [
        // Estado
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado',
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => CustomDropdown<SupplierStatus>(
                label: 'Estado',
                value: controller.statusFilter.value,
                hintText: 'Todos',
                items: SupplierStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(controller.getStatusText(status)),
                        ))
                    .toList(),
                onChanged: (value) {
                  controller.statusFilter.value = value;
                },
              )),
            ],
          ),
        ),
        
        const SizedBox(width: AppDimensions.paddingMedium),
        
        // Tipo de documento
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documento',
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => CustomDropdown<DocumentType>(
                label: 'Tipo de Documento',
                value: controller.documentTypeFilter.value,
                hintText: 'Todos',
                items: DocumentType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(controller.getDocumentTypeText(type)),
                        ))
                    .toList(),
                onChanged: (value) {
                  controller.documentTypeFilter.value = value;
                },
              )),
            ],
          ),
        ),
        
        const SizedBox(width: AppDimensions.paddingMedium),
        
        // Moneda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moneda',
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              CustomTextField(
                label: 'Moneda',
                controller: TextEditingController(text: controller.currencyFilter.value),
                hint: 'Ej: COP, USD',
                onChanged: (value) {
                  controller.currencyFilter.value = value;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableFilters() {
    return ExpansionTile(
      title: Text(
        'Filtros adicionales',
        style: Get.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      childrenPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
      children: [
        // Checkboxes para filtros booleanos
        Wrap(
          spacing: AppDimensions.paddingMedium,
          runSpacing: AppDimensions.paddingSmall,
          children: [
            _buildFilterCheckbox(
              label: 'Con email',
              value: controller.hasEmailFilter,
              icon: Icons.email_outlined,
            ),
            _buildFilterCheckbox(
              label: 'Con teléfono',
              value: controller.hasPhoneFilter,
              icon: Icons.phone_outlined,
            ),
            _buildFilterCheckbox(
              label: 'Con límite de crédito',
              value: controller.hasCreditLimitFilter,
              icon: Icons.credit_card_outlined,
            ),
            _buildFilterCheckbox(
              label: 'Con descuento',
              value: controller.hasDiscountFilter,
              icon: Icons.discount_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterCheckbox({
    required String label,
    required RxBool value,
    required IconData icon,
  }) {
    return Obx(() => InkWell(
      onTap: () => value.value = !value.value,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: value.value ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: value.value ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value.value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: value.value ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 16,
              color: value.value ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Get.textTheme.bodySmall?.copyWith(
                color: value.value ? AppColors.primary : Colors.grey.shade700,
                fontWeight: value.value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Aplicar filtros',
            onPressed: () {
              controller.applyFilters();
              controller.toggleFilters();
            },
            type: ButtonType.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            onPressed: controller.toggleFilters,
            type: ButtonType.outline,
          ),
        ),
      ],
    );
  }
}