import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/features/products/domain/services/product_deletion_rules.dart';

/// Integridad del inventario: un producto con existencias no se borra, y un
/// rechazo del servidor no se convierte en un borrado local.
void main() {
  group('productDeletionBlockReason', () {
    test('con existencias no se puede borrar y el mensaje dice cuántas', () {
      final reason = productDeletionBlockReason(name: 'Arroz', stock: 50);
      expect(reason, isNotNull);
      expect(reason, contains('Arroz'));
      expect(reason, contains('50'));
    });

    test('con existencias fraccionadas muestra los decimales', () {
      expect(productDeletionBlockReason(name: 'Queso', stock: 1.5), contains('1.50'));
    });

    test('sin existencias sí se puede borrar', () {
      expect(productDeletionBlockReason(name: 'Arroz', stock: 0), isNull);
    });

    test('con existencias negativas (sobreventa) no bloquea aquí: decide el servidor', () {
      expect(productDeletionBlockReason(name: 'Arroz', stock: -2), isNull);
    });
  });

  group('isServerRejection', () {
    test('409, 400, 403 y 422 son rechazos definitivos', () {
      for (final code in [400, 403, 409, 422]) {
        expect(isServerRejection(code), isTrue, reason: '$code');
      }
    });

    test('sin código, 401, 408, 429 y 5xx no son rechazos: se puede reintentar', () {
      for (final code in [null, 401, 408, 429, 500, 503]) {
        expect(isServerRejection(code), isFalse, reason: '$code');
      }
    });
  });
}
