// lib/features/invoices/presentation/screens/invoice_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_stats_controller.dart';
import '../widgets/invoice_stats_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceStatsScreen extends StatelessWidget {
  const InvoiceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: GetBuilder<InvoiceStatsController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Cargando estadísticas...');
          }

          if (!controller.hasStats) {
            return _buildErrorState(context, controller);
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, controller),
            tablet: _buildTabletLayout(context, controller),
            desktop: _buildDesktopLayout(context, controller),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Estadísticas de Facturas'),
      elevation: 0,
      actions: [
        // Selector de período
        GetBuilder<InvoiceStatsController>(
          builder:
              (controller) => PopupMenuButton<StatsPeriod>(
                icon: const Icon(Icons.date_range),
                onSelected: controller.changePeriod,
                itemBuilder:
                    (context) =>
                        StatsPeriod.values
                            .map(
                              (period) => PopupMenuItem(
                                value: period,
                                child: Row(
                                  children: [
                                    Icon(
                                      controller.selectedPeriod == period
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(period.displayName),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
              ),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => Get.find<InvoiceStatsController>().refreshAllData(),
          tooltip: 'Actualizar datos',
        ),

        // Exportar
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _showExportOptions(context),
          tooltip: 'Exportar estadísticas',
        ),

        // Más opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Imprimir Reporte'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Configuración'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          children: [
            // Selector de período
            _buildPeriodSelector(context, controller),
            SizedBox(height: context.verticalSpacing),

            // Resumen general
            const InvoiceStatsWidget(showHeader: false),
            SizedBox(height: context.verticalSpacing),

            // Gráfico de estado
            _buildStatusChart(context, controller),
            SizedBox(height: context.verticalSpacing),

            // Gráfico de montos
            _buildAmountChart(context, controller),
            SizedBox(height: context.verticalSpacing),

            // Indicadores de rendimiento
            _buildPerformanceIndicators(context, controller),
            SizedBox(height: context.verticalSpacing),

            // Facturas vencidas
            if (controller.hasOverdueInvoices)
              _buildOverdueSection(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          maxWidth: 1000,
          child: Column(
            children: [
              SizedBox(height: context.verticalSpacing),

              // Selector de período
              _buildPeriodSelector(context, controller),
              SizedBox(height: context.verticalSpacing),

              // Resumen general
              const InvoiceStatsWidget(showHeader: false),
              SizedBox(height: context.verticalSpacing),

              // Gráficos en fila
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStatusChart(context, controller)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAmountChart(context, controller)),
                ],
              ),
              SizedBox(height: context.verticalSpacing),

              // Indicadores y facturas vencidas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPerformanceIndicators(context, controller),
                  ),
                  if (controller.hasOverdueInvoices) ...[
                    const SizedBox(width: 16),
                    Expanded(child: _buildOverdueSection(context, controller)),
                  ],
                ],
              ),
              SizedBox(height: context.verticalSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Row(
      children: [
        // Panel lateral izquierdo
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Panel de Control',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPeriodSelector(context, controller),
                      const SizedBox(height: 20),
                      _buildQuickActions(context, controller),
                      const SizedBox(height: 20),
                      _buildPerformanceIndicators(context, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshAllData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Resumen general
                  const InvoiceStatsWidget(showHeader: false),
                  const SizedBox(height: 32),

                  // Gráficos principales
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildStatusChart(context, controller),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildAmountChart(context, controller)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tendencias y análisis
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.hasOverdueInvoices) ...[
                        Expanded(
                          child: _buildOverdueSection(context, controller),
                        ),
                        const SizedBox(width: 24),
                      ],
                      Expanded(
                        child: _buildTrendsAnalysis(context, controller),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== COMPONENTS ====================

  Widget _buildPeriodSelector(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return GetBuilder<InvoiceStatsController>(
      builder:
          (controller) => CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período de Análisis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        StatsPeriod.values
                            .map(
                              (period) => ChoiceChip(
                                label: Text(period.displayName),
                                selected: controller.selectedPeriod == period,
                                onSelected:
                                    (_) => controller.changePeriod(period),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatusChart(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(controller),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch events
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(controller.getStatusChartData()),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChart(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Montos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _buildBarGroups(controller),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${_formatCurrency(value)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Cobrado', 'Pendiente', 'Vencido'];
                          if (value.toInt() < titles.length) {
                            return Text(
                              titles[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores de Rendimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...controller.getPerformanceIndicators().map(
              (indicator) => _buildIndicatorRow(context, indicator),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(
    BuildContext context,
    PerformanceIndicator indicator,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(indicator.icon, size: 20, color: indicator.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  indicator.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                indicator.displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: indicator.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (indicator.value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(indicator.color),
          ),
          const SizedBox(height: 4),
          Text(
            'Meta: ${indicator.targetText}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueSection(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Facturas Vencidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Ver Todas',
                  type: ButtonType.outline,
                  onPressed: controller.goToOverdueInvoices,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.overdueInvoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('¡No hay facturas vencidas!'),
                  ],
                ),
              )
            else
              Column(
                children:
                    controller.overdueInvoices
                        .take(5)
                        .map((invoice) => _buildOverdueInvoiceItem(invoice))
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueInvoiceItem(Invoice invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  invoice.customerName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${invoice.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              Text(
                '${invoice.daysOverdue} días',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Nueva Factura',
              icon: Icons.add,
              onPressed: controller.goToCreateInvoice,
              width: double.infinity,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Ver Facturas',
              icon: Icons.list,
              type: ButtonType.outline,
              onPressed: () => controller.goToInvoiceList(),
              width: double.infinity,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Exportar Datos',
              icon: Icons.download,
              type: ButtonType.outline,
              onPressed: () => _showExportOptions(context),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsAnalysis(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis de Tendencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              'Estado de Salud Financiera',
              controller.getHealthMessage(),
              controller.getHealthIcon(),
              controller.getHealthColor(),
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              'Tasa de Cobro',
              '${controller.collectionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              controller.collectionRate >= 85 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              'Facturas Activas',
              '${controller.activeInvoices} facturas',
              Icons.receipt,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(List<ChartData> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          data
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.label} (${item.value.toInt()})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )
              .toList(),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar los datos estadísticos',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Reintentar',
            icon: Icons.refresh,
            onPressed: controller.refreshAllData,
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (!context.isMobile) return null;

    return FloatingActionButton.extended(
      onPressed: () => Get.find<InvoiceStatsController>().goToCreateInvoice(),
      icon: const Icon(Icons.add),
      label: const Text('Nueva Factura'),
    );
  }

  // ==================== CHART DATA HELPERS ====================

  List<PieChartSectionData> _buildPieChartSections(
    InvoiceStatsController controller,
  ) {
    final data = controller.getStatusChartData();
    return data
        .asMap()
        .entries
        .map(
          (entry) => PieChartSectionData(
            value: entry.value.value,
            title: '${entry.value.value.toInt()}',
            color: entry.value.color,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _buildBarGroups(InvoiceStatsController controller) {
    final data = controller.getAmountChartData();
    return data
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: entry.value.color,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        )
        .toList();
  }

  // ==================== EVENT HANDLERS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'print':
        _showInfo('Próximamente', 'Función de impresión en desarrollo');
        break;
      case 'share':
        _showInfo('Próximamente', 'Función de compartir en desarrollo');
        break;
      case 'settings':
        Get.toNamed('/settings/invoices');
        break;
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Exportar Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Exportar como PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfo('Próximamente', 'Exportación PDF en desarrollo');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Exportar como Excel'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfo(
                      'Próximamente',
                      'Exportación Excel en desarrollo',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Exportar gráficos como imagen'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfo(
                      'Próximamente',
                      'Exportación de imagen en desarrollo',
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  // ==================== UTILS ====================

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
    );
  }
}


// // lib/features/invoices/presentation/screens/invoice_stats_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_button.dart';
// import '../../../../app/shared/widgets/custom_card.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/invoice_stats_controller.dart';
// import '../widgets/invoice_stats_widget.dart';
// import '../../domain/entities/invoice.dart';

// class InvoiceStatsScreen extends StatelessWidget {
//   const InvoiceStatsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: GetBuilder<InvoiceStatsController>(
//         builder: (controller) {
//           if (controller.isLoading) {
//             return _buildLoadingState(context);
//           }

//           if (controller.hasError) {
//             return _buildErrorState(context, controller);
//           }

//           if (!controller.hasStats) {
//             return _buildErrorState(context, controller);
//           }

//           return ResponsiveLayout(
//             mobile: _buildMobileLayout(context, controller),
//             tablet: _buildTabletLayout(context, controller),
//             desktop: _buildDesktopLayout(context, controller),
//           );
//         },
//       ),
//       floatingActionButton: _buildFloatingActionButton(context),
//     );
//   }

//   // ==================== LOADING & ERROR STATES ====================

//   Widget _buildLoadingState(BuildContext context) {
//     return Center(
//       child: Container(
//         padding: context.responsivePadding,
//         child: const LoadingWidget(
//           message: 'Cargando estadísticas...',
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return Center(
//       child: Container(
//         padding: context.responsivePadding,
//         constraints: const BoxConstraints(maxWidth: 400),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: context.isMobile ? 64 : 80,
//               color: Colors.red.shade400,
//             ),
//             SizedBox(height: context.verticalSpacing),
//             Text(
//               'Error al cargar estadísticas',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 18 : 22,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.red.shade700,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: context.verticalSpacing / 2),
//             Text(
//               controller.hasError 
//                 ? controller.errorMessage 
//                 : 'No se pudieron cargar los datos estadísticos',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: context.isMobile ? 14 : 16,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: context.verticalSpacing * 1.5),
//             CustomButton(
//               text: 'Reintentar',
//               icon: Icons.refresh,
//               onPressed: controller.refreshAllData,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== APP BAR ====================

//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       title: const Text('Estadísticas de Facturas'),
//       elevation: 0,
//       actions: [
//         // Selector de período
//         GetBuilder<InvoiceStatsController>(
//           builder: (controller) => PopupMenuButton<StatsPeriod>(
//             icon: const Icon(Icons.date_range),
//             onSelected: controller.changePeriod,
//             itemBuilder: (context) =>
//                 StatsPeriod.values
//                     .map(
//                       (period) => PopupMenuItem(
//                         value: period,
//                         child: Row(
//                           children: [
//                             Icon(
//                               controller.selectedPeriod == period
//                                   ? Icons.check_circle
//                                   : Icons.circle_outlined,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(period.displayName),
//                           ],
//                         ),
//                       ),
//                     )
//                     .toList(),
//           ),
//         ),

//         // Refrescar
//         IconButton(
//           icon: const Icon(Icons.refresh),
//           onPressed: () => Get.find<InvoiceStatsController>().refreshAllData(),
//           tooltip: 'Actualizar datos',
//         ),

//         // Exportar
//         IconButton(
//           icon: const Icon(Icons.download),
//           onPressed: () => _showExportOptions(context),
//           tooltip: 'Exportar estadísticas',
//         ),

//         // Más opciones
//         PopupMenuButton<String>(
//           onSelected: (value) => _handleMenuAction(value, context),
//           itemBuilder: (context) => [
//             const PopupMenuItem(
//               value: 'print',
//               child: Row(
//                 children: [
//                   Icon(Icons.print),
//                   SizedBox(width: 8),
//                   Text('Imprimir Reporte'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'share',
//               child: Row(
//                 children: [
//                   Icon(Icons.share),
//                   SizedBox(width: 8),
//                   Text('Compartir'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'settings',
//               child: Row(
//                 children: [
//                   Icon(Icons.settings),
//                   SizedBox(width: 8),
//                   Text('Configuración'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ==================== RESPONSIVE LAYOUTS ====================

//   Widget _buildMobileLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return RefreshIndicator(
//       onRefresh: controller.refreshAllData,
//       child: SingleChildScrollView(
//         padding: context.responsivePadding,
//         child: Column(
//           children: [
//             // Selector de período
//             _buildPeriodSelector(context, controller),
//             SizedBox(height: context.verticalSpacing),

//             // Resumen general usando el widget
//             const InvoiceStatsWidget(showHeader: false),
//             SizedBox(height: context.verticalSpacing),

//             // Gráfico de estado
//             _buildStatusChart(context, controller),
//             SizedBox(height: context.verticalSpacing),

//             // Gráfico de montos
//             _buildAmountChart(context, controller),
//             SizedBox(height: context.verticalSpacing),

//             // Indicadores de rendimiento
//             _buildPerformanceIndicators(context, controller),
            
//             // Facturas vencidas (si las hay)
//             if (controller.hasOverdueInvoices) ...[
//               SizedBox(height: context.verticalSpacing),
//               _buildOverdueSection(context, controller),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabletLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return RefreshIndicator(
//       onRefresh: controller.refreshAllData,
//       child: SingleChildScrollView(
//         child: AdaptiveContainer(
//           maxWidth: 1000,
//           child: Column(
//             children: [
//               SizedBox(height: context.verticalSpacing),

//               // Selector de período
//               _buildPeriodSelector(context, controller),
//               SizedBox(height: context.verticalSpacing),

//               // Resumen general
//               const InvoiceStatsWidget(showHeader: false),
//               SizedBox(height: context.verticalSpacing),

//               // Gráficos en fila
//               IntrinsicHeight(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(child: _buildStatusChart(context, controller)),
//                     SizedBox(width: context.horizontalSpacing),
//                     Expanded(child: _buildAmountChart(context, controller)),
//                   ],
//                 ),
//               ),
//               SizedBox(height: context.verticalSpacing),

//               // Indicadores y facturas vencidas
//               IntrinsicHeight(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       child: _buildPerformanceIndicators(context, controller),
//                     ),
//                     if (controller.hasOverdueInvoices) ...[
//                       SizedBox(width: context.horizontalSpacing),
//                       Expanded(child: _buildOverdueSection(context, controller)),
//                     ],
//                   ],
//                 ),
//               ),
//               SizedBox(height: context.verticalSpacing),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDesktopLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return Row(
//       children: [
//         // Panel lateral izquierdo
//         Container(
//           width: 300,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             border: Border(right: BorderSide(color: Colors.grey.shade300)),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   border: Border(
//                     bottom: BorderSide(color: Colors.grey.shade300),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.analytics,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Panel de Control',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       _buildPeriodSelector(context, controller),
//                       const SizedBox(height: 20),
//                       _buildQuickActions(context, controller),
//                       const SizedBox(height: 20),
//                       _buildPerformanceIndicators(context, controller),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Contenido principal
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: controller.refreshAllData,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 children: [
//                   // Resumen general
//                   const InvoiceStatsWidget(showHeader: false),
//                   const SizedBox(height: 32),

//                   // Gráficos principales
//                   IntrinsicHeight(
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: _buildStatusChart(context, controller),
//                         ),
//                         const SizedBox(width: 24),
//                         Expanded(child: _buildAmountChart(context, controller)),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Tendencias y análisis
//                   IntrinsicHeight(
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         if (controller.hasOverdueInvoices) ...[
//                           Expanded(
//                             child: _buildOverdueSection(context, controller),
//                           ),
//                           const SizedBox(width: 24),
//                         ],
//                         Expanded(
//                           child: _buildTrendsAnalysis(context, controller),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ==================== COMPONENTS ====================

//   Widget _buildPeriodSelector(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return GetBuilder<InvoiceStatsController>(
//       builder: (controller) => CustomCard(
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Período de Análisis',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: StatsPeriod.values
//                     .map(
//                       (period) => ChoiceChip(
//                         label: Text(period.displayName),
//                         selected: controller.selectedPeriod == period,
//                         onSelected: (_) => controller.changePeriod(period),
//                       ),
//                     )
//                     .toList(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusChart(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Distribución por Estado',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: controller.getStatusChartData().isNotEmpty
//                   ? PieChart(
//                       PieChartData(
//                         sections: _buildPieChartSections(controller),
//                         centerSpaceRadius: 40,
//                         sectionsSpace: 2,
//                         pieTouchData: PieTouchData(
//                           touchCallback: (FlTouchEvent event, pieTouchResponse) {
//                             // Handle touch events
//                           },
//                         ),
//                       ),
//                     )
//                   : const Center(
//                       child: Text(
//                         'Sin datos para mostrar',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 16),
//             _buildLegend(controller.getStatusChartData()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAmountChart(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Distribución de Montos',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: controller.getAmountChartData().isNotEmpty
//                   ? BarChart(
//                       BarChartData(
//                         barGroups: _buildBarGroups(controller),
//                         titlesData: FlTitlesData(
//                           leftTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               reservedSize: 60,
//                               getTitlesWidget: (value, meta) {
//                                 return Text(
//                                   '\$${_formatCurrency(value)}',
//                                   style: const TextStyle(fontSize: 10),
//                                 );
//                               },
//                             ),
//                           ),
//                           bottomTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               getTitlesWidget: (value, meta) {
//                                 const titles = ['Cobrado', 'Pendiente', 'Vencido'];
//                                 if (value.toInt() < titles.length) {
//                                   return Text(
//                                     titles[value.toInt()],
//                                     style: const TextStyle(fontSize: 10),
//                                   );
//                                 }
//                                 return const Text('');
//                               },
//                             ),
//                           ),
//                           topTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           rightTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                         ),
//                         borderData: FlBorderData(show: false),
//                         barTouchData: BarTouchData(enabled: false),
//                       ),
//                     )
//                   : const Center(
//                       child: Text(
//                         'Sin datos para mostrar',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPerformanceIndicators(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Indicadores de Rendimiento',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...controller.getPerformanceIndicators().map(
//               (indicator) => _buildIndicatorRow(context, indicator),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildIndicatorRow(
//     BuildContext context,
//     PerformanceIndicator indicator,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(indicator.icon, size: 20, color: indicator.color),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   indicator.title,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ),
//               Text(
//                 indicator.displayValue,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: indicator.color,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: (indicator.value / 100).clamp(0.0, 1.0),
//             backgroundColor: Colors.grey.shade300,
//             valueColor: AlwaysStoppedAnimation<Color>(indicator.color),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Meta: ${indicator.targetText}',
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOverdueSection(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.red.shade600),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Facturas Vencidas',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red.shade800,
//                     ),
//                   ),
//                 ),
//                 CustomButton(
//                   text: 'Ver Todas',
//                   type: ButtonType.outline,
//                   onPressed: controller.goToOverdueInvoices,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (controller.overdueInvoices.isEmpty)
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green.shade600),
//                     const SizedBox(width: 8),
//                     const Expanded(child: Text('¡No hay facturas vencidas!')),
//                   ],
//                 ),
//               )
//             else
//               Column(
//                 children: controller.overdueInvoices
//                     .take(5)
//                     .map((invoice) => _buildOverdueInvoiceItem(invoice))
//                     .toList(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOverdueInvoiceItem(Invoice invoice) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.shade200),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   invoice.number,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   invoice.customerName,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '\${invoice.total.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red.shade600,
//                 ),
//               ),
//               Text(
//                 '${invoice.daysOverdue} días',
//                 style: TextStyle(fontSize: 12, color: Colors.red.shade600),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Acciones Rápidas',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 12),
//             CustomButton(
//               text: 'Nueva Factura',
//               icon: Icons.add,
//               onPressed: controller.goToCreateInvoice,
//               width: double.infinity,
//             ),
//             const SizedBox(height: 8),
//             CustomButton(
//               text: 'Ver Facturas',
//               icon: Icons.list,
//               type: ButtonType.outline,
//               onPressed: () => controller.goToInvoiceList(),
//               width: double.infinity,
//             ),
//             const SizedBox(height: 8),
//             CustomButton(
//               text: 'Exportar Datos',
//               icon: Icons.download,
//               type: ButtonType.outline,
//               onPressed: () => _showExportOptions(context),
//               width: double.infinity,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendsAnalysis(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Análisis de Tendencias',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildTrendItem(
//               'Estado de Salud Financiera',
//               controller.getHealthMessage(),
//               controller.getHealthIcon(),
//               controller.getHealthColor(),
//             ),
//             const SizedBox(height: 12),
//             _buildTrendItem(
//               'Tasa de Cobro',
//               '${controller.collectionRate.toStringAsFixed(1)}%',
//               Icons.trending_up,
//               controller.collectionRate >= 85 ? Colors.green : Colors.red,
//             ),
//             const SizedBox(height: 12),
//             _buildTrendItem(
//               'Facturas Activas',
//               '${controller.activeInvoices} facturas',
//               Icons.receipt,
//               Colors.blue,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendItem(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//               Text(
//                 value,
//                 style: TextStyle(color: color, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLegend(List<ChartData> data) {
//     return Wrap(
//       spacing: 16,
//       runSpacing: 8,
//       children: data
//           .map(
//             (item) => Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: item.color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${item.label} (${item.value.toInt()})',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           )
//           .toList(),
//     );
//   }

//   Widget? _buildFloatingActionButton(BuildContext context) {
//     if (!context.isMobile) return null;

//     return FloatingActionButton.extended(
//       onPressed: () => Get.find<InvoiceStatsController>().goToCreateInvoice(),
//       icon: const Icon(Icons.add),
//       label: const Text('Nueva Factura'),
//     );
//   }

//   // ==================== CHART DATA HELPERS ====================

//   List<PieChartSectionData> _buildPieChartSections(
//     InvoiceStatsController controller,
//   ) {
//     final data = controller.getStatusChartData();
//     return data
//         .asMap()
//         .entries
//         .map(
//           (entry) => PieChartSectionData(
//             value: entry.value.value,
//             title: '${entry.value.value.toInt()}',
//             color: entry.value.color,
//             radius: 50,
//             titleStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         )
//         .toList();
//   }

//   List<BarChartGroupData> _buildBarGroups(InvoiceStatsController controller) {
//     final data = controller.getAmountChartData();
//     return data
//         .asMap()
//         .entries
//         .map(
//           (entry) => BarChartGroupData(
//             x: entry.key,
//             barRods: [
//               BarChartRodData(
//                 toY: entry.value.value,
//                 color: entry.value.color,
//                 width: 20,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ],
//           ),
//         )
//         .toList();
//   }

//   // ==================== EVENT HANDLERS ====================

//   void _handleMenuAction(String action, BuildContext context) {
//     switch (action) {
//       case 'print':
//         _showInfo('Próximamente', 'Función de impresión en desarrollo');
//         break;
//       case 'share':
//         _showInfo('Próximamente', 'Función de compartir en desarrollo');
//         break;
//       case 'settings':
//         Get.toNamed('/settings/invoices');
//         break;
//     }
//   }

//   void _showExportOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Exportar Estadísticas',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.picture_as_pdf),
//               title: const Text('Exportar como PDF'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showInfo('Próximamente', 'Exportación PDF en desarrollo');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.table_chart),
//               title: const Text('Exportar como Excel'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showInfo(
//                   'Próximamente',
//                   'Exportación Excel en desarrollo',
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.image),
//               title: const Text('Exportar gráficos como imagen'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showInfo(
//                   'Próximamente',
//                   'Exportación de imagen en desarrollo',
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== UTILS ====================

//   String _formatCurrency(double value) {
//     if (value >= 1000000) {
//       return '${(value / 1000000).toStringAsFixed(1)}M';
//     } else if (value >= 1000) {
//       return '${(value / 1000).toStringAsFixed(1)}K';
//     } else {
//       return value.toStringAsFixed(0);
//     }
//   }

//   void _showInfo(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.blue.shade100,
//       colorText: Colors.blue.shade800,
//       icon: const Icon(Icons.info, color: Colors.blue),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }