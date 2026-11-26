// Buscador de la factura: lectura DIRECTA del lector por teclas.
//
// Como en Windows: cada tecla llega primero a la app; SOLO si la app no la
// consume, el sistema escribe el carácter en la caja.
//
// Criterios del CEO:
//  - en una lectura, la tarjeta "Producto sin registrar" no se pinta ni una
//    vez y el código nunca se ve a medias;
//  - a mano, todo igual (el valor pinta su tarjeta junto con el dígito).

import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/product_fixtures.dart';

class MockInvoiceFormController extends Mock implements InvoiceFormController {}

void main() {
  late MockInvoiceFormController controller;
  late List<String> added;

  final arroz = ProductFixtures.createProductEntity(
      id: 'arroz', name: 'Arroz Diana', sku: 'ARR-1', barcode: '7701111111111');
  final leche = ProductFixtures.createProductEntity(
      id: 'leche', name: 'Leche Alpina', sku: 'LEC-1', barcode: '7702222222222');
  final index = ShortCodeIndex.build(const [], complete: true);

  setUp(() {
    InvoiceEntryMetrics.instance.reset();
    Get.testMode = true;
    controller = MockInvoiceFormController();
    added = [];
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.searchProducts(any())).thenAnswer((_) async => []);
    when(() => controller.scanMayExistOnServer()).thenAnswer((_) async => false);
    when(() => controller.findProductByBarcode(any(),
            localOnly: any(named: 'localOnly')))
        .thenAnswer((inv) async => [arroz, leche].firstWhereOrNull(
            (p) => p.barcode == inv.positionalArguments.first));
  });

  tearDown(() {
    ProductSearchWidgetState.debugKeyClock = null;
    ProductSearchWidgetState.debugDirectScanKeys = true;
    Get.reset();
  });

  Future<void> open(WidgetTester tester) async {
    final start = tester.binding.clock.now();
    ProductSearchWidgetState.debugKeyClock =
        () => tester.binding.clock.now().difference(start);
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: ProductSearchWidget(
          controller: controller,
          onProductSelected: (p, qty) => added.add('${p.id}x$qty'),
        ),
      ),
    ));
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();
  }

  TextEditingController field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  ProductSearchWidgetState search(WidgetTester tester) =>
      tester.state<ProductSearchWidgetState>(find.byType(ProductSearchWidget));

  /// Una tecla como en Windows. Devuelve si la app la consumió.
  Future<bool> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    String? character,
  }) async {
    final consumed = await tester.sendKeyDownEvent(key, character: character);
    if (!consumed) {
      if (character != null) {
        final c = field(tester);
        final sel = c.selection;
        final text = sel.isValid
            ? c.text.replaceRange(sel.start, sel.end, character)
            : c.text + character;
        final offset = (sel.isValid ? sel.start : c.text.length) + 1;
        tester.testTextInput.updateEditingValue(TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ));
      } else if (key == LogicalKeyboardKey.enter) {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      } else if (key == LogicalKeyboardKey.backspace) {
        final c = field(tester);
        if (c.text.isNotEmpty) {
          final text = c.text.substring(0, c.text.length - 1);
          tester.testTextInput.updateEditingValue(TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ));
        }
      }
    }
    await tester.sendKeyUpEvent(key);
    return consumed;
  }

  Future<bool> digit(WidgetTester tester, String d) =>
      press(tester, LogicalKeyboardKey(0x30 + int.parse(d)), character: d);

  /// Lo que se vio en pantalla durante [action]: en cada cuadro, el texto
  /// de la caja y si estaba la tarjeta "Producto sin registrar".
  final seenTexts = <String>[];
  var cardFrames = 0;
  Future<void> frame(WidgetTester tester, [int ms = 0]) async {
    await tester.pump(Duration(milliseconds: ms));
    seenTexts.add(field(tester).text);
    if (search(tester).debugValueOptionVisible ||
        find.text('Producto sin registrar').evaluate().isNotEmpty) {
      cardFrames++;
    }
  }

  setUp(() {
    seenTexts.clear();
    cardFrames = 0;
  });

  /// Lector: dígitos a [gapMs] + Enter; un cuadro tras cada tecla.
  Future<void> scan(WidgetTester tester, String code,
      {int gapMs = 1, LogicalKeyboardKey? end = LogicalKeyboardKey.enter}) async {
    for (final d in code.split('')) {
      expect(await digit(tester, d), isTrue,
          reason: 'cada dígito de la lectura se retiene');
      await frame(tester, gapMs);
    }
    if (end != null) {
      expect(await press(tester, end), isTrue);
      await frame(tester);
    }
  }

  for (final gap in [1, 10, 25]) {
    testWidgets('lector a $gap ms por tecla: ni tarjeta ni código a medias; '
        'la caja pasa de vacía a la línea agregada', (tester) async {
      await open(tester);
      await scan(tester, arroz.barcode!, gapMs: gap);
      await frame(tester, 16);
      expect(added, ['arrozx1.0']);
      expect(cardFrames, 0, reason: 'la tarjeta de valor no se pinta ni una vez');
      expect(seenTexts.toSet(), {''},
          reason: 'la caja nunca mostró el código a medias');
      final m = InvoiceEntryMetrics.instance;
      expect(m.scans, 1);
      expect(m.scansDirect, 1);
      expect(m.scanPartialFrames, 0);
      expect(m.summary(EntryMetric.scanFirstKeyToCode)!.count, 1);
      expect(m.scanGapMs!.$1, closeTo(gap.toDouble(), 0.01));
      await tester.pump(const Duration(seconds: 1));
      expect(added, ['arrozx1.0'], reason: 'no se agrega dos veces');
    });
  }

  testWidgets('20 lecturas pegadas: entran todas, en orden, sin tarjeta',
      (tester) async {
    await open(tester);
    for (var n = 0; n < 20; n++) {
      await scan(tester, (n.isEven ? arroz : leche).barcode!);
      await frame(tester, 5);
    }
    await tester.pump(const Duration(seconds: 1));
    expect(added, [for (var n = 0; n < 20; n++) n.isEven ? 'arrozx1.0' : 'lechex1.0']);
    expect(cardFrames, 0);
    expect(seenTexts.toSet(), {''});
  });

  testWidgets('lector con Tab al final en vez de Enter', (tester) async {
    await open(tester);
    await scan(tester, leche.barcode!, end: LogicalKeyboardKey.tab);
    await frame(tester, 16);
    expect(added, ['lechex1.0']);
    expect(cardFrames, 0);
    expect(seenTexts.toSet(), {''});
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lector SIN Enter: el código aparece completo de un golpe y '
      'se agrega sin esperar la pausa de tecleo', (tester) async {
    await open(tester);
    await scan(tester, arroz.barcode!, end: null);
    expect(seenTexts.toSet(), {''}, reason: 'retenido mientras llegan teclas');
    await frame(tester, 81); // se cortó la ráfaga
    await frame(tester, 5);
    expect(added, ['arrozx1.0']);
    expect(cardFrames, 0);
    expect(seenTexts.where((t) => t.isNotEmpty).toSet(),
        anyOf(isEmpty, {arroz.barcode}),
        reason: 'si se ve, se ve completo');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lectura con Mayús o Bloq Mayús entre dígitos no se corta',
      (tester) async {
    await open(tester);
    final code = arroz.barcode!;
    for (var i = 0; i < code.length; i++) {
      if (i == 3) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.capsLock);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.capsLock);
      }
      if (i == 6) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      if (i == 7) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(await digit(tester, code[i]), isTrue);
      await frame(tester, 2);
    }
    expect(await press(tester, LogicalKeyboardKey.enter), isTrue);
    await frame(tester, 16);
    expect(added, ['arrozx1.0']);
    expect(seenTexts.toSet(), {''});
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('código que no existe queda seleccionado; la lectura siguiente '
      'lo reemplaza sin mostrar nada a medias', (tester) async {
    await open(tester);
    await scan(tester, '7709999999999');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(field(tester).text, '7709999999999');
    expect(added, isEmpty);
    seenTexts.clear();
    await scan(tester, leche.barcode!);
    await frame(tester, 16);
    expect(added, ['lechex1.0']);
    expect(field(tester).text, isEmpty);
    expect(seenTexts.toSet().difference({'7709999999999', ''}), isEmpty,
        reason: 'nunca una mezcla ni un código a medias');
    expect(cardFrames, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  // ───────────── equipo lento: los temporizadores vencen tarde ─────────────
  //
  // En un equipo cargado las teclas SÍ llegan al instante, pero los
  // temporizadores vencen cientos de milisegundos tarde. Aquí el reloj de
  // las teclas se mueve a mano y NO se deja pasar tiempo de la prueba: es
  // como si ningún temporizador venciera.

  /// Abre con un reloj de teclas manual (en ms).
  Future<void Function(int)> openWithManualClock(WidgetTester tester) async {
    await open(tester);
    var ms = 0;
    ProductSearchWidgetState.debugKeyClock = () => Duration(milliseconds: ms);
    return (int value) => ms = value;
  }

  testWidgets('equipo lento, a mano "700" a 120 ms por tecla y ningún '
      'temporizador a tiempo: al llegar el 2.º dígito los dos entran YA a la '
      'caja; el 3.º sigue normal; nunca se toma como lectura', (tester) async {
    final at = await openWithManualClock(tester);
    at(0);
    expect(await digit(tester, '7'), isTrue, reason: 'el 1.º se retiene');
    expect(field(tester).text, isEmpty);
    at(120);
    expect(await digit(tester, '0'), isTrue,
        reason: 'lo pone la app junto con el 7');
    expect(field(tester).text, '70',
        reason: 'sin esperar temporizador ni cuadro');
    at(240);
    expect(await digit(tester, '0'), isFalse, reason: 'camino de siempre');
    expect(field(tester).text, '700');
    await tester.pump();
    expect(find.text('Valor: \$ 700'), findsOneWidget);
    expect(InvoiceEntryMetrics.instance.scans, 0);
    // Enter: es un valor, no un código leído.
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(added, isEmpty);
    expect(InvoiceEntryMetrics.instance.scans, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('equipo lento, un solo dígito: entra en el siguiente cuadro '
      'aunque el temporizador no haya vencido', (tester) async {
    final at = await openWithManualClock(tester);
    at(0);
    await digit(tester, '5');
    at(20);
    await tester.pump(); // un cuadro antes de tiempo: sigue retenido
    expect(field(tester).text, isEmpty);
    at(40);
    await tester.pump(); // otro cuadro; el temporizador (32 ms) NO venció
    expect(field(tester).text, '5');
    expect(find.text('Valor: \$ 5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('equipo lento, un solo dígito: también entra al soltar la '
      'tecla si ya pasó la espera', (tester) async {
    final at = await openWithManualClock(tester);
    at(0);
    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.digit5, character: '5'),
        isTrue);
    expect(field(tester).text, isEmpty);
    at(70); // una persona suelta la tecla a los 70 ms
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit5);
    expect(field(tester).text, '5', reason: 'sin temporizador ni cuadro');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('equipo lento, lector: las 13 teclas llegan en 25 ms y ningún '
      'temporizador vence a tiempo → lectura directa, nada en la caja',
      (tester) async {
    final at = await openWithManualClock(tester);
    final code = arroz.barcode!;
    for (var i = 0; i < code.length; i++) {
      at(i * 2);
      expect(await digit(tester, code[i]), isTrue);
      expect(field(tester).text, isEmpty);
    }
    at(27);
    expect(await press(tester, LogicalKeyboardKey.enter), isTrue);
    await tester.pump();
    expect(added, ['arrozx1.0']);
    expect(field(tester).text, isEmpty);
    expect(InvoiceEntryMetrics.instance.scansDirect, 1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lector a 30 ms por tecla (lento) sigue siendo lectura; a mano '
      'a 70 ms (rapidísimo) sigue siendo a mano', (tester) async {
    final at = await openWithManualClock(tester);
    final code = leche.barcode!;
    for (var i = 0; i < code.length; i++) {
      at(i * 30);
      expect(await digit(tester, code[i]), isTrue);
    }
    at(13 * 30);
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump();
    expect(added, ['lechex1.0']);
    expect(field(tester).text, isEmpty);

    at(5000);
    await digit(tester, '2');
    at(5070);
    await digit(tester, '5');
    expect(field(tester).text, '25');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Enter con un solo dígito retenido (persona muy rápida): es un '
      'valor, no un código', (tester) async {
    final at = await openWithManualClock(tester);
    at(0);
    await digit(tester, '9');
    at(10);
    expect(await press(tester, LogicalKeyboardKey.enter), isTrue);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(added, isEmpty);
    expect(InvoiceEntryMetrics.instance.scans, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  // ───────────── a mano: todo igual ─────────────

  testWidgets('a mano: el primer dígito y su tarjeta salen juntos tras la '
      'espera corta; los siguientes, en la misma tecla', (tester) async {
    await open(tester);
    expect(await digit(tester, '2'), isTrue, reason: 'con la caja vacía se retiene');
    await frame(tester, 30);
    expect(field(tester).text, isEmpty);
    await frame(tester, 3); // 33 ms
    expect(field(tester).text, '2');
    expect(find.text('Valor: \$ 2'), findsOneWidget,
        reason: 'dígito y tarjeta en el mismo cuadro');
    // Dígitos siguientes: la app no los toca (camino de siempre).
    const shown = ['\$ 25', '\$ 250', '\$ 2.500'];
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      expect(await digit(tester, '500'[i]), isFalse);
      await tester.pump();
      expect(find.text('Valor: ${shown[i]}'), findsOneWidget,
          reason: 'en la misma tecla, sin esperar');
    }
    // Enter: el diálogo del nombre, como siempre.
    expect(await press(tester, LogicalKeyboardKey.enter), isFalse);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(added, isEmpty);
    expect(InvoiceEntryMetrics.instance.scans, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a mano: un dígito y Enter enseguida abre el diálogo del valor',
      (tester) async {
    await open(tester);
    await digit(tester, '7');
    await tester.pump(const Duration(milliseconds: 10));
    expect(await press(tester, LogicalKeyboardKey.enter), isTrue);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    expect(find.text('Valor: \$ 7'), findsWidgets);
    expect(added, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a mano: valor de 4 dígitos tecleado rapidísimo sin Enter entra '
      'completo y con su tarjeta', (tester) async {
    await open(tester);
    for (final d in '2500'.split('')) {
      await digit(tester, d);
      await frame(tester, 20);
    }
    expect(seenTexts.toSet(), {''});
    await frame(tester, 81);
    expect(field(tester).text, '2500');
    expect(find.text('Valor: \$ 2.500'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a mano: con texto en la caja los dígitos no se retienen',
      (tester) async {
    await open(tester);
    for (final ch in ['a', 'r']) {
      expect(await press(tester, LogicalKeyboardKey(ch.codeUnitAt(0)), character: ch),
          isFalse, reason: 'las letras nunca se retienen');
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(await digit(tester, '5'), isFalse);
    await tester.pump();
    expect(field(tester).text, 'ar5');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a mano: dígito y enseguida una letra o Retroceso: el dígito '
      'entra primero y la otra tecla sigue normal', (tester) async {
    await open(tester);
    await digit(tester, '5');
    await tester.pump(const Duration(milliseconds: 10));
    expect(await press(tester, LogicalKeyboardKey.keyK, character: 'k'), isFalse);
    await tester.pump();
    expect(field(tester).text, '5k');
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(seconds: 1));
    await digit(tester, '8');
    await tester.pump(const Duration(milliseconds: 10));
    // (Retroceso lo atiende la propia caja de texto.)
    await press(tester, LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(field(tester).text, isEmpty, reason: 'el 8 entró y se borró');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Ctrl + dígito (atajo de cantidad) no se retiene', (tester) async {
    await open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(
        await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2, character: '2'),
        isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));
    expect(field(tester).text, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Mayús + número (símbolo en teclado español) no se retiene',
      (tester) async {
    await open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(await press(tester, LogicalKeyboardKey.digit7, character: '/'), isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(field(tester).text, '/');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('teclado numérico: sus dígitos también son una lectura',
      (tester) async {
    await open(tester);
    final code = arroz.barcode!;
    const pad = [
      LogicalKeyboardKey.numpad0, LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4, LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6, LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8, LogicalKeyboardKey.numpad9,
    ];
    for (final d in code.split('')) {
      expect(await press(tester, pad[int.parse(d)], character: d), isTrue);
      await frame(tester, 2);
    }
    expect(await press(tester, LogicalKeyboardKey.numpadEnter), isTrue);
    await frame(tester, 16);
    expect(added, ['arrozx1.0']);
    expect(seenTexts.toSet(), {''});
    await tester.pump(const Duration(seconds: 1));
  });

  // ───────────── la captura solo actúa en el buscador ─────────────

  testWidgets('diálogo del nombre: dígitos y letras se escriben ahí; la '
      'captura del lector no los toca ("7up", "2 litros")', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
    final name = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(EditableText));
    final nameController = tester.widget<EditableText>(name).controller;
    expect(tester.widget<EditableText>(name).focusNode.hasPrimaryFocus, isTrue);

    Future<bool> typeInName(LogicalKeyboardKey key, String ch) async {
      final consumed = await tester.sendKeyDownEvent(key, character: ch);
      if (!consumed) {
        final sel = nameController.selection;
        final text = nameController.text.replaceRange(sel.start, sel.end, ch);
        tester.testTextInput.updateEditingValue(TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: sel.start + 1),
        ));
      }
      await tester.sendKeyUpEvent(key);
      await tester.pump(const Duration(milliseconds: 5));
      return consumed;
    }

    // "7up": el 7 reemplaza el nombre seleccionado (por eso el texto queda
    // MÁS CORTO que antes: 1 carácter en vez de 22).
    expect(await typeInName(LogicalKeyboardKey.digit7, '7'), isFalse);
    expect(nameController.text, '7');
    expect(await typeInName(LogicalKeyboardKey.keyU, 'u'), isFalse);
    expect(await typeInName(LogicalKeyboardKey.keyP, 'p'), isFalse);
    // Dígitos seguidos, rapidísimo (como un precio o "2 litros").
    for (final d in '2500'.split('')) {
      expect(
          await typeInName(LogicalKeyboardKey(0x30 + int.parse(d)), d), isFalse);
    }
    expect(nameController.text, '7up2500');
    await tester.pump(const Duration(milliseconds: 200));
    expect(nameController.text, '7up2500', reason: 'nada retenido que caiga después');
    expect(field(tester).text, '500', reason: 'el buscador no recibe nada');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(added.single, startsWith('temp_'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('otro campo con el foco (cantidad, precio, cliente…): los '
      'dígitos no se retienen aunque el buscador esté vacío', (tester) async {
    final other = TextEditingController();
    final start = tester.binding.clock.now();
    ProductSearchWidgetState.debugKeyClock =
        () => tester.binding.clock.now().difference(start);
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ProductSearchWidget(
              controller: controller,
              onProductSelected: (p, qty) => added.add('${p.id}x$qty'),
            ),
            TextField(key: const Key('cantidad'), controller: other),
          ],
        ),
      ),
    ));
    await tester.showKeyboard(find.byKey(const Key('cantidad')));
    await tester.pump();
    for (final d in '125'.split('')) {
      final consumed = await tester.sendKeyDownEvent(
          LogicalKeyboardKey(0x30 + int.parse(d)),
          character: d);
      expect(consumed, isFalse, reason: 'dígito $d en otro campo');
      if (!consumed) {
        tester.testTextInput.updateEditingValue(TextEditingValue(
          text: other.text + d,
          selection: TextSelection.collapsed(offset: other.text.length + 1),
        ));
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey(0x30 + int.parse(d)));
      await tester.pump(const Duration(milliseconds: 2));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(other.text, '125');
    expect(field(tester).text, isEmpty);
    expect(added, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('apagada la lectura directa, todo va por la caja como antes',
      (tester) async {
    ProductSearchWidgetState.debugDirectScanKeys = false;
    await open(tester);
    expect(await digit(tester, '7'), isFalse);
    await tester.pump();
    expect(field(tester).text, '7');
    await tester.pump(const Duration(seconds: 1));
  });
}
