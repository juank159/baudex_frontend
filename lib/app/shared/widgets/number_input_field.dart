// lib/app/shared/widgets/number_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/themes/app_dimensions.dart';
import '../../core/utils/formatters.dart';

class NumberInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final double? initialValue;
  final Function(double) onChanged;
  final bool isCurrency;
  final bool isStock;
  final bool isPercentage;
  final String? Function(String?)? validator;
  final bool enabled;
  final double? minValue;
  final double? maxValue;

  const NumberInputField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.initialValue,
    required this.onChanged,
    this.isCurrency = false,
    this.isStock = false,
    this.isPercentage = false,
    this.validator,
    this.enabled = true,
    this.minValue,
    this.maxValue,
  });

  @override
  State<NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _setupController();
    _focusNode.addListener(_onFocusChange);
  }

  void _setupController() {
    if (widget.initialValue != null) {
      _updateControllerValue(widget.initialValue!);
    }
  }

  void _updateControllerValue(double value) {
    String formattedValue;
    if (widget.isCurrency) {
      formattedValue = AppFormatters.formatCurrency(value);
    } else if (widget.isStock) {
      formattedValue = AppFormatters.formatStock(value);
    } else if (widget.isPercentage) {
      formattedValue = AppFormatters.formatStock(value);
    } else {
      formattedValue = AppFormatters.formatNumber(value);
    }
    
    if (!_isEditing) {
      _controller.text = formattedValue;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Al enfocar, mostrar el valor sin formato para fácil edición
      _isEditing = true;
      final currentValue = AppFormatters.parseNumber(_controller.text) ?? 0.0;
      _controller.text = currentValue.toString();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    } else {
      // Al desenfocar, formatear el valor
      _isEditing = false;
      final currentValue = AppFormatters.parseNumber(_controller.text) ?? 0.0;
      _updateControllerValue(currentValue);
    }
  }

  @override
  void didUpdateWidget(NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != null) {
      _updateControllerValue(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixText: widget.isPercentage ? '%' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
      ),
      validator: widget.validator,
      onChanged: (value) {
        final numericValue = AppFormatters.parseNumber(value) ?? 0.0;
        
        // Aplicar límites si están definidos
        double finalValue = numericValue;
        if (widget.minValue != null && finalValue < widget.minValue!) {
          finalValue = widget.minValue!;
        }
        if (widget.maxValue != null && finalValue > widget.maxValue!) {
          finalValue = widget.maxValue!;
        }
        
        widget.onChanged(finalValue);
      },
    );
  }
}