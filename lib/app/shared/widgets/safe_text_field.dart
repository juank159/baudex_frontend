// File: lib/app/shared/widgets/safe_text_field.dart
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de campo de texto ultra-simple y robusto para casos de emergencia
/// Se usa cuando CustomTextField presenta problemas de eventos de teclado
class SafeTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const SafeTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<SafeTextField> {
  late TextEditingController _controller;
  bool _isUsingInternalController = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isUsingInternalController = false;
    } else {
      _controller = TextEditingController();
      _isUsingInternalController = true;
    }
  }

  @override
  void didUpdateWidget(SafeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_isUsingInternalController) {
        _controller.dispose();
      }
      _initializeController();
    }
  }

  @override
  void dispose() {
    if (_isUsingInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      style: TextStyle(
        fontSize: Responsive.getFontSize(context),
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 16.0 : 20.0,
          vertical: context.isMobile ? 16.0 : 18.0,
        ),
      ),
    );
  }
}
