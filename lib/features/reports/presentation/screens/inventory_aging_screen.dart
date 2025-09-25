// lib/features/reports/presentation/screens/inventory_aging_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/reports_controller.dart';

class InventoryAgingScreen extends GetView<ReportsController> {
  const InventoryAgingScreen({super.key});

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
              Icon(Icons.schedule, color: AppColors.primary, size: 20),
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
                child: _buildDateSelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWarehouseDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAgingMethodDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _showDatePicker(),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de Análisis',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _formatDate(DateTime.now()),
          style: Get.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: '',
          child: Text('Todas las categorías'),
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

  Widget _buildAgingMethodDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Método de Análisis',
        prefixIcon: Icon(Icons.analytics),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: 'lastMovement',
          child: Text('Último movimiento'),
        ),
        DropdownMenuItem<String>(
          value: 'purchaseDate',
          child: Text('Fecha de compra'),
        ),
        DropdownMenuItem<String>(
          value: 'expirationDate',
          child: Text('Fecha de vencimiento'),
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
          _buildAgingSummaryCards(),
          const SizedBox(height: 24),
          _buildAgingBucketsChart(),
          const SizedBox(height: 24),
          _buildExpirationAlertsTable(),
          const SizedBox(height: 24),
          _buildDetailedAgingTable(),
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
            Colors.deepOrange.withOpacity(0.1),
            Colors.deepOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timer,
              size: 32,
              color: Colors.deepOrange.shade700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis de Antigüedad del Inventario',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Identifica productos con inventario obsoleto, próximos a vencer y optimiza la rotación de stock.',
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

  Widget _buildAgingSummaryCards() {
    // Datos de ejemplo para demostración
    final agingData = {
      'totalProducts': 2456,
      'nearExpiration': 45,
      'expired': 12,
      'slowMoving': 128,
    };

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Productos',
            value: agingData['totalProducts'].toString(),
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Próximos a Vencer',
            value: agingData['nearExpiration'].toString(),
            icon: Icons.warning_amber,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Vencidos',
            value: agingData['expired'].toString(),
            icon: Icons.dangerous,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Baja Rotación',
            value: agingData['slowMoving'].toString(),
            icon: Icons.slow_motion_video,
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

  Widget _buildAgingBucketsChart() {
    // Datos de ejemplo para demostración
    final agingBuckets = [
      {'range': '0-30 días', 'count': 1200, 'percentage': 48.8, 'color': Colors.green},
      {'range': '31-60 días', 'count': 650, 'percentage': 26.5, 'color': Colors.blue},
      {'range': '61-90 días', 'count': 380, 'percentage': 15.5, 'color': Colors.orange},
      {'range': '91-180 días', 'count': 180, 'percentage': 7.3, 'color': Colors.red},
      {'range': '+180 días', 'count': 46, 'percentage': 1.9, 'color': Colors.grey},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución por Antigüedad',
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
                      Icons.pie_chart,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Productos por Rango de Antigüedad',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: agingBuckets.map((bucket) {
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
                                  color: bucket['color'] as Color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  bucket['range'] as String,
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${bucket['count']} (${(bucket['percentage'] as double).toStringAsFixed(1)}%)',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: bucket['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (bucket['percentage'] as double) / 100,
                            backgroundColor: AppColors.borderColor.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(bucket['color'] as Color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationAlertsTable() {
    // Datos de ejemplo para demostración
    final expirationAlerts = [
      {
        'product': 'Medicina ABC',
        'sku': 'MED001',
        'batch': 'LT001',
        'daysToExpire': 5,
        'quantity': 25,
        'priority': 'Crítico'
      },
      {
        'product': 'Alimento XYZ',
        'sku': 'ALM002',
        'batch': 'LT002',
        'daysToExpire': 15,
        'quantity': 50,
        'priority': 'Alto'
      },
      {
        'product': 'Suplemento DEF',
        'sku': 'SUP003',
        'batch': 'LT003',
        'daysToExpire': 28,
        'quantity': 30,
        'priority': 'Medio'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Alertas de Vencimiento',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewAllExpirations(),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Ver todas'),
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
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Días al Vencer')),
                DataColumn(label: Text('Cantidad')),
                DataColumn(label: Text('Prioridad')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: expirationAlerts.map((alert) {
                final days = alert['daysToExpire'] as int;
                final priority = alert['priority'] as String;
                Color priorityColor;
                
                switch (priority) {
                  case 'Crítico':
                    priorityColor = Colors.red;
                    break;
                  case 'Alto':
                    priorityColor = Colors.orange;
                    break;
                  default:
                    priorityColor = Colors.yellow.shade700;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            alert['product'] as String,
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'SKU: ${alert['sku']}',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        alert['batch'] as String,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
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
                          color: days <= 7 
                              ? Colors.red.withOpacity(0.1)
                              : days <= 30
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.yellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$days días',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: days <= 7 
                                ? Colors.red 
                                : days <= 30
                                    ? Colors.orange
                                    : Colors.yellow.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${alert['quantity']} und.',
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _createDiscount(alert),
                            icon: const Icon(Icons.local_offer, size: 16),
                            tooltip: 'Crear descuento',
                          ),
                          IconButton(
                            onPressed: () => _adjustInventory(alert),
                            icon: const Icon(Icons.edit, size: 16),
                            tooltip: 'Ajustar inventario',
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
  }

  Widget _buildDetailedAgingTable() {
    // Datos de ejemplo para demostración
    final agingDetails = [
      {
        'product': 'Producto A',
        'sku': 'SKU001',
        'category': 'Categoría 1',
        'lastMovement': '2024-01-10',
        'daysIdle': 35,
        'quantity': 150,
        'value': 2500.00,
      },
      {
        'product': 'Producto B',
        'sku': 'SKU002',
        'category': 'Categoría 2',
        'lastMovement': '2024-01-05',
        'daysIdle': 40,
        'quantity': 80,
        'value': 1200.00,
      },
      {
        'product': 'Producto C',
        'sku': 'SKU003',
        'category': 'Categoría 1',
        'lastMovement': '2023-12-20',
        'daysIdle': 56,
        'quantity': 200,
        'value': 3000.00,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis Detallado de Antigüedad',
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
                DataColumn(label: Text('Producto')),
                DataColumn(label: Text('Categoría')),
                DataColumn(label: Text('Último Movimiento')),
                DataColumn(label: Text('Días Inactivo')),
                DataColumn(label: Text('Cantidad')),
                DataColumn(label: Text('Valor')),
                DataColumn(label: Text('Estado')),
              ],
              rows: agingDetails.map((item) {
                final days = item['daysIdle'] as int;
                Color statusColor;
                String status;
                
                if (days <= 30) {
                  statusColor = Colors.green;
                  status = 'Normal';
                } else if (days <= 60) {
                  statusColor = Colors.orange;
                  status = 'Atención';
                } else {
                  statusColor = Colors.red;
                  status = 'Crítico';
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['product'] as String,
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'SKU: ${item['sku']}',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        item['category'] as String,
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        item['lastMovement'] as String,
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        '$days días',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${item['quantity']} und.',
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${(item['value'] as double).toStringAsFixed(2)}',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
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
      Get.snackbar(
        'Fecha actualizada',
        'Análisis para ${_formatDate(date)}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _exportAgingReport() {
    Get.snackbar(
      'Exportar',
      'Generando reporte de antigüedad de inventario...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  void _refreshReport() {
    Get.snackbar(
      'Actualizar',
      'Actualizando análisis de antigüedad...',
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

  void _viewAllExpirations() {
    Get.snackbar(
      'Ver todas',
      'Navegando a lista completa de vencimientos...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _createDiscount(Map<String, dynamic> alert) {
    Get.snackbar(
      'Crear descuento',
      'Iniciando proceso de descuento para ${alert['product']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
    );
  }

  void _adjustInventory(Map<String, dynamic> alert) {
    Get.snackbar(
      'Ajustar inventario',
      'Iniciando ajuste de inventario para ${alert['product']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Análisis de Antigüedad'),
      actions: [
        IconButton(
          onPressed: () => _exportAgingReport(),
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