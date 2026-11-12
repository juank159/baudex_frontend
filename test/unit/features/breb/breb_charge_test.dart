import 'package:baudex_desktop/features/breb/domain/breb_charge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lo que responde el servidor', () {
    test('un cobro con sus llaves y el QR de cada una', () {
      final charge = BrebCharge.fromJson({
        'chargeId': 'c1',
        'amount': 14999,
        'requestedAmount': 15000,
        'expiresAt': '2026-11-12T15:10:00.000Z',
        'llaves': [
          {'id': 'a', 'label': 'Nequi tienda', 'llave': '3000000000', 'qrPayload': '0002010102...6304ABCD'},
          {'id': 'b', 'label': 'Bancolombia', 'llave': '@tienda', 'qrPayload': null},
          {'id': 'c', 'label': 'vacía', 'llave': ''},
        ],
      });
      expect(charge.amount, 14999);
      expect(charge.adjustment, 1);
      expect(charge.llaves.map((l) => l.id), ['a', 'b']);
      expect(charge.llaves.first.qrPayload, isNotNull);
      expect(charge.llaves.last.qrPayload, isNull);
    });

    test('sin ajuste cuando se cobra el valor completo', () {
      final charge = BrebCharge.fromJson({'chargeId': 'c1', 'amount': 15000, 'llaves': []});
      expect(charge.requestedAmount, 15000);
      expect(charge.adjustment, 0);
    });

    test('estados: "matching" (registrando el pago) sigue siendo esperar', () {
      expect(parseBrebStatus('pending'), BrebChargeStatus.pending);
      expect(parseBrebStatus('matching'), BrebChargeStatus.pending);
      expect(parseBrebStatus('matched'), BrebChargeStatus.matched);
      expect(parseBrebStatus('expired'), BrebChargeStatus.expired);
      expect(parseBrebStatus('cancelled'), BrebChargeStatus.cancelled);
      expect(parseBrebStatus(null), BrebChargeStatus.pending);
    });

    test('cuando el pago se confirma viene la factura creada', () {
      final state = BrebChargeState.fromJson({
        'status': 'matched',
        'invoiceId': 'f1',
        'payerName': 'LUISA DIAZ',
        'bankLabel': 'Nequi',
      });
      expect(state.status, BrebChargeStatus.matched);
      expect(state.invoiceId, 'f1');
      expect(state.payerName, 'LUISA DIAZ');
    });
  });

  group('tiempo que le queda al cobro', () {
    final now = DateTime(2026, 11, 12, 10, 0, 0);
    test('minutos y segundos', () {
      expect(brebRemainingLabel(now.add(const Duration(minutes: 9, seconds: 5)), now), '9:05');
      expect(brebRemainingLabel(now.add(const Duration(seconds: 59)), now), '0:59');
    });
    test('vencido', () {
      expect(brebRemainingLabel(now.subtract(const Duration(seconds: 1)), now), '0:00');
    });
  });

  group('llaves del negocio en su configuración', () {
    test('con llaves, el punto de venta puede cobrar por Bre-B', () {
      final settings = {
        'breb': {
          'llaves': [
            {'id': 'a', 'label': 'Nequi', 'llave': '3000000000'},
            {'id': 'b', 'label': 'vacía', 'llave': ' '},
          ],
        },
      };
      expect(brebLlavesOf(settings).length, 1);
      expect(brebEnabled(settings), isTrue);
    });
    test('sin llaves, no', () {
      expect(brebEnabled(null), isFalse);
      expect(brebEnabled({}), isFalse);
      expect(brebEnabled({'breb': {'llaves': []}}), isFalse);
      expect(brebEnabled({'breb': 'x'}), isFalse);
    });
  });

  group('productos no registrados', () {
    test('los identificadores temporales de la app se reconocen', () {
      expect(isTemporaryProductId('temp_1731430000000'), isTrue);
      expect(isTemporaryProductId('temp_price_1731430000000'), isTrue);
      expect(isTemporaryProductId('unregistered_123'), isTrue);
    });
    test('un producto registrado o creado sin conexión no es temporal', () {
      expect(isTemporaryProductId('3f2b8c1e-0f2a-4d6b-9c1d-2e5f7a8b9c0d'), isFalse);
      expect(isTemporaryProductId('product_offline_1731430000000'), isFalse);
      expect(isTemporaryProductId(null), isFalse);
    });
  });
}
