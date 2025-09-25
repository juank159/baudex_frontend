// lib/features/inventory/presentation/widgets/transfer_form_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/warehouse.dart';
import '../../../products/domain/entities/product.dart';
import '../controllers/inventory_transfers_controller.dart';
import 'warehouse_selector_widget.dart';
import 'product_search_widget.dart';

class TransferFormWidget extends GetView<InventoryTransfersController> {
  const TransferFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Nueva Transferencia',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: controller.toggleForm,
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Warehouse selection row
          Row(
            children: [
              Expanded(
                child: Obx(() => WarehouseSelectorWidget(
                  label: 'Almacén de Origen',
                  selectedWarehouse: _getWarehouseById(controller.selectedFromWarehouseId.value),
                  onWarehouseSelected: (warehouse) {
                    controller.selectedFromWarehouseId.value = warehouse.id;
                    controller.fromWarehouseController.text = warehouse.displayName;
                  },
                  isRequired: true,
                  icon: Icons.warehouse,
                  iconColor: Colors.blue,
                )),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => WarehouseSelectorWidget(
                  label: 'Almacén de Destino',
                  selectedWarehouse: _getWarehouseById(controller.selectedToWarehouseId.value),
                  onWarehouseSelected: (warehouse) {
                    controller.selectedToWarehouseId.value = warehouse.id;
                    controller.toWarehouseController.text = warehouse.displayName;
                  },
                  isRequired: true,
                  icon: Icons.warehouse,
                  iconColor: Colors.green,
                )),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Product and quantity row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildProductSelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuantityField(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Notes field
          _buildNotesField(),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.toggleForm,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isCreating.value 
                      ? null 
                      : controller.createTransfer,
                  icon: controller.isCreating.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    controller.isCreating.value 
                        ? 'Creando...' 
                        : 'Crear Transferencia',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Producto *',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ProductSearchWidget(
          hintText: 'Buscar producto...',
          searchFunction: _searchProducts,
          onProductSelected: (product) {
            controller.selectedProductId.value = product.id;
            controller.productController.text = '${product.name} (${product.sku})';
          },
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Icon(Icons.tag, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas (Opcional)',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Agregar notas sobre la transferencia...',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.notes, color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Warehouse? _getWarehouseById(String id) {
    if (id.isEmpty) return null;
    
    final warehouses = _getAvailableWarehouses();
    try {
      return warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Warehouse> _getAvailableWarehouses() {
    // TODO: Get warehouses from a service/controller
    // For now, return mock data
    return [
      const Warehouse(
        id: '1',
        name: 'Almacén Principal',
        code: 'ALM-001',
        description: 'Almacén central de la empresa',
      ),
      const Warehouse(
        id: '2',
        name: 'Almacén Secundario',
        code: 'ALM-002',
        description: 'Almacén de respaldo y distribución',
      ),
      const Warehouse(
        id: '3',
        name: 'Almacén de Productos Fríos',
        code: 'ALM-003',
        description: 'Especializado en productos refrigerados',
      ),
    ];
  }

  Future<List<Product>> _searchProducts(String query) async {
    try {
      // Since there's no direct search method, return empty list
      // The ProductSearchWidget will handle the search internally
      return [];
    } catch (e) {
      return [];
    }
  }

}