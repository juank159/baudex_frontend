// lib/features/inventory/presentation/widgets/inventory_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../controllers/inventory_controller.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';

class InventoryFilterWidget extends StatefulWidget {
  const InventoryFilterWidget({super.key});

  @override
  State<InventoryFilterWidget> createState() => _InventoryFilterWidgetState();
}

class _InventoryFilterWidgetState extends State<InventoryFilterWidget> {
  final controller = Get.find<InventoryController>();
  List<Category> _categories = [];
  List<Warehouse> _warehouses = [];
  bool _isLoadingCategories = false;
  bool _isLoadingWarehouses = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadWarehouses();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
      final result = await getCategoriesUseCase(
        const GetCategoriesParams(limit: 100, onlyParents: true),
      );
      
      result.fold(
        (failure) => setState(() => _isLoadingCategories = false),
        (categoriesResult) => setState(() {
          _categories = categoriesResult.data;
          _isLoadingCategories = false;
        }),
      );
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: Get.theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.clearFilters,
                child: const Text('Limpiar'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stock filters (only for balances tab)
          Obx(() => controller.selectedTab.value == 0 
              ? _buildStockFilters() 
              : const SizedBox.shrink()),
          
          // Warehouse filter
          _buildWarehouseFilter(),
          
          const SizedBox(height: 16),
          
          // Category filter (only for balances tab)
          Obx(() => controller.selectedTab.value == 0 
              ? _buildCategoryFilter() 
              : const SizedBox.shrink()),
          
          const SizedBox(height: 16),
          
          // Sorting options
          _buildSortingOptions(),
          
          const SizedBox(height: 16),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.applyFilters,
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Stock',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Obx(() => FilterChip(
              label: const Text('Stock bajo'),
              selected: controller.showLowStockOnly.value,
              onSelected: (value) => controller.showLowStockOnly.value = value,
              avatar: const Icon(Icons.warning, size: 16),
            )),
            Obx(() => FilterChip(
              label: const Text('Sin stock'),
              selected: controller.showOutOfStockOnly.value,
              onSelected: (value) => controller.showOutOfStockOnly.value = value,
              avatar: const Icon(Icons.error, size: 16),
            )),
            Obx(() => FilterChip(
              label: const Text('Próximos a vencer'),
              selected: controller.showNearExpiryOnly.value,
              onSelected: (value) => controller.showNearExpiryOnly.value = value,
              avatar: const Icon(Icons.schedule, size: 16),
            )),
            Obx(() => FilterChip(
              label: const Text('Vencidos'),
              selected: controller.showExpiredOnly.value,
              onSelected: (value) => controller.showExpiredOnly.value = value,
              avatar: const Icon(Icons.dangerous, size: 16),
            )),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWarehouseFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.warehouseIdFilter.value.isEmpty 
              ? null 
              : controller.warehouseIdFilter.value,
          decoration: const InputDecoration(
            hintText: 'Todos los almacenes',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warehouse),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Todos los almacenes'),
            ),
            if (_isLoadingWarehouses)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Cargando almacenes...'),
              )
            else
              ..._warehouses.map((warehouse) => DropdownMenuItem<String>(
                value: warehouse.id,
                child: Text(warehouse.name),
              )),
          ],
          onChanged: (value) {
            controller.warehouseIdFilter.value = value ?? '';
          },
        )),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.categoryIdFilter.value.isEmpty 
              ? null 
              : controller.categoryIdFilter.value,
          decoration: const InputDecoration(
            hintText: 'Todas las categorías',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Todas las categorías'),
            ),
            if (_isLoadingCategories)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Cargando categorías...'),
              )
            else
              ..._categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }),
          ],
          onChanged: (value) {
            controller.categoryIdFilter.value = value ?? '';
          },
        )),
      ],
    );
  }

  Widget _buildSortingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordenar por',
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Obx(() => DropdownButtonFormField<String>(
                value: controller.sortBy.value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                ),
                items: _getSortByOptions(),
                onChanged: (value) {
                  if (value != null) {
                    controller.sortBy.value = value;
                  }
                },
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => DropdownButtonFormField<String>(
                value: controller.sortOrder.value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'asc',
                    child: Text('Ascendente'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'desc',
                    child: Text('Descendente'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.sortOrder.value = value;
                  }
                },
              )),
            ),
          ],
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getSortByOptions() {
    if (controller.selectedTab.value == 0) {
      // Balances tab
      return const [
        DropdownMenuItem<String>(
          value: 'productName',
          child: Text('Nombre del producto'),
        ),
        DropdownMenuItem<String>(
          value: 'totalQuantity',
          child: Text('Cantidad total'),
        ),
        DropdownMenuItem<String>(
          value: 'totalValue',
          child: Text('Valor total'),
        ),
        DropdownMenuItem<String>(
          value: 'averageCost',
          child: Text('Costo promedio'),
        ),
        DropdownMenuItem<String>(
          value: 'lastMovementDate',
          child: Text('Último movimiento'),
        ),
      ];
    } else {
      // Movements tab
      return const [
        DropdownMenuItem<String>(
          value: 'movementDate',
          child: Text('Fecha de movimiento'),
        ),
        DropdownMenuItem<String>(
          value: 'productName',
          child: Text('Nombre del producto'),
        ),
        DropdownMenuItem<String>(
          value: 'quantity',
          child: Text('Cantidad'),
        ),
        DropdownMenuItem<String>(
          value: 'type',
          child: Text('Tipo de movimiento'),
        ),
        DropdownMenuItem<String>(
          value: 'status',
          child: Text('Estado'),
        ),
      ];
    }
  }
}