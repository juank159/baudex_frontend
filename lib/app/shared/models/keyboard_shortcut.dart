// lib/app/shared/models/keyboard_shortcut.dart
import 'package:flutter/services.dart';

/// Modificadores soportados en los atajos.
enum ShortcutModifier { ctrl, alt, shift, meta }

/// Contexto donde aplica un atajo. Sirve solo para AGRUPAR la guía
/// visual; el comportamiento (interceptar o no) lo decide el árbol de
/// `Shortcuts/Actions` de Flutter en cada pantalla.
enum ShortcutScope {
  /// Funciona en cualquier pantalla de la app autenticada.
  global,

  /// Solo en la pantalla de pestañas de creación de facturas
  /// (`/invoices/tabs`). Maneja navegación entre pestañas.
  invoiceTabs,

  /// Dentro del formulario individual de factura (cantidades, navegación
  /// de items, agregar productos).
  invoiceForm,
}

/// Una entrada de la cheat sheet: la tecla, qué hace y dónde aplica.
///
/// Esta es la fuente única de verdad. El widget que muestra la guía
/// (`KeyboardShortcutsDialog`) y los handlers de `Shortcuts/Actions`
/// leen de aquí, así no hay riesgo de que la guía mienta sobre lo que
/// realmente está implementado.
class KeyboardShortcut {
  /// Identificador estable usado por los Intents (no es visible al usuario).
  final String id;

  /// Modificadores requeridos (Ctrl, Alt, Shift, Cmd).
  final List<ShortcutModifier> modifiers;

  /// Tecla principal. Puede ser una letra, número, símbolo o tecla
  /// especial (Enter, Esc, etc).
  final LogicalKeyboardKey key;

  /// Etiqueta humana de la tecla cuando no es solo `key.keyLabel`.
  /// Ej. `=` se muestra como `+`, `slash` como `/`, etc.
  final String keyLabel;

  /// Texto descriptivo para mostrar en la guía.
  final String description;

  /// Donde aplica.
  final ShortcutScope scope;

  /// Nombre humano de la pantalla donde funciona. Útil para que el
  /// usuario sepa "esto solo aplica en el form de factura".
  final String screenName;

  const KeyboardShortcut({
    required this.id,
    required this.modifiers,
    required this.key,
    required this.keyLabel,
    required this.description,
    required this.scope,
    required this.screenName,
  });

  /// Combinación canónica para mostrar (ej. "Ctrl + K", "Alt + 1").
  /// En macOS Ctrl se renombra a Cmd para coincidir con la convención.
  String displayCombo({bool isMacOs = false}) {
    final parts = <String>[];
    for (final m in modifiers) {
      switch (m) {
        case ShortcutModifier.ctrl:
          parts.add(isMacOs ? '⌘' : 'Ctrl');
          break;
        case ShortcutModifier.alt:
          parts.add(isMacOs ? '⌥' : 'Alt');
          break;
        case ShortcutModifier.shift:
          parts.add(isMacOs ? '⇧' : 'Shift');
          break;
        case ShortcutModifier.meta:
          parts.add(isMacOs ? '⌘' : 'Win');
          break;
      }
    }
    parts.add(keyLabel);
    return parts.join(isMacOs ? '' : ' + ');
  }

  /// Lista de teclas individuales para renderizar como pills/chips en UI.
  List<String> displayParts({bool isMacOs = false}) {
    final parts = <String>[];
    for (final m in modifiers) {
      switch (m) {
        case ShortcutModifier.ctrl:
          parts.add(isMacOs ? '⌘' : 'Ctrl');
          break;
        case ShortcutModifier.alt:
          parts.add(isMacOs ? '⌥' : 'Alt');
          break;
        case ShortcutModifier.shift:
          parts.add(isMacOs ? '⇧' : 'Shift');
          break;
        case ShortcutModifier.meta:
          parts.add(isMacOs ? '⌘' : 'Win');
          break;
      }
    }
    parts.add(keyLabel);
    return parts;
  }
}
