// tool/probes/prefs_windows_probe.dart
//
// Prueba en Windows real de las preferencias del equipo
// (lib/app/core/storage/durable_prefs_store.dart).
//
// Reglas que debe cumplir el almacén nuevo:
//  1. Un dato cuyo `set*` ya devolvió sobrevive a matar el proceso.
//  2. Un dato viejo nunca se pierde por una escritura posterior cortada.
//
// Baudex solo deja abrir UNA copia a la vez (el ejecutable tiene un
// candado de instancia única), así que no puede lanzar procesos hijos de
// sí mismo: la primera versión de esta prueba lo intentaba, los hijos se
// cerraban al instante sin escribir nada y el resultado no valía. Ahora el
// flujo de GitHub abre la app de una en una, según BAUDEX_PREFS_PROBE_MODE:
//
//   escribir  escribe 200 preferencias a la vez, sin parar; tras cada tanda
//             cuyo `set*` devolvió, anota el número de tanda en un archivo
//             aparte (con flush). El flujo la mata a mitad.
//   revisar   abre lo que quedó, lo compara con la última tanda anotada y
//             agrega una línea al conteo.
//   (vacío)   imprime el conteo, prueba "archivo dañado al arrancar" y
//             decide el resultado.
//
// BAUDEX_PREFS_PROBE_STORE = original | nuevo
// BAUDEX_PREFS_PROBE_DIR   = carpeta de trabajo (obligatoria)
// BAUDEX_PROBE_OUT         = archivo de salida (modo final)
// Solo para el equipo de pruebas: "original" usa las preferencias reales
// de ese equipo.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/storage/durable_prefs_store.dart';
import 'package:baudex_desktop/app/core/storage/value_protector.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _sentinel = 'flutter.centinela';
const _sentinelValue = 'dato viejo';
const _keys = 200;
final _sep = Platform.pathSeparator;

int _roundOf(Object? value) =>
    value is String ? int.tryParse(value.split('-').first) ?? 0 : 0;

Future<File> _prefsFile(String store, String dir) async => store == 'nuevo'
    ? File('$dir${_sep}nuevo${_sep}shared_preferences.json')
    : File(
        '${(await getApplicationSupportDirectory()).path}'
        '${_sep}shared_preferences.json',
      );

File _ackFile(String dir, String store) => File('$dir${_sep}confirmado-$store.txt');
File _tallyFile(String dir) => File('$dir${_sep}conteo.txt');

/// Última tanda anotada completa (0 si el escritor no alcanzó a anotar).
int _lastAck(File ack) {
  if (!ack.existsSync()) return 0;
  final lines = ack.readAsStringSync().split('\n');
  // La última línea puede haber quedado a medias: solo valen las cerradas.
  for (var i = lines.length - 2; i >= 0; i--) {
    final n = int.tryParse(lines[i].trim());
    if (n != null) return n;
  }
  return 0;
}

Future<void> probeWrite(String store, String dir, {int? maxRounds}) async {
  final file = await _prefsFile(store, dir);
  final SharedPreferencesStorePlatform target;
  if (store == 'nuevo') {
    target = DurablePrefsStore(file)..open();
  } else {
    target = SharedPreferencesStorePlatform.instance; // el complemento
  }
  final before = await target.getAllWithPrefix('');
  var round = _roundOf(before['flutter.k0']);
  final ack = _ackFile(dir, store)..parent.createSync(recursive: true);
  ack.writeAsStringSync('');

  await target.setValue('String', _sentinel, _sentinelValue);
  final payload = 'x' * 20000;
  final stopAt = maxRounds == null ? null : round + maxRounds;
  while (stopAt == null || round < stopAt) {
    round++;
    await Future.wait([
      for (var i = 0; i < _keys; i++)
        target.setValue('String', 'flutter.k$i', '$round-$payload'),
    ]);
    // Todos los `set*` de la tanda devolvieron: queda prometida.
    ack.writeAsStringSync('$round\n', mode: FileMode.append, flush: true);
  }
}

Future<void> probeCheck(String store, String dir) async {
  final file = await _prefsFile(store, dir);
  final ackFile = _ackFile(dir, store);
  final acked = _lastAck(ackFile);
  String outcome;
  var detail = '';

  if (acked == 0) {
    // Sin ninguna tanda prometida la vuelta no prueba nada.
    outcome = 'sin_escritura';
  } else if (store == 'nuevo') {
    final loaded = loadDurablePrefs(file);
    final values = loaded.values;
    final rounds = [for (var i = 0; i < _keys; i++) _roundOf(values['flutter.k$i'])];
    final lowest = rounds.reduce((a, b) => a < b ? a : b);
    if (loaded.report.source == PrefsLoadSource.empty) {
      outcome = 'irrecuperable';
    } else if (values[_sentinel] != _sentinelValue) {
      outcome = 'perdio_dato_viejo';
    } else if (lowest < acked) {
      outcome = 'perdio_confirmado';
      detail = 'en disco tanda $lowest, prometida $acked';
    } else {
      outcome = loaded.report.recovered ? 'ok_recuperado' : 'ok';
      detail = loaded.report.source.name;
    }
    // Dejarlo como lo dejaría el arranque de la app, para la vuelta siguiente.
    if (loaded.report.recovered && values.isNotEmpty) {
      await writeDurablePrefs(file, values);
    }
  } else {
    // Lo que encontraría la app al abrir, leído como lee el complemento.
    if (!file.existsSync()) {
      outcome = 'falta_archivo';
    } else {
      try {
        final text = file.readAsStringSync();
        if (text.isEmpty) {
          outcome = 'vacio';
        } else {
          final data = json.decode(text) as Map;
          final lowest = [
            for (var i = 0; i < _keys; i++) _roundOf(data['flutter.k$i']),
          ].reduce((a, b) => a < b ? a : b);
          if (data[_sentinel] != _sentinelValue) {
            outcome = 'perdio_dato_viejo';
          } else if (lowest < acked) {
            outcome = 'perdio_confirmado';
          } else {
            outcome = 'ok';
          }
        }
      } catch (_) {
        outcome = 'ilegible';
      }
    }
    // La vuelta siguiente del original parte de cero si quedó mal.
    if (outcome != 'ok' && file.existsSync()) file.deleteSync();
  }

  _tallyFile(dir).writeAsStringSync(
    '$store|$outcome|$acked|$detail\n',
    mode: FileMode.append,
    flush: true,
  );
  if (ackFile.existsSync()) ackFile.deleteSync();
}

Future<int> probeFinish(String dir, void Function(String) log) async {
  var failures = 0;
  log('PRUEBA PREFERENCIAS | inicio | ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}');

  final tally = _tallyFile(dir);
  final lines = tally.existsSync()
      ? tally.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList()
      : <String>[];
  for (final store in ['original', 'nuevo']) {
    final counts = <String, int>{};
    final details = <String>[];
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.first != store) continue;
      counts[parts[1]] = (counts[parts[1]] ?? 0) + 1;
      if (parts[1].startsWith('perdio') && parts.length > 3 && parts[3].isNotEmpty) {
        details.add(parts[3]);
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final valid = total - (counts['sin_escritura'] ?? 0);
    final good = (counts['ok'] ?? 0) + (counts['ok_recuperado'] ?? 0);
    final summary = (counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    if (store == 'original') {
      log('PRUEBA PREFERENCIAS | complemento original, matar a mitad | '
          '${valid == 0
              ? 'SIN DATOS'
              : good == valid
              ? 'no se dañó en este equipo'
              : 'CAUSA DEMOSTRADA'} | '
          'vueltas válidas: $valid de $total | $summary');
    } else {
      final ok = valid >= 6 && good == valid;
      if (!ok) failures++;
      log('PRUEBA PREFERENCIAS | almacén nuevo, matar a mitad | '
          '${ok ? 'OK' : 'FALLA'} | vueltas válidas: $valid de $total | $summary'
          '${details.isEmpty ? '' : ' | ${details.take(3).join('; ')}'}'
          '${valid < 6 ? ' | pocas vueltas válidas: la prueba no es concluyente' : ''}');
    }
  }

  // ---- Archivo dañado al arrancar ----
  final bootFile = File('$dir${_sep}arranque${_sep}shared_preferences.json');
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
  // Apagón: el archivo queda con su tamaño pero lleno de ceros.
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
      'origen: ${report?.source.name}, claves: ${report?.keys}'
      '${missing.isEmpty ? '' : ' | faltan: $missing'}');

  // ---- Cifrado de la copia de sesión (DPAPI), solo en Windows ----
  if (DpapiProtector.isSupported) {
    const protector = DpapiProtector();
    const secret = 'token.de.prueba-ñ-2026';
    final stored = protector.protect(secret);
    final back = stored == null ? null : protector.unprotect(stored);
    final tampered = stored == null
        ? null
        : protector.unprotect('${stored.substring(0, stored.length - 6)}AAAAAA');
    final okDpapi = stored != null &&
        stored.startsWith('dpapi:v2:') &&
        !stored.contains(secret) &&
        back == secret &&
        tampered == null &&
        protector.unprotect('dpapi:v1:AAAA') == null;
    if (!okDpapi) failures++;
    log('PRUEBA PREFERENCIAS | cifrado de la copia de sesión (DPAPI) | '
        '${okDpapi ? 'OK' : 'FALLA'} | cifra: ${stored != null}, '
        'descifra igual: ${back == secret}, alterado se rechaza: ${tampered == null}');
  } else {
    log('PRUEBA PREFERENCIAS | cifrado de la copia de sesión (DPAPI) | OMITIDA | solo en Windows');
  }

  log('PRUEBA PREFERENCIAS | RESULTADO: ${failures == 0 ? 'CUMPLE' : 'FALLA'}');
  return failures;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final dir = env['BAUDEX_PREFS_PROBE_DIR'] ?? '';
  // Nunca correr por accidente en el equipo de un cliente.
  if (dir.isEmpty) exit(3);
  Directory(dir).createSync(recursive: true);
  final mode = env['BAUDEX_PREFS_PROBE_MODE'] ?? '';
  final store = env['BAUDEX_PREFS_PROBE_STORE'] ?? 'nuevo';

  try {
    if (mode == 'escribir') {
      await probeWrite(store, dir); // no termina: la matan
      return;
    }
    if (mode == 'revisar') {
      await probeCheck(store, dir);
      exit(0);
    }
  } catch (e) {
    File('$dir${_sep}errores.txt').writeAsStringSync(
      '$mode $store: $e\n',
      mode: FileMode.append,
      flush: true,
    );
    exit(4);
  }

  final outPath = env['BAUDEX_PROBE_OUT'] ?? '$dir${_sep}preferencias.txt';
  final sink = File(outPath)..parent.createSync(recursive: true);
  sink.writeAsStringSync('');
  void log(String line) {
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  Timer(const Duration(minutes: 5), () {
    log('PRUEBA PREFERENCIAS | RESULTADO: FALLA — no terminó en 5 minutos');
    exit(2);
  });
  var failures = 1;
  try {
    failures = await probeFinish(dir, log);
    final errors = File('$dir${_sep}errores.txt');
    if (errors.existsSync()) {
      log('PRUEBA PREFERENCIAS | errores de la prueba | ${errors.readAsStringSync().trim()}');
    }
  } catch (e, st) {
    log('PRUEBA PREFERENCIAS | excepción | FALLA | $e');
    log(st.toString().split('\n').take(6).join('\n'));
  }
  exit(failures == 0 ? 0 : 1);
}
