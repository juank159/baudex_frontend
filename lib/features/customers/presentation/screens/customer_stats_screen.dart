// lib/features/customers/presentation/screens/customer_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/animated_charts.dart';
import '../controllers/customer_stats_controller.dart';

class CustomerStatsScreen extends GetView<CustomerStatsController> {
  const CustomerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCompactAppBar(context),
      body: GetBuilder<CustomerStatsController>(
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return const LoadingWidget(message: 'Cargando estadísticas...');
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, ctrl),
            tablet: _buildTabletLayout(context, ctrl),
            desktop: _buildDesktopLayout(context, ctrl),
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
              Icons.people_outline,
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
              'Estadísticas de Clientes',
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
            onPressed: () => controller.refreshStats(),
            padding: const EdgeInsets.all(8),
            tooltip: 'Actualizar datos',
          ),
        ),
      ],
    );
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, CustomerStatsController ctrl) {
    return RefreshIndicator(
      onRefresh: () => ctrl.refreshStats(),
      child: CustomScrollView(
        slivers: [
          // Period Selector
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: _buildElegantPeriodSelector(context, ctrl),
            ),
          ),

          // KPI Cards compactas
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCompactKPIGrid(context, ctrl),
            ),
          ),

          // Quick Stats Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildQuickStatsBar(context, ctrl),
            ),
          ),

          // Charts Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildCompactChartsSection(context, ctrl),
            ),
          ),

          // Financial Summary
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildFinancialSummaryCard(ctrl),
            ),
          ),

          // Top Customers
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildTopCustomersCard(context, ctrl),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================

  Widget _buildTabletLayout(BuildContext context, CustomerStatsController ctrl) {
    return RefreshIndicator(
      onRefresh: () => ctrl.refreshStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Top Row: KPIs
            _buildCompactKPIGrid(context, ctrl),
            const SizedBox(height: 12),

            // Charts Row
            Row(
              children: [
                Expanded(child: _buildStatusDonutChart(context, ctrl)),
                const SizedBox(width: 12),
                Expanded(child: _buildFinancialBarChart(context, ctrl)),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildActivityStatsCard(ctrl)),
                const SizedBox(width: 12),
                Expanded(child: _buildTopCustomersCard(context, ctrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================

  Widget _buildDesktopLayout(BuildContext context, CustomerStatsController ctrl) {
    return Row(
      children: [
        // Enhanced Sidebar
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
              // Sidebar Header
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
                            Icons.people_outline,
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
                                'Dashboard de Clientes',
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
                    // Period Selector
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: _buildDesktopPeriodSelector(context, ctrl),
                    ),
                  ],
                ),
              ),

              // Sidebar Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildEnhancedSidebarKPIs(context, ctrl),
                      const SizedBox(height: 14),
                      _buildHealthCard(context, ctrl),
                      const SizedBox(height: 14),
                      _buildEnhancedQuickActionsCard(context, ctrl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: Container(
            color: ElegantLightTheme.backgroundColor,
            child: Column(
              children: [
                // Top KPI Bar
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
                  child: _buildTopKPIBar(ctrl),
                ),

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ctrl.refreshStats(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Charts Row
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildStatusDonutChart(context, ctrl),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFinancialBarChart(context, ctrl),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Performance Analytics
                          _buildPerformanceAnalytics(context, ctrl),

                          const SizedBox(height: 16),

                          // Financial Summary
                          _buildFinancialSummaryCard(ctrl),

                          const SizedBox(height: 16),

                          // Top Customers
                          _buildTopCustomersCard(context, ctrl),
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

  // ==================== COMPACT WIDGETS ====================

  Widget _buildTopKPIBar(CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildTopKPIItem(
            'Total Clientes',
            stats.total.toString(),
            Icons.people,
            ElegantLightTheme.primaryBlue,
          ),
        ),
        _buildVerticalDivider(),
        Expanded(
          child: _buildTopKPIItem(
            'Activos',
            stats.active.toString(),
            Icons.check_circle,
            const Color(0xFF10B981),
          ),
        ),
        _buildVerticalDivider(),
        Expanded(
          child: _buildTopKPIItem(
            'Tasa Activos',
            '${(stats.total > 0 ? (stats.active / stats.total * 100) : 0).toStringAsFixed(1)}%',
            Icons.trending_up,
            stats.active / (stats.total > 0 ? stats.total : 1) >= 0.8
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ),
        _buildVerticalDivider(),
        Expanded(
          child: _buildTopKPIItem(
            'Crédito Total',
            AppFormatters.formatCompactCurrency(stats.totalCreditLimit),
            Icons.credit_card,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
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

  Widget _buildCompactKPIGrid(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

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
            stats.total,
            Icons.people,
            ElegantLightTheme.primaryBlue,
          ),
          _buildMiniKPI(
            'Activos',
            stats.active,
            Icons.check_circle,
            const Color(0xFF10B981),
          ),
          _buildMiniKPI(
            'Inactivos',
            stats.inactive,
            Icons.pause_circle,
            const Color(0xFFF59E0B),
          ),
          _buildMiniKPI(
            'Suspendidos',
            stats.suspended,
            Icons.block,
            const Color(0xFFEF4444),
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

  Widget _buildQuickStatsBar(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    return Obx(() => FuturisticContainer(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ElegantLightTheme.primaryBlue.withValues(alpha: ctrl.isPeriodLoading ? 0.12 : 0.08),
          ElegantLightTheme.primaryBlue.withValues(alpha: ctrl.isPeriodLoading ? 0.06 : 0.03),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ctrl.isPeriodLoading ? 0.6 : 1.0,
        child: Row(
          children: [
            Expanded(
              child: _buildQuickStat(
                'Crédito',
                AppFormatters.formatCompactCurrency(stats.totalCreditLimit),
                const Color(0xFF10B981),
                Icons.credit_card,
              ),
            ),
            _buildQuickStatDivider(),
            Expanded(
              child: _buildQuickStat(
                'Balance',
                AppFormatters.formatCompactCurrency(stats.totalBalance),
                const Color(0xFFF59E0B),
                Icons.account_balance,
              ),
            ),
            _buildQuickStatDivider(),
            Expanded(
              child: _buildQuickStat(
                'Nuevos (${ctrl.currentPeriodLabel})',
                ctrl.newCustomersThisPeriod.toString(),
                ElegantLightTheme.primaryBlue,
                Icons.person_add,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildQuickStatDivider() {
    return Container(
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

  Widget _buildCompactChartsSection(BuildContext context, CustomerStatsController ctrl) {
    return Column(
      children: [
        _buildStatusDonutChart(context, ctrl),
        const SizedBox(height: 12),
        _buildFinancialBarChart(context, ctrl),
      ],
    );
  }

  // ==================== CHARTS ====================

  Widget _buildStatusDonutChart(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final segments = <ChartSegment>[];

    if (stats.active > 0) {
      segments.add(ChartSegment(
        label: 'Activos',
        value: stats.active.toDouble(),
        color: const Color(0xFF10B981),
        icon: Icons.check_circle,
      ));
    }

    if (stats.inactive > 0) {
      segments.add(ChartSegment(
        label: 'Inactivos',
        value: stats.inactive.toDouble(),
        color: const Color(0xFFF59E0B),
        icon: Icons.pause_circle,
      ));
    }

    if (stats.suspended > 0) {
      segments.add(ChartSegment(
        label: 'Suspendidos',
        value: stats.suspended.toDouble(),
        color: const Color(0xFFEF4444),
        icon: Icons.block,
      ));
    }

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
                'Estados de Clientes',
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
            child: segments.isEmpty
                ? Center(
                    child: Text(
                      'No hay datos disponibles',
                      style: TextStyle(color: ElegantLightTheme.textSecondary),
                    ),
                  )
                : Animated3DDonutChart(
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

  Widget _buildFinancialBarChart(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final creditLimit = stats.totalCreditLimit;
    final balance = stats.totalBalance;
    final available = creditLimit - balance;

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
                'Análisis Financiero',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnimatedFinancialBars(creditLimit, balance, available),
        ],
      ),
    );
  }

  Widget _buildAnimatedFinancialBars(double creditLimit, double balance, double available) {
    final maxValue = [creditLimit, balance, available].reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue > 0 ? maxValue : 100000.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildAnimatedBarWithLabel(
            label: 'Crédito',
            value: creditLimit,
            maxValue: effectiveMax,
            color: ElegantLightTheme.primaryBlue,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                ElegantLightTheme.primaryBlue.withValues(alpha: 0.8),
                ElegantLightTheme.primaryBlue,
                ElegantLightTheme.primaryBlueLight,
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildAnimatedBarWithLabel(
            label: 'Usado',
            value: balance,
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
            label: 'Disponible',
            value: available,
            maxValue: effectiveMax,
            color: const Color(0xFF10B981),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
            ),
          ),
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
        AnimatedVerticalBar(
          label: '',
          value: value,
          maxValue: maxValue,
          color: color,
          gradient: gradient,
          width: 50,
          height: 130,
          minFilledHeight: 50,
          animationDuration: const Duration(milliseconds: 1400),
        ),
        const SizedBox(height: 8),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: value > 0
                ? color.withValues(alpha: 0.12)
                : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value > 0
                  ? color.withValues(alpha: 0.2)
                  : ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Text(
            AppFormatters.formatCompactCurrency(value),
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

  // ==================== PERFORMANCE & HEALTH ====================

  Widget _buildPerformanceAnalytics(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final total = stats.total > 0 ? stats.total : 1;
    final activePercent = stats.active / total * 100;
    final inactivePercent = stats.inactive / total * 100;
    final suspendedPercent = stats.suspended / total * 100;

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
                  'Clientes Activos',
                  activePercent,
                  '%',
                  80,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Clientes Inactivos',
                  inactivePercent,
                  '%',
                  15,
                  Icons.pause_circle,
                  isInverted: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Suspendidos',
                  suspendedPercent,
                  '%',
                  5,
                  Icons.block,
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

  Widget _buildHealthCard(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final total = stats.total > 0 ? stats.total : 1;
    final activeRate = stats.active / total * 100;
    final suspendedRate = stats.suspended / total * 100;

    final isHealthy = activeRate >= 80 && suspendedRate <= 5;
    final hasIssues = activeRate < 60 || suspendedRate > 15;

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
        ? 'Cartera de clientes saludable'
        : hasIssues
            ? 'Requiere atención urgente'
            : 'Estado aceptable';

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
                      'Salud de Cartera',
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
          _buildProgressIndicator(
            'Tasa de Clientes Activos',
            activeRate,
            100,
            '%',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, double target, String unit) {
    final progress = (value / target).clamp(0.0, 1.0);
    final isGood = value >= 80;
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
        _buildAnimatedProgressBar(progress, color),
      ],
    );
  }

  Widget _buildAnimatedProgressBar(double percentage, Color color) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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
                    height: 6,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.85),
                          color,
                          color.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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

  // ==================== FINANCIAL & TOP CUSTOMERS ====================

  Widget _buildFinancialSummaryCard(CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final creditLimit = stats.totalCreditLimit;
    final balance = stats.totalBalance;
    final available = creditLimit - balance;

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
                'Resumen de Crédito',
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
                  'Total: ${AppFormatters.formatCurrency(creditLimit)}',
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
          _buildSalesProgressBar('Límite Total', creditLimit, creditLimit, ElegantLightTheme.primaryBlue),
          const SizedBox(height: 12),
          _buildSalesProgressBar('Utilizado', balance, creditLimit, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildSalesProgressBar('Disponible', available, creditLimit, const Color(0xFF10B981)),
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
        _buildAnimatedProgressBar(percentage / 100, color),
      ],
    );
  }

  Widget _buildActivityStatsCard(CustomerStatsController ctrl) {
    return Obx(() => FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ctrl.isPeriodLoading
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: ctrl.isPeriodLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'Actividad ${ctrl.currentPeriodLabel}',
                        key: ValueKey('activity_${ctrl.currentPeriod}'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      ctrl.periodDateRange,
                      style: TextStyle(
                        fontSize: 10,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: ctrl.isPeriodLoading ? 0.5 : 1.0,
            child: Column(
              children: [
                _buildActivityItem(
                  'Nuevos Clientes',
                  ctrl.newCustomersThisPeriod.toString(),
                  Icons.person_add,
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  'Clientes Activos',
                  ctrl.activeCustomersThisPeriod.toString(),
                  Icons.check_circle,
                  ElegantLightTheme.primaryBlue,
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  'Promedio Diario',
                  ctrl.daysInCurrentPeriod > 0
                      ? (ctrl.newCustomersThisPeriod / ctrl.daysInCurrentPeriod).toStringAsFixed(1)
                      : '0.0',
                  Icons.timeline,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildActivityItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
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

  Widget _buildTopCustomersCard(BuildContext context, CustomerStatsController ctrl) {
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
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Top Clientes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ctrl.topCustomers.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: ElegantLightTheme.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay clientes disponibles',
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...ctrl.topCustomers.asMap().entries.map((entry) {
              final index = entry.key;
              final customer = entry.value;

              final name = customer['name'] as String? ?? 'Cliente sin nombre';
              final totalPurchases = (customer['totalPurchases'] as num?)?.toDouble() ?? 0.0;
              final totalOrders = (customer['totalOrders'] as num?)?.toInt() ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTopCustomerItem(
                  context,
                  index + 1,
                  name,
                  totalPurchases,
                  totalOrders,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopCustomerItem(
    BuildContext context,
    int position,
    String name,
    double totalPurchases,
    int totalOrders,
  ) {
    Color positionColor;
    IconData positionIcon;
    LinearGradient positionGradient;

    switch (position) {
      case 1:
        positionColor = Colors.amber;
        positionIcon = Icons.looks_one;
        positionGradient = ElegantLightTheme.warningGradient;
        break;
      case 2:
        positionColor = Colors.grey.shade400;
        positionIcon = Icons.looks_two;
        positionGradient = ElegantLightTheme.glassGradient;
        break;
      case 3:
        positionColor = Colors.brown.shade400;
        positionIcon = Icons.looks_3;
        positionGradient = LinearGradient(
          colors: [Colors.brown.shade300, Colors.brown.shade500],
        );
        break;
      default:
        positionColor = ElegantLightTheme.primaryBlue;
        positionIcon = Icons.person;
        positionGradient = ElegantLightTheme.primaryGradient;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            positionColor.withValues(alpha: 0.08),
            positionColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: positionColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: positionGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: positionColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(positionIcon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totalPurchases > 0
                      ? '${AppFormatters.formatCompactCurrency(totalPurchases)} • $totalOrders órdenes'
                      : 'Sin compras registradas',
                  style: TextStyle(
                    fontSize: 11,
                    color: totalPurchases > 0
                        ? ElegantLightTheme.textSecondary
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR COMPONENTS ====================

  Widget _buildEnhancedSidebarKPIs(BuildContext context, CustomerStatsController ctrl) {
    final stats = ctrl.stats;
    if (stats == null) return const SizedBox.shrink();

    final total = stats.total > 0 ? stats.total : 1;
    final activePercent = stats.active / total * 100;

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
          'Total Clientes',
          stats.total.toString(),
          Icons.people,
          ElegantLightTheme.primaryBlue,
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Clientes Activos',
          '${stats.active} (${activePercent.toStringAsFixed(1)}%)',
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Crédito Total',
          AppFormatters.formatCompactCurrency(stats.totalCreditLimit),
          Icons.credit_card,
          const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 10),
        _buildEnhancedKPICard(
          'Balance Pendiente',
          AppFormatters.formatCompactCurrency(stats.totalBalance),
          Icons.account_balance,
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildEnhancedKPICard(String title, String value, IconData icon, Color color) {
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

  Widget _buildEnhancedQuickActionsCard(BuildContext context, CustomerStatsController ctrl) {
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
          _buildQuickActionButton(
            label: 'Nuevo Cliente',
            icon: Icons.person_add,
            color: ElegantLightTheme.primaryBlue,
            onTap: () => ctrl.goToCreateCustomer(),
            isPrimary: true,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            label: 'Ver Todos',
            icon: Icons.people_outline,
            color: ElegantLightTheme.textSecondary,
            onTap: () => ctrl.goToCustomersList(),
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
            border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.15)),
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

  // ==================== PERIOD SELECTOR ====================

  Widget _buildElegantPeriodSelector(BuildContext context, CustomerStatsController ctrl) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ctrl.isPeriodLoading
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
              : ElegantLightTheme.primaryBlue.withValues(alpha: 0.12),
          width: ctrl.isPeriodLoading ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: ctrl.isPeriodLoading ? 0.15 : 0.06),
            blurRadius: ctrl.isPeriodLoading ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: ctrl.isPeriodLoading
                      ? [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ctrl.isPeriodLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
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
                      'Período de Análisis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        ctrl.isPeriodLoading
                            ? 'Actualizando datos...'
                            : '${ctrl.currentPeriodLabel} • ${ctrl.periodDateRange}',
                        key: ValueKey('${ctrl.currentPeriod}_${ctrl.isPeriodLoading}'),
                        style: TextStyle(
                          fontSize: 10,
                          color: ctrl.isPeriodLoading
                              ? ElegantLightTheme.primaryBlue
                              : ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de carga pequeño
              if (ctrl.isPeriodLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ElegantLightTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cargando',
                        style: TextStyle(
                          fontSize: 10,
                          color: ElegantLightTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Primera fila de períodos
          Row(
            children: ctrl.availablePeriods.take(3).map((period) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildPeriodButton(ctrl, period),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Segunda fila de períodos
          Row(
            children: ctrl.availablePeriods.skip(3).map((period) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildPeriodButton(ctrl, period),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ));
  }

  Widget _buildPeriodButton(CustomerStatsController ctrl, Map<String, dynamic> period) {
    return Obx(() {
      final isSelected = ctrl.currentPeriod == period['value'];
      final isLoading = ctrl.isPeriodLoading;
      final label = period['label'] as String;

      return GestureDetector(
        onTap: isLoading ? null : () => ctrl.changePeriod(period['value'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
            color: isSelected
                ? null
                : isLoading
                    ? ElegantLightTheme.backgroundColor.withValues(alpha: 0.5)
                    : ElegantLightTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : ElegantLightTheme.textTertiary.withValues(alpha: isLoading ? 0.1 : 0.2),
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
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isLoading
                      ? ElegantLightTheme.textTertiary
                      : ElegantLightTheme.textSecondary,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDesktopPeriodSelector(BuildContext context, CustomerStatsController ctrl) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ctrl.isPeriodLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ctrl.isPeriodLoading
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: ctrl.isPeriodLoading
                ? Border.all(color: Colors.white.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  ctrl.isPeriodLoading ? 'Actualizando...' : ctrl.currentPeriodLabel,
                  key: ValueKey('desktop_${ctrl.currentPeriod}_${ctrl.isPeriodLoading}'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!ctrl.isPeriodLoading) ...[
                const SizedBox(height: 2),
                Text(
                  ctrl.periodDateRange,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ctrl.availablePeriods.map((period) {
            return _buildDesktopPeriodButton(ctrl, period);
          }).toList(),
        ),
      ],
    ));
  }

  Widget _buildDesktopPeriodButton(CustomerStatsController ctrl, Map<String, dynamic> period) {
    return Obx(() {
      final isSelected = ctrl.currentPeriod == period['value'];
      final isLoading = ctrl.isPeriodLoading;
      final label = period['label'] as String;

      return GestureDetector(
        onTap: isLoading ? null : () => ctrl.changePeriod(period['value'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: isLoading ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: isLoading ? 0.15 : 0.25),
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
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? ElegantLightTheme.primaryBlue
                  : Colors.white.withValues(alpha: isLoading ? 0.5 : 1.0),
            ),
            child: Text(label),
          ),
        ),
      );
    });
  }

  // ==================== FAB ====================

  Widget? _buildCompactFAB(BuildContext context) {
    if (!context.isMobile) return null;

    return FloatingActionButton(
      onPressed: () => controller.goToCreateCustomer(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ElegantLightTheme.glowShadow,
        ),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
