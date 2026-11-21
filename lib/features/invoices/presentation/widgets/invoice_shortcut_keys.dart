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
