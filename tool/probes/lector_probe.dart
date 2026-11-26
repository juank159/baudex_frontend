// tool/probes/lector_probe.dart
//
// Sonda del lector de código de barras: abre el formulario de factura REAL
// sobre un catálogo sembrado en una base Isar TEMPORAL (nunca la del
// equipo), le manda teclas como las del lector y anota, con el reloj del
// motor, lo que de verdad pasa:
//
//   - cuándo llega cada tecla a la app (KeyEvent),
//   - cuándo el texto de la caja alcanza cada longitud,
//   - qué texto mostraba cada cuadro dibujado y cuánto tardó en armarse
//     (hilo de la app) y en pintarse (tarjeta gráfica),
//   - cuándo la línea queda en la factura y cuándo se VE.
//
// La usan:
//   - tool/probes/lector_windows_probe.dart: app de Windows que inyecta
//     teclas de verdad al sistema (SendInput);
//   - test/windows/lector_probe_smoke_test.dart: la misma sonda con teclas
//     simuladas, para comprobar aquí que la sonda funciona.
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product_price.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_presentation.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_presentations_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Reloj del motor en microsegundos (el mismo de los tiempos de cuadro).
int probeNow() => developer.Timeline.now;

/// Quien manda las teclas (el sistema en Windows; simuladas en pruebas).
abstract class KeyInjector {
  String get name;

  /// Deja la ventana lista para recibir teclas. Devuelve una nota para el
  /// informe (o `null`).
  Future<String?> prepare();

  /// Manda [digits] con [gapMs] entre teclas y, si [enter], Enter al final.
  Future<void> type(String digits, {required int gapMs, bool enter = true});

  /// Borra [count] caracteres (tecla Retroceso).
  Future<void> backspace(int count);
}

class LectorProbeConfig {
  const LectorProbeConfig({
    this.products = 3000,
    this.existingLines = 0,
    this.scans = 10,
    this.keyGapMs = 1,
    this.humanGapMs = 120,
    this.maxTextMs = 150,
    this.maxLineMs = 0,
    this.label = '',
  });

  /// Productos del catálogo de prueba.
  final int products;

  /// Líneas ya puestas en la factura antes de medir.
  final int existingLines;

  /// Lecturas por escenario.
  final int scans;

  /// Milisegundos entre teclas del lector.
  final int keyGapMs;

  /// Milisegundos entre teclas de una persona.
  final int humanGapMs;

  /// Falla si, en lo normal (mediana), el código tarda más que esto en
  /// estar completo desde la primera tecla.
  final int maxTextMs;

  /// Falla si, en lo normal, la línea tarda más que esto en VERSE desde el
  /// Enter (0 = no revisar).
  final int maxLineMs;

  final String label;
}

class LectorProbeResult {
  LectorProbeResult(this.lines, this.failures);
  final List<String> lines;
  final List<String> failures;
  bool get ok => failures.isEmpty;
  String get text => lines.join('\n');
}

// ───────────────────────── datos de prueba ─────────────────────────

String probeCode(int i) => '770${i.toString().padLeft(10, '0')}';

IsarProduct _product(int i) => (IsarProduct.create(
      serverId: 'p$i',
      name: 'PRODUCTO DE PRUEBA NUMERO $i PRESENTACION ${i % 7}00 GR',
      description: 'Descripcion del producto $i',
      sku: 'SKU-${100000 + i}',
      barcode: probeCode(i),
      type: IsarProductType.product,
      status: IsarProductStatus.active,
      stock: 50000,
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

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

// Servicios de relleno (sin servidor): la sonda mide el buscador, no la red.
class _Create implements CreateInvoiceUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Update implements UpdateInvoiceUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GetById implements GetInvoiceByIdUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Net implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Catálogo completo en el equipo (descarga terminada).
class _Sync implements FullSyncService {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
  @override
  Future<bool> isModuleDownloaded(String entity) async => true;
  @override
  bool get hasPendingFullDownload => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Presentations implements GetProductPresentationsUseCase {
  @override
  Future<Either<Failure, List<ProductPresentation>>> call(
    GetProductPresentationsParams params,
  ) async =>
      const Right(<ProductPresentation>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ───────────────────────── registro ─────────────────────────

class _Frame {
  _Frame(this.number, this.builtAt, this.textLength, this.units, this.card);
  final int number;

  /// ¿Este cuadro mostraba la tarjeta "Producto sin registrar"?
  final bool card;
  final int builtAt; // µs, fin del trabajo del hilo de la app
  final int textLength;
  final double units;
  double? buildMs;
  double? rasterMs;
  int? rasterFinish; // µs, ya está en pantalla
}

class _Recorder {
  final List<int> keyDowns = [];
  final List<int> enterDowns = [];
  final List<(int, int)> textChanges = []; // (µs, longitud)
  final List<(int, double)> unitChanges = []; // (µs, unidades)
  final List<_Frame> frames = [];
  final Map<int, _Frame> _byNumber = {};

  TextEditingController? field;
  double Function()? units;
  bool Function()? card;

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final t = probeNow();
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        enterDowns.add(t);
      } else {
        keyDowns.add(t);
      }
    }
    return false;
  }

  void _onText() => textChanges.add((probeNow(), field!.text.length));

  void _onFrame(Duration _) {
    final number = ui.PlatformDispatcher.instance.frameData.frameNumber;
    final frame = _Frame(
      number,
      probeNow(),
      field?.text.length ?? 0,
      units?.call() ?? 0,
      card?.call() ?? false,
    );
    frames.add(frame);
    _byNumber[number] = frame;
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    for (final t in timings) {
      final frame = _byNumber[t.frameNumber];
      if (frame == null) continue;
      frame.buildMs = t.buildDuration.inMicroseconds / 1000;
      frame.rasterMs = t.rasterDuration.inMicroseconds / 1000;
      frame.rasterFinish =
          t.timestampInMicroseconds(ui.FramePhase.rasterFinish);
    }
  }

  void start() {
    HardwareKeyboard.instance.addHandler(_onKey);
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void attachField(TextEditingController controller) {
    field = controller;
    controller.addListener(_onText);
  }
}

double _ms(int fromUs, int toUs) => (toUs - fromUs) / 1000;

String _f(double? v) => v == null ? '  n/d' : v.toStringAsFixed(1).padLeft(7);

double? _median(Iterable<double?> values) {
  final v = [for (final x in values) if (x != null) x]..sort();
  return v.isEmpty ? null : v[(v.length - 1) ~/ 2];
}

double? _max(Iterable<double?> values) {
  final v = [for (final x in values) if (x != null) x];
  return v.isEmpty ? null : v.reduce((a, b) => a > b ? a : b);
}

/// Lo que pasó en una lectura.
class _Scan {
  String code = '';
  int keys = 0;
  double? keysMs; // primera tecla → última tecla (llegada a la app)
  double? textMs; // primera tecla → texto completo en la caja
  double? enterMs; // primera tecla → Enter (llegada a la app)
  int framesToEnter = 0; // cuadros entre la primera tecla y el Enter
  List<int> seenLengths = []; // longitudes que alcanzó a mostrar la pantalla
  int cardFrames = 0; // cuadros que mostraron "Producto sin registrar"
  bool get sawPartial => seenLengths.any((l) => l < code.length);
  double? lineMs; // Enter → línea en la factura (datos)
  double? lineSeenMs; // Enter → línea VISIBLE (cuadro pintado)
  double? totalSeenMs; // primera tecla → línea VISIBLE
  double? lineBuildMs; // armar el cuadro de la línea
  double? lineRasterMs; // pintarlo
  int framesTotal = 0; // cuadros de la primera tecla a la línea visible
  double? worstBuildMs;
  double? worstRasterMs;
  bool added = false;
}

// ───────────────────────── la sonda ─────────────────────────

/// Corre la sonda. [mount] pone la app en pantalla (`runApp` en la app,
/// `pumpWidget` en la prueba). [log] recibe cada línea en cuanto sale.
Future<LectorProbeResult> runLectorProbe({
  required Future<void> Function(Widget app) mount,
  required KeyInjector injector,
  LectorProbeConfig config = const LectorProbeConfig(),
  void Function(String line)? log,
  String? isarLibrary,
}) async {
  final lines = <String>[];
  final failures = <String>[];
  void out(String line) {
    lines.add(line);
    log?.call(line);
  }

  final recorder = _Recorder();
  Isar? isar;
  Directory? dir;
  try {
    // ── Base temporal y servicios ──
    tzdata.initializeTimeZones();
    dir = await Directory.systemTemp.createTemp('baudex_lector_probe');
    if (isarLibrary != null) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): isarLibrary});
    }
    isar = await Isar.open(
      IsarDatabase.schemas,
      directory: dir.path,
      maxSizeMiB: 1024,
      name: 'lector_probe',
    );
    IsarDatabase.debugSetDatabase(isar);
    final db = isar;
    for (var from = 0; from < config.products; from += 5000) {
      await db.writeTxn(() => db.isarProducts.putAll([
            for (var i = from; i < from + 5000 && i < config.products; i++)
              _product(i),
          ]));
    }
    final repo = ProductOfflineRepository(database: _Db(db));

    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
    Get.put<ProductOfflineRepository>(repo);
    Get.put<FullSyncService>(_Sync());
    Get.put<NetworkInfo>(_Net());
    Get.put<GetProductPresentationsUseCase>(_Presentations());

    // ── Pantalla ──
    recorder.start();
    await mount(const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: InvoiceFormTabsScreen(),
    ));
    await _wait(1500);
    final controller = await _waitFor<InvoiceFormController>(() {
      if (!Get.isRegistered<InvoiceTabsController>()) return null;
      return Get.find<InvoiceTabsController>().currentTab?.controller;
    });
    if (controller == null) throw StateError('la factura no abrió');
    double units() {
      var total = 0.0;
      for (final item in controller.invoiceItems) {
        total += item.quantity;
      }
      return total;
    }

    recorder.units = units;
    (controller.invoiceItems as RxList)
        .listen((_) => recorder.unitChanges.add((probeNow(), units())));

    for (var n = 0; n < config.existingLines; n++) {
      final found = await repo.getProductByBarcode(
          probeCode(config.products - 1 - n));
      found.fold((_) {}, controller.addOrUpdateProductToInvoice);
    }

    final field = await _waitFor<EditableTextState>(_findSearchField);
    if (field == null) throw StateError('no aparece la caja del buscador');
    recorder.attachField(field.widget.controller);
    final search = field.context
        .findAncestorStateOfType<ProductSearchWidgetState>();
    recorder.card = () => search?.debugValueOptionVisible ?? false;
    await _wait(800); // el buscador pide el foco a los 300 ms
    if (!field.widget.focusNode.hasFocus) {
      field.widget.focusNode.requestFocus();
      await _wait(300);
    }
    await controller.refreshShortCodeIndex();

    final note = await injector.prepare();
    final view = ui.PlatformDispatcher.instance.views.first;
    out('MEDICION LECTOR | ${config.label.isEmpty ? 'sin etiqueta' : config.label} | '
        'teclas: ${injector.name} | ${config.products} productos, '
        '${config.existingLines} líneas previas | ventana '
        '${view.physicalSize.width.toInt()}x${view.physicalSize.height.toInt()} '
        '(x${view.devicePixelRatio.toStringAsFixed(2)}) | '
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion} | '
        '${Platform.numberOfProcessors} núcleos | '
        '${kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug')}');
    if (note != null) out('MEDICION LECTOR | $note');
    out('MEDICION LECTOR | foco en la caja: ${field.widget.focusNode.hasFocus}');

    // ── Una lectura ──
    Future<_Scan> scan(String code, {required int gapMs, int settleMs = 1300}) async {
      final s = _Scan()..code = code;
      final unitsBefore = units();
      final keyFrom = recorder.keyDowns.length;
      final enterFrom = recorder.enterDowns.length;
      final textFrom = recorder.textChanges.length;
      final unitFrom = recorder.unitChanges.length;
      final sentAt = probeNow();
      await injector.type(code, gapMs: gapMs);
      final limit = Stopwatch()..start();
      while (units() <= unitsBefore && limit.elapsedMilliseconds < 5000) {
        await _wait(4);
      }
      s.added = units() > unitsBefore;
      await _wait(settleMs); // que lleguen los tiempos de los cuadros

      final keys = recorder.keyDowns.sublist(keyFrom);
      final enters = recorder.enterDowns.sublist(enterFrom);
      s.keys = keys.length;
      if (keys.isEmpty) return s;
      final first = keys.first;
      s.keysMs = _ms(first, keys.last);
      final enter = enters.isEmpty ? null : enters.first;
      if (enter != null) s.enterMs = _ms(first, enter);
      for (final (t, length) in recorder.textChanges.sublist(textFrom)) {
        if (length >= code.length) {
          s.textMs = _ms(first, t);
          break;
        }
      }
      final added = recorder.unitChanges
          .sublist(unitFrom)
          .where((u) => u.$2 > unitsBefore)
          .map((u) => u.$1)
          .firstOrNull;
      if (added != null && enter != null) s.lineMs = _ms(enter, added);

      // Cuadros desde que se mandó la primera tecla.
      final frames = [
        for (final f in recorder.frames)
          if (f.builtAt >= sentAt) f,
      ];
      _Frame? lineFrame;
      for (final f in frames) {
        if (f.units > unitsBefore) {
          lineFrame = f;
          break;
        }
      }
      final until = lineFrame?.builtAt ?? (frames.isEmpty ? 0 : frames.last.builtAt);
      final window = [for (final f in frames) if (f.builtAt <= until) f];
      s.framesTotal = window.length;
      s.framesToEnter = enter == null
          ? window.length
          : window.where((f) => f.builtAt <= enter).length;
      s.seenLengths = [
        for (final f in window)
          if (f.textLength > 0) f.textLength,
      ];
      s.cardFrames = window.where((f) => f.card).length;
      s.worstBuildMs = _max(window.map((f) => f.buildMs));
      s.worstRasterMs = _max(window.map((f) => f.rasterMs));
      if (lineFrame != null) {
        s.lineBuildMs = lineFrame.buildMs;
        s.lineRasterMs = lineFrame.rasterMs;
        final seen = lineFrame.rasterFinish;
        if (seen != null) {
          if (enter != null) s.lineSeenMs = _ms(enter, seen);
          s.totalSeenMs = _ms(first, seen);
        }
      }
      return s;
    }

    void table(String title, List<_Scan> scans) {
      out('MEDICION LECTOR | $title');
      out('MEDICION LECTOR |  #  teclas  1ª→últ.tecla  1ª→código  cuadros  '
          'Enter→línea  Enter→VISTA  1ª→VISTA  armar  pintar  (peor armar/pintar)  tarjeta  se vio');
      for (var i = 0; i < scans.length; i++) {
        final s = scans[i];
        out('MEDICION LECTOR | ${(i + 1).toString().padLeft(2)}  '
            '${s.keys.toString().padLeft(4)}  ${_f(s.keysMs)}    ${_f(s.textMs)}  '
            '${s.framesTotal.toString().padLeft(5)}    ${_f(s.lineMs)}    '
            '${_f(s.lineSeenMs)}  ${_f(s.totalSeenMs)} ${_f(s.lineBuildMs)} '
            '${_f(s.lineRasterMs)}  (${_f(s.worstBuildMs).trim()}/'
            '${_f(s.worstRasterMs).trim()})  '
            '${s.cardFrames.toString().padLeft(4)}     '
            '${s.added ? '' : 'NO ENTRÓ '}${s.seenLengths}');
      }
      out('MEDICION LECTOR | NORMAL (mediana): 1ª→código ${_f(_median(scans.map((s) => s.textMs))).trim()} ms · '
          'Enter→línea ${_f(_median(scans.map((s) => s.lineMs))).trim()} ms · '
          'Enter→VISTA ${_f(_median(scans.map((s) => s.lineSeenMs))).trim()} ms · '
          '1ª tecla→VISTA ${_f(_median(scans.map((s) => s.totalSeenMs))).trim()} ms · '
          'cuadros ${_median(scans.map((s) => s.framesTotal.toDouble()))?.toStringAsFixed(0)} · '
          'PEOR 1ª tecla→VISTA ${_f(_max(scans.map((s) => s.totalSeenMs))).trim()} ms · '
          'lecturas que pintaron la tarjeta "sin registrar": ${scans.where((s) => s.cardFrames > 0).length} · '
          'lecturas con el código a medias en pantalla: ${scans.where((s) => s.sawPartial).length}');
    }

    // Calentar (no se cuenta).
    final warm = await scan(probeCode(1), gapMs: config.keyGapMs);
    if (warm.keys == 0) {
      failures.add('las teclas no llegaron a la app (${injector.name})');
      out('MEDICION LECTOR | FALLA: las teclas no llegaron a la app');
      return LectorProbeResult(lines, failures);
    }

    // A. Lecturas nuevas, con pausa entre una y otra.
    final fresh = <_Scan>[];
    for (var n = 0; n < config.scans; n++) {
      fresh.add(await scan(probeCode((100 + n * 37) % config.products),
          gapMs: config.keyGapMs));
    }
    table('A. ${config.scans} lecturas de productos distintos '
        '(13 dígitos a ${config.keyGapMs} ms + Enter), tiempos en ms', fresh);

    // B. Re-lecturas del mismo producto (suma cantidad).
    final again = <_Scan>[];
    for (var n = 0; n < config.scans; n++) {
      again.add(await scan(probeCode(100), gapMs: config.keyGapMs));
    }
    table('B. ${config.scans} re-lecturas del mismo producto', again);

    // C. Lector más lento (10 ms entre teclas).
    final slow = <_Scan>[];
    for (var n = 0; n < 5; n++) {
      slow.add(await scan(probeCode(config.products ~/ 2 + n), gapMs: 10));
    }
    table('C. 5 lecturas con 10 ms entre teclas', slow);

    // D. Lecturas pegadas: sin esperar a que entre la anterior.
    final unitsBeforeBurst = units();
    final burstStart = probeNow();
    for (var n = 0; n < config.scans; n++) {
      await injector.type(probeCode(config.products ~/ 3 + n),
          gapMs: config.keyGapMs);
      await _wait(60);
    }
    final burstLimit = Stopwatch()..start();
    while (units() < unitsBeforeBurst + config.scans &&
        burstLimit.elapsedMilliseconds < 8000) {
      await _wait(5);
    }
    final burstMs = _ms(burstStart, probeNow());
    final burstAdded = (units() - unitsBeforeBurst).round();
    out('MEDICION LECTOR | D. ${config.scans} lecturas pegadas (60 ms entre una y otra): '
        'entraron $burstAdded de ${config.scans} en ${burstMs.toStringAsFixed(0)} ms; '
        'caja al final: "${recorder.field!.text}"');
    if (burstAdded != config.scans) {
      failures.add('lecturas pegadas: entraron $burstAdded de ${config.scans}');
    }
    await _wait(1500);

    // E. Persona tecleando un valor (120 ms entre teclas): tecla → se ve.
    const value = '2500';
    final human = <double?>[];
    final humanBuild = <double?>[];
    final humanRaster = <double?>[];
    final humanCard = <bool>[];
    for (var i = 1; i <= value.length; i++) {
      final keyFrom = recorder.keyDowns.length;
      await injector.type(value[i - 1], gapMs: 0, enter: false);
      await _wait(config.humanGapMs);
      final keyAt = recorder.keyDowns.length > keyFrom
          ? recorder.keyDowns[keyFrom]
          : null;
      if (keyAt == null) continue;
      await _wait(1200);
      final frame = recorder.frames
          .where((f) => f.builtAt >= keyAt && f.textLength >= i)
          .firstOrNull;
      human.add(frame?.rasterFinish == null
          ? null
          : _ms(keyAt, frame!.rasterFinish!));
      humanBuild.add(frame?.buildMs);
      humanRaster.add(frame?.rasterMs);
      humanCard.add(frame?.card ?? false);
    }
    out('MEDICION LECTOR | E. a mano "$value" (${config.humanGapMs} ms entre teclas), '
        'tecla → se VE el dígito: ${human.map((v) => _f(v).trim()).toList()} ms; '
        'armar ${humanBuild.map((v) => _f(v).trim()).toList()}; '
        'pintar ${humanRaster.map((v) => _f(v).trim()).toList()}; '
        'tarjeta "sin registrar" en ese mismo cuadro: $humanCard; '
        'caja: "${recorder.field!.text}"');
    if (humanCard.length != value.length || humanCard.contains(false)) {
      failures.add('a mano: la tarjeta "sin registrar" no salió en la misma '
          'tecla ($humanCard)');
    }
    if (recorder.field!.text != value) {
      failures.add('a mano: en la caja quedó "${recorder.field!.text}", no "$value"');
    }
    await injector.backspace(recorder.field!.text.length);
    await _wait(600);

    // Cuadros de toda la corrida.
    final build = [for (final f in recorder.frames) f.buildMs];
    final raster = [for (final f in recorder.frames) f.rasterMs];
    out('MEDICION LECTOR | cuadros en total: ${recorder.frames.length}; '
        'armar: normal ${_f(_median(build)).trim()} ms, peor ${_f(_max(build)).trim()} ms; '
        'pintar: normal ${_f(_median(raster)).trim()} ms, peor ${_f(_max(raster)).trim()} ms');
    for (final line in InvoiceEntryMetrics.instance.report().split('\n')) {
      if (line.trim().isNotEmpty) out('MEDICION LECTOR | diagnóstico | $line');
    }

    // ── Veredicto ──
    for (final (name, scans) in [('A', fresh), ('B', again), ('C', slow)]) {
      final lost = scans.where((s) => !s.added).length;
      if (lost > 0) failures.add('$name: $lost lecturas no entraron');
      final short = scans.where((s) => s.keys != 13).length;
      if (short > 0) failures.add('$name: $short lecturas sin las 13 teclas');
      final cards = scans.where((s) => s.cardFrames > 0).length;
      if (cards > 0) {
        failures.add('$name: $cards lecturas pintaron la tarjeta "sin registrar"');
      }
      final partial = scans.where((s) => s.sawPartial).length;
      if (partial > 0) {
        failures.add('$name: en $partial lecturas el código se vio a medias '
            '(dígitos entrando de a pocos)');
      }
    }
    final textMs = _median(fresh.map((s) => s.textMs));
    if (textMs == null || textMs > config.maxTextMs) {
      failures.add('el código tarda ${textMs?.toStringAsFixed(0) ?? 'n/d'} ms en '
          'completarse (tope ${config.maxTextMs} ms)');
    }
    final seenMs = _median(fresh.map((s) => s.lineSeenMs));
    if (config.maxLineMs > 0 && (seenMs == null || seenMs > config.maxLineMs)) {
      failures.add('la línea tarda ${seenMs?.toStringAsFixed(0) ?? 'n/d'} ms en '
          'verse tras el Enter (tope ${config.maxLineMs} ms)');
    }
  } catch (e, st) {
    failures.add('error: $e');
    out('MEDICION LECTOR | ERROR: $e');
    out(st.toString().split('\n').take(12).join('\n'));
  } finally {
    out(failures.isEmpty
        ? 'MEDICION LECTOR | RESULTADO: BIEN'
        : 'MEDICION LECTOR | RESULTADO: FALLA — ${failures.join('; ')}');
    try {
      await isar?.close(deleteFromDisk: true);
      await dir?.delete(recursive: true);
    } catch (_) {}
  }
  return LectorProbeResult(lines, failures);
}

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

Future<T?> _waitFor<T>(T? Function() find, {int timeoutMs = 15000}) async {
  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < timeoutMs) {
    final value = find();
    if (value != null) return value;
    await _wait(50);
  }
  return null;
}

/// La caja de texto del buscador de productos.
EditableTextState? _findSearchField() {
  EditableTextState? found;
  void inSearch(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is EditableTextState) {
      found = element.state as EditableTextState;
      return;
    }
    element.visitChildElements(inSearch);
  }

  void visit(Element element) {
    if (found != null) return;
    if (element.widget is ProductSearchWidget) {
      element.visitChildElements(inSearch);
      return;
    }
    element.visitChildElements(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildElements(visit);
  return found;
}
