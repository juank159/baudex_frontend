import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? (context.isMobile ? 2.0 : 4.0),
        color: backgroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12.0),
          side: border?.top ?? BorderSide.none,
        ),
        child: Padding(
          padding: padding ?? context.responsivePadding,
          child: child,
        ),
      ),
    );
  }
}
