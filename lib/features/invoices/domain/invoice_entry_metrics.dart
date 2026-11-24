// lib/features/invoices/domain/invoice_entry_metrics.dart
//
// Medición permanente y barata del buscador de la factura, para saber qué
// pasa en el equipo real del cliente: cuánto tarda en pintarse la opción
// después de una tecla, cuánto tarda el Enter, y en qué estado estaban el
// índice de códigos y la sincronización. Solo memoria (últimas muestras);
// sale en el reporte de diagnóstico. Sin Flutter ni GetX.

/// Estado del índice de códigos cortos y de la sincronización en el
/// momento de una tecla.
class EntryContext {
  final bool indexLoaded;
  final bool indexComplete;
  final bool indexStale;
  final int indexSize;
  final bool syncRunning;
  final bool fullDownloadPending;
  final int queueSize;

  const EntryContext({
    this.indexLoaded = false,
    this.indexComplete = false,
    this.indexStale = false,
    this.indexSize = 0,
    this.syncRunning = false,
    this.fullDownloadPending = false,
    this.queueSize = 0,
  });

  String get label => [
        !indexLoaded
            ? 'índice sin cargar'
            : 'índice ${indexComplete ? "completo" : "INCOMPLETO"}'
                '${indexStale ? " pendiente" : ""} ($indexSize)',
        if (syncRunning) 'sync corriendo',
        if (fullDownloadPending) 'descarga completa pendiente',
        'cola $queueSize',
      ].join(', ');
}

enum EntryMetric {
  /// Tecla con un valor → opción "Producto sin registrar" pintada.
  keyToOption('Tecla → opción "sin registrar"'),

  /// Confirmación en segundo plano del valor (consulta local exacta).
  backgroundCheck('Confirmación en segundo plano'),

  /// Enter con un valor → diálogo del nombre pintado.
  enterToDialog('Enter → diálogo del nombre'),

  /// Enter en el diálogo (o producto elegido) → línea pintada en la factura.
  confirmToLine('Enter → línea en la factura'),

  /// Carga del índice de códigos cortos (lectura + armado).
  indexLoad('Carga del índice de códigos'),

  /// Búsqueda por texto (después de la pausa de tecleo).
  textSearch('Búsqueda por texto');

  const EntryMetric(this.title);
  final String title;
}

class EntrySample {
  final DateTime at;
  final double ms;
  final EntryContext context;
  const EntrySample(this.at, this.ms, this.context);
}

class EntryMetricSummary {
  final int count;
  final double medianMs;
  final double p95Ms;
  final double maxMs;
  final double lastMs;
  const EntryMetricSummary({
    required this.count,
    required this.medianMs,
    required this.p95Ms,
    required this.maxMs,
    required this.lastMs,
  });
}

/// Una impresión de tiquete: cuánto pasó desde que se pidió imprimir hasta
/// que el tiquete quedó enviado a la impresora, y cuánto de eso fue armar
/// el tiquete (logo, líneas) antes de enviarlo.
class PrintSample {
  final DateTime at;
  final double totalMs;
  final double buildMs;
  final bool ok;
  const PrintSample(this.at, this.totalMs, this.buildMs, this.ok);
}

class InvoiceEntryMetrics {
  InvoiceEntryMetrics({this.capacity = 200, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// Una sola para toda la app.
  static final InvoiceEntryMetrics instance = InvoiceEntryMetrics();

  /// Desde cuántos ms una muestra se guarda aparte como "lenta".
  static const double slowMs = 100;

  final int capacity;
  final DateTime Function() _now;
  final Map<EntryMetric, List<EntrySample>> _samples = {};
  final List<(EntryMetric, EntrySample)> _slow = [];
  final Map<EntryMetric, int> _totals = {};

  /// Teclas con un valor: cuántas pintaron la opción con el índice seguro y
  /// cuántas la pintaron "por confirmar" (índice sin cargar, incompleto o
  /// pendiente).
  int valueKeysCertain = 0;
  int valueKeysUnconfirmed = 0;

  /// Cuadros de pantalla lentos (los llena la app con los tiempos reales
  /// del motor): más de 50 ms y más de 200 ms, y el peor.
  int frames = 0;
  int framesOver50 = 0;
  int framesOver200 = 0;
  double worstFrameMs = 0;

  /// Último estado visto al facturar (índice, sincronización, cola).
  EntryContext? lastContext;

  /// Desde cuántos ms una impresión se cuenta como "lenta".
  static const double slowPrintMs = 1000;

  /// Impresiones por tipo de impresora ("USB Windows (directo)", "Red"…).
  final Map<String, List<PrintSample>> _prints = {};
  final Map<String, int> _printTotals = {};
  final Map<String, int> _printFailures = {};
  final Map<String, int> _printSlow = {};

  /// Guarda una impresión: [totalMs] va desde que se pidió imprimir hasta
  /// que el tiquete quedó enviado a la impresora (incluye la espera si
  /// había otro tiquete saliendo); [buildMs] es la parte de armar el tiquete.
  void recordPrint(
    String printerKind,
    double totalMs, {
    double buildMs = 0,
    bool ok = true,
  }) {
    final list = _prints.putIfAbsent(printerKind, () => []);
    list.add(PrintSample(_now(), totalMs, buildMs, ok));
    if (list.length > capacity) list.removeAt(0);
    _printTotals[printerKind] = (_printTotals[printerKind] ?? 0) + 1;
    if (!ok) {
      _printFailures[printerKind] = (_printFailures[printerKind] ?? 0) + 1;
    }
    if (totalMs >= slowPrintMs) {
      _printSlow[printerKind] = (_printSlow[printerKind] ?? 0) + 1;
    }
  }

  /// Tipos de impresora con al menos una impresión, en orden de aparición.
  List<String> get printerKinds => _prints.keys.toList();

  /// Resumen de las impresiones que SÍ salieron por ese tipo de impresora.
  EntryMetricSummary? printSummary(String printerKind) {
    final list = _prints[printerKind];
    if (list == null) return null;
    final ok = [for (final s in list) if (s.ok) s];
    if (ok.isEmpty) return null;
    final sorted = [for (final s in ok) s.totalMs]..sort();
    double at(double q) =>
        sorted[((sorted.length - 1) * q).round().clamp(0, sorted.length - 1)];
    return EntryMetricSummary(
      count: ok.length,
      medianMs: at(0.5),
      p95Ms: at(0.95),
      maxMs: sorted.last,
      lastMs: ok.last.totalMs,
    );
  }

  int printFailures(String printerKind) => _printFailures[printerKind] ?? 0;

  void record(EntryMetric metric, double ms, [EntryContext? context]) {
    if (context != null) lastContext = context;
    final sample = EntrySample(_now(), ms, context ?? const EntryContext());
    final list = _samples.putIfAbsent(metric, () => []);
    list.add(sample);
    if (list.length > capacity) list.removeAt(0);
    _totals[metric] = (_totals[metric] ?? 0) + 1;
    if (ms >= slowMs) {
      _slow.add((metric, sample));
      if (_slow.length > 30) _slow.removeAt(0);
    }
  }

  void recordFrame(double totalMs) {
    frames++;
    if (totalMs > 50) framesOver50++;
    if (totalMs > 200) framesOver200++;
    if (totalMs > worstFrameMs) worstFrameMs = totalMs;
  }

  EntryMetricSummary? summary(EntryMetric metric) {
    final list = _samples[metric];
    if (list == null || list.isEmpty) return null;
    final sorted = [for (final s in list) s.ms]..sort();
    double at(double q) =>
        sorted[((sorted.length - 1) * q).round().clamp(0, sorted.length - 1)];
    return EntryMetricSummary(
      count: _totals[metric] ?? list.length,
      medianMs: at(0.5),
      p95Ms: at(0.95),
      maxMs: sorted.last,
      lastMs: list.last.ms,
    );
  }

  void reset() {
    _samples.clear();
    _slow.clear();
    _totals.clear();
    lastContext = null;
    _prints.clear();
    _printTotals.clear();
    _printFailures.clear();
    _printSlow.clear();
    valueKeysCertain = valueKeysUnconfirmed = 0;
    frames = framesOver50 = framesOver200 = 0;
    worstFrameMs = 0;
  }

  /// Texto para el reporte de diagnóstico.
  String report({EntryContext? current}) {
    final b = StringBuffer();
    b.writeln('Rendimiento al facturar (desde que se abrió la app):');
    final state = current ?? lastContext;
    if (state != null) b.writeln('  Último estado al facturar: ${state.label}');
    final keys = valueKeysCertain + valueKeysUnconfirmed;
    b.writeln('  Teclas con un valor: $keys '
        '(opción segura: $valueKeysCertain, por confirmar: $valueKeysUnconfirmed)');
    var any = false;
    for (final m in EntryMetric.values) {
      final s = summary(m);
      if (s == null) continue;
      any = true;
      b.writeln('  ${m.title}: ${s.count} veces, '
          'normal ${_f(s.medianMs)} ms, 95 % bajo ${_f(s.p95Ms)} ms, '
          'peor ${_f(s.maxMs)} ms, última ${_f(s.lastMs)} ms');
    }
    if (!any) b.writeln('  (todavía no se ha facturado en esta sesión)');
    b.writeln('  Cuadros de pantalla: $frames, de más de 50 ms: $framesOver50, '
        'de más de 200 ms: $framesOver200, peor: ${_f(worstFrameMs)} ms');
    if (_slow.isNotEmpty) {
      b.writeln('  Lentas (≥ ${slowMs.toStringAsFixed(0)} ms), últimas ${_slow.length}:');
      for (final (m, s) in _slow.reversed.take(15)) {
        b.writeln('    [${s.at.toIso8601String()}] ${m.title}: '
            '${_f(s.ms)} ms — ${s.context.label}');
      }
    }
    _writePrints(b);
    return b.toString();
  }

  void _writePrints(StringBuffer b) {
    b.writeln('  Impresión del tiquete (imprimir → enviado a la impresora):');
    if (_prints.isEmpty) {
      b.writeln('    (todavía no se ha impreso en esta sesión)');
      return;
    }
    for (final kind in _prints.keys) {
      final list = _prints[kind]!;
      final total = _printTotals[kind] ?? list.length;
      final failed = _printFailures[kind] ?? 0;
      final slow = _printSlow[kind] ?? 0;
      final s = printSummary(kind);
      final line = StringBuffer('    $kind: $total veces');
      if (s != null) {
        final builds = [for (final p in list) if (p.ok) p.buildMs]..sort();
        line.write(', normal ${_f(s.medianMs)} ms, 95 % bajo ${_f(s.p95Ms)} ms, '
            'peor ${_f(s.maxMs)} ms, última ${_f(s.lastMs)} ms'
            ' (armar el tiquete: normal ${_f(builds[(builds.length - 1) ~/ 2])} ms)');
      }
      line.write(', de ${slowPrintMs.toStringAsFixed(0)} ms o más: $slow');
      line.write(', fallidas: $failed');
      if (failed > 0) {
        final last = list.lastWhere((p) => !p.ok, orElse: () => list.last);
        if (!last.ok) {
          line.write(' (última falla tras ${_f(last.totalMs)} ms, '
              '${last.at.toIso8601String()})');
        }
      }
      b.writeln(line);
    }
  }

  static String _f(double ms) => ms.toStringAsFixed(ms < 10 ? 1 : 0);
}
