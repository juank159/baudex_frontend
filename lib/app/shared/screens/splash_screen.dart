// lib/app/shared/screens/splash_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/elegant_light_theme.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _backgroundController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialRoute();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _logoController.forward();
    _backgroundController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  Future<void> _checkInitialRoute() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      final authController = Get.find<AuthController>();
      final isAuthenticated = authController.isAuthenticated;

      if (!mounted) return;

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente elegante
          _buildAnimatedBackground(),
          // Contenido
          SafeArea(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(context),
              tablet: _buildTabletLayout(context),
              desktop: _buildDesktopLayout(context),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB), // Blue 600
                  Color(0xFF1D4ED8), // Blue 700
                  Color(0xFF1E40AF), // Blue 800
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: _SplashPatternPainter(
                animation: _backgroundAnimation,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildSplashContent(context, isMobile: true);
  }

  Widget _buildTabletLayout(BuildContext context) {
    return _buildSplashContent(context, isMobile: false);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Panel izquierdo con branding
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Circles decorativos
                      _buildDecorativeCircles(),
                      const SizedBox(height: 40),
                      Text(
                        'Bienvenido a',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Baudex',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Gestiona tu negocio con todas las\nherramientas que necesitas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panel derecho con splash principal
        Expanded(flex: 1, child: _buildSplashContent(context, isMobile: false)),
      ],
    );
  }

  Widget _buildDecorativeCircles() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo exterior
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          // Círculo medio
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
          // Círculo interior con glow
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashContent(BuildContext context, {required bool isMobile}) {
    final logoSize = isMobile ? 100.0 : 120.0;
    final titleSize = isMobile ? 32.0 : 40.0;
    final subtitleSize = isMobile ? 16.0 : 18.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado con glassmorfismo
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoAnimation.value,
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/baudex_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: context.verticalSpacing * 1.5),

          // Título animado
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Baudex',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.verticalSpacing / 2),

          // Subtítulo animado
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Inicializando...',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.verticalSpacing * 2),

          // Barra de progreso con gradiente y glow
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Container(
                    width: isMobile ? 200 : 260,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFBFDBFE), // Blue 200
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: context.verticalSpacing * 2),

          // Versión
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para patrón decorativo de fondo
class _SplashPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _SplashPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final time = animation.value * 2 * math.pi;

    // Círculos grandes decorativos translúcidos
    final circles = [
      _CircleConfig(
        cx: size.width * 0.85,
        cy: size.height * 0.15,
        radius: 180,
        opacity: 0.06,
        phaseOffset: 0,
      ),
      _CircleConfig(
        cx: size.width * 0.1,
        cy: size.height * 0.8,
        radius: 220,
        opacity: 0.05,
        phaseOffset: math.pi / 3,
      ),
      _CircleConfig(
        cx: size.width * 0.7,
        cy: size.height * 0.7,
        radius: 140,
        opacity: 0.04,
        phaseOffset: math.pi / 2,
      ),
      _CircleConfig(
        cx: size.width * 0.3,
        cy: size.height * 0.3,
        radius: 100,
        opacity: 0.05,
        phaseOffset: math.pi,
      ),
    ];

    for (final circle in circles) {
      final offsetX = math.sin(time + circle.phaseOffset) * 15;
      final offsetY = math.cos(time + circle.phaseOffset) * 10;

      paint.color = Colors.white.withOpacity(circle.opacity);
      canvas.drawCircle(
        Offset(circle.cx + offsetX, circle.cy + offsetY),
        circle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPatternPainter oldDelegate) => true;
}

class _CircleConfig {
  final double cx, cy, radius, opacity, phaseOffset;
  _CircleConfig({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.opacity,
    required this.phaseOffset,
  });
}
