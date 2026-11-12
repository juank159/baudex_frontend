// lib/app/core/printing/receipt_line.dart

/// Una línea de un recibo de impresora térmica, sin saber nada de la
/// impresora: quien arma el recibo solo dice QUÉ va en cada línea, y el
/// controlador de impresión lo convierte a comandos.
class ReceiptLine {
  /// Texto a la izquierda (o centrado si [center]).
  final String text;

  /// Texto a la derecha (valores); `null` si la línea es solo texto.
  final String? right;
  final bool bold;
  final bool center;

  /// Texto más grande (títulos).
  final bool large;

  /// Línea separadora (se ignora [text]).
  final bool divider;

  /// Líneas en blanco después.
  final int feedAfter;

  const ReceiptLine(
    this.text, {
    this.right,
    this.bold = false,
    this.center = false,
    this.large = false,
    this.feedAfter = 0,
  }) : divider = false;

  const ReceiptLine.divider()
      : text = '',
        right = null,
        bold = false,
        center = false,
        large = false,
        feedAfter = 0,
        divider = true;

  const ReceiptLine.title(this.text)
      : right = null,
        bold = true,
        center = true,
        large = true,
        feedAfter = 0,
        divider = false;

  const ReceiptLine.center(this.text, {this.bold = false})
      : right = null,
        center = true,
        large = false,
        feedAfter = 0,
        divider = false;

  const ReceiptLine.amount(this.text, String this.right, {this.bold = false})
      : center = false,
        large = false,
        feedAfter = 0,
        divider = false;

  /// El recibo como texto plano (para pruebas y vista previa).
  static String toPlainText(List<ReceiptLine> lines, {int width = 42}) {
    final out = StringBuffer();
    for (final line in lines) {
      if (line.divider) {
        out.writeln('-' * width);
      } else if (line.right != null) {
        final space = width - line.text.length - line.right!.length;
        out.writeln('${line.text}${' ' * (space < 1 ? 1 : space)}${line.right}');
      } else if (line.center) {
        final pad = ((width - line.text.length) / 2).floor();
        out.writeln('${' ' * (pad < 0 ? 0 : pad)}${line.text}');
      } else {
        out.writeln(line.text);
      }
      for (var i = 0; i < line.feedAfter; i++) {
        out.writeln();
      }
    }
    return out.toString();
  }
}
