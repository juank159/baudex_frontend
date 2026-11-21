import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/customer_selector_widget.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen.dart';
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

/// Punto de venta con muchas líneas, lector de código de barras (teclas
/// rapidísimas + Enter) y atajos Ctrl+número. Lo que el cajero sentía lento:
/// cada escaneo y cada atajo redibujaba la pantalla entera (cliente, buscador,
/// tabla y totales) y cada escaneo repetido dejaba un aviso en cola (2,4 s
/// cada uno, con animación continua).
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

  Product product(int n) => Product(
        id: 'p$n',
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
            productId: 'p$n',
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

  /// Lector: cada dígito llega como tecla (KeyDown/KeyUp) y como texto; al
  /// final, Enter.
  Future<void> scan(WidgetTester t, String code) async {
    for (var i = 1; i <= code.length; i++) {
      final key = LogicalKeyboardKey(0x30 + int.parse(code[i - 1]));
      await t.sendKeyDownEvent(key);
      t.testTextInput.updateEditingValue(TextEditingValue(
        text: code.substring(0, i),
        selection: TextSelection.collapsed(offset: i),
      ));
      await t.sendKeyUpEvent(key);
      await t.pump(const Duration(milliseconds: 3));
    }
    await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await t.pump(const Duration(milliseconds: 20));
  }

  Future<void> ctrl(WidgetTester t, LogicalKeyboardKey key) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(key);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump(const Duration(milliseconds: 20));
  }

  /// Cuenta cuántas veces se redibuja cada parte durante [action].
  Future<Map<Type, int>> rebuilds(WidgetTester t, Future<void> Function() action) async {
    final counts = <Type, int>{};
    debugOnRebuildDirtyWidget = (e, _) {
      final type = e.widget.runtimeType;
      counts[type] = (counts[type] ?? 0) + 1;
    };
    try {
      await action();
      await frames(t, 3);
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    return counts;
  }

  Future<InvoiceTabsController> openWith(WidgetTester t, int lines) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const GetMaterialApp(home: InvoiceFormTabsScreen()));
    await frames(t);
    final tabs = Get.find<InvoiceTabsController>();
    final c = tabs.currentTab!.controller;
    for (var n = 0; n < lines; n++) {
      c.addOrUpdateProductToInvoice(product(n));
    }
    await frames(t);
    await t.tap(find.descendant(
        of: find.byType(ProductSearchWidget), matching: find.byType(TextField)));
    await frames(t, 2);
    return tabs;
  }

  testWidgets('60 líneas: un atajo Ctrl+1 solo redibuja la tabla y los totales',
      (t) async {
    final tabs = await openWith(t, 60);
    final c = tabs.currentTab!.controller;
    final before = c.invoiceItems.first.quantity;

    final counts = await rebuilds(t, () => ctrl(t, LogicalKeyboardKey.digit1));

    expect(c.invoiceItems.first.quantity, before + 1, reason: 'el atajo sí suma');
    expect(counts[InvoiceFormScreen] ?? 0, 0, reason: 'no redibuja la pantalla entera');
    expect(counts[CustomerSelectorWidget] ?? 0, 0, reason: 'el cliente no cambió');
    expect(counts[ProductSearchWidget] ?? 0, 0, reason: 'el buscador no cambió');
    await frames(t, 10);
  });

  testWidgets('60 líneas: escanear un producto ya agregado no redibuja la pantalla '
      'ni deja avisos en cola, y Ctrl+2 suma a ESE producto', (t) async {
    final tabs = await openWith(t, 60);
    final c = tabs.currentTab!.controller;
    // El producto 5 quedó en la posición 54 (los nuevos entran arriba).
    final index = c.invoiceItems.indexWhere((i) => i.productId == 'p5');

    final counts = await rebuilds(t, () => scan(t, product(5).barcode!));

    expect(c.invoiceItems[index].quantity, 2);
    expect(c.invoiceItems.length, 60);
    expect(counts[InvoiceFormScreen] ?? 0, 0, reason: 'no redibuja la pantalla entera');
    expect(counts[CustomerSelectorWidget] ?? 0, 0);
    expect(Get.isSnackbarOpen, isFalse, reason: 'la fila resaltada ya avisa; sin cola de avisos');

    await ctrl(t, LogicalKeyboardKey.digit2);
    expect(c.invoiceItems[index].quantity, 4, reason: 'el atajo va al último producto escaneado');
    await frames(t, 10);
  });

  testWidgets('ráfaga: 70 escaneos seguidos (nuevos y repetidos) no pierden ni duplican',
      (t) async {
    final tabs = await openWith(t, 0);
    final c = tabs.currentTab!.controller;
    for (var n = 0; n < 60; n++) {
      c.availableProducts.add(product(n));
    }
    for (var n = 0; n < 70; n++) {
      await scan(t, product(n % 60).barcode!);
    }
    await frames(t, 10);

    expect(c.invoiceItems.length, 60);
    final total = c.invoiceItems.fold<double>(0, (s, i) => s + i.quantity);
    expect(total, 70);
    expect(Get.isSnackbarOpen, isFalse);
    await frames(t, 10);
  });
}
