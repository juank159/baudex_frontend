// lib/app/shared/animations/stats_animations.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class StatsAnimations {
  static const Duration shortDuration = Duration(milliseconds: 800);
  static const Duration mediumDuration = Duration(milliseconds: 1200);
  static const Duration longDuration = Duration(milliseconds: 1500);
  
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.bounceOut;

  /// Animación de contador numérico que se incrementa rápidamente
  static Widget animatedCounter({
    required int value,
    required TextStyle style,
    Duration duration = mediumDuration,
    Curve curve = elasticCurve,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo, // Curva que empieza rápido y se ralentiza
      builder: (context, animatedValue, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: style.color!.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            '$animatedValue',
            style: style.copyWith(
              shadows: [
                Shadow(
                  color: style.color!.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Animación de porcentaje que se incrementa rápidamente
  static Widget animatedPercentage({
    required double value,
    required TextStyle style,
    Duration duration = mediumDuration,
    Curve curve = elasticCurve,
    int decimals = 1,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value * 100),
      duration: duration,
      curve: Curves.easeOutExpo, // Curva que empieza rápido y se ralentiza
      builder: (context, animatedValue, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: style.color!.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 1),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Text(
            '${animatedValue.toStringAsFixed(decimals)}%',
            style: style.copyWith(
              shadows: [
                Shadow(
                  color: style.color!.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Animación de barra de progreso que se llena progresivamente
  static Widget animatedProgressBar({
    required double value,
    required LinearGradient gradient,
    required double height,
    required double borderRadius,
    Duration duration = mediumDuration,
    Curve curve = smoothCurve,
    Duration fillDelay = const Duration(milliseconds: 300),
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: value),
          duration: duration,
          curve: Curves.easeOutExpo, // Curva que se llena rápido al inicio y se ralentiza
          builder: (context, animatedValue, child) {
            return Stack(
              children: [
                // Barra de progreso principal con animación progresiva
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shimmer effect solo cuando está completamente llena
                if (animatedValue >= value * 0.98) // Casi completamente llena
                  _ShimmerEffect(
                    widthFactor: animatedValue,
                    borderRadius: borderRadius,
                    gradient: gradient,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Animación de entrada con slide y fade
  static Widget slideInFadeIn({
    required Widget child,
    Duration duration = shortDuration,
    Curve curve = smoothCurve,
    Offset beginOffset = const Offset(0, 0.3),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - value) * 50,
            beginOffset.dy * (1 - value) * 50,
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Animación de escala con pulse
  static Widget pulseScale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // This creates a continuous pulse effect
      },
      child: child,
    );
  }

  /// Animación de moneda (para valores monetarios)
  static Widget animatedCurrency({
    required double value,
    required TextStyle style,
    Duration duration = mediumDuration,
    Curve curve = elasticCurve,
    String symbol = '\$',
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        // Format with thousands separator
        final formattedValue = animatedValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        return Text(
          '$symbol$formattedValue',
          style: style,
        );
      },
    );
  }

  /// Gráfico de dona animado con efectos espectaculares
  static Widget animatedDonutChart({
    required double size,
    required List<DonutSegment> segments,
    Duration duration = const Duration(milliseconds: 2000),
    Duration staggerDelay = const Duration(milliseconds: 300),
    bool showCenterText = true,
    String? centerText,
    TextStyle? centerTextStyle,
  }) {
    return _AnimatedDonutChart(
      size: size,
      segments: segments,
      duration: duration,
      staggerDelay: staggerDelay,
      showCenterText: showCenterText,
      centerText: centerText,
      centerTextStyle: centerTextStyle,
    );
  }

  /// Partícula flotante con física realista
  static Widget floatingParticle({
    required Widget child,
    Duration duration = const Duration(seconds: 4),
    double amplitude = 20.0,
    bool repeat = true,
  }) {
    return _FloatingParticle(
      duration: duration,
      amplitude: amplitude,
      repeat: repeat,
      child: child,
    );
  }

  /// Efecto de brillo pulsante en el borde
  static Widget glowingBorder({
    required Widget child,
    required Color glowColor,
    double glowRadius = 10.0,
    Duration duration = const Duration(seconds: 2),
  }) {
    return _GlowingBorder(
      glowColor: glowColor,
      glowRadius: glowRadius,
      duration: duration,
      child: child,
    );
  }

  /// Efecto de partículas que orbitan
  static Widget orbitingParticles({
    required Widget child,
    required double radius,
    int particleCount = 6,
    Duration duration = const Duration(seconds: 8),
  }) {
    return _OrbitingParticles(
      radius: radius,
      particleCount: particleCount,
      duration: duration,
      child: child,
    );
  }

  /// Ciclo de vida de partículas orgánicas (deshabilitado)
  static Widget particleLifeCycle({
    required Widget child,
    required double width,
    required double height,
    Duration cycleDuration = const Duration(seconds: 6),
    int particleCount = 0, // Sin partículas
  }) {
    return child; // Retorna solo el child sin efectos
  }
}

/// Datos para segmento de dona
class DonutSegment {
  final double value;
  final Color color;
  final LinearGradient? gradient;
  final String label;
  final double strokeWidth;

  DonutSegment({
    required this.value,
    required this.color,
    this.gradient,
    required this.label,
    this.strokeWidth = 12.0,
  });
}

class _ShimmerEffect extends StatefulWidget {
  final double widthFactor;
  final double borderRadius;
  final LinearGradient? gradient;

  const _ShimmerEffect({
    required this.widthFactor,
    required this.borderRadius,
    this.gradient,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widget.widthFactor,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
                end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// Gráfico de dona animado con efectos espectaculares
class _AnimatedDonutChart extends StatefulWidget {
  final double size;
  final List<DonutSegment> segments;
  final Duration duration;
  final Duration staggerDelay;
  final bool showCenterText;
  final String? centerText;
  final TextStyle? centerTextStyle;

  const _AnimatedDonutChart({
    required this.size,
    required this.segments,
    required this.duration,
    required this.staggerDelay,
    required this.showCenterText,
    this.centerText,
    this.centerTextStyle,
  });

  @override
  State<_AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<_AnimatedDonutChart>
    with TickerProviderStateMixin {
  late List<AnimationController> _segmentControllers;
  late List<Animation<double>> _segmentAnimations;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controladores para cada segmento con animación escalonada
    _segmentControllers = List.generate(
      widget.segments.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    // Animaciones de segmento con curvas elásticas
    _segmentAnimations = _segmentControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();

    // Animación de pulso para el centro
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación de brillo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Iniciar animaciones escalonadas
    _startStaggeredAnimations();
    
    // Iniciar animaciones continuas
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  void _startStaggeredAnimations() async {
    for (int i = 0; i < _segmentControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: widget.staggerDelay.inMilliseconds * i));
      if (mounted) {
        _segmentControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _segmentControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gráfico de dona principal
          AnimatedBuilder(
            animation: Listenable.merge(_segmentAnimations),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _SpectacularDonutPainter(
                  segments: widget.segments,
                  segmentAnimations: _segmentAnimations,
                ),
              );
            },
          ),

          // Texto central con pulso
          if (widget.showCenterText)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.centerText ?? '',
                      style: widget.centerTextStyle?.copyWith(
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

          // Sin partículas flotantes adicionales
        ],
      ),
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(6, (index) {
      final angle = (index * 2 * 3.14159) / 6;
      final radius = widget.size * 0.4;
      
      return Positioned(
        left: widget.size / 2 + radius * _cos(angle) - 4,
        top: widget.size / 2 + radius * _sin(angle) - 4,
        child: _FloatingParticle(
          duration: Duration(seconds: 3 + index),
          amplitude: 15.0,
          repeat: true,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.segments[index % widget.segments.length].color,
              boxShadow: [
                BoxShadow(
                  color: widget.segments[index % widget.segments.length].color.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Painter personalizado para el gráfico de dona espectacular
class _SpectacularDonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final List<Animation<double>> segmentAnimations;

  _SpectacularDonutPainter({
    required this.segments,
    required this.segmentAnimations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    
    double startAngle = -3.14159 / 2;
    double totalValue = segments.fold(0.0, (sum, segment) => sum + segment.value);

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final animation = segmentAnimations[i];
      final sweepAngle = (segment.value / totalValue) * 2 * 3.14159 * animation.value;

      if (sweepAngle > 0) {
        // Sombra del segmento
        _drawSegmentShadow(canvas, center, radius, startAngle, sweepAngle, segment);
        
        // Segmento principal con gradiente
        _drawSegmentWithGradient(canvas, center, radius, startAngle, sweepAngle, segment);
        
        // Efecto de brillo
        _drawSegmentGlow(canvas, center, radius, startAngle, sweepAngle, segment, animation.value);
        
        // Líneas de separación elegantes
        _drawSeparatorLines(canvas, center, radius, startAngle, segment);
        
        startAngle += sweepAngle;
      }
    }

    // Sin anillo interior
  }

  void _drawSegmentShadow(Canvas canvas, Offset center, double radius, 
                         double startAngle, double sweepAngle, DonutSegment segment) {
    final shadowPaint = Paint()
      ..color = segment.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = segment.strokeWidth + 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center.translate(2, 4), radius: radius),
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );
  }

  void _drawSegmentWithGradient(Canvas canvas, Offset center, double radius,
                               double startAngle, double sweepAngle, DonutSegment segment) {
    final gradient = segment.gradient ?? LinearGradient(
      colors: [segment.color, segment.color.withOpacity(0.7)],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = segment.strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawSegmentGlow(Canvas canvas, Offset center, double radius,
                       double startAngle, double sweepAngle, DonutSegment segment, double animationValue) {
    final glowPaint = Paint()
      ..color = segment.color.withOpacity(0.4 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = segment.strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  void _drawSeparatorLines(Canvas canvas, Offset center, double radius, double startAngle, DonutSegment segment) {
    final separatorPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final outerRadius = radius + segment.strokeWidth / 2;
    final innerRadius = radius - segment.strokeWidth / 2;

    // Línea de inicio
    final startX1 = center.dx + innerRadius * _cos(startAngle);
    final startY1 = center.dy + innerRadius * _sin(startAngle);
    final startX2 = center.dx + outerRadius * _cos(startAngle);
    final startY2 = center.dy + outerRadius * _sin(startAngle);

    canvas.drawLine(Offset(startX1, startY1), Offset(startX2, startY2), separatorPaint);
  }

  void _drawInnerRing(Canvas canvas, Offset center, double radius) {
    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, glassPaint);
    
    // Reflejo de vidrio
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      3.14159,
      false,
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Partícula flotante con movimiento orgánico
class _FloatingParticle extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;
  final bool repeat;

  const _FloatingParticle({
    required this.child,
    required this.duration,
    required this.amplitude,
    required this.repeat,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _offsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(widget.amplitude * 0.7, -widget.amplitude),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(widget.amplitude * 0.7, -widget.amplitude),
          end: Offset(-widget.amplitude * 0.3, -widget.amplitude * 0.5),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(-widget.amplitude * 0.3, -widget.amplitude * 0.5),
          end: Offset(widget.amplitude * 0.2, widget.amplitude * 0.3),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(widget.amplitude * 0.2, widget.amplitude * 0.3),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25.0,
      ),
    ]).animate(_controller);

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Efecto de brillo pulsante
class _GlowingBorder extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;

  const _GlowingBorder({
    required this.child,
    required this.glowColor,
    required this.glowRadius,
    required this.duration,
  });

  @override
  State<_GlowingBorder> createState() => _GlowingBorderState();
}

class _GlowingBorderState extends State<_GlowingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.6 * _animation.value),
                blurRadius: widget.glowRadius * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Partículas que orbitan alrededor
class _OrbitingParticles extends StatefulWidget {
  final Widget child;
  final double radius;
  final int particleCount;
  final Duration duration;

  const _OrbitingParticles({
    required this.child,
    required this.radius,
    required this.particleCount,
    required this.duration,
  });

  @override
  State<_OrbitingParticles> createState() => _OrbitingParticlesState();
}

class _OrbitingParticlesState extends State<_OrbitingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            ...List.generate(widget.particleCount, (index) {
              final angle = _animation.value + (index * 2 * 3.14159 / widget.particleCount);
              final x = widget.radius * _cos(angle);
              final y = widget.radius * _sin(angle);
              
              // Colores espectaculares: Verde, Azul, Naranja
              final colors = [
                [Color(0xFF10B981), Color(0xFF34D399)], // Verde esmeralda
                [Color(0xFF3B82F6), Color(0xFF60A5FA)], // Azul brillante
                [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Naranja dorado
              ];
              
              final particleColors = colors[index % colors.length];
              
              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        particleColors[1].withOpacity(0.9),
                        particleColors[0].withOpacity(0.6),
                        particleColors[0].withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.4, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: particleColors[0].withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: particleColors[1].withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          particleColors[1].withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// Ciclo de vida de partículas orgánicas
class _ParticleLifeCycle extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Duration cycleDuration;
  final int particleCount;

  const _ParticleLifeCycle({
    required this.child,
    required this.width,
    required this.height,
    required this.cycleDuration,
    required this.particleCount,
  });

  @override
  State<_ParticleLifeCycle> createState() => _ParticleLifeCycleState();
}

class _ParticleLifeCycleState extends State<_ParticleLifeCycle>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _positionAnimations;
  
  // Colores para las partículas que coinciden con el gráfico de dona
  final List<List<Color>> particleColors = [
    [Color(0xFF10B981), Color(0xFF34D399)], // Verde esmeralda - Recibidos
    [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Naranja dorado - Parciales
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Púrpura vibrante - Pendientes
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startLifeCycle();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      widget.particleCount,
      (index) => AnimationController(
        duration: widget.cycleDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        // Nacimiento: crece suavemente
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 25.0,
        ),
        // Vida: tamaño estable con pulso más sutil
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.02)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 30.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.02, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 25.0,
        ),
        // Muerte: desaparece muy gradualmente
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 20.0,
        ),
      ]).animate(controller);
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        // Aparición gradual
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          weight: 15.0,
        ),
        // Vida plena
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          weight: 60.0,
        ),
        // Desvanecimiento
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          weight: 25.0,
        ),
      ]).animate(controller);
    }).toList();

    _positionAnimations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      
      // Movimiento circular simple alrededor de la dona
      final paths = [
        // Movimiento circular suave alrededor del centro
        [
          Offset(0.5, 0.2), // Arriba
          Offset(0.75, 0.35), // Arriba derecha
          Offset(0.8, 0.5), // Derecha
          Offset(0.75, 0.65), // Abajo derecha
          Offset(0.5, 0.8), // Abajo
          Offset(0.25, 0.65), // Abajo izquierda
          Offset(0.2, 0.5), // Izquierda
          Offset(0.25, 0.35), // Arriba izquierda
        ],
      ];
      
      final pathPoints = paths[index % paths.length];
      final numPoints = pathPoints.length;
      final weightPerSegment = 100.0 / numPoints;
      
      // Crear segmentos dinámicos basados en el número de puntos
      final List<TweenSequenceItem<Offset>> segments = [];
      
      for (int i = 0; i < numPoints; i++) {
        final startPoint = pathPoints[i];
        final endPoint = pathPoints[(i + 1) % numPoints];
        
        // Movimiento circular ultra suave
        Curve segmentCurve = Curves.easeInOutSine;
        
        segments.add(
          TweenSequenceItem(
            tween: Tween<Offset>(begin: startPoint, end: endPoint)
                .chain(CurveTween(curve: segmentCurve)),
            weight: weightPerSegment,
          ),
        );
      }
      
      return TweenSequence<Offset>(segments).animate(controller);
    }).toList();
  }

  void _startLifeCycle() async {
    // Iniciar la única partícula inmediatamente
    for (int i = 0; i < _controllers.length; i++) {
      if (mounted) {
        _controllers[i].repeat();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asegurar que las dimensiones sean válidas
    final safeWidth = widget.width.isFinite && widget.width > 0 ? widget.width : 300.0;
    final safeHeight = widget.height.isFinite && widget.height > 0 ? widget.height : 200.0;
    
    return Container(
      width: safeWidth,
      height: safeHeight,
      child: Stack(
        children: [
          // Contenido principal
          widget.child,
          
          // Partículas con ciclo de vida
          ...List.generate(widget.particleCount, (index) {
            return AnimatedBuilder(
              animation: Listenable.merge([
                _scaleAnimations[index],
                _opacityAnimations[index],
                _positionAnimations[index],
              ]),
              builder: (context, child) {
                // Usar el primer color de la paleta (dorado/amarillo) para la única partícula
                final colors = [Color(0xFFFFD700), Color(0xFFFFA500)]; // Dorado brillante
                final position = _positionAnimations[index].value;
                final scale = _scaleAnimations[index].value;
                final opacity = _opacityAnimations[index].value;
                
                // Validar que todos los valores sean finitos
                final safeDx = position.dx.isFinite ? position.dx : 0.5;
                final safeDy = position.dy.isFinite ? position.dy : 0.5;
                final safeScale = scale.isFinite && scale > 0 ? scale : 0.0;
                final safeOpacity = opacity.isFinite && opacity >= 0 && opacity <= 1 ? opacity : 0.0;
                
                // Si la escala o opacidad son 0, no renderizar
                if (safeScale == 0.0 || safeOpacity == 0.0) {
                  return const SizedBox.shrink();
                }
                
                return Positioned(
                  left: (safeDx * safeWidth - 30).clamp(-30.0, safeWidth),
                  top: (safeDy * safeHeight - 30).clamp(-30.0, safeHeight),
                  child: Transform.scale(
                    scale: safeScale.clamp(0.0, 3.0),
                    child: Opacity(
                      opacity: safeOpacity,
                      child: Container(
                        width: 60, // Partículas más grandes
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors[1].withOpacity(0.9),
                              colors[0].withOpacity(0.7),
                              colors[0].withOpacity(0.4),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.3, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors[0].withOpacity((0.6 * safeOpacity).clamp(0.0, 1.0)),
                              blurRadius: (25 * safeScale).clamp(0.0, 50.0),
                              spreadRadius: (5 * safeScale).clamp(0.0, 10.0),
                            ),
                            BoxShadow(
                              color: colors[1].withOpacity((0.8 * safeOpacity).clamp(0.0, 1.0)),
                              blurRadius: (15 * safeScale).clamp(0.0, 30.0),
                              spreadRadius: (2 * safeScale).clamp(0.0, 5.0),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity((0.4 * safeOpacity).clamp(0.0, 1.0)),
                              blurRadius: (10 * safeScale).clamp(0.0, 20.0),
                              spreadRadius: (1 * safeScale).clamp(0.0, 3.0),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity((0.8 * safeOpacity).clamp(0.0, 1.0)),
                                colors[1].withOpacity((0.1 * safeOpacity).clamp(0.0, 1.0)),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// Funciones matemáticas auxiliares
double _cos(double radians) => math.cos(radians);
double _sin(double radians) => math.sin(radians);