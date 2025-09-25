// lib/features/reports/presentation/widgets/valuation_breakdown_charts.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_valuation_report.dart';

class ValuationBreakdownCharts extends StatefulWidget {
  final InventoryValuationSummary summary;

  const ValuationBreakdownCharts({
    super.key,
    required this.summary,
  });

  @override
  State<ValuationBreakdownCharts> createState() => _ValuationBreakdownChartsState();
}

class _ValuationBreakdownChartsState extends State<ValuationBreakdownCharts>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _getTabCount(),
      vsync: this,
    );
  }

  int _getTabCount() {
    int count = 1; // Always have overview
    if (widget.summary.categoryBreakdown != null && widget.summary.categoryBreakdown!.isNotEmpty) {
      count++;
    }
    if (widget.summary.warehouseBreakdown != null && widget.summary.warehouseBreakdown!.isNotEmpty) {
      count++;
    }
    return count;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        Card(
          child: Column(
            children: [
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: _buildTabs(),
                ),
              ),
              
              // Chart Content
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(text: 'Resumen General'),
    ];

    if (widget.summary.categoryBreakdown != null && widget.summary.categoryBreakdown!.isNotEmpty) {
      tabs.add(const Tab(text: 'Por Categorías'));
    }

    if (widget.summary.warehouseBreakdown != null && widget.summary.warehouseBreakdown!.isNotEmpty) {
      tabs.add(const Tab(text: 'Por Almacenes'));
    }

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _buildOverviewChart(),
    ];

    if (widget.summary.categoryBreakdown != null && widget.summary.categoryBreakdown!.isNotEmpty) {
      views.add(_buildCategoryChart());
    }

    if (widget.summary.warehouseBreakdown != null && widget.summary.warehouseBreakdown!.isNotEmpty) {
      views.add(_buildWarehouseChart());
    }

    return views;
  }

  Widget _buildOverviewChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Valoración',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Row(
              children: [
                // Pie chart representation
                Expanded(
                  flex: 2,
                  child: _buildSimplePieChart(),
                ),
                
                // Metrics
                Expanded(
                  flex: 3,
                  child: _buildOverviewMetrics(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (widget.summary.categoryBreakdown == null || widget.summary.categoryBreakdown!.isEmpty) {
      return const Center(child: Text('No hay datos de categorías'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valoración por Categorías',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildCategoryBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseChart() {
    if (widget.summary.warehouseBreakdown == null || widget.summary.warehouseBreakdown!.isEmpty) {
      return const Center(child: Text('No hay datos de almacenes'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valoración por Almacenes',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildWarehouseBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePieChart() {
    final total = widget.summary.totalInventoryValue;
    final categories = widget.summary.categoryBreakdown ?? [];
    
    if (categories.isEmpty) {
      return Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.primary,
              width: 8,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppFormatters.formatCurrency(total),
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Valor Total',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Simple circular representation
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(total),
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Total',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Legend
        const SizedBox(height: 16),
        _buildLegend(categories.take(5).toList()),
      ],
    );
  }

  Widget _buildLegend(List<CategoryValuationBreakdown> categories) {
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category.categoryId),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  category.categoryName,
                  style: Get.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricRow(
          'Valor Total',
          AppFormatters.formatCurrency(widget.summary.totalInventoryValue),
          Icons.account_balance_wallet,
          AppColors.primary,
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Total Productos',
          widget.summary.totalProducts.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Total Unidades',
          widget.summary.totalQuantity.toStringAsFixed(0),
          Icons.format_list_numbered,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Costo Promedio',
          AppFormatters.formatCurrency(widget.summary.averageCostPerUnit),
          Icons.attach_money,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Método',
          widget.summary.valuationMethod,
          Icons.calculate,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
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
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBars() {
    final categories = widget.summary.categoryBreakdown!;
    final maxValue = categories.isNotEmpty 
        ? categories.map((c) => c.totalValue).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final percentage = maxValue > 0 ? (category.totalValue / maxValue) : 0.0;
        final color = _getCategoryColor(category.categoryId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
                      category.categoryName,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(category.totalValue),
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${category.productCount} productos',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${category.percentageOfTotalValue.toStringAsFixed(1)}%',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarehouseBars() {
    final warehouses = widget.summary.warehouseBreakdown!;
    final maxValue = warehouses.isNotEmpty 
        ? warehouses.map((w) => w.totalValue).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return ListView.builder(
      itemCount: warehouses.length,
      itemBuilder: (context, index) {
        final warehouse = warehouses[index];
        final percentage = maxValue > 0 ? (warehouse.totalValue / maxValue) : 0.0;
        final color = _getWarehouseColor(warehouse.warehouseId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warehouse,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warehouse.warehouseName,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(warehouse.totalValue),
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${warehouse.productCount} productos',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${warehouse.percentageOfTotalValue.toStringAsFixed(1)}%',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String categoryId) {
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
    return colors[categoryId.hashCode % colors.length];
  }

  Color _getWarehouseColor(String warehouseId) {
    final colors = [
      AppColors.primary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[warehouseId.hashCode % colors.length];
  }
}