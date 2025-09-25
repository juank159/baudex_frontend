// lib/features/inventory/presentation/widgets/inventory_balance_filters.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../controllers/inventory_balance_controller.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';

class InventoryBalanceFilters extends StatefulWidget {
  const InventoryBalanceFilters({super.key});

  @override
  State<InventoryBalanceFilters> createState() => _InventoryBalanceFiltersState();
}

class _InventoryBalanceFiltersState extends State<InventoryBalanceFilters> {
  final controller = Get.find<InventoryBalanceController>();
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros de Inventario',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Category and Warehouse filters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: controller.selectedCategory.value.isNotEmpty 
                          ? controller.selectedCategory.value 
                          : null,
                      onChanged: controller.updateCategory,
                      decoration: InputDecoration(
                        hintText: 'Todas las categorías',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _isLoadingCategories
                          ? [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Cargando categorías...'),
                              ),
                            ]
                          : _categories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almacén',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: controller.selectedWarehouse.value.isNotEmpty 
                          ? controller.selectedWarehouse.value 
                          : null,
                      onChanged: controller.updateWarehouse,
                      decoration: InputDecoration(
                        hintText: 'Todos los almacenes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stock status filters
          Text(
            'Estado del Stock',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Obx(() => FilterChip(
                label: const Text('Stock Bajo'),
                selected: controller.showLowStock.value,
                onSelected: (_) => controller.toggleLowStock(),
                avatar: Icon(
                  Icons.warning,
                  size: 16,
                  color: controller.showLowStock.value 
                      ? Colors.white 
                      : Colors.orange,
                ),
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
              )),
              
              Obx(() => FilterChip(
                label: const Text('Sin Stock'),
                selected: controller.showOutOfStock.value,
                onSelected: (_) => controller.toggleOutOfStock(),
                avatar: Icon(
                  Icons.error,
                  size: 16,
                  color: controller.showOutOfStock.value 
                      ? Colors.white 
                      : Colors.red,
                ),
                selectedColor: Colors.red,
                checkmarkColor: Colors.white,
              )),
              
              Obx(() => FilterChip(
                label: const Text('Con Stock'),
                selected: controller.showWithStock.value,
                onSelected: (_) => controller.toggleWithStock(),
                avatar: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: controller.showWithStock.value 
                      ? Colors.white 
                      : Colors.green,
                ),
                selectedColor: Colors.green,
                checkmarkColor: Colors.white,
              )),
              
              Obx(() => FilterChip(
                label: const Text('Vencidos'),
                selected: controller.showExpired.value,
                onSelected: (_) => controller.toggleExpired(),
                avatar: Icon(
                  Icons.dangerous,
                  size: 16,
                  color: controller.showExpired.value 
                      ? Colors.white 
                      : Colors.red.shade800,
                ),
                selectedColor: Colors.red.shade800,
                checkmarkColor: Colors.white,
              )),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Filtros'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.loadInventoryBalances(refresh: true),
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}