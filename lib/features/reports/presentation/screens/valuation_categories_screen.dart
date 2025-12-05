// lib/features/reports/presentation/screens/valuation_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/valuation_method_selector.dart';

class ValuationCategoriesScreen extends GetView<ReportsController> {
  const ValuationCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlsSection(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingValuation.value) {
                return const LoadingWidget(
                  message: 'Cargando valoración por categorías...',
                );
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.valuationByCategories.isEmpty) {
                return _buildEmptyState();
              }

              return _buildContentSection();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
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
              Icon(Icons.category, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Configuración de Valoración',
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
              Expanded(child: _buildDateSelector()),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => ValuationMethodSelector(
                    selectedMethod: controller.valuationMethod.value,
                    onMethodChanged: controller.setValuationMethod,
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

  Widget _buildDateSelector() {
    return Obx(
      () => InkWell(
        onTap: () => _showDatePicker(),
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Fecha de Valoración',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          child: Text(
            controller.asOfDate.value != null
                ? controller.formatDate(controller.asOfDate.value!)
                : 'Seleccionar fecha',
            style: Get.textTheme.bodyMedium,
          ),
        ),
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
          _buildSummarySection(),
          const SizedBox(height: 24),
          _buildCategoriesGrid(),
          const SizedBox(height: 24),
          _buildComparisonChart(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Obx(() {
      final categories = controller.valuationByCategories;
      final totalValue = categories.fold(0.0, (sum, c) => sum + c.totalValue);
      final totalQuantity = categories.fold(
        0.0,
        (sum, c) => sum + c.currentQuantity,
      );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pie_chart, size: 32, color: AppColors.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valoración por Categorías',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valor Total: ${controller.formatCurrency(totalValue)}',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${categories.length} categorías | ${totalQuantity.toStringAsFixed(0)} unidades',
                    style: Get.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoriesGrid() {
    return Obx(() {
      final categories = controller.valuationByCategories;
      final totalValue = categories.fold(0.0, (sum, c) => sum + c.totalValue);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valoración Detallada',
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
              childAspectRatio: 1.3,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final percentage =
                  totalValue > 0
                      ? (category.totalValue / totalValue) * 100
                      : 0.0;
              final color = _getCategoryColor(index);

              return Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
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
                      Text(
                        controller.formatCurrency(category.totalValue),
                        style: Get.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% del total',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(percentage / 100, color),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${category.currentQuantity.toStringAsFixed(0)} und.',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            controller.formatCurrency(category.averageCost),
                            style: Get.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
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

  Widget _buildProgressBar(double percentage, Color color) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        widthFactor: percentage.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return Obx(() {
      final categories = controller.valuationByCategories;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparación Visual',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Distribución de Valor por Categoría',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHorizontalBarChart(categories),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHorizontalBarChart(List categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final maxValue = categories.fold<double>(
      0,
      (max, cat) => cat.totalValue > max ? cat.totalValue : max,
    );

    return Column(
      children:
          categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final percentage =
                maxValue > 0 ? (category.totalValue / maxValue) : 0.0;
            final color = _getCategoryColor(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.categoryName ?? 'Sin categoría',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        controller.formatCurrency(category.totalValue),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.borderColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: controller.asOfDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.setAsOfDate(date);
    }
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
            onPressed: controller.refreshValuationReports,
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
            'No hay categorías para valorar',
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
      title: const Text('Valoración por Categorías'),
      actions: [
        IconButton(
          onPressed: controller.exportValuationReport,
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar',
        ),
        IconButton(
          onPressed: controller.refreshValuationReports,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}
