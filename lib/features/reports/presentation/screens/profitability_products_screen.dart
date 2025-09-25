// lib/features/reports/presentation/screens/profitability_products_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/date_range_picker_widget.dart';
import '../widgets/profitability_chart_widget.dart';
import '../widgets/profitability_table_widget.dart';

class ProfitabilityProductsScreen extends GetView<ReportsController> {
  const ProfitabilityProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),
          
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProfitability.value) {
                return const LoadingWidget(message: 'Cargando análisis de rentabilidad...');
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.profitabilityByProducts.isEmpty) {
                return _buildEmptyState();
              }

              return _buildContentSection();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
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
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros de Análisis',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date Range Picker
              Expanded(
                flex: 2,
                child: Obx(() => DateRangePickerWidget(
                  startDate: controller.startDate.value,
                  endDate: controller.endDate.value,
                  onDateRangeChanged: controller.setDateRange,
                  label: 'Período de Análisis',
                )),
              ),
              const SizedBox(width: 16),
              
              // Category Filter
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 16),
              
              // Warehouse Filter  
              Expanded(
                child: _buildWarehouseDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedCategoryId.value.isEmpty 
          ? null 
          : controller.selectedCategoryId.value,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Todas las categorías'),
        ),
        // TODO: Add actual categories from a categories controller
      ],
      onChanged: (value) => controller.setCategoryFilter(value ?? ''),
    ));
  }

  Widget _buildWarehouseDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedWarehouseId.value.isEmpty 
          ? null 
          : controller.selectedWarehouseId.value,
      decoration: const InputDecoration(
        labelText: 'Almacén',
        prefixIcon: Icon(Icons.warehouse),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Todos los almacenes'),
        ),
        // TODO: Add actual warehouses from a warehouses controller
      ],
      onChanged: (value) => controller.setWarehouseFilter(value ?? ''),
    ));
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          
          const SizedBox(height: 24),
          
          // Charts Section
          _buildChartsSection(),
          
          const SizedBox(height: 24),
          
          // Data Table
          _buildDataTableSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final reports = controller.profitabilityByProducts;
      final totalRevenue = reports.fold(0.0, (sum, report) => sum + report.totalRevenue);
      final totalCost = reports.fold(0.0, (sum, report) => sum + report.totalCost);
      final totalProfit = reports.fold(0.0, (sum, report) => sum + report.grossProfit);
      final avgMargin = reports.isNotEmpty 
          ? reports.fold(0.0, (sum, report) => sum + report.profitMargin) / reports.length
          : 0.0;

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Ingresos Totales',
              value: controller.formatCurrency(totalRevenue),
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Costos Totales',
              value: controller.formatCurrency(totalCost),
              icon: Icons.money_off,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Ganancia Bruta',
              value: controller.formatCurrency(totalProfit),
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Margen Promedio',
              value: controller.formatPercentage(avgMargin),
              icon: Icons.percent,
              color: Colors.purple,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis Visual',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => ProfitabilityChartWidget(
          reports: controller.profitabilityByProducts,
        )),
      ],
    );
  }

  Widget _buildDataTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detalle por Productos',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Obx(() => Chip(
              label: Text('${controller.profitabilityByProducts.length} productos'),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => ProfitabilityTableWidget(
          reports: controller.profitabilityByProducts,
          onProductTap: (productId) {
            // TODO: Navigate to product detail
          },
        )),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar los datos',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            controller.error.value,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshProfitabilityReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos de rentabilidad',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron datos para el período seleccionado.',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar Filtros'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Rentabilidad por Productos'),
      actions: [
        IconButton(
          onPressed: controller.exportProfitabilityReport,
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar',
        ),
        IconButton(
          onPressed: controller.refreshProfitabilityReports,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}