// Genera imágenes (PNG) de las pantallas y diálogos de Bre-B con fuentes
// reales, para revisarlas a ojo sin abrir la app. No corre con `flutter test`
// normal: solo si se indica dónde guardar.
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/breb_screens_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/breb/data/breb_api.dart';
import 'package:baudex_desktop/features/breb/domain/breb_charge.dart';
import 'package:baudex_desktop/features/breb/presentation/controllers/breb_payment_controller.dart';
import 'package:baudex_desktop/features/breb/presentation/screens/breb_settings_screen.dart';
import 'package:baudex_desktop/features/breb/presentation/widgets/breb_payment_dialog.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:baudex_desktop/features/settings/domain/repositories/organization_repository.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

// QR de prueba (inventado, estructura real).
const _qr =
    '00020101021126330014CO.COM.RBM.LLA0111@300000000049250014CO.COM.RBM.RED0103RBM50310013CO.COM.RBM.CU'
    '0110000000000051250013CO.COM.RBM.CA01040000520400005303170540814999.005802CO5918Tienda Demo Baudex'
    '60050000080270016CO.COM.RBM.CANAL0103APP90430016CO.COM.RBM.TRXID01190000000PRUEBA0000006304EC48';

class _Repo implements OrganizationRepository {
  Organization current;
  _Repo(this.current);
  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async => Right(current);
  @override
  Future<Either<Failure, Organization>> updateCurrentOrganization(Map<String, dynamic> updates) async => Right(current);
  @override
  Future<Either<Failure, Organization>> getOrganizationById(String id) async => Right(current);
  @override
  Future<Either<Failure, bool>> updateProfitMargin(double marginPercentage) async => const Right(true);
}

class _Api implements BrebApi {
  BrebChargeState state = const BrebChargeState(status: BrebChargeStatus.pending);

  @override
  Future<String> inboundAddress() async => 'pagos-bx35dd2626f2fe@notificaciones.baudity.com';

  @override
  Future<List<Map<String, dynamic>>> recentEmails() async => [
        {
          'id': '1',
          'reason': 'not_approved',
          'receivedAt': '2026-11-12T16:20:00.000Z',
          'body': 'Gmail: confirmación de reenvío\n\nsu-correo@gmail.com ha solicitado reenviar automáticamente '
              'correo a tu dirección pagos-bx35dd2626f2fe@notificaciones.baudity.com.\n\nCódigo de confirmación: 123456789\n\n'
              'Para permitir el reenvío, haz clic en el enlace o escribe el código en Gmail.',
        },
        {
          'id': '2',
          'reason': 'no_pending_match',
          'amount': 9500,
          'bankLabel': 'Nequi',
          'payerName': 'ANA RUIZ',
          'receivedAt': '2026-11-12T15:02:00.000Z',
          'body': 'Venta exitosa Monto: \$9.500 Estado: Aprobada',
        },
        {
          'id': '3',
          'reason': 'not_a_sale',
          'bankLabel': 'Bancolombia',
          'resolved': true,
          'receivedAt': '2026-11-11T21:40:00.000Z',
        },
      ];

  @override
  Future<String> previewQr(String template, double amount) async => _qr;

  @override
  Future<BrebCharge> createChargeForSale({required Map<String, dynamic> draft, required double amount}) async => BrebCharge(
        chargeId: 'c1',
        amount: amount - 1,
        requestedAmount: amount,
        llaves: const [
          BrebLlaveQr(id: 'a', label: 'Nequi tienda', llave: '3000000000', qrPayload: _qr),
          BrebLlaveQr(id: 'b', label: 'Bancolombia', llave: '@tiendademo'),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 9, seconds: 41)),
      );

  @override
  Future<BrebCharge> createChargeForInvoice(String invoiceId) => createChargeForSale(draft: const {}, amount: 20000);
  @override
  Future<BrebChargeState> status(String chargeId) async => state;
  @override
  Future<void> cancel(String chargeId) async {}
  @override
  Future<List<BrebReceivedPayment>> unassigned() async => [
        BrebReceivedPayment(id: 'e1', amount: 14990, payerName: 'ANA RUIZ', bankLabel: 'Nequi', receivedAt: DateTime(2026, 11, 12, 10, 2)),
        BrebReceivedPayment(id: 'e2', amount: 52000, payerName: 'CARLOS PEREZ', bankLabel: 'Bancolombia', receivedAt: DateTime(2026, 11, 12, 9, 40)),
      ];
  @override
  Future<String?> assign({required String chargeId, required String emailId}) async => 'f1';
}

Organization _org() => Organization(
      id: 'org-1',
      name: 'Tienda Demo',
      slug: 'tienda-demo',
      settings: const {
        'breb': {
          'llaves': [
            {'id': 'a', 'label': 'Nequi de la tienda', 'llave': '3000000000', 'qrTemplate': _qr},
            {'id': 'b', 'label': 'Bancolombia negocio', 'llave': '@tiendademo'},
          ],
        },
      },
      subscriptionPlan: SubscriptionPlan.basic,
      subscriptionStatus: SubscriptionStatus.active,
      isActive: true,
      currency: 'COP',
      locale: 'es',
      timezone: 'America/Bogota',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  if (_out == null) {
    test('imágenes de Bre-B (omitida: falta BAUDEX_VISUAL_OUT)', () {}, skip: 'Solo para revisión visual');
    return;
  }

  final boundaryKey = GlobalKey();

  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  setUp(() {
    Get.testMode = true;
    final controller = Get.put(OrganizationController(_Repo(_org())));
    controller.applyOrganization(_org(), notifyRateChange: false);
  });
  tearDown(Get.reset);

  Widget app(Widget home) => RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: home,
        ),
      );

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> size(WidgetTester tester, double w, double h) async {
    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('configuración: escritorio, celular, correo y llave', (tester) async {
    await size(tester, 1180, 1000);
    await tester.pumpWidget(app(BrebSettingsScreen(api: _Api())));
    await settle(tester);
    await shot(tester, '1-config-escritorio');

    await tester.tap(find.text('Correo que no es de un banco reconocido'));
    await settle(tester);
    await shot(tester, '2-correo-recibido');
    await tester.tap(find.text('Cerrar'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('breb-add-llave')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('breb-llave-label')), 'Nequi de la tienda');
    await tester.enterText(find.byKey(const Key('breb-llave-value')), '3000000000');
    await tester.enterText(find.byKey(const Key('breb-llave-template')), _qr);
    await tester.tap(find.textContaining('Probar QR'));
    await settle(tester);
    await shot(tester, '3-agregar-llave');
    await tester.tap(find.text('Cancelar'));
    await settle(tester);

    await size(tester, 400, 860);
    await tester.pumpWidget(app(BrebSettingsScreen(key: UniqueKey(), api: _Api())));
    await settle(tester);
    await shot(tester, '4-config-celular');

    // Cierra el controlador (su temporizador) antes de terminar.
    await tester.pumpWidget(const SizedBox());
    Get.reset();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('cobro: esperando, pagos recibidos, confirmado y vencido', (tester) async {
    await size(tester, 900, 900);
    final api = _Api();
    final controller = BrebPaymentController(api, pollEvery: const Duration(hours: 1))..onInit();

    await tester.pumpWidget(app(Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (_) => BrebPaymentDialog.forSale(draft: const {}, amount: 15000, controller: controller),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('abrir'));
    await settle(tester);
    await shot(tester, '5-cobro-esperando');

    await tester.tap(find.byKey(const Key('breb-received')));
    await settle(tester);
    await shot(tester, '6-pagos-recibidos');
    await tester.tap(find.text('Cerrar'));
    await settle(tester);

    controller.phase.value = BrebPaymentPhase.expired;
    await settle(tester);
    await shot(tester, '7-cobro-vencido');

    controller.state.value = const BrebChargeState(
      status: BrebChargeStatus.matched,
      invoiceId: 'f1',
      payerName: 'LUISA DIAZ',
      bankLabel: 'Nequi',
    );
    controller.phase.value = BrebPaymentPhase.confirmed;
    await tester.pump(const Duration(milliseconds: 200));
    await shot(tester, '8-cobro-confirmado');

    await tester.pump(const Duration(seconds: 3));
    controller.onClose();
    await tester.pumpWidget(const SizedBox());
    Get.reset();
    await tester.pump(const Duration(seconds: 1));
  });
}
