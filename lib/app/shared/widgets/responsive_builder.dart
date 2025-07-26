// lib/app/shared/widgets/responsive_builder.dart
import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200 && desktop != null) {
      return desktop!;
    } else if (screenWidth >= 768 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}