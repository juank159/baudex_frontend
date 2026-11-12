// Genera imágenes (PNG) de la pantalla de caja y del detalle de un cierre,
// con fuentes reales, para revisarlas a ojo sin abrir la app.
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/cash_register_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/cash_register/domain/entities/cash_register.dart';
import 'package:baudex_desktop/features/cash_register/domain/repositories/cash_register_repository.dart';
import 'package:baudex_desktop/features/cash_register/presentation/controllers/cash_register_controller.dart';
import 'package:baudex_desktop/features/cash_register/presentation/screens/cash_register_history_screen.dart';
import 'package:baudex_desktop/features/cash_register/presentation/screens/cash_register_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

const _summary = CashRegisterSummary(
  cashSales: 150000,
  cashSalesCount: 7,
  cashExpenses: 20000,
  cashExpensesCount: 1,
  cashFromSales: 120000,
  cashFromSalesCount: 5,
  cashFromCreditPayments: 30000,
  cashFromCreditPaymentsCount: 2,
  otherMethods: [
    OtherMethodTotal(method: 'breb', label: 'Bre-B · Nequi tienda', total: 39999, count: 2),
    OtherMethodTotal(method: 'bank_transfer', label: 'Bancolombia', total: 50000, count: 1),
  ],
  otherMethodsTotal: 89999,
  otherMethodsCount: 3,
  totalCollected: 239999,
  creditSalesTotal: 45000,
  creditSalesCount: 1,
  brebTotal: 39999,
  brebCount: 2,
  brebAdjustmentsTotal: 1,
  brebAdjustmentsCount: 1,
);

CashRegister _register({bool closed = false}) => CashRegister(
      id: 'c1',
      status: closed ? CashRegisterStatus.closed : CashRegisterStatus.open,
      openingAmount: 100000,
      closingExpectedAmount: closed ? 230000 : null,
      closingActualAmount: closed ? 225000 : null,
      closingDifference: closed ? -5000 : null,
      closingSummary: closed ? _summary : null,
      openedAt: DateTime.now().subtract(const Duration(hours: 6)),
      openedById: 'u1',
      openedByName: 'María Peña',
      closedAt: closed ? DateTime.now() : null,
      closedByName: closed ? 'María Peña' : null,
      organizationId: 'o1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

class _Repo implements CashRegisterRepository {
  bool isOpen;
  _Repo({this.isOpen = true});

  @override
  Future<Either<Failure, CashRegisterCurrentState>> getCurrent() async => Right(isOpen
      ? CashRegisterCurrentState(cashRegister: _register(), summary: _summary, expectedAmount: 230000)
      : const CashRegisterCurrentState());

  @override
  Future<Either<Failure, List<CashRegister>>> list({CashRegisterStatus? status, int limit = 30, int offset = 0}) async =>
      Right([_register(closed: true)]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  if (_out == null) {
    test('imágenes de la caja (omitida: falta BAUDEX_VISUAL_OUT)', () {}, skip: 'Solo para revisión visual');
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
    ErrorWidget.builder = (_) => const SizedBox.shrink();
  });

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

  // El indicador de sincronización de la barra superior necesita el servicio
  // de sincronización real, que aquí no existe: se deja vacío y se descarta
  // ese único error. Lo que se revisa es el cuerpo de la pantalla.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      while (true) {
        final error = tester.takeException();
        if (error == null) break;
        if (!error.toString().contains('SyncService')) throw error as Object;
      }
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Cierra el controlador para que cancele su temporizador de refresco.
    await Get.delete<CashRegisterController>(force: true);
    Get.reset();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('caja abierta con Bre-B y botón de imprimir', (tester) async {
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(CashRegisterController(repository: _Repo()));
    await tester.pumpWidget(app(const CashRegisterScreen()));
    await settle(tester);
    expect(find.text('Bre-B · Nequi tienda'), findsOneWidget);
    expect(find.text('Imprimir arqueo'), findsOneWidget);
    await shot(tester, 'caja-1-abierta');

    // Caja recién cerrada: ofrece imprimir el recibo del cierre.
    controller.lastClosed.value = _register(closed: true);
    controller.currentState.value = const CashRegisterCurrentState();
    await settle(tester);
    expect(find.text('Imprimir recibo del último cierre'), findsOneWidget);
    await shot(tester, 'caja-2-cerrada');
    await close(tester);
  });

  testWidgets('historial: detalle del cierre con desglose y botón de imprimir', (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(CashRegisterController(repository: _Repo(isOpen: false)));
    await controller.loadHistory();
    await tester.pumpWidget(app(const CashRegisterHistoryScreen()));
    await settle(tester);
    await shot(tester, 'caja-3-historial');
    await tester.tap(find.textContaining('SALDO INICIAL'));
    await settle(tester);
    await tester.drag(find.byType(DraggableScrollableSheet), const Offset(0, -500));
    await settle(tester);
    await shot(tester, 'caja-4-detalle-cierre');
    await close(tester);
  });
}
