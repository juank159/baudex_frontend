// lib/app/shared/widgets/keyboard_safe_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A TextField wrapper that prevents Flutter keyboard state desynchronization issues
/// that cause KeyDownEvent assertions to fail
class KeyboardSafeTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? initialValue;
  final int? maxLines;
  final bool enabled;
  final bool autofocus;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;

  const KeyboardSafeTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.initialValue,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
  });

  @override
  State<KeyboardSafeTextField> createState() => _KeyboardSafeTextFieldState();
}

class _KeyboardSafeTextFieldState extends State<KeyboardSafeTextField> {
  // Track keyboard state to prevent conflicts
  final Map<LogicalKeyboardKey, bool> _pressedKeys = <LogicalKeyboardKey, bool>{};
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _shouldDisposeController = false;
  bool _shouldDisposeFocusNode = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _shouldDisposeController = true;
    }
    
    // Initialize focus node
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _shouldDisposeFocusNode = true;
    }
  }

  @override
  void dispose() {
    _pressedKeys.clear();
    if (_shouldDisposeController) {
      _controller.dispose();
    }
    if (_shouldDisposeFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // Key event handler to prevent keyboard state conflicts
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (_pressedKeys[event.logicalKey] == true) {
          // Key is already pressed, ignore this event to prevent assertion
          return KeyEventResult.handled;
        }
        _pressedKeys[event.logicalKey] = true;
      } else if (event is KeyUpEvent) {
        _pressedKeys[event.logicalKey] = false;
      } else if (event is KeyRepeatEvent) {
        // Handle repeat events without changing pressed state
        return KeyEventResult.ignored;
      }
      return KeyEventResult.ignored; // Allow normal processing
    } catch (e) {
      // Clear state on any error to reset keyboard tracking
      _pressedKeys.clear();
      return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        style: widget.style,
        textAlign: widget.textAlign,
        readOnly: widget.readOnly,
      ),
    );
  }
}

/// A TextFormField wrapper that prevents Flutter keyboard state desynchronization issues
class KeyboardSafeTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? initialValue;
  final int? maxLines;
  final bool enabled;
  final bool autofocus;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  const KeyboardSafeTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.initialValue,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<KeyboardSafeTextFormField> createState() => _KeyboardSafeTextFormFieldState();
}

class _KeyboardSafeTextFormFieldState extends State<KeyboardSafeTextFormField> {
  // Track keyboard state to prevent conflicts
  final Map<LogicalKeyboardKey, bool> _pressedKeys = <LogicalKeyboardKey, bool>{};
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _shouldDisposeController = false;
  bool _shouldDisposeFocusNode = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _shouldDisposeController = true;
    }
    
    // Initialize focus node
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _shouldDisposeFocusNode = true;
    }
  }

  @override
  void dispose() {
    _pressedKeys.clear();
    if (_shouldDisposeController) {
      _controller.dispose();
    }
    if (_shouldDisposeFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // Key event handler to prevent keyboard state conflicts
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (_pressedKeys[event.logicalKey] == true) {
          // Key is already pressed, ignore this event to prevent assertion
          return KeyEventResult.handled;
        }
        _pressedKeys[event.logicalKey] = true;
      } else if (event is KeyUpEvent) {
        _pressedKeys[event.logicalKey] = false;
      } else if (event is KeyRepeatEvent) {
        // Handle repeat events without changing pressed state
        return KeyEventResult.ignored;
      }
      return KeyEventResult.ignored; // Allow normal processing
    } catch (e) {
      // Clear state on any error to reset keyboard tracking
      _pressedKeys.clear();
      return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        style: widget.style,
        textAlign: widget.textAlign,
        readOnly: widget.readOnly,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        initialValue: widget.controller == null ? widget.initialValue : null,
      ),
    );
  }
}