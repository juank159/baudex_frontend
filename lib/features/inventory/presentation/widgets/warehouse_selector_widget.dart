// lib/features/inventory/presentation/widgets/warehouse_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';

class WarehouseSelectorWidget extends StatefulWidget {
  final String label;
  final String? hintText;
  final Warehouse? selectedWarehouse;
  final Function(Warehouse) onWarehouseSelected;
  final bool isRequired;
  final bool enabled;
  final IconData? icon;
  final Color? iconColor;

  const WarehouseSelectorWidget({
    super.key,
    required this.label,
    this.hintText,
    this.selectedWarehouse,
    required this.onWarehouseSelected,
    this.isRequired = false,
    this.enabled = true,
    this.icon,
    this.iconColor,
  });

  @override
  State<WarehouseSelectorWidget> createState() => _WarehouseSelectorWidgetState();
}

class _WarehouseSelectorWidgetState extends State<WarehouseSelectorWidget> {
  List<Warehouse> _warehouses = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final getWarehousesUseCase = Get.find<GetWarehousesUseCase>();
      final result = await getWarehousesUseCase();
      
      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (warehouses) {
          setState(() {
            _warehouses = warehouses;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            children: widget.isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.enabled ? _showWarehouseSelector : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.enabled ? AppColors.borderLight : AppColors.borderLight.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
              color: widget.enabled ? Colors.transparent : AppColors.surface.withOpacity(0.5),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.enabled 
                        ? (widget.iconColor ?? AppColors.primary)
                        : AppColors.textSecondary.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.selectedWarehouse?.name ?? 
                        widget.hintText ?? 
                        'Seleccionar almacén',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: widget.selectedWarehouse != null
                          ? (widget.enabled ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5))
                          : (widget.enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.5)),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWarehouseSelector() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Seleccionar Almacén',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar almacén...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Warehouses list
            Expanded(
              child: _buildWarehousesList(),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildWarehousesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando almacenes...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWarehouses,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_warehouses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warehouse, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay almacenes disponibles'),
          ],
        ),
      );
    }

    // Filter warehouses based on search query
    final filteredWarehouses = _warehouses.where((warehouse) {
      if (_searchQuery.isEmpty) return true;
      return warehouse.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             warehouse.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredWarehouses.length,
      itemBuilder: (context, index) {
        final warehouse = filteredWarehouses[index];
        final isSelected = widget.selectedWarehouse?.id == warehouse.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (widget.iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warehouse,
                color: widget.iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              warehouse.name,
              style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${warehouse.code}'),
                if (warehouse.description != null)
                  Text(
                    warehouse.description!,
                    style: Get.textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              widget.onWarehouseSelected(warehouse);
              Get.back();
            },
          ),
        );
      },
    );
  }
}