// Imágenes reales de la factura con muchas líneas tras escanear:
//   BAUDEX_VISUAL_OUT=/ruta flutter test test/visual/estres_factura_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/config/themes/app_theme.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _sizes = {'escritorio': Size(1280, 760), 'celular': Size(390, 844)};
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

void main() {
  if (_out == null) {
    test('imágenes de la factura (omitida: falta BAUDEX_VISUAL_OUT)', () {},
        skip: 'Solo para revisión visual');
    return;
  }
  final boundaryKey = GlobalKey();

  setUpAll(() async {
    tzdata.initializeTimeZones();
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
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
  });
  tearDown(Get.reset);

  Product product(int n, {double stock = 500}) => Product(
        id: 'p$n',
        name: ['Arroz Diana 500 g', 'Aceite Premier 1 L', 'Leche Alpina 1 L',
            'Huevos AA x 30', 'Café Sello Rojo 250 g'][n % 5] + (n >= 5 ? ' #$n' : ''),
        sku: 'SKU-$n',
        barcode: '770${n.toString().padLeft(10, '0')}',
        type: ProductType.product,
        status: ProductStatus.active,
        stock: stock,
        minStock: 0,
        categoryId: 'c',
        createdById: 'u',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        prices: [
          ProductPrice(
            id: 'pr$n',
            type: PriceType.price1,
            amount: 2500.0 + n * 150,
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

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() async {
      final b = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> frames(WidgetTester t, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  for (final size in _sizes.entries) {
    testWidgets('factura con 40 líneas tras re-escanear (${size.key})', (t) async {
      t.view.physicalSize = size.value;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          // Título de la barra con la fuente cargada en la prueba (el tema
          // global no se toca).
          theme: AppTheme.lightTheme.copyWith(
            appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
              titleTextStyle:
                  (AppTheme.lightTheme.appBarTheme.titleTextStyle ?? const TextStyle())
                      .copyWith(fontFamily: 'Roboto'),
            ),
          ),
          home: const InvoiceFormTabsScreen(),
        ),
      ));
      await frames(t);
      final c = Get.find<InvoiceTabsController>().currentTab!.controller;
      for (var n = 0; n < 40; n++) {
        c.addOrUpdateProductToInvoice(product(n));
      }
      await frames(t, 3);
      await shot(t, 'factura-${size.key}-v4');
      // Re-escaneo de una fila del medio (la 20): debe quedar a la vista y
      // resaltada, sin aviso flotante.
      c.addOrUpdateProductToInvoice(product(20));
      c.addOrUpdateProductToInvoice(product(20));
      await frames(t, 4);
      await shot(t, 'factura-reescaneo-fila20-${size.key}-v4');
      // Producto sin unidades: aviso con el tema (FuturisticNotifications).
      c.addOrUpdateProductToInvoice(product(99, stock: 0));
      await frames(t, 3);
      await shot(t, 'aviso-sin-stock-${size.key}-v4');
      await frames(t, 50);
    });
  }
}
