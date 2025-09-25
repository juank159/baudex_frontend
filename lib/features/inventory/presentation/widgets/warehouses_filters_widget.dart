// lib/features/inventory/presentation/widgets/warehouses_filters_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../controllers/warehouses_controller.dart';

class WarehousesFiltersWidget extends GetView<WarehousesController> {
  const WarehousesFiltersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de filtros
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros de búsqueda',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.clearAllFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Primera fila de filtros
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, código, descripción o dirección...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: controller.clearSearchQuery,
                            icon: const Icon(Icons.clear),
                          )
                        : const SizedBox.shrink()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Filtro de estado
              Expanded(
                child: Obx(() => DropdownButtonFormField<bool?>(
                  value: controller.selectedStatus,
                  onChanged: controller.updateStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Activos'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Inactivos'),
                        ],
                      ),
                    ),
                  ],
                )),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Segunda fila - Filtros avanzados
          Row(
            children: [
              // Filtro por fecha de creación
              Expanded(
                child: InkWell(
                  onTap: () => _showDateRangeFilter(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => Text(
                            controller.getDateRangeText(),
                            style: Get.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        if (controller.hasDateFilter()) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: controller.clearDateFilter,
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Filtro por criterios múltiples
              Expanded(
                child: InkWell(
                  onTap: () => _showMultipleCriteriaFilter(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => Text(
                            controller.getMultipleCriteriaText(),
                            style: Get.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                        if (controller.hasMultipleCriteria()) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: controller.clearMultipleCriteria,
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botón de exportar
              ElevatedButton.icon(
                onPressed: controller.hasWarehouses ? () => _showExportOptions(context) : null,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ordenamiento
          Row(
            children: [
              Text(
                'Ordenar por:',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Obx(() => DropdownButton<String>(
                  value: controller.sortBy,
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateSort(value, controller.sortOrder);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Nombre'),
                    ),
                    DropdownMenuItem(
                      value: 'code',
                      child: Text('Código'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Fecha de creación'),
                    ),
                  ],
                )),
              ),
              
              const SizedBox(width: 16),
              
              Obx(() => IconButton(
                onPressed: () {
                  final newOrder = controller.sortOrder == 'asc' ? 'desc' : 'asc';
                  controller.updateSort(controller.sortBy, newOrder);
                },
                icon: Icon(
                  controller.sortOrder == 'asc' 
                      ? Icons.arrow_upward 
                      : Icons.arrow_downward,
                ),
                tooltip: controller.sortOrder == 'asc' 
                    ? 'Ascendente (A-Z)' 
                    : 'Descendente (Z-A)',
              )),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas de filtros
          Obx(() {
            final stats = controller.getWarehousesStats();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    'Total',
                    '${stats['total']}',
                    Icons.warehouse,
                    Colors.blue,
                  ),
                  _buildStatChip(
                    'Activos',
                    '${stats['active']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatChip(
                    'Inactivos',
                    '${stats['inactive']}',
                    Icons.cancel,
                    Colors.red,
                  ),
                  _buildStatChip(
                    'Mostrados',
                    '${stats['filtered']}',
                    Icons.visibility,
                    AppColors.primary,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
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
        ),
      ],
    );
  }

  // ==================== ADVANCED FILTERS ====================

  /// Mostrar selector de rango de fechas
  void _showDateRangeFilter(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: controller.hasDateFilter() 
          ? DateTimeRange(
              start: controller.dateFrom!,
              end: controller.dateTo!,
            )
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Guardar',
      locale: const Locale('es', 'ES'),
    );

    if (pickedRange != null) {
      controller.setDateFilter(pickedRange.start, pickedRange.end);
    }
  }

  /// Mostrar filtro de criterios múltiples
  void _showMultipleCriteriaFilter(BuildContext context) {
    Get.dialog(
      Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros Avanzados',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Filtros
              Text(
                'Filtrar por:',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Checkbox para almacenes con descripción
              Obx(() => CheckboxListTile(
                title: const Text('Solo almacenes con descripción'),
                subtitle: const Text('Almacenes que tienen descripción definida'),
                value: controller.filterWithDescription,
                onChanged: controller.toggleDescriptionFilter,
                controlAffinity: ListTileControlAffinity.leading,
              )),
              
              // Checkbox para almacenes con dirección
              Obx(() => CheckboxListTile(
                title: const Text('Solo almacenes con dirección'),
                subtitle: const Text('Almacenes que tienen dirección definida'),
                value: controller.filterWithAddress,
                onChanged: controller.toggleAddressFilter,
                controlAffinity: ListTileControlAffinity.leading,
              )),
              
              // Checkbox para almacenes recientes
              Obx(() => CheckboxListTile(
                title: const Text('Almacenes recientes'),
                subtitle: const Text('Creados en los últimos 30 días'),
                value: controller.filterRecent,
                onChanged: controller.toggleRecentFilter,
                controlAffinity: ListTileControlAffinity.leading,
              )),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.clearMultipleCriteria();
                      Get.back();
                    },
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostrar opciones de exportación
  void _showExportOptions(BuildContext context) {
    Get.dialog(
      Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.download, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Exportar Almacenes',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Información de exportación
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Información de exportación',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final stats = controller.getWarehousesStats();
                      return Text(
                        'Se exportarán ${stats['filtered']} almacenes de ${stats['total']} totales.\n'
                        'Los datos incluirán: nombre, código, descripción, dirección, estado y fechas.',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Opciones de formato
              Text(
                'Selecciona el formato de exportación:',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botones de formato
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.exportToExcel();
                      },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.exportToCsv();
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.exportToPdf();
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.printWarehouses();
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}