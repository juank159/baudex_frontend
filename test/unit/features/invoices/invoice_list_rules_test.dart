import 'package:baudex_desktop/features/invoices/domain/services/invoice_list_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool more({
    bool filter = true,
    int visible = 0,
    int target = 30,
    bool next = true,
    int extra = 0,
  }) =>
      shouldFetchMoreToFillList(
        localFilterActive: filter,
        visible: visible,
        target: target,
        hasNextPage: next,
        extraPagesSoFar: extra,
      );

  test('"Pendientes" con la página vacía: trae otra', () {
    expect(more(), isTrue);
    expect(more(visible: 12), isTrue);
  });
  test('ya hay filas suficientes: no trae más', () {
    expect(more(visible: 30), isFalse);
    expect(more(visible: 45, target: 40), isFalse);
  });
  test('sin filtro en pantalla, sin más páginas o en el tope: no trae', () {
    expect(more(filter: false), isFalse);
    expect(more(next: false), isFalse);
    expect(more(extra: 15), isFalse);
    expect(more(extra: 14), isTrue);
  });
}
