import 'dart:async';
import 'dart:io';

import 'package:baudex_desktop/app/core/diagnostics/speed_test.dart';
import 'package:baudex_desktop/app/core/diagnostics/speed_test_probes.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/isar_core.dart';

SpeedCheck _check(String id, Future<double?> Function() run,
        {int repeat = 1, Duration timeout = const Duration(seconds: 20)}) =>
    SpeedCheck(
      id: id,
      title: 'Medición $id',
      hint: 'Pista de $id.',
      fastMs: 40,
      slowMs: 250,
      repeat: repeat,
      timeout: timeout,
      run: run,
    );

class _MemoryStore implements SecureKeyValueStore {
  final Map<String, String> values = {};
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  group('semáforo', () {
    test('rápido, lento y muy lento según los ms', () async {
      expect((await SpeedTestRunner.runCheck(_check('a', () async => 12))).grade, SpeedGrade.fast);
      expect((await SpeedTestRunner.runCheck(_check('b', () async => 200))).grade, SpeedGrade.slow);
      expect(
          (await SpeedTestRunner.runCheck(_check('c', () async => 2500))).grade, SpeedGrade.verySlow);
    });

    test('con varias repeticiones informa lo normal (mediana) y el peor caso', () async {
      final times = [10.0, 12.0, 900.0, 11.0, 13.0];
      var i = 0;
      final result = await SpeedTestRunner.runCheck(_check('disco', () async => times[i++], repeat: 5));
      expect(result.runs, 5);
      expect(result.medianMs, 12);
      expect(result.worstMs, 900);
      expect(result.grade, SpeedGrade.fast);
      expect(result.timeLabel, 'normal 12 ms · peor 900 ms');
    });

    test('textos: un solo valor si normal y peor son iguales, coma decimal y segundos', () {
      final check = _check('x', () async => 1);
      SpeedResult r(double median, double worst, {int runs = 5}) => SpeedResult(
          check: check, grade: SpeedGrade.fast, medianMs: median, worstMs: worst, runs: runs);
      expect(r(12, 12).timeLabel, '12 ms');
      expect(r(1.5, 1.5).timeLabel, '1,5 ms');
      expect(r(1.2, 6.4).timeLabel, 'normal 1,2 ms · peor 6,4 ms');
      expect(r(1850, 1850, runs: 1).timeLabel, 'tarda 1,9 segundos');
      expect(r(400, 2300).timeLabel, 'normal 400 ms · peor 2,3 segundos');
    });

    test('si el equipo va lento, el veredicto pide copiar el reporte para soporte', () {
      final check = _check('disco', () async => 1);
      SpeedReport report(SpeedGrade g) => SpeedReport(
            at: DateTime(2026, 11, 28),
            results: [SpeedResult(check: check, grade: g, medianMs: 900, runs: 1)],
            facts: const DeviceFacts([]),
            totalMs: 1,
          );
      const ask = ' Toque "Copiar reporte" y péguelo en el chat o correo de soporte.';
      expect(report(SpeedGrade.slow).verdict, endsWith(ask));
      expect(report(SpeedGrade.verySlow).verdict, endsWith(ask));
      expect(report(SpeedGrade.fast).verdict, isNot(contains('Copiar reporte')));
    });

    test('lo que no responde no deja la prueba colgada', () async {
      final result = await SpeedTestRunner.runCheck(_check(
        'almacén',
        () => Completer<double?>().future,
        timeout: const Duration(milliseconds: 50),
      ));
      expect(result.grade, SpeedGrade.failed);
      expect(result.error, contains('sin respuesta'));
    });

    test('un error queda anotado en una línea y sin correos', () async {
      final result = await SpeedTestRunner.runCheck(
          _check('x', () async => throw StateError('no pude con ana.perez@tienda.com\notra línea')));
      expect(result.grade, SpeedGrade.failed);
      expect(result.error, isNot(contains('ana.perez')));
      expect(result.error, isNot(contains('otra línea')));
    });

    test('lo que no aplica en este equipo no cuenta', () async {
      final runner = SpeedTestRunner(
        checks: [
          _check('a', () async => 5),
          _check('b', () async => speedNotApplicable),
        ],
        facts: () async => const DeviceFacts([]),
      );
      final report = await runner.run();
      expect(report.results[1].grade, SpeedGrade.skipped);
      expect(report.overall, SpeedGrade.fast);
    });
  });

  group('reporte', () {
    test('equipo con disco lento: veredicto, semáforo y texto para soporte', () async {
      final seen = <String>[];
      var cleaned = false;
      final runner = SpeedTestRunner(
        appVersion: '1.0.24 (25)',
        checks: [
          _check('disco', () async => 1800),
          _check('servidor', () async => 30),
        ],
        cleanup: () async => cleaned = true,
        facts: () async => const DeviceFacts([
          ('Carpeta de datos', r'C:\Users\<usuario>\OneDrive\Baudex — DENTRO DE OneDrive', true),
        ]),
      );
      final report = await runner.run(onResult: (r) => seen.add(r.check.id));
      expect(seen, ['disco', 'servidor']);
      expect(cleaned, isTrue);
      expect(report.overall, SpeedGrade.verySlow);
      expect(report.verdict, contains('muy lento en: medición disco'));
      final text = report.toText();
      expect(text, contains('Resultado general: MUY LENTO'));
      expect(text, contains('[MUY LENTO] Medición disco: tarda 1,8 segundos'));
      expect(text, contains('[RÁPIDO] Medición servidor: 30 ms'));
      expect(text, contains('<-- revisar'));
      expect(text, contains('Versión de la app: 1.0.24 (25)'));
    });

    test('si fallan los datos del equipo, el reporte sale igual', () async {
      final runner = SpeedTestRunner(
        checks: [_check('a', () async => 5)],
        facts: () async => throw StateError('sin datos'),
      );
      final report = await runner.run();
      expect(report.results, hasLength(1));
      expect(report.toText(), contains('no disponibles'));
    });
  });

  group('datos del equipo', () {
    test('la ruta no lleva el nombre del usuario', () {
      expect(maskUserInPath(r'C:\Users\Ana Perez\AppData\Roaming\Baudex'),
          r'C:\Users\<usuario>\AppData\Roaming\Baudex');
      expect(maskUserInPath('/Users/ana/Library/x'), '/Users/<usuario>/Library/x');
      expect(maskUserInPath(r'D:\Baudex'), r'D:\Baudex');
    });

    test('detecta carpetas que se sincronizan con la nube', () {
      expect(cloudFolderOf(r'C:\Users\ana\OneDrive\Escritorio\Baudex'), 'OneDrive');
      expect(cloudFolderOf(r'C:\Users\ana\OneDrive - Tienda SAS\Baudex'), 'OneDrive');
      expect(cloudFolderOf(r'D:\Nube\Baudex', cloudRoots: [r'D:\Nube']), 'OneDrive');
      expect(cloudFolderOf(r'C:\Users\ana\Dropbox\Baudex'), 'Dropbox');
      expect(cloudFolderOf(r'C:\Users\ana\AppData\Roaming\Baudex', cloudRoots: [null, '']), isNull);
    });

    test('detecta un programa abierto desde descargas, temporal o red', () {
      expect(riskyProgramLocation(r'C:\Users\ana\Downloads\baudex\baudex.exe'), contains('Descargas'));
      expect(riskyProgramLocation(r'C:\Users\ana\AppData\Local\Temp\Rar$1\baudex.exe'),
          contains('temporal'));
      expect(riskyProgramLocation(r'\\servidor\compartida\baudex.exe'), contains('red'));
      expect(riskyProgramLocation(r'C:\Program Files\Baudex\baudex.exe'), isNull);
    });
  });

  group('mediciones reales (carpeta temporal, sin datos del negocio)', () {
    late Directory dir;
    late HttpServer server;

    setUpAll(initIsarCore);

    setUp(() async {
      SharedPreferences.setMockInitialValues({'flutter.negocio': 'Tienda'});
      dir = await Directory.systemTemp.createTemp('baudex_velocidad');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..statusCode = 200
          ..write('ok')
          ..close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('mide disco, preferencias, almacén, base local y servidor, y no deja rastro', () async {
      final store = _MemoryStore()..values['token'] = 'no-tocar';
      final runner = buildDeviceSpeedTest(
        dataDir: () async => dir,
        secureStore: store,
        healthUrl: 'http://127.0.0.1:${server.port}/health',
      );
      final report = await runner.run();

      expect(report.results.map((r) => r.check.id), [
        'disk_write',
        'disk_read',
        'prefs_write',
        'prefs_read',
        'secure_write',
        'secure_read',
        'isar_open',
        'isar_write',
        'server',
      ]);
      for (final r in report.results) {
        expect(r.grade, isNot(SpeedGrade.failed), reason: '${r.check.id}: ${r.error}');
        expect(r.medianMs, isNotNull, reason: r.check.id);
      }
      expect(report.results.first.runs, 20);

      // Nada de la prueba queda en el equipo y nada del negocio se toca.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(dir.listSync(), isEmpty, reason: '${dir.listSync()}');
      expect(store.values, {'token': 'no-tocar'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'negocio'});

      final text = report.toText();
      expect(text, contains('Núcleos del procesador'));
      expect(text, contains('Carpeta de datos'));
    });

    test('con el servidor caído, esa medición sale "No respondió" y el resto sigue', () async {
      final port = server.port;
      await server.close(force: true);
      final runner = buildDeviceSpeedTest(
        dataDir: () async => dir,
        secureStore: _MemoryStore(),
        healthUrl: 'http://127.0.0.1:$port/health',
        includeIsar: false,
      );
      final report = await runner.run();
      expect(report.results.last.grade, SpeedGrade.failed);
      expect(report.results.first.grade, isNot(SpeedGrade.failed));
      expect(report.overall, SpeedGrade.failed);
    });
  });
}
