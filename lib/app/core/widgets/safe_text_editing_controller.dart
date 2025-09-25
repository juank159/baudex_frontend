// lib/app/core/widgets/safe_text_editing_controller.dart
import 'package:flutter/material.dart';

/// Un wrapper seguro para TextEditingController que maneja la disposición de forma segura
/// y previene errores cuando se intenta usar un controller después de disposed
class SafeTextEditingController extends TextEditingController {
  bool _isDisposed = false;
  
  /// Getter para verificar si el controller ha sido disposed
  bool get isDisposed => _isDisposed;
  
  /// Getter seguro para text que no falla si está disposed
  @override
  String get text {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de acceso a text después de dispose');
      return '';
    }
    try {
      return super.text;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error accediendo text: $e');
      _isDisposed = true;
      return '';
    }
  }
  
  /// Setter seguro para text que no falla si está disposed
  @override
  set text(String newText) {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de modificar text después de dispose');
      return;
    }
    try {
      super.text = newText;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error modificando text: $e');
      _isDisposed = true;
    }
  }
  
  /// Getter seguro para selection que no falla si está disposed
  @override
  TextSelection get selection {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de acceso a selection después de dispose');
      return const TextSelection.collapsed(offset: 0);
    }
    try {
      return super.selection;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error accediendo selection: $e');
      _isDisposed = true;
      return const TextSelection.collapsed(offset: 0);
    }
  }
  
  /// Setter seguro para selection que no falla si está disposed
  @override
  set selection(TextSelection newSelection) {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de modificar selection después de dispose');
      return;
    }
    try {
      super.selection = newSelection;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error modificando selection: $e');
      _isDisposed = true;
    }
  }
  
  /// Getter seguro para value que no falla si está disposed
  @override
  TextEditingValue get value {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de acceso a value después de dispose');
      return const TextEditingValue(text: '');
    }
    try {
      return super.value;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error accediendo value: $e');
      _isDisposed = true;
      return const TextEditingValue(text: '');
    }
  }
  
  /// Setter seguro para value que no falla si está disposed
  @override
  set value(TextEditingValue newValue) {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de modificar value después de dispose');
      return;
    }
    try {
      super.value = newValue;
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error modificando value: $e');
      _isDisposed = true;
    }
  }
  
  /// Clear seguro que no falla si está disposed
  @override
  void clear() {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de clear después de dispose');
      return;
    }
    try {
      super.clear();
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error en clear: $e');
      _isDisposed = true;
    }
  }
  
  /// addListener seguro que no falla si está disposed
  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de addListener después de dispose');
      return;
    }
    try {
      super.addListener(listener);
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error en addListener: $e');
      _isDisposed = true;
    }
  }
  
  /// removeListener seguro que no falla si está disposed
  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de removeListener después de dispose');
      return;
    }
    try {
      super.removeListener(listener);
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error en removeListener: $e');
      _isDisposed = true;
    }
  }
  
  /// Dispose seguro que marca el controller como disposed y previene uso futuro
  @override
  void dispose() {
    if (_isDisposed) {
      print('⚠️ SafeTextEditingController: Intento de dispose múltiple');
      return;
    }
    
    try {
      print('🔧 SafeTextEditingController: Disposing controller safely');
      _isDisposed = true;
      super.dispose();
      print('✅ SafeTextEditingController: Controller disposed successfully');
    } catch (e) {
      print('⚠️ SafeTextEditingController: Error during dispose: $e');
      _isDisposed = true;
    }
  }
  
  /// Método para verificar si el controller es seguro de usar
  bool get isSafeToUse {
    if (_isDisposed) return false;
    
    try {
      // Test básico de accesibilidad
      super.text;
      return true;
    } catch (e) {
      _isDisposed = true;
      return false;
    }
  }
}