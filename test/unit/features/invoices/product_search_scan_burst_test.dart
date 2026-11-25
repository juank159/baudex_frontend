// Buscador de la factura: ráfaga del lector vs. tecleo a mano.
//
// - En ráfaga (teclas en milésimas) los primeros dígitos de un código NO se
//   pintan como "valor" tecla a tecla.
// - A ritmo humano, el valor se pinta en la MISMA tecla, como siempre.
import 'dart:async';

import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/product_fixtures.dart';

class MockInvoiceFormController extends Mock implements InvoiceFormController {}

void main() {
  late MockInvoiceFormController controller;
  late List<String> added;
  var mayExistOnServer = false;
  var serverLookups = 0;
  Completer<Product?>? serverAnswer;

  final arroz = ProductFixtures.createProductEntity(
      id: 'arroz', name: 'Arroz Diana', sku: 'ARR-1', barcode: '7701111111111');
  final leche = ProductFixtures.createProductEntity(
      id: 'leche', name: 'Leche Alpina', sku: 'LEC-1', barcode: '7702222222222');
  // Código de barras guardado como SKU.
  final panela = ProductFixtures.createProductEntity(
      id: 'panela', name: 'Panela', sku: '7703333333333', barcode: null);
  final index = ShortCodeIndex.build(const [], complete: true);

  setUp(() {
    mayExistOnServer = false;
    serverLookups = 0;
    serverAnswer = null;
    InvoiceEntryMetrics.instance.reset();
    Get.testMode = true;
    controller = MockInvoiceFormController();
    added = [];
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.searchProducts(any())).thenAnswer((_) async => []);
    when(() => controller.scanMayExistOnServer())
        .thenAnswer((_) async => mayExistOnServer);
    when(() => controller.findProductByBarcode(any(),
        localOnly: any(named: 'localOnly'))).thenAnswer((inv) {
      final code = inv.positionalArguments.first as String;
      final local = [arroz, leche, panela]
          .firstWhereOrNull((p) => p.barcode == code || p.sku == code);
      if (inv.namedArguments[#localOnly] == true) return Future.value(local);
      // Búsqueda completa: puede esperar al servidor.
      serverLookups++;
      return (serverAnswer = Completer<Product?>()).future;
    });
  });

  tearDown(() {
    ProductSearchWidgetState.debugKeyClock = null;
    Get.reset();
  });

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    // Reloj de las teclas = el tiempo simulado de la prueba.
    final start = tester.binding.clock.now();
    ProductSearchWidgetState.debugKeyClock =
        () => tester.binding.clock.now().difference(start);
    await tester.pumpWidget(GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            const Text('Vecino de la caja', key: Key('vecino')),
            ProductSearchWidget(
              controller: controller,
              onProductSelected: (p, qty) => added.add('${p.id}x$qty'),
            ),
            const Text('Tabla de la factura', key: Key('tabla')),
          ],
        ),
      ),
    ));
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();
  }

  /// Una tecla: el texto crece un carácter. Dibuja el cuadro de la tecla sin
  /// dejar pasar tiempo y devuelve cuántas veces se redibujó el buscador.
  Future<int> key(WidgetTester tester, String textSoFar) async {
    var rebuilds = 0;
    debugOnRebuildDirtyWidget = (e, _) {
      if (e.widget is ProductSearchWidget) rebuilds++;
    };
    try {
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: textSoFar,
        selection: TextSelection.collapsed(offset: textSoFar.length),
      ));
      await tester.pump();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    return rebuilds;
  }

  /// Teclea [text] con [gapMs] entre teclas; devuelve los redibujados del
  /// buscador en el cuadro de cada tecla.
  Future<List<int>> type(WidgetTester tester, String text, int gapMs) async {
    final rebuilds = <int>[];
    for (var i = 1; i <= text.length; i++) {
      if (i > 1) await tester.pump(Duration(milliseconds: gapMs));
      rebuilds.add(await key(tester, text.substring(0, i)));
    }
    return rebuilds;
  }

  Future<void> enter(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  bool fieldHasFocus(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).focusNode!.hasFocus;

  testWidgets('a mano (120 ms entre teclas): el valor se pinta en la MISMA tecla',
      (tester) async {
    await open(tester);
    const shown = ['\$ 2', '\$ 25', '\$ 250', '\$ 2.500'];
    for (var i = 1; i <= 4; i++) {
      if (i > 1) await tester.pump(const Duration(milliseconds: 120));
      final rebuilds = await key(tester, '2500'.substring(0, i));
      expect(rebuilds, greaterThan(0), reason: 'tecla $i redibuja');
      expect(find.text('Producto sin registrar'), findsOneWidget);
      expect(find.text('Valor: ${shown[i - 1]}'), findsOneWidget,
          reason: 'tecla $i, sin esperar');
    }
    expect(InvoiceEntryMetrics.instance.scanKeysNotRedrawn, 0);
    // Enter: el diálogo del nombre, como siempre.
    await enter(tester);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(added, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a mano muy rápido (60 ms): también en la misma tecla',
      (tester) async {
    await open(tester);
    await type(tester, '350', 60);
    expect(find.text('Valor: \$ 350'), findsOneWidget);
    expect(InvoiceEntryMetrics.instance.scanKeysNotRedrawn, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lector (8 ms entre teclas): desde la 2.ª tecla el buscador NO '
      'se redibuja ni pinta valores; Enter agrega el producto', (tester) async {
    await open(tester);
    final rebuilds = await type(tester, arroz.barcode!, 8);
    expect(rebuilds.first, greaterThan(0),
        reason: 'la primera tecla no se puede distinguir de una a mano');
    expect(rebuilds.skip(1), everyElement(0),
        reason: 'teclas 2 a 13: ningún redibujado del buscador');
    expect(find.text('Valor: \$ 77'), findsNothing);
    expect(find.text('Valor: \$ 7.701.111'), findsNothing);
    expect(InvoiceEntryMetrics.instance.scanKeysNotRedrawn, 6,
        reason: 'teclas 2 a 7 (las que antes pintaban el valor)');

    await enter(tester);
    await tester.pump();
    expect(added, ['arrozx1.0']);
    expect(fieldText(tester), isEmpty);
    expect(find.text('Producto sin registrar'), findsNothing);
    final m = InvoiceEntryMetrics.instance;
    expect(m.scans, 1);
    expect(m.scansAsBurst, 1);
    expect(m.scanGapMs!.$1, closeTo(8, 0.01));
    await tester.pump(const Duration(seconds: 1));
    expect(added, ['arrozx1.0'], reason: 'no se agrega dos veces');
  });

  testWidgets('ráfaga que se corta sin Enter (valor tecleado rapidísimo): se '
      'pinta a los 60 ms y Enter abre el diálogo', (tester) async {
    await open(tester);
    await type(tester, '2500', 8);
    expect(find.text('Valor: \$ 2.500'), findsNothing);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Valor: \$ 2.500'), findsNothing, reason: 'aún en espera');
    await tester.pump(const Duration(milliseconds: 25));
    expect(find.text('Valor: \$ 2.500'), findsOneWidget);
    await enter(tester);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('valor tecleado rapidísimo + Enter enseguida: no espera la pintura',
      (tester) async {
    await open(tester);
    await type(tester, '2500', 8);
    await enter(tester);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(find.text('Valor: \$ 2.500'), findsOneWidget, reason: 'en el diálogo');
    expect(added, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('después de una lectura, teclear un valor a mano vuelve a pintar '
      'en la misma tecla', (tester) async {
    await open(tester);
    await type(tester, arroz.barcode!, 8);
    await enter(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(added, ['arrozx1.0']);
    expect(await key(tester, '9'), greaterThan(0));
    expect(find.text('Valor: \$ 9'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 110));
    await key(tester, '90');
    expect(find.text('Valor: \$ 90'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  /// Teclea y devuelve si el resto de la pantalla (los vecinos de la caja)
  /// se repintó en el cuadro de alguna tecla.
  Future<bool> neighboursRepainted(
      WidgetTester tester, String text, int gapMs) async {
    final neighbours = {
      tester.renderObject(find.byKey(const Key('vecino'))),
      tester.renderObject(find.byKey(const Key('tabla'))),
    };
    var repainted = false;
    debugOnProfilePaint = (o) {
      if (neighbours.contains(o)) repainted = true;
    };
    try {
      await type(tester, text, gapMs);
    } finally {
      debugOnProfilePaint = null;
    }
    return repainted;
  }

  testWidgets('cada tecla repinta SOLO la caja, no el resto de la pantalla '
      '(lector y texto a mano)', (tester) async {
    await open(tester);
    expect(tester.getSize(find.byType(TextField).first).height, 48,
        reason: 'el mismo alto de siempre');
    expect(await neighboursRepainted(tester, 'arr', 120), isFalse,
        reason: 'texto a mano');
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(seconds: 1));
    // Lector: la 1.ª tecla sí pinta la opción (y mueve lo de abajo); de la
    // 2.ª en adelante, nada fuera de la caja.
    await key(tester, '7');
    expect(await neighboursRepainted(tester, '7701111111111'.substring(1), 8),
        isFalse, reason: 'ráfaga del lector');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('con letra agrandada la caja crece como antes (sin alto fijo)',
      (tester) async {
    await open(tester, textScale: 2);
    expect(tester.getSize(find.byType(TextField).first).height,
        greaterThan(48));
    await type(tester, '25', 120);
    expect(find.text('Valor: \$ 25'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Enter no suelta el foco de la caja', (tester) async {
    await open(tester);
    expect(fieldHasFocus(tester), isTrue);
    await type(tester, arroz.barcode!, 8);
    await enter(tester);
    expect(fieldHasFocus(tester), isTrue,
        reason: 'ni un instante sin foco: el siguiente código entra completo');
    await tester.pump();
    expect(fieldHasFocus(tester), isTrue);
    expect(added, ['arrozx1.0']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('código guardado como SKU: el lector lo encuentra', (tester) async {
    await open(tester);
    await type(tester, panela.sku, 8);
    await enter(tester);
    await tester.pump();
    expect(added, ['panelax1.0']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('código que no existe (catálogo completo): avisa sin ir al servidor',
      (tester) async {
    await open(tester);
    await type(tester, '7709999999999', 8);
    await enter(tester);
    await tester.pump();
    await tester.pump();
    expect(added, isEmpty);
    expect(serverLookups, 0);
    expect(fieldText(tester), '7709999999999',
        reason: 'queda escrito y seleccionado para corregirlo');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('catálogo bajando: una lectura que no está en el equipo NO frena '
      'las siguientes; si el servidor la tiene, entra al llegar', (tester) async {
    mayExistOnServer = true;
    await open(tester);
    // 1.ª lectura: no está en el equipo → se pregunta al servidor (lento).
    await type(tester, '7705555555555', 8);
    await enter(tester);
    await tester.pump(const Duration(milliseconds: 20));
    expect(serverLookups, 1);
    expect(added, isEmpty);
    // 2.ª y 3.ª lecturas mientras el servidor no responde: entran ya.
    await type(tester, arroz.barcode!, 8);
    await enter(tester);
    await tester.pump(const Duration(milliseconds: 20));
    await type(tester, leche.barcode!, 8);
    await enter(tester);
    await tester.pump(const Duration(milliseconds: 20));
    expect(added, ['arrozx1.0', 'lechex1.0'],
        reason: 'no esperan a la primera');
    // Llega el servidor con el producto.
    final remoto = ProductFixtures.createProductEntity(
        id: 'remoto', name: 'Del servidor', sku: 'R-1', barcode: '7705555555555');
    serverAnswer!.complete(remoto);
    await tester.pump();
    await tester.pump();
    expect(added, ['arrozx1.0', 'lechex1.0', 'remotox1.0']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('catálogo bajando y el servidor tampoco lo tiene: avisa al llegar '
      'la respuesta, sin tapar lo que se esté escribiendo', (tester) async {
    mayExistOnServer = true;
    await open(tester);
    await type(tester, '7705555555555', 8);
    await enter(tester);
    await tester.pump(const Duration(milliseconds: 20));
    expect(fieldText(tester), isEmpty, reason: 'caja libre para el siguiente');
    serverAnswer!.complete(null);
    await tester.pump();
    await tester.pump();
    expect(added, isEmpty);
    expect(fieldText(tester), '7705555555555');
    await tester.pump(const Duration(seconds: 1));
  });
}
