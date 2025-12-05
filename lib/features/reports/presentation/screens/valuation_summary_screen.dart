// lib/features/reports/presentation/screens/valuation_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/valuation_method_selector.dart';
import '../widgets/valuation_summary_cards.dart';
import '../widgets/valuation_breakdown_charts.dart';

class ValuationSummaryScreen extends GetView<ReportsController> {
  const ValuationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Controls Section
          _buildControlsSection(),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingValuation.value) {
                return const LoadingWidget(
                  message: 'Cargando valoración de inventario...',
                );
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.valuationSummary.value == null) {
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
              Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 20,
              ),
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
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // As Of Date
              Expanded(child: _buildDateSelector()),
              const SizedBox(width: 16),

              // Valuation Method
              Expanded(
                child: Obx(
                  () => ValuationMethodSelector(
                    selectedMethod: controller.valuationMethod.value,
                    onMethodChanged: controller.setValuationMethod,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Warehouse Filter
              Expanded(child: _buildWarehouseDropdown()),
              const SizedBox(width: 16),

              // Category Filter
              Expanded(child: _buildCategoryDropdown()),
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
          // TODO: Add actual warehouses
        ],
        onChanged: (value) => controller.setWarehouseFilter(value ?? ''),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(
      () => DropdownButtonFormField<String>(
        value:
            controller.selectedCategoryId.value.isEmpty
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
          // TODO: Add actual categories
        ],
        onChanged: (value) => controller.setCategoryFilter(value ?? ''),
      ),
    );
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with summary info
          _buildHeaderSection(),

          const SizedBox(height: 24),

          // Summary Cards
          Obx(
            () => ValuationSummaryCards(
              summary: controller.valuationSummary.value!,
            ),
          ),

          const SizedBox(height: 24),

          // Breakdown Charts
          Obx(
            () => ValuationBreakdownCharts(
              summary: controller.valuationSummary.value!,
            ),
          ),

          const SizedBox(height: 24),

          // Top Valued Products
          _buildTopValuedProducts(),

          const SizedBox(height: 24),

          // Valuation Comparison
          _buildValuationComparison(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Obx(() {
      final summary = controller.valuationSummary.value!;
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
              child: Icon(
                Icons.account_balance_wallet,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valoración Total del Inventario',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.formatCurrency(summary.totalInventoryValue),
                    style: Get.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Método: ${summary.valuationMethod} | ${controller.formatDate(summary.valuationDate)}',
                    style: Get.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatChip(
                  '${summary.totalProducts}',
                  'Productos',
                  Icons.inventory_2,
                ),
                const SizedBox(height: 8),
                _buildStatChip(
                  summary.totalQuantity.toStringAsFixed(0),
                  'Unidades',
                  Icons.format_list_numbered,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            children: [
              Text(
                value,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopValuedProducts() {
    return Obx(() {
      final summary = controller.valuationSummary.value!;
      if (summary.topValuedProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos con Mayor Valor',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children:
                    summary.topValuedProducts.take(10).map((product) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'SKU: ${product.productSku}',
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
                                  controller.formatCurrency(product.totalValue),
                                  style: Get.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${product.percentageOfTotalValue.toStringAsFixed(1)}%',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildValuationComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Comparación de Métodos',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => controller.loadValuationVariances(),
              icon: const Icon(Icons.compare_arrows, size: 16),
              label: const Text('Ver Diferencias'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMethodComparisonRow('FIFO', true),
                const Divider(),
                _buildMethodComparisonRow('LIFO', false),
                const Divider(),
                _buildMethodComparisonRow('Promedio Ponderado', false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodComparisonRow(String method, bool isSelected) {
    return Row(
      children: [
        Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            method,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
        if (isSelected)
          Obx(
            () => Text(
              controller.formatCurrency(
                controller.valuationSummary.value?.totalInventoryValue ?? 0,
              ),
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          )
        else
          TextButton(
            onPressed: () => _calculateWithMethod(method),
            child: const Text('Calcular'),
          ),
      ],
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
            'Error al cargar la valoración',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              controller.error.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos de valoración',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron datos para la fecha seleccionada.',
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

  void _calculateWithMethod(String method) {
    Get.snackbar(
      'Calculando',
      'Calculando valoración con método $method...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Resumen de Valoración'),
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
