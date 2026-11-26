// tool/probes/impresoras_windows_probe.dart
//
// App de prueba para Windows real (release). Ver impresoras_probe.dart.
//
//   flutter build windows --release -t tool/probes/impresoras_windows_probe.dart
//
// Variables: BAUDEX_PROBE_OUT (archivo de salida, obligatoria: sin ella no
// hace nada), BAUDEX_PRUEBA_IMPRESORA, BAUDEX_PRUEBA_SALIDA,
// BAUDEX_PROBE_CORRUPT_PREFS=1 (daña a propósito las preferencias de ESTE
// equipo: solo para el equipo de pruebas de GitHub), BAUDEX_PROBE_LABEL.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'impresoras_probe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final outPath = env['BAUDEX_PROBE_OUT'];
  if (outPath == null || outPath.isEmpty) {
    // Nunca correr por accidente en el equipo de un cliente.
    exit(3);
  }
  final sink = File(outPath);
  sink.parent.createSync(recursive: true);
  sink.writeAsStringSync('');
  void log(String line) {
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  FlutterError.onError = (details) => log(
    'PRUEBA IMPRESORAS | aviso de Flutter | '
    '${details.exceptionAsString().split('\n').first}',
  );

  Timer(const Duration(minutes: 8), () {
    log('PRUEBA IMPRESORAS | RESULTADO: FALLA — la prueba no terminó en 8 minutos');
    exit(2);
  });

  // Una pantalla mínima para que los avisos de la app tengan dónde salir.
  runApp(
    const GetMaterialApp(
      home: Scaffold(body: Center(child: Text('Prueba de impresoras'))),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 1));

  File? prefsFile;
  if (env['BAUDEX_PROBE_CORRUPT_PREFS'] == '1') {
    final dir = await getApplicationSupportDirectory();
    prefsFile = File('${dir.path}${Platform.pathSeparator}shared_preferences.json');
  }

  String? value(String key) {
    final v = env[key]?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  final result = await runZonedGuarded(
    () => runImpresorasProbe(
      config: ImpresorasProbeConfig(
        windowsPrinter: value('BAUDEX_PRUEBA_IMPRESORA'),
        printerOutput: value('BAUDEX_PRUEBA_SALIDA'),
        prefsFile: prefsFile,
        label: env['BAUDEX_PROBE_LABEL'] ?? '',
      ),
      log: log,
    ),
    (error, stack) => log('PRUEBA IMPRESORAS | error suelto | $error'),
  );
  exit((await result)?.ok == true ? 0 : 1);
}
