// lib/features/inventory/presentation/screens/inventory_valuation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_balance_controller.dart';

class InventoryValuationScreen extends GetView<InventoryBalanceController> {
  const InventoryValuationScreen({super.key});

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
              if (controller.isLoading.value && controller.valuationData.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando valoración de inventario...'),
                    ],
                  ),
                );
              }

              if (controller.error.value.isNotEmpty && controller.valuationData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        controller.error.value,
                        textAlign: TextAlign.center,
                        style: Get.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadValuation,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return _buildValuationContent();
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Valoración de Inventario'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => _showExportOptions(),
          icon: const Icon(Icons.download),
          tooltip: 'Exportar',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                controller.loadValuation();
                break;
              case 'filter':
                _showFilterOptions();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'filter',
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
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Valor Total',
                  value: Obx(() => Text(
                    controller.valuationData['totalValue'] != null
                        ? AppFormatters.formatCurrency(controller.valuationData['totalValue']!)
                        : '\$0.00',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )),
                  icon: Icons.monetization_on,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Productos',
                  value: Obx(() => Text(
                    controller.valuationData['totalProducts']?.toInt().toString() ?? '0',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )),
                  icon: Icons.inventory,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Unidades',
                  value: Obx(() => Text(
                    controller.valuationData['totalUnits']?.toInt().toString() ?? '0',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )),
                  icon: Icons.inventory_2,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date and warehouse filters
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWarehouseFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Widget value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de Valoración',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => Text(
                  controller.selectedDate.value != null
                      ? AppFormatters.formatDate(controller.selectedDate.value!)
                      : 'Seleccionar fecha',
                  style: Get.textTheme.bodyMedium,
                )),
              ),
              Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warehouse, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => Text(
                  controller.selectedWarehouse.value.isNotEmpty
                      ? controller.selectedWarehouse.value
                      : 'Todos los almacenes',
                  style: Get.textTheme.bodyMedium,
                )),
              ),
              Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValuationContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Valuation method selector
          _buildValuationMethodSelector(),
          
          const SizedBox(height: 16),
          
          // Results section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Results header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Resultados de Valoración',
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Obx(() => Text(
                          'Actualizado: ${controller.lastUpdated.value != null ? AppFormatters.formatDateTime(controller.lastUpdated.value!) : 'N/A'}',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  // Results content
                  Expanded(
                    child: Obx(() {
                      if (controller.valuationData.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay datos de valoración disponibles',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return _buildValuationDetails();
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de Valoración',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMethodOption(
                  'FIFO',
                  'Primero en entrar, primero en salir',
                  'fifo',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMethodOption(
                  'Costo Promedio',
                  'Basado en costo promedio ponderado',
                  'average',
                  Icons.analytics,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMethodOption(
                  'Último Costo',
                  'Basado en el último precio de compra',
                  'latest',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(String title, String description, String method, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedValuationMethod.value == method;
      
      return GestureDetector(
        onTap: () {
          controller.selectedValuationMethod.value = method;
          controller.loadValuation();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildValuationDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Breakdown by categories
        _buildCategoryBreakdown(),
        
        const SizedBox(height: 24),
        
        // Breakdown by warehouses
        _buildWarehouseBreakdown(),
        
        const SizedBox(height: 24),
        
        // Movement impact
        _buildMovementImpact(),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valoración por Categorías',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mock category data
        ...['Electrónicos', 'Ropa', 'Hogar', 'Deportes'].map((category) => 
          _buildValuationRow(
            category,
            '\$${(1000 + (category.hashCode % 5000)).toStringAsFixed(2)}',
            '${10 + (category.hashCode % 50)} productos',
            Icons.category,
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildWarehouseBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valoración por Almacenes',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mock warehouse data
        ...['Almacén Principal', 'Almacén Secundario', 'Almacén Frío'].map((warehouse) => 
          _buildValuationRow(
            warehouse,
            '\$${(2000 + (warehouse.hashCode % 8000)).toStringAsFixed(2)}',
            '${20 + (warehouse.hashCode % 80)} productos',
            Icons.warehouse,
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildMovementImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impacto de Movimientos (Últimos 30 días)',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildImpactCard(
                'Entradas',
                '+\$3,250.00',
                '45 movimientos',
                Colors.green,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImpactCard(
                'Salidas',
                '-\$1,890.00',
                '32 movimientos',
                Colors.red,
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImpactCard(
                'Ajustes',
                '+\$125.00',
                '8 ajustes',
                Colors.orange,
                Icons.tune,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValuationRow(String title, String value, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Get.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Valoración',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar a PDF'),
              subtitle: const Text('Reporte detallado con gráficos'),
              onTap: () {
                Get.back();
                controller.exportBalancesToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Datos para análisis adicional'),
              onTap: () {
                Get.back();
                controller.exportBalancesToExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
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
              'Filtros de Valorización',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Filtrar por Almacén'),
              subtitle: const Text('Seleccionar almacenes específicos'),
              onTap: () {
                Get.back();
                controller.showFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filtrar por Categoría'),
              subtitle: const Text('Seleccionar categorías de productos'),
              onTap: () {
                Get.back();
                controller.showFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Rango de Valores'),
              subtitle: const Text('Filtrar por valor de inventario'),
              onTap: () {
                Get.back();
                _showValueRangeFilter();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showValueRangeFilter() {
    final minController = TextEditingController();
    final maxController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Rango de Valores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtrar productos por valor de inventario'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor mínimo',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor máximo',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
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
              Get.back();
              Get.snackbar('Filtro aplicado', 'Rango de valores configurado');
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}