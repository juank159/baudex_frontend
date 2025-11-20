// lib/features/reports/presentation/screens/kardex_multi_product_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/date_range_picker_widget.dart';

class KardexMultiProductScreen extends GetView<ReportsController> {
  const KardexMultiProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlsSection(),
          Expanded(child: _buildContentSection()),
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
              Icon(Icons.timeline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Configuración de Kardex',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _clearFilters(),
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
                child: DateRangePickerWidget(
                  startDate: DateTime.now().subtract(const Duration(days: 30)),
                  endDate: DateTime.now(),
                  onDateRangeChanged: (start, end) {},
                  label: 'Período de Análisis',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildProductSelector()),
              const SizedBox(width: 16),
              Expanded(child: _buildCategoryDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Buscar Productos',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        hintText: 'Escriba para buscar...',
      ),
      onChanged: (value) {
        // TODO: Implement product search
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
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
      onChanged: (value) {},
    );
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildSelectedProductsList(),
          const SizedBox(height: 24),
          _buildKardexComparison(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.compare_arrows,
              size: 32,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kardex Comparativo',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Compare movimientos de inventario entre múltiples productos para identificar tendencias y patrones.',
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
  }

  Widget _buildSelectedProductsList() {
    // Datos de ejemplo para demostración
    final selectedProducts = [
      {'name': 'Producto A', 'sku': 'SKU001', 'category': 'Categoría 1'},
      {'name': 'Producto B', 'sku': 'SKU002', 'category': 'Categoría 2'},
      {'name': 'Producto C', 'sku': 'SKU003', 'category': 'Categoría 1'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Productos Seleccionados',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showProductPicker(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar Producto'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (selectedProducts.isEmpty)
          _buildEmptyProductsState()
        else
          _buildProductsGrid(selectedProducts),
      ],
    );
  }

  Widget _buildEmptyProductsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay productos seleccionados',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agregue productos para comparar sus movimientos de inventario.',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showProductPicker(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Productos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Map<String, String>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product['name']!,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product['sku']!,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Remover',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKardexComparison() {
    // Datos de ejemplo para demostración
    final movements = [
      {
        'date': '2024-01-15',
        'type': 'Entrada',
        'productA': 100,
        'productB': 50,
        'productC': 75,
      },
      {
        'date': '2024-01-16',
        'type': 'Salida',
        'productA': -20,
        'productB': -15,
        'productC': -10,
      },
      {
        'date': '2024-01-17',
        'type': 'Entrada',
        'productA': 50,
        'productB': 30,
        'productC': 25,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparación de Movimientos',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Producto A')),
                DataColumn(label: Text('Producto B')),
                DataColumn(label: Text('Producto C')),
                DataColumn(label: Text('Total')),
              ],
              rows:
                  movements.map((movement) {
                    final productA = movement['productA'] as int;
                    final productB = movement['productB'] as int;
                    final productC = movement['productC'] as int;
                    final total = productA + productB + productC;
                    final isInbound = movement['type'] == 'Entrada';

                    return DataRow(
                      cells: [
                        DataCell(Text(movement['date'] as String)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isInbound
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movement['type'] as String,
                              style: TextStyle(
                                color: isInbound ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_buildMovementCell(productA)),
                        DataCell(_buildMovementCell(productB)),
                        DataCell(_buildMovementCell(productC)),
                        DataCell(
                          Text(
                            total.toString(),
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: total >= 0 ? Colors.green : Colors.red,
                            ),
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
  }

  Widget _buildMovementCell(int value) {
    final isPositive = value >= 0;
    return Text(
      value.toString(),
      style: Get.textTheme.bodyMedium?.copyWith(
        color: isPositive ? Colors.green : Colors.red,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showProductPicker() {
    Get.dialog(
      AlertDialog(
        title: const Text('Seleccionar Productos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar productos',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // TODO: Filter products
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 10, // Ejemplo
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text('Producto ${index + 1}'),
                      subtitle: Text(
                        'SKU${(index + 1).toString().padLeft(3, '0')}',
                      ),
                      value: false,
                      onChanged: (value) {
                        // TODO: Handle selection
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Add selected products
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeProduct(int index) {
    // TODO: Remove product from selection
  }

  void _exportKardexReport() {
    Get.snackbar(
      'Exportar',
      'Generando reporte de Kardex multi-producto...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  void _refreshReport() {
    Get.snackbar(
      'Actualizar',
      'Actualizando datos del Kardex...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  void _clearFilters() {
    Get.snackbar(
      'Filtros',
      'Filtros limpiados',
      snackPosition: SnackPosition.TOP,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Kardex Multi-Producto'),
      actions: [
        IconButton(
          onPressed: () => _exportKardexReport(),
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar',
        ),
        IconButton(
          onPressed: () => _refreshReport(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}
