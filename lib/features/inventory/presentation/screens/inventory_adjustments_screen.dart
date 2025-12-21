// lib/features/inventory/presentation/screens/inventory_adjustments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/inventory_adjustments_controller.dart';
import '../widgets/product_search_widget.dart';

class InventoryAdjustmentsScreen extends GetView<InventoryAdjustmentsController> {
  const InventoryAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustar Inventario',
      showBackButton: true,
      showDrawer: false,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1200;
            final isMediumScreen = constraints.maxWidth > 800;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMediumScreen ? AppDimensions.paddingLarge : AppDimensions.paddingMedium,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 1000 : (isMediumScreen ? 800 : double.infinity),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructions(),
                      const SizedBox(height: AppDimensions.paddingLarge),
                      _buildWarehouseSelector(),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _buildProductSelector(),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      if (controller.hasCurrentBalance) ...[
                        if (isWideScreen) 
                          _buildWideScreenLayout()
                        else 
                          _buildNormalLayout(),
                        const SizedBox(height: AppDimensions.paddingLarge),
                        _buildSubmitButton(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Ajuste de Inventario',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Use esta función para corregir las cantidades de inventario cuando encuentre diferencias entre el stock del sistema y el conteo físico.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              '• Seleccione el almacén donde aplicar el ajuste\n'
              '• Seleccione el producto a ajustar\n'
              '• Ingrese la cantidad real encontrada\n'
              '• Especifique la razón del ajuste\n'
              '• Confirme para aplicar los cambios',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Producto',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ProductSearchWidget(
              hintText: 'Buscar producto por nombre o SKU...',
              onProductSelected: controller.selectProduct,
              searchFunction: controller.searchProducts,
            ),
            if (controller.selectedProductName.value.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warehouse,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Seleccionar Almacén',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Seleccione el almacén donde se aplicará el ajuste de inventario',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Obx(() {
              if (controller.warehouses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Text(
                        'Cargando almacenes...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.warehouse, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                hint: Text('Seleccione un almacén'),
                value: controller.selectedWarehouseId.value.isNotEmpty 
                    ? controller.selectedWarehouseId.value 
                    : null,
                items: controller.warehouses.map((warehouse) {
                  return DropdownMenuItem<String>(
                    value: warehouse.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: AppDimensions.paddingSmall),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                warehouse.name,
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (warehouse.description?.isNotEmpty == true)
                                Text(
                                  warehouse.description!,
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? warehouseId) {
                  if (warehouseId != null) {
                    final warehouse = controller.warehouses.firstWhere(
                      (w) => w.id == warehouseId,
                    );
                    controller.setSelectedWarehouse(warehouseId, warehouse.name);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debe seleccionar un almacén';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: AppDimensions.paddingSmall),
            Obx(() {
              if (controller.selectedWarehouseId.value.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Expanded(
                        child: Text(
                          'Seleccione el almacén antes de continuar',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final selectedWarehouse = controller.warehouses.firstWhereOrNull(
                (w) => w.id == controller.selectedWarehouseId.value,
              );

              if (selectedWarehouse != null) {
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warehouse,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Almacén seleccionado: ${selectedWarehouse.name}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (selectedWarehouse.description?.isNotEmpty == true)
                              Text(
                                selectedWarehouse.description!,
                                style: TextStyle(
                                  color: AppColors.primary.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              controller.selectedWarehouseName.value != 'Seleccionar almacén'
                  ? 'Stock en ${controller.selectedWarehouseName.value}'
                  : 'Stock Actual en Sistema',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )),
            const SizedBox(height: AppDimensions.paddingMedium),
            Obx(() {
              final balance = controller.currentBalance.value;
              if (balance == null) return const SizedBox.shrink();

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStockMetric(
                          'Stock Total',
                          '${balance.totalQuantity}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStockMetric(
                          'Stock Disponible',
                          '${balance.availableQuantity}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStockMetric(
                          'Stock Reservado',
                          '${balance.reservedQuantity}',
                          Icons.lock,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStockMetric(
                          'Valor Total',
                          controller.formatCurrency(balance.totalValue),
                          Icons.monetization_on,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMetric(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            value,
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajuste de Cantidad',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // New quantity input with responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Wide layout
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: controller.newQuantityController,
                          label: 'Cantidad Final del Inventario',
                          hint: 'Cantidad real encontrada en conteo físico',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.inventory_2,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMedium),
                      Expanded(
                        flex: 1,
                        child: _buildQuantityActionButtons(),
                      ),
                    ],
                  );
                } else {
                  // Narrow layout
                  return Column(
                    children: [
                      CustomTextField(
                        controller: controller.newQuantityController,
                        label: 'Cantidad Final del Inventario',
                        hint: 'Cantidad real encontrada en conteo físico',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        prefixIcon: Icons.inventory_2,
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _buildQuantityActionButtons(isHorizontal: true),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Adjustment preview
            Obx(() => _buildAdjustmentPreview()),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Unit cost (if needed)
            Obx(() {
              if (!controller.showUnitCostField) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Text(
                        'Costo Unitario',
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    controller.adjustmentDifference > 0 
                        ? 'Ingrese el costo por unidad de las nuevas existencias'
                        : 'Costo usado para calcular el impacto del ajuste',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  CustomTextField(
                    controller: controller.unitCostController,
                    label: 'Costo por Unidad (COP)',
                    hint: 'Ejemplo: 25000.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    prefixIcon: Icons.attach_money,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                ],
              );
            }),
            
            // Reason selection
            _buildReasonSection(),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Notes
            CustomTextField(
              controller: controller.notesController,
              label: 'Notas (Opcional)',
              hint: 'Información adicional sobre el ajuste...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentPreview() {
    final difference = controller.adjustmentDifference;
    if (difference == 0) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.remove, color: Colors.grey),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              'Sin cambios en el inventario',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: controller.getAdjustmentColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: controller.getAdjustmentColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                controller.getAdjustmentIcon(),
                color: controller.getAdjustmentColor(),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Text(
                  controller.getAdjustmentText(),
                  style: TextStyle(
                    color: controller.getAdjustmentColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (controller.adjustmentValue != 0) ...[
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: controller.getAdjustmentColor(),
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Impacto: ${controller.adjustmentValueText}',
                  style: TextStyle(
                    color: controller.getAdjustmentColor(),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              'Razón del Ajuste',
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Text(
          'Seleccione la causa que motivó este ajuste de inventario',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Predefined reasons with better layout
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.adjustmentReasons.map((reason) {
                return Obx(() => SizedBox(
                  width: constraints.maxWidth > 600 
                      ? (constraints.maxWidth - 16) / 3 
                      : (constraints.maxWidth - 8) / 2,
                  child: FilterChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: controller.reason.value == reason 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    selected: controller.reason.value == reason,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setReasonFromPredefined(reason);
                      }
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: controller.reason.value == reason 
                          ? AppColors.primary 
                          : Colors.grey.shade300,
                    ),
                  ),
                ));
              }).toList(),
            );
          },
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Custom reason input
        CustomTextField(
          controller: controller.reasonController,
          label: 'Razón Personalizada (Opcional)',
          hint: 'Si ninguna opción aplica, describa la razón específica...',
          maxLines: 2,
          prefixIcon: Icons.edit_note,
        ),
        
        const SizedBox(height: AppDimensions.paddingSmall),
        Obx(() {
          final hasSelectedReason = controller.reason.value.isNotEmpty;
          final hasCustomReason = controller.reasonController.text.trim().isNotEmpty;
          
          if (!hasSelectedReason && !hasCustomReason) {
            return Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Text(
                      'Debe seleccionar una razón o escribir una personalizada',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildCurrentStockCard(),
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildAdjustmentForm(),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.paddingLarge),
        Expanded(
          flex: 1,
          child: _buildAdjustmentSummaryCard(),
        ),
      ],
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        _buildCurrentStockCard(),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildAdjustmentForm(),
      ],
    );
  }

  Widget _buildAdjustmentSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Ajuste',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Obx(() => _buildAdjustmentPreview()),
            const SizedBox(height: AppDimensions.paddingMedium),
            Obx(() {
              final balance = controller.currentBalance.value;
              if (balance == null) return const SizedBox.shrink();

              return Column(
                children: [
                  _buildSummaryRow(
                    'Stock Actual',
                    '${balance.totalQuantity}',
                    Icons.inventory,
                  ),
                  _buildSummaryRow(
                    'Nueva Cantidad',
                    '${controller.newQuantity.value}',
                    Icons.edit,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Diferencia',
                    '${controller.adjustmentDifference}',
                    controller.getAdjustmentIcon(),
                    color: controller.getAdjustmentColor(),
                  ),
                  if (controller.unitCost.value > 0) ...[
                    const Divider(),
                    _buildSummaryRow(
                      'Impacto Monetario',
                      controller.adjustmentValueText,
                      Icons.monetization_on,
                      color: controller.getAdjustmentColor(),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityActionButtons({bool isHorizontal = false}) {
    final buttons = [
      _buildActionButton(
        icon: Icons.clear,
        tooltip: 'Poner en cero',
        color: Colors.red,
        onPressed: controller.setQuantityToZero,
      ),
      _buildActionButton(
        icon: Icons.refresh,
        tooltip: 'Restaurar cantidad actual',
        color: Colors.blue,
        onPressed: controller.resetToCurrentStock,
      ),
    ];

    if (isHorizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buttons[0],
          const SizedBox(height: 4),
          buttons[1],
        ],
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Colors.grey.shade600,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              label,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: controller.submitButtonText,
        onPressed: controller.isFormValid ? controller.createAdjustment : null,
        isLoading: controller.isCreating.value,
        backgroundColor: controller.adjustmentDifference == 0 
            ? Colors.grey 
            : controller.getAdjustmentColor(),
        icon: controller.adjustmentDifference == 0 
            ? Icons.remove 
            : controller.getAdjustmentIcon(),
      ),
    ));
  }
}