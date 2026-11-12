import 'dart:async';

import 'package:baudex_desktop/features/breb/data/breb_api.dart';
import 'package:baudex_desktop/features/breb/domain/breb_charge.dart';
import 'package:baudex_desktop/features/breb/presentation/controllers/breb_payment_controller.dart';
import 'package:baudex_desktop/features/breb/presentation/widgets/breb_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Servidor simulado: la prueba decide qué responde cada vez.
class _FakeApi implements BrebApi {
  BrebException? failOnCreate;
  bool networkDown = false;
  BrebChargeState serverState = const BrebChargeState(status: BrebChargeStatus.pending);
  Map<String, dynamic>? draftSent;
  double? amountSent;
  String? invoiceSent;
  int statusCalls = 0;
  bool cancelled = false;

  BrebCharge _charge(double amount, double requested) => BrebCharge(
        chargeId: 'c1',
        amount: amount,
        requestedAmount: requested,
        llaves: const [
          BrebLlaveQr(id: 'a', label: 'Nequi tienda', llave: '3000000000', qrPayload: '00020101021153031705406100.006304ABCD'),
          BrebLlaveQr(id: 'b', label: 'Bancolombia', llave: '@tiendademo'),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

  @override
  Future<BrebCharge> createChargeForSale({required Map<String, dynamic> draft, required double amount}) async {
    if (failOnCreate != null) throw failOnCreate!;
    draftSent = draft;
    amountSent = amount;
    return _charge(amount - 1, amount);
  }

  @override
  Future<BrebCharge> createChargeForInvoice(String invoiceId) async {
    invoiceSent = invoiceId;
    return _charge(20000, 20000);
  }

  String? creditSent;
  double? creditAmountSent;

  @override
  Future<BrebCharge> createChargeForCredit(String creditId, {double? amount}) async {
    creditSent = creditId;
    creditAmountSent = amount;
    return _charge(amount ?? 18000, amount ?? 18000);
  }

  @override
  Future<BrebChargeState> status(String chargeId) async {
    statusCalls++;
    if (networkDown) throw const BrebException('sin red', offline: true);
    return serverState;
  }

  @override
  Future<void> cancel(String chargeId) async {
    cancelled = true;
    if (serverState.status == BrebChargeStatus.pending) {
      serverState = const BrebChargeState(status: BrebChargeStatus.cancelled);
    }
  }

  List<BrebReceivedPayment> received = const [];
  BrebException? failOnAssign;
  String? assignedEmail;

  @override
  Future<List<BrebReceivedPayment>> unassigned() async => received;

  @override
  Future<String?> assign({required String chargeId, required String emailId}) async {
    if (failOnAssign != null) throw failOnAssign!;
    assignedEmail = emailId;
    serverState = const BrebChargeState(status: BrebChargeStatus.matched, invoiceId: 'factura-2');
    return 'factura-2';
  }

  @override
  Future<String> inboundAddress() async => 'pagos-bx000000000000@notificaciones.baudity.com';
  @override
  Future<String> previewQr(String template, double amount) async => template;
  @override
  Future<List<Map<String, dynamic>>> recentEmails() async => [];
}

const _paid = BrebChargeState(
  status: BrebChargeStatus.matched,
  invoiceId: 'factura-1',
  payerName: 'LUISA DIAZ',
  bankLabel: 'Nequi',
);

void main() {
  late _FakeApi api;
  late BrebPaymentController controller;
  const tick = Duration(milliseconds: 20);

  setUp(() {
    api = _FakeApi();
    controller = BrebPaymentController(api, pollEvery: tick)..onInit();
  });
  tearDown(() => controller.onClose());

  Future<void> wait([int ticks = 3]) => Future<void>.delayed(tick * ticks);

  group('controlador del cobro', () {
    test('venta nueva: envía el borrador y el valor, y queda esperando', () async {
      await controller.startForSale(draft: {'customerId': 'cf', 'items': []}, amount: 15000);
      expect(api.draftSent, {'customerId': 'cf', 'items': []});
      expect(api.amountSent, 15000);
      expect(controller.phase.value, BrebPaymentPhase.waiting);
      expect(controller.charge.value!.amount, 14999);
    });

    test('cuando el banco avisa, queda confirmado con la factura creada', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.waiting);
      api.serverState = _paid;
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
      expect(controller.invoiceId, 'factura-1');
      final calls = api.statusCalls;
      await wait();
      expect(api.statusCalls, calls, reason: 'ya no sigue preguntando');
    });

    test('si se cae la red mientras espera, no cancela: sigue y confirma cuando vuelve', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      api.networkDown = true;
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.waiting);
      api.networkDown = false;
      api.serverState = _paid;
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
    });

    test('el cobro vence', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      api.serverState = const BrebChargeState(status: BrebChargeStatus.expired);
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.expired);
    });

    test('cancelar: el cobro se cancela en el servidor', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      expect(await controller.cancel(), isTrue);
      expect(api.cancelled, isTrue);
      expect(controller.phase.value, BrebPaymentPhase.cancelled);
    });

    test('cancelar justo cuando entró el pago: NO se cancela, la venta ya existe', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      api.serverState = _paid;
      expect(await controller.cancel(), isFalse);
      expect(api.cancelled, isFalse);
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
      expect(controller.invoiceId, 'factura-1');
    });

    test('si el servidor rechaza el cobro, se muestra su motivo', () async {
      api.failOnCreate = const BrebException('Este negocio no tiene llaves Bre-B configuradas');
      await controller.startForSale(draft: {}, amount: 15000);
      expect(controller.phase.value, BrebPaymentPhase.failed);
      expect(controller.errorMessage.value, contains('llaves'));
    });

    const late = BrebReceivedPayment(id: 'correo-1', amount: 14990, payerName: 'ANA RUIZ', bankLabel: 'Nequi');

    test('asignar a mano un pago recibido: queda confirmado con su factura', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      expect(await controller.assignReceived(late), isNull);
      expect(api.assignedEmail, 'correo-1');
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
      expect(controller.invoiceId, 'factura-2');
      expect(controller.state.value!.payerName, 'ANA RUIZ');
    });

    test('también sirve cuando el cobro ya venció (el aviso llegó tarde)', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      api.serverState = const BrebChargeState(status: BrebChargeStatus.expired);
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.expired);
      expect(await controller.assignReceived(late), isNull);
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
    });

    test('si el servidor no lo permite (el pago no cubre la venta), se muestra el motivo y sigue esperando', () async {
      await controller.startForSale(draft: {}, amount: 15000);
      api.failOnAssign = const BrebException('El pago recibido no cubre la venta');
      expect(await controller.assignReceived(late), contains('no cubre'));
      expect(controller.phase.value, BrebPaymentPhase.waiting);
      expect(controller.invoiceId, isNull);
    });

    test('crédito: abono por un valor y confirmación con el crédito pagado', () async {
      await controller.startForCredit('credito-1', amount: 12000);
      expect(api.creditSent, 'credito-1');
      expect(api.creditAmountSent, 12000);
      api.serverState = const BrebChargeState(status: BrebChargeStatus.matched, creditId: 'credito-1');
      await wait();
      expect(controller.phase.value, BrebPaymentPhase.confirmed);
      expect(controller.settledId, 'credito-1', reason: 'un crédito directo no tiene factura');
    });

    test('crédito: sin valor se cobra todo el saldo', () async {
      await controller.startForCredit('credito-1');
      expect(api.creditAmountSent, isNull);
      expect(controller.charge.value!.amount, 18000);
    });

    test('cartera: cobro de una factura que ya existe', () async {
      await controller.startForInvoice('factura-9');
      expect(api.invoiceSent, 'factura-9');
      expect(controller.charge.value!.adjustment, 0);
    });
  });

  group('diálogo de cobro', () {
    Future<String?> open(WidgetTester tester) async {
      String? result = 'sin cerrar';
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => BrebPaymentDialog.forSale(draft: const {}, amount: 15000, controller: controller),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(tick);
      return result;
    }

    testWidgets('muestra el valor exacto, el QR, la llave y el aviso del ajuste', (tester) async {
      await tester.runAsync(() async {
        await open(tester);
        await wait(1);
        await tester.pump();
        expect(find.byKey(const Key('breb-amount')), findsOneWidget);
        expect(find.textContaining('14.999'), findsWidgets);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.textContaining('3000000000'), findsOneWidget);
        expect(find.textContaining('para identificar este pago'), findsOneWidget);
        expect(find.textContaining('Esperando el pago'), findsOneWidget);

        // La otra llave no tiene QR: se paga escribiéndola.
        await tester.tap(find.text('Bancolombia'));
        await tester.pump();
        expect(find.byType(QrImageView), findsNothing);
        expect(find.textContaining('@tiendademo'), findsOneWidget);
        await controller.cancel();
        await tester.pump();
      });
    });

    testWidgets('pagos recibidos: lista los que llegaron y al tocar uno lo asigna', (tester) async {
      await tester.runAsync(() async {
        api.received = const [
          BrebReceivedPayment(id: 'correo-1', amount: 14990, payerName: 'ANA RUIZ', bankLabel: 'Nequi'),
        ];
        await open(tester);
        await wait(1);
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('breb-received')));
        await tester.tap(find.byKey(const Key('breb-received')));
        await tester.pump();
        await wait(1);
        await tester.pump();
        expect(find.text('Pagos Bre-B recibidos'), findsOneWidget);
        expect(find.textContaining('ANA RUIZ'), findsOneWidget);

        await tester.tap(find.textContaining('ANA RUIZ'));
        await tester.pump();
        await wait(1);
        await tester.pump();
        expect(api.assignedEmail, 'correo-1');
        expect(controller.phase.value, BrebPaymentPhase.confirmed);
        expect(find.text('¡Pago recibido!'), findsOneWidget);
      });
    });

    testWidgets('al llegar el pago muestra quién pagó', (tester) async {
      await tester.runAsync(() async {
        await open(tester);
        api.serverState = _paid;
        await wait();
        await tester.pump();
        expect(find.text('¡Pago recibido!'), findsOneWidget);
        expect(find.textContaining('LUISA DIAZ'), findsOneWidget);
      });
    });
  });
}
