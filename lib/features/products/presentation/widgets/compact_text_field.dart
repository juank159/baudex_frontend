// lib/features/products/presentation/widgets/compact_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/utils/responsive_helper.dart';

class CompactTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool isRequired;
  final bool enabled;
  final bool obscureText;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;

  const CompactTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.isRequired = false,
    this.enabled = true,
    this.obscureText = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<CompactTextField> createState() => _CompactTextFieldState();
}

class _CompactTextFieldState extends State<CompactTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasValue = widget.controller.text.isNotEmpty;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label animado
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight:
                          _isFocused || hasValue
                              ? FontWeight.w600
                              : FontWeight.w500,
                      color:
                          _isFocused
                              ? primaryColor
                              : widget.enabled
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                    ),
                    child: Text(widget.label),
                  ),
                  if (widget.isRequired)
                    Text(
                      ' *',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Campo de texto
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _isFocused
                          ? primaryColor
                          : hasValue
                          ? primaryColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                color: Colors.white,
                boxShadow:
                    _isFocused || hasValue
                        ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                validator: widget.validator,
                maxLines: widget.maxLines,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                textCapitalization: widget.textCapitalization,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  color:
                      widget.enabled
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isMobile ? 12 : 14,
                  ),
                  prefixIcon:
                      widget.prefixIcon != null
                          ? Icon(
                              widget.prefixIcon!,
                              size: 18,
                              color:
                                  _isFocused || hasValue
                                      ? primaryColor
                                      : Colors.grey.shade400,
                            )
                          : null,
                  suffixIcon:
                      widget.suffixIcon != null
                          ? IconButton(
                            onPressed: widget.onSuffixIconPressed,
                            icon: Icon(
                              widget.suffixIcon!,
                              size: 18,
                              color:
                                  _isFocused
                                      ? primaryColor
                                      : Colors.grey.shade400,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.all(8),
                            ),
                          )
                          : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Widget para números con formato automático
class CompactNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final bool allowDecimals;
  final String? suffix;

  const CompactNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.allowDecimals = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return CompactTextField(
      controller: controller,
      label: suffix != null ? '$label ($suffix)' : label,
      hint: hint ?? '0',
      prefixIcon: prefixIcon,
      keyboardType:
          allowDecimals
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
      inputFormatters: [
        if (allowDecimals)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      isRequired: isRequired,
      enabled: enabled,
      focusNode: focusNode,
      onChanged: onChanged,
    );
  }
}

// Widget para precios con formato de moneda
class CompactPriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onChanged;

  const CompactPriceField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CompactTextField(
      controller: controller,
      label: label,
      hint: hint ?? '0',
      prefixIcon: Icons.attach_money,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
      isRequired: isRequired,
      enabled: enabled,
      focusNode: focusNode,
      onChanged: onChanged,
    );
  }
}

// Widget para campos con iconos de acción
class CompactActionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData actionIcon;
  final VoidCallback onActionPressed;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final FocusNode? focusNode;

  const CompactActionField({
    super.key,
    required this.controller,
    required this.label,
    required this.actionIcon,
    required this.onActionPressed,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return CompactTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: actionIcon,
      onSuffixIconPressed: onActionPressed,
      validator: validator,
      isRequired: isRequired,
      enabled: enabled,
      focusNode: focusNode,
    );
  }
}
