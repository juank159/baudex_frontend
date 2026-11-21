// PRUEBA DE ESTRÉS (escritorio macOS, modo profile): abre la app REAL contra
// el servidor de PRUEBAS (puerto 3101, base baudex_qa) y la usa como un cajero
// apurado: lector de código de barras (ráfagas de teclas + Enter), atajos de
// teclado, ir y volver entre pantallas cientos de veces, notas crédito y
// órdenes de compra. Mide tiempos, cuadros lentos y memoria (RSS).
//
// La memoria del montículo (heap) y los controladores vivos los mide aparte
// tool/estres/vm_probe.dart conectándose al servicio de la VM.
//
// Compilar: flutter build macos --profile -t tool/estres/stress_main.dart
// Correr:   tool/estres/run_stress.sh   (pone HOME aislado; nunca la carpeta real)
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/app_binding.dart';
import 'package:baudex_desktop/app/config/env/env_config.dart';
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/controllers/credit_note_detail_controller.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/products_controller.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/controllers/purchase_order_detail_controller.dart';
import 'package:baudex_desktop/main.dart' show MyApp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

final env = Platform.environment;
final steps = (env['QA_STEPS'] ??
        'login,descarga,pos_escanear,pos_reescanear,pos_atajos,pos_productos_ida_vuelta,'
            'busquedas,factura_detalle,kardex_saldos_movs,nota_credito,orden_compra,nav_loop')
    .split(',');
final email = env['QA_EMAIL'] ?? 'qa@baudex.test';
final password = env['QA_PASSWORD'] ?? 'Prueba123!';
final business = env['QA_BUSINESS'] ?? '';
final port = env['QA_PORT'] ?? '3101';
final markFile = env['QA_MARK'];
final outFile = env['QA_OUT'];
final scale = int.tryParse(env['QA_SCALE'] ?? '') ?? 1; // multiplica repeticiones

void log(String m) => stdout.writeln('QA| $m');

// ── Resultados ──
final List<Map<String, Object?>> results = [];
final List<String> errors = [];
String currentScenario = 'arranque';

void mark(String name) {
  currentScenario = name;
  if (markFile != null) File(markFile!).writeAsStringSync(name);
}

void saveResults() {
  if (outFile == null) return;
  File(outFile!).writeAsStringSync(const JsonEncoder.withIndent(' ')
      .convert({'results': results, 'errors': errors}));
}

// ── Cuadros ──
final List<ui.FrameTiming> _frames = [];
Map<String, Object?> frameStats() {
  if (_frames.isEmpty) return {'cuadros': 0};
  final total = _frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList()..sort();
  final build = _frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()..sort();
  final raster = _frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()..sort();
  double p(List<double> l, double q) => l[((l.length - 1) * q).round()];
  return {
    'cuadros': total.length,
    'lentos_16ms': total.where((m) => m > 16.7).length,
    'lentos_50ms': total.where((m) => m > 50).length,
    'congelados_500ms': total.where((m) => m > 500).length,
    'p95_ms': p(total, .95).toStringAsFixed(1),
    'peor_ms': total.last.toStringAsFixed(0),
    'build_p95_ms': p(build, .95).toStringAsFixed(1),
    'build_peor_ms': build.last.toStringAsFixed(0),
    'raster_peor_ms': raster.last.toStringAsFixed(0),
  };
}

// Mayor pausa del hilo principal medida con un reloj que late cada 16 ms
// (un congelamiento real no deja pintar cuadros, así que no aparece en ellos).
Timer? _hb;
DateTime _lastBeat = DateTime.now();
int _maxStallMs = 0;
void _startHeartbeat() {
  _hb?.cancel();
  _lastBeat = DateTime.now();
  _hb = Timer.periodic(const Duration(milliseconds: 16), (_) {
    final now = DateTime.now();
    final gap = now.difference(_lastBeat).inMilliseconds;
    if (gap > _maxStallMs) _maxStallMs = gap;
    _lastBeat = now;
  });
}

int rssMb() => ProcessInfo.currentRss ~/ (1024 * 1024);

double pct(List<int> l, double q) {
  if (l.isEmpty) return 0;
  final s = [...l]..sort();
  return s[((s.length - 1) * q).round()].toDouble();
}

Future<T> scenario<T>(String name, Future<T> Function(Map<String, Object?> extra) fn) async {
  mark(name);
  await Future.delayed(const Duration(milliseconds: 600)); // la sonda toma foto "antes"
  final extra = <String, Object?>{};
  final errBefore = errors.length;
  final rss0 = rssMb();
  _frames.clear();
  _maxStallMs = 0;
  final sw = Stopwatch()..start();
  T? r;
  try {
    r = await fn(extra).timeout(Duration(minutes: int.tryParse(env['QA_SCEN_MAX_MIN'] ?? '') ?? 20));
  } on TimeoutException {
    errors.add('[$name] el escenario no terminó a tiempo (ruta ${Get.currentRoute})');
    extra['no_termino'] = true;
    await snap('${name}_sin_terminar');
  } catch (e, st) {
    errors.add('[$name] EXCEPCIÓN $e\n$st');
    extra['excepcion'] = '$e';
  }
  sw.stop();
  await Future.delayed(const Duration(milliseconds: 400));
  await snap('${name}_fin');
  final nq = Map.of(neverQuiet);
  neverQuiet.clear();
  if (backIgnored > 0) extra['volver_sin_efecto'] = backIgnored;
  backIgnored = 0;
  final res = {
    'escenario': name,
    if (nq.isNotEmpty) 'pantallas_nunca_quietas': nq,
    'ms': sw.elapsedMilliseconds,
    'rss_mb_antes': rss0,
    'rss_mb_despues': rssMb(),
    'pausa_max_hilo_ms': _maxStallMs,
    ...frameStats(),
    'errores': errors.length - errBefore,
    ...extra,
  };
  results.add(res);
  log(jsonEncode(res));
  saveResults();
  mark('$name:fin');
  await Future.delayed(const Duration(milliseconds: 600));
  return r as T;
}

// ── Teclado simulado: mismo camino que el motor de macOS (KeyData + mensaje crudo) ──
final _clock = Stopwatch()..start();
const _ctrlMods = 0x40000 | 0x1; // NSEventModifierFlagControl | izquierda
int _mods = 0;

int _macKeyCode(PhysicalKeyboardKey p) {
  for (final e in kMacOsToPhysicalKey.entries) {
    if (e.value == p) return e.key;
  }
  return 0;
}

Future<bool> _key(bool down, LogicalKeyboardKey logical, PhysicalKeyboardKey physical,
    {String? ch}) async {
  final mgr = ServicesBinding.instance.keyEventManager;
  final byData = mgr.handleKeyData(ui.KeyData(
    type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
    physical: physical.usbHidUsage,
    logical: logical.keyId,
    timeStamp: Duration(microseconds: _clock.elapsedMicroseconds),
    character: down ? ch : null,
    synthesized: false,
  ));
  final reply = await mgr.handleRawKeyMessage(<String, Object?>{
    'type': down ? 'keydown' : 'keyup',
    'keymap': 'macos',
    'keyCode': _macKeyCode(physical),
    'characters': ch ?? '',
    'charactersIgnoringModifiers': ch ?? '',
    'modifiers': _mods,
  });
  return byData || (reply['handled'] == true);
}

Future<bool> tap(LogicalKeyboardKey l, PhysicalKeyboardKey p, {String? ch, bool ctrl = false, bool alt = false}) async {
  if (ctrl) {
    _mods = _ctrlMods;
    await _key(true, LogicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlLeft);
  }
  if (alt) {
    _mods = 0x80000 | 0x20;
    await _key(true, LogicalKeyboardKey.altLeft, PhysicalKeyboardKey.altLeft);
  }
  final h = await _key(true, l, p, ch: ch);
  await _key(false, l, p);
  if (alt) {
    await _key(false, LogicalKeyboardKey.altLeft, PhysicalKeyboardKey.altLeft);
  }
  if (ctrl) {
    await _key(false, LogicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlLeft);
  }
  _mods = 0;
  return h;
}

const _digitsL = [
  LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];
const _digitsP = [
  PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.digit2,
  PhysicalKeyboardKey.digit3, PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.digit5,
  PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.digit7, PhysicalKeyboardKey.digit8,
  PhysicalKeyboardKey.digit9,
];

EditableTextState? focusedEditable() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return null;
  if (ctx is StatefulElement && ctx.state is EditableTextState) {
    return ctx.state as EditableTextState;
  }
  return ctx.findAncestorStateOfType<EditableTextState>();
}

EditableTextState? findEditable(bool Function(EditableText w) test, {bool Function(Element e)? where}) {
  EditableTextState? found;
  void visit(Element e) {
    if (found != null) return;
    if (e is StatefulElement && e.state is EditableTextState && test(e.widget as EditableText) &&
        (where == null || where(e))) {
      found = e.state as EditableTextState;
      return;
    }
    e.visitChildren(visit);
  }
  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// Lector de código de barras tipo teclado: cada dígito es una tecla
/// (≈4 ms entre teclas) y al final Enter. Igual que el motor: tecla → si nadie
/// la toma, el texto llega a la caja; Enter → acción "listo" de la caja.
Future<void> scanBarcode(String code, {EditableTextState? target, int gapMs = 4}) async {
  for (final c in code.split('')) {
    final d = int.parse(c);
    final handled = await _key(true, _digitsL[d], _digitsP[d], ch: c);
    final st = target ?? focusedEditable();
    if (!handled && st != null) {
      final t = st.textEditingValue.text + c;
      st.updateEditingValue(TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length)));
    }
    await _key(false, _digitsL[d], _digitsP[d]);
    if (gapMs > 0) await Future.delayed(Duration(milliseconds: gapMs));
  }
  final handled = await _key(true, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter, ch: '\r');
  final st = target ?? focusedEditable();
  if (!handled && st != null) st.performAction(st.widget.textInputAction ?? TextInputAction.done);
  await _key(false, LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
}

// ── Utilidades ──
final _rootKey = GlobalKey();
final snapDir = env['QA_SNAPS'];
int _snapN = 0;

/// Foto de la pantalla actual (PNG) para ver dónde quedó la app.
Future<void> snap(String name) async {
  if (snapDir == null) return;
  try {
    final ro = _rootKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (ro == null) return;
    final img = await ro.toImage(pixelRatio: 0.6).timeout(const Duration(seconds: 5));
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$snapDir/${(++_snapN).toString().padLeft(3, '0')}_$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(bytes!.buffer.asUint8List());
  } catch (e) {
    log('foto $name falló: $e');
  }
}

/// Paso con reloj: si tarda más de [warnS] lo anota (con foto); si pasa de
/// [maxS] lo da por colgado y sigue (para que una sola traba no detenga toda la noche).
Future<T?> stepT<T>(String label, Future<T> Function() f, {int warnS = 5, int maxS = 60}) async {
  final sw = Stopwatch()..start();
  var warned = false;
  final t = Timer(Duration(seconds: warnS), () {
    warned = true;
    log('  LENTO (>${warnS}s) $label · ruta=${Get.currentRoute}');
    snap('lento_${label.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}');
  });
  try {
    return await f().timeout(Duration(seconds: maxS));
  } on TimeoutException {
    errors.add('[$currentScenario] COLGADO >${maxS}s en "$label" (ruta ${Get.currentRoute})');
    log('  COLGADO >${maxS}s en $label · ruta=${Get.currentRoute}');
    await snap('colgado_${label.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}');
    return null;
  } finally {
    t.cancel();
    if (warned) log('  $label terminó en ${sw.elapsedMilliseconds} ms');
  }
}

Future<bool> until(bool Function() ok, {int seconds = 60}) async {
  for (var i = 0; i < seconds * 50; i++) {
    if (ok()) return true;
    await Future.delayed(const Duration(milliseconds: 20));
  }
  return false;
}

/// Espera a que la pantalla quede quieta (sin cuadros por [quietMs]).
/// Los cuadros se cuentan con un callback persistente (uno solo, en main).
int _frameCount = 0;
/// Pantallas que nunca quedaron quietas (animación sin fin = CPU gastada).
final Map<String, int> neverQuiet = {};
Future<int> settle({int quietMs = 400, int maxSeconds = 8}) async {
  final sw = Stopwatch()..start();
  var lastFrames = -1;
  var quietSince = sw.elapsedMilliseconds;
  while (sw.elapsed.inSeconds < maxSeconds) {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_frameCount != lastFrames || SchedulerBinding.instance.hasScheduledFrame) {
      lastFrames = _frameCount;
      quietSince = sw.elapsedMilliseconds;
    } else if (sw.elapsedMilliseconds - quietSince >= quietMs) {
      return quietSince;
    }
  }
  neverQuiet[Get.currentRoute] = (neverQuiet[Get.currentRoute] ?? 0) + 1;
  return sw.elapsedMilliseconds;
}

Future<int> go(String route, {dynamic args}) async {
  final sw = Stopwatch()..start();
  Get.toNamed(route, arguments: args);
  await until(() => Get.currentRoute == route || Get.currentRoute.startsWith(route), seconds: 20);
  await settle();
  return sw.elapsedMilliseconds;
}

/// "Volver" como lo hace la app (Get.back). Si la ruta no cambia (porque
/// Get.back() se gastó cerrando un aviso), se cuenta.
int backIgnored = 0;
Future<int> back() async {
  final sw = Stopwatch()..start();
  final before = Get.currentRoute;
  final snack = Get.isSnackbarOpen;
  Get.back();
  await settle();
  if (Get.currentRoute == before) {
    backIgnored++;
    if (backIgnored <= 5) log('  VOLVER SIN EFECTO en $before (aviso abierto: $snack)');
  }
  return sw.elapsedMilliseconds;
}

InvoiceFormController? get form =>
    Get.isRegistered<InvoiceTabsController>() ? Get.find<InvoiceTabsController>().currentTab?.controller : null;

double qtySum() => form?.invoiceItems.fold<double>(0, (a, i) => a + i.quantity) ?? 0;

List<String> _barcodes = [];
Future<List<String>> barcodes(int n) async {
  if (_barcodes.length < n) {
    final ps = await IsarDatabase.instance.database.isarProducts
        .filter()
        .barcodeIsNotNull()
        .limit(n + 200)
        .findAll();
    _barcodes = ps.map((p) => p.barcode!).where((b) => b.length >= 8).toList();
  }
  return _barcodes.take(n).toList();
}

// ── Escenarios ──
Future<void> _login() async {
  await until(() => Get.currentRoute == AppRoutes.login || Get.currentRoute == AppRoutes.dashboard, seconds: 60);
  if (Get.currentRoute == AppRoutes.dashboard) return;
  await Future.delayed(const Duration(seconds: 1));
  final auth = Get.find<AuthController>();
  auth.loginEmailController.text = email;
  auth.loginPasswordController.text = password;
  auth.loginBusinessController.text = business;
  await auth.login();
  await until(() => Get.currentRoute == AppRoutes.dashboard, seconds: 60);
  log('login → ${Get.currentRoute}');
  if (Get.currentRoute != AppRoutes.dashboard) throw StateError('no inició sesión (¿falta QA_BUSINESS?)');
}

Future<void> _download(Map<String, Object?> x) async {
  const modules = ['products', 'customers', 'invoices', 'purchase_orders', 'credit_notes',
    'inventory_batches', 'inventory_movements'];
  final sync = Get.find<FullSyncService>();
  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(minutes: 25)) {
    final missing = <String>[];
    for (final m in modules) {
      if (!await sync.isModuleDownloaded(m)) missing.add(m);
    }
    if (missing.isEmpty && !sync.isSyncing.value) break;
    await Future.delayed(const Duration(seconds: 2));
  }
  final isar = IsarDatabase.instance.database;
  x['productos'] = await isar.isarProducts.count();
  x['clientes'] = await isar.isarCustomers.count();
  x['facturas'] = await isar.isarInvoices.count();
  x['segundos'] = sw.elapsed.inSeconds;
}

Future<void> _openPos() async {
  if (Get.currentRoute != AppRoutes.invoicesWithTabs) {
    Get.toNamed(AppRoutes.invoicesWithTabs);
  }
  await until(() => form != null);
  await until(() => !form!.isLoadingProducts, seconds: 60);
  await settle();
}

/// Caja de búsqueda de productos del punto de venta. Si perdió el foco (el
/// cajero tendría que hacer clic en ella antes de escanear), se anota.
int focusLost = 0;
final List<String> focusThieves = [];
EditableTextState? posSearchBox() {
  final box = findEditable((w) => true,
      where: (e) => e.findAncestorWidgetOfExactType<ProductSearchWidget>() != null);
  if (box != null && !box.widget.focusNode.hasFocus) {
    focusLost++;
    final pf = FocusManager.instance.primaryFocus;
    if (focusThieves.length < 10) {
      focusThieves.add('${pf?.debugLabel ?? pf?.runtimeType} en ${pf?.context?.widget.runtimeType} '
          '(líneas=${form?.invoiceItems.length})');
    }
    box.requestKeyboard();
  }
  return box;
}

/// Escanea [codes] en el punto de venta y mide cuánto tarda cada código en
/// verse en la factura (desde el Enter hasta que cambia la cantidad).
Future<List<int>> _scanInPos(List<String> codes, Map<String, Object?> x, {int timeoutS = 15}) async {
  final lat = <int>[];
  var lost = 0;
  for (final code in codes) {
    final before = qtySum();
    final st = posSearchBox();
    if (st == null) {
      x['sin_caja_de_busqueda'] = true;
      break;
    }
    final sw = Stopwatch()..start();
    await scanBarcode(code, target: st);
    final ok = await until(() => qtySum() > before, seconds: timeoutS);
    if (!ok) lost++;
    lat.add(sw.elapsedMilliseconds);
  }
  x['foco_perdido'] = focusLost;
  if (focusThieves.isNotEmpty) x['foco_quedo_en'] = [...focusThieves];
  focusLost = 0;
  focusThieves.clear();
  x['escaneos'] = codes.length;
  x['perdidos'] = lost;
  x['lineas'] = form?.invoiceItems.length;
  x['escaneo_p50_ms'] = pct(lat, .5);
  x['escaneo_p95_ms'] = pct(lat, .95);
  x['escaneo_max_ms'] = pct(lat, 1);
  return lat;
}

Future<void> _posScan(Map<String, Object?> x) async {
  await _openPos();
  form!.clearFormForNewSale();
  await settle();
  final codes = await barcodes(150 * scale);
  // Primeras 20 líneas vs últimas 20: ¿cada escaneo es más lento que el anterior?
  final lat = await _scanInPos(codes, x);
  if (lat.length >= 40) {
    x['primeros20_p50_ms'] = pct(lat.sublist(0, 20), .5);
    x['ultimos20_p50_ms'] = pct(lat.sublist(lat.length - 20), .5);
  }
}

Future<void> _posRescan(Map<String, Object?> x) async {
  await _openPos();
  final codes = (await barcodes(10));
  await _scanInPos([for (var i = 0; i < 100 * scale; i++) codes[i % codes.length]], x);
}

Future<void> _posShortcuts(Map<String, Object?> x) async {
  await _openPos();
  if ((form?.invoiceItems.length ?? 0) == 0) {
    await _scanInPos(await barcodes(30), x);
  }
  // Los atajos no se procesan con la caja de texto enfocada (Ctrl+Enter) pero
  // Ctrl+= / Ctrl+N sí. Se prueban igual que un cajero: con la caja enfocada.
  final lat = <int>[];
  var noEffect = 0;
  Future<void> shortcut(LogicalKeyboardKey l, PhysicalKeyboardKey p, double expectDelta) async {
    final before = qtySum();
    final sw = Stopwatch()..start();
    await tap(l, p, ctrl: true);
    final ok = await until(() => (qtySum() - before - expectDelta).abs() < 0.001, seconds: 5);
    if (!ok) noEffect++;
    lat.add(sw.elapsedMilliseconds);
  }
  for (var i = 0; i < 100 * scale; i++) {
    await shortcut(LogicalKeyboardKey.equal, PhysicalKeyboardKey.equal, 1);
  }
  for (var i = 0; i < 50 * scale; i++) {
    await shortcut(LogicalKeyboardKey.digit5, PhysicalKeyboardKey.digit5, 5);
  }
  for (var i = 0; i < 30 * scale; i++) {
    await shortcut(LogicalKeyboardKey.minus, PhysicalKeyboardKey.minus, -1);
  }
  // Teclado en español (Colombia/España): la tecla "+" da el carácter '+'
  // (LogicalKeyboardKey.add), no '='. Y el "+"/"-" del teclado numérico.
  final esp = <String, Object?>{};
  Future<void> espKey(String label, LogicalKeyboardKey l, PhysicalKeyboardKey p, double delta) async {
    final before = qtySum();
    await tap(l, p, ctrl: true);
    await until(() => (qtySum() - before - delta).abs() < 0.001, seconds: 2);
    esp[label] = (qtySum() - before - delta).abs() < 0.001 ? 'funciona' : 'NO HACE NADA';
  }
  await espKey('Ctrl + "+" (teclado español)', LogicalKeyboardKey.add, PhysicalKeyboardKey.bracketRight, 1);
  await espKey('Ctrl + "+" teclado numérico', LogicalKeyboardKey.numpadAdd, PhysicalKeyboardKey.numpadAdd, 1);
  await espKey('Ctrl + "-" teclado numérico', LogicalKeyboardKey.numpadSubtract, PhysicalKeyboardKey.numpadSubtract, -1);
  x['teclado_espanol'] = esp;
  // Flechas arriba/abajo por toda la lista
  final swA = Stopwatch()..start();
  final arrows = <int>[];
  for (var i = 0; i < 100 * scale; i++) {
    final sa = Stopwatch()..start();
    await tap(i < 50 * scale ? LogicalKeyboardKey.arrowDown : LogicalKeyboardKey.arrowUp,
        i < 50 * scale ? PhysicalKeyboardKey.arrowDown : PhysicalKeyboardKey.arrowUp);
    arrows.add(sa.elapsedMilliseconds);
    await Future.delayed(const Duration(milliseconds: 10));
  }
  x['flecha_p50_ms'] = pct(arrows, .5);
  x['flecha_max_ms'] = pct(arrows, 1);
  await settle();
  x['flechas_100_ms'] = swA.elapsedMilliseconds;
  x['atajos'] = lat.length;
  x['atajos_sin_efecto'] = noEffect;
  x['atajo_p50_ms'] = pct(lat, .5);
  x['atajo_p95_ms'] = pct(lat, .95);
  x['atajo_max_ms'] = pct(lat, 1);
  x['lineas'] = form?.invoiceItems.length;
}

/// Bug reportado: con la factura abierta, ir a Productos, escanear en el
/// buscador y volver a la factura → se congela.
Future<void> _posProductsRoundTrip(Map<String, Object?> x) async {
  await _openPos();
  final codes = await barcodes(60);
  final toProducts = <int>[], scanProd = <int>[], backPos = <int>[], scanPosAfter = <int>[];
  var useAlt = true;
  for (var i = 0; i < 15 * scale; i++) {
    // Alt+6 = Productos (atajo global) — mitad de las veces por atajo, mitad por ruta
    log('  ida y vuelta $i (${useAlt ? "Alt+6" : "ruta"})');
    final sw = Stopwatch()..start();
    if (useAlt) {
      await stepT('Alt+6 a Productos', () async {
        await tap(LogicalKeyboardKey.digit6, PhysicalKeyboardKey.digit6, alt: true);
        await until(() => Get.currentRoute == AppRoutes.products, seconds: 20);
        await settle();
      });
    } else {
      await stepT('ruta a Productos', () => go(AppRoutes.products));
    }
    useAlt = !useAlt;
    toProducts.add(sw.elapsedMilliseconds);
    if (Get.currentRoute != AppRoutes.products) {
      x['no_abrio_productos'] = (x['no_abrio_productos'] as int? ?? 0) + 1;
      continue;
    }
    final pc = Get.find<ProductsController>();
    final box = findEditable((w) => identical(w.controller, pc.searchController));
    if (box == null) {
      x['sin_buscador_productos'] = true;
    } else {
      box.requestKeyboard();
      for (var k = 0; k < 3; k++) {
        final s2 = Stopwatch()..start();
        final code = codes[(i * 3 + k) % codes.length];
        await stepT('escanear en Productos', () async {
          await scanBarcode(code, target: box);
          await settle();
        });
        scanProd.add(s2.elapsedMilliseconds);
        pc.searchController.clear();
      }
    }
    final s3 = Stopwatch()..start();
    await stepT('volver a la factura', () async {
      Get.back();
      await until(() => Get.currentRoute == AppRoutes.invoicesWithTabs, seconds: 20);
      await settle();
    });
    backPos.add(s3.elapsedMilliseconds);
    if (i == 0) await snap('factura_tras_volver');
    final l = await stepT('escanear al volver', () => _scanInPos([codes[i % codes.length]], {})) ?? [60000];
    scanPosAfter.addAll(l);
  }
  x['ir_a_productos_p95_ms'] = pct(toProducts, .95);
  x['ir_a_productos_max_ms'] = pct(toProducts, 1);
  x['escaneo_en_productos_p95_ms'] = pct(scanProd, .95);
  x['escaneo_en_productos_max_ms'] = pct(scanProd, 1);
  x['volver_a_factura_p95_ms'] = pct(backPos, .95);
  x['volver_a_factura_max_ms'] = pct(backPos, 1);
  x['escaneo_al_volver_p95_ms'] = pct(scanPosAfter, .95);
  x['escaneo_al_volver_max_ms'] = pct(scanPosAfter, 1);
}

Future<void> _searches(Map<String, Object?> x) async {
  await _openPos();
  final c = form!;
  final t = <String, int>{};
  for (final q in ['ar', 'ma', 'arroz', 'marca1', 'queso marca2', '2500', '7']) {
    final sw = Stopwatch()..start();
    final r = await c.searchProducts(q);
    t['producto "$q" (${r.length})'] = sw.elapsedMilliseconds;
  }
  for (final q in ['ge', 'apellido', 'genesis apellido 80', '30000']) {
    final sw = Stopwatch()..start();
    final r = await c.searchCustomers(q);
    t['cliente "$q" (${r.length})'] = sw.elapsedMilliseconds;
  }
  x['tiempos_ms'] = t;
}

Future<void> _invoiceDetail(Map<String, Object?> x) async {
  final invs = await IsarDatabase.instance.database.isarInvoices.where().sortByCreatedAtDesc().limit(30 * scale).findAll();
  final open = <int>[], close = <int>[];
  for (final inv in invs) {
    open.add(await go(AppRoutes.invoiceDetail(inv.serverId)));
    close.add(await back());
  }
  x['abrir_p50_ms'] = pct(open, .5);
  x['abrir_p95_ms'] = pct(open, .95);
  x['abrir_max_ms'] = pct(open, 1);
  x['cerrar_p95_ms'] = pct(close, .95);
}

Future<void> _kardex(Map<String, Object?> x) async {
  // Los primeros productos sembrados son los más vendidos (kardex largo).
  final ps = await IsarDatabase.instance.database.isarProducts.where().limit(5).findAll();
  final t = <String, int>{};
  for (final p in ps) {
    t['kardex ${p.sku}'] = await go(AppRoutes.inventoryProductKardex(p.serverId));
    await back();
  }
  t['saldos'] = await go(AppRoutes.inventoryBalances);
  await back();
  t['movimientos'] = await go(AppRoutes.inventoryMovements);
  await back();
  t['inventario'] = await go(AppRoutes.inventory);
  await back();
  x['tiempos_ms'] = t;
}

/// Bug reportado: confirmar una nota crédito en borrador tarda, muestra error
/// y luego aparece confirmada.
Future<void> _creditNotes(Map<String, Object?> x) async {
  final ids = (env['QA_CN_IDS'] ?? '').split(',').where((s) => s.isNotEmpty).toList();
  final rows = <Map<String, Object?>>[];
  for (final id in ids.take(8 * scale)) {
    await go(AppRoutes.creditNotesDetail + '/$id');
    final c = Get.find<CreditNoteDetailController>();
    await until(() => !c.isLoading && c.creditNote != null, seconds: 30);
    final before = c.creditNote?.status.name;
    final shownId = c.creditNote?.id;
    final snackBefore = errors.length;
    final sw = Stopwatch()..start();
    final f = c.confirmCreditNote();
    await until(() => Get.isDialogOpen == true, seconds: 5);
    Get.back(result: true);
    await f;
    final ms = sw.elapsedMilliseconds;
    await settle();
    rows.add({
      'id': id.substring(0, 8),
      'antes': before,
      'despues': c.creditNote?.status.name,
      'ms': ms,
      'errores_log': errors.length - snackBefore,
      // Si quedó en borrador en pantalla, la app mostró el aviso rojo de error
      'mostro_error': c.creditNote?.status.name != 'confirmed',
      // ¿La pantalla muestra la nota pedida o la de antes (controlador reutilizado)?
      'pantalla_muestra_otra_nota': shownId != id,
    });
    if (c.creditNote?.status.name != 'confirmed') await snap('nota_credito_error_$id');
    await back();
  }
  x['notas'] = rows;
}

/// Bug reportado: orden de compra en borrador → Productos → volver → abrir su
/// detalle → se congela o cierra.
Future<void> _purchaseOrders(Map<String, Object?> x) async {
  final ids = (env['QA_PO_IDS'] ?? '').split(',').where((s) => s.isNotEmpty).toList();
  final rows = <Map<String, Object?>>[];
  for (final id in ids.take(6 * scale)) {
    final r = <String, Object?>{'id': id.substring(0, 8)};
    log('  orden ${id.substring(0, 8)}');
    r['lista_ms'] = await stepT('lista de órdenes', () => go(AppRoutes.purchaseOrders));
    r['detalle_ms'] = await stepT('detalle de la orden', () => go(AppRoutes.purchaseOrderDetail(id)));
    if (rows.isEmpty) await snap('orden_detalle');
    // A) desde el detalle, Alt+6 (Productos) y volver
    await tap(LogicalKeyboardKey.digit6, PhysicalKeyboardKey.digit6, alt: true);
    await until(() => Get.currentRoute == AppRoutes.products, seconds: 20);
    await settle();
    r['productos_ms'] = 0;
    await back();
    r['detalle_tras_volver_ok'] = Get.isRegistered<PurchaseOrderDetailController>() &&
        Get.find<PurchaseOrderDetailController>().purchaseOrder.value?.id == id;
    r['ruta_tras_volver_de_productos'] = Get.currentRoute;
    await back(); // a la lista
    // B) volver a abrir el MISMO detalle desde la lista
    r['detalle_otra_vez_ms'] = await stepT('detalle otra vez', () => go(AppRoutes.purchaseOrderDetail(id)));
    await until(() => Get.isRegistered<PurchaseOrderDetailController>() &&
        !Get.find<PurchaseOrderDetailController>().isLoading.value, seconds: 20);
    r['detalle_otra_vez_ok'] = Get.isRegistered<PurchaseOrderDetailController>() &&
        Get.find<PurchaseOrderDetailController>().purchaseOrder.value?.id == id;
    // C) detalle → Productos por ruta → detalle de OTRA orden encima → volver dos veces
    await go(AppRoutes.products);
    final other = ids[(ids.indexOf(id) + 1) % ids.length];
    await go(AppRoutes.purchaseOrderDetail(other));
    r['detalle_apilado_muestra'] = Get.isRegistered<PurchaseOrderDetailController>()
        ? (Get.find<PurchaseOrderDetailController>().purchaseOrder.value?.id == other ? 'correcta' : 'OTRA ORDEN')
        : 'sin controlador';
    await back();
    await back();
    r['al_volver_al_primero_ok'] = Get.isRegistered<PurchaseOrderDetailController>();
    await back();
    await back();
    // D) crear orden (formulario) → Productos → volver → volver → detalle
    await go(AppRoutes.purchaseOrdersCreate);
    await go(AppRoutes.products);
    await back();
    await back();
    r['detalle_tras_formulario_ms'] = await stepT('detalle tras formulario', () => go(AppRoutes.purchaseOrderDetail(id)));
    r['detalle_tras_formulario_ok'] = Get.isRegistered<PurchaseOrderDetailController>() &&
        Get.find<PurchaseOrderDetailController>().purchaseOrder.value?.id == id;
    if (rows.isEmpty) await snap('orden_detalle_tras_formulario');
    await back();
    rows.add(r);
    log('  ${jsonEncode(r)}');
    Get.until((route) => route.isFirst || Get.currentRoute == AppRoutes.dashboard);
    await settle();
  }
  x['ordenes'] = rows;
}

Future<void> _navLoop(Map<String, Object?> x) async {
  final isar = IsarDatabase.instance.database;
  final inv = await isar.isarInvoices.where().findFirst();
  final prod = await isar.isarProducts.where().findFirst();
  final routes = <String>[
    AppRoutes.invoices,
    if (inv != null) AppRoutes.invoiceDetail(inv.serverId),
    AppRoutes.products,
    AppRoutes.customers,
    AppRoutes.purchaseOrders,
    AppRoutes.creditNotes,
    if (prod != null) AppRoutes.inventoryProductKardex(prod.serverId),
    AppRoutes.inventoryBalances,
    AppRoutes.inventoryMovements,
    AppRoutes.invoicesWithTabs,
  ];
  final n = int.tryParse(env['QA_NAV_N'] ?? '') ?? 100 * scale;
  final rssSeries = <int>[];
  final per = <String, List<int>>{};
  for (var i = 0; i < n; i++) {
    // Mitad apilando (toNamed + back), mitad como el menú (offAllNamed).
    for (final r in routes) {
      final sw = Stopwatch()..start();
      if (i.isEven) {
        Get.toNamed(r);
        await settle(quietMs: 250, maxSeconds: 15);
        Get.back();
      } else {
        Get.offAllNamed(r);
        await settle(quietMs: 250, maxSeconds: 15);
      }
      (per[r.split('/').take(3).join('/')] ??= []).add(sw.elapsedMilliseconds);
    }
    if (i.isOdd) {
      Get.offAllNamed(AppRoutes.dashboard);
      await settle(quietMs: 250);
    }
    if (i % 10 == 0) {
      rssSeries.add(rssMb());
      mark('nav_loop:$i');
      log('  vuelta $i rss=${rssMb()}MB');
    }
  }
  rssSeries.add(rssMb());
  x['vueltas'] = n;
  x['rss_serie_mb'] = rssSeries;
  x['p95_por_pantalla_ms'] = {for (final e in per.entries) e.key: pct(e.value, .95)};
}

/// Llavero EN MEMORIA: la app real de este Mac guarda su sesión en el llavero
/// de macOS con el mismo grupo; la prueba NO debe leerla ni borrarla.
class _MemoryKeychain extends FlutterSecureStoragePlatform {
  final _m = <String, String>{};
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async => _m[key] = value;
  @override
  Future<String?> read({required String key, required Map<String, String> options}) async => _m[key];
  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async => _m.containsKey(key);
  @override
  Future<void> delete({required String key, required Map<String, String> options}) async => _m.remove(key);
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async => Map.of(_m);
  @override
  Future<void> deleteAll({required Map<String, String> options}) async => _m.clear();
}

// ── Arranque ──
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStoragePlatform.instance = _MemoryKeychain();
  final docs = (await getApplicationDocumentsDirectory()).path;
  if (!docs.contains('baudex-qa-home')) {
    log('ABORTADO: no es la carpeta aislada de pruebas ($docs)');
    exit(2);
  }
  await initializeDateFormatting('es_CO', null);
  tz.initializeTimeZones();
  await EnvConfig.initialize();
  dotenv.env
    ..['SERVER_IP'] = '127.0.0.1'
    ..['SERVER_PORT'] = port
    ..['APP_ENV'] = 'development';
  if (!EnvConfig.baseUrl.startsWith('http://127.0.0.1:$port')) {
    log('ABORTADO: la URL no es la de pruebas (${EnvConfig.baseUrl})');
    exit(3);
  }
  await IsarDatabase.instance.initialize();
  InitialBinding().dependencies();
  SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
  SchedulerBinding.instance.addPersistentFrameCallback((_) => _frameCount++);

  final info = await developer.Service.getInfo();
  log('VM_SERVICE ${info.serverUri}');
  log('PID $pid');

  final prevFlutterError = FlutterError.onError;
  FlutterError.onError = (d) {
    errors.add('[$currentScenario] FlutterError ${d.exceptionAsString()}\n${d.stack}');
    log('ERROR [$currentScenario] ${d.exceptionAsString()}');
    prevFlutterError?.call(d);
  };
  runZonedGuarded(() {
    runApp(RepaintBoundary(key: _rootKey, child: const MyApp()));
  }, (e, st) {
    errors.add('[$currentScenario] Zona $e\n$st');
    log('ERROR(zona) [$currentScenario] $e');
  });
  // La app pone su propio PlatformDispatcher.onError en algún punto: lo
  // envolvemos después de arrancar para no perder errores que ella "traga".
  Future.delayed(const Duration(seconds: 3), () {
    final prev = ui.PlatformDispatcher.instance.onError;
    ui.PlatformDispatcher.instance.onError = (e, st) {
      errors.add('[$currentScenario] PlatformDispatcher $e\n$st');
      log('ERROR(plataforma) [$currentScenario] $e');
      return prev?.call(e, st) ?? true;
    };
  });
  _startHeartbeat();
  unawaited(_run());
}

Future<void> _run() async {
  try {
    for (final step in steps) {
      log('--- $step');
      switch (step) {
        case 'login':
          await scenario('login', (_) => _login());
        case 'descarga':
          await scenario('descarga_inicial', _download);
        case 'pos_escanear':
          await scenario('pos_escanear_${150 * scale}_lineas', _posScan);
        case 'pos_reescanear':
          await scenario('pos_reescanear_mismos', _posRescan);
        case 'pos_atajos':
          await scenario('pos_atajos_teclado', _posShortcuts);
        case 'pos_productos_ida_vuelta':
          await scenario('pos_productos_ida_vuelta', _posProductsRoundTrip);
        case 'busquedas':
          await scenario('busquedas', _searches);
        case 'factura_detalle':
          await scenario('factura_detalle', _invoiceDetail);
        case 'kardex_saldos_movs':
          await scenario('kardex_saldos_movimientos', _kardex);
        case 'nota_credito':
          await scenario('nota_credito_confirmar', _creditNotes);
        case 'orden_compra':
          await scenario('orden_compra_borrador_productos_detalle', _purchaseOrders);
        case 'nav_loop':
          await scenario('navegacion_bucle', _navLoop);
        case 'conteo':
          await scenario('conteo_en_equipo', (x) async {
            final isar = IsarDatabase.instance.database;
            x['productos'] = await isar.isarProducts.count();
            x['clientes'] = await isar.isarCustomers.count();
            x['facturas'] = await isar.isarInvoices.count();
            x['esperado'] = env['QA_EXPECT'] ?? '';
          });
        case 'reposo':
          await scenario('reposo_60s', (_) => Future.delayed(const Duration(seconds: 60)));
      }
    }
  } catch (e, st) {
    errors.add('FALLÓ: $e\n$st');
    log('FALLÓ: $e\n$st');
  }
  saveResults();
  mark('FIN');
  log('FIN errores=${errors.length}');
  await Future.delayed(const Duration(seconds: 3));
  exit(0);
}
