import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCreditPaymentDto idempotencyKey', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('cada abono nuevo recibe una clave UUID v4 distinta', () {
      final keys = List.generate(
        500,
        (_) => AddCreditPaymentDto(amount: 1000, paymentMethod: 'cash')
            .idempotencyKey,
      );
      expect(keys.every(uuidV4.hasMatch), isTrue);
      expect(keys.toSet().length, 500);
    });

    test('la clave de un abono no cambia entre lecturas (reintentos)', () {
      final dto = AddCreditPaymentDto(amount: 1000, paymentMethod: 'cash');
      expect(dto.idempotencyKey, dto.idempotencyKey);
      expect(dto.idempotencyKey.length, lessThanOrEqualTo(64));
    });

    test('respeta la clave guardada en la cola offline', () {
      final dto = AddCreditPaymentDto(
        amount: 1000,
        paymentMethod: 'cash',
        idempotencyKey: 'payment_1700000000000_123',
      );
      expect(dto.idempotencyKey, 'payment_1700000000000_123');
    });

    test('la clave no viaja en el body (va en el header Idempotency-Key)', () {
      final json = AddCreditPaymentDto(
        amount: 1000,
        paymentMethod: 'cash',
        paymentDate: '2026-10-13T12:00:00.000',
      ).toJson();
      expect(json.containsKey('idempotencyKey'), isFalse);
      expect(json.keys.toSet(), {'amount', 'paymentMethod', 'paymentDate'});
    });
  });
}
