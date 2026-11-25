// test/unit/features/invoices/product_search_widget_test.dart
//
// Buscador de productos de la factura: escáner, precio (producto no
// registrado) y texto.
import 'dart:async';

import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
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
  final huevo = ProductFixtures.createProductEntity(
      id: 'huevo', name: 'Huevo AA', sku: '5000', barcode: null);
  // Producto registrado con código de barras CORTO (gana al "sin registrar").
  final pan = ProductFixtures.createProductEntity(
      id: 'pan', name: 'Pan', sku: 'PAN-1', barcode: '777');
  final byLocalId = {1: arroz, 2: leche, 3: huevo, 4: pan};
  ShortCodeIndex? index;
  var stale = false;
  // Lo que respondería la base local por código exacto.
  Future<Product?> Function(String code)? localLookup;

  setUp(() {
    stale = false;
    localLookup = null;
    InvoiceEntryMetrics.instance.reset();
    Get.testMode = true;
    controller = MockInvoiceFormController();
    added = [];
    index = ShortCodeIndex.build([
      for (final e in byLocalId.entries) ...[
        (e.value.sku, e.key),
        (e.value.barcode, e.key),
      ],
    ], complete: true);
    when(() => controller.decideValueEntry(any()))
        .thenAnswer((inv) => decidePriceEntry(inv.positionalArguments.first as String, index));
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index,
            stale: stale));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.findRegisteredProductForValue(any()))
        .thenAnswer((inv) async {
      final code = inv.positionalArguments.first as String;
      if (localLookup != null) return localLookup!(code);
      return [arroz, leche, huevo, pan].firstWhereOrNull(
          (p) => p.sku == code || p.barcode == code);
    });
    when(() => controller.productByLocalId(any()))
        .thenAnswer((inv) async => byLocalId[inv.positionalArguments.first as int]);
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.searchProducts(any())).thenAnswer((inv) async {
      final q = (inv.positionalArguments.first as String).toLowerCase();
      return [arroz, leche, huevo]
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q))
          .toList();
    });
    // El Enter con un valor busca el código EXACTO (ya no la búsqueda "que contenga").
    when(() => controller.findProductBySku(any())).thenAnswer((inv) async {
      final sku = (inv.positionalArguments.first as String).toLowerCase();
      return [arroz, leche, huevo].firstWhereOrNull((p) => p.sku.toLowerCase() == sku);
    });
    when(() => controller.findProductByBarcode(any(),
            localOnly: any(named: 'localOnly')))
        .thenAnswer((inv) async {
      final code = inv.positionalArguments.first as String;
      return [arroz, leche].firstWhereOrNull((p) => p.barcode == code);
    });
  });

  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: ProductSearchWidget(
          controller: controller,
          onProductSelected: (p, qty) => added.add('${p.id}x$qty'),
        ),
      ),
    ));
  }

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField).first, code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  testWidgets('código de barras + Enter agrega de una vez', (tester) async {
    await pump(tester);
    await scan(tester, '7701111111111');
    await tester.pump();
    expect(added, ['arrozx1.0']);
    expect(fieldText(tester), isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(added, ['arrozx1.0'], reason: 'no se agrega dos veces');
  });

  testWidgets('dos escaneos seguidos se agregan los dos en orden',
      (tester) async {
    await pump(tester);
    await scan(tester, '7701111111111');
    await scan(tester, '7702222222222');
    await tester.pump(const Duration(seconds: 1));
    expect(added, ['arrozx1.0', 'lechex1.0']);
  });

  testWidgets('código no encontrado queda en la caja para corregirlo',
      (tester) async {
    await pump(tester);
    await scan(tester, '9999999999');
    await tester.pump(const Duration(seconds: 1));
    expect(added, isEmpty);
    expect(fieldText(tester), '9999999999');
  });

  testWidgets('resultados viejos de texto no agregan otro producto al escanear',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'arroz');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Arroz Diana'), findsWidgets);

    await scan(tester, '7702222222222');
    await tester.pump(const Duration(seconds: 1));
    expect(added, ['lechex1.0']);
  });

  testWidgets('texto + Enter selecciona el primer resultado', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'leche');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(added, ['lechex1.0']);
  });

  testWidgets('precio + Enter rápido con SKU existente agrega ese producto',
      (tester) async {
    await pump(tester);
    await scan(tester, '5000');
    await tester.pump(const Duration(milliseconds: 50));
    expect(added, ['huevox1.0']);
    expect(find.text('Nuevo Producto'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('precio + Enter sin SKU abre el nombre y Enter otra vez lo agrega',
      (tester) async {
    await pump(tester);
    final watch = Stopwatch()..start();
    await scan(tester, '3500');
    await tester.pumpAndSettle();
    expect(find.text('Nombre en la factura'), findsOneWidget,
        reason: 'Enter abre el diálogo del nombre, como siempre');
    expect(added, isEmpty);
    verifyNever(() => controller.findProductBySku(any()));
    // Enter dentro del diálogo: entra con el nombre por defecto.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    watch.stop();
    expect(added, hasLength(1));
    expect(added.single, startsWith('temp_'));
    expect(find.text('Nombre en la factura'), findsNothing);
    expect(fieldText(tester), isEmpty);
    // ignore: avoid_print
    print('MEDICION Enter+Enter "3500" -> linea: ${watch.elapsedMicroseconds / 1000} ms');
    await tester.pump(const Duration(seconds: 1));
    expect(added, hasLength(1), reason: 'no se agrega dos veces');
  });

  testWidgets('valores 500, 600 y 20000 entran con su precio (Enter, Enter)',
      (tester) async {
    final prices = <double>[];
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: ProductSearchWidget(
          controller: controller,
          onProductSelected: (p, qty) => prices.add(p.sellingPrice ?? -1),
        ),
      ),
    ));
    for (final v in ['500', '600', '20000']) {
      await scan(tester, v);
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(prices, [500, 600, 20000]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('código de barras corto registrado gana al sin registrar',
      (tester) async {
    await pump(tester);
    await scan(tester, '777');
    await tester.pump();
    await tester.pump();
    expect(added, ['panx1.0']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('con el catálogo bajando, Enter confirma en la base local: gana el producto',
      (tester) async {
    index = ShortCodeIndex.build(const [], complete: false);
    await pump(tester);
    await scan(tester, '5000');
    await tester.pump(const Duration(milliseconds: 50));
    expect(added, ['huevox1.0']);
    verify(() => controller.findRegisteredProductForValue('5000')).called(1);
    await tester.pump(const Duration(seconds: 1));
  });

  // ───── El valor se pinta en la misma tecla, pase lo que pase ─────

  Future<void> expectInstantOption(WidgetTester tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pump(); // el cuadro de la tecla, sin dejar pasar tiempo
    expect(find.text('Producto sin registrar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.pump();
    expect(find.text('Valor: \$ 2.000'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(added, isEmpty);
  }

  testWidgets('catálogo sin terminar de bajar: la opción sale en la misma tecla',
      (tester) async {
    index = ShortCodeIndex.build(const [], complete: false);
    await expectInstantOption(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Producto sin registrar'), findsOneWidget);
    verifyNever(() => controller.searchProducts(any()));
    verifyNever(() => controller.findProductBySku(any()));
    verifyNever(() => controller.findProductByBarcode(any()));
  });

  testWidgets('índice sin cargar todavía: la opción sale en la misma tecla',
      (tester) async {
    index = null;
    await expectInstantOption(tester);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('sincronización escribiendo productos: la opción sale en la misma tecla',
      (tester) async {
    stale = true;
    await expectInstantOption(tester);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la base local no responde: la opción sale igual y Enter abre el nombre',
      (tester) async {
    index = ShortCodeIndex.build(const [], complete: false);
    final never = Completer<Product?>();
    localLookup = (_) => never.future;
    await expectInstantOption(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(added.single, startsWith('temp_'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('por confirmar: si existía un producto con ese código, reemplaza la opción',
      (tester) async {
    // El índice no lo tiene (llegó por la sincronización hace un momento).
    index = ShortCodeIndex.build(const [], complete: true);
    stale = true;
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pump();
    expect(find.text('Producto sin registrar'), findsOneWidget,
        reason: 'primero se pinta, sin esperar');
    await tester.pump(const Duration(milliseconds: 100)); // confirmación
    await tester.pump();
    expect(find.text('Huevo AA'), findsOneWidget);
    expect(find.text('Producto sin registrar'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(added, ['huevox1.0']);
    verify(() => controller.findRegisteredProductForValue('5000')).called(1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('con el índice seguro no se consulta la base ni al teclear ni con Enter',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget,
        reason: 'Enter abre el nombre en el mismo cuadro');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(added.single, startsWith('temp_'));
    verifyNever(() => controller.findRegisteredProductForValue(any()));
    verifyNever(() => controller.searchProducts(any()));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('producto registrado con código corto sale sin pausa de tecleo',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '777');
    await tester.pump();
    await tester.pump();
    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('Producto sin registrar'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la medición registra tecla → opción y Enter → línea',
      (tester) async {
    index = ShortCodeIndex.build(const [], complete: false);
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final m = InvoiceEntryMetrics.instance;
    expect(m.valueKeysUnconfirmed, 1);
    expect(m.summary(EntryMetric.keyToOption)?.count, 1);
    expect(m.summary(EntryMetric.backgroundCheck)?.count, 1);
    expect(m.summary(EntryMetric.enterToDialog)?.count, 1);
    expect(m.summary(EntryMetric.confirmToLine)?.count, 1);
    expect(m.report(), contains('Tecla → opción'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('clic en la opción abre el diálogo para ponerle nombre',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '3500');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.text('Producto sin registrar'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nombre en la factura'), 'Bolsa');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(added, hasLength(1));
    expect(added.single, startsWith('temp_'));
  });

  testWidgets('precio escrito sale al instante con el valor que va escrito',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pump();
    expect(find.text('Producto sin registrar'), findsOneWidget,
        reason: 'sin esperar la pausa');
    await tester.enterText(find.byType(TextField).first, '700');
    await tester.pump();
    expect(find.text('Valor: \$ 700'), findsOneWidget,
        reason: 'el valor se actualiza en el acto');
    expect(added, isEmpty);
    verifyNever(() => controller.findProductBySku(any()));

    // Enter con la opción a la vista: abre el nombre; Enter otra vez agrega.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(added.single, startsWith('temp_'));
    await tester.pump(const Duration(seconds: 1));
  });
}
