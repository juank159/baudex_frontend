// lib/app/core/theme/futuristic_theme.dart
import 'package:flutter/material.dart';
import 'elegant_light_theme.dart';

// Alias para el nuevo tema elegante claro
class FuturisticTheme {
  static const LinearGradient primaryGradient = ElegantLightTheme.primaryGradient;
  static const LinearGradient cardGradient = ElegantLightTheme.cardGradient;
  static const LinearGradient glassGradient = ElegantLightTheme.glassGradient;
  static const LinearGradient successGradient = ElegantLightTheme.successGradient;
  static const LinearGradient warningGradient = ElegantLightTheme.warningGradient;
  static const LinearGradient errorGradient = ElegantLightTheme.errorGradient;
  static const LinearGradient infoGradient = ElegantLightTheme.infoGradient;
  
  static List<BoxShadow> get neuomorphicShadow => ElegantLightTheme.neuomorphicShadow;
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
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isHoverable = true,
    VoidCallback? onTap,
    LinearGradient? gradient,
    bool hasGlow = false,
  }) : super(
          key: key,
          child: child,
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          isHoverable: isHoverable,
          onTap: onTap,
          gradient: gradient,
          hasGlow: hasGlow,
        );
}

class FuturisticButton extends ElegantButton {
  const FuturisticButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    LinearGradient? gradient,
    double? width,
    double? height,
    bool isLoading = false,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          icon: icon,
          gradient: gradient,
          width: width,
          height: height,
          isLoading: isLoading,
        );
}

class FuturisticProgressIndicator extends ElegantProgressIndicator {
  const FuturisticProgressIndicator({
    Key? key,
    required double progress,
    String? label,
    LinearGradient? gradient,
  }) : super(
          key: key,
          progress: progress,
          label: label,
          gradient: gradient,
        );
}