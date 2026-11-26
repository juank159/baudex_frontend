// lib/app/core/diagnostics/startup_trace.dart
//
// Línea de tiempo del arranque: qué tarea corrió, cuándo y cuánto duró, y
// cuánto se trabó la pantalla en el primer minuto (al abrir) y en el minuto
// siguiente a iniciar sesión. Sale en Diagnóstico → Exportar reporte, para
// saber qué pesa en el equipo de un cliente sin tener que estar ahí.
//
// Sin Flutter ni GetX (se prueba solo). Los tiempos de cuadro los entrega
// `startup_trace_binding.dart`.
import 'dart:async';

/// Una tarea medida. [durationMs] es null mientras no termina.
class StartupTask {
  StartupTask(this.name, this.startMs);
  final String name;
  final int startMs;
  int? durationMs;
  bool failed = false;
}

/// Trabas y cuadros lentos de un tramo (p. ej. "al abrir").
class StartupPhase {
  StartupPhase(this.name, this.startMs, this.lengthMs);
  final String name;
  final int startMs;
  final int lengthMs;

  /// Trabas del hilo de la app (no pudo atender nada durante ese tiempo).
  int stallsOver50 = 0;
  int stallsOver200 = 0;
  int stallsOver1000 = 0;
  int stalledMs = 0;

  /// Las peores trabas: (momento ms, duración ms).
  final List<(int, int)> worstStalls = [];

  int frames = 0;
  int buildOver50 = 0;
  int buildOver200 = 0;
  int rasterOver50 = 0;
  int rasterOver200 = 0;
  double worstBuildMs = 0;
  double worstRasterMs = 0;

  /// Cuándo se informó el peor cuadro de pintar (ms; el motor avisa hasta
  /// un segundo después de pintarlo).
  int worstRasterAt = 0;

  bool contains(int atMs) => atMs >= startMs && atMs < startMs + lengthMs;
}

class StartupTrace {
  StartupTrace({int Function()? clock}) : _clock = clock;

  static final StartupTrace instance = StartupTrace();

  final int Function()? _clock;
  final Stopwatch _watch = Stopwatch()..start();

  static const int maxTasks = 300;
  static const int _tick = 10;
  static const Duration phaseLength = Duration(seconds: 60);

  final List<StartupTask> tasks = [];
  final List<(int, String)> marks = [];
  final List<StartupPhase> phases = [];
  Timer? _timer;
  int _lastTick = 0;

  /// Milisegundos desde que arrancó la medición.
  int get nowMs => _clock?.call() ?? _watch.elapsedMilliseconds;

  /// Mide [body] como la tarea [name]. Nunca cambia el resultado ni el
  /// error de [body].
  Future<T> task<T>(String name, FutureOr<T> Function() body) async {
    final entry = begin(name);
    try {
      return await body();
    } catch (_) {
      entry?.failed = true;
      rethrow;
    } finally {
      end(entry);
    }
  }

  /// Igual que [task], para trabajo que no espera a nada.
  T taskSync<T>(String name, T Function() body) {
    final entry = begin(name);
    try {
      return body();
    } catch (_) {
      entry?.failed = true;
      rethrow;
    } finally {
      end(entry);
    }
  }

  StartupTask? begin(String name) {
    if (tasks.length >= maxTasks) return null;
    final entry = StartupTask(name, nowMs);
    tasks.add(entry);
    return entry;
  }

  void end(StartupTask? entry) {
    if (entry == null || entry.durationMs != null) return;
    entry.durationMs = nowMs - entry.startMs;
  }

  /// Un momento: "primer cuadro", "pantalla de iniciar sesión", etc. Cada
  /// nombre se anota una sola vez.
  void mark(String name) {
    if (marks.length >= 60 || marks.any((m) => m.$2 == name)) return;
    marks.add((nowMs, name));
  }

  /// Empieza a contar trabas y cuadros lentos durante [phaseLength].
  void startPhase(String name) {
    if (phases.length >= 6) return;
    phases.add(StartupPhase(name, nowMs, phaseLength.inMilliseconds));
    _lastTick = nowMs;
    _timer ??= Timer.periodic(const Duration(milliseconds: _tick), (_) => tick());
  }

  StartupPhase? _phaseAt(int atMs) {
    for (final phase in phases.reversed) {
      if (phase.contains(atMs)) return phase;
    }
    return null;
  }

  /// Un latido del reloj de trabas. Público para las pruebas.
  void tick() {
    final now = nowMs;
    final late = now - _lastTick - _tick;
    final startedAt = _lastTick;
    _lastTick = now;
    final phase = _phaseAt(startedAt);
    if (phase == null) {
      if (phases.every((p) => now >= p.startMs + p.lengthMs)) {
        _timer?.cancel();
        _timer = null;
      }
      return;
    }
    if (late <= 50) return;
    phase.stallsOver50++;
    phase.stalledMs += late;
    if (late > 200) phase.stallsOver200++;
    if (late > 1000) phase.stallsOver1000++;
    phase.worstStalls.add((startedAt, late));
    phase.worstStalls.sort((a, b) => b.$2.compareTo(a.$2));
    if (phase.worstStalls.length > 10) phase.worstStalls.removeLast();
  }

  /// Un cuadro de pantalla: lo que tardó la app en armarlo y la tarjeta
  /// gráfica en pintarlo.
  void recordFrame({required double buildMs, required double rasterMs}) {
    final phase = _phaseAt(nowMs);
    if (phase == null) return;
    phase.frames++;
    if (buildMs > 50) phase.buildOver50++;
    if (buildMs > 200) phase.buildOver200++;
    if (rasterMs > 50) phase.rasterOver50++;
    if (rasterMs > 200) phase.rasterOver200++;
    if (buildMs > phase.worstBuildMs) phase.worstBuildMs = buildMs;
    if (rasterMs > phase.worstRasterMs) {
      phase.worstRasterMs = rasterMs;
      phase.worstRasterAt = nowMs;
    }
  }

  /// ¿Queda algún tramo midiendo? (para no dejar el reloj de cuadros puesto).
  bool get measuring => phases.any((p) => nowMs < p.startMs + p.lengthMs);

  /// Tareas que estaban corriendo en el momento [atMs].
  List<String> runningAt(int atMs, int lengthMs) => [
        for (final t in tasks)
          if (t.startMs <= atMs + lengthMs &&
              (t.durationMs == null || t.startMs + t.durationMs! >= atMs))
            t.name,
      ];

  /// Una línea por tarea y por momento, en orden: `t=… ms | tarea | duró …`.
  List<String> timelineLines() {
    final rows = <(int, String)>[
      for (final m in marks) (m.$1, 't=${m.$1} ms | ${m.$2} | momento'),
      for (final t in tasks)
        (
          t.startMs,
          't=${t.startMs} ms | ${t.name} | '
              '${t.durationMs == null ? 'SIN TERMINAR' : 'duró ${t.durationMs} ms'}'
              '${t.failed ? ' (falló)' : ''}',
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final r in rows) r.$2];
  }

  /// Una línea por tramo con las trabas y los cuadros lentos.
  List<String> phaseLines() => [
        for (final p in phases) ...[
          'Tramo "${p.name}" (desde t=${p.startMs} ms, ${p.lengthMs ~/ 1000} s): '
              'trabas de la app de más de 50 ms: ${p.stallsOver50}, '
              'de más de 200 ms: ${p.stallsOver200}, de más de 1 s: ${p.stallsOver1000}, '
              'tiempo trabado: ${p.stalledMs} ms',
          '  Cuadros: ${p.frames}; armar (app) de más de 50 ms: ${p.buildOver50}, '
              'de más de 200 ms: ${p.buildOver200}, peor ${p.worstBuildMs.toStringAsFixed(0)} ms; '
              'pintar (tarjeta gráfica) de más de 50 ms: ${p.rasterOver50}, '
              'de más de 200 ms: ${p.rasterOver200}, peor ${p.worstRasterMs.toStringAsFixed(0)} ms',
          if (p.worstRasterMs > 200)
            '  Peor cuadro de pintar: ${p.worstRasterMs.toStringAsFixed(0)} ms, informado en '
                't=${p.worstRasterAt} ms; corría: '
                '${_orNone(runningAt(p.worstRasterAt - p.worstRasterMs.round() - 1000, p.worstRasterMs.round() + 1000))}',
          for (final s in p.worstStalls)
            '  Traba de ${s.$2} ms en t=${s.$1} ms; corría: '
                '${_orNone(runningAt(s.$1, s.$2))}',
        ],
      ];

  static String _orNone(List<String> names) =>
      names.isEmpty ? '(ninguna tarea medida)' : names.join(', ');

  /// Sección del reporte de Diagnóstico.
  String report() {
    final b = StringBuffer()..writeln('Arranque de la app (tarea → ms):');
    final lines = timelineLines();
    if (lines.isEmpty) b.writeln('  (sin datos)');
    // Lo que no pesa no se lista: solo tareas de 20 ms o más, las que no
    // terminaron y los momentos.
    var hidden = 0;
    final rows = <(int, String)>[
      for (final m in marks) (m.$1, '  t=${m.$1} ms — ${m.$2}'),
    ];
    for (final t in tasks) {
      final d = t.durationMs;
      if (d != null && d < 20 && !t.failed) {
        hidden++;
        continue;
      }
      rows.add((
        t.startMs,
        '  t=${t.startMs} ms — ${t.name}: '
            '${d == null ? 'SIN TERMINAR' : '$d ms'}${t.failed ? ' (falló)' : ''}',
      ));
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    for (final r in rows) {
      b.writeln(r.$2);
    }
    if (hidden > 0) b.writeln('  ($hidden tareas de menos de 20 ms no se listan)');
    for (final line in phaseLines()) {
      b.writeln('  $line');
    }
    return b.toString();
  }

  /// Solo para pruebas y para la sonda.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
