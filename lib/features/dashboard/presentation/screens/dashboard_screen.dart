// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/profitability_section.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/notifications_panel.dart';
import '../widgets/period_selector.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/bank_accounts_summary.dart';
import '../widgets/income_breakdown_widget.dart';
import '../widgets/accounts_receivable_widget.dart';
import '../widgets/currency_breakdown_widget.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';
import '../../../../app/data/local/full_sync_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  DashboardController get controller => Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: ElegantLightTheme.elasticCurve),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _animationController.forward();
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildFuturisticAppBar(),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: controller.refreshAll,
                backgroundColor: ElegantLightTheme.backgroundColor,
                color: ElegantLightTheme.primaryBlue,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    children: [
                      // FASE 6: Banner de Full Sync en progreso
                      _buildFullSyncBanner(),
                      // Selector de períodos con animación
                      _buildAnimatedPeriodSelector(),
                      const SizedBox(height: AppDimensions.spacingMedium),

                      // Contenido responsivo
                      ResponsiveBuilder(
                        mobile: _buildMobileLayout(),
                        tablet: _buildTabletLayout(),
                        desktop: _buildDesktopLayout(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                // Patrón de puntos diagonal
                Positioned(
                  bottom: 0,
                  right: 0,
                  width: 600,
                  height: 800,
                  child: CustomPaint(
                    painter: DiagonalDotPatternPainter(
                      animation: _backgroundAnimation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.dashboard,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Dashboard',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menú',
        ),
      ),
      actions: [
        // FASE 6: Indicador de estado de sincronización
        const SyncStatusIcon(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshAll,
          tooltip: 'Actualizar datos',
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElegantLightTheme.primaryGradient.colors.first,
              ElegantLightTheme.primaryGradient.colors.last,
              ElegantLightTheme.primaryBlue,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.5),
    );
  }

  /// FASE 6: Banner que muestra el progreso del Full Sync
  Widget _buildFullSyncBanner() {
    try {
      if (!Get.isRegistered<FullSyncService>()) return const SizedBox.shrink();
      final fullSync = Get.find<FullSyncService>();

      return Obx(() {
        if (!fullSync.isSyncing.value) return const SizedBox.shrink();

        final overall = fullSync.overallProgress.value;
        final percent = (overall * 100).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Actualizando datos en segundo plano ($percent%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => fullSync.abortSync(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: overall > 0 ? overall : null,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAnimatedPeriodSelector() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // Asegurar que el valor esté siempre entre 0.0 y 1.0
        final safeValue = value.clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: 0.8 + (0.2 * safeValue),
          child: Opacity(
            opacity: safeValue,
            child: const PeriodSelector(),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section unificada con animación
        _buildAnimatedCard(
          const DashboardChartsSection(),
          delay: 200,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Income Breakdown Widget con animación
        Obx(() {
          final stats = controller.dashboardStats;
          if (stats == null) return const SizedBox.shrink();
          final rec = stats.receivables;
          return Column(
            children: [
              _buildAnimatedCard(
                IncomeBreakdownWidget(stats: stats),
                delay: 250,
              ),
              if (rec != null && rec.hasAny) ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                _buildAnimatedCard(
                  AccountsReceivableWidget(receivables: rec),
                  delay: 300,
                ),
              ],
              const SizedBox(height: AppDimensions.spacingMedium),
            ],
          );
        }),

        // Currency Breakdown Widget (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final showCurrency = stats != null &&
              stats.multiCurrencyEnabled &&
              stats.currencyBreakdown != null &&
              stats.currencyBreakdown!.isNotEmpty;
          if (!showCurrency) return const SizedBox.shrink();
          return Column(
            children: [
              _buildAnimatedCard(
                CurrencyBreakdownWidget(stats: stats),
                delay: 260,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
            ],
          );
        }),

        // Cuentas por Cobrar (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final receivable = stats?.sales.accountsReceivable ?? 0;
          if (receivable <= 0) return const SizedBox.shrink();
          final count = stats?.sales.receivableCount ?? 0;
          return Column(
            children: [
              _buildAnimatedCard(
                _buildReceivablesCard(receivable, count),
                delay: 270,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
            ],
          );
        }),

        // Expense Pie Chart con animación (sin altura fija para móvil)
        _buildAnimatedCard(
          const ExpensePieChart(),
          delay: 300,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Profitability Section con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Bank Accounts Summary con animación
        _buildAnimatedCard(
          Obx(() => BankAccountsSummaryWidget(
            startDate: controller.selectedDateRange?.start,
            endDate: controller.selectedDateRange?.end,
          )),
          delay: 500,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Recent Activity con animación
        _buildAnimatedCard(
          const RecentActivityCard(),
          delay: 600,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Notifications con animación
        _buildAnimatedCard(
          const NotificationsPanel(),
          delay: 800,
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section unificada - Primera fila con animación
        _buildAnimatedCard(
          const SizedBox(
            height: 580,
            child: DashboardChartsSection(),
          ),
          delay: 200,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Income Breakdown Widget - Segunda fila con animación
        Obx(() {
          final stats = controller.dashboardStats;
          if (stats == null) return const SizedBox.shrink();
          final rec = stats.receivables;
          return Column(
            children: [
              _buildAnimatedCard(
                IncomeBreakdownWidget(stats: stats),
                delay: 250,
              ),
              if (rec != null && rec.hasAny) ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                _buildAnimatedCard(
                  AccountsReceivableWidget(receivables: rec),
                  delay: 300,
                ),
              ],
              const SizedBox(height: AppDimensions.spacingLarge),
            ],
          );
        }),

        // Currency Breakdown Widget (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final showCurrency = stats != null &&
              stats.multiCurrencyEnabled &&
              stats.currencyBreakdown != null &&
              stats.currencyBreakdown!.isNotEmpty;
          if (!showCurrency) return const SizedBox.shrink();
          return Column(
            children: [
              _buildAnimatedCard(
                CurrencyBreakdownWidget(stats: stats),
                delay: 260,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
            ],
          );
        }),

        // Cuentas por Cobrar (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final receivable = stats?.sales.accountsReceivable ?? 0;
          if (receivable <= 0) return const SizedBox.shrink();
          final count = stats?.sales.receivableCount ?? 0;
          return Column(
            children: [
              _buildAnimatedCard(
                _buildReceivablesCard(receivable, count),
                delay: 270,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
            ],
          );
        }),

        // Expense Pie Chart - Tercera fila con animación
        _buildAnimatedCard(
          const SizedBox(
            height: 350,
            child: ExpensePieChart(),
          ),
          delay: 300,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Profitability Section - Tercera fila con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Bank Accounts Summary - Cuarta fila con animación
        _buildAnimatedCard(
          Obx(() => BankAccountsSummaryWidget(
            startDate: controller.selectedDateRange?.start,
            endDate: controller.selectedDateRange?.end,
          )),
          delay: 500,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Two column layout for activity and notifications
        // Usar altura fija para que ambas columnas tengan el mismo tamaño
        SizedBox(
          height: 450, // Altura fija para ambas columnas en tablet
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _buildAnimatedCard(
                  const RecentActivityCard(),
                  delay: 600,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Expanded(
                flex: 3,
                child: _buildAnimatedCard(
                  const NotificationsPanel(),
                  delay: 700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera fila: Análisis Financiero y Desglose de Ingresos en 2 columnas
        SizedBox(
          height: 580,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna 1: Análisis Financiero (Dashboard Charts)
              Expanded(
                flex: 3,
                child: _buildAnimatedCard(
                  const DashboardChartsSection(),
                  delay: 200,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingLarge),

              // Columna 2: Desglose de Ingresos + Cuentas por Cobrar
              Expanded(
                flex: 2,
                child: Obx(() {
                  final stats = controller.dashboardStats;
                  if (stats == null) return const SizedBox.shrink();
                  final rec = stats.receivables;
                  final showReceivables = rec != null && rec.hasAny;
                  return Column(
                    children: [
                      // Ocupa toda la altura si no hay receivables, o ~55% si sí.
                      // Ambos widgets tienen scroll interno, así que quepan sin overflow.
                      Expanded(
                        flex: showReceivables ? 11 : 20,
                        child: _buildAnimatedCard(
                          IncomeBreakdownWidget(stats: stats),
                          delay: 250,
                        ),
                      ),
                      if (showReceivables) ...[
                        const SizedBox(height: AppDimensions.spacingMedium),
                        Expanded(
                          flex: 9,
                          child: _buildAnimatedCard(
                            AccountsReceivableWidget(receivables: rec),
                            delay: 300,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Cuentas por Cobrar (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final receivable = stats?.sales.accountsReceivable ?? 0;
          if (receivable <= 0) return const SizedBox.shrink();
          final count = stats?.sales.receivableCount ?? 0;
          return Column(
            children: [
              _buildAnimatedCard(
                _buildReceivablesCard(receivable, count),
                delay: 270,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
            ],
          );
        }),

        // Segunda fila: Expense Pie Chart + Currency Breakdown (condicional)
        Obx(() {
          final stats = controller.dashboardStats;
          final showCurrency = stats != null &&
              stats.multiCurrencyEnabled &&
              stats.currencyBreakdown != null &&
              stats.currencyBreakdown!.isNotEmpty;

          if (showCurrency) {
            return SizedBox(
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildAnimatedCard(
                      const ExpensePieChart(),
                      delay: 300,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingLarge),
                  Expanded(
                    flex: 2,
                    child: _buildAnimatedCard(
                      CurrencyBreakdownWidget(stats: stats),
                      delay: 350,
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildAnimatedCard(
            const SizedBox(
              height: 350,
              child: ExpensePieChart(),
            ),
            delay: 300,
          );
        }),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Tercera fila: Análisis de Rentabilidad con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Cuarta fila: Bank Accounts Summary con animación
        _buildAnimatedCard(
          Obx(() => BankAccountsSummaryWidget(
            startDate: controller.selectedDateRange?.start,
            endDate: controller.selectedDateRange?.end,
          )),
          delay: 500,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Quinta fila: Grid de componentes adicionales con animaciones en paralelo
        // Usar altura fija para que ambas columnas tengan el mismo tamaño
        SizedBox(
          height: 480, // Altura fija para ambas columnas
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna izquierda
              Expanded(
                flex: 6,
                child: _buildAnimatedCard(
                  const RecentActivityCard(),
                  delay: 600,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),

              // Columna derecha
              Expanded(
                flex: 4,
                child: _buildAnimatedCard(
                  const NotificationsPanel(),
                  delay: 700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget child, {required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: ElegantLightTheme.elasticCurve,
      builder: (context, value, _) {
        // Asegurar que el valor esté siempre entre 0.0 y 1.0
        final safeValue = value.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, 30 * (1 - safeValue)),
          child: Transform.scale(
            scale: 0.9 + (0.1 * safeValue),
            child: Opacity(
              opacity: safeValue,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: (0.1 * safeValue).clamp(0.0, 1.0)),
                      Colors.white.withValues(alpha: (0.05 * safeValue).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: (0.1 * safeValue).clamp(0.0, 1.0)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: (0.1 * safeValue).clamp(0.0, 1.0)),
                      blurRadius: (20 * safeValue).clamp(0.0, 20.0),
                      offset: Offset(0, (10 * safeValue).clamp(0.0, 10.0)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceivablesCard(double receivable, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.12),
            const Color(0xFFF59E0B).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuentas por Cobrar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count factura${count == 1 ? '' : 's'} pendiente${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.formatCurrency(receivable),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalDotPatternPainter extends CustomPainter {
  final Animation<double> animation;

  DiagonalDotPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Configuración del patrón de puntos
    const double dotSize = 3.0;
    const double spacing = 15.0;
    
    // Crear el patrón diagonal desde la esquina inferior derecha
    for (double diagonal = 0; diagonal < size.width + size.height; diagonal += spacing) {
      for (double offset = 0; offset < diagonal; offset += spacing) {
        // Calcular posición del punto en la diagonal
        final double x = size.width - offset;
        final double y = size.height - (diagonal - offset);
        
        // Solo dibujar si está dentro de los límites
        if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
          // Calcular distancia desde la esquina inferior derecha para opacidad
          final double distanceFromCorner = math.sqrt(
            math.pow(size.width - x, 2) + math.pow(size.height - y, 2)
          );
          
          // Calcular opacidad basada en la distancia
          final double maxDistance = 300.0; // Distancia máxima visible
          double opacity = 1.0 - (distanceFromCorner / maxDistance);
          opacity = opacity.clamp(0.0, 1.0);
          
          // Solo dibujar si la opacidad es significativa
          if (opacity > 0.1) {
            // Usar gradiente de colores del AppBar
            Color finalColor;
            if (opacity > 0.7) {
              finalColor = ElegantLightTheme.primaryGradient.colors.first;
            } else if (opacity > 0.4) {
              finalColor = ElegantLightTheme.primaryGradient.colors.last;
            } else {
              finalColor = ElegantLightTheme.primaryBlue;
            }
            
            paint.color = finalColor.withValues(alpha: opacity);
            
            // Dibujar el punto con tamaño variable
            canvas.drawCircle(
              Offset(x, y),
              dotSize * (0.5 + opacity * 0.5), // Tamaño variable
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
