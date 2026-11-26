// tool/probes/tecleo_medicion.dart
//
// Mide el tecleo A MANO sobre la app real (ver arranque_windows_probe.dart):
// manda teclas al sistema a ritmo de persona y anota, por tecla, cuánto
// tarda en llegar a la app, en cambiar el texto y en VERSE en pantalla
// (cuadro ya pintado). En Windows las teclas son de verdad (SendInput desde
// otro hilo, para que el ritmo no dependa del hilo de la app); fuera de
// Windows se simulan escribiendo en la caja (solo sirve para comprobar que
// la medición corre).
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

/// Reloj del motor en microsegundos (el mismo de los tiempos de cuadro y
/// el mismo en todos los hilos).
int tecleoNow() => developer.Timeline.now;

const String teclaEnter = 'ENTER';
const String teclaEscape = 'ESC';

int _vk(String key) => switch (key) {
      teclaEnter => VK_RETURN,
      teclaEscape => VK_ESCAPE,
      _ => key.codeUnitAt(0), // '0'..'9' = VK_0..VK_9
    };

/// Corre en otro isolate. Devuelve la hora de envío de cada tecla.
List<int> _sendKeys(List<int> keys, int gapMs) {
  final sent = <int>[];
  final input = calloc<INPUT>(2);
  try {
    for (final vk in keys) {
      final scan = MapVirtualKey(vk, 0);
      input[0]
        ..type = INPUT_KEYBOARD
        ..ki.wVk = vk
        ..ki.wScan = scan
        ..ki.dwFlags = 0;
      input[1]
        ..type = INPUT_KEYBOARD
        ..ki.wVk = vk
        ..ki.wScan = scan
        ..ki.dwFlags = KEYEVENTF_KEYUP;
      sent.add(developer.Timeline.now);
      SendInput(2, input, sizeOf<INPUT>());
      if (gapMs > 0) Sleep(gapMs);
    }
  } finally {
    calloc.free(input);
  }
  return sent;
}

/// Corre en otro isolate: una tecla que la app no usa (F15), cada [gapMs],
/// durante [seconds]. Devuelve la hora de envío de cada una.
List<int> _heartbeat(int seconds, int gapMs) {
  final sent = <int>[];
  final input = calloc<INPUT>(2);
  try {
    final until = developer.Timeline.now + seconds * 1000000;
    while (developer.Timeline.now < until) {
      input[0]
        ..type = INPUT_KEYBOARD
        ..ki.wVk = VK_F15
        ..ki.dwFlags = 0;
      input[1]
        ..type = INPUT_KEYBOARD
        ..ki.wVk = VK_F15
        ..ki.dwFlags = KEYEVENTF_KEYUP;
      sent.add(developer.Timeline.now);
      SendInput(2, input, sizeOf<INPUT>());
      Sleep(gapMs);
    }
  } finally {
    calloc.free(input);
  }
  return sent;
}

/// Atraso de la ventana en atender el teclado durante un rato.
class Latido {
  Latido(this.enviadas, this.llegaron, this.mas50, this.mas200, this.mas1000, this.peorMs);
  final int enviadas;
  final int llegaron;
  final int mas50;
  final int mas200;
  final int mas1000;
  final double peorMs;

  String get texto => enviadas == 0
      ? 'sin datos (solo en Windows)'
      : 'teclas de prueba: $enviadas, llegaron: $llegaron; envío → llega de más de 50 ms: $mas50, '
          'de más de 200 ms: $mas200, de más de 1 s: $mas1000, peor: ${peorMs.toStringAsFixed(0)} ms';
}

/// Trae la ventana de la app al frente (las teclas del sistema van a la
/// ventana activa). Devuelve una nota para el log.
Future<String> ventanaAlFrente() async {
  if (!Platform.isWindows) return 'teclas simuladas (no es Windows)';
  final name = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
  try {
    final main = FindWindow(name, nullptr);
    if (main == 0) return 'no se encontró la ventana de la app';
    ShowWindow(main, SW_RESTORE);
    BringWindowToTop(main);
    final ok = SetForegroundWindow(main);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'ventana al frente: ${GetForegroundWindow() == main} (SetForegroundWindow=$ok)';
  } finally {
    calloc.free(name);
  }
}

class _Cuadro {
  _Cuadro(this.numero, this.armadoEn);
  final int numero;
  final int armadoEn; // µs: el hilo de la app terminó este cuadro
  double? totalMs;
  int? pintadoEn; // µs: ya está en pantalla
}

/// Todas las cajas de texto montadas, en orden de pantalla.
List<EditableTextState> cajasDeTexto() {
  final found = <EditableTextState>[];
  void visit(Element element) {
    if (element is StatefulElement && element.state is EditableTextState) {
      found.add(element.state as EditableTextState);
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// La caja de texto que tiene el cursor, o null.
EditableTextState? cajaConFoco() {
  for (final box in cajasDeTexto()) {
    if (box.widget.focusNode.hasPrimaryFocus) return box;
  }
  return null;
}

/// ¿Hay en pantalla un texto que contenga [needle] (sin distinguir mayúsculas)?
bool hayTexto(String needle) {
  final wanted = needle.toLowerCase();
  var found = false;
  void visit(Element element) {
    if (found) return;
    final widget = element.widget;
    if (widget is Text && (widget.data ?? '').toLowerCase().contains(wanted)) {
      found = true;
      return;
    }
    if (widget is RichText && widget.text.toPlainText().toLowerCase().contains(wanted)) {
      found = true;
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// Los últimos textos montados (lo de encima: un diálogo, un aviso), para
/// saber qué hay en pantalla cuando algo no abre.
String textosEnPantalla({int last = 8}) {
  final texts = <String>[];
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && (widget.data ?? '').trim().isNotEmpty) {
      texts.add(widget.data!.trim());
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  final tail = texts.length > last ? texts.sublist(texts.length - last) : texts;
  return tail.map((t) => t.length > 40 ? '${t.substring(0, 40)}…' : t).join(' | ');
}

/// Resultado de una tanda de teclas.
class Tanda {
  Tanda(this.porTecla, this.cuadros, this.cuadrosMas50, this.cuadrosMas200, this.peorCuadroMs);

  /// Por tecla: (tecla, envío→llega a la app, envío→texto cambia,
  /// envío→se ve). null = no pasó en el tiempo de espera.
  final List<(String, double?, double?, double?)> porTecla;
  final int cuadros;
  final int cuadrosMas50;
  final int cuadrosMas200;
  final double peorCuadroMs;

  double? get peorVisibleMs {
    double? worst;
    for (final k in porTecla) {
      final v = k.$4;
      if (v != null && (worst == null || v > worst)) worst = v;
    }
    return worst;
  }

  bool get todasVisibles => porTecla.every((k) => k.$4 != null);

  static String _n(double? v) => v == null ? 'NO' : v.toStringAsFixed(0);

  String get detalle => porTecla
      .map((k) => '${k.$1}: llega ${_n(k.$2)} / texto ${_n(k.$3)} / visible ${_n(k.$4)} ms')
      .join('; ');

  String get cuadrosTexto => 'cuadros: $cuadros, de más de 50 ms: $cuadrosMas50, '
      'de más de 200 ms: $cuadrosMas200, peor: ${peorCuadroMs.toStringAsFixed(0)} ms';
}

class MedidorDeTecleo {
  final List<int> _llegadas = []; // µs de cada tecla que llegó a la app
  final List<int> _latidos = []; // µs de cada tecla de prueba (F15) que llegó
  final List<_Cuadro> _cuadros = [];
  final Map<int, _Cuadro> _porNumero = {};
  final List<(bool Function(), Completer<_Cuadro>)> _esperas = [];
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    HardwareKeyboard.instance.addHandler((event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f15) {
          _latidos.add(tecleoNow());
        } else {
          _llegadas.add(tecleoNow());
        }
      }
      return false;
    });
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      final numero = ui.PlatformDispatcher.instance.frameData.frameNumber;
      final cuadro = _Cuadro(numero, tecleoNow());
      _cuadros.add(cuadro);
      _porNumero[numero] = cuadro;
      _esperas.removeWhere((espera) {
        var ok = false;
        try {
          ok = espera.$1();
        } catch (_) {}
        if (ok) espera.$2.complete(cuadro);
        return ok;
      });
    });
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        final cuadro = _porNumero[t.frameNumber];
        if (cuadro == null) continue;
        cuadro.totalMs = t.totalSpan.inMicroseconds / 1000;
        cuadro.pintadoEn = t.timestampInMicroseconds(ui.FramePhase.rasterFinish);
      }
    });
  }

  /// Primer cuadro en el que [condition] ya se cumple (pide cuadros
  /// mientras espera). null si no pasó en [seconds].
  Future<_Cuadro?> _cuando(bool Function() condition, {int seconds = 10}) async {
    final done = Completer<_Cuadro>();
    final espera = (condition, done);
    _esperas.add(espera);
    final ticker = Timer.periodic(const Duration(milliseconds: 8), (_) {
      SchedulerBinding.instance.scheduleFrame();
    });
    SchedulerBinding.instance.scheduleFrame();
    try {
      return await done.future.timeout(Duration(seconds: seconds));
    } on TimeoutException {
      _esperas.remove(espera);
      return null;
    } finally {
      ticker.cancel();
    }
  }

  /// Hora en que el cuadro quedó en pantalla (espera el dato del motor).
  Future<int?> _pintado(_Cuadro? cuadro) async {
    if (cuadro == null) return null;
    for (var i = 0; i < 150 && cuadro.pintadoEn == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return cuadro.pintadoEn;
  }

  Future<List<int>> _mandar(List<String> keys, int gapMs, EditableTextState? box) async {
    if (Platform.isWindows) {
      final codes = keys.map(_vk).toList();
      return Isolate.run(() => _sendKeys(codes, gapMs));
    }
    // Simuladas: se escribe en la caja (no pasan por el teclado).
    final sent = <int>[];
    for (final key in keys) {
      sent.add(tecleoNow());
      _llegadas.add(tecleoNow());
      if (box != null && box.mounted) {
        final controller = box.widget.controller;
        if (key == teclaEnter) {
          box.widget.onSubmitted?.call(controller.text);
        } else if (key != teclaEscape) {
          final text = controller.text + key;
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
      await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
    return sent;
  }

  static double _ms(int from, int? to) => to == null ? -1 : (to - from) / 1000;

  /// Escribe [digits] en [box] a ritmo de persona y mide cada tecla.
  Future<Tanda> escribir(EditableTextState box, String digits, {int gapMs = 120}) async {
    start();
    final controller = box.widget.controller;
    // Cada tecla debe CAMBIAR el texto (no hacerlo crecer: si la caja sale
    // con su contenido seleccionado, la primera tecla lo reemplaza).
    final cambios = <int>[]; // µs de cada cambio de texto
    var anterior = controller.text;
    void onText() {
      if (controller.text == anterior) return; // solo se movió el cursor
      anterior = controller.text;
      cambios.add(tecleoNow());
    }

    controller.addListener(onText);
    final desdeCuadro = _cuadros.length;
    final desdeLlegada = _llegadas.length;
    final keys = digits.split('');
    // Las esperas se arman ANTES de mandar: si la app se traba, el cuadro
    // que por fin muestre cada carácter queda anotado.
    final visibles = [
      for (var i = 0; i < keys.length; i++)
        _cuando(() => cambios.length >= i + 1, seconds: 15),
    ];
    final sent = await _mandar(keys, gapMs, box);
    final porTecla = <(String, double?, double?, double?)>[];
    for (var i = 0; i < keys.length; i++) {
      final pintado = await _pintado(await visibles[i]);
      final llegada =
          desdeLlegada + i < _llegadas.length ? _llegadas[desdeLlegada + i] : null;
      final cambio = i < cambios.length ? cambios[i] : null;
      double? ms(int? at) => at == null ? null : _ms(sent[i], at);
      porTecla.add((keys[i], ms(llegada), ms(cambio), ms(pintado)));
    }
    controller.removeListener(onText);
    return _tanda(porTecla, desdeCuadro);
  }

  /// Manda [key] (Enter o Escape) y mide cuánto tarda en cumplirse
  /// [condition] y en verse. Devuelve (envío→cumple, envío→se ve).
  Future<(double?, double?)> pulsar(
    String key,
    bool Function() condition, {
    EditableTextState? box,
    int seconds = 10,
  }) async {
    start();
    final espera = _cuando(condition, seconds: seconds);
    final sent = await _mandar([key], 0, box);
    final cuadro = await espera;
    final pintado = await _pintado(cuadro);
    if (cuadro == null) return (null, null);
    return (_ms(sent.single, cuadro.armadoEn), pintado == null ? null : _ms(sent.single, pintado));
  }

  /// Cuadros desde [desdeCuadro] (índice interno) hasta ahora.
  Tanda _tanda(List<(String, double?, double?, double?)> porTecla, int desdeCuadro) {
    var mas50 = 0;
    var mas200 = 0;
    var peor = 0.0;
    final desde = desdeCuadro.clamp(0, _cuadros.length);
    for (final cuadro in _cuadros.skip(desde)) {
      final ms = cuadro.totalMs ?? 0;
      if (ms > 50) mas50++;
      if (ms > 200) mas200++;
      if (ms > peor) peor = ms;
    }
    return Tanda(porTecla, _cuadros.length - desde, mas50, mas200, peor);
  }

  /// Manda una tecla que la app no usa cada [gapMs] durante [seconds] y
  /// mide cuánto tarda la ventana en entregarla: si el hilo de la ventana
  /// está ocupado (un complemento leyendo un archivo, la voz cargando), las
  /// teclas llegan tarde aunque la app no esté trabada.
  Future<Latido> latido({required int seconds, int gapMs = 100}) async {
    start();
    if (!Platform.isWindows) {
      await Future<void>.delayed(Duration(seconds: seconds));
      return Latido(0, 0, 0, 0, 0, 0);
    }
    final desde = _latidos.length;
    final sent = await Isolate.run(() => _heartbeat(seconds, gapMs));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final got = _latidos.sublist(desde.clamp(0, _latidos.length));
    var mas50 = 0, mas200 = 0, mas1000 = 0;
    var peor = 0.0;
    for (var i = 0; i < sent.length && i < got.length; i++) {
      final ms = (got[i] - sent[i]) / 1000;
      if (ms > 50) mas50++;
      if (ms > 200) mas200++;
      if (ms > 1000) mas1000++;
      if (ms > peor) peor = ms;
    }
    return Latido(sent.length, got.length, mas50, mas200, mas1000, peor);
  }

  int get marca => _cuadros.length;

  /// Resumen de cuadros desde [marca] (para ventanas sin teclas).
  Tanda cuadrosDesde(int marca) => _tanda(const [], marca);

  /// Espera a que [condition] se cumpla; devuelve si pasó.
  Future<bool> esperar(bool Function() condition, {int seconds = 10}) async =>
      await _cuando(condition, seconds: seconds) != null;
}
