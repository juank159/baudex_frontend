// lib/app/core/utils/responsive_helper.dart
import 'package:flutter/material.dart';
import 'responsive.dart';

/// Helper class para evitar conflictos con extensiones
class ResponsiveHelper {
  static bool isMobile(BuildContext context) => Responsive.isMobile(context);
  static bool isTablet(BuildContext context) => Responsive.isTablet(context);
  static bool isDesktop(BuildContext context) => Responsive.isDesktop(context);

  static DeviceType getDeviceType(BuildContext context) =>
      Responsive.getDeviceType(context);

  static EdgeInsets getPadding(BuildContext context) =>
      Responsive.getPadding(context);
  static double getMaxWidth(BuildContext context) =>
      Responsive.getMaxWidth(context);
  static double getVerticalSpacing(BuildContext context) =>
      Responsive.getVerticalSpacing(context);
  static double getHorizontalSpacing(BuildContext context) =>
      Responsive.getHorizontalSpacing(context);

  static double getFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) => Responsive.getFontSize(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
