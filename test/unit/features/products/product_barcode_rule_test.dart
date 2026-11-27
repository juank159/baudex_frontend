// Regla del código de barras al guardar un producto: de 1 a 20 caracteres,
// sin espacios (o vacío). Caso real: "0013390" (7 dígitos, ceros adelante)
// salía "Código de barras inválido" porque se exigían de 8 a 18.
import 'package:baudex_desktop/features/products/domain/services/product_code_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('productBarcodeError', () {
    test('vacío o solo espacios: sirve (es opcional)', () {
      expect(productBarcodeError(null), isNull);
      expect(productBarcodeError(''), isNull);
      expect(productBarcodeError('   '), isNull);
    });

    test('códigos cortos y con ceros adelante: sirven', () {
      for (final code in ['0013390', '1', '57', '500', '0', '000123']) {
        expect(productBarcodeError(code), isNull, reason: code);
      }
    });

    test('EAN-8, UPC-A, EAN-13 y códigos con letras: sirven', () {
      for (final code in [
        '12345670',
        '012345678905',
        '7701234567890',
        'ABC-123',
        'p.01/x',
      ]) {
        expect(productBarcodeError(code), isNull, reason: code);
      }
    });

    test('espacios a los lados no cuentan', () {
      expect(productBarcodeError('  0013390  '), isNull);
      expect(productBarcodeError(' ${'9' * 20} '), isNull);
    });

    test('20 caracteres sirve; 21 no', () {
      expect(productBarcodeError('1' * 20), isNull);
      expect(productBarcodeError('1' * 21),
          'El código de barras no puede tener más de 20 caracteres');
    });

    test('antes se rechazaban 19 y 20 (el servidor sí los acepta)', () {
      expect(productBarcodeError('1' * 19), isNull);
    });

    test('espacios por dentro: mensaje claro', () {
      expect(productBarcodeError('001 3390'),
          'El código de barras no puede tener espacios');
      expect(productBarcodeError('001\t3390'),
          'El código de barras no puede tener espacios');
    });

    test('el largo máximo se puede cambiar (presentaciones: 30)', () {
      expect(productBarcodeError('1' * 30, maxLength: 30), isNull);
      expect(productBarcodeError('1' * 31, maxLength: 30),
          'El código de barras no puede tener más de 30 caracteres');
    });
  });
}
