// lib/app/core/theme/elegant_light_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class ElegantLightTheme {
  // Colores base del tema claro
  static const Color primaryBlue = Color(0xFF2563EB); // Blue 600
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Blue 500
  static const Color primaryBlueDark = Color(0xFF1D4ED8); // Blue 700

  // Colores de acento
  static const Color accentOrange = Color(0xFFF59E0B); // Amber 500

  // Colores de estado (sólidos)
  static const Color successGreen = Color(0xFF10B981); // Green 500
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500
  static const Color errorRed = Color(0xFFEF4444); // Red 500

  // Colores de fondo claros
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color cardColor = Color(0xFFF1F5F9); // Slate 100

  // Colores de texto
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // Gradientes principales (más suaves para tema claro)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Blue 500
      Color(0xFF2563EB), // Blue 600
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // 🪟 Glassmorfismo - Gradientes con transparencia
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCCFFFFFF), // Blanco 80% opacidad
      Color(0xB3F8FAFC), // Slate 50 70% opacidad
    ],
  );

  static const LinearGradient glassPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x803B82F6), // Blue 500 50% opacidad
      Color(0x662563EB), // Blue 600 40% opacidad
    ],
  );

  static const LinearGradient glassSuccessGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x8010B981), // Green 50% opacidad
      Color(0x66059669), // Green dark 40% opacidad
    ],
  );

  // Gradientes de estado
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  // Sombras elegantes para tema claro
  static List<BoxShadow> get neuomorphicShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      offset: const Offset(5, 5),
      blurRadius: 15,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white,
      offset: const Offset(-5, -5),
      blurRadius: 15,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: const Color(0xFF3B82F6).withOpacity(0.15),
      offset: const Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // 🪟 Glassmorfismo - Sombras suaves con color
  static List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF3B82F6).withOpacity(0.08),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.6),
      offset: const Offset(0, -2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // 🪟 Método helper para crear decoración glassmorphism
  static BoxDecoration glassDecoration({
    Color? borderColor,
    double borderRadius = 20,
    LinearGradient? gradient,
    List<BoxShadow>? customShadows,
  }) {
    return BoxDecoration(
      gradient: gradient ?? glassGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: customShadows ?? glassShadow,
    );
  }

  // Animaciones
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Curvas de animación
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

// Widget para contenedor elegante con efectos 3D suaves
class ElegantContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isHoverable;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final bool hasGlow;

  const ElegantContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.isHoverable = true,
    this.onTap,
    this.gradient,
    this.hasGlow = false,
  });

  @override
  State<ElegantContainer> createState() => _ElegantContainerState();
}

class _ElegantContainerState extends State<ElegantContainer>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: widget.isHoverable ? (_) => _onHover(true) : null,
            onExit: widget.isHoverable ? (_) => _onHover(false) : null,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                padding: widget.padding ?? const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: widget.gradient ?? ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    if (widget.hasGlow || _isHovered)
                      ...ElegantLightTheme.glowShadow.map(
                        (shadow) => shadow.copyWith(
                          color: shadow.color.withOpacity(
                            shadow.color.opacity *
                                _glowAnimation.value.clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

// Botón elegante con efectos 3D suaves
class ElegantButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient? gradient;
  final double? width;
  final double? height;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const ElegantButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.height,
    this.isLoading = false,
    this.padding,
  });

  @override
  State<ElegantButton> createState() => _ElegantButtonState();
}

class _ElegantButtonState extends State<ElegantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.fastAnimation,
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.bounceCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pressAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _onPressChanged(true),
            onTapUp: (_) => _onPressChanged(false),
            onTapCancel: () => _onPressChanged(false),
            onTap: widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height ?? 48,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ElegantLightTheme.elevatedShadow,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onPressed,
                  child: Container(
                    padding:
                        widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else if (widget.icon != null)
                          Icon(widget.icon, color: Colors.white, size: 16),
                        if ((widget.icon != null || widget.isLoading) &&
                            widget.text.isNotEmpty)
                          const SizedBox(width: 6),
                        if (widget.text.isNotEmpty)
                          Flexible(
                            child: Text(
                              widget.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPressChanged(bool isPressed) {
    setState(() {
      _isPressed = isPressed;
    });
    if (isPressed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

// Indicador de progreso elegante
class ElegantProgressIndicator extends StatefulWidget {
  final double progress;
  final String? label;
  final LinearGradient? gradient;

  const ElegantProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.gradient,
  });

  @override
  State<ElegantProgressIndicator> createState() =>
      _ElegantProgressIndicatorState();
}

class _ElegantProgressIndicatorState extends State<ElegantProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.slowAnimation,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ElegantProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: ElegantLightTheme.elasticCurve,
        ),
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ElegantLightTheme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value.clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.gradient != null
                        ? widget.gradient!.colors.first
                        : ElegantLightTheme.primaryBlue,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Text(
              '${(_progressAnimation.value * 100).toInt()}%',
              style: const TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }
}

// 🪟 Widget GlassCard con efecto glassmorfismo completo
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double blurIntensity;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.gradient,
    this.borderColor,
    this.blurIntensity = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: ElegantLightTheme.glassDecoration(
              borderColor: borderColor,
              borderRadius: borderRadius,
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Alias para compatibilidad con código existente
class FuturisticContainer extends ElegantContainer {
  const FuturisticContainer({
    super.key,
    required super.child,
    super.width,
    super.height,
    super.padding,
    super.margin,
    super.isHoverable,
    super.onTap,
    super.gradient,
    super.hasGlow,
  });
}

class FuturisticButton extends ElegantButton {
  const FuturisticButton({
    super.key,
    required super.text,
    super.onPressed,
    super.icon,
    super.gradient,
    super.width,
    super.height,
    super.isLoading,
  });
}

class FuturisticProgressIndicator extends ElegantProgressIndicator {
  const FuturisticProgressIndicator({
    super.key,
    required super.progress,
    super.label,
    super.gradient,
  });
}

// Alias para FuturisticTheme para compatibilidad
class FuturisticTheme {
  static const LinearGradient primaryGradient =
      ElegantLightTheme.primaryGradient;
  static const LinearGradient cardGradient = ElegantLightTheme.cardGradient;
  static const LinearGradient glassGradient = ElegantLightTheme.glassGradient;
  static const LinearGradient successGradient =
      ElegantLightTheme.successGradient;
  static const LinearGradient warningGradient =
      ElegantLightTheme.warningGradient;
  static const LinearGradient errorGradient = ElegantLightTheme.errorGradient;
  static const LinearGradient infoGradient = ElegantLightTheme.infoGradient;

  static List<BoxShadow> get neuomorphicShadow =>
      ElegantLightTheme.neuomorphicShadow;
  static List<BoxShadow> get elevatedShadow => ElegantLightTheme.elevatedShadow;
  static List<BoxShadow> get glowShadow => ElegantLightTheme.glowShadow;

  static const Duration fastAnimation = ElegantLightTheme.fastAnimation;
  static const Duration normalAnimation = ElegantLightTheme.normalAnimation;
  static const Duration slowAnimation = ElegantLightTheme.slowAnimation;

  static const Curve elasticCurve = ElegantLightTheme.elasticCurve;
  static const Curve bounceCurve = ElegantLightTheme.bounceCurve;
  static const Curve smoothCurve = ElegantLightTheme.smoothCurve;
}
