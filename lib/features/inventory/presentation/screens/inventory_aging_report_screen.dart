// lib/features/inventory/presentation/screens/inventory_aging_report_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_aging_controller.dart';

class InventoryAgingReportScreen extends GetView<InventoryAgingController> {
  const InventoryAgingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando reporte de antigüedad...'),
                    ],
                  ),
                );
              }

              if (controller.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(controller.error.value, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.refreshReport,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (!controller.hasData) {
                return _buildEmptyState();
              }

              return _buildAgingReport();
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Reporte de Antigüedad'),
      actions: [
        IconButton(
          onPressed: controller.refreshReport,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export_excel':
                _exportToExcel();
                break;
              case 'export_pdf':
                _exportToPdf();
                break;
              case 'filters':
                _showFilters();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_excel',
              child: Row(
                children: [
                  Icon(Icons.table_chart),
                  SizedBox(width: 8),
                  Text('Exportar Excel'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Exportar PDF'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'filters',
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('Filtros'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
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
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporte de Antigüedad de Inventario',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Análisis del tiempo de permanencia de productos en inventario',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Summary cards
          Obx(() => _buildSummaryCards()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (!controller.hasData) return const SizedBox.shrink();

    final summary = controller.agingSummary.value!;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Productos',
            '${summary.totalProducts}',
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Valor Total',
            AppFormatters.formatCurrency(summary.totalValue),
            Icons.monetization_on,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Promedio Días',
            '${summary.averageAgeDays}',
            Icons.schedule,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAgingReport() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.agingData.length,
      itemBuilder: (context, index) {
        final agingItem = controller.agingData[index];
        return _buildAgingCard(agingItem);
      },
    );
  }

  Widget _buildAgingCard(Map<String, dynamic> agingItem) {
    final productName = agingItem['productName'] ?? 'N/A';
    final productSku = agingItem['productSku'] ?? 'N/A';
    final quantity = agingItem['quantity'] ?? 0;
    final totalValue = (agingItem['totalValue'] ?? 0.0).toDouble();
    final averageAge = agingItem['averageAgeDays'] ?? 0;
    final oldestBatchAge = agingItem['oldestBatchAge'] ?? 0;
    final newestBatchAge = agingItem['newestBatchAge'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAgeColor(averageAge).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: _getAgeColor(averageAge),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: $productSku',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cantidad: $quantity',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(totalValue),
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Aging details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAgeMetric(
                        'Promedio',
                        '$averageAge días',
                        Icons.schedule,
                        _getAgeColor(averageAge),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderColor,
                    ),
                    Expanded(
                      child: _buildAgeMetric(
                        'Más Antiguo',
                        '$oldestBatchAge días',
                        Icons.schedule,
                        _getAgeColor(oldestBatchAge),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderColor,
                    ),
                    Expanded(
                      child: _buildAgeMetric(
                        'Más Nuevo',
                        '$newestBatchAge días',
                        Icons.new_releases,
                        _getAgeColor(newestBatchAge),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getAgeColor(int ageDays) {
    if (ageDays <= 30) return Colors.green;
    if (ageDays <= 90) return Colors.orange;
    if (ageDays <= 180) return Colors.red;
    return Colors.red.shade800;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos de antigüedad',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron datos de antigüedad para mostrar.',
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() {
    controller.exportToExcel();
  }

  void _exportToPdf() {
    controller.exportToPdf();
  }

  void _showFilters() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtros de Reporte',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Filtrar por Almacén'),
              subtitle: Obx(() => Text(
                controller.selectedWarehouseId.value.isNotEmpty 
                  ? 'Almacén seleccionado' 
                  : 'Seleccionar almacenes específicos'
              )),
              onTap: () {
                Get.back();
                _showWarehouseFilter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filtrar por Categoría'),
              subtitle: Obx(() => Text(
                controller.selectedCategoryId.value.isNotEmpty 
                  ? 'Categoría seleccionada' 
                  : 'Seleccionar categorías de productos'
              )),
              onTap: () {
                Get.back();
                _showCategoryFilter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Rango de Antigüedad'),
              subtitle: Obx(() => Text(
                'Entre ${controller.minAgeDays.value} y ${controller.maxAgeDays.value} días'
              )),
              onTap: () {
                Get.back();
                _showAgeRangeFilter();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Get.back();
                      controller.clearFilters();
                    },
                    child: const Text('Limpiar Filtros'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.applyFilters();
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseFilter() {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtrar por Almacén'),
        content: const Text('Seleccione el almacén para filtrar el reporte'),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedWarehouseId.value = '';
              Get.back();
            },
            child: const Text('Todos los almacenes'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter() {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtrar por Categoría'),
        content: const Text('Seleccione la categoría para filtrar el reporte'),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedCategoryId.value = '';
              Get.back();
            },
            child: const Text('Todas las categorías'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAgeRangeFilter() {
    final minController = TextEditingController(text: controller.minAgeDays.value.toString());
    final maxController = TextEditingController(text: controller.maxAgeDays.value.toString());
    
    Get.dialog(
      AlertDialog(
        title: const Text('Rango de Antigüedad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtrar productos por días en inventario'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mínimo (días)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Máximo (días)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
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
              final minDays = int.tryParse(minController.text) ?? 0;
              final maxDays = int.tryParse(maxController.text) ?? 365;
              controller.updateAgeRange(minDays, maxDays);
              Get.back();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}