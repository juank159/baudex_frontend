// La lógica de la prueba de preferencias de Windows
// (tool/probes/prefs_windows_probe.dart), con el almacén nuevo y sin matar
// procesos: que cuente bien una vuelta buena y que detecte una pérdida.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/probes/prefs_windows_probe.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('baudex_prefs_probe_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  File prefs() => File('${dir.path}/nuevo/shared_preferences.json');
  List<String> tally() => File('${dir.path}/conteo.txt').readAsLinesSync();

  test('vueltas buenas cuentan como ok y el resultado cumple', () async {
    for (var i = 0; i < 6; i++) {
      await probeWrite('nuevo', dir.path, maxRounds: 2);
      await probeCheck('nuevo', dir.path);
    }
    expect(tally().every((l) => l.startsWith('nuevo|ok|')), isTrue, reason: '${tally()}');
    // Las tandas siguen donde iban: la última prometida es la 12.
    expect(tally().last.split('|')[2], '12');

    final lines = <String>[];
    final failures = await probeFinish(dir.path, lines.add);
    // ignore: avoid_print
    print(lines.join('\n'));
    expect(failures, 0);
    expect(lines.any((l) => l.contains('almacén nuevo, matar a mitad | OK')), isTrue);
    expect(lines.any((l) => l.contains('archivo dañado al arrancar | OK')), isTrue);
  });

  test('si lo prometido no está en disco, la vuelta cuenta como pérdida', () async {
    await probeWrite('nuevo', dir.path, maxRounds: 2);
    final old = prefs().readAsStringSync();
    await probeWrite('nuevo', dir.path, maxRounds: 1); // promete la tanda 3
    prefs().writeAsStringSync(old); // en disco quedó la 2
    File('${prefs().path}.bak').deleteSync();

    await probeCheck('nuevo', dir.path);

    expect(tally().single, startsWith('nuevo|perdio_confirmado|3|'));
    final lines = <String>[];
    expect(await probeFinish(dir.path, lines.add), greaterThan(0));
  });

  test('si el escritor nunca escribió, la vuelta no cuenta y no hay veredicto', () async {
    await probeCheck('nuevo', dir.path);
    expect(tally().single, startsWith('nuevo|sin_escritura|0|'));
    final lines = <String>[];
    expect(await probeFinish(dir.path, lines.add), greaterThan(0));
    expect(lines.join('\n'), contains('no es concluyente'));
  });
}
