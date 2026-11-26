// tool/probes/equipo_lento.dart
//
// Modo "equipo lento" de la medición de arranque: deja a la app con pocos
// núcleos y prioridad baja, y le pone al lado carga de procesador y de
// disco, para parecerse a un PC de oficina con antivirus y otros programas
// abiertos (el equipo de pruebas de GitHub es mucho más holgado).
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Limita ESTE proceso a [cores] núcleos y prioridad por debajo de lo
/// normal. Solo en Windows. Devuelve una nota para el log.
String limitarProceso(int cores) {
  if (!Platform.isWindows) return 'sin límite de núcleos (no es Windows)';
  final process = GetCurrentProcess();
  final mask = (1 << cores.clamp(1, 16)) - 1;
  final affinity = SetProcessAffinityMask(process, mask);
  var priority = 0;
  try {
    final setPriorityClass = DynamicLibrary.open('kernel32.dll').lookupFunction<
        Int32 Function(IntPtr, Uint32),
        int Function(int, int)>('SetPriorityClass');
    priority = setPriorityClass(process, BELOW_NORMAL_PRIORITY_CLASS);
  } catch (_) {}
  return 'app limitada a $cores núcleo(s): ${affinity != 0 ? 'sí' : 'NO'}; '
      'prioridad baja: ${priority != 0 ? 'sí' : 'NO'}';
}

/// Ventana a pantalla completa (más píxeles que pintar, como en un monitor
/// de oficina). Solo en Windows.
void maximizarVentana() {
  if (!Platform.isWindows) return;
  final name = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
  try {
    final main = FindWindow(name, nullptr);
    if (main != 0) ShowWindow(main, SW_MAXIMIZE);
  } finally {
    calloc.free(name);
  }
}

void _burn(int _) {
  var x = 1;
  while (true) {
    for (var i = 0; i < 5000000; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
    }
    if (x == -1) break;
  }
}

void _churn(String dir) {
  final folder = Directory(dir)..createSync(recursive: true);
  final block = Uint8List(4 * 1024 * 1024);
  for (var i = 0; i < block.length; i += 4096) {
    block[i] = i & 0xff;
  }
  var n = 0;
  while (true) {
    final file = File('${folder.path}${Platform.pathSeparator}carga_${n++ % 4}.bin');
    try {
      file.writeAsBytesSync(block, flush: true);
      file.readAsBytesSync();
    } catch (_) {}
  }
}

/// Carga en paralelo: [cpu] bucles de procesador y uno que escribe y lee
/// archivos de 4 MB en [dir] sin parar. Como son hilos de este mismo
/// proceso, compiten con la app por los pocos núcleos que le quedaron.
Future<String> cargaDeFondo({required int cpu, required String dir}) async {
  for (var i = 0; i < cpu; i++) {
    await Isolate.spawn(_burn, i, debugName: 'carga_cpu_$i');
  }
  await Isolate.spawn(_churn, dir, debugName: 'carga_disco');
  return 'carga de fondo: $cpu bucle(s) de procesador y 1 de disco (archivos de 4 MB en $dir)';
}
