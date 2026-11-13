import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}
class _Update extends Mock implements UpdateInvoiceUseCase {}
class _GetById extends Mock implements GetInvoiceByIdUseCase {}

/// Medición de la pantalla real de pestañas de factura: cuánto cuesta abrir
/// otra pestaña y volver, según los productos que tenga la primera.
/// No incluye base local ni red (aquí no existen): mide solo el dibujo.
/// Correr con: flutter test test/perf/invoice_tabs_open_perf_test.dart
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
        name: 'Producto de prueba número $n',
        sku: 'SKU-$n',
        barcode: '77000000$n',
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

  Future<int> frames(WidgetTester tester, {int count = 8}) async {
    // Devuelve el tiempo real (ms) gastado en construir y pintar.
    final watch = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(milliseconds: 400));
    }
    return watch.elapsedMilliseconds;
  }

  for (final items in [0, 20, 60]) {
    testWidgets('medición: $items productos en la primera pestaña', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GetMaterialApp(home: InvoiceFormTabsScreen()));
      await frames(tester);
      final tabs = Get.find<InvoiceTabsController>();

      final first = tabs.tabs.first.controller;
      for (var n = 0; n < items; n++) {
        first.addOrUpdateProductToInvoice(product(n));
      }
      final addMs = await frames(tester);
      expect(first.invoiceItems.length, items);

      var watch = Stopwatch()..start();
      tabs.addNewTab();
      final syncOpenMs = watch.elapsedMilliseconds;
      final openMs = await frames(tester);

      watch = Stopwatch()..start();
      tabs.switchToTab(0);
      final backMs = await frames(tester);

      tabs.switchToTab(1);
      final againMs = await frames(tester);

      // ignore: avoid_print
      print('MEDICION items=$items | pintar productos=${addMs}ms | abrir pestaña: '
          'sincrónico=${syncOpenMs}ms cuadros=${openMs}ms | volver a la 1=${backMs}ms | ir a la 2=${againMs}ms');
      // Tope amplio (es una medición, no un cronómetro fino): abrir una pestaña
      // no debe depender de cuántos productos tenga otra.
      expect(openMs, lessThan(1500));
      await frames(tester, count: 20);
    });
  }
}
