// lib/app/core/widgets/safe_text_field.dart
import 'package:flutter/material.dart';
import 'safe_text_editing_controller.dart';

/// Un TextField completamente seguro que nunca crashea por controllers disposed
class SafeTextField extends StatefulWidget {
  final SafeTextEditingController? controller;
  final InputDecoration? decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String? hintText;

  const SafeTextField({
    super.key,
    this.controller,
    this.decoration,
    this.style,
    this.onChanged,
    this.autofocus = false,
    this.hintText,
  });

  @override
  State<SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<SafeTextField> {
  late SafeTextEditingController _internalController;
  bool _usingInternalController = false;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(SafeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _setupController();
    }
  }

  void _setupController() {
    if (widget.controller != null && widget.controller!.isSafeToUse) {
      _internalController = widget.controller!;
      _usingInternalController = false;
    } else {
      // Si el controller externo no es seguro, usar uno interno
      if (_usingInternalController) {
        _internalController.dispose();
      }
      _internalController = SafeTextEditingController();
      _usingInternalController = true;
      print('⚠️ SafeTextField: Usando controller interno por controller externo no válido');
    }
  }

  @override
  void dispose() {
    if (_usingInternalController && _internalController.isSafeToUse) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar constantemente que el controller es seguro
    if (!_internalController.isSafeToUse) {
      return _buildFallbackField();
    }

    try {
      return TextField(
        controller: _internalController,
        decoration: widget.decoration ?? InputDecoration(
          hintText: widget.hintText ?? 'Buscar...',
          border: InputBorder.none,
        ),
        style: widget.style,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged != null ? (value) {
          if (mounted && _internalController.isSafeToUse) {
            try {
              widget.onChanged!(value);
            } catch (e) {
              print('⚠️ SafeTextField: Error in onChanged: $e');
            }
          }
        } : null,
      );
    } catch (e) {
      print('⚠️ SafeTextField: Error building TextField: $e');
      return _buildFallbackField();
    }
  }

  Widget _buildFallbackField() {
    return TextField(
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText ?? 'Buscar...',
        border: InputBorder.none,
        enabled: false,
      ),
      style: widget.style,
      enabled: false,
    );
  }
}