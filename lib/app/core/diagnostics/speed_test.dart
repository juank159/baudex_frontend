// lib/app/core/diagnostics/speed_test.dart
//
// "Prueba de velocidad de este equipo": mide lo que la app necesita del
// computador (disco, almacén seguro, preferencias, base local, servidor) y
// lo califica con un semáforo, para saber por qué la app va lenta en un
// equipo sin tener que estar ahí.
//
// Sin Flutter ni GetX: cada medición es una función que se entrega desde
// fuera (las reales están en `speed_test_probes.dart`), así se prueba solo.
import 'dart:async';

enum SpeedGrade { fast, slow, verySlow, failed, skipped }

extension SpeedGradeX on SpeedGrade {
  String get label => switch (this) {
        SpeedGrade.fast => 'Rápido',
        SpeedGrade.slow => 'Lento',
        SpeedGrade.verySlow => 'Muy lento',
        SpeedGrade.failed => 'No respondió',
        SpeedGrade.skipped => 'No aplica',
      };
}

/// Una medición de la prueba.
class SpeedCheck {
  const SpeedCheck({
    required this.id,
    required this.title,
    required this.hint,
    required this.fastMs,
    required this.slowMs,
    required this.run,
    this.repeat = 1,
    this.timeout = const Duration(seconds: 20),
  });

  final String id;

  /// Lo que ve el cliente: "Guardar un archivo en el disco".
  final String title;

  /// Qué significa si sale lento (una frase, para el cliente).
  final String hint;

  /// Hasta [fastMs] es rápido; hasta [slowMs], lento; más, muy lento.
  final int fastMs;
  final int slowMs;

  /// Hace la operación UNA vez. Devuelve null si en este equipo no aplica.
  /// El tiempo lo toma la prueba, salvo que devuelva sus propios ms.
  final Future<double?> Function() run;

  final int repeat;

  /// Tope de cada repetición.
  final Duration timeout;

  SpeedGrade grade(double ms) =>
      ms <= fastMs ? SpeedGrade.fast : (ms <= slowMs ? SpeedGrade.slow : SpeedGrade.verySlow);
}

/// Sentinela: la medición no aplica en este equipo.
const double speedNotApplicable = -1;

class SpeedResult {
  const SpeedResult({
    required this.check,
    required this.grade,
    this.medianMs,
    this.worstMs,
    this.runs = 0,
    this.error,
  });

  final SpeedCheck check;
  final SpeedGrade grade;
  final double? medianMs;
  final double? worstMs;
  final int runs;
  final String? error;

  static String ms(double? v) =>
      v == null ? '—' : '${v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0)} ms';

  /// "12 ms" o "normal 12 ms · peor 340 ms".
  String get timeLabel {
    if (medianMs == null) return grade == SpeedGrade.skipped ? '—' : (error ?? '—');
    if (runs <= 1) return ms(medianMs);
    return 'normal ${ms(medianMs)} · peor ${ms(worstMs)}';
  }
}

/// Datos del equipo (sin nada sensible).
class DeviceFacts {
  const DeviceFacts(this.rows);

  /// (nombre, valor, ¿es una señal de alerta?)
  final List<(String, String, bool)> rows;
}

class SpeedReport {
  const SpeedReport({
    required this.at,
    required this.results,
    required this.facts,
    required this.totalMs,
    this.appVersion,
  });

  final DateTime at;
  final List<SpeedResult> results;
  final DeviceFacts facts;
  final int totalMs;
  final String? appVersion;

  /// El peor semáforo de la prueba.
  SpeedGrade get overall {
    var worst = SpeedGrade.fast;
    for (final r in results) {
      if (r.grade == SpeedGrade.skipped) continue;
      if (r.grade == SpeedGrade.failed) return SpeedGrade.failed;
      if (r.grade.index > worst.index) worst = r.grade;
    }
    return worst;
  }

  /// Una frase para el cliente.
  String get verdict {
    final bad = [
      for (final r in results)
        if (r.grade == SpeedGrade.verySlow || r.grade == SpeedGrade.failed) r,
    ];
    final slow = [
      for (final r in results)
        if (r.grade == SpeedGrade.slow) r,
    ];
    String names(List<SpeedResult> rows) {
      final shown = rows.take(3).map((r) => r.check.title.toLowerCase()).join('; ');
      return rows.length > 3 ? '$shown; y ${rows.length - 3} más' : shown;
    }

    if (bad.isNotEmpty) {
      return 'Este equipo va muy lento en: ${names(bad)}. ${bad.first.check.hint}';
    }
    if (slow.isNotEmpty) {
      return 'Este equipo va lento en: ${names(slow)}. ${slow.first.check.hint}';
    }
    return 'Este equipo responde rápido en todo lo que la app necesita.';
  }

  /// Texto para copiar o guardar y enviar a soporte.
  String toText() {
    final b = StringBuffer()
      ..writeln('=== Prueba de velocidad de este equipo (Baudex) ===')
      ..writeln('Fecha: ${at.toUtc().toIso8601String()}')
      ..writeln('Versión de la app: ${appVersion ?? 'desconocida'}')
      ..writeln('Resultado general: ${overall.label.toUpperCase()}')
      ..writeln(verdict)
      ..writeln()
      ..writeln('Mediciones:');
    for (final r in results) {
      b.writeln('  [${r.grade.label.toUpperCase()}] ${r.check.title}: ${r.timeLabel}'
          '${r.runs > 1 ? ' (${r.runs} veces)' : ''}'
          '${r.error != null && r.medianMs != null ? ' — ${r.error}' : ''}'
          ' | rápido hasta ${r.check.fastMs} ms, lento hasta ${r.check.slowMs} ms');
    }
    b
      ..writeln()
      ..writeln('Equipo:');
    for (final (name, value, alert) in facts.rows) {
      b.writeln('  $name: $value${alert ? '  <-- revisar' : ''}');
    }
    b.writeln('La prueba tardó $totalMs ms.');
    return b.toString();
  }
}

class SpeedTestRunner {
  SpeedTestRunner({
    required this.checks,
    required this.facts,
    this.cleanup,
    this.appVersion,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Borra lo que la prueba dejó en el equipo (archivo, clave y base de
  /// prueba). Con tope: si el disco no responde, la prueba termina igual.
  final Future<void> Function()? cleanup;

  final List<SpeedCheck> checks;
  final Future<DeviceFacts> Function() facts;
  final String? appVersion;
  final DateTime Function() _now;

  /// Corre una medición ([repeat] veces, cada una con su tope). Nunca lanza.
  static Future<SpeedResult> runCheck(SpeedCheck check) async {
    final times = <double>[];
    String? error;
    for (var i = 0; i < check.repeat; i++) {
      final watch = Stopwatch()..start();
      try {
        final own = await check.run().timeout(check.timeout);
        if (own == speedNotApplicable) {
          return SpeedResult(check: check, grade: SpeedGrade.skipped);
        }
        times.add(own ?? watch.elapsedMicroseconds / 1000);
      } on TimeoutException {
        error = check.timeout.inSeconds >= 1
            ? 'sin respuesta en ${check.timeout.inSeconds} s'
            : 'sin respuesta en ${check.timeout.inMilliseconds} ms';
        break;
      } catch (e) {
        error = _oneLine(e);
        break;
      }
      // Deja respirar a la pantalla entre repeticiones.
      await Future<void>.delayed(Duration.zero);
    }
    if (times.isEmpty) {
      return SpeedResult(check: check, grade: SpeedGrade.failed, error: error ?? 'sin datos');
    }
    times.sort();
    final median = times[(times.length - 1) ~/ 2];
    return SpeedResult(
      check: check,
      // Si alguna repetición no respondió, eso manda.
      grade: error != null ? SpeedGrade.failed : check.grade(median),
      medianMs: median,
      worstMs: times.last,
      runs: times.length,
      error: error,
    );
  }

  /// Corre todo, en orden. [onResult] avisa de cada medición al terminar.
  Future<SpeedReport> run({void Function(SpeedResult result)? onResult}) async {
    final watch = Stopwatch()..start();
    final results = <SpeedResult>[];
    for (final check in checks) {
      final result = await runCheck(check);
      results.add(result);
      try {
        onResult?.call(result);
      } catch (_) {}
    }
    try {
      await cleanup?.call().timeout(const Duration(seconds: 10));
    } catch (_) {}
    DeviceFacts device;
    try {
      device = await facts().timeout(const Duration(seconds: 10));
    } catch (e) {
      device = DeviceFacts([('Datos del equipo', 'no disponibles (${_oneLine(e)})', false)]);
    }
    return SpeedReport(
      at: _now(),
      results: results,
      facts: device,
      totalMs: watch.elapsedMilliseconds,
      appVersion: appVersion,
    );
  }

  static String _oneLine(Object error) {
    var text = '$error'.split('\n').first.trim();
    // Nada de correos en el reporte.
    text = text.replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<correo>');
    return text.length > 140 ? '${text.substring(0, 140)}…' : text;
  }
}

/// La última prueba hecha en esta ejecución (sale en el reporte exportado).
class SpeedTestHistory {
  SpeedTestHistory._();
  static SpeedReport? last;

  static String report() => last == null
      ? 'Prueba de velocidad de este equipo: no se ha hecho en esta ejecución '
          '(Diagnóstico → "Probar velocidad", o desde la pantalla de inicio de sesión).\n'
      : last!.toText();
}

// ---------------- reglas puras de los datos del equipo ----------------

/// Quita el nombre del usuario de una ruta (`C:\Users\ana\…` → `C:\Users\<usuario>\…`).
String maskUserInPath(String path) => path
    .replaceAllMapped(RegExp(r'^([A-Za-z]:[\\/]Users[\\/])[^\\/]+', caseSensitive: false),
        (m) => '${m[1]}<usuario>')
    .replaceAllMapped(RegExp(r'^(/Users/|/home/)[^/]+'), (m) => '${m[1]}<usuario>');

/// ¿La ruta está dentro de una carpeta que se sincroniza con la nube?
/// [cloudRoots]: carpetas de OneDrive que informa Windows.
String? cloudFolderOf(String path, {Iterable<String?> cloudRoots = const []}) {
  final lower = path.toLowerCase().replaceAll('/', '\\');
  for (final root in cloudRoots) {
    if (root == null || root.isEmpty) continue;
    if (lower.startsWith(root.toLowerCase().replaceAll('/', '\\'))) return 'OneDrive';
  }
  if (lower.contains('\\onedrive')) return 'OneDrive';
  if (lower.contains('\\dropbox')) return 'Dropbox';
  if (lower.contains('\\google drive') || lower.contains('\\googledrive')) return 'Google Drive';
  if (lower.contains('\\icloud')) return 'iCloud';
  return null;
}

/// ¿El programa se abre desde un sitio poco confiable (descargas, temporal,
/// un .zip abierto sin extraer, memoria USB o red)?
String? riskyProgramLocation(String executablePath) {
  final lower = executablePath.toLowerCase().replaceAll('/', '\\');
  if (lower.startsWith('\\\\')) return 'una carpeta de red';
  if (lower.contains('\\appdata\\local\\temp\\') || lower.contains('\\temp\\')) {
    return 'una carpeta temporal (¿se abrió desde el .zip sin extraer?)';
  }
  if (lower.contains('\\downloads\\') || lower.contains('\\descargas\\')) {
    return 'la carpeta de Descargas';
  }
  return null;
}

String formatBytes(int bytes) {
  const gb = 1024 * 1024 * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
}
