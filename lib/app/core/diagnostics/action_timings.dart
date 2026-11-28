// lib/app/core/diagnostics/action_timings.dart
//
// Registro liviano de cuánto tardan DE VERDAD las acciones clave en este
// equipo: iniciar sesión (por pasos), abrir el diálogo de pago, procesar la
// venta (por etapas) y navegar por el menú. Guarda las últimas muestras en
// memoria y en un archivo pequeño (para que sobrevivan a cerrar la app) y
// salen en Diagnóstico → Exportar reporte.
//
// Sin Flutter ni GetX (se prueba solo). Nunca lanza y nunca cambia el
// resultado de lo que mide. No guarda datos del negocio: solo el nombre de
// la acción, la hora y los milisegundos.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Una acción medida.
class ActionSample {
  const ActionSample(this.at, this.action, this.ms, {this.note});

  final DateTime at;
  final String action;
  final int ms;

  /// Dato corto y no sensible ("sin internet", "falló").
  final String? note;

  Map<String, Object?> toJson() => {
        't': at.toUtc().toIso8601String(),
        'a': action,
        'ms': ms,
        if (note != null) 'n': note,
      };

  static ActionSample? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse('${raw['t']}');
    final action = raw['a'];
    final ms = raw['ms'];
    if (at == null || action is! String || ms is! num) return null;
    final note = raw['n'];
    return ActionSample(at, action, ms.round(), note: note is String ? note : null);
  }
}

/// Una medición abierta: se cierra con [end] (una sola vez).
class ActionSpan {
  ActionSpan._(this._owner, this.action) : _watch = Stopwatch()..start();

  final ActionTimings _owner;
  final String action;
  final Stopwatch _watch;
  bool _done = false;

  int get elapsedMs => _watch.elapsedMilliseconds;

  void end({String? note}) {
    if (_done) return;
    _done = true;
    _owner.record(action, _watch.elapsedMilliseconds, note: note);
  }

  /// Deja de medir sin anotar nada (la acción no llegó a pasar).
  void cancel() => _done = true;
}

class ActionTimings {
  ActionTimings({this.capacity = 150, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// Una sola para toda la app.
  static final ActionTimings instance = ActionTimings();

  /// Desde cuántos ms una acción se considera lenta / muy lenta.
  static const int slowMs = 1000;
  static const int verySlowMs = 4000;

  /// Cada cuánto, como mucho, se escribe el archivo.
  static Duration saveDelay = const Duration(seconds: 8);

  final int capacity;
  final DateTime Function() _now;
  final List<ActionSample> _samples = [];
  File? _file;
  Timer? _saveTimer;
  bool _saving = false;
  bool _dirty = false;

  List<ActionSample> get samples => List.unmodifiable(_samples);

  /// Anota una acción ya medida.
  void record(String action, int ms, {String? note}) {
    try {
      _samples.add(ActionSample(_now(), action, ms < 0 ? 0 : ms, note: _short(note)));
      if (_samples.length > capacity) {
        _samples.removeRange(0, _samples.length - capacity);
      }
      _scheduleSave();
    } catch (_) {}
  }

  /// Empieza a medir [action]; se cierra con `end()`.
  ActionSpan start(String action) => ActionSpan._(this, action);

  /// Mide [body] como [action]. No cambia su resultado ni su error.
  Future<T> measure<T>(String action, FutureOr<T> Function() body) async {
    final span = start(action);
    try {
      final result = await body();
      span.end();
      return result;
    } catch (_) {
      span.end(note: 'falló');
      rethrow;
    }
  }

  static String? _short(String? note) {
    if (note == null) return null;
    final line = note.split('\n').first.trim();
    return line.length > 60 ? '${line.substring(0, 60)}…' : line;
  }

  // ---------------- archivo pequeño ----------------

  /// Carga lo guardado en [file] (de ejecuciones anteriores) y desde ahora
  /// guarda ahí. Nunca lanza.
  Future<void> attach(File file) async {
    _file = file;
    try {
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return;
      final old = [
        for (final row in decoded)
          if (ActionSample.fromJson(row) case final sample?) sample,
      ];
      // Lo de antes va primero; lo medido en este arranque, después.
      _samples.insertAll(0, old);
      if (_samples.length > capacity) {
        _samples.removeRange(0, _samples.length - capacity);
      }
    } catch (_) {}
  }

  void _scheduleSave() {
    if (_file == null) return;
    _dirty = true;
    _saveTimer ??= Timer(saveDelay, () {
      _saveTimer = null;
      unawaited(save());
    });
  }

  /// Escribe el archivo ahora (sin forzar el disco: es un dato de apoyo).
  Future<void> save() async {
    final file = _file;
    if (file == null || _saving || !_dirty) return;
    _saving = true;
    _dirty = false;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode([for (final s in _samples) s.toJson()]));
    } catch (_) {
    } finally {
      _saving = false;
    }
  }

  // ---------------- reporte ----------------

  static String grade(int ms) =>
      ms >= verySlowMs ? 'MUY LENTO' : (ms >= slowMs ? 'lento' : 'rápido');

  /// Sección del reporte de Diagnóstico: resumen por acción y las últimas
  /// [last] muestras.
  String report({int last = 60}) {
    final b = StringBuffer()
      ..writeln('Tiempos reales de las acciones en este equipo '
          '(${_samples.length} muestras):');
    if (_samples.isEmpty) {
      b.writeln('  (todavía no se ha medido ninguna acción)');
      return b.toString();
    }
    final byAction = <String, List<int>>{};
    for (final s in _samples) {
      (byAction[s.action] ??= []).add(s.ms);
    }
    b.writeln('  Resumen (acción: veces, normal, peor):');
    for (final entry in byAction.entries) {
      final sorted = [...entry.value]..sort();
      final median = sorted[(sorted.length - 1) ~/ 2];
      b.writeln('    ${entry.key}: ${sorted.length}, $median ms, '
          '${sorted.last} ms — ${grade(median)}');
    }
    b.writeln('  Últimas acciones:');
    final from = _samples.length > last ? _samples.length - last : 0;
    for (final s in _samples.sublist(from)) {
      b.writeln('    ${s.at.toUtc().toIso8601String()} | ${s.action} | ${s.ms} ms'
          '${s.ms >= slowMs ? ' — ${grade(s.ms)}' : ''}'
          '${s.note == null ? '' : ' (${s.note})'}');
    }
    return b.toString();
  }

  /// Solo para pruebas.
  void debugClear() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _samples.clear();
    _file = null;
    _dirty = false;
  }
}
