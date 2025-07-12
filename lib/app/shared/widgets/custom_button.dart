import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/responsive_helper.dart';

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large, compact }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final bool isCompact;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dimensions = _getButtonDimensions(context);
    
    if (isLoading) {
      return _buildLoadingButton(context, dimensions);
    }

    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context, dimensions);
      case ButtonType.secondary:
        return _buildSecondaryButton(context, dimensions);
      case ButtonType.outline:
        return _buildOutlineButton(context, dimensions);
      case ButtonType.text:
        return _buildTextButton(context, dimensions);
    }
  }

  ButtonDimensions _getButtonDimensions(BuildContext context) {
    // Base dimensions according to size
    late double baseHeight;
    late double baseFontSize;
    late EdgeInsets basePadding;

    switch (size) {
      case ButtonSize.small:
        baseHeight = ResponsiveHelper.responsiveValue(
          context,
          mobile: 32,
          tablet: 36,
          desktop: 36,
        );
        baseFontSize = ResponsiveHelper.getFontSize(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 14,
          fontContext: FontContext.caption,
        );
        basePadding = EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small),
          vertical: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.tiny),
        );
        break;

      case ButtonSize.medium:
        baseHeight = ResponsiveHelper.responsiveValue(
          context,
          mobile: 44,
          tablet: 48,
          desktop: 48,
        );
        baseFontSize = ResponsiveHelper.getFontSize(
          context,
          mobile: 14,
          tablet: 16,
          desktop: 16,
        );
        basePadding = EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalSpacing(context),
          vertical: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small),
        );
        break;

      case ButtonSize.large:
        baseHeight = ResponsiveHelper.responsiveValue(
          context,
          mobile: 52,
          tablet: 56,
          desktop: 56,
        );
        baseFontSize = ResponsiveHelper.getFontSize(
          context,
          mobile: 16,
          tablet: 18,
          desktop: 18,
          fontContext: FontContext.subtitle,
        );
        basePadding = EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.large),
          vertical: ResponsiveHelper.getVerticalSpacing(context),
        );
        break;

      case ButtonSize.compact:
        baseHeight = ResponsiveHelper.responsiveValue(
          context,
          mobile: 28,
          tablet: 32,
          desktop: 32,
        );
        baseFontSize = ResponsiveHelper.getFontSize(
          context,
          mobile: 11,
          tablet: 12,
          desktop: 12,
          fontContext: FontContext.caption,
        );
        basePadding = EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.tiny),
          vertical: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.tiny),
        );
        break;
    }

    // Apply compact mode adjustments
    if (isCompact) {
      baseHeight *= 0.85;
      baseFontSize *= 0.9;
      basePadding = EdgeInsets.symmetric(
        horizontal: basePadding.horizontal * 0.7,
        vertical: basePadding.vertical * 0.7,
      );
    }

    return ButtonDimensions(
      height: height ?? baseHeight,
      fontSize: fontSize ?? baseFontSize,
      padding: padding ?? basePadding,
    );
  }

  Widget _buildPrimaryButton(BuildContext context, ButtonDimensions dimensions) {
    final borderRadius = ResponsiveHelper.getBorderRadius(
      context,
      radiusContext: BorderRadiusContext.button,
    );

    return SizedBox(
      width: width,
      height: dimensions.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          elevation: ResponsiveHelper.getElevation(
            context,
            elevationContext: ElevationContext.normal,
          ),
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: dimensions.padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _buildButtonContent(dimensions.fontSize),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, ButtonDimensions dimensions) {
    final borderRadius = ResponsiveHelper.getBorderRadius(
      context,
      radiusContext: BorderRadiusContext.button,
    );

    return SizedBox(
      width: width,
      height: dimensions.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.grey.shade100,
          foregroundColor: textColor ?? Colors.grey.shade800,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: dimensions.padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _buildButtonContent(dimensions.fontSize),
      ),
    );
  }

  Widget _buildOutlineButton(BuildContext context, ButtonDimensions dimensions) {
    final borderRadius = ResponsiveHelper.getBorderRadius(
      context,
      radiusContext: BorderRadiusContext.button,
    );
    final borderColor = backgroundColor ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: width,
      height: dimensions.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? borderColor,
          side: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: dimensions.padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _buildButtonContent(dimensions.fontSize),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, ButtonDimensions dimensions) {
    final borderRadius = ResponsiveHelper.getBorderRadius(
      context,
      radiusContext: BorderRadiusContext.button,
    );

    return SizedBox(
      width: width,
      height: dimensions.height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: dimensions.padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _buildButtonContent(dimensions.fontSize),
      ),
    );
  }

  Widget _buildLoadingButton(BuildContext context, ButtonDimensions dimensions) {
    final borderRadius = ResponsiveHelper.getBorderRadius(
      context,
      radiusContext: BorderRadiusContext.button,
    );

    return SizedBox(
      width: width,
      height: dimensions.height,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (backgroundColor ?? Theme.of(context).primaryColor)
              .withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: dimensions.padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: SizedBox(
          width: dimensions.fontSize,
          height: dimensions.fontSize,
          child: CircularProgressIndicator(
            strokeWidth: dimensions.fontSize * 0.1,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(double fontSize) {
    // Calculate icon size based on font size
    final iconSize = fontSize * 1.2;
    
    if (icon != null) {
      // Determine spacing based on button size
      final spacing = size == ButtonSize.compact || isCompact ? 4.0 : 8.0;
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          if (text.isNotEmpty) ...[
            SizedBox(width: spacing),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }
}

// Helper class for button dimensions
class ButtonDimensions {
  final double height;
  final double fontSize;
  final EdgeInsets padding;

  const ButtonDimensions({
    required this.height,
    required this.fontSize,
    required this.padding,
  });
}

// Extension for easy button creation
extension CustomButtonExtensions on BuildContext {
  // Quick compact buttons
  Widget compactButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    ButtonType type = ButtonType.primary,
    Color? backgroundColor,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      type: type,
      size: ButtonSize.compact,
      backgroundColor: backgroundColor,
    );
  }

  // Quick small buttons
  Widget smallButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    ButtonType type = ButtonType.primary,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      type: type,
      size: ButtonSize.small,
    );
  }
}