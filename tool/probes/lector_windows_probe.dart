// tool/probes/lector_windows_probe.dart
//
// App de Windows que mide el lector de código de barras con TECLAS DE
// VERDAD: se las manda al sistema con SendInput (como una pistola USB) y
// anota lo que pasa en el formulario de factura real. Ver lector_probe.dart.
//
//   flutter build windows --release -t tool/probes/lector_windows_probe.dart
//   $env:BAUDEX_PROBE_OUT = 'C:\salida\lector.txt'
//   build\windows\x64\runner\Release\Baudex.exe
//
// Variables (todas opcionales):
//   BAUDEX_PROBE_OUT       archivo donde deja la tabla "MEDICION LECTOR | …"
//   BAUDEX_PROBE_LABEL     etiqueta (p. ej. "antes c05b2dd")
//   BAUDEX_PROBE_PRODUCTS  productos del catálogo (3000)
//   BAUDEX_PROBE_LINES     líneas ya puestas en la factura (0)
//   BAUDEX_PROBE_SCANS     lecturas por escenario (10)
//   BAUDEX_PROBE_KEY_MS    ms entre teclas del lector (1)
//   BAUDEX_PROBE_MAX_TEXT_MS  tope para "1ª tecla → código completo" (150)
//   BAUDEX_PROBE_MAX_LINE_MS  tope para "Enter → línea VISTA" (0 = no revisar)
//   BAUDEX_PROBE_KEYS      sendinput (por defecto) | postmessage
//
// Sale con 0 si todo bien, 1 si algún criterio falla, 2 si se colgó.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

import 'lector_probe.dart';

const _windowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

int _mainWindow() {
  final name = _windowClass.toNativeUtf16();
  try {
    return FindWindow(name, nullptr);
  } finally {
    calloc.free(name);
  }
}

int _viewWindow(int main) {
  final name = 'FLUTTERVIEW'.toNativeUtf16();
  try {
    return FindWindowEx(main, 0, name, nullptr);
  } finally {
    calloc.free(name);
  }
}

/// Teclas al sistema, desde otro hilo (isolate) para que el ritmo no
/// dependa del hilo de la app. [keys]: códigos de tecla virtual.
void _sendKeys(List<int> keys, int gapMs) {
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
      SendInput(2, input, sizeOf<INPUT>());
      if (gapMs > 0) Sleep(gapMs);
    }
  } finally {
    calloc.free(input);
  }
}

/// Plan B: los mismos mensajes de teclado directo a la ventana de Flutter
/// (pasan por el mismo camino del motor, sin depender de la sesión).
void _postKeys(int hwnd, List<int> keys, int gapMs) {
  for (final vk in keys) {
    final scan = MapVirtualKey(vk, 0);
    PostMessage(hwnd, WM_KEYDOWN, vk, 1 | (scan << 16));
    PostMessage(hwnd, WM_KEYUP, vk, 1 | (scan << 16) | (0xC0000000));
    if (gapMs > 0) Sleep(gapMs);
  }
}

class WindowsKeyInjector implements KeyInjector {
  WindowsKeyInjector({required this.postMessage});

  final bool postMessage;
  int _view = 0;

  @override
  String get name =>
      postMessage ? 'mensajes a la ventana (PostMessage)' : 'del sistema (SendInput)';

  @override
  Future<String?> prepare() async {
    final main = _mainWindow();
    if (main == 0) return 'no se encontró la ventana de la app';
    _view = _viewWindow(main);
    ShowWindow(main, SW_RESTORE);
    BringWindowToTop(main);
    final ok = SetForegroundWindow(main);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final front = GetForegroundWindow() == main;
    return 'ventana al frente: $front (SetForegroundWindow=$ok), '
        'vista de Flutter: ${_view != 0}';
  }

  List<int> _keys(String digits, bool enter) => [
        for (final ch in digits.codeUnits) ch, // '0'..'9' = VK_0..VK_9
        if (enter) VK_RETURN,
      ];

  @override
  Future<void> type(String digits, {required int gapMs, bool enter = true}) {
    final keys = _keys(digits, enter);
    final view = _view;
    final post = postMessage;
    return Isolate.run(
        () => post ? _postKeys(view, keys, gapMs) : _sendKeys(keys, gapMs));
  }

  @override
  Future<void> backspace(int count) {
    final keys = List<int>.filled(count, VK_BACK);
    final view = _view;
    final post = postMessage;
    return Isolate.run(() => post ? _postKeys(view, keys, 20) : _sendKeys(keys, 20));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  int number(String key, int fallback) => int.tryParse(env[key] ?? '') ?? fallback;
  final outPath = env['BAUDEX_PROBE_OUT'];
  final sink = outPath == null ? null : File(outPath);
  sink?.parent.createSync(recursive: true);
  sink?.writeAsStringSync('');
  void log(String line) {
    // ignore: avoid_print
    print(line);
    sink?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  FlutterError.onError = (details) =>
      log('MEDICION LECTOR | aviso de Flutter: ${details.exceptionAsString().split('\n').first}');

  // Si algo se cuelga, no dejar el trabajo esperando.
  Timer(const Duration(minutes: 6), () {
    log('MEDICION LECTOR | RESULTADO: FALLA — la sonda no terminó en 6 minutos');
    exit(2);
  });

  final result = await runLectorProbe(
    mount: (app) async => runApp(app),
    injector: WindowsKeyInjector(
      postMessage: (env['BAUDEX_PROBE_KEYS'] ?? 'sendinput') == 'postmessage',
    ),
    config: LectorProbeConfig(
      products: number('BAUDEX_PROBE_PRODUCTS', 3000),
      existingLines: number('BAUDEX_PROBE_LINES', 0),
      scans: number('BAUDEX_PROBE_SCANS', 10),
      keyGapMs: number('BAUDEX_PROBE_KEY_MS', 1),
      maxTextMs: number('BAUDEX_PROBE_MAX_TEXT_MS', 150),
      maxLineMs: number('BAUDEX_PROBE_MAX_LINE_MS', 0),
      label: env['BAUDEX_PROBE_LABEL'] ?? '',
    ),
    log: log,
  );
  exit(result.ok ? 0 : 1);
}
