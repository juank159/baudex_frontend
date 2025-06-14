import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? (context.isMobile ? 48.0 : 52.0);
    final buttonFontSize =
        fontSize ??
        Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 18);

    if (isLoading) {
      return _buildLoadingButton(context, buttonHeight);
    }

    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context, buttonHeight, buttonFontSize);
      case ButtonType.secondary:
        return _buildSecondaryButton(context, buttonHeight, buttonFontSize);
      case ButtonType.outline:
        return _buildOutlineButton(context, buttonHeight, buttonFontSize);
      case ButtonType.text:
        return _buildTextButton(context, buttonHeight, buttonFontSize);
    }
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    double buttonHeight,
    double buttonFontSize,
  ) {
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: context.isMobile ? 24.0 : 32.0,
                vertical: context.isMobile ? 12.0 : 16.0,
              ),
        ),
        child: _buildButtonContent(buttonFontSize),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    double buttonHeight,
    double buttonFontSize,
  ) {
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.grey.shade200,
          foregroundColor: textColor ?? Colors.grey.shade800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: context.isMobile ? 24.0 : 32.0,
                vertical: context.isMobile ? 12.0 : 16.0,
              ),
        ),
        child: _buildButtonContent(buttonFontSize),
      ),
    );
  }

  Widget _buildOutlineButton(
    BuildContext context,
    double buttonHeight,
    double buttonFontSize,
  ) {
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? Theme.of(context).primaryColor,
          side: BorderSide(
            color: backgroundColor ?? Theme.of(context).primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: context.isMobile ? 24.0 : 32.0,
                vertical: context.isMobile ? 12.0 : 16.0,
              ),
        ),
        child: _buildButtonContent(buttonFontSize),
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    double buttonHeight,
    double buttonFontSize,
  ) {
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: context.isMobile ? 16.0 : 24.0,
                vertical: context.isMobile ? 8.0 : 12.0,
              ),
        ),
        child: _buildButtonContent(buttonFontSize),
      ),
    );
  }

  Widget _buildLoadingButton(BuildContext context, double buttonHeight) {
    return SizedBox(
      width: width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              Theme.of(context).primaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(double fontSize) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
    );
  }
}
