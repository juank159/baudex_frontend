import 'package:baudex_desktop/features/invoices/presentation/widgets/items_scroll_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Re-escanear una línea del medio de una factura larga debe llevarla a la
/// vista con el alto real de las filas (antes se suponían 54 px).
void main() {
  double? reveal(int index, {double row = 36, int count = 40, double viewport = 300, double offset = 0}) =>
      scrollOffsetToReveal(
        index: index,
        itemCount: count,
        contentExtent: row * count,
        viewportExtent: viewport,
        currentOffset: offset,
      );

  test('fila 20 en escritorio (36 px): queda centrada en la vista', () {
    // Tope 720; centrada: 720 - (300 - 36) / 2 = 588. Con 54 px por fila
    // habría ido a ~1000, muy por debajo de la fila.
    expect(reveal(20), 588);
  });

  test('fila 20 en celular (41 px)', () {
    expect(reveal(20, row: 41), 20 * 41 - (300 - 41) / 2);
  });

  test('cerca del final no pasa del máximo', () {
    expect(reveal(39), 40 * 36 - 300);
  });

  test('si ya se ve completa no se mueve', () {
    expect(reveal(3), isNull);
    expect(reveal(20, offset: 500), isNull);
    expect(reveal(20, offset: 800), 588); // arriba de la vista: vuelve a centrarla
  });

  test('índices fuera de rango o lista vacía: nada', () {
    expect(reveal(-1), isNull);
    expect(reveal(40), isNull);
    expect(reveal(0, count: 0), isNull);
  });
}
