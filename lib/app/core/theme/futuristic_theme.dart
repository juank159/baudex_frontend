// lib/app/core/theme/futuristic_theme.dart
import 'package:flutter/material.dart';
import 'elegant_light_theme.dart';

// Alias para el nuevo tema elegante claro
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

// Alias de componentes para compatibilidad con código existente
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
