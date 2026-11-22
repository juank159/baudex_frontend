// Imágenes del buscador de la factura (producto sin registrar) y del aviso
// de impresoras. Solo corre si se indica dónde guardar:
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/venta_rapida_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/printing/system_printer_discovery.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/app/core/theme/futuristic_notifications.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

class _Controller extends Mock implements InvoiceFormController {}

void main() {
  if (_out == null) {
    test('imágenes de venta rápida (omitida: falta BAUDEX_VISUAL_OUT)', () {},
        skip: 'Solo para revisión visual');
    return;
  }

  final boundaryKey = GlobalKey();
  late _Controller controller;

  setUpAll(() async {
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  setUp(() {
    Get.testMode = true;
    controller = _Controller();
    final index = ShortCodeIndex.build(const [], complete: true);
    when(() => controller.shouldValidateStock).thenReturn(false);
    when(() => controller.decideValueEntry(any()))
        .thenAnswer((inv) => decidePriceEntry(inv.positionalArguments.first as String, index));
  });
  tearDown(Get.reset);

  Widget app(Widget body) => RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: Scaffold(
            backgroundColor: ElegantLightTheme.backgroundColor,
            body: Padding(padding: const EdgeInsets.all(24), child: body),
          ),
        ),
      );

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> size(WidgetTester tester, double w, double h) async {
    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final (label, w, h) in [('escritorio', 900.0, 560.0), ('celular', 390.0, 560.0)]) {
    testWidgets('buscador con valor: $label', (tester) async {
      await size(tester, w, h);
      await tester.pumpWidget(app(ProductSearchWidget(
        controller: controller,
        onProductSelected: (_, __) {},
      )));
      await tester.enterText(find.byType(TextField).first, '20000');
      await settle(tester);
      await shot(tester, '1-sin-registrar-$label');

      await tester.tap(find.text('Producto sin registrar'));
      await settle(tester);
      await shot(tester, '2-nombre-$label');
    });
  }

  testWidgets('aviso sin impresoras', (tester) async {
    await size(tester, 900, 400);
    await tester.pumpWidget(app(const SizedBox.expand()));
    final r = await discoverPrinters([
      PrinterSource('wmic', () async => throw const ProcessException('wmic', [])),
    ]);
    FuturisticNotifications.showWarning('Sin impresoras', r.emptyMessage);
    await settle(tester);
    await shot(tester, '3-sin-impresoras');
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
