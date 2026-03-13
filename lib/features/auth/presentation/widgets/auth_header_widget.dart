import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? logo;
  final Color? titleColor;
  final Color? subtitleColor;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.logo,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        if (logo != null)
          logo!
        else
          Container(
            width: context.isMobile ? 80 : 100,
            height: context.isMobile ? 80 : 100,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/images/baudex_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

        SizedBox(height: context.verticalSpacing),

        // Título
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 28,
              tablet: 32,
              desktop: 36,
            ),
            fontWeight: FontWeight.bold,
            color: titleColor ?? ElegantLightTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.verticalSpacing / 2),

        // Subtítulo
        Text(
          subtitle,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: subtitleColor ?? ElegantLightTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
