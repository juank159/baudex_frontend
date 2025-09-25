// lib/features/settings/presentation/widgets/main_warehouse_selector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../inventory/domain/entities/warehouse.dart';
import '../../../inventory/presentation/controllers/warehouses_controller.dart';

class MainWarehouseSelector extends StatelessWidget {
  const MainWarehouseSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarehousesController>(
      init: Get.find<WarehousesController>(),
      builder: (controller) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(Icons.warehouse, color: AppColors.primary, size: 24),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    Text(
                      'Almacén Principal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                
                // Descripción
                Text(
                  'El almacén principal es donde se descontará automáticamente el inventario al hacer ventas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                
                // Selector de almacén
                Obx(() {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (controller.warehouses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: AppDimensions.spacingSmall),
                          Expanded(
                            child: Text(
                              'No hay almacenes disponibles. Crea uno primero.',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final warehouses = controller.warehouses.map((w) => w.warehouse).toList();
                  final mainWarehouse = warehouses.firstWhereOrNull((w) => w.isMainWarehouse);
                  
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        // Almacén principal actual
                        if (mainWarehouse != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                const SizedBox(width: AppDimensions.spacingSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Principal: ${mainWarehouse.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        'Código: ${mainWarehouse.code}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Lista de todos los almacenes
                        ...warehouses.map((warehouse) => _buildWarehouseOption(
                          context, 
                          warehouse, 
                          warehouse.isMainWarehouse,
                          controller,
                        )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseOption(
    BuildContext context,
    Warehouse warehouse,
    bool isMain,
    WarehousesController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Radio<String>(
          value: warehouse.id,
          groupValue: isMain ? warehouse.id : null,
          onChanged: isMain ? null : (String? value) {
            if (value != null) {
              _showChangeMainWarehouseDialog(context, warehouse, controller);
            }
          },
        ),
        title: Text(
          warehouse.name,
          style: TextStyle(
            fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
            color: isMain ? Colors.green[700] : Colors.black,
          ),
        ),
        subtitle: Text(
          'Código: ${warehouse.code}${isMain ? ' (Principal)' : ''}',
          style: TextStyle(
            color: isMain ? Colors.green[600] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: isMain
            ? Icon(Icons.star, color: Colors.green[700], size: 20)
            : null,
      ),
    );
  }

  void _showChangeMainWarehouseDialog(
    BuildContext context,
    Warehouse newMainWarehouse,
    WarehousesController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cambiar Almacén Principal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres cambiar el almacén principal?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo almacén principal:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text('• ${newMainWarehouse.name}'),
                  Text('• Código: ${newMainWarehouse.code}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las próximas ventas descontarán de este almacén.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _changeMainWarehouse(newMainWarehouse, controller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Cambiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _changeMainWarehouse(
    Warehouse newMainWarehouse,
    WarehousesController controller,
  ) async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cambiando almacén principal...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // TODO: Hacer la llamada al API cuando esté disponible
      // Por ahora simulamos la operación
      await Future.delayed(const Duration(seconds: 2));
      
      // Cerrar loading
      Get.back();
      
      // Actualizar la lista
      await controller.refreshWarehouses();
      
      // Mostrar éxito
      Get.snackbar(
        '¡Éxito!',
        '${newMainWarehouse.name} establecido como almacén principal',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[700],
        icon: Icon(Icons.check_circle, color: Colors.green[700]),
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'No se pudo cambiar el almacén principal: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[700],
        icon: Icon(Icons.error, color: Colors.red[700]),
        duration: const Duration(seconds: 4),
      );
    }
  }
}