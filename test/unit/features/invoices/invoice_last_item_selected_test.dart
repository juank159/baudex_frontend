import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

/// Regla del negocio: el ÚLTIMO producto agregado queda siempre elegido, para
/// que Ctrl+número le sume sin bajar con las flechas. Fallaba al vaciar la
/// lista y volver a agregar (y con otra fila elegida): el producto nuevo entra
/// en la posición 0 y "0 sobre 0" no avisaba a la pantalla.
///
/// Cada caso se comprueba con el atajo REAL (Ctrl+1 suma 1 a la fila elegida):
/// si la fila no queda elegida, la cantidad no cambia y la prueba falla.
void main() {
  setUpAll(tzdata.initializeTimeZones);
  setUp(() {
    Get.testMode = true;
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
  });
  tearDown(Get.reset);

  Product product(int n, {String? id}) => Product(
        id: id ?? 'p$n',
        name: 'Producto $n',
        sku: 'SKU-$n',
        barcode: '770${n.toString().padLeft(10, '0')}',
        type: ProductType.product,
        status: ProductStatus.active,
        stock: 500,
        minStock: 0,
        categoryId: 'c',
        createdById: 'u',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        prices: [
          ProductPrice(
            id: 'pr$n',
            type: PriceType.price1,
            amount: 1000.0 + n,
            currency: 'COP',
            status: PriceStatus.active,
            discountPercentage: 0,
            minQuantity: 1,
            productId: id ?? 'p$n',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );

  Future<void> frames(WidgetTester t, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> key(WidgetTester t, LogicalKeyboardKey k) async {
    await t.sendKeyEvent(k);
    await t.pump(const Duration(milliseconds: 20));
  }

  Future<void> ctrl(WidgetTester t, LogicalKeyboardKey k) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(k);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump(const Duration(milliseconds: 20));
  }

  Future<InvoiceTabsController> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const GetMaterialApp(home: InvoiceFormTabsScreen()));
    await frames(t);
    await t.tap(find.descendant(
        of: find.byType(ProductSearchWidget), matching: find.byType(TextField)));
    await frames(t, 2);
    return Get.find<InvoiceTabsController>();
  }

  double qty(InvoiceFormController c, String productId) =>
      c.invoiceItems.firstWhere((i) => i.productId == productId).quantity;

  /// Ctrl+1 debe sumarle 1 a [productId] y a nadie más.
  Future<void> expectShortcutGoesTo(
      WidgetTester t, InvoiceFormController c, String productId, String caso) async {
    final before = {for (final i in c.invoiceItems) i.productId: i.quantity};
    await ctrl(t, LogicalKeyboardKey.digit1);
    for (final i in c.invoiceItems) {
      final expected = before[i.productId]! + (i.productId == productId ? 1 : 0);
      expect(i.quantity, expected,
          reason: '$caso: el atajo debe ir a $productId (fila ${i.productId})');
    }
  }

  testWidgets('vaciar la lista quitando uno por uno y volver a agregar', (t) async {
    final c = (await open(t)).currentTab!.controller;
    c.addOrUpdateProductToInvoice(product(1));
    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p2', 'recién agregado');

    c.removeItem(0);
    c.removeItem(0);
    await frames(t);
    expect(c.invoiceItems, isEmpty);

    c.addOrUpdateProductToInvoice(product(3));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p3', 'tras vaciar la lista');
    c.addOrUpdateProductToInvoice(product(4));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p4', 'segundo tras vaciar');
    await frames(t, 10);
  });

  testWidgets('vaciar con Ctrl+Supr (atajo) y volver a agregar', (t) async {
    final c = (await open(t)).currentTab!.controller;
    c.addOrUpdateProductToInvoice(product(1));
    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    await ctrl(t, LogicalKeyboardKey.delete);
    await frames(t);
    expect(c.invoiceItems.length, 1);
    await expectShortcutGoesTo(t, c, 'p1', 'tras borrar el de arriba queda el otro');
    await ctrl(t, LogicalKeyboardKey.delete);
    await frames(t);
    expect(c.invoiceItems, isEmpty);

    c.addOrUpdateProductToInvoice(product(3));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p3', 'tras vaciar con el atajo');
    await frames(t, 10);
  });

  testWidgets('venta nueva (se limpia la factura) y primer producto', (t) async {
    final c = (await open(t)).currentTab!.controller;
    c.addOrUpdateProductToInvoice(product(1));
    await frames(t);
    c.clearFormForNewSale();
    await frames(t);
    expect(c.invoiceItems, isEmpty);

    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p2', 'primera línea de la venta nueva');
    await frames(t, 10);
  });

  testWidgets('limpiar productos (clearItems) y volver a agregar', (t) async {
    final c = (await open(t)).currentTab!.controller;
    c.addOrUpdateProductToInvoice(product(1));
    await frames(t);
    c.clearItems();
    await frames(t);
    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p2', 'tras limpiar productos');
    await frames(t, 10);
  });

  testWidgets('con otra fila elegida con las flechas, el producto nuevo queda elegido',
      (t) async {
    final c = (await open(t)).currentTab!.controller;
    for (var n = 1; n <= 4; n++) {
      c.addOrUpdateProductToInvoice(product(n));
    }
    await frames(t);
    await key(t, LogicalKeyboardKey.arrowDown);
    await key(t, LogicalKeyboardKey.arrowDown);
    await expectShortcutGoesTo(t, c, 'p2', 'flechas: tercera fila');

    c.addOrUpdateProductToInvoice(product(5));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p5', 'nuevo con otra fila elegida');
    await frames(t, 10);
  });

  testWidgets('repetir un producto ya agregado: queda elegido ese', (t) async {
    final c = (await open(t)).currentTab!.controller;
    for (var n = 1; n <= 4; n++) {
      c.addOrUpdateProductToInvoice(product(n));
    }
    await frames(t);
    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    expect(qty(c, 'p2'), 2);
    await expectShortcutGoesTo(t, c, 'p2', 'repetido');
    // Y otra vez el mismo (mismo índice que la vez anterior).
    await key(t, LogicalKeyboardKey.arrowUp);
    c.addOrUpdateProductToInvoice(product(2));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p2', 'repetido dos veces seguidas');
    await frames(t, 10);
  });

  testWidgets('producto no registrado (500 + Enter + Enter) queda elegido', (t) async {
    final c = (await open(t)).currentTab!.controller;
    c.addOrUpdateProductToInvoice(product(1));
    await frames(t);
    await key(t, LogicalKeyboardKey.arrowDown);
    c.addOrUpdateProductToInvoice(product(500, id: 'unregistered_a'));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'unregistered_a', 'no registrado');
    c.removeItem(0);
    c.removeItem(0);
    await frames(t);
    c.addOrUpdateProductToInvoice(product(700, id: 'unregistered_b'));
    await frames(t);
    await expectShortcutGoesTo(t, c, 'unregistered_b', 'no registrado tras vaciar');
    await frames(t, 10);
  });

  testWidgets('quitar una fila con el botón de la tabla: sigue habiendo una elegida',
      (t) async {
    final c = (await open(t)).currentTab!.controller;
    for (var n = 1; n <= 3; n++) {
      c.addOrUpdateProductToInvoice(product(n));
    }
    await frames(t);
    // Elegida la última fila (p1) y se quita: debe quedar elegida la que
    // ahora es la última (p2).
    await key(t, LogicalKeyboardKey.arrowDown);
    await key(t, LogicalKeyboardKey.arrowDown);
    c.removeItem(2);
    await frames(t);
    await expectShortcutGoesTo(t, c, 'p2', 'tras quitar la fila elegida');
    await frames(t, 10);
  });

  testWidgets('otra pestaña de factura y volver: cada una con su último elegido',
      (t) async {
    final tabs = await open(t);
    final a = tabs.currentTab!.controller;
    a.addOrUpdateProductToInvoice(product(1));
    a.addOrUpdateProductToInvoice(product(2));
    await frames(t);

    tabs.addNewTab();
    await frames(t);
    final b = tabs.currentTab!.controller;
    expect(identical(a, b), isFalse);
    b.addOrUpdateProductToInvoice(product(7));
    await frames(t);
    await expectShortcutGoesTo(t, b, 'p7', 'pestaña nueva');

    tabs.switchToTab(0);
    await frames(t);
    await expectShortcutGoesTo(t, a, 'p2', 'de vuelta en la primera pestaña');
    a.addOrUpdateProductToInvoice(product(3));
    await frames(t);
    await expectShortcutGoesTo(t, a, 'p3', 'agregar tras volver');
    await frames(t, 10);
  });
}
