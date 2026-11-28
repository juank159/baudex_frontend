import 'dart:io';

import 'package:baudex_desktop/app/core/diagnostics/action_timings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guarda las últimas muestras y descarta las más viejas', () {
    final t = ActionTimings(capacity: 3);
    for (var i = 0; i < 5; i++) {
      t.record('acción $i', i * 10);
    }
    expect(t.samples.map((s) => s.action), ['acción 2', 'acción 3', 'acción 4']);
  });

  test('medir no cambia el resultado ni el error de lo medido', () async {
    final t = ActionTimings();
    expect(await t.measure('ok', () async => 7), 7);
    await expectLater(
      t.measure<int>('mal', () async => throw StateError('x')),
      throwsStateError,
    );
    expect(t.samples.map((s) => s.action), ['ok', 'mal']);
    expect(t.samples.last.note, 'falló');
  });

  test('una medición abierta se anota una sola vez', () {
    final t = ActionTimings();
    final span = t.start('abrir');
    span.end();
    span.end();
    expect(t.samples, hasLength(1));
    t.start('cancelada').cancel();
    expect(t.samples, hasLength(1));
  });

  test('se guardan en un archivo pequeño y vuelven en el siguiente arranque', () async {
    final dir = await Directory.systemTemp.createTemp('baudex_tiempos');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/tiempos.json');

    final first = ActionTimings();
    await first.attach(file);
    first.record('Procesar venta: total', 5200, note: 'sin internet');
    first.record('Menú → /credits', 300);
    await first.save();
    first.debugClear();

    final second = ActionTimings();
    second.record('de este arranque', 10);
    await second.attach(file);
    expect(second.samples.map((s) => s.action),
        ['Procesar venta: total', 'Menú → /credits', 'de este arranque']);
    expect(second.samples.first.ms, 5200);
    expect(second.samples.first.note, 'sin internet');
    second.debugClear();
  });

  test('un archivo dañado no rompe nada', () async {
    final dir = await Directory.systemTemp.createTemp('baudex_tiempos');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/tiempos.json')..writeAsStringSync('{{{ no es json');
    final t = ActionTimings();
    await t.attach(file);
    expect(t.samples, isEmpty);
    t.debugClear();
  });

  test('el reporte resume por acción y marca lo lento', () {
    final t = ActionTimings();
    t.record('Abrir diálogo de pago', 120);
    t.record('Abrir diálogo de pago', 180);
    t.record('Procesar venta: total', 6500);
    final text = t.report();
    expect(text, contains('Abrir diálogo de pago: 2, 120 ms, 180 ms — rápido'));
    expect(text, contains('Procesar venta: total: 1, 6500 ms, 6500 ms — MUY LENTO'));
    expect(text, contains('| Procesar venta: total | 6500 ms — MUY LENTO'));
  });

  test('sin muestras, el reporte lo dice', () {
    expect(ActionTimings().report(), contains('todavía no se ha medido'));
  });
}
