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
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../app/shared/widgets/app_drawer.dart';

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

        // Profitability Section con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
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

        // Profitability Section - Segunda fila con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Two column layout for activity and notifications - Tercera fila con animaciones en paralelo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera fila: Resumen Financiero unificado con animación futurística
        _buildAnimatedCard(
          const SizedBox(
            height: 580,
            child: DashboardChartsSection(),
          ),
          delay: 200,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Segunda fila: Profitabilidad FIFO con animación
        _buildAnimatedCard(
          const ProfitabilitySection(),
          delay: 400,
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Tercera fila: Grid de componentes adicionales con animaciones en paralelo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
