// lib/features/reports/presentation/widgets/profitability_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/profitability_report.dart';

class ProfitabilityChartWidget extends StatefulWidget {
  final List<ProfitabilityReport> reports;

  const ProfitabilityChartWidget({
    super.key,
    required this.reports,
  });

  @override
  State<ProfitabilityChartWidget> createState() => _ProfitabilityChartWidgetState();
}

class _ProfitabilityChartWidgetState extends State<ProfitabilityChartWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
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
              tabs: const [
                Tab(text: 'Ingresos vs Costos'),
                Tab(text: 'Márgenes de Ganancia'),
                Tab(text: 'Top 10 Productos'),
              ],
            ),
          ),
          
          // Chart Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRevenueCostChart(),
                _buildMarginChart(),
                _buildTopProductsChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCostChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparación de Ingresos vs Costos',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleBarChart(
              data: widget.reports.take(10).map((report) => {
                'name': report.productName.length > 15 
                    ? '${report.productName.substring(0, 15)}...'
                    : report.productName,
                'revenue': report.totalRevenue,
                'cost': report.totalCost,
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Márgenes de Ganancia por Producto',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMarginBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart() {
    final topProducts = widget.reports
        .where((r) => r.grossProfit > 0)
        .toList()
      ..sort((a, b) => b.grossProfit.compareTo(a.grossProfit));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 10 Productos Más Rentables',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: topProducts.take(10).length,
              itemBuilder: (context, index) {
                final product = topProducts[index];
                final maxProfit = topProducts.first.grossProfit;
                final percentage = (product.grossProfit / maxProfit);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getColorForIndex(index),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                  '${AppFormatters.formatCurrency(product.grossProfit)} (${product.grossMarginPercentage.toStringAsFixed(1)}%)',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppColors.borderColor,
                        valueColor: AlwaysStoppedAnimation(_getColorForIndex(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart({required List<Map<String, dynamic>> data}) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.fold<double>(0, (max, item) {
      final revenue = item['revenue'] as double;
      final cost = item['cost'] as double;
      return [max, revenue, cost].reduce((a, b) => a > b ? a : b);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final revenue = item['revenue'] as double;
          final cost = item['cost'] as double;
          final name = item['name'] as String;

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Revenue bar
                      Container(
                        width: 25,
                        height: (revenue / maxValue) * 250,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Cost bar
                      Container(
                        width: 25,
                        height: (cost / maxValue) * 250,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: Get.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarginBars() {
    final sortedReports = widget.reports.toList()
      ..sort((a, b) => b.grossMarginPercentage.compareTo(a.grossMarginPercentage));

    return ListView.builder(
      itemCount: sortedReports.take(15).length,
      itemBuilder: (context, index) {
        final report = sortedReports[index];
        final isPositive = report.grossMarginPercentage > 0;
        final barColor = isPositive ? Colors.green : Colors.red;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  report.productName.length > 15 
                      ? '${report.productName.substring(0, 15)}...'
                      : report.productName,
                  style: Get.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (report.grossMarginPercentage.abs() / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  '${report.grossMarginPercentage.toStringAsFixed(1)}%',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForIndex(int index) {
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
}