// lib/features/inventory/presentation/widgets/inventory_batches_filters.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/inventory_batch.dart';
import '../controllers/inventory_batches_controller.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';

class InventoryBatchesFilters extends StatefulWidget {
  const InventoryBatchesFilters({super.key});

  @override
  State<InventoryBatchesFilters> createState() => _InventoryBatchesFiltersState();
}

class _InventoryBatchesFiltersState extends State<InventoryBatchesFilters> {
  final controller = Get.find<InventoryBatchesController>();
  List<Warehouse> _warehouses = [];
  bool _isLoadingWarehouses = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoadingWarehouses = true);

    try {
      final getWarehousesUseCase = Get.find<GetWarehousesUseCase>();
      final result = await getWarehousesUseCase();

      result.fold(
        (failure) => setState(() => _isLoadingWarehouses = false),
        (warehouses) => setState(() {
          _warehouses = warehouses;
          _isLoadingWarehouses = false;
        }),
      );
    } catch (e) {
      setState(() => _isLoadingWarehouses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtros de Lotes',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Status and Warehouse filters - Stack on mobile
            isMobile 
              ? Column(
                  children: [
                    _buildStatusFilter(isMobile),
                    const SizedBox(height: 12),
                    _buildWarehouseFilter(isMobile),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatusFilter(isMobile)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildWarehouseFilter(isMobile)),
                  ],
                ),

            SizedBox(height: isMobile ? 12 : 16),

            // Special filters
            Text(
              'Filtros Especiales',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            
            Wrap(
              spacing: isMobile ? 6 : 8,
              runSpacing: isMobile ? 6 : 8,
              children: [
                _buildFilterChip(
                  'Solo Activos',
                  controller.showActiveOnly,
                  controller.toggleActiveOnly,
                  Icons.check_circle,
                  Colors.green,
                  isMobile,
                ),
                _buildFilterChip(
                  'Por Vencer',
                  controller.showNearExpiryOnly,
                  controller.toggleNearExpiryOnly,
                  Icons.warning,
                  Colors.orange,
                  isMobile,
                ),
                _buildFilterChip(
                  'Vencidos',
                  controller.showExpiredOnly,
                  controller.toggleExpiredOnly,
                  Icons.dangerous,
                  Colors.red,
                  isMobile,
                ),
              ],
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons - Stack on very small screens
            isMobile && screenWidth < 400
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => controller.loadInventoryBatches(refresh: true),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Aplicar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.clearFilters,
                        icon: Icon(Icons.clear, size: isMobile ? 16 : 18),
                        label: Text(isMobile ? 'Limpiar' : 'Limpiar Filtros'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.loadInventoryBatches(refresh: true),
                        icon: Icon(Icons.search, size: isMobile ? 16 : 18),
                        label: Text(isMobile ? 'Aplicar' : 'Aplicar Filtros'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8 : 12,
                          ),
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

  Widget _buildStatusFilter(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Lote',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedStatus.value.isNotEmpty 
              ? controller.selectedStatus.value 
              : null,
          onChanged: controller.updateStatus,
          decoration: InputDecoration(
            hintText: 'Todos los estados',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
          ),
          style: TextStyle(fontSize: isMobile ? 12 : 14),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Todos los estados'),
            ),
            ...InventoryBatchStatus.values.map((status) => 
              DropdownMenuItem(
                value: status.name,
                child: Text(status.displayStatus),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildWarehouseFilter(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedWarehouse.value.isNotEmpty 
              ? controller.selectedWarehouse.value 
              : null,
          onChanged: controller.updateWarehouse,
          decoration: InputDecoration(
            hintText: 'Todos los almacenes',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
          ),
          style: TextStyle(fontSize: isMobile ? 12 : 14),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Todos los almacenes'),
            ),
            if (_isLoadingWarehouses)
              const DropdownMenuItem(
                value: null,
                child: Text('Cargando almacenes...'),
              )
            else
              ..._warehouses.map((warehouse) => DropdownMenuItem(
                value: warehouse.id,
                child: Text(warehouse.name),
              )),
          ],
        )),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    RxBool isSelected,
    VoidCallback onTap,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Obx(() => FilterChip(
      label: Text(
        label,
        style: TextStyle(fontSize: isMobile ? 11 : 12),
      ),
      selected: isSelected.value,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: isMobile ? 14 : 16,
        color: isSelected.value ? Colors.white : color,
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 2 : 4,
      ),
      materialTapTargetSize: isMobile 
        ? MaterialTapTargetSize.shrinkWrap 
        : MaterialTapTargetSize.padded,
    ));
  }
}