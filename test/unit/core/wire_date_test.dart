import 'package:baudex_desktop/app/core/utils/wire_date.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toWireDateTime: la hora viaja como instante exacto en UTC', () {
    test('hora local del dispositivo → mismo instante en UTC, con Z', () {
      final local = DateTime(2026, 10, 13, 8, 22, 11, 243);
      final wire = toWireDateTime(local)!;
      expect(wire.endsWith('Z'), isTrue);
      expect(DateTime.parse(wire).isAtSameMomentAs(local), isTrue);
    });

    test('texto sin zona (como lo guardaba la cola) → mismo instante en UTC', () {
      final local = DateTime(2026, 10, 13, 8, 22, 11, 243);
      final wire = toWireDateTime(local.toIso8601String())!;
      expect(wire.endsWith('Z'), isTrue);
      expect(DateTime.parse(wire).isAtSameMomentAs(local), isTrue);
    });

    test('texto que ya trae Z no cambia de instante', () {
      final wire = toWireDateTime('2026-10-13T12:22:11.243Z')!;
      expect(DateTime.parse(wire), DateTime.utc(2026, 10, 13, 12, 22, 11, 243));
    });

    test('nulo y vacío', () {
      expect(toWireDateTime(null), isNull);
      expect(toWireDateTime(''), isNull);
    });

    test('texto que no es fecha se deja para que lo valide el servidor', () {
      expect(toWireDateTime('no-es-fecha'), 'no-es-fecha');
    });
  });

  offsetTests();

  test('el abono manda su fecha en UTC', () {
    final local = DateTime(2026, 10, 13, 8, 22, 11, 243);
    final json = AddCreditPaymentDto(
      amount: 140000,
      paymentMethod: 'cash',
      paymentDate: local.toIso8601String(),
    ).toJson();
    final sent = json['paymentDate'] as String;
    expect(sent.endsWith('Z'), isTrue);
    expect(DateTime.parse(sent).isAtSameMomentAs(local), isTrue);
  });
}

void offsetTests() {
  group('withDeviceOffset / withExplicitOffsets', () {
    test('agrega el desfase sin cambiar el reloj ni el instante', () {
      final local = DateTime(2026, 10, 13, 23, 59, 59, 999);
      final wire = withDeviceOffset(local.toIso8601String());
      expect(wire.startsWith('2026-10-13T23:59:59.999'), isTrue, reason: 'el día y la hora del reloj no cambian');
      expect(RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(wire), isTrue);
      expect(DateTime.parse(wire).isAtSameMomentAs(local), isTrue);
    });

    test('recorre cuerpos anidados y solo toca fecha-horas sin zona', () {
      final local = DateTime(2026, 10, 13, 8, 22, 11, 243);
      final body = {
        'amount': 140000,
        'paymentDate': local.toIso8601String(),
        'dueDate': '2026-11-12',
        'already': '2026-10-13T12:22:11.243Z',
        'notes': 'pago del 2026-10-13 08:22',
        'items': [
          {'expiresAt': local.toIso8601String(), 'qty': 2},
        ],
      };
      final out = withExplicitOffsets(body) as Map<String, dynamic>;

      expect(DateTime.parse(out['paymentDate'] as String).isAtSameMomentAs(local), isTrue);
      expect((out['paymentDate'] as String).contains(RegExp(r'[+-]\d{2}:\d{2}$')), isTrue);
      expect(out['dueDate'], '2026-11-12', reason: 'las fechas solas no se tocan');
      expect(out['already'], '2026-10-13T12:22:11.243Z');
      expect(out['notes'], 'pago del 2026-10-13 08:22');
      expect(out['amount'], 140000);
      final item = (out['items'] as List).first as Map<String, dynamic>;
      expect(DateTime.parse(item['expiresAt'] as String).isAtSameMomentAs(local), isTrue);
      // no modifica el original
      expect(body['paymentDate'], local.toIso8601String());
    });

    test('un DateTime suelto sale como instante UTC', () {
      final local = DateTime(2026, 10, 13, 8, 0);
      final out = withExplicitOffsets({'at': local}) as Map<String, dynamic>;
      expect(DateTime.parse(out['at'] as String).isAtSameMomentAs(local), isTrue);
    });
  });
}
