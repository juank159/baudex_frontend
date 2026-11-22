// Regla del buscador de la factura: valor (producto sin registrar) frente a
// código de barras, y el índice de códigos cortos.
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifySearchEntry', () {
    test('hasta 7 dígitos es un valor', () {
      for (final v in ['5', '500', '600', '20000', '9999999', ' 3500 ']) {
        expect(classifySearchEntry(v), SearchEntryKind.price, reason: v);
      }
    });
    test('8 dígitos o más es código de barras', () {
      for (final v in ['12345678', '7701234567890', '012345678905']) {
        expect(classifySearchEntry(v), SearchEntryKind.barcode, reason: v);
      }
    });
    test('texto, vacío y negativos no son valor', () {
      for (final v in ['', 'leche', 'ARR-1', '50a', '-500']) {
        expect(classifySearchEntry(v), SearchEntryKind.text, reason: v);
      }
    });
    test('puntos y comas se ignoran para contar dígitos (regla de siempre)', () {
      expect(classifySearchEntry('3.500'), SearchEntryKind.price);
      expect(classifySearchEntry('1234.5678'), SearchEntryKind.barcode);
    });
  });

  group('decidePriceEntry', () {
    final index = ShortCodeIndex.build([
      ('5000', 3), // SKU numérico corto
      ('777', 4), // código de barras corto
      ('ARR-1', 1), // SKU con letras: no entra
      ('7701111111111', 1), // código largo: no entra
      (null, 2),
    ], complete: true);

    test('valor sin producto con ese código: sin registrar al instante', () {
      final d = decidePriceEntry('20000', index);
      expect(d, isA<AddUnregisteredProduct>());
      expect((d as AddUnregisteredProduct).price, 20000);
    });
    test('SKU corto registrado gana', () {
      final d = decidePriceEntry('5000', index);
      expect((d as AddExistingProduct).localId, 3);
    });
    test('código de barras corto registrado gana', () {
      expect((decidePriceEntry('777', index) as AddExistingProduct).localId, 4);
    });
    test('el índice solo guarda códigos cortos', () {
      expect(index.length, 2);
    });
    test('sin índice o con catálogo incompleto se consulta la base', () {
      expect(decidePriceEntry('20000', null), isA<PriceEntryNeedsLookup>());
      final partial = ShortCodeIndex.build([('5000', 3)], complete: false);
      expect(decidePriceEntry('20000', partial), isA<PriceEntryNeedsLookup>());
      expect(decidePriceEntry('5000', partial), isA<AddExistingProduct>());
    });
    test('un código de barras nunca es sin registrar', () {
      expect(decidePriceEntry('7701111111111', index), isA<PriceEntryNeedsLookup>());
    });
    test('vejez del índice', () {
      final i = ShortCodeIndex.build(const [], complete: true, builtAt: DateTime(2026, 1, 1, 10));
      expect(i.isOlderThan(const Duration(seconds: 20), DateTime(2026, 1, 1, 10, 0, 10)), isFalse);
      expect(i.isOlderThan(const Duration(seconds: 20), DateTime(2026, 1, 1, 10, 0, 30)), isTrue);
    });
  });

  test('barcodeVariants: con y sin cero adelante', () {
    expect(barcodeVariants('012345678905'), ['012345678905', '12345678905', '0012345678905']);
    expect(barcodeVariants('7701234567890'), ['7701234567890', '07701234567890']);
    expect(barcodeVariants(' '), isEmpty);
  });
}
