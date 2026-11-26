import 'package:baudex_desktop/app/core/diagnostics/startup_trace.dart';
import 'package:flutter_test/flutter_test.dart';

/// Línea de tiempo del arranque: tareas, trabas y cuadros lentos, con un
/// reloj de mentira.
void main() {
  late int now;
  late StartupTrace trace;

  setUp(() {
    now = 0;
    trace = StartupTrace(clock: () => now);
  });
  tearDown(() => trace.dispose());

  test('mide cada tarea sin cambiar su resultado ni su error', () async {
    final value = await trace.task('abrir la base', () async {
      now += 180;
      return 7;
    });
    expect(value, 7);
    await expectLater(
      trace.task('voz', () async {
        now += 40;
        throw StateError('sin voz');
      }),
      throwsStateError,
    );
    expect(trace.taskSync('registrar', () {
      now += 5;
      return 'ok';
    }), 'ok');
    trace.begin('sin terminar');

    expect(trace.timelineLines(), [
      't=0 ms | abrir la base | duró 180 ms',
      't=180 ms | voz | duró 40 ms (falló)',
      't=220 ms | registrar | duró 5 ms',
      't=225 ms | sin terminar | SIN TERMINAR',
    ]);
    final report = trace.report();
    expect(report, contains('abrir la base: 180 ms'));
    expect(report, contains('sin terminar: SIN TERMINAR'));
    expect(report, isNot(contains('registrar')), reason: 'lo que no pesa no se lista');
    expect(report, contains('1 tareas de menos de 20 ms'));
  });

  test('cuenta las trabas del primer minuto y dice qué corría', () async {
    trace.startPhase('al abrir');
    final slow = trace.begin('sincronización al abrir: limpieza');
    now = 10;
    trace.tick(); // a tiempo
    now = 400; // 380 ms sin atender nada
    trace.tick();
    trace.end(slow);
    now = 410;
    trace.tick();
    now = 1700; // 1,28 s
    trace.tick();

    final phase = trace.phases.single;
    expect(phase.stallsOver50, 2);
    expect(phase.stallsOver200, 2);
    expect(phase.stallsOver1000, 1);
    expect(phase.stalledMs, 380 + 1280);
    // Lo trabado se reparte: con una tarea medida corriendo (lo nuestro,
    // como mucho) y sin ninguna (sin turno de procesador o pintando).
    expect(phase.stalledInTasksMs, 380);
    expect(phase.stalledNoTaskMs, 1280);
    expect(phase.stalledByTask, {'sincronización al abrir: limpieza': 380});
    final text = trace.phaseLines().join('\n');
    expect(text, contains('Traba de 1280 ms en t=410 ms; corría: (ninguna tarea medida)'));
    expect(text, contains('Traba de 380 ms en t=10 ms; corría: sincronización al abrir: limpieza'));

    // Pasado el minuto ya no cuenta.
    for (now = 1710; now <= 61000; now += 10) {
      trace.tick();
    }
    now = 75000;
    trace.tick();
    expect(phase.stallsOver50, 2);
    expect(trace.measuring, isFalse);
  });

  test('separa cuadros lentos por armar (app) y por pintar (tarjeta gráfica)', () {
    trace.startPhase('al abrir');
    trace.recordFrame(buildMs: 4, rasterMs: 6);
    trace.recordFrame(buildMs: 70, rasterMs: 6);
    trace.recordFrame(buildMs: 5, rasterMs: 260);
    final phase = trace.phases.single;
    expect(phase.frames, 3);
    expect(phase.buildOver50, 1);
    expect(phase.rasterOver50, 1);
    expect(phase.rasterOver200, 1);
    expect(trace.report(), contains('pintar (tarjeta gráfica) de más de 50 ms: 1'));

    now = 61000;
    trace.recordFrame(buildMs: 900, rasterMs: 900);
    expect(phase.frames, 3);
  });

  test('un segundo tramo (tras iniciar sesión) se cuenta aparte; los '
      'momentos no se repiten', () {
    trace.startPhase('al abrir');
    trace.mark('pantalla de iniciar sesión');
    trace.mark('pantalla de iniciar sesión');
    now = 90000;
    trace.startPhase('tras iniciar sesión');
    now = 90010;
    trace.tick();
    now = 90300;
    trace.tick();
    expect(trace.phases[0].stallsOver50, 0);
    expect(trace.phases[1].stallsOver200, 1);
    expect(trace.marks, hasLength(1));
  });
}
