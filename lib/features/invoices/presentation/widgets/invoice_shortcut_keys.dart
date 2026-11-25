// lib/features/invoices/presentation/widgets/invoice_shortcut_keys.dart
import 'package:flutter/services.dart';

/// Ctrl + tecla de la factura: ¿suma uno (+1), resta uno (-1) o ninguna (null)?
///
/// En el teclado español/latinoamericano la tecla "+" no es `=` sino el
/// carácter `+` (`LogicalKeyboardKey.add`), y el teclado numérico manda
/// `numpadAdd`/`numpadSubtract`: antes solo se atendía `Ctrl + =` y en el
/// teclado del cliente Ctrl++ no hacía nada.
int? quantityShortcutDelta(LogicalKeyboardKey key, {String? character}) {
  if (key == LogicalKeyboardKey.equal ||
      key == LogicalKeyboardKey.add ||
      key == LogicalKeyboardKey.numpadAdd ||
      character == '+' ||
      character == '=') {
    return 1;
  }
  if (key == LogicalKeyboardKey.minus ||
      key == LogicalKeyboardKey.numpadSubtract ||
      character == '-') {
    return -1;
  }
  return null;
}

final Set<LogicalKeyboardKey> _digitKeys = {
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
  LogicalKeyboardKey.numpad0,
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
  LogicalKeyboardKey.numpad7,
  LogicalKeyboardKey.numpad8,
  LogicalKeyboardKey.numpad9,
};

/// Dígito suelto (sin Ctrl, Alt ni la tecla de Windows/Cmd): lo escribe el
/// cajero o el lector de código de barras y ningún atajo de la factura lo
/// usa (todos van con Ctrl). Los manejadores globales salen de una vez con
/// estas teclas: el lector manda 13 seguidas en milésimas.
bool isPlainDigitKey(
  LogicalKeyboardKey key, {
  required bool modifierPressed,
}) =>
    !modifierPressed && _digitKeys.contains(key);

/// ¿Hay un modificador de atajo presionado ahora?
bool shortcutModifierPressed() {
  final keyboard = HardwareKeyboard.instance;
  return keyboard.isControlPressed ||
      keyboard.isAltPressed ||
      keyboard.isMetaPressed;
}
