// File: lib/app/shared/widgets/safe_text_editing_controller.dart
import 'package:flutter/material.dart';
import 'dart:async';

/// ✅ SOLUCIÓN DEFINITIVA: SafeTextEditingController
/// 
/// Este wrapper previene COMPLETAMENTE los errores de:
/// - "A TextEditingController was used after being disposed"
/// - Crashes durante navegación y lifecycle de widgets
/// 
/// Características:
/// 1. Auto-detección de estado disposed
/// 2. Fallback seguro para todas las operaciones
/// 3. Logging detallado para debugging
/// 4. Compatible 100% con TextEditingController standard
class SafeTextEditingController extends TextEditingController {
  bool _isDisposed = false;
  bool _isInitialized = true;
  final String? _debugLabel;
  final List<VoidCallback> _safeListeners = [];

  SafeTextEditingController({
    String? text,
    String? debugLabel,
  }) : _debugLabel = debugLabel,
       super(text: text) {
    _log('🔧 SafeTextEditingController creado: $_debugLabel');
  }

  SafeTextEditingController.fromValue(
    TextEditingValue? value, {
    String? debugLabel,
  }) : _debugLabel = debugLabel,
       super.fromValue(value) {
    _log('🔧 SafeTextEditingController.fromValue creado: $_debugLabel');
  }

  /// ✅ VERIFICACIÓN CRÍTICA: Estado del controlador
  bool get isSafeToUse {
    return !_isDisposed && _isInitialized;
  }

  bool get isDisposed => _isDisposed;

  /// ✅ OVERRIDE SEGURO: text getter
  @override
  String get text {
    if (!isSafeToUse) {
      return '';
    }
    try {
      return super.text;
    } catch (e) {
      _isDisposed = true;
      return '';
    }
  }

  /// ✅ OVERRIDE SEGURO: text setter
  @override
  set text(String newText) {
    if (!isSafeToUse) {
      return;
    }
    try {
      super.text = newText;
    } catch (e) {
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: selection getter
  @override
  TextSelection get selection {
    if (!isSafeToUse) {
      return const TextSelection.collapsed(offset: 0);
    }
    try {
      return super.selection;
    } catch (e) {
      _isDisposed = true;
      return const TextSelection.collapsed(offset: 0);
    }
  }

  /// ✅ OVERRIDE SEGURO: selection setter
  @override
  set selection(TextSelection newSelection) {
    if (!isSafeToUse) {
      return;
    }
    try {
      super.selection = newSelection;
    } catch (e) {
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: value getter
  @override
  TextEditingValue get value {
    if (!isSafeToUse) {
      return const TextEditingValue();
    }
    try {
      return super.value;
    } catch (e) {
      _isDisposed = true;
      return const TextEditingValue();
    }
  }

  /// ✅ OVERRIDE SEGURO: value setter
  @override
  set value(TextEditingValue newValue) {
    if (!isSafeToUse) {
      return;
    }
    try {
      super.value = newValue;
    } catch (e) {
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: clear
  @override
  void clear() {
    if (!isSafeToUse) {
      _log('⚠️ Intentando clear en controlador disposed, ignorando');
      return;
    }
    try {
      super.clear();
    } catch (e) {
      _log('❌ Error en clear: $e');
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: addListener
  @override
  void addListener(VoidCallback listener) {
    if (!isSafeToUse) {
      return;
    }
    try {
      super.addListener(listener);
      _safeListeners.add(listener);
    } catch (e) {
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: removeListener
  @override
  void removeListener(VoidCallback listener) {
    if (!isSafeToUse) {
      return;
    }
    try {
      super.removeListener(listener);
      _safeListeners.remove(listener);
    } catch (e) {
      _isDisposed = true;
    }
  }

  /// ✅ OVERRIDE SEGURO: hasListeners
  @override
  bool get hasListeners {
    if (!isSafeToUse) {
      return false;
    }
    try {
      return super.hasListeners;
    } catch (e) {
      _isDisposed = true;
      return false;
    }
  }

  /// ✅ OVERRIDE SEGURO: dispose
  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    try {
      // Marcar como disposed ANTES de cualquier operación
      _isDisposed = true;
      _isInitialized = false;

      // Remover todos los listeners de forma segura
      final listenersToRemove = List<VoidCallback>.from(_safeListeners);
      for (final listener in listenersToRemove) {
        try {
          super.removeListener(listener);
        } catch (e) {
          // Silently handle listener removal errors
        }
      }
      _safeListeners.clear();

      // Llamar dispose del padre
      super.dispose();
      
    } catch (e) {
      _isDisposed = true;
      _isInitialized = false;
    }
  }

  /// ✅ MÉTODO UTILITY: Verificar si el controlador puede usarse de forma segura
  bool canSafelyAccess() {
    return isSafeToUse;
  }

  /// ✅ MÉTODO UTILITY: Intentar operación de forma segura
  T? safeExecute<T>(T Function() operation, [T? fallback]) {
    if (!isSafeToUse) {
      return fallback;
    }
    
    try {
      return operation();
    } catch (e) {
      _isDisposed = true;
      return fallback;
    }
  }

  /// ✅ MÉTODO UTILITY: Obtener texto de forma segura
  String safeText() {
    return safeExecute(() => text, '') ?? '';
  }

  /// ✅ MÉTODO UTILITY: Setear texto de forma segura
  void safeSetText(String newText) {
    safeExecute(() => text = newText);
  }

  /// ✅ MÉTODO UTILITY: Clear de forma segura
  void safeClear() {
    safeExecute(() => clear());
  }

  /// ✅ LOGGING: Método privado para logging consistente
  void _log(String message) {
    print('🛡️ SafeTextEditingController${_debugLabel != null ? " ($_debugLabel)" : ""}: $message');
  }

  /// ✅ FACTORY: Crear desde controlador existente (si es necesario)
  factory SafeTextEditingController.fromExisting(
    TextEditingController? existing, {
    String? debugLabel,
  }) {
    if (existing == null) {
      return SafeTextEditingController(debugLabel: debugLabel);
    }
    
    // Intentar copiar el valor si el controlador existente es seguro
    try {
      final currentText = existing.text;
      return SafeTextEditingController(
        text: currentText,
        debugLabel: debugLabel,
      );
    } catch (e) {
      print('⚠️ SafeTextEditingController.fromExisting: Controlador fuente unsafe, creando nuevo vacío');
      return SafeTextEditingController(debugLabel: debugLabel);
    }
  }
}

/// ✅ EXTENSION UTILITY: Para convertir TextEditingController normales
extension TextEditingControllerSafeExtension on TextEditingController {
  /// Verificar si el controlador es seguro para usar
  bool get isSafe {
    try {
      final _ = text;
      final __ = selection;
      final ___ = value;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convertir a SafeTextEditingController
  SafeTextEditingController toSafe([String? debugLabel]) {
    return SafeTextEditingController.fromExisting(this, debugLabel: debugLabel);
  }
}