// tool/probes/prefs_windows_probe.dart
//
// Prueba en Windows real de las preferencias del equipo
// (lib/app/core/storage/durable_prefs_store.dart):
//
//  1. Un proceso hijo escribe 200 preferencias a la vez, sin parar, y se le
//     mata a mitad, varias veces. Con el almacén nuevo el archivo SIEMPRE
//     se puede abrir y conserva lo guardado. Con el complemento original
//     se cuenta cuántas veces quedó ilegible o vacío (demuestra la causa).
//  2. Archivo dañado al arrancar: se restaura de la copia y siguen la
//     marca de sesión, el negocio y las marcas de sincronización.
//
//   flutter build windows --release -t tool/probes/prefs_windows_probe.dart
//
// Variables: BAUDEX_PROBE_OUT (obligatoria: sin ella no hace nada),
// BAUDEX_PROBE_ROUNDS (por defecto 12). Solo para el equipo de pruebas:
// el modo "original" escribe en las preferencias reales de ese equipo.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:baudex_desktop/app/core/storage/durable_prefs_store.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _sentinel = 'flutter.centinela';
const _keys = 200;

Future<void> _writer(String store, String filePath) async {
  final SharedPreferencesStorePlatform target;
  if (store == 'nuevo') {
    target = DurablePrefsStore(File(filePath))..open();
  } else {
    // El complemento original, tal como viene registrado en Windows.
    target = SharedPreferencesStorePlatform.instance;
  }
  await target.setValue('String', _sentinel, 'sigo aquí');
  final payload = 'x' * 20000;
  var round = 0;
  while (true) {
    round++;
    await Future.wait([
      for (var i = 0; i < _keys; i++)
        target.setValue('String', 'flutter.k$i', '$round-$payload'),
    ]);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;

  final mode = env['BAUDEX_PREFS_PROBE_WRITER'];
  if (mode != null) {
    await _writer(mode, env['BAUDEX_PREFS_PROBE_FILE'] ?? '');
    return;
  }

  final outPath = env['BAUDEX_PROBE_OUT'];
  if (outPath == null || outPath.isEmpty) exit(3);
  final sink = File(outPath)..parent.createSync(recursive: true);
  sink.writeAsStringSync('');
  void log(String line) {
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  Timer(const Duration(minutes: 12), () {
    log('PRUEBA PREFERENCIAS | RESULTADO: FALLA — no terminó en 12 minutos');
    exit(2);
  });

  var failures = 0;
  final rounds = int.tryParse(env['BAUDEX_PROBE_ROUNDS'] ?? '') ?? 12;
  final random = Random(7);
  final dir = await Directory.systemTemp.createTemp('baudex_prefs_probe');
  log('PRUEBA PREFERENCIAS | inicio | ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion} | $rounds vueltas por almacén');

  try {
    final support = await getApplicationSupportDirectory();
    final originalFile = File(
      '${support.path}${Platform.pathSeparator}shared_preferences.json',
    );
    final newFile = File('${dir.path}${Platform.pathSeparator}shared_preferences.json');

    for (final store in ['original', 'nuevo']) {
      final file = store == 'nuevo' ? newFile : originalFile;
      var unreadable = 0, empty = 0, lost = 0, recovered = 0;
      for (var i = 0; i < rounds; i++) {
        if (store == 'original' && file.existsSync()) {
          // Cada vuelta del original parte de un archivo sano.
          try {
            json.decode(file.readAsStringSync());
          } catch (_) {
            file.deleteSync();
          }
        }
        final child = await Process.start(Platform.resolvedExecutable, [], environment: {
          'BAUDEX_PREFS_PROBE_WRITER': store,
          'BAUDEX_PREFS_PROBE_FILE': file.path,
        });
        unawaited(child.stdout.drain<void>());
        unawaited(child.stderr.drain<void>());
        // Arranque del motor + un momento cualquiera en plena escritura.
        await Future<void>.delayed(
          Duration(milliseconds: 2500 + random.nextInt(2500)),
        );
        child.kill();
        await child.exitCode.timeout(const Duration(seconds: 20), onTimeout: () => -1);
        await Future<void>.delayed(const Duration(milliseconds: 300));

        if (store == 'original') {
          // Lo que encontraría la app al abrir (así lee el complemento).
          try {
            final text = file.existsSync() ? file.readAsStringSync() : '';
            if (text.isEmpty) {
              empty++;
            } else {
              final data = json.decode(text) as Map;
              if (!data.containsKey(_sentinel)) lost++;
            }
          } catch (_) {
            unreadable++;
          }
        } else {
          final loaded = loadDurablePrefs(file);
          if (loaded.report.recovered) recovered++;
          if (loaded.report.source == PrefsLoadSource.empty) unreadable++;
          if (loaded.values[_sentinel] != 'sigo aquí') lost++;
        }
      }
      if (store == 'original') {
        final bad = unreadable + empty + lost;
        log('PRUEBA PREFERENCIAS | complemento original, matar a mitad | '
            'ilegible: $unreadable, vacío: $empty, sin el dato: $lost de $rounds '
            '| ${bad > 0 ? 'CAUSA DEMOSTRADA' : 'no se reprodujo en este equipo'}');
      } else {
        final ok = unreadable == 0 && lost == 0;
        if (!ok) failures++;
        log('PRUEBA PREFERENCIAS | almacén nuevo, matar a mitad | '
            '${ok ? 'OK' : 'FALLA'} | irrecuperable: $unreadable, '
            'sin el dato: $lost, recuperado de copia/temporal: $recovered de $rounds');
      }
    }

    // ---- Archivo dañado al arrancar ----
    final bootFile = File('${dir.path}${Platform.pathSeparator}arranque.json');
    const kept = {
      'baudex_secure_store_migrated_v1': 'true',
      'full_sync_business_v1': 'negocio-1',
      'sync_wm_v1|negocio-1|products': '2026-11-25T10:00:00.000Z',
      'default_printer_id': 'impresora-1',
    };
    await installDurablePrefs(fileOverride: bootFile);
    var prefs = await SharedPreferences.getInstance();
    for (final e in kept.entries) {
      await prefs.setString(e.key, e.value);
    }
    await prefs.setString('ultimo', 'cambio');
    await installedDurablePrefs!.flush();
    // Apagón: el archivo queda con el tamaño correcto pero lleno de ceros.
    bootFile.writeAsBytesSync(List<int>.filled(bootFile.lengthSync(), 0), flush: true);

    final report = await installDurablePrefs(fileOverride: bootFile);
    prefs = await SharedPreferences.getInstance();
    final missing = [
      for (final e in kept.entries)
        if (prefs.getString(e.key) != e.value) e.key,
    ];
    final ok = report != null && report.source == PrefsLoadSource.backup && missing.isEmpty;
    if (!ok) failures++;
    log('PRUEBA PREFERENCIAS | archivo dañado al arrancar | ${ok ? 'OK' : 'FALLA'} | '
        '$report${missing.isEmpty ? '' : ' | faltan: $missing'}');
  } catch (e, st) {
    failures++;
    log('PRUEBA PREFERENCIAS | excepción | FALLA | $e');
    log(st.toString().split('\n').take(6).join('\n'));
  } finally {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }

  log('PRUEBA PREFERENCIAS | RESULTADO: ${failures == 0 ? 'CUMPLE' : 'FALLA'}');
  exit(failures == 0 ? 0 : 1);
}
