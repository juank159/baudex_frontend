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
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

/// Base local lenta (la sincronización escribiendo con el catálogo completo).
class _SlowLocal extends Mock implements ProductOfflineRepository {}

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

  /// Lector, como en Windows: cada dígito llega primero como tecla; SOLO si
  /// la app no la consume, el sistema la escribe en la caja. Igual el Enter.
  Future<void> scan(WidgetTester t, String code) async {
    final field = find.descendant(
        of: find.byType(ProductSearchWidget), matching: find.byType(EditableText));
    for (var i = 1; i <= code.length; i++) {
      final digit = code[i - 1];
      final key = LogicalKeyboardKey(0x30 + int.parse(digit));
      final consumed = await t.sendKeyDownEvent(key, character: digit);
      if (!consumed) {
        final text = t.widget<EditableText>(field).controller.text + digit;
        t.testTextInput.updateEditingValue(TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ));
      }
      await t.sendKeyUpEvent(key);
      await t.pump(const Duration(milliseconds: 3));
    }
    final consumed = await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
    if (!consumed) await t.testTextInput.receiveAction(TextInputAction.done);
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

  testWidgets('re-escaneos con la base local lenta: cada uno entra en un cuadro',
      (t) async {
    final slow = _SlowLocal();
    var lookups = 0;
    when(() => slow.getProductByBarcode(any())).thenAnswer((inv) async {
      lookups++;
      await Future<void>.delayed(const Duration(seconds: 3));
      final code = inv.positionalArguments.first as String;
      return Right(product(int.parse(code.substring(3))));
    });
    Get.put<ProductOfflineRepository>(slow);
    final tabs = await openWith(t, 0);
    final c = tabs.currentTab!.controller;

    // Primeros escaneos: la base tarda 3 s.
    for (var n = 0; n < 10; n++) {
      await scan(t, product(n).barcode!);
      await t.pump(const Duration(seconds: 3));
    }
    await frames(t);
    expect(c.invoiceItems.length, 10);
    expect(lookups, 10);

    // 100 re-escaneos de los mismos 10: ya no esperan a la base.
    final watch = Stopwatch()..start();
    var slowest = Duration.zero;
    for (var n = 0; n < 100; n++) {
      final p = product(n % 10);
      final before = c.invoiceItems.firstWhere((i) => i.productId == p.id).quantity;
      final w = Stopwatch()..start();
      await scan(t, p.barcode!);
      await t.pump(const Duration(milliseconds: 16));
      if (w.elapsed > slowest) slowest = w.elapsed;
      expect(c.invoiceItems.firstWhere((i) => i.productId == p.id).quantity, before + 1,
          reason: 're-escaneo $n entró sin esperar la base');
    }
    watch.stop();
    expect(lookups, 10, reason: 'los re-escaneos no consultan la base');
    expect(c.invoiceItems.fold<double>(0, (s, i) => s + i.quantity), 110);
    // ignore: avoid_print
    print('re-escaneos: 100 en ${watch.elapsedMilliseconds} ms (peor ${slowest.inMilliseconds} ms)');
    await frames(t, 10);
  });

  testWidgets('el foco cae al ámbito (reconstrucción): la caja lo recupera y el '
      'siguiente escaneo entra', (t) async {
    final tabs = await openWith(t, 0);
    final c = tabs.currentTab!.controller;
    for (var n = 0; n < 5; n++) {
      c.availableProducts.add(product(n));
    }
    final field = find.descendant(
        of: find.byType(ProductSearchWidget), matching: find.byType(EditableText));
    bool hasFocus() => t.widget<EditableText>(field).focusNode.hasFocus;
    for (var round = 0; round < 15; round++) {
      expect(hasFocus(), isTrue, reason: 'vuelta $round');
      // Lo que pasaba: el foco quedaba en el FocusScopeNode (nadie).
      FocusManager.instance.primaryFocus!.unfocus(
          disposition: UnfocusDisposition.scope);
      await t.pump();
      await t.pump();
      expect(hasFocus(), isTrue, reason: 'recuperado en la vuelta $round');
      await scan(t, product(round % 5).barcode!);
      await frames(t, 1);
    }
    expect(c.invoiceItems.fold<double>(0, (s, i) => s + i.quantity), 15);
    await frames(t, 10);
  });

  testWidgets('Ctrl + "+" del teclado español y del numérico suman uno', (t) async {
    final tabs = await openWith(t, 3);
    final c = tabs.currentTab!.controller;
    await ctrl(t, LogicalKeyboardKey.digit1); // selecciona y suma 1
    final i = c.invoiceItems.indexWhere((x) => x.quantity == 2);
    expect(i, isNot(-1));
    // Tecla "+" del teclado español (junto al Enter): manda el carácter "+".
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.add,
        physicalKey: PhysicalKeyboardKey.bracketRight, character: '+');
    await t.sendKeyUpEvent(LogicalKeyboardKey.add,
        physicalKey: PhysicalKeyboardKey.bracketRight);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump(const Duration(milliseconds: 20));
    expect(c.invoiceItems[i].quantity, 3);
    await ctrl(t, LogicalKeyboardKey.numpadAdd);
    expect(c.invoiceItems[i].quantity, 4);
    await ctrl(t, LogicalKeyboardKey.numpadSubtract);
    expect(c.invoiceItems[i].quantity, 3);
    await frames(t, 30);
  });
}
