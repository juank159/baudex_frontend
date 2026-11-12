import 'package:baudex_desktop/features/breb/data/breb_api.dart';
import 'package:baudex_desktop/features/breb/domain/breb_charge.dart';
import 'package:baudex_desktop/features/breb/presentation/controllers/breb_payment_controller.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_payment.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements BrebApi {
  BrebChargeState serverState = const BrebChargeState(status: BrebChargeStatus.pending);

  @override
  Future<BrebCharge> createChargeForSale({required Map<String, dynamic> draft, required double amount}) async => BrebCharge(
        chargeId: 'c1',
        amount: amount - 1,
        requestedAmount: amount,
        llaves: const [BrebLlaveQr(id: 'a', label: 'Nequi', llave: '3000000000')],
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

  @override
  Future<BrebChargeState> status(String chargeId) async => serverState;

  @override
  Future<void> cancel(String chargeId) async {}

  @override
  Future<String?> assign({required String chargeId, required String emailId}) async => 'inv-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InvoicePayment _payment({PaymentMethod method = PaymentMethod.bankTransfer, String? channel}) {
  final date = DateTime(2026, 11, 12);
  return InvoicePayment(
    id: 'p',
    amount: 2000,
    paymentMethod: method,
    paymentDate: date,
    invoiceId: 'i',
    createdById: 'u',
    organizationId: 'o',
    createdAt: date,
    updatedAt: date,
    channel: channel,
  );
}

void main() {
  group('frase al recibir un pago Bre-B', () {
    test('dice el valor y el banco', () {
      expect(brebPaidAnnouncement(amount: 2000, bank: 'Nequi'), 'Recibiste 2000 pesos en Nequi');
      expect(brebPaidAnnouncement(amount: 14999.0, bank: ' Bancolombia '), 'Recibiste 14999 pesos en Bancolombia');
    });

    test('sin banco o sin valor no se queda callada', () {
      expect(brebPaidAnnouncement(amount: 2000), 'Pago recibido, 2000 pesos');
      expect(brebPaidAnnouncement(bank: 'Nequi'), 'Pago recibido en Nequi');
      expect(brebPaidAnnouncement(), 'Pago recibido');
    });
  });

  group('voz al confirmarse el cobro', () {
    late _Api api;
    late List<String> spoken;
    late BrebPaymentController controller;

    setUp(() {
      api = _Api();
      spoken = [];
      controller = BrebPaymentController(api, pollEvery: const Duration(hours: 1), speak: spoken.add)..onInit();
    });
    tearDown(() => controller.onClose());

    test('habla una sola vez cuando el banco confirma, con el valor cobrado y el banco', () async {
      await controller.startForSale(draft: const {}, amount: 2000);
      expect(spoken, isEmpty, reason: 'mientras espera no dice nada');

      api.serverState = const BrebChargeState(status: BrebChargeStatus.matched, invoiceId: 'inv-1', bankLabel: 'Nequi');
      await controller.checkNow();
      await controller.checkNow();
      await Future<void>.delayed(Duration.zero);

      expect(controller.phase.value, BrebPaymentPhase.confirmed);
      expect(spoken, ['Recibiste 1999 pesos en Nequi']);
    });

    test('también habla si el pago entra justo al cancelar', () async {
      await controller.startForSale(draft: const {}, amount: 5000);
      api.serverState = const BrebChargeState(status: BrebChargeStatus.matched, invoiceId: 'inv-1', bankLabel: 'Bancolombia');
      final cancelled = await controller.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(cancelled, isFalse);
      expect(spoken, ['Recibiste 4999 pesos en Bancolombia']);
    });

    test('y si el cajero asigna a mano un pago recibido', () async {
      await controller.startForSale(draft: const {}, amount: 3000);
      final problem = await controller.assignReceived(
        BrebReceivedPayment.fromJson(const {'id': 'e1', 'amount': 3000, 'bankLabel': 'Daviplata'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(problem, isNull);
      expect(spoken, ['Recibiste 2999 pesos en Daviplata']);
    });

    test('no habla si el cobro vence o se cancela sin pago', () async {
      await controller.startForSale(draft: const {}, amount: 2000);
      api.serverState = const BrebChargeState(status: BrebChargeStatus.expired);
      await controller.checkNow();
      await Future<void>.delayed(Duration.zero);
      expect(spoken, isEmpty);
    });
  });

  group('el medio de pago se llama Bre-B en todo lado', () {
    test('un pago con canal Bre-B no sale como "Transferencia"', () {
      final payment = _payment(channel: 'breb');
      expect(payment.isBreb, isTrue);
      expect(payment.paymentMethodDisplayName, 'Bre-B');
      expect(payment.displayName, 'Bre-B');
      expect(payment.shortDisplayName, 'Bre-B');
    });

    test('el ajuste de redondeo se llama "Ajuste Bre-B", no "Otro"', () {
      final payment = _payment(method: PaymentMethod.other, channel: 'breb_adjustment');
      expect(payment.paymentMethodDisplayName, 'Ajuste Bre-B');
      expect(payment.shortDisplayName, 'Ajuste Bre-B');
    });

    test('una transferencia normal sigue igual', () {
      final payment = _payment();
      expect(payment.isBreb, isFalse);
      expect(payment.paymentMethodDisplayName, 'Transferencia Bancaria');
      expect(payment.shortDisplayName, 'Transferencia');
    });
  });
}
