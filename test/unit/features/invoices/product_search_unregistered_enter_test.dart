// "Producto sin registrar" a mano: se escribe un valor, Enter, y el campo
// del nombre debe quedar listo DE INMEDIATO (un cuadro), aunque el equipo
// no pueda asegurar todavía que no existe un producto con ese código
// (índice sin cargar, catálogo bajando, sincronización escribiendo).
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
  late bool stale;
  late Completer<Product?> local; // respuesta de la base local
  var localLookups = 0;

  final huevo = ProductFixtures.createProductEntity(
      id: 'huevo', name: 'Huevo AA', sku: '500', barcode: null);
  final index = ShortCodeIndex.build(const [], complete: true);

  setUp(() {
    InvoiceEntryMetrics.instance.reset();
    Get.testMode = true;
    controller = MockInvoiceFormController();
    added = [];
    stale = true; // la sincronización está escribiendo productos
    local = Completer();
    localLookups = 0;
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index,
            stale: stale));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.findRegisteredProductForValue(any())).thenAnswer((_) {
      localLookups++;
      return local.future;
    });
  });

  tearDown(Get.reset);

  Future<void> typeValueAndEnter(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: ProductSearchWidget(
          controller: controller,
          onProductSelected: (p, qty) => added.add('${p.id}:${p.name}'),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();
    expect(find.text('Valor: \$ 500'), findsOneWidget, reason: 'la tarjeta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
  }

  Finder nameField() => find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(EditableText));

  void expectNameFieldReady(WidgetTester tester) {
    expect(find.text('Nombre en la factura'), findsOneWidget);
    final field = tester.widget<EditableText>(nameField());
    expect(field.focusNode.hasFocus, isTrue, reason: 'con el cursor adentro');
    expect(field.controller.text, unregisteredProductName);
    expect(field.controller.selection.start, 0);
    expect(field.controller.selection.end, unregisteredProductName.length,
        reason: 'todo seleccionado: se escribe encima o se da Enter');
    // Sin animación de entrada: ya está en su sitio y opaco.
    final route = ModalRoute.of(tester.element(find.byType(AlertDialog)))!;
    expect(route.animation!.status, AnimationStatus.completed,
        reason: 'el diálogo no entra animado');
  }

  testWidgets('índice seguro: Enter abre el campo del nombre en el mismo cuadro',
      (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    stale = false;
    await typeValueAndEnter(tester);
    await tester.pump();
    await tester.pump(); // el foco se asienta
    expectNameFieldReady(tester);
    expect(localLookups, 0, reason: 'no consulta nada');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('equipo sin certeza y la base lenta: el campo sale a un cuadro '
      '(16 ms), no espera los 250 ms de antes', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    await typeValueAndEnter(tester);
    await tester.pump(const Duration(milliseconds: 15));
    expect(find.text('Nombre en la factura'), findsNothing,
        reason: 'un cuadro de gracia a la base local');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expectNameFieldReady(tester);
    expect(localLookups, 1, reason: 'una sola consulta local');
    // El cajero acepta el nombre: la base por fin responde que no existe.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsNothing,
        reason: 'el diálogo se cierra ya');
    expect(added, isEmpty, reason: 'espera la respuesta (250 ms como mucho)');
    local.complete(null);
    await tester.pump();
    expect(added, ['${added.single.split(':').first}:$unregisteredProductName']);
    expect(added.single, startsWith('temp_'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la base responde enseguida que no existe: diálogo sin esperar '
      'el cuadro de gracia', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    local.complete(null);
    await typeValueAndEnter(tester);
    await tester.pump();
    await tester.pump();
    expectNameFieldReady(tester);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la base responde enseguida que SÍ existe: se agrega el '
      'registrado, sin diálogo', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    local.complete(huevo);
    await typeValueAndEnter(tester);
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsNothing);
    expect(added, ['huevo:Huevo AA']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la base responde tarde que SÍ existe, con el diálogo abierto: '
      'se cierra y entra el registrado (el registrado gana)', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    await typeValueAndEnter(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    local.complete(huevo);
    await tester.pump();
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsNothing);
    expect(added, ['huevo:Huevo AA']);
    await tester.pump(const Duration(seconds: 1));
    expect(added, hasLength(1));
  });

  testWidgets('Enter en el nombre antes de que la base responda, y SÍ existía: '
      'entra el registrado, no uno sin registrar', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    await typeValueAndEnter(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    local.complete(huevo);
    await tester.pump();
    expect(added, ['huevo:Huevo AA']);
    await tester.pump(const Duration(seconds: 1));
    expect(added, hasLength(1));
  });

  testWidgets('la base nunca responde: a los 250 ms entra como sin registrar '
      'con el nombre escrito', (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    await typeValueAndEnter(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    await tester.enterText(nameField(), 'Bolsa grande');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 249));
    expect(added, isEmpty);
    await tester.pump(const Duration(milliseconds: 2));
    expect(added.single, endsWith(':Bolsa grande'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Cancelar: no agrega nada, aunque la base responda después',
      (tester) async {
    // Dentro de la prueba: así su respuesta corre con el reloj simulado.
    local = Completer();
    await typeValueAndEnter(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    local.complete(huevo);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Nombre en la factura'), findsNothing);
    expect(added, isEmpty);
  });
}
