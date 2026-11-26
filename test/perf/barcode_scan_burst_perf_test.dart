// Medición: lectura con el lector de código de barras (pistola USB que
// escribe como teclado: dígitos en ráfaga + Enter) en el buscador de la
// factura REAL, sobre un catálogo grande en una base Isar TEMPORAL (nunca
// la del equipo).
//
//   flutter test test/perf/barcode_scan_burst_perf_test.dart
//   (BAUDEX_PERF_PRODUCTS=20000 por defecto; BAUDEX_SCAN_KEY_MS=10)
//
// Por cada lectura informa: trabajo por tecla (manejadores de teclado +
// cambio de texto, y el cuadro que se dibuja), consultas a la base,
// redibujados y el tiempo desde el Enter hasta que el producto queda en la
// factura. Los tiempos son del hilo de Dart en modo de pruebas (sin la
// tarjeta gráfica): sirven para comparar, no son los de Windows.
import 'dart:async';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/modern_invoice_items_table.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product_price.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_presentation.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_presentations_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../helpers/isar_test_lib.dart';

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

class _Net extends Mock implements NetworkInfo {}

class _Server extends Mock implements ProductRepository {}

class _Presentations extends Mock implements GetProductPresentationsUseCase {}

class _Sync extends Mock implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

/// La base local real, contando cada consulta.
class _CountingRepo extends ProductOfflineRepository {
  _CountingRepo(Isar isar) : super(database: _Db(isar));
  int byBarcode = 0, bySku = 0, byLocalId = 0, contains = 0, codes = 0;

  void reset() => byBarcode = bySku = byLocalId = contains = codes = 0;

  String get summary => 'código exacto: $byBarcode, SKU exacto: $bySku, '
      'por id: $byLocalId, "que contenga": $contains, carga de índice: $codes';

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) {
    byBarcode++;
    return super.getProductByBarcode(barcode);
  }

  @override
  Future<Either<Failure, Product>> getProductBySku(String sku) {
    bySku++;
    return super.getProductBySku(sku);
  }

  @override
  Future<Product?> getProductByLocalId(int localId) {
    byLocalId++;
    return super.getProductByLocalId(localId);
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String searchTerm, {
    int? limit,
  }) {
    contains++;
    return super.searchProducts(searchTerm, limit: limit);
  }

  @override
  Future<List<(String?, int)>> activeProductCodes() {
    codes++;
    return super.activeProductCodes();
  }
}

String codeOf(int i) => '770${i.toString().padLeft(10, '0')}';

IsarProduct _product(int i, {String? sku, String? barcode, bool noBarcode = false}) =>
    (IsarProduct.create(
      serverId: 'p$i',
      name: 'PRODUCTO DE PRUEBA NUMERO $i PRESENTACION ${i % 7}00 GR',
      description: 'Descripcion del producto $i',
      sku: sku ?? 'SKU-${100000 + i}',
      barcode: noBarcode ? null : (barcode ?? codeOf(i)),
      type: IsarProductType.product,
      status: IsarProductStatus.active,
      stock: 5000,
      minStock: 0,
      categoryId: 'c',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isSynced: true,
      taxCategory: IsarTaxCategory.noGravado,
      taxRate: 0,
      isTaxable: false,
      hasRetention: false,
      prices: [
        IsarProductPrice.create(
          serverId: 'pr$i',
          type: IsarPriceType.price1,
          amount: 1000.0 + i,
          currency: 'COP',
          status: IsarPriceStatus.active,
          discountPercentage: 0,
          minQuantity: 1,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    ))
      ..id = i + 1;

/// Tiempos de una lectura.
class ScanTiming {
  final List<double> handlerMs = []; // teclas + texto (síncrono)
  final List<double> frameMs = []; // cuadro dibujado tras la tecla
  double enterHandlerMs = 0;
  double enterToDoneMs = 0; // Enter → producto en la factura (o aviso)
  int polls = 0;
}

double _avg(Iterable<double> v) =>
    v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
double _max(Iterable<double> v) =>
    v.isEmpty ? 0 : v.reduce((a, b) => a > b ? a : b);
String _f(double v) => v.toStringAsFixed(2);

void main() {
  final total =
      int.tryParse(Platform.environment['BAUDEX_PERF_PRODUCTS'] ?? '') ?? 20000;
  final keyMs =
      int.tryParse(Platform.environment['BAUDEX_SCAN_KEY_MS'] ?? '') ?? 10;

  // Códigos especiales (fuera del rango normal).
  const duplicated = '7709990000001'; // en 3 productos
  const onlyInSku = '7708880000001'; // guardado como SKU, sin código de barras
  const missing = '7701234567890';

  late Isar isar;
  late _CountingRepo repo;
  var catalogComplete = true;
  var online = false;
  var serverCalls = 0;
  var presentationCalls = 0;

  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initIsarForTests();
    final dir = await Directory.systemTemp.createTemp('isar_scan_burst');
    isar = await Isar.open(
      IsarDatabase.schemas,
      directory: dir.path,
      maxSizeMiB: 2048,
    );
    IsarDatabase.debugSetDatabase(isar);
    for (var from = 0; from < total; from += 5000) {
      await isar.writeTxn(() => isar.isarProducts.putAll([
            for (var i = from; i < from + 5000 && i < total; i++) _product(i),
          ]));
    }
    await isar.writeTxn(() => isar.isarProducts.putAll([
          for (var k = 0; k < 3; k++)
            _product(total + 10 + k, barcode: duplicated),
          _product(total + 20, sku: onlyInSku, noBarcode: true),
        ]));
    repo = _CountingRepo(isar);
  });

  setUp(() {
    Get.testMode = true;
    resetLocalCollectionsReady();
    catalogComplete = true;
    online = false;
    serverCalls = 0;
    presentationCalls = 0;
    repo.reset();
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
    Get.put<ProductOfflineRepository>(repo);

    final sync = _Sync();
    when(() => sync.isModuleDownloaded(any()))
        .thenAnswer((_) async => catalogComplete);
    when(() => sync.hasPendingFullDownload).thenReturn(false);
    Get.put<FullSyncService>(sync);

    final net = _Net();
    when(() => net.isConnected).thenAnswer((_) async => online);
    Get.put<NetworkInfo>(net);

    // Servidor de mentiras: 800 ms y sin resultados.
    final server = _Server();
    when(() => server.searchProducts(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async {
      serverCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return const Right(<Product>[]);
    });
    Get.put<ProductRepository>(server);

    final presentations = _Presentations();
    when(() => presentations.call(any())).thenAnswer((_) async {
      presentationCalls++;
      return const Right(<ProductPresentation>[]);
    });
    Get.put<GetProductPresentationsUseCase>(presentations);
  });

  setUpAll(() {
    registerFallbackValue(
        const GetProductPresentationsParams(productId: 'x'));
  });

  tearDown(Get.reset);

  /// Deja pasar tiempo REAL (la base responde) y lo mismo de tiempo de la
  /// app (pausas y temporizadores del buscador), y dibuja un cuadro.
  Future<double> step(WidgetTester t, int ms) async {
    if (ms > 0) {
      await t.runAsync(
          () => Future<void>.delayed(Duration(milliseconds: ms)));
    }
    final w = Stopwatch()..start();
    await t.pump(Duration(milliseconds: ms));
    return w.elapsedMicroseconds / 1000;
  }

  Future<void> settle(WidgetTester t, [int rounds = 20]) async {
    for (var i = 0; i < rounds; i++) {
      await step(t, 20);
    }
  }

  Future<InvoiceFormController> open(WidgetTester t, {int lines = 0}) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const GetMaterialApp(home: InvoiceFormTabsScreen()));
    await settle(t, 40);
    final c = Get.find<InvoiceTabsController>().currentTab!.controller;
    for (var n = 0; n < lines; n++) {
      final p = await t.runAsync(() => repo.getProductByBarcode(codeOf(15000 + n)));
      c.addOrUpdateProductToInvoice(p!.getOrElse(() => throw 'sin producto'));
    }
    await settle(t, 10);
    await t.tap(find.descendant(
        of: find.byType(ProductSearchWidget), matching: find.byType(TextField)));
    await settle(t, 30);
    // El índice de códigos cortos se carga al primer valor: calentarlo.
    await t.runAsync(() => c.refreshShortCodeIndex());
    await settle(t, 10);
    return c;
  }

  String fieldText(WidgetTester t) => t
      .widget<EditableText>(find.descendant(
          of: find.byType(ProductSearchWidget),
          matching: find.byType(EditableText)))
      .controller
      .text;

  double qty(InvoiceFormController c) =>
      c.invoiceItems.fold<double>(0, (s, i) => s + i.quantity);

  /// Teclas del lector: KeyDown + texto + KeyUp por dígito, [gapMs] entre
  /// teclas. No espera nada después del Enter.
  Future<ScanTiming> typeBurst(
    WidgetTester t,
    String code, {
    int? gapMs,
    bool enter = true,
    String prefix = '',
  }) async {
    final gap = gapMs ?? keyMs;
    final timing = ScanTiming();
    for (var i = 1; i <= code.length; i++) {
      final ch = code[i - 1];
      final digit = int.tryParse(ch);
      final key = digit != null
          ? LogicalKeyboardKey(0x30 + digit)
          : LogicalKeyboardKey(ch.toLowerCase().codeUnitAt(0));
      final w = Stopwatch()..start();
      // Como en Windows: solo si la app no consume la tecla, el sistema
      // escribe el carácter en la caja.
      final consumed = await t.sendKeyDownEvent(key, character: ch);
      if (!consumed) {
        final text = fieldText(t) + ch;
        t.testTextInput.updateEditingValue(TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ));
      }
      await t.sendKeyUpEvent(key);
      timing.handlerMs.add(w.elapsedMicroseconds / 1000);
      timing.frameMs.add(await step(t, gap));
    }
    if (enter) {
      final w = Stopwatch()..start();
      final consumed = await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
      if (!consumed) await t.testTextInput.receiveAction(TextInputAction.done);
      await t.sendKeyUpEvent(LogicalKeyboardKey.enter);
      timing.enterHandlerMs = w.elapsedMicroseconds / 1000;
    }
    return timing;
  }

  /// Lectura completa: ráfaga + Enter y espera (real) hasta [done].
  Future<ScanTiming> scan(
    WidgetTester t,
    String code, {
    required bool Function() done,
    int? gapMs,
    int timeoutMs = 6000,
  }) async {
    final timing = await typeBurst(t, code, gapMs: gapMs);
    final w = Stopwatch()..start();
    while (!done() && w.elapsedMilliseconds < timeoutMs) {
      timing.polls++;
      await step(t, 1);
    }
    timing.enterToDoneMs = w.elapsedMicroseconds / 1000;
    return timing;
  }

  Future<Map<String, int>> countRebuilds(
      Future<void> Function() action) async {
    final counts = <String, int>{};
    debugOnRebuildDirtyWidget = (e, _) {
      final type = e.widget.runtimeType.toString();
      counts[type] = (counts[type] ?? 0) + 1;
    };
    try {
      await action();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    return counts;
  }

  String rebuildLine(Map<String, int> c, int scans) {
    int n(Type t) => c['$t'] ?? 0;
    final all = c.values.fold<int>(0, (s, v) => s + v);
    final top = (c.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(6)
        .map((e) => '${e.key}×${e.value}')
        .join(', ');
    return 'redibujados en $scans lectura(s): buscador ${n(ProductSearchWidget)}, '
        'pantalla ${n(InvoiceFormScreen)}, tabla ${n(ModernInvoiceItemsTable)}, '
        'Obx ${n(Obx)}, total $all [$top]';
  }

  void report(String label, List<ScanTiming> scans, {String extra = ''}) {
    final value = <double>[], valueFrame = <double>[];
    final rest = <double>[], restFrame = <double>[];
    for (final s in scans) {
      for (var i = 0; i < s.handlerMs.length; i++) {
        (i < 7 ? value : rest).add(s.handlerMs[i]);
        (i < 7 ? valueFrame : restFrame).add(s.frameMs[i]);
      }
    }
    // ignore: avoid_print
    print('MEDICION [$label] $total productos, ${scans.length} lectura(s), '
        '$keyMs ms entre teclas\n'
        '  teclas 1-7 (se leen como "valor"): manejadores ${_f(_avg(value))} ms '
        '(peor ${_f(_max(value))}), cuadro ${_f(_avg(valueFrame))} ms (peor ${_f(_max(valueFrame))})\n'
        '  teclas 8+ (ya es código): manejadores ${_f(_avg(rest))} ms '
        '(peor ${_f(_max(rest))}), cuadro ${_f(_avg(restFrame))} ms (peor ${_f(_max(restFrame))})\n'
        '  Enter: manejadores ${_f(_avg(scans.map((s) => s.enterHandlerMs)))} ms; '
        'Enter → resultado ${_f(_avg(scans.map((s) => s.enterToDoneMs)))} ms '
        '(peor ${_f(_max(scans.map((s) => s.enterToDoneMs)))})\n'
        '  consultas: ${repo.summary}; servidor: $serverCalls; presentaciones: $presentationCalls'
        '${extra.isEmpty ? '' : '\n  $extra'}');
  }

  Future<void> close(WidgetTester t) async {
    await settle(t, 30);
    await t.pumpWidget(const SizedBox());
    Get.reset();
    // Reintentos de la impresora y del índice (5-15 s): dejarlos vencer.
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 15));
    }
  }

  const timeout = Timeout(Duration(minutes: 5));

  for (final lines in const [0, 60]) {
    testWidgets('lectura de 13 dígitos + Enter, factura con $lines líneas',
        (t) async {
      final c = await open(t, lines: lines);
      // Calentar (no se cuenta).
      var before = qty(c);
      await scan(t, codeOf(1), done: () => qty(c) > before);
      await settle(t);
      repo.reset();
      presentationCalls = 0;

      final scans = <ScanTiming>[];
      final counts = await countRebuilds(() async {
        for (var n = 0; n < 5; n++) {
          before = qty(c);
          scans.add(await scan(t, codeOf(100 + n * 37),
              done: () => qty(c) > before));
          expect(qty(c), before + 1);
          await settle(t, 15); // ~300 ms entre lecturas
        }
      });
      expect(fieldText(t), isEmpty);
      report('existe, $lines líneas', scans, extra: rebuildLine(counts, 5));
      await close(t);
    }, timeout: timeout);
  }

  testWidgets('desglose: qué se redibuja en cada tecla de una lectura',
      (t) async {
    final c = await open(t);
    var before = qty(c);
    await scan(t, codeOf(1), done: () => qty(c) > before);
    await settle(t);
    before = qty(c);
    final code = codeOf(321);
    // Cuadros SIN tecla (pantalla quieta): ¿se repinta algo de todos modos?
    await settle(t, 150); // 3 s: que terminen los resaltados de la tabla
    final idlePaints = <int>[];
    final idleScheduled = <bool>[];
    for (var k = 0; k < 4; k++) {
      var n = 0;
      debugOnProfilePaint = (_) => n++;
      idleScheduled.add(t.binding.hasScheduledFrame);
      await step(t, 16);
      debugOnProfilePaint = null;
      idlePaints.add(n);
    }
    final perKey = <int>[];
    final perKeyMs = <double>[];
    final perKeyPaints = <int>[];
    final firstPainted = <String>[];
    final types = <int, Map<String, int>>{};
    for (var i = 1; i <= code.length; i++) {
      var paints = 0;
      var lastDepth = 1 << 30;
      debugOnProfilePaint = (o) {
        // Cada vez que la profundidad baja de golpe empieza otra capa.
        if (i == 9 && o.depth < lastDepth - 3 && firstPainted.length < 12) {
          firstPainted.add('\n      #$paints ${o.runtimeType}@${o.depth} '
              '${'${o.debugCreator}'.split(' ← ').take(6).join(' ← ')}');
        }
        lastDepth = o.depth;
        paints++;
      };
      final counts = await countRebuilds(() async {
        final s = await typeBurst(t, code.substring(i - 1, i),
            enter: false, prefix: code.substring(0, i - 1));
        perKeyMs.add(s.handlerMs.single + s.frameMs.single);
      });
      debugOnProfilePaint = null;
      perKeyPaints.add(paints);
      perKey.add(counts.values.fold<int>(0, (a, b) => a + b));
      types[i] = counts;
    }
    String top(Map<String, int> m) =>
        (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(8)
            .map((e) => '${e.key}×${e.value}')
            .join(', ');
    final enterCounts = await countRebuilds(() async {
      await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.sendKeyUpEvent(LogicalKeyboardKey.enter);
      while (qty(c) == before) {
        await step(t, 1);
      }
      await settle(t, 5);
    });
    // ignore: avoid_print
    print('MEDICION [desglose por tecla] redibujados por tecla: $perKey\n'
        '  objetos repintados por tecla: $perKeyPaints\n'
        '  pantalla quieta (sin teclas): repintados por cuadro $idlePaints, cuadro pedido: $idleScheduled\n'
        '  primeros repintados (tecla 9): $firstPainted; caja: ${t.getSize(find.descendant(of: find.byType(ProductSearchWidget), matching: find.byType(TextField)))}\n'
        '  ms por tecla (manejadores + cuadro): ${perKeyMs.map(_f).toList()}\n'
        '  tecla 1: ${top(types[1]!)}\n'
        '  tecla 4: ${top(types[4]!)}\n'
        '  tecla 8: ${top(types[8]!)}\n'
        '  tecla 12: ${top(types[12]!)}\n'
        '  Enter + agregar: ${enterCounts.values.fold<int>(0, (a, b) => a + b)} → ${top(enterCounts)}');
    await close(t);
  }, timeout: timeout);

  testWidgets('texto a mano (referencia): "producto" tecla a tecla', (t) async {
    await open(t);
    final typed = await typeBurst(t, 'producto', gapMs: 120, enter: false);
    await settle(t, 30);
    // ignore: avoid_print
    print('MEDICION [referencia texto a mano] por tecla: manejadores '
        '${_f(_avg(typed.handlerMs))} ms (peor ${_f(_max(typed.handlerMs))}), '
        'cuadro ${_f(_avg(typed.frameMs))} ms (peor ${_f(_max(typed.frameMs))}); '
        'consultas: ${repo.summary}');
    await close(t);
  }, timeout: timeout);

  testWidgets('20 lecturas pegadas (sin pausa entre una y otra)', (t) async {
    final c = await open(t);
    var before = qty(c);
    await scan(t, codeOf(1), done: () => qty(c) > before);
    await settle(t);
    repo.reset();
    presentationCalls = 0;
    before = qty(c);
    final rows = c.invoiceItems.length;

    final w = Stopwatch()..start();
    final scans = <ScanTiming>[];
    for (var n = 0; n < 20; n++) {
      scans.add(await typeBurst(t, codeOf(2000 + n), gapMs: 5));
      await step(t, 5); // 5 ms y ya entra el siguiente código
    }
    final typedMs = w.elapsedMilliseconds;
    while (qty(c) < before + 20 && w.elapsedMilliseconds < 20000) {
      await step(t, 1);
    }
    final doneMs = w.elapsedMilliseconds;
    await settle(t);
    expect(qty(c), before + 20, reason: 'ninguna lectura se pierde');
    expect(c.invoiceItems.length, rows + 20, reason: 'ninguna se pega a otra');
    report('20 pegadas, 5 ms entre teclas', scans,
        extra: 'las 20 tecleadas en $typedMs ms; las 20 en la factura a los $doneMs ms; '
            'caja al final: "${fieldText(t)}"');
    await close(t);
  }, timeout: timeout);

  testWidgets('código que no existe (catálogo completo en el equipo)', (t) async {
    final c = await open(t);
    final before = qty(c);
    final scans = <ScanTiming>[];
    final counts = await countRebuilds(() async {
      scans.add(await scan(t, missing, done: () => fieldText(t) == missing));
    });
    await settle(t);
    expect(qty(c), before);
    expect(fieldText(t), missing, reason: 'queda escrito y seleccionado para corregir');
    report('no existe, catálogo completo', scans, extra: rebuildLine(counts, 1));
    await close(t);
  }, timeout: timeout);

  testWidgets('código que no existe con el catálogo SIN terminar de bajar',
      (t) async {
    for (final withNet in const [false, true]) {
      catalogComplete = false;
      online = withNet;
      resetLocalCollectionsReady();
      final c = await open(t);
      repo.reset();
      serverCalls = 0;
      final before = qty(c);
      final s = await scan(t, missing, done: () => fieldText(t) == missing);
      await settle(t);
      expect(qty(c), before);
      report('no existe, catálogo bajando, ${withNet ? 'con' : 'sin'} internet', [s]);

      // Y uno que SÍ existe, en el mismo estado.
      repo.reset();
      serverCalls = 0;
      // Borrar lo que quedó escrito.
      t.testTextInput.updateEditingValue(TextEditingValue.empty);
      await settle(t, 5);
      final s2 = await scan(t, codeOf(4242), done: () => qty(c) > before);
      expect(qty(c), before + 1);
      report('existe, catálogo bajando, ${withNet ? 'con' : 'sin'} internet', [s2]);
      await settle(t, 30);
      await t.pumpWidget(const SizedBox());
      Get.delete<InvoiceTabsController>(force: true);
      await t.pump(const Duration(seconds: 15));
    }
    await close(t);
  }, timeout: timeout);

  testWidgets('código repetido en 3 productos', (t) async {
    final c = await open(t);
    final before = qty(c);
    final s = await scan(t, duplicated, done: () => qty(c) > before);
    await settle(t);
    expect(qty(c), before + 1);
    report('repetido en 3 productos', [s],
        extra: 'se agregó sin preguntar: ${c.invoiceItems.first.description} '
            '(el primero que devuelve la base)');
    await close(t);
  }, timeout: timeout);

  testWidgets('código guardado como SKU (sin código de barras)', (t) async {
    final c = await open(t);
    final before = qty(c);
    final s = await scan(t, onlyInSku,
        done: () => qty(c) > before || fieldText(t) == onlyInSku,
        timeoutMs: 3000);
    await settle(t);
    expect(qty(c), before + 1, reason: 'el lector lo encuentra por el SKU exacto');
    report('guardado solo como SKU', [s],
        extra: 'ENCONTRADO: ${c.invoiceItems.first.description}');
    await close(t);
  }, timeout: timeout);

  testWidgets('catálogo bajando y con internet: una lectura que no está en el '
      'equipo no frena la siguiente', (t) async {
    catalogComplete = false;
    online = true;
    resetLocalCollectionsReady();
    final c = await open(t);
    repo.reset();
    serverCalls = 0;
    final before = qty(c);
    await typeBurst(t, missing); // Enter y, sin esperar, el siguiente código
    final next = await scan(t, codeOf(4343), done: () => qty(c) > before);
    expect(qty(c), before + 1);
    expect(fieldText(t), isNot(missing),
        reason: 'el servidor todavía no ha respondido por la primera');
    report('existe, leída justo después de una que espera al servidor', [next]);
    final w = Stopwatch()..start();
    while (fieldText(t) != missing && w.elapsedMilliseconds < 8000) {
      await step(t, 5);
    }
    expect(serverCalls, 1);
    expect(fieldText(t), missing, reason: 'al final avisa que no existe');
    expect(qty(c), before + 1);
    await close(t);
  }, timeout: timeout);

  testWidgets('lector SIN Enter al final: espera la pausa de tecleo', (t) async {
    final c = await open(t);
    var before = qty(c);
    await scan(t, codeOf(1), done: () => qty(c) > before);
    await settle(t);
    before = qty(c);
    await typeBurst(t, codeOf(777), enter: false);
    var waited = 0;
    while (qty(c) == before && waited < 3000) {
      await step(t, 5);
      waited += 5;
    }
    expect(qty(c), before + 1);
    // ignore: avoid_print
    print('MEDICION [sin Enter] el producto entra $waited ms después de la '
        'última tecla (pausa de tecleo de 300 ms + consulta)');
    await close(t);
  }, timeout: timeout);

  testWidgets('lectura mientras la sincronización escribe productos', (t) async {
    final c = await open(t);
    var before = qty(c);
    await scan(t, codeOf(1), done: () => qty(c) > before);
    await settle(t);
    repo.reset();

    // Tandas de 50 productos, como la descarga; en la zona real.
    var stop = false;
    var batches = 0;
    final writer = Zone.root.run(() async {
      while (!stop) {
        await isar.writeTxn(() => isar.isarProducts.putAll([
              for (var i = 0; i < 50; i++) _product((batches * 50 + i) % total),
            ]));
        batches++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await step(t, 100);

    final scans = <ScanTiming>[];
    for (var n = 0; n < 5; n++) {
      before = qty(c);
      scans.add(await scan(t, codeOf(9000 + n * 11),
          done: () => qty(c) > before));
      expect(qty(c), before + 1);
      await settle(t, 10);
    }
    stop = true;
    await t.runAsync(() => writer);
    report('existe, sincronización escribiendo ($batches tandas)', scans);
    await close(t);
  }, timeout: timeout);
}
