// lib/app/core/printing/receipt_escpos.dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;

import 'receipt_line.dart';

/// Deja el texto en caracteres que cualquier impresora térmica imprime bien
/// (sin tildes ni símbolos especiales).
String printableAscii(String text) {
  const map = <String, String>{
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
    '·': '-', '−': '-', '–': '-', '—': '-', '¡': '', '¿': '',
    ' ': ' ', ' ': ' ', '“': '"', '”': '"', '‘': "'", '’': "'",
  };
  final out = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = map[ch];
    if (mapped != null) {
      out.write(mapped);
    } else if (rune >= 0x20 && rune < 0x7F) {
      out.write(ch);
    } else {
      out.write('?');
    }
  }
  return out.toString();
}

/// Columnas (de 12) que necesita el texto de la derecha de una línea.
/// [charsPerLine]: 48 en papel de 80 mm, 32 en 58 mm.
int receiptRightColumns(String right, int charsPerLine) {
  final perColumn = charsPerLine / 12;
  final needed = ((right.length + 1) / perColumn).ceil();
  return needed.clamp(3, 8);
}

/// Convierte las líneas de un recibo a comandos ESC/POS.
List<int> receiptLinesToEscPos(
  esc_pos.Generator generator,
  List<ReceiptLine> lines, {
  int charsPerLine = 48,
}) {
  final bytes = <int>[];
  for (final line in lines) {
    if (line.divider) {
      bytes.addAll(generator.hr());
    } else if (line.right != null) {
      final right = printableAscii(line.right!);
      final left = printableAscii(line.text);
      // Si no caben los dos en un renglón (papel angosto), van en dos.
      if (left.length + right.length + 1 > charsPerLine) {
        bytes
          ..addAll(generator.text(left, styles: esc_pos.PosStyles(bold: line.bold)))
          ..addAll(generator.text(
            right,
            styles: esc_pos.PosStyles(bold: line.bold, align: esc_pos.PosAlign.right),
          ));
        if (line.feedAfter > 0) bytes.addAll(generator.feed(line.feedAfter));
        continue;
      }
      final rightColumns = receiptRightColumns(right, charsPerLine);
      bytes.addAll(generator.row([
        esc_pos.PosColumn(
          text: left,
          width: 12 - rightColumns,
          styles: esc_pos.PosStyles(bold: line.bold),
        ),
        esc_pos.PosColumn(
          text: right,
          width: rightColumns,
          styles: esc_pos.PosStyles(bold: line.bold, align: esc_pos.PosAlign.right),
        ),
      ]));
    } else {
      bytes.addAll(generator.text(
        printableAscii(line.text),
        styles: esc_pos.PosStyles(
          bold: line.bold,
          align: line.center ? esc_pos.PosAlign.center : esc_pos.PosAlign.left,
          height: line.large ? esc_pos.PosTextSize.size2 : esc_pos.PosTextSize.size1,
          width: line.large ? esc_pos.PosTextSize.size2 : esc_pos.PosTextSize.size1,
        ),
      ));
    }
    if (line.feedAfter > 0) bytes.addAll(generator.feed(line.feedAfter));
  }
  return bytes;
}
