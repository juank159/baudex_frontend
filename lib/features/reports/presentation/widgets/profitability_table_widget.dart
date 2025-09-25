// lib/features/reports/presentation/widgets/profitability_table_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/profitability_report.dart';

class ProfitabilityTableWidget extends StatefulWidget {
  final List<ProfitabilityReport> reports;
  final Function(String)? onProductTap;

  const ProfitabilityTableWidget({
    super.key,
    required this.reports,
    this.onProductTap,
  });

  @override
  State<ProfitabilityTableWidget> createState() => _ProfitabilityTableWidgetState();
}

class _ProfitabilityTableWidgetState extends State<ProfitabilityTableWidget> {
  String _sortColumn = 'grossProfit';
  bool _sortAscending = false;
  List<ProfitabilityReport> _sortedReports = [];

  @override
  void initState() {
    super.initState();
    _updateSortedReports();
  }

  @override
  void didUpdateWidget(ProfitabilityTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reports != widget.reports) {
      _updateSortedReports();
    }
  }

  void _updateSortedReports() {
    _sortedReports = List.from(widget.reports);
    _sortReports();
  }

  void _sortReports() {
    _sortedReports.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (_sortColumn) {
        case 'productName':
          aValue = a.productName;
          bValue = b.productName;
          break;
        case 'totalRevenue':
          aValue = a.totalRevenue;
          bValue = b.totalRevenue;
          break;
        case 'totalCost':
          aValue = a.totalCost;
          bValue = b.totalCost;
          break;
        case 'grossProfit':
          aValue = a.grossProfit;
          bValue = b.grossProfit;
          break;
        case 'grossMarginPercentage':
          aValue = a.grossMarginPercentage;
          bValue = b.grossMarginPercentage;
          break;
        case 'unitsSold':
          aValue = a.unitsSold;
          bValue = b.unitsSold;
          break;
        case 'averageSellingPrice':
          aValue = a.averageSellingPrice;
          bValue = b.averageSellingPrice;
          break;
        case 'rotationRate':
          aValue = a.rotationRate;
          bValue = b.rotationRate;
          break;
        default:
          aValue = a.grossProfit;
          bValue = b.grossProfit;
      }

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
      _sortReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay datos para mostrar',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Análisis de Rentabilidad',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_sortedReports.length} productos'),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ],
            ),
          ),
          
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _getSortColumnIndex(),
                  sortAscending: _sortAscending,
                  columns: [
                    DataColumn(
                      label: const Text('Producto'),
                      onSort: (columnIndex, ascending) => _onSort('productName'),
                    ),
                    DataColumn(
                      label: const Text('SKU'),
                    ),
                    DataColumn(
                      label: const Text('Categoría'),
                    ),
                    DataColumn(
                      label: const Text('Ingresos'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('totalRevenue'),
                    ),
                    DataColumn(
                      label: const Text('Costos'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('totalCost'),
                    ),
                    DataColumn(
                      label: const Text('Ganancia'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('grossProfit'),
                    ),
                    DataColumn(
                      label: const Text('Margen %'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('grossMarginPercentage'),
                    ),
                    DataColumn(
                      label: const Text('Unidades'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('unitsSold'),
                    ),
                    DataColumn(
                      label: const Text('Precio Prom.'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('averageSellingPrice'),
                    ),
                    DataColumn(
                      label: const Text('Rotación'),
                      numeric: true,
                      onSort: (columnIndex, ascending) => _onSort('rotationRate'),
                    ),
                    const DataColumn(
                      label: Text('Acciones'),
                    ),
                  ],
                  rows: _sortedReports.map((report) {
                    final isPositiveMargin = report.grossMarginPercentage > 0;
                    final marginColor = isPositiveMargin ? Colors.green : Colors.red;
                    
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
                                  report.productName,
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (report.warehouseName != null)
                                  Text(
                                    report.warehouseName!,
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: widget.onProductTap != null 
                              ? () => widget.onProductTap!(report.productId)
                              : null,
                        ),
                        DataCell(
                          Text(
                            report.productSku,
                            style: Get.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            report.categoryName ?? 'Sin categoría',
                            style: Get.textTheme.bodySmall,
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.formatCurrency(report.totalRevenue),
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.formatCurrency(report.totalCost),
                            style: Get.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade700,
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
                              color: marginColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppFormatters.formatCurrency(report.grossProfit),
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: marginColor,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositiveMargin ? Icons.trending_up : Icons.trending_down,
                                size: 16,
                                color: marginColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${report.grossMarginPercentage.toStringAsFixed(1)}%',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: marginColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            report.unitsSold.toString(),
                            style: Get.textTheme.bodyMedium,
                          ),
                        ),
                        DataCell(
                          Text(
                            AppFormatters.formatCurrency(report.averageSellingPrice),
                            style: Get.textTheme.bodyMedium,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${report.rotationRate.toStringAsFixed(2)}x',
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showProductDetails(report),
                                icon: const Icon(Icons.visibility, size: 16),
                                tooltip: 'Ver detalles',
                              ),
                              IconButton(
                                onPressed: () => _exportProductReport(report),
                                icon: const Icon(Icons.file_download, size: 16),
                                tooltip: 'Exportar',
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
          ),
        ],
      ),
    );
  }

  int _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'productName': return 0;
      case 'totalRevenue': return 3;
      case 'totalCost': return 4;
      case 'grossProfit': return 5;
      case 'grossMarginPercentage': return 6;
      case 'unitsSold': return 7;
      case 'averageSellingPrice': return 8;
      case 'rotationRate': return 9;
      default: return 5;
    }
  }

  void _showProductDetails(ProfitabilityReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${report.productName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SKU', report.productSku),
              _buildDetailRow('Categoría', report.categoryName ?? 'Sin categoría'),
              _buildDetailRow('Almacén', report.warehouseName ?? 'Todos'),
              const Divider(),
              _buildDetailRow('Período', '${AppFormatters.formatDate(report.periodStart)} - ${AppFormatters.formatDate(report.periodEnd)}'),
              const Divider(),
              _buildDetailRow('Ingresos Totales', AppFormatters.formatCurrency(report.totalRevenue)),
              _buildDetailRow('Costos Totales', AppFormatters.formatCurrency(report.totalCost)),
              _buildDetailRow('Ganancia Bruta', AppFormatters.formatCurrency(report.grossProfit)),
              _buildDetailRow('Margen de Ganancia', '${report.grossMarginPercentage.toStringAsFixed(2)}%'),
              const Divider(),
              _buildDetailRow('Unidades Vendidas', report.unitsSold.toString()),
              _buildDetailRow('Precio Promedio', AppFormatters.formatCurrency(report.averageSellingPrice)),
              _buildDetailRow('Costo Promedio', AppFormatters.formatCurrency(report.averageCost)),
              _buildDetailRow('Tasa de Rotación', '${report.rotationRate.toStringAsFixed(2)}x'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onProductTap != null) {
                widget.onProductTap!(report.productId);
              }
            },
            child: const Text('Ver Producto'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
              value,
              style: Get.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _exportProductReport(ProfitabilityReport report) {
    Get.snackbar(
      'Exportar',
      'Exportando reporte de ${report.productName}...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }
}