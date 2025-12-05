// lib/features/reports/presentation/screens/profitability_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/date_range_picker_widget.dart';

class ProfitabilityCategoriesScreen extends GetView<ReportsController> {
  const ProfitabilityCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProfitability.value) {
                return const LoadingWidget(
                  message: 'Cargando análisis por categorías...',
                );
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.profitabilityByCategories.isEmpty) {
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
          bottom: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: AppColors.primary, size: 20),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(
                  () => DateRangePickerWidget(
                    startDate: controller.startDate.value,
                    endDate: controller.endDate.value,
                    onDateRangeChanged: controller.setDateRange,
                    label: 'Período de Análisis',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildWarehouseDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseDropdown() {
    return Obx(
      () => DropdownButtonFormField<String>(
        value:
            controller.selectedWarehouseId.value.isEmpty
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
        ],
        onChanged: (value) => controller.setWarehouseFilter(value ?? ''),
      ),
    );
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildCategoriesGrid(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final categories = controller.profitabilityByCategories;
      final totalRevenue = categories.fold(
        0.0,
        (sum, cat) => sum + cat.totalRevenue,
      );
      final totalCost = categories.fold(0.0, (sum, cat) => sum + cat.totalCost);
      final totalProfit = categories.fold(
        0.0,
        (sum, cat) => sum + cat.grossProfit,
      );

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Categorías Analizadas',
              value: categories.length.toString(),
              icon: Icons.category,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
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
              title: 'Ganancia Total',
              value: controller.formatCurrency(totalProfit),
              icon: Icons.trending_up,
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
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

  Widget _buildCategoriesGrid() {
    return Obx(() {
      final categories = controller.profitabilityByCategories;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis por Categorías',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isPositive = category.profitMargin > 0;
              final marginColor = isPositive ? Colors.green : Colors.red;

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.categoryName ?? 'Sin categoría',
                              style: Get.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryMetric(
                        'Ingresos',
                        controller.formatCurrency(category.totalRevenue),
                        Colors.green,
                      ),
                      _buildCategoryMetric(
                        'Costos',
                        controller.formatCurrency(category.totalCost),
                        Colors.orange,
                      ),
                      _buildCategoryMetric(
                        'Ganancia',
                        controller.formatCurrency(category.grossProfit),
                        marginColor,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: marginColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.profitMargin.toStringAsFixed(1)}% margen',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: marginColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildCategoryMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error al cargar los datos',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
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
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos de categorías',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
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
      title: const Text('Rentabilidad por Categorías'),
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
