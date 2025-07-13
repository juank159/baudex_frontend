// lib/features/invoices/presentation/screens/invoice_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_stats_controller.dart';
import '../widgets/invoice_stats_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceStatsScreen extends StatelessWidget {
  const InvoiceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCompactAppBar(context),
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
      floatingActionButton: _buildCompactFAB(context),
    );
  }

  // ==================== COMPACT APP BAR ====================
  
  PreferredSizeWidget _buildCompactAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Estadísticas', 
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () => Get.find<InvoiceStatsController>().refreshAllData(),
          padding: const EdgeInsets.all(8),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) => _handleMenuAction(value, context),
          padding: const EdgeInsets.all(8),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(children: [Icon(Icons.download, size: 16), SizedBox(width: 8), Text('Exportar')]),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(children: [Icon(Icons.settings, size: 16), SizedBox(width: 8), Text('Configurar')]),
            ),
          ],
        ),
      ],
    );
  }


  // ==================== ULTRA COMPACT LAYOUTS ====================

  Widget _buildMobileLayout(BuildContext context, InvoiceStatsController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: CustomScrollView(
        slivers: [
          // Period Selector elegante
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: _buildElegantPeriodSelector(context, controller),
            ),
          ),
          
          // KPI Cards compactas
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCompactKPIGrid(context, controller),
            ),
          ),
          
          // Quick Stats Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildQuickStatsBar(context, controller),
            ),
          ),
          
          // Charts Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildCompactChartsSection(context, controller),
            ),
          ),
          
          // Health & Actions
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildHealthActionsSection(context, controller),
            ),
          ),
          
          // Overdue (if any)
          if (controller.hasOverdueInvoices)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: _buildCompactOverdueSection(context, controller),
              ),
            ),
          
          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, InvoiceStatsController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Top Row: KPIs + Health
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCompactKPIGrid(context, controller),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(context, controller),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Charts Row
            Row(
              children: [
                Expanded(child: _buildStatusDonutChart(context, controller)),
                const SizedBox(width: 12),
                Expanded(child: _buildAmountBarChart(context, controller)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bottom Row: Quick Actions + Overdue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildQuickActionsCard(context, controller)),
                if (controller.hasOverdueInvoices) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompactOverdueSection(context, controller)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, InvoiceStatsController controller) {
    return Row(
      children: [
        // Enhanced Sidebar
        Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
            ),
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced Sidebar Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Period Selector in Desktop Sidebar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildDesktopPeriodSelector(context, controller),
                    ),
                  ],
                ),
              ),
              
              // Enhanced Sidebar Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildEnhancedSidebarKPIs(context, controller),
                      const SizedBox(height: 20),
                      _buildEnhancedHealthCard(context, controller),
                      const SizedBox(height: 20),
                      _buildEnhancedQuickActionsCard(context, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Main Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshAllData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top Charts Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildStatusDonutChart(context, controller),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildAmountBarChart(context, controller),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Performance Analytics
                  _buildPerformanceAnalytics(context, controller),
                  
                  if (controller.hasOverdueInvoices) ...[
                    const SizedBox(height: 24),
                    _buildCompactOverdueSection(context, controller),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== MODERN COMPACT WIDGETS ====================

  Widget _buildCompactKPIGrid(BuildContext context, InvoiceStatsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: context.isMobile ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: context.isMobile ? 1.4 : 1.2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: [
          _buildMiniKPI('Total', controller.totalInvoices.toString(), Icons.receipt_long, Colors.blue),
          _buildMiniKPI('Pagadas', controller.paidInvoices.toString(), Icons.check_circle, Colors.green),
          _buildMiniKPI('Pendientes', controller.pendingInvoices.toString(), Icons.schedule, Colors.orange),
          _buildMiniKPI('Vencidas', controller.overdueCount.toString(), Icons.warning, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsBar(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStat(
              'Ventas',
              AppFormatters.formatCurrency(controller.totalSales),
              Colors.green,
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          Expanded(
            child: _buildQuickStat(
              'Cobro',
              '${controller.collectionRate.toStringAsFixed(1)}%',
              controller.collectionRate >= 85 ? Colors.green : Colors.red,
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          Expanded(
            child: _buildQuickStat(
              'Pendiente',
              AppFormatters.formatCurrency(controller.pendingAmount),
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChartsSection(BuildContext context, InvoiceStatsController controller) {
    return Column(
      children: [
        _buildStatusDonutChart(context, controller),
        const SizedBox(height: 12),
        _buildAmountBarChart(context, controller),
      ],
    );
  }

  Widget _buildStatusDonutChart(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.pie_chart, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              Text(
                'Estados de Facturas',
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180, // Aumentado para igualar con barras
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(controller),
                      centerSpaceRadius: 35,
                      sectionsSpace: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildLegend(controller.getStatusChartData())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBarChart(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart, size: 16, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis de Montos',
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180, // Igualado con gráfico circular
            child: BarChart(
              BarChartData(
                barGroups: _buildBarGroups(controller),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Cobrado', 'Pendiente', 'Vencido'];
                        if (value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const titles = ['Cobrado', 'Pendiente', 'Vencido'];
                      return BarTooltipItem(
                        '${titles[group.x]}\n${AppFormatters.formatCurrency(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.getHealthColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.getHealthIcon(),
                  color: controller.getHealthColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Salud Financiera',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      controller.getHealthMessage(),
                      style: TextStyle(
                        color: controller.getHealthColor(),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(
            'Tasa de Cobro',
            controller.collectionRate,
            85,
            '%',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, double target, String unit) {
    final progress = (value / target).clamp(0.0, 1.0);
    final isGood = value >= target;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isGood ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isGood ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthActionsSection(BuildContext context, InvoiceStatsController controller) {
    return Row(
      children: [
        Expanded(child: _buildHealthCard(context, controller)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickActionsCard(context, controller)),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Nueva Factura',
            Icons.add,
            Theme.of(context).primaryColor,
            controller.goToCreateInvoice,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            'Ver Facturas',
            Icons.list,
            Colors.grey.shade600,
            () => controller.goToInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(text, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSidebarKPIs(BuildContext context, InvoiceStatsController controller) {
    return Column(
      children: [
        _buildSidebarKPI(
          'Total Facturas',
          controller.totalInvoices.toString(),
          Icons.receipt_long,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildSidebarKPI(
          'Ventas Totales',
          AppFormatters.formatCurrency(controller.totalSales),
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildSidebarKPI(
          'Monto Pendiente',
          AppFormatters.formatCurrency(controller.pendingAmount),
          Icons.schedule,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSidebarKPI(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalytics(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis de Rendimiento',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Tasa de Cobro',
                  controller.collectionRate,
                  '%',
                  85,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Facturas Pagadas',
                  controller.paidPercentage,
                  '%',
                  80,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Facturas Vencidas',
                  controller.overduePercentage,
                  '%',
                  5,
                  Icons.warning,
                  isInverted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    double value,
    String unit,
    double target,
    IconData icon, {
    bool isInverted = false,
  }) {
    final isGood = isInverted ? value <= target : value >= target;
    final color = isGood ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Meta: ${isInverted ? "≤" : "≥"} $target$unit',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOverdueSection(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.warning, size: 16, color: Colors.red),
              ),
              const SizedBox(width: 8),
              const Text(
                'Facturas Vencidas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.goToOverdueInvoices,
                child: const Text('Ver Todas', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.overdueInvoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('¡No hay facturas vencidas!', style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${controller.overdueInvoices.length} facturas por ${AppFormatters.formatCurrency(controller.overdueAmount)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.overdueInvoices.take(3).map(
                  (invoice) => _buildCompactOverdueItem(context, invoice, controller),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactOverdueItem(BuildContext context, Invoice invoice, InvoiceStatsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => controller.goToInvoiceDetail(invoice.id),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                  Text(
                    invoice.customerName,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatCurrency(invoice.total),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.red),
                ),
                Text(
                  '${invoice.daysOverdue}d',
                  style: TextStyle(fontSize: 9, color: Colors.red.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<ChartData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${item.value.toInt()} facturas',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, InvoiceStatsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar estadísticas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.refreshAllData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget? _buildCompactFAB(BuildContext context) {
    if (!context.isMobile) return null;
    
    return FloatingActionButton(
      onPressed: () => Get.find<InvoiceStatsController>().goToCreateInvoice(),
      child: const Icon(Icons.add),
    );
  }

  // ==================== CHART HELPERS ====================

  List<PieChartSectionData> _buildPieChartSections(InvoiceStatsController controller) {
    final data = controller.getStatusChartData();
    return data.map((item) => PieChartSectionData(
      value: item.value,
      title: item.value > 0 ? item.value.toInt().toString() : '',
      color: item.color,
      radius: 30,
      titleStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800, // Cambiado de blanco a gris oscuro
        shadows: [
          Shadow(
            color: Colors.white,
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    )).toList();
  }

  List<BarChartGroupData> _buildBarGroups(InvoiceStatsController controller) {
    final data = controller.getAmountChartData();
    return data.asMap().entries.map((entry) => BarChartGroupData(
      x: entry.key,
      barRods: [
        BarChartRodData(
          toY: entry.value.value,
          color: entry.value.color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    )).toList();
  }

  // ==================== ELEGANT PERIOD SELECTOR ====================

  Widget _buildElegantPeriodSelector(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Período:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GetBuilder<InvoiceStatsController>(
                builder: (controller) => Row(
                  children: StatsPeriod.values.map((period) {
                    final isSelected = controller.selectedPeriod == period;
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () => controller.changePeriod(period),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                                ? null 
                                : Border.all(color: Colors.grey.shade400),
                          ),
                          child: Text(
                            period.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
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

  // ==================== ENHANCED DESKTOP COMPONENTS ====================

  Widget _buildDesktopPeriodSelector(BuildContext context, InvoiceStatsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período de Análisis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: StatsPeriod.values.map((period) {
            final isSelected = controller.selectedPeriod == period;
            return GestureDetector(
              onTap: () {
                controller.changePeriod(period);
                controller.update(); // Forzar actualización visual
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.6)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  period.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedSidebarKPIs(BuildContext context, InvoiceStatsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KPIs Principales',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildEnhancedKPICard(
          'Total Facturas',
          controller.totalInvoices.toString(),
          Icons.receipt_long,
          Colors.blue,
          context,
        ),
        const SizedBox(height: 8),
        _buildEnhancedKPICard(
          'Ventas Totales',
          AppFormatters.formatCurrency(controller.totalSales),
          Icons.attach_money,
          Colors.green,
          context,
        ),
        const SizedBox(height: 8),
        _buildEnhancedKPICard(
          'Pendientes',
          '${controller.pendingInvoices} (${controller.pendingPercentage.toStringAsFixed(1)}%)',
          Icons.schedule,
          Colors.orange,
          context,
        ),
        const SizedBox(height: 8),
        _buildEnhancedKPICard(
          'Vencidas',
          '${controller.overdueCount} (${controller.overduePercentage.toStringAsFixed(1)}%)',
          Icons.warning,
          Colors.red,
          context,
        ),
      ],
    );
  }

  Widget _buildEnhancedKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHealthCard(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            controller.getHealthColor().withOpacity(0.1),
            controller.getHealthColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: controller.getHealthColor().withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.getHealthColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.getHealthIcon(),
                  color: controller.getHealthColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado Financiero',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.getHealthMessage(),
                      style: TextStyle(
                        fontSize: 11,
                        color: controller.getHealthColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedIndicator(
            'Tasa de Cobro',
            controller.collectionRate,
            '%',
            85,
            controller.collectionRate >= 85,
          ),
          const SizedBox(height: 12),
          _buildEnhancedIndicator(
            'Facturas Vencidas',
            controller.overduePercentage,
            '%',
            5,
            controller.overduePercentage <= 5,
            isInverted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedIndicator(
    String label,
    double value,
    String unit,
    double target,
    bool isGood, {
    bool isInverted = false,
  }) {
    final progress = isInverted
        ? (target - value).clamp(0, target) / target
        : (value / target).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isGood ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              isGood ? Colors.green.shade600 : Colors.red.shade600,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuickActionsCard(BuildContext context, InvoiceStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildEnhancedActionButton(
            'Nueva Factura',
            Icons.add_circle_outline,
            Colors.blue,
            () => controller.goToCreateInvoice(),
          ),
          const SizedBox(height: 8),
          _buildEnhancedActionButton(
            'Facturas Vencidas',
            Icons.warning_amber_outlined,
            Colors.red,
            () => controller.goToOverdueInvoices(),
          ),
          const SizedBox(height: 8),
          _buildEnhancedActionButton(
            'Ver Todas',
            Icons.receipt_long_outlined,
            Colors.grey.shade600,
            () => controller.goToInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 12),
          ],
        ),
      ),
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'export':
        _showInfo('Próximamente', 'Función de exportación en desarrollo');
        break;
      case 'settings':
        Get.toNamed('/settings/invoices');
        break;
    }
  }

  void _showPeriodSelector(BuildContext context, InvoiceStatsController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar Período',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: StatsPeriod.values.map((period) => ChoiceChip(
                label: Text(period.displayName),
                selected: controller.selectedPeriod == period,
                onSelected: (_) {
                  controller.changePeriod(period);
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 3),
    );
  }
}