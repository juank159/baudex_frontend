// lib/app/shared/widgets/spectacular_floating_action_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/elegant_light_theme.dart';

class SpectacularFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? text;
  final bool showText;
  final LinearGradient? gradient;
  final double? size;
  final bool enablePulse;
  final bool enableHover;

  const SpectacularFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.text,
    this.showText = false,
    this.gradient,
    this.size,
    this.enablePulse = true,
    this.enableHover = true,
  });

  @override
  State<SpectacularFloatingActionButton> createState() =>
      _SpectacularFloatingActionButtonState();
}

class _SpectacularFloatingActionButtonState
    extends State<SpectacularFloatingActionButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late AnimationController _floatingController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverScaleAnimation;
  late Animation<double> _hoverGlowAnimation;
  late Animation<double> _floatingAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Animación de pulso (respiración)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación de hover
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.elasticOut),
    );
    _hoverGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    // Animación de flotación
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Iniciar animaciones automáticas
    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hoverController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (widget.enableHover && !_isHovered) {
      setState(() => _isHovered = true);
      _hoverController.forward();
    }
  }

  void _onHoverEnd() {
    if (widget.enableHover && _isHovered) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isDesktop = constraints.maxWidth >= 1200;

        // Determinar si mostrar texto basado en el tamaño de pantalla
        final shouldShowText =
            isDesktop && (widget.showText || widget.text != null);

        return AnimatedBuilder(
          animation: Listenable.merge([
            _pulseAnimation,
            _hoverScaleAnimation,
            _hoverGlowAnimation,
            _floatingAnimation,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatingAnimation.value),
              child: MouseRegion(
                onEnter: widget.enableHover ? (_) => _onHoverStart() : null,
                onExit: widget.enableHover ? (_) => _onHoverEnd() : null,
                child: GestureDetector(
                  onTap: widget.onPressed,
                  child: Container(
                    margin: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Resplandor holográfico
                        if (widget.enableHover) _buildHolographicGlow(),

                        // Botón principal con efectos elegantes
                        Transform.scale(
                          scale:
                              _hoverScaleAnimation.value *
                              _pulseAnimation.value,
                          child: _buildMainButton(
                            shouldShowText,
                            isMobile,
                            isTablet,
                            isDesktop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainButton(
    bool shouldShowText,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final gradient = widget.gradient ?? ElegantLightTheme.primaryGradient;

    // Tamaños responsivos
    final buttonWidth =
        shouldShowText
            ? null
            : (isMobile
                ? 56.0
                : isTablet
                ? 64.0
                : 68.0);
    final buttonHeight =
        isMobile
            ? 56.0
            : isTablet
            ? 64.0
            : 68.0;
    final iconSize =
        isMobile
            ? 24.0
            : isTablet
            ? 28.0
            : 32.0;

    return Container(
      width: buttonWidth,
      height: buttonHeight,
      padding:
          shouldShowText
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
              : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient.colors.first,
            gradient.colors.last,
            Color.lerp(
              gradient.colors.last,
              Colors.purple,
              _hoverGlowAnimation.value * 0.3,
            )!,
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(
          shouldShowText ? 30 : buttonHeight / 2,
        ),
        boxShadow: [
          // Sombra base elegante
          ...ElegantLightTheme.glowShadow,
          // Sombra de hover espectacular
          BoxShadow(
            color: gradient.colors.first.withOpacity(
              0.4 + (_hoverGlowAnimation.value * 0.4),
            ),
            blurRadius: 15 + (_hoverGlowAnimation.value * 25),
            spreadRadius: 2 + (_hoverGlowAnimation.value * 8),
            offset: const Offset(0, 0),
          ),
          // Resplandor mágico
          BoxShadow(
            color: Colors.white.withOpacity(_hoverGlowAnimation.value * 0.3),
            blurRadius: 30 + (_hoverGlowAnimation.value * 20),
            spreadRadius: -5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efectos de brillo interno
          _buildInternalShimmer(shouldShowText, buttonHeight),

          // Contenido del botón
          shouldShowText
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: iconSize,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.text ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Icon(
                widget.icon,
                color: Colors.white,
                size: iconSize + (_hoverGlowAnimation.value * 4),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildHolographicGlow() {
    final baseSize = widget.size ?? 60.0;
    return Container(
      width: baseSize + 20 + (_hoverGlowAnimation.value * 40),
      height: baseSize + 20 + (_hoverGlowAnimation.value * 40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.transparent,
            ElegantLightTheme.primaryBlue.withOpacity(
              _hoverGlowAnimation.value * 0.1,
            ),
            Colors.purple.withOpacity(_hoverGlowAnimation.value * 0.05),
            Colors.transparent,
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildInternalShimmer(bool shouldShowText, double buttonHeight) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: shouldShowText ? double.infinity : buttonHeight,
          height: buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              shouldShowText ? 30 : buttonHeight / 2,
            ),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _pulseAnimation.value * 2, 0),
              end: Alignment(1.0 + _pulseAnimation.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(_hoverGlowAnimation.value * 0.15),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
