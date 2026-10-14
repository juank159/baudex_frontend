import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/app/shared/widgets/cost_above_price_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  group('Tasa de impuesto: lo que se muestra al editar se guarda igual', () {
    // Antes: el campo se llenaba con 19.0.toString() = "19.0" y se leía con
    // parseNumber, que borra los puntos → 190%. Pasó en 13 productos.
    test('parseNumber("19.0") era el bug', () {
      expect(AppFormatters.parseNumber('19.0'), 190);
    });

    for (final rate in [0.0, 5.0, 8.0, 16.0, 19.0, 2.5, 0.4, 100.0]) {
      test('$rate% ida y vuelta', () {
        final shown = AppFormatters.formatStock(rate);
        expect(AppFormatters.parseRate(shown), rate);
      });
    }

    test('acepta lo que el usuario escribe a mano', () {
      expect(AppFormatters.parseRate('19'), 19);
      expect(AppFormatters.parseRate('19.0'), 19);
      expect(AppFormatters.parseRate('2,5'), 2.5);
      expect(AppFormatters.parseRate('2.5'), 2.5);
    });
  });

  group('Stock y medidas conservan decimales al editar', () {
    for (final value in [2.5, 0.75, 1234.5, 1000.0, 12.0]) {
      test('$value', () {
        final shown = AppFormatters.formatStock(value);
        expect(AppFormatters.parseNumber(shown), value);
      });
    }
  });

  group('Costo de ajuste: formato colombiano', () {
    test('miles y decimales', () {
      expect(AppFormatters.parseRate('14.000'), 14000);
      expect(AppFormatters.parseRate('1.400'), 1400);
      expect(AppFormatters.parseRate('14000.00'), 14000);
      expect(AppFormatters.parseRate('1400'), 1400);
    });
  });

  group('Aviso de costo mayor al precio', () {
    test('chorizos: costo del paquete como costo por unidad', () {
      final w = CostAbovePrice.check(
        productName: 'CHORIZOS VNZOLANOS',
        unitCost: 14000,
        unitPrice: 2500,
      );
      expect(w, isNotNull);
      expect(w!.unitCost / w.unitPrice, closeTo(5.6, 0.01));
    });

    test('costo normal no avisa', () {
      expect(
        CostAbovePrice.check(productName: 'X', unitCost: 1400, unitPrice: 2500),
        isNull,
      );
      expect(
        CostAbovePrice.check(productName: 'X', unitCost: 2500, unitPrice: 2500),
        isNull,
      );
    });

    test('sin precio de venta no hay con qué comparar', () {
      expect(
        CostAbovePrice.check(productName: 'X', unitCost: 9000, unitPrice: null),
        isNull,
      );
      expect(
        CostAbovePrice.check(productName: 'X', unitCost: 9000, unitPrice: 0),
        isNull,
      );
    });
  });
}
