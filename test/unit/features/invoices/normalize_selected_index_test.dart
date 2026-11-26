import 'package:baudex_desktop/features/invoices/presentation/widgets/items_scroll_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('con productos siempre hay una fila elegida; sin productos, ninguna', () {
    expect(normalizeSelectedIndex(-1, 0), -1);
    expect(normalizeSelectedIndex(3, 0), -1);
    expect(normalizeSelectedIndex(-1, 1), 0);
    expect(normalizeSelectedIndex(-1, 5), 0);
    expect(normalizeSelectedIndex(5, 5), 4);
    expect(normalizeSelectedIndex(9, 2), 1);
    expect(normalizeSelectedIndex(2, 5), 2);
    expect(normalizeSelectedIndex(0, 1), 0);
  });
}
