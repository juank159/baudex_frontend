// lib/features/reports/presentation/screens/valuation_products_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/valuation_method_selector.dart';

class ValuationProductsScreen extends GetView<ReportsController> {
  const ValuationProductsScreen({super.key});

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
                return const LoadingWidget(message: 'Cargando valoración por productos...');
              }

              if (controller.error.value.isNotEmpty) {
                return _buildErrorState();
              }

              if (controller.valuationByProducts.isEmpty) {
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
              Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
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
              Expanded(
                child: _buildDateSelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => ValuationMethodSelector(
                  selectedMethod: controller.valuationMethod.value,
                  onMethodChanged: controller.setValuationMethod,
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Obx(() => InkWell(
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
    ));
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
      ],
      onChanged: (value) => controller.setCategoryFilter(value ?? ''),
    ));
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildProductsTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final products = controller.valuationByProducts;
      final totalValue = products.fold(0.0, (sum, p) => sum + p.totalValue);
      final totalQuantity = products.fold(0.0, (sum, p) => sum + p.currentQuantity);
      final avgCost = products.isNotEmpty 
          ? products.fold(0.0, (sum, p) => sum + p.averageCost) / products.length
          : 0.0;

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Productos Valorados',
              value: products.length.toString(),
              icon: Icons.inventory_2,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Valor Total',
              value: controller.formatCurrency(totalValue),
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Cantidad Total',
              value: totalQuantity.toStringAsFixed(0),
              icon: Icons.format_list_numbered,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Costo Promedio',
              value: controller.formatCurrency(avgCost),
              icon: Icons.attach_money,
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

  Widget _buildProductsTable() {
    return Obx(() {
      final products = controller.valuationByProducts;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Valoración Detallada por Productos',
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text('${products.length} productos'),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Costo Unit.')),
                  DataColumn(label: Text('Valor Total')),
                  DataColumn(label: Text('Costo Prom.')),
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: products.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.productName,
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (product.warehouseName != null)
                                Text(
                                  product.warehouseName!,
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          product.productSku,
                          style: Get.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          product.currentQuantity.toStringAsFixed(2),
                          style: Get.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          controller.formatCurrency(product.unitCost),
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.formatCurrency(product.totalValue),
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          controller.formatCurrency(product.averageCost),
                          style: Get.textTheme.bodyMedium,
                        ),
                      ),
                      DataCell(
                        Text(
                          product.categoryName ?? 'Sin categoría',
                          style: Get.textTheme.bodySmall,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showProductDetails(product),
                              icon: const Icon(Icons.visibility, size: 16),
                              tooltip: 'Ver detalles',
                            ),
                            if (product.batches != null && product.batches!.isNotEmpty)
                              IconButton(
                                onPressed: () => _showBatchDetails(product),
                                icon: const Icon(Icons.inventory, size: 16),
                                tooltip: 'Ver lotes',
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showProductDetails(product) {
    Get.dialog(
      AlertDialog(
        title: Text('Valoración de ${product.productName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SKU', product.productSku),
              _buildDetailRow('Categoría', product.categoryName ?? 'Sin categoría'),
              _buildDetailRow('Almacén', product.warehouseName ?? 'Todos'),
              const Divider(),
              _buildDetailRow('Método de Valoración', product.valuationMethod),
              _buildDetailRow('Fecha de Valoración', controller.formatDate(product.asOfDate)),
              const Divider(),
              _buildDetailRow('Cantidad Actual', product.currentQuantity.toStringAsFixed(2)),
              _buildDetailRow('Costo Unitario', controller.formatCurrency(product.unitCost)),
              _buildDetailRow('Valor Total', controller.formatCurrency(product.totalValue)),
              _buildDetailRow('Costo Promedio', controller.formatCurrency(product.averageCost)),
              if (product.lastPurchaseDate != null) ...[
                const Divider(),
                _buildDetailRow('Última Compra', controller.formatDate(product.lastPurchaseDate!)),
                if (product.lastPurchaseCost != null)
                  _buildDetailRow('Último Costo', controller.formatCurrency(product.lastPurchaseCost!)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBatchDetails(product) {
    Get.dialog(
      AlertDialog(
        title: Text('Lotes de ${product.productName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: product.batches?.length ?? 0,
            itemBuilder: (context, index) {
              final batch = product.batches![index];
              return Card(
                child: ListTile(
                  title: Text('Lote: ${batch.batchNumber}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad: ${batch.quantity.toStringAsFixed(2)}'),
                      Text('Valor: ${controller.formatCurrency(batch.totalValue)}'),
                      if (batch.expirationDate != null)
                        Text('Vence: ${controller.formatDate(batch.expirationDate!)}'),
                    ],
                  ),
                  trailing: Text(
                    controller.formatCurrency(batch.unitCost),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Get.textTheme.bodyMedium),
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
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
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos para valorar',
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
      title: const Text('Valoración por Productos'),
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