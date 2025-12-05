// lib/features/invoices/presentation/screens/invoice_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/animated_charts.dart';
import '../controllers/invoice_stats_controller.dart';
import '../controllers/invoice_list_controller.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/services/invoice_stats_calculator.dart';

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

  // ==================== ELEGANT APP BAR ====================

  PreferredSizeWidget _buildCompactAppBar(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE0E7FF)],
            ).createShader(bounds),
            child: const Text(
              'Estadísticas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed:
                () => Get.find<InvoiceStatsController>().refreshAllData(
                  showSuccessMessage: true,
                ),
            padding: const EdgeInsets.all(8),
            tooltip: 'Actualizar datos',
          ),
        ),
      ],
    );
  }

  // ==================== ULTRA COMPACT LAYOUTS ====================

  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshAllData(showSuccessMessage: true),
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

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshAllData(showSuccessMessage: true),
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
                Expanded(child: _buildHealthCard(context, controller)),
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
                  Expanded(
                    child: _buildCompactOverdueSection(context, controller),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Calcular estadísticas locales para consistencia
    final localStats = _calculateLocalStats();

    return Row(
      children: [
        // Enhanced Sidebar con tema elegant - ancho reducido
        Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.backgroundColor,
                ElegantLightTheme.cardColor,
              ],
            ),
            border: Border(
              right: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              ),
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            children: [
              // Enhanced Sidebar Header con gradient elegant - más compacto
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Dashboard de Facturas',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Period Selector in Desktop Sidebar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: _buildDesktopPeriodSelector(context, controller),
                    ),
                  ],
                ),
              ),

              // Enhanced Sidebar Content - más compacto
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildEnhancedSidebarKPIs(context, controller, localStats),
                      const SizedBox(height: 14),
                      _buildEnhancedHealthCard(context, controller),
                      const SizedBox(height: 14),
                      _buildEnhancedQuickActionsCard(context, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content - Layout optimizado para llenar el espacio
        Expanded(
          child: Container(
            color: ElegantLightTheme.backgroundColor,
            child: Column(
              children: [
                // Header con KPIs compactos en la parte superior
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildTopKPIBar(controller, localStats),
                ),

                // Contenido principal scrolleable
                Expanded(
                  child: RefreshIndicator(
                    onRefresh:
                        () => controller.refreshAllData(showSuccessMessage: true),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Gráficos en Row
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildStatusDonutChart(context, controller),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildAmountBarChart(context, controller),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Performance Analytics
                          _buildPerformanceAnalytics(context, controller, localStats),

                          const SizedBox(height: 16),

                          // Resumen de ventas adicional
                          _buildSalesSummaryCard(controller),

                          // Solo mostrar si hay vencidas según lógica local
                          if (localStats['overdue']! > 0) ...[
                            const SizedBox(height: 16),
                            _buildCompactOverdueSection(context, controller),
                          ],
                        ],
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

  // ==================== ELEGANT COMPACT WIDGETS ====================

  /// Barra de KPIs en la parte superior del área principal
  Widget _buildTopKPIBar(InvoiceStatsController controller, Map<String, int> localStats) {
    final amounts = _calculateLocalAmounts();
    final totalSales = amounts['totalSales']!;
    final paidAmount = amounts['paidAmount']!;
    final pendingAmount = amounts['pendingAmount']!;
    // Calcular tasa de cobro local
    final collectionRate = totalSales > 0 ? (paidAmount / totalSales * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildTopKPIItem(
            'Total Facturas',
            localStats['total'].toString(),
            Icons.receipt_long,
            ElegantLightTheme.primaryBlue,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildTopKPIItem(
            'Ventas Totales',
            AppFormatters.formatCurrency(totalSales),
            Icons.attach_money,
            const Color(0xFF10B981),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildTopKPIItem(
            'Tasa de Cobro',
            '${collectionRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            collectionRate >= 85 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildTopKPIItem(
            'Pendiente',
            AppFormatters.formatCurrency(pendingAmount),
            Icons.hourglass_empty,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildTopKPIItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula los montos usando el servicio centralizado InvoiceStatsCalculator
  /// Wrapper para compatibilidad - retorna Map<String, double>
  Map<String, double> _calculateLocalAmounts() {
    return _getStatsForCurrentPeriod().toAmountsMap();
  }

  /// Card de resumen de ventas adicional
  Widget _buildSalesSummaryCard(InvoiceStatsController controller) {
    final amounts = _calculateLocalAmounts();
    final pendingAmount = amounts['pendingAmount']!;
    final overdueAmount = amounts['overdueAmount']!;
    final paidAmount = amounts['paidAmount']!;
    final totalSales = amounts['totalSales']!;

    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen de Cartera',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${AppFormatters.formatCurrency(totalSales)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barras de progreso horizontales
          _buildSalesProgressBar('Cobrado', paidAmount, totalSales, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildSalesProgressBar('Pendiente', pendingAmount, totalSales, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildSalesProgressBar('Vencido', overdueAmount, totalSales, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildSalesProgressBar(String label, double value, double total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  AppFormatters.formatCurrency(value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAnimatedProgressBarWithShimmer(
          percentage: percentage / 100,
          color: color,
          height: 10,
        ),
      ],
    );
  }

  /// Barra de progreso animada con efecto shimmer
  Widget _buildAnimatedProgressBarWithShimmer({
    required double percentage,
    required Color color,
    double height = 8,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: percentage.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutExpo,
        builder: (context, animatedValue, child) {
          return Row(
            children: [
              if (animatedValue > 0)
                Flexible(
                  flex: (animatedValue * 100).round().clamp(1, 100),
                  child: Container(
                    height: height - 2,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color.withValues(alpha: 0.85),
                          color,
                          color.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular((height - 2) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular((height - 2) / 2),
                      child: Stack(
                        children: [
                          if (animatedValue >= percentage * 0.9 && percentage > 0.05)
                            ProgressShimmerEffect(
                              borderRadius: (height - 2) / 2,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (animatedValue < 1.0)
                Flexible(
                  flex: ((1.0 - animatedValue) * 100).round().clamp(1, 100),
                  child: Container(),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Calcula las estadísticas usando el servicio centralizado InvoiceStatsCalculator
  /// Garantiza consistencia con la pantalla de lista de facturas usando invoice.isOverdue
  InvoiceStatsResult _getStatsForCurrentPeriod() {
    final statsController = Get.find<InvoiceStatsController>();
    final dateRange = statsController.currentPeriodRange;

    // Intentar obtener las facturas del InvoiceListController si está disponible
    if (Get.isRegistered<InvoiceListController>()) {
      final listController = Get.find<InvoiceListController>();
      final allInvoices = listController.invoices;

      if (allInvoices.isNotEmpty) {
        // Usar el servicio centralizado para calcular estadísticas
        return InvoiceStatsCalculator.calculateForPeriod(
          allInvoices,
          startDate: dateRange.start,
          endDate: dateRange.end,
          useInvoiceDate: true,
        );
      }
    }

    // Si no hay facturas locales, crear resultado desde el controlador de stats
    // Nota: El backend puede tener discrepancias, pero al menos mostramos algo
    return InvoiceStatsResult(
      total: statsController.totalInvoices,
      paid: statsController.paidInvoices,
      pending: statsController.pendingInvoices,
      overdue: statsController.overdueCount,
      partiallyPaid: statsController.partiallyPaidInvoices,
      draft: statsController.draftInvoices,
      cancelled: statsController.cancelledInvoices,
      totalSales: statsController.totalSales,
      paidAmount: statsController.totalSales - statsController.pendingAmount,
      pendingAmount: statsController.pendingAmount - statsController.overdueAmount,
      overdueAmount: statsController.overdueAmount,
    );
  }

  /// Wrapper para compatibilidad - retorna Map<String, int>
  Map<String, int> _calculateLocalStats() {
    return _getStatsForCurrentPeriod().toStatsMap();
  }

  Widget _buildCompactKPIGrid(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Calcular estadísticas localmente para consistencia
    final localStats = _calculateLocalStats();

    return FuturisticContainer(
      padding: EdgeInsets.zero,
      child: GridView.count(
        crossAxisCount: context.isMobile ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: context.isMobile ? 1.4 : 1.2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: [
          _buildMiniKPI(
            'Total',
            localStats['total']!,
            Icons.receipt_long,
            ElegantLightTheme.primaryBlue,
          ),
          _buildMiniKPI(
            'Pagadas',
            localStats['paid']!,
            Icons.check_circle,
            const Color(0xFF10B981), // Verde elegante
          ),
          _buildMiniKPI(
            'Pendientes',
            localStats['pending']!,
            Icons.schedule,
            const Color(0xFFF59E0B), // Naranja elegante
          ),
          _buildMiniKPI(
            'Vencidas',
            localStats['overdue']!,
            Icons.warning,
            const Color(0xFFEF4444), // Rojo elegante
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.05),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          // Contador animado
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                animatedValue.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: color,
                ),
              );
            },
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsBar(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
          ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStat(
              'Ventas',
              AppFormatters.formatCurrency(controller.totalSales),
              const Color(0xFF10B981), // Verde elegante
              Icons.trending_up,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildQuickStat(
              'Cobro',
              '${controller.collectionRate.toStringAsFixed(1)}%',
              controller.collectionRate >= 85
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              Icons.percent,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildQuickStat(
              'Pendiente',
              AppFormatters.formatCurrency(controller.pendingAmount),
              const Color(0xFFF59E0B), // Naranja elegante
              Icons.hourglass_empty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ElegantLightTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChartsSection(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Column(
      children: [
        _buildStatusDonutChart(context, controller),
        const SizedBox(height: 12),
        _buildAmountBarChart(context, controller),
      ],
    );
  }

  Widget _buildStatusDonutChart(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Obtener datos locales filtrados por período
    final localStats = _calculateLocalStats();
    final segments = _buildDonutSegments(localStats);

    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pie_chart,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Estados de Facturas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Animated3DDonutChart(
              segments: segments,
              size: 160,
              showLegend: true,
              animationDuration: const Duration(milliseconds: 1200),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye los segmentos para el gráfico de dona 3D
  List<ChartSegment> _buildDonutSegments(Map<String, int> localStats) {
    final segments = <ChartSegment>[];

    final pending = localStats['pending'] ?? 0;
    final paid = localStats['paid'] ?? 0;
    final overdue = localStats['overdue'] ?? 0;
    final total = localStats['total'] ?? 0;
    final partial = total - paid - pending - overdue;

    if (pending > 0) {
      segments.add(ChartSegment(
        label: 'Pendientes',
        value: pending.toDouble(),
        color: Colors.orange,
        icon: Icons.schedule,
      ));
    }

    if (paid > 0) {
      segments.add(ChartSegment(
        label: 'Pagadas',
        value: paid.toDouble(),
        color: const Color(0xFF10B981),
        icon: Icons.check_circle,
      ));
    }

    if (overdue > 0) {
      segments.add(ChartSegment(
        label: 'Vencidas',
        value: overdue.toDouble(),
        color: const Color(0xFFEF4444),
        icon: Icons.warning_amber,
      ));
    }

    if (partial > 0) {
      segments.add(ChartSegment(
        label: 'Pago Parcial',
        value: partial.toDouble(),
        color: const Color(0xFF3B82F6),
        icon: Icons.pie_chart,
      ));
    }

    return segments;
  }

  Widget _buildAmountBarChart(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Obtener valores filtrados por período
    final amounts = _calculateLocalAmounts();
    final pendingAmount = amounts['pendingAmount']!;
    final overdueAmount = amounts['overdueAmount']!;
    final paidAmount = amounts['paidAmount']!;

    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bar_chart,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Análisis de Montos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barras verticales animadas con efecto shimmer
          _buildAnimatedAmountBars(paidAmount, pendingAmount, overdueAmount),
        ],
      ),
    );
  }

  Widget _buildAnimatedAmountBars(
    double paidAmount,
    double pendingAmount,
    double overdueAmount,
  ) {
    final maxValue = [paidAmount, pendingAmount, overdueAmount]
        .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue > 0 ? maxValue : 100000.0;

    return Column(
      children: [
        // Barras verticales con etiquetas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildAnimatedBarWithLabel(
                label: 'Cobrado',
                value: paidAmount,
                maxValue: effectiveMax,
                color: const Color(0xFF10B981),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
            ),
            Expanded(
              child: _buildAnimatedBarWithLabel(
                label: 'Pendiente',
                value: pendingAmount,
                maxValue: effectiveMax,
                color: const Color(0xFFF59E0B),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
              ),
            ),
            Expanded(
              child: _buildAnimatedBarWithLabel(
                label: 'Vencido',
                value: overdueAmount,
                maxValue: effectiveMax,
                color: const Color(0xFFEF4444),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFF87171)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedBarWithLabel({
    required String label,
    required double value,
    required double maxValue,
    required Color color,
    LinearGradient? gradient,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra animada con forma de píldora
        AnimatedVerticalBar(
          label: '',
          value: value,
          maxValue: maxValue,
          color: color,
          gradient: gradient,
          width: 50,
          height: 130,
          minFilledHeight: 50, // Altura mínima para mantener forma de píldora
          animationDuration: const Duration(milliseconds: 1400),
        ),
        const SizedBox(height: 8),
        // Etiqueta
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Monto con badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: value > 0 ? color.withValues(alpha: 0.12) : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value > 0 ? color.withValues(alpha: 0.2) : ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Text(
            AppFormatters.formatCurrency(value),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: value > 0 ? color : ElegantLightTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Usar datos locales filtrados por período
    final localStats = _calculateLocalStats();
    final amounts = _calculateLocalAmounts();

    final totalInvoices = localStats['total']!;
    final overdueCount = localStats['overdue']!;
    final totalSales = amounts['totalSales']!;
    final paidAmount = amounts['paidAmount']!;

    // Calcular porcentajes locales
    final collectionRate = totalSales > 0 ? (paidAmount / totalSales * 100) : 100.0;
    final overduePercentage = totalInvoices > 0 ? (overdueCount / totalInvoices * 100) : 0.0;

    // Determinar estado de salud basado en datos locales
    final isHealthy = collectionRate >= 85 && overduePercentage <= 5;
    final hasIssues = collectionRate < 70 || overduePercentage > 15;

    final healthColor = isHealthy
        ? Colors.green
        : hasIssues
            ? Colors.red
            : Colors.orange;

    final healthIcon = isHealthy
        ? Icons.check_circle
        : hasIssues
            ? Icons.error
            : Icons.warning_amber;

    final healthMessage = isHealthy
        ? 'Estado financiero saludable'
        : hasIssues
            ? 'Requiere atención urgente'
            : 'Estado financiero aceptable';

    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          healthColor.withValues(alpha: 0.08),
          healthColor.withValues(alpha: 0.03),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      healthColor.withValues(alpha: 0.3),
                      healthColor.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  healthIcon,
                  color: healthColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salud Financiera',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      healthMessage,
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
            collectionRate,
            100,
            '%',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    double value,
    double target,
    String unit,
  ) {
    final progress = (value / target).clamp(0.0, 1.0);
    final isGood = value >= target;
    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAnimatedProgressBarWithShimmer(
          percentage: progress,
          color: color,
          height: 8,
        ),
      ],
    );
  }

  Widget _buildHealthActionsSection(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Row(
      children: [
        Expanded(child: _buildHealthCard(context, controller)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickActionsCard(context, controller)),
      ],
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    final localStats = _calculateLocalStats();
    final overdueCount = localStats['overdue']!;

    return FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Acciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            label: 'Nueva Factura',
            icon: Icons.add_circle_outline,
            color: ElegantLightTheme.primaryBlue,
            onTap: controller.goToCreateInvoice,
            isPrimary: true,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            label: 'Vencidas',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => controller.goToOverdueInvoices(),
            badge: overdueCount > 0 ? overdueCount.toString() : null,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            label: 'Ver Todas',
            icon: Icons.list_alt,
            color: ElegantLightTheme.textSecondary,
            onTap: () => controller.goToInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarKPIs(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
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

  Widget _buildSidebarKPI(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalytics(
    BuildContext context,
    InvoiceStatsController controller,
    Map<String, int> localStats,
  ) {
    final total = localStats['total']!;
    final paid = localStats['paid']!;
    final overdue = localStats['overdue']!;
    final paidPercent = total > 0 ? (paid / total * 100) : 0.0;
    final overduePercent = total > 0 ? (overdue / total * 100) : 0.0;

    return FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.speed,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Análisis de Rendimiento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
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
                  paidPercent,
                  '%',
                  80,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Facturas Vencidas',
                  overduePercent,
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
    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                '${animatedValue.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Meta: ${isInverted ? "≤" : "≥"} ${target.toInt()}$unit',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOverdueSection(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.06),
          const Color(0xFFEF4444).withValues(alpha: 0.02),
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
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.warning, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Facturas Vencidas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
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
                  Text(
                    '¡No hay facturas vencidas!',
                    style: TextStyle(fontSize: 12),
                  ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.overdueInvoices
                    .take(3)
                    .map(
                      (invoice) => _buildCompactOverdueItem(
                        context,
                        invoice,
                        controller,
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactOverdueItem(
    BuildContext context,
    Invoice invoice,
    InvoiceStatsController controller,
  ) {
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.red,
                  ),
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
          const Text(
            'Error al cargar estadísticas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                () => controller.refreshAllData(showSuccessMessage: true),
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

  // ==================== ELEGANT PERIOD SELECTOR ====================

  Widget _buildElegantPeriodSelector(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return GetBuilder<InvoiceStatsController>(
      builder: (ctrl) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compacto
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${ctrl.selectedPeriod.displayName} • ${ctrl.selectedPeriod.getDateRangeDescription()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ElegantLightTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de períodos 3x2 con tamaño uniforme
            Row(
              children: [
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.today)),
                const SizedBox(width: 8),
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.thisWeek)),
                const SizedBox(width: 8),
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.thisMonth)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.thisQuarter)),
                const SizedBox(width: 8),
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.thisYear)),
                const SizedBox(width: 8),
                Expanded(child: _buildPeriodButton(ctrl, StatsPeriod.allTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(InvoiceStatsController ctrl, StatsPeriod period) {
    final isSelected = ctrl.selectedPeriod == period;

    return GestureDetector(
      onTap: () => ctrl.changePeriod(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
          color: isSelected ? null : ElegantLightTheme.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              period.icon,
              size: 18,
              color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              period.shortName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ENHANCED DESKTOP COMPONENTS ====================

  Widget _buildDesktopPeriodSelector(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return GetBuilder<InvoiceStatsController>(
      builder: (ctrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con indicador de período actual
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Período de Análisis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Descripción del rango actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ctrl.selectedPeriod.icon,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  ctrl.selectedPeriod.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${ctrl.selectedPeriod.getDateRangeDescription()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Grid de períodos 3x2 con tamaño uniforme
          Row(
            children: [
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.today)),
              const SizedBox(width: 6),
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.thisWeek)),
              const SizedBox(width: 6),
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.thisMonth)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.thisQuarter)),
              const SizedBox(width: 6),
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.thisYear)),
              const SizedBox(width: 6),
              Expanded(child: _buildDesktopPeriodButton(ctrl, StatsPeriod.allTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPeriodButton(InvoiceStatsController ctrl, StatsPeriod period) {
    final isSelected = ctrl.selectedPeriod == period;

    return GestureDetector(
      onTap: () => ctrl.changePeriod(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              period.icon,
              size: 14,
              color: isSelected
                  ? ElegantLightTheme.primaryBlue
                  : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 2),
            Text(
              period.shortName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? ElegantLightTheme.primaryBlue
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSidebarKPIs(
    BuildContext context,
    InvoiceStatsController controller,
    Map<String, int> localStats,
  ) {
    final total = localStats['total']!;
    final pending = localStats['pending']!;
    final overdue = localStats['overdue']!;
    final pendingPercent = total > 0 ? (pending / total * 100) : 0.0;
    final overduePercent = total > 0 ? (overdue / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.insights,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'KPIs Principales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildEnhancedKPICard(
          'Total Facturas',
          total.toString(),
          Icons.receipt_long,
          ElegantLightTheme.primaryBlue,
          context,
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Ventas Totales',
          AppFormatters.formatCurrency(controller.totalSales),
          Icons.attach_money,
          const Color(0xFF10B981),
          context,
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Pendientes',
          '$pending (${pendingPercent.toStringAsFixed(1)}%)',
          Icons.schedule,
          const Color(0xFFF59E0B),
          context,
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Vencidas',
          '$overdue (${overduePercent.toStringAsFixed(1)}%)',
          Icons.warning,
          const Color(0xFFEF4444),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildEnhancedHealthCard(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    // Usar datos locales filtrados por período
    final localStats = _calculateLocalStats();
    final amounts = _calculateLocalAmounts();

    final totalInvoices = localStats['total']!;
    final overdueCount = localStats['overdue']!;
    final totalSales = amounts['totalSales']!;
    final paidAmount = amounts['paidAmount']!;

    // Calcular porcentajes locales
    final collectionRate = totalSales > 0 ? (paidAmount / totalSales * 100) : 100.0;
    final overduePercentage = totalInvoices > 0 ? (overdueCount / totalInvoices * 100) : 0.0;

    // Determinar estado de salud basado en datos locales
    final isHealthy = collectionRate >= 85 && overduePercentage <= 5;
    final hasIssues = collectionRate < 70 || overduePercentage > 15;

    final healthColor = isHealthy
        ? Colors.green
        : hasIssues
            ? Colors.red
            : Colors.orange;

    final healthIcon = isHealthy
        ? Icons.check_circle
        : hasIssues
            ? Icons.error
            : Icons.warning_amber;

    final healthMessage = isHealthy
        ? 'Estado financiero saludable'
        : hasIssues
            ? 'Requiere atención urgente'
            : 'Estado financiero aceptable';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            healthColor.withValues(alpha: 0.12),
            healthColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: healthColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      healthColor.withValues(alpha: 0.3),
                      healthColor.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  healthIcon,
                  color: healthColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado Financiero',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      healthMessage,
                      style: TextStyle(
                        fontSize: 11,
                        color: healthColor,
                        fontWeight: FontWeight.w600,
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
            collectionRate,
            '%',
            100,
            collectionRate >= 85,
          ),
          const SizedBox(height: 12),
          _buildEnhancedIndicator(
            'Facturas Vencidas',
            overduePercentage,
            '%',
            100,
            overduePercentage <= 5,
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
    final progress =
        isInverted
            ? (target - value).clamp(0, target) / target
            : (value / target).clamp(0, 1);

    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAnimatedProgressBarWithShimmer(
          percentage: progress.toDouble(),
          color: color,
          height: 8,
        ),
      ],
    );
  }

  Widget _buildEnhancedQuickActionsCard(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    final localStats = _calculateLocalStats();
    final overdueCount = localStats['overdue']!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón principal: Nueva Factura
          _buildQuickActionButton(
            label: 'Nueva Factura',
            icon: Icons.add_circle_outline,
            color: ElegantLightTheme.primaryBlue,
            onTap: () => controller.goToCreateInvoice(),
            isPrimary: true,
          ),
          const SizedBox(height: 8),

          // Facturas Vencidas con badge de cantidad
          _buildQuickActionButton(
            label: 'Facturas Vencidas',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => controller.goToOverdueInvoices(),
            badge: overdueCount > 0 ? overdueCount.toString() : null,
          ),
          const SizedBox(height: 8),

          // Ver Todas las Facturas
          _buildQuickActionButton(
            label: 'Ver Todas',
            icon: Icons.receipt_long_outlined,
            color: ElegantLightTheme.textSecondary,
            onTap: () => controller.goToInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isPrimary ? ElegantLightTheme.primaryGradient : null,
            color: isPrimary ? null : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: isPrimary
                ? null
                : Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : color,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.25)
                        : color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.8)
                    : color.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodSelector(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
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
                  children:
                      StatsPeriod.values
                          .map(
                            (period) => ChoiceChip(
                              label: Text(period.displayName),
                              selected: controller.selectedPeriod == period,
                              onSelected: (_) {
                                controller.changePeriod(period);
                                Navigator.pop(context);
                              },
                            ),
                          )
                          .toList(),
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
