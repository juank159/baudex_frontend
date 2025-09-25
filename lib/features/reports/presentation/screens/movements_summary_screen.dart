// lib/features/reports/presentation/screens/movements_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';
import '../widgets/date_range_picker_widget.dart';

class MovementsSummaryScreen extends GetView<ReportsController> {
  const MovementsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlsSection(),
          Expanded(
            child: _buildContentSection(),
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
              Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Configuración de Análisis',
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
              Expanded(
                child: _buildMovementTypeDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWarehouseDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Tipo de Movimiento',
        prefixIcon: Icon(Icons.compare_arrows),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: '',
          child: Text('Todos los movimientos'),
        ),
        DropdownMenuItem<String>(
          value: 'IN',
          child: Text('Solo entradas'),
        ),
        DropdownMenuItem<String>(
          value: 'OUT',
          child: Text('Solo salidas'),
        ),
      ],
      onChanged: (value) {},
    );
  }

  Widget _buildWarehouseDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Almacén',
        prefixIcon: Icon(Icons.warehouse),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: '',
          child: Text('Todos los almacenes'),
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
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildMovementsByTypeChart(),
          const SizedBox(height: 24),
          _buildTopMovedProductsTable(),
          const SizedBox(height: 24),
          _buildMovementsTrendChart(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.indigo.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insights,
              size: 32,
              color: Colors.indigo.shade700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis de Movimientos',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estadísticas detalladas de entradas y salidas de inventario para optimizar la gestión de stock.',
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

  Widget _buildSummaryCards() {
    // Datos de ejemplo para demostración
    final summaryData = {
      'totalMovements': 1245,
      'inboundMovements': 678,
      'outboundMovements': 567,
      'netChange': 111,
    };

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Movimientos',
            value: summaryData['totalMovements'].toString(),
            icon: Icons.swap_horiz,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Entradas',
            value: summaryData['inboundMovements'].toString(),
            icon: Icons.call_received,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Salidas',
            value: summaryData['outboundMovements'].toString(),
            icon: Icons.call_made,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Cambio Neto',
            value: '+${summaryData['netChange']}',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ),
      ],
    );
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

  Widget _buildMovementsByTypeChart() {
    // Datos de ejemplo para demostración
    final movementTypes = [
      {'type': 'Compras', 'quantity': 45, 'color': Colors.green},
      {'type': 'Ventas', 'quantity': 38, 'color': Colors.blue},
      {'type': 'Ajustes', 'quantity': 12, 'color': Colors.orange},
      {'type': 'Transferencias', 'quantity': 18, 'color': Colors.purple},
      {'type': 'Devoluciones', 'quantity': 8, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movimientos por Tipo',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: movementTypes.map((movement) {
                final total = movementTypes.fold<int>(0, (sum, m) => sum + (m['quantity'] as int));
                final percentage = total > 0 ? (movement['quantity'] as int) / total : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: movement['color'] as Color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              movement['type'] as String,
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${movement['quantity']} (${(percentage * 100).toStringAsFixed(1)}%)',
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: movement['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppColors.borderColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(movement['color'] as Color),
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
  }

  Widget _buildTopMovedProductsTable() {
    // Datos de ejemplo para demostración
    final topProducts = [
      {'name': 'Producto A', 'sku': 'SKU001', 'inbound': 150, 'outbound': 120, 'net': 30},
      {'name': 'Producto B', 'sku': 'SKU002', 'inbound': 80, 'outbound': 95, 'net': -15},
      {'name': 'Producto C', 'sku': 'SKU003', 'inbound': 200, 'outbound': 180, 'net': 20},
      {'name': 'Producto D', 'sku': 'SKU004', 'inbound': 60, 'outbound': 45, 'net': 15},
      {'name': 'Producto E', 'sku': 'SKU005', 'inbound': 90, 'outbound': 110, 'net': -20},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Productos con Más Movimientos',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewAllProducts(),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Ver todos'),
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
                DataColumn(label: Text('Entradas')),
                DataColumn(label: Text('Salidas')),
                DataColumn(label: Text('Neto')),
                DataColumn(label: Text('Estado')),
              ],
              rows: topProducts.map((product) {
                final net = product['net'] as int;
                final isPositive = net >= 0;
                final netColor = isPositive ? Colors.green : Colors.red;

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product['name'] as String,
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        product['sku'] as String,
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        (product['inbound'] as int).toString(),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        (product['outbound'] as int).toString(),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        net.toString(),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: netColor,
                          fontWeight: FontWeight.bold,
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
                          color: netColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPositive ? 'Creciendo' : 'Decreciendo',
                          style: TextStyle(
                            color: netColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
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

  Widget _buildMovementsTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencia de Movimientos (Últimos 30 días)',
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
                    Icon(
                      Icons.trending_up,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Evolución Temporal',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Entradas', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Salidas', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Gráfico de tendencia de movimientos\n(Integración con librería de gráficos)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _exportMovementsReport() {
    Get.snackbar(
      'Exportar',
      'Generando reporte de movimientos...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  void _refreshReport() {
    Get.snackbar(
      'Actualizar',
      'Actualizando datos de movimientos...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  void _clearFilters() {
    Get.snackbar(
      'Filtros',
      'Filtros limpiados',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewAllProducts() {
    Get.snackbar(
      'Ver todos',
      'Navegando a lista completa de productos...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Resumen de Movimientos'),
      actions: [
        IconButton(
          onPressed: () => _exportMovementsReport(),
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