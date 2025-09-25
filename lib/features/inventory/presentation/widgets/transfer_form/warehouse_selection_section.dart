// lib/features/inventory/presentation/widgets/transfer_form/warehouse_selection_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/config/themes/app_dimensions.dart';
import '../../../../../app/core/theme/elegant_light_theme.dart';
import '../../../domain/entities/warehouse.dart';
import '../../controllers/create_transfer_controller.dart';

class WarehouseSelectionSection extends GetView<CreateTransferController> {
  const WarehouseSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Almacenes'),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildWarehouseSelectors(),
        const SizedBox(height: AppDimensions.paddingMedium),
      ],
    );
  }

  Widget _buildWarehouseSelectors() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return Column(
            children: [
              _buildFromWarehouseSelector(),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildTransferArrow(isVertical: true),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildToWarehouseSelector(),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: _buildFromWarehouseSelector()),
              const SizedBox(width: AppDimensions.paddingMedium),
              _buildTransferArrow(isVertical: false),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(child: _buildToWarehouseSelector()),
            ],
          );
        }
      },
    );
  }

  Widget _buildFromWarehouseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén de origen',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() => _buildWarehouseDropdown(
          value: controller.selectedFromWarehouseId.value,
          hint: 'Seleccionar almacén de origen',
          onChanged: controller.selectFromWarehouse,
          icon: Icons.outbox,
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderColor: Colors.grey.shade300,
        )),
      ],
    );
  }

  Widget _buildToWarehouseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén de destino',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() => _buildWarehouseDropdown(
          value: controller.selectedToWarehouseId.value,
          hint: 'Seleccionar almacén de destino',
          onChanged: controller.selectToWarehouse,
          icon: Icons.inbox,
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderColor: Colors.grey.shade300,
        )),
      ],
    );
  }

  Widget _buildWarehouseDropdown({
    required String value,
    required String hint,
    required Function(String) onChanged,
    required IconData icon,
    required LinearGradient gradient,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: borderColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey.shade600),
          overflow: TextOverflow.ellipsis,
        ),
        isDense: true,
        menuMaxHeight: 300,
        items: controller.warehouses.map((warehouse) {
          final isDisabled = (value == controller.selectedFromWarehouseId.value && 
                             warehouse.id == controller.selectedToWarehouseId.value) ||
                            (value == controller.selectedToWarehouseId.value && 
                             warehouse.id == controller.selectedFromWarehouseId.value);
          
          return DropdownMenuItem<String>(
            value: warehouse.id,
            enabled: !isDisabled,
            child: _buildWarehouseItem(warehouse, isDisabled),
          );
        }).toList(),
        onChanged: controller.isLoadingWarehouses.value 
            ? null 
            : (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
        isExpanded: true,
      ),
    );
  }

  Widget _buildWarehouseItem(Warehouse warehouse, bool isDisabled) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        height: 48, // Altura fija para evitar overflow
        child: Row(
          children: [
            // Icono del almacén
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isDisabled 
                    ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                    : ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.warehouse,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            // Información del almacén (simplificada para evitar overflow)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      warehouse.name,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey.shade500 : ElegantLightTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Badges compactos
                  if (warehouse.isMainWarehouse) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'P',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                  if (isDisabled) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.block,
                      color: Colors.grey.shade400,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferArrow({required bool isVertical}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isVertical ? Icons.arrow_downward : Icons.arrow_forward,
        color: Colors.white,
        size: 20,
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      ),
    );
  }
}