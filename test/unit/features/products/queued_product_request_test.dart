// Armado de requests de producto desde la cola de sincronización.
// Caso real: operaciones encoladas con taxCategory 'IVA' (valor del servidor)
// fallaban siempre con "Bad state: No element".
import 'dart:convert';

import 'package:baudex_desktop/app/data/local/sync_enum_parse.dart';
import 'package:baudex_desktop/features/expenses/domain/entities/expense.dart';
import 'package:baudex_desktop/features/products/data/sync/queued_product_request.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos como los deja `product_repository_impl` en la cola, pasados por
/// JSON igual que en Isar.
Map<String, dynamic> queued({Object? tax, Object? ret}) => jsonDecode(
      jsonEncode({
        'name': 'Gaseosa',
        'sku': 'GAS-1',
        'type': 'product',
        'status': 'active',
        'stock': 10,
        'minStock': 2,
        'categoryId': 'cat-1',
        'prices': [
          {'type': 'price1', 'name': 'Público', 'amount': 3500, 'currency': 'COP'},
        ],
        'taxCategory': tax,
        'taxRate': 19,
        'isTaxable': true,
        'retentionCategory': ret,
        'retentionRate': 15,
        'hasRetention': ret != null,
      }),
    ) as Map<String, dynamic>;

void main() {
  group('create y update desde la cola', () {
    final casos = <String, (Object?, Object?, String?, String?)>{
      "valor del servidor 'IVA' / 'RET_IVA'": ('IVA', 'RET_IVA', 'IVA', 'RET_IVA'),
      "nombre del enum 'iva' / 'retIva'": ('iva', 'retIva', 'IVA', 'RET_IVA'),
      "'NO_GRAVADO' / 'RET_RENTA'": ('NO_GRAVADO', 'RET_RENTA', 'NO_GRAVADO', 'RET_RENTA'),
      "'incBolsa' / 'retIca'": ('incBolsa', 'retIca', 'INC_BOLSA', 'RET_ICA'),
      'desconocido: se envía tal cual': ('IVA_RARO', 'RET_X', 'IVA_RARO', 'RET_X'),
      'sin impuesto: no se envía': (null, null, null, null),
    };

    casos.forEach((nombre, c) {
      final (tax, ret, taxEsperado, retEsperado) = c;

      test('create · $nombre', () {
        final req = createProductRequestFromQueue(
          queued(tax: tax, ret: ret),
          categoryId: 'cat-1',
        );
        final json = req.toJson();
        expect(json['taxCategory'], taxEsperado);
        expect(json['retentionCategory'], retEsperado);
        expect(json['taxRate'], 19.0);
        expect(json['isTaxable'], true);
        expect(json['name'], 'Gaseosa');
        expect(json['type'], 'product');
        expect(json['status'], 'active');
        expect(json['stock'], 10.0);
        expect((json['prices'] as List).single['type'], 'price1');
        expect((json['prices'] as List).single['amount'], 3500.0);
      });

      test('update · $nombre', () {
        final req = updateProductRequestFromQueue(
          queued(tax: tax, ret: ret),
          categoryId: 'cat-1',
        );
        final json = req.toJson();
        expect(json['taxCategory'], taxEsperado);
        expect(json['retentionCategory'], retEsperado);
        expect(json['taxRate'], 19.0);
        expect(json['name'], 'Gaseosa');
        expect(json['categoryId'], 'cat-1');
        expect((json['prices'] as List).single['type'], 'price1');
      });
    });

    test('tipo de producto desconocido no rompe el armado', () {
      final data = queued(tax: 'IVA', ret: null)..['type'] = 'combo';
      expect(createProductRequestFromQueue(data, categoryId: 'c').type, 'combo');
    });
  });

  group('tryParse de impuestos', () {
    test('acepta valor o nombre, sin distinguir mayúsculas', () {
      expect(TaxCategory.tryParse('IVA'), TaxCategory.iva);
      expect(TaxCategory.tryParse('iva'), TaxCategory.iva);
      expect(TaxCategory.tryParse('noGravado'), TaxCategory.noGravado);
      expect(TaxCategory.tryParse(' NO_GRAVADO '), TaxCategory.noGravado);
      expect(RetentionCategory.tryParse('RET_IVA'), RetentionCategory.retIva);
      expect(RetentionCategory.tryParse('retRenta'), RetentionCategory.retRenta);
    });

    test('desconocido o vacío → null, nunca un valor por defecto', () {
      expect(TaxCategory.tryParse('XYZ'), isNull);
      expect(TaxCategory.tryParse(''), isNull);
      expect(TaxCategory.tryParse(null), isNull);
      expect(RetentionCategory.tryParse('XYZ'), isNull);
    });
  });

  group('enumFromQueue', () {
    test('reconoce nombre y MAYUSCULA_CON_GUION', () {
      expect(enumFromQueue(PaymentMethod.values, 'cash'), PaymentMethod.cash);
      expect(enumFromQueue(ExpenseStatus.values, 'PENDING'), ExpenseStatus.pending);
      expect(enumFromQueue(PaymentMethod.values, PaymentMethod.cash), PaymentMethod.cash);
    });

    test('desconocido → null; obligatorio → rechazo visible', () {
      expect(enumFromQueue(PaymentMethod.values, 'bitcoin'), isNull);
      expect(
        () => requiredEnumFromQueue(PaymentMethod.values, 'bitcoin', field: 'paymentMethod'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Solicitud incorrecta'),
        )),
      );
    });
  });
}
