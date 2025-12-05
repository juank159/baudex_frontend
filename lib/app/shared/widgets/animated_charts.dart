// lib/app/shared/widgets/animated_charts.dart
// Widgets compartidos para gráficos animados reutilizables
// Principio DRY - Don't Repeat Yourself

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/elegant_light_theme.dart';

/// Datos para un segmento del gráfico
class ChartSegment {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

/// Gráfico de dona 3D animado reutilizable
class Animated3DDonutChart extends StatefulWidget {
  final List<ChartSegment> segments;
  final double size;
  final Duration animationDuration;
  final bool showLegend;
  final Widget? centerWidget;

  const Animated3DDonutChart({
    super.key,
    required this.segments,
    this.size = 200,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.showLegend = true,
    this.centerWidget,
  });

  @override
  State<Animated3DDonutChart> createState() => _Animated3DDonutChartState();
}

class _Animated3DDonutChartState extends State<Animated3DDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _total => widget.segments.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty || _total == 0) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text(
            'Sin datos',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 400;

        if (!widget.showLegend || isCompact) {
          return Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return _Donut3DPainterWidget(
                  segments: widget.segments,
                  total: _total,
                  size: widget.size,
                  animationValue: _animation.value,
                  centerWidget: widget.centerWidget,
                );
              },
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return _Donut3DPainterWidget(
                  segments: widget.segments,
                  total: _total,
                  size: widget.size,
                  animationValue: _animation.value,
                  centerWidget: widget.centerWidget,
                );
              },
            ),
            const SizedBox(width: 24),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: widget.segments.map((segment) {
                  return _buildLegendItem(segment, screenWidth);
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(ChartSegment segment, double screenWidth) {
    final percentage = _total > 0 ? (segment.value / _total * 100) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: ElegantLightTheme.elasticCurve,
      builder: (context, animatedValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animatedValue), 0),
          child: Opacity(
            opacity: animatedValue.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    segment.color.withValues(alpha: 0.1),
                    segment.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: segment.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: segment.color.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [segment.color, segment.color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: segment.color.withValues(alpha: 0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      segment.icon ?? Icons.circle,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        segment.label,
                        style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${segment.value.toInt()} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Donut3DPainterWidget extends StatelessWidget {
  final List<ChartSegment> segments;
  final double total;
  final double size;
  final double animationValue;
  final Widget? centerWidget;

  const _Donut3DPainterWidget({
    required this.segments,
    required this.total,
    required this.size,
    required this.animationValue,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _Donut3DPainter(
                segments: segments,
                total: total,
                animationValue: animationValue,
              ),
            ),
          ),
          if (centerWidget != null)
            Center(child: centerWidget!),
        ],
      ),
    );
  }
}

class _Donut3DPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double total;
  final double animationValue;

  _Donut3DPainter({
    required this.segments,
    required this.total,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2.8;
    final innerRadius = outerRadius * 0.45;
    final depth3D = outerRadius * 0.35;

    double currentAngle = -math.pi / 2;
    const gapAngle = 0.08;
    final totalGaps = segments.length * gapAngle;
    final availableAngle = (2 * math.pi) - totalGaps;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final percentage = segment.value / total;
      final segmentAngle = (availableAngle * percentage) * animationValue;

      if (segmentAngle > 0.01) {
        _drawDonutSegment3D(
          canvas,
          center,
          outerRadius,
          innerRadius,
          currentAngle,
          segmentAngle,
          segment.color,
          depth3D,
        );
      }

      currentAngle += segmentAngle + gapAngle;
    }
  }

  void _drawDonutSegment3D(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    double depth,
  ) {
    final depthOffset = Offset(-depth * 0.5, -depth * 0.7);

    // Superficie trasera
    _drawDonutSegment(
      canvas,
      Offset(center.dx + depthOffset.dx, center.dy + depthOffset.dy),
      outerRadius,
      innerRadius,
      startAngle,
      sweepAngle,
      _darkenColor(color, 0.4),
    );

    // Paredes laterales
    _drawSegmentWalls(
      canvas,
      center,
      outerRadius,
      innerRadius,
      startAngle,
      sweepAngle,
      color,
      depthOffset,
    );

    // Superficie frontal
    _drawDonutSegment(
      canvas,
      center,
      outerRadius,
      innerRadius,
      startAngle,
      sweepAngle,
      _lightenColor(color, 0.1),
    );
  }

  void _drawDonutSegment(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.0,
      colors: [_lightenColor(color, 0.3), color, _darkenColor(color, 0.2)],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(
          center: center,
          width: outerRadius * 2,
          height: outerRadius * 2,
        ),
      );

    final path = Path();
    path.addArc(
      Rect.fromCenter(center: center, width: outerRadius * 2, height: outerRadius * 2),
      startAngle,
      sweepAngle,
    );
    path.arcTo(
      Rect.fromCenter(center: center, width: innerRadius * 2, height: innerRadius * 2),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSegmentWalls(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    Offset depthOffset,
  ) {
    final outerWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lightenColor(color, 0.1), _darkenColor(color, 0.3)],
      ).createShader(Rect.fromLTWH(0, 0, outerRadius * 2, depthOffset.dy.abs()));

    const steps = 15;
    final angleStep = sweepAngle / steps;

    for (int i = 0; i < steps; i++) {
      final currentAngle = startAngle + (i * angleStep);
      final nextAngle = startAngle + ((i + 1) * angleStep);

      final p1Front = Offset(
        center.dx + outerRadius * math.cos(currentAngle),
        center.dy + outerRadius * math.sin(currentAngle),
      );
      final p2Front = Offset(
        center.dx + outerRadius * math.cos(nextAngle),
        center.dy + outerRadius * math.sin(nextAngle),
      );
      final p1Back = Offset(p1Front.dx + depthOffset.dx, p1Front.dy + depthOffset.dy);
      final p2Back = Offset(p2Front.dx + depthOffset.dx, p2Front.dy + depthOffset.dy);

      final wallPath = Path()
        ..moveTo(p1Front.dx, p1Front.dy)
        ..lineTo(p2Front.dx, p2Front.dy)
        ..lineTo(p2Back.dx, p2Back.dy)
        ..lineTo(p1Back.dx, p1Back.dy)
        ..close();

      canvas.drawPath(wallPath, outerWallPaint);
    }

    // Pared interior
    final innerWallPaint = Paint()..color = _darkenColor(color, 0.5);
    for (int i = 0; i < steps; i++) {
      final currentAngle = startAngle + (i * angleStep);
      final nextAngle = startAngle + ((i + 1) * angleStep);

      final p1Front = Offset(
        center.dx + innerRadius * math.cos(currentAngle),
        center.dy + innerRadius * math.sin(currentAngle),
      );
      final p2Front = Offset(
        center.dx + innerRadius * math.cos(nextAngle),
        center.dy + innerRadius * math.sin(nextAngle),
      );
      final p1Back = Offset(p1Front.dx + depthOffset.dx, p1Front.dy + depthOffset.dy);
      final p2Back = Offset(p2Front.dx + depthOffset.dx, p2Front.dy + depthOffset.dy);

      final innerWallPath = Path()
        ..moveTo(p1Front.dx, p1Front.dy)
        ..lineTo(p1Back.dx, p1Back.dy)
        ..lineTo(p2Back.dx, p2Back.dy)
        ..lineTo(p2Front.dx, p2Front.dy)
        ..close();

      canvas.drawPath(innerWallPath, innerWallPaint);
    }
  }

  Color _lightenColor(Color color, double factor) {
    return Color.fromRGBO(
      math.min(255, (color.r * 255 + (255 - color.r * 255) * factor).round()),
      math.min(255, (color.g * 255 + (255 - color.g * 255) * factor).round()),
      math.min(255, (color.b * 255 + (255 - color.b * 255) * factor).round()),
      color.a,
    );
  }

  Color _darkenColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.r * 255 * (1 - factor)).round(),
      (color.g * 255 * (1 - factor)).round(),
      (color.b * 255 * (1 - factor)).round(),
      color.a,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Barra de progreso horizontal animada con efecto shimmer
class AnimatedProgressBar extends StatefulWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final LinearGradient? gradient;
  final bool showPercentage;
  final bool showValue;
  final String? valuePrefix;
  final String? valueSuffix;
  final double height;
  final Duration animationDuration;
  final int animationDelayMs;

  const AnimatedProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100,
    this.color = const Color(0xFF3B82F6),
    this.gradient,
    this.showPercentage = true,
    this.showValue = false,
    this.valuePrefix,
    this.valueSuffix,
    this.height = 12,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationDelayMs = 0,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  @override
  Widget build(BuildContext context) {
    final percentage = widget.maxValue > 0 ? (widget.value / widget.maxValue) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.showPercentage)
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (widget.showValue)
              Text(
                '${widget.valuePrefix ?? ''}${widget.value.toStringAsFixed(0)}${widget.valueSuffix ?? ''}',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage.clamp(0.0, 1.0)),
            duration: widget.animationDuration,
            curve: Curves.easeOutExpo,
            builder: (context, animatedValue, child) {
              return Row(
                children: [
                  if (animatedValue > 0)
                    Flexible(
                      flex: (animatedValue * 100).round().clamp(1, 100),
                      child: Container(
                        height: widget.height - 2,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          gradient: widget.gradient ?? LinearGradient(
                            colors: [widget.color, widget.color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular((widget.height - 2) / 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular((widget.height - 2) / 2),
                          child: Stack(
                            children: [
                              if (animatedValue >= percentage * 0.95 && percentage > 0.1)
                                ProgressShimmerEffect(
                                  borderRadius: (widget.height - 2) / 2,
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
        ),
      ],
    );
  }
}

/// Efecto de destello (shimmer) para barras de progreso
class ProgressShimmerEffect extends StatefulWidget {
  final double borderRadius;

  const ProgressShimmerEffect({
    super.key,
    required this.borderRadius,
  });

  @override
  State<ProgressShimmerEffect> createState() => _ProgressShimmerEffectState();
}

class _ProgressShimmerEffectState extends State<ProgressShimmerEffect>
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
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
              end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Barra de progreso vertical animada con forma de píldora
/// Maneja correctamente valores bajos y cero
class AnimatedVerticalBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final LinearGradient? gradient;
  final double width;
  final double height;
  final Duration animationDuration;
  final int animationDelayMs;
  /// Altura mínima de la barra llena (para mantener forma de píldora)
  final double minFilledHeight;

  const AnimatedVerticalBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.color = const Color(0xFF3B82F6),
    this.gradient,
    this.width = 40,
    this.height = 150,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationDelayMs = 0,
    this.minFilledHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final barWidth = width - 4;
    final barRadius = barWidth / 2;

    // Altura mínima para mantener forma de píldora (al menos el ancho de la barra)
    final effectiveMinHeight = minFilledHeight > 0 ? minFilledHeight : barWidth;
    final maxBarHeight = height - 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: animationDuration,
            curve: Curves.easeOutExpo,
            builder: (context, animatedValue, child) {
              // Si el valor es cero, no mostrar barra llena
              final showFilledBar = value > 0;

              // Calcular altura proporcional con mínimo garantizado
              double barHeight = 0;
              if (showFilledBar) {
                final proportionalHeight = maxBarHeight * animatedValue;
                barHeight = proportionalHeight < effectiveMinHeight
                    ? effectiveMinHeight
                    : proportionalHeight;
              }

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Fondo con forma de píldora (siempre visible)
                  Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(width / 2),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Barra llena con forma de píldora (solo si hay valor > 0)
                  if (showFilledBar && barHeight > 0)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: barWidth,
                        height: barHeight.clamp(effectiveMinHeight, maxBarHeight),
                        decoration: BoxDecoration(
                          gradient: gradient ?? LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              color.withValues(alpha: 0.75),
                              color,
                              color.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(barRadius),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, -2),
                            ),
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(barRadius),
                          child: Stack(
                            children: [
                              // Efecto de brillo interno
                              Positioned(
                                left: 3,
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Shimmer effect
                              if (animatedValue >= percentage * 0.9 && percentage > 0.02)
                                ProgressShimmerEffect(borderRadius: barRadius),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
