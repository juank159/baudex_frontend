// lib/app/core/utils/responsive_helper.dart
import 'package:flutter/material.dart';
import 'responsive.dart';

/// Helper class mejorado para responsividad sin conflictos
class ResponsiveHelper {
  // ==================== DEVICE TYPE DETECTION ====================
  
  static bool isMobile(BuildContext context) => Responsive.isMobile(context);
  static bool isTablet(BuildContext context) => Responsive.isTablet(context);
  static bool isDesktop(BuildContext context) => Responsive.isDesktop(context);

  static DeviceType getDeviceType(BuildContext context) =>
      Responsive.getDeviceType(context);

  // ==================== LAYOUT DIMENSIONS ====================
  
  /// Obtener padding optimizado para cada contexto
  static EdgeInsets getPadding(BuildContext context, {
    PaddingContext paddingContext = PaddingContext.general,
  }) {
    final baseSize = _getBasePaddingSize(context);
    
    switch (paddingContext) {
      case PaddingContext.general:
        return EdgeInsets.all(baseSize);
      case PaddingContext.compact:
        return EdgeInsets.all(baseSize * 0.75);
      case PaddingContext.spacious:
        return EdgeInsets.all(baseSize * 1.25);
      case PaddingContext.card:
        return EdgeInsets.all(baseSize * 0.85);
      case PaddingContext.sidebar:
        return EdgeInsets.symmetric(
          horizontal: baseSize * 0.75,
          vertical: baseSize * 0.5,
        );
    }
  }

  static double _getBasePaddingSize(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  /// Ancho máximo optimizado
  static double getMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }

  /// Espaciado vertical optimizado
  static double getVerticalSpacing(BuildContext context, {
    SpacingSize size = SpacingSize.medium,
  }) {
    final baseSpacing = _getBaseSpacing(context);
    return baseSpacing * _getSpacingMultiplier(size);
  }

  /// Espaciado horizontal optimizado
  static double getHorizontalSpacing(BuildContext context, {
    SpacingSize size = SpacingSize.medium,
  }) {
    final baseSpacing = _getBaseSpacing(context);
    return baseSpacing * _getSpacingMultiplier(size);
  }

  static double _getBaseSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  static double _getSpacingMultiplier(SpacingSize size) {
    switch (size) {
      case SpacingSize.tiny: return 0.25;
      case SpacingSize.small: return 0.5;
      case SpacingSize.medium: return 1.0;
      case SpacingSize.large: return 1.5;
      case SpacingSize.extraLarge: return 2.0;
    }
  }

  // ==================== TYPOGRAPHY ====================
  
  static double getFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
    FontContext fontContext = FontContext.body,
  }) {
    double baseFontSize;
    
    if (isMobile(context)) {
      baseFontSize = mobile;
    } else if (isTablet(context)) {
      baseFontSize = tablet;
    } else {
      baseFontSize = desktop;
    }

    // Ajustar según el contexto
    switch (fontContext) {
      case FontContext.caption:
        return baseFontSize * 0.85;
      case FontContext.body:
        return baseFontSize;
      case FontContext.subtitle:
        return baseFontSize * 1.1;
      case FontContext.title:
        return baseFontSize * 1.3;
      case FontContext.headline:
        return baseFontSize * 1.6;
    }
  }

  // ==================== COMPONENT DIMENSIONS ====================
  
  /// Ancho optimizado para componentes
  static double getWidth(
    BuildContext context, {
    double mobile = 200,
    double tablet = 280,
    double desktop = 320,
    WidthContext widthContext = WidthContext.normal,
  }) {
    double baseWidth;
    
    if (isMobile(context)) {
      baseWidth = mobile;
    } else if (isTablet(context)) {
      baseWidth = tablet;
    } else {
      baseWidth = desktop;
    }

    switch (widthContext) {
      case WidthContext.compact:
        return baseWidth * 0.8;
      case WidthContext.normal:
        return baseWidth;
      case WidthContext.wide:
        return baseWidth * 1.2;
      case WidthContext.sidebar:
        return _getSidebarWidth(context);
    }
  }

  /// Alto optimizado para componentes
  static double getHeight(
    BuildContext context, {
    double mobile = 40,
    double tablet = 44,
    double desktop = 48,
    HeightContext heightContext = HeightContext.normal,
  }) {
    double baseHeight;
    
    if (isMobile(context)) {
      baseHeight = mobile;
    } else if (isTablet(context)) {
      baseHeight = tablet;
    } else {
      baseHeight = desktop;
    }

    switch (heightContext) {
      case HeightContext.compact:
        return baseHeight * 0.8;
      case HeightContext.normal:
        return baseHeight;
      case HeightContext.comfortable:
        return baseHeight * 1.2;
      case HeightContext.spacious:
        return baseHeight * 1.4;
    }
  }

  // ==================== SPECIALIZED DIMENSIONS ====================
  
  /// Ancho óptimo para sidebar
  static double _getSidebarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 1200) {
      return 280; // Pantallas pequeñas
    } else if (screenWidth < 1600) {
      return 320; // Pantallas medianas
    } else if (screenWidth < 2000) {
      return 350; // Pantallas grandes
    } else {
      return 380; // Pantallas muy grandes
    }
  }

  /// Alto de AppBar optimizado
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight + 8;
    } else {
      return kToolbarHeight + 12;
    }
  }

  /// Radio de borde optimizado
  static double getBorderRadius(
    BuildContext context, {
    BorderRadiusContext radiusContext = BorderRadiusContext.normal,
  }) {
    double baseRadius = isMobile(context) ? 8.0 : 12.0;
    
    switch (radiusContext) {
      case BorderRadiusContext.small:
        return baseRadius * 0.5;
      case BorderRadiusContext.normal:
        return baseRadius;
      case BorderRadiusContext.large:
        return baseRadius * 1.5;
      case BorderRadiusContext.card:
        return baseRadius * 1.2;
      case BorderRadiusContext.button:
        return baseRadius * 0.8;
    }
  }

  /// Elevación optimizada para cards
  static double getElevation(
    BuildContext context, {
    ElevationContext elevationContext = ElevationContext.normal,
  }) {
    double baseElevation = isMobile(context) ? 2.0 : 4.0;
    
    switch (elevationContext) {
      case ElevationContext.none:
        return 0.0;
      case ElevationContext.subtle:
        return baseElevation * 0.5;
      case ElevationContext.normal:
        return baseElevation;
      case ElevationContext.raised:
        return baseElevation * 1.5;
      case ElevationContext.floating:
        return baseElevation * 2.0;
    }
  }

  // ==================== GRID & LAYOUT ====================
  
  /// Número de columnas para grids
  static int getGridColumns(
    BuildContext context, {
    GridContext gridContext = GridContext.normal,
  }) {
    int baseColumns;
    
    if (isMobile(context)) {
      baseColumns = 1;
    } else if (isTablet(context)) {
      baseColumns = 2;
    } else {
      baseColumns = 3;
    }

    switch (gridContext) {
      case GridContext.compact:
        return baseColumns + 1;
      case GridContext.normal:
        return baseColumns;
      case GridContext.spacious:
        return (baseColumns - 1).clamp(1, 10);
      case GridContext.stats:
        return isMobile(context) ? 2 : (isTablet(context) ? 3 : 4);
    }
  }

  /// Aspecto ratio para grid items
  static double getGridAspectRatio(
    BuildContext context, {
    GridContext gridContext = GridContext.normal,
  }) {
    switch (gridContext) {
      case GridContext.compact:
        return 1.2;
      case GridContext.normal:
        return 1.0;
      case GridContext.spacious:
        return 0.8;
      case GridContext.stats:
        return 1.5;
    }
  }

  // ==================== UTILITY METHODS ====================
  
  /// Verificar si la pantalla es pequeña
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Verificar si la pantalla es grande
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Obtener orientación de la pantalla
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Obtener densidad de píxeles
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Verificar si es una pantalla de alta densidad
  static bool isHighDensityScreen(BuildContext context) {
    return getPixelRatio(context) >= 2.0;
  }

  // ==================== RESPONSIVE BUILDERS ====================
  
  /// Builder responsivo simplificado
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }

  /// Builder para valores numéricos
  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Builder para EdgeInsets
  static EdgeInsets responsivePadding(
    BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return responsive<EdgeInsets>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

// ==================== ENUMS PARA CONTEXTOS ====================

enum PaddingContext {
  general,
  compact,
  spacious,
  card,
  sidebar,
}

enum SpacingSize {
  tiny,
  small,
  medium,
  large,
  extraLarge,
}

enum FontContext {
  caption,
  body,
  subtitle,
  title,
  headline,
}

enum WidthContext {
  compact,
  normal,
  wide,
  sidebar,
}

enum HeightContext {
  compact,
  normal,
  comfortable,
  spacious,
}

enum BorderRadiusContext {
  small,
  normal,
  large,
  card,
  button,
}

enum ElevationContext {
  none,
  subtle,
  normal,
  raised,
  floating,
}

enum GridContext {
  compact,
  normal,
  spacious,
  stats,
}

// ==================== EXTENSIÓN ÚNICA SIN CONFLICTOS ====================
// ✅ REMOVEMOS ResponsiveExtensions para evitar conflictos

// En lugar de extensiones conflictivas, usa métodos estáticos directamente:
// ResponsiveHelper.isMobile(context) en lugar de context.isMobile