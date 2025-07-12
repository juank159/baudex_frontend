// File: lib/app/core/utils/responsive.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static const double mobileMaxWidth = 650;
  static const double tabletMaxWidth = 1100;

  /// Obtener el tipo de dispositivo actual
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width < mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width < tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Verificar si es móvil
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Verificar si es tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Verificar si es desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Widget responsivo que construye diferentes layouts según el dispositivo
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    DeviceType deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Obtener padding responsivo
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Obtener ancho máximo para contenido centrado
  static double getMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 400;
    }
  }

  /// Obtener número de columnas para grids
  static int getColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Obtener tamaño de fuente responsivo
  static double getFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Obtener height del app bar responsivo
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else {
      return kToolbarHeight + 10;
    }
  }

  /// Obtener espaciado vertical responsivo
  static double getVerticalSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  /// Obtener espaciado horizontal responsivo
  static double getHorizontalSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  /// Widget que ajusta su contenido según el ancho disponible
  static Widget adaptiveContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? getPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? getMaxWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ✅ EXTENSIÓN SIMPLE SIN CONFLICTOS - solo para compatibilidad
extension ResponsiveExtension on BuildContext {
  DeviceType get deviceType => Responsive.getDeviceType(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);

  EdgeInsets get responsivePadding => Responsive.getPadding(this);
  double get responsiveMaxWidth => Responsive.getMaxWidth(this);
  double get verticalSpacing => Responsive.getVerticalSpacing(this);
  double get horizontalSpacing => Responsive.getHorizontalSpacing(this);
}

/// Widget helper para layouts responsivos
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Responsive.builder(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Widget para contenedor adaptivo centrado
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const AdaptiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: padding ?? context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? context.responsiveMaxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}