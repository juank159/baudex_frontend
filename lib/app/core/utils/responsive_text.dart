// lib/app/core/utils/responsive_text.dart
import 'package:flutter/material.dart';

class ResponsiveText {
  static const double _mobileBreakpoint = 480;
  static const double _tabletBreakpoint = 768;
  static const double _desktopBreakpoint = 1024;

  /// Determina el tipo de dispositivo basado en el ancho de pantalla
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < _mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < _tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Obtiene el tamaño de fuente responsivo basado en el dispositivo
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  // Tamaños de fuente para títulos principales
  static double getTitleLargeSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 18.0,     // Móvil: más pequeño
      tablet: 22.0,     // Tablet: intermedio
      desktop: 24.0,    // Desktop: más grande
    );
  }

  // Tamaños de fuente para títulos medianos
  static double getTitleMediumSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 16.0,     // Móvil
      tablet: 18.0,     // Tablet
      desktop: 20.0,    // Desktop
    );
  }

  // Tamaños de fuente para títulos pequeños
  static double getTitleSmallSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 14.0,     // Móvil
      tablet: 16.0,     // Tablet
      desktop: 18.0,    // Desktop
    );
  }

  // Tamaños de fuente para texto de cuerpo
  static double getBodyLargeSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 14.0,     // Móvil
      tablet: 15.0,     // Tablet
      desktop: 16.0,    // Desktop
    );
  }

  // Tamaños de fuente para texto de cuerpo mediano
  static double getBodyMediumSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 12.0,     // Móvil
      tablet: 13.0,     // Tablet
      desktop: 14.0,    // Desktop
    );
  }

  // Tamaños de fuente para texto de cuerpo pequeño
  static double getBodySmallSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 10.0,     // Móvil
      tablet: 11.0,     // Tablet
      desktop: 12.0,    // Desktop
    );
  }

  // Tamaños de fuente para texto muy pequeño (labels, captions)
  static double getCaptionSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 8.0,      // Móvil: muy pequeño
      tablet: 9.0,      // Tablet: pequeño
      desktop: 10.0,    // Desktop: normal
    );
  }

  // Tamaños de fuente para valores numéricos importantes
  static double getValueTextSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 14.0,     // Móvil
      tablet: 16.0,     // Tablet
      desktop: 18.0,    // Desktop
    );
  }

  // Tamaños de fuente para valores numéricos grandes (métricas principales)
  static double getLargeValueSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 16.0,     // Móvil
      tablet: 18.0,     // Tablet
      desktop: 20.0,    // Desktop
    );
  }

  // Tamaños para iconos también
  static double getIconSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 16.0,     // Móvil
      tablet: 20.0,     // Tablet
      desktop: 24.0,    // Desktop
    );
  }

  // Tamaños para iconos pequeños
  static double getSmallIconSize(BuildContext context) {
    return getResponsiveFontSize(
      context,
      mobile: 14.0,     // Móvil
      tablet: 16.0,     // Tablet
      desktop: 18.0,    // Desktop
    );
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}