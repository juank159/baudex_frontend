// Factura: producto con código de barras CORTO y ceros adelante ("0013390").
//
// 7 dígitos se leen como un valor ("Producto sin registrar" de $13.390),
// salvo que exista un producto con ese código exacto. Aquí se prueba, con
// la pantalla, que leerlo con el lector (teclas rápidas + Enter) o
// teclearlo a mano agrega ESE producto, y que sin producto con ese código
// "13390" y "500" siguen abriendo el nombre del producto sin registrar.
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
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
  late ShortCodeIndex? index;

  const panelaLocalId = 41;
  final panela = ProductFixtures.createProductEntity(
      id: 'panela', name: 'Panela', sku: 'PAN-1', barcode: '0013390');

  /// La base local: producto activo con SKU o código EXACTO.
  Product? registered(String q) =>
      (panela.sku == q || panela.barcode == q) ? panela : null;

  setUpAll(() => registerFallbackValue(panela));

  setUp(() {
    InvoiceEntryMetrics.instance.reset();
    Get.testMode = true;
    controller = MockInvoiceFormController();
    added = [];
    // Índice al día, con el código de la panela (como lo arma la app).
    index = ShortCodeIndex.build(
        [(panela.sku, panelaLocalId), (panela.barcode, panelaLocalId)],
        complete: true);
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.searchProducts(any())).thenAnswer((_) async => []);
    when(() => controller.scanMayExistOnServer()).thenAnswer((_) async => false);
    when(() => controller.findProductByBarcode(any(),
            localOnly: any(named: 'localOnly')))
        .thenAnswer((_) async => null);
    when(() => controller.productByLocalId(panelaLocalId))
        .thenAnswer((_) async => panela);
    when(() => controller.findRegisteredProductForValue(any())).thenAnswer(
        (inv) async => registered(inv.positionalArguments.first as String));
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
          onProductSelected: (p, qty) => added.add('${p.id}:${p.name}'),
        ),
      ),
    ));
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();
  }

  TextEditingController field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  /// Una tecla como en Windows: si la app no la consume, el sistema la
  /// escribe en la caja.
  Future<bool> press(WidgetTester tester, LogicalKeyboardKey key,
      {String? character}) async {
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
      }
    }
    await tester.sendKeyUpEvent(key);
    return consumed;
  }

  Future<bool> digit(WidgetTester tester, String d) =>
      press(tester, LogicalKeyboardKey(0x30 + int.parse(d)), character: d);

  /// Lector: dígitos a [gapMs] + Enter.
  Future<void> scan(WidgetTester tester, String code, {int gapMs = 2}) async {
    for (final d in code.split('')) {
      await digit(tester, d);
      await tester.pump(Duration(milliseconds: gapMs));
    }
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump();
  }

  /// A mano: una tecla cada [gapMs] + Enter.
  Future<void> typeByHand(WidgetTester tester, String code,
      {int gapMs = 150}) async {
    for (final d in code.split('')) {
      await digit(tester, d);
      await tester.pump(Duration(milliseconds: gapMs));
    }
    expect(field(tester).text, code, reason: 'se ve lo tecleado');
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump();
  }

  final nameDialog = find.text('Nombre en la factura');

  void expectPanelaAdded() {
    expect(added, ['panela:Panela']);
    expect(nameDialog, findsNothing,
        reason: 'no se abre el producto sin registrar');
  }

  group('existe un producto con código "0013390"', () {
    for (final gap in [1, 10, 25]) {
      testWidgets('lector a $gap ms por tecla + Enter: agrega la panela',
          (tester) async {
        await open(tester);
        await scan(tester, '0013390', gapMs: gap);
        await tester.pump(const Duration(milliseconds: 50));
        expectPanelaAdded();
        expect(field(tester).text, isEmpty, reason: 'caja lista');
        await tester.pump(const Duration(seconds: 1));
        expect(added, hasLength(1), reason: 'no se agrega dos veces');
      });
    }

    testWidgets('tecleado a mano + Enter: agrega la panela', (tester) async {
      await open(tester);
      await typeByHand(tester, '0013390');
      await tester.pump(const Duration(milliseconds: 50));
      expectPanelaAdded();
      await tester.pump(const Duration(seconds: 1));
      expect(added, hasLength(1));
    });

    testWidgets('pegado en la caja + Enter: agrega la panela', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).first, '0013390');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      expectPanelaAdded();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('índice aún sin cargar (equipo recién abierto): la base '
        'local la encuentra y se agrega la panela', (tester) async {
      index = null;
      await open(tester);
      await scan(tester, '0013390');
      await tester.pump(const Duration(milliseconds: 50));
      expectPanelaAdded();
      await tester.pump(const Duration(seconds: 1));
      expect(added, hasLength(1));
    });

    testWidgets('"13390" (sin los ceros) NO es la panela: producto sin '
        'registrar de \$13.390, como hoy', (tester) async {
      await open(tester);
      await typeByHand(tester, '13390');
      await tester.pump();
      expect(nameDialog, findsOneWidget);
      expect(added, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(added.single, startsWith('temp_'));
      expect(added.single, endsWith(':$unregisteredProductName'));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('sin producto con ese código (como hoy)', () {
    setUp(() {
      index = ShortCodeIndex.build(const [], complete: true);
      when(() => controller.findRegisteredProductForValue(any()))
          .thenAnswer((_) async => null);
    });

    for (final value in ['500', '13390', '0013390']) {
      testWidgets('"$value" a mano + Enter abre el nombre; Enter agrega el '
          'producto sin registrar', (tester) async {
        await open(tester);
        await typeByHand(tester, value);
        await tester.pump();
        expect(nameDialog, findsOneWidget);
        expect(added, isEmpty);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(added.single, startsWith('temp_'));
        expect(added.single, endsWith(':$unregisteredProductName'));
        await tester.pump(const Duration(seconds: 1));
        expect(added, hasLength(1));
      });
    }

    testWidgets('"500" leído rapidísimo + Enter: también el nombre del '
        'producto sin registrar', (tester) async {
      await open(tester);
      await scan(tester, '500');
      await tester.pump();
      expect(nameDialog, findsOneWidget);
      expect(added, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(added.single, endsWith(':$unregisteredProductName'));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
