// lib/app/core/errors/automatic_work.dart
//
// Trabajo AUTOMÁTICO (el que el usuario no pidió): cargas al arrancar, al
// entrar, al abrir una pantalla y recargas de fondo.
//
// Regla de la casa: una petición automática que falla NO muestra un aviso
// de error en pantalla (el usuario no hizo nada y no puede hacer nada con
// "Error del servidor"). Queda anotada aquí, con ruta, código y mensaje, y
// sale en el reporte de Diagnóstico. Los avisos quedan para lo que el
// usuario SÍ pidió (guardar, buscar, refrescar con el botón…).
//
// Cómo se usa:
//  - quien arranca el trabajo automático lo envuelve:
//      AutomaticWork.run('clientes: carga al abrir', () => _cargar());
//    (las recargas de `CacheFirstMixin.refreshInBackground` y de
//    `SyncAutoRefreshMixin` ya vienen envueltas);
//  - quien muestra el aviso pregunta primero:
//      if (AutomaticWork.swallow(titulo, mensaje)) return;
//  - el cliente HTTP anota aquí cada petición fallida (ver DioClient).
//
// La marca viaja con la zona de Dart: sigue a todo lo que se espere
// (`await`) dentro de ese trabajo, también en otros archivos.
import 'dart:async';

const Symbol _automaticKey = #baudexAutomaticWork;

class AutomaticWork {
  AutomaticWork._();

  /// Nombre del trabajo automático en curso, o `null` si lo que corre lo
  /// pidió el usuario.
  static String? get current => Zone.current[_automaticKey] as String?;

  /// Corre [body] marcado como automático: sus errores no avisan en
  /// pantalla, quedan en [BackgroundFailureLog].
  static R run<R>(String source, R Function() body) =>
      runZoned(body, zoneValues: {_automaticKey: source});

  /// ¿Se debe callar este aviso de error? Sí si viene de un trabajo
  /// automático: en ese caso queda anotado y devuelve `true`.
  static bool swallow(String title, String message) {
    final source = current;
    if (source == null) return false;
    BackgroundFailureLog.instance.noteNotice(source, title, message);
    return true;
  }
}

/// Una falla anotada.
class BackgroundFailure {
  const BackgroundFailure({
    required this.at,
    required this.source,
    required this.message,
    this.method,
    this.route,
    this.statusCode,
  });

  final DateTime at;

  /// Qué trabajo la produjo ("acción del usuario" si no era automático).
  final String source;
  final String message;
  final String? method;
  final String? route;
  final int? statusCode;

  String get line {
    final request = route == null
        ? ''
        : '${method ?? 'GET'} $route → ${statusCode ?? 'sin respuesta'} — ';
    return '[${at.toIso8601String()}] $source: $request$message';
  }
}

/// Últimas fallas de peticiones y avisos callados. En memoria; sale en el
/// reporte de Diagnóstico.
class BackgroundFailureLog {
  BackgroundFailureLog({this.capacity = 60, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static final BackgroundFailureLog instance = BackgroundFailureLog();

  static const String userAction = 'acción del usuario';

  final int capacity;
  final DateTime Function() _now;
  final List<BackgroundFailure> _entries = [];

  /// Total de avisos de error que NO se mostraron por venir de trabajo
  /// automático, y de peticiones fallidas (automáticas y del usuario).
  int silencedNotices = 0;
  int failedRequests = 0;

  /// Aviso para errores 5xx de trabajo automático (lo conecta la app con
  /// el reporte de errores; aquí no se depende de él).
  void Function(BackgroundFailure failure)? onServerError;

  List<BackgroundFailure> get entries => List.unmodifiable(_entries);

  void _add(BackgroundFailure failure) {
    _entries.add(failure);
    if (_entries.length > capacity) _entries.removeAt(0);
  }

  /// Un aviso de error que no se mostró.
  void noteNotice(String source, String title, String message) {
    silencedNotices++;
    _add(BackgroundFailure(
      at: _now(),
      source: source,
      message: 'aviso no mostrado: $title — ${_short(message)}',
    ));
  }

  /// Una petición al servidor que falló (la anota el cliente HTTP).
  void noteRequest({
    required String method,
    required String route,
    int? statusCode,
    required String message,
  }) {
    failedRequests++;
    final failure = BackgroundFailure(
      at: _now(),
      source: AutomaticWork.current ?? userAction,
      method: method,
      route: _withoutQueryValues(route),
      statusCode: statusCode,
      message: _short(message),
    );
    _add(failure);
    final automatic = failure.source != userAction;
    if (automatic && (statusCode ?? 0) >= 500) {
      try {
        onServerError?.call(failure);
      } catch (_) {}
    }
  }

  void clear() {
    _entries.clear();
    silencedNotices = failedRequests = 0;
  }

  /// Texto para el reporte de diagnóstico.
  String report({int last = 30}) {
    final b = StringBuffer();
    b.writeln('Peticiones que fallaron y avisos automáticos callados '
        '(desde que se abrió la app):');
    b.writeln('  Peticiones fallidas: $failedRequests; avisos de error que NO '
        'se mostraron por ser de trabajo automático: $silencedNotices');
    if (_entries.isEmpty) {
      b.writeln('  (ninguna)');
      return b.toString();
    }
    for (final e in _entries.reversed.take(last)) {
      b.writeln('  ${e.line}');
    }
    return b.toString();
  }

  static String _short(String text) {
    final line = text.replaceAll('\n', ' ').trim();
    return line.length > 240 ? '${line.substring(0, 240)}…' : line;
  }

  /// La ruta sin los valores de la consulta (pueden traer datos del
  /// negocio: un nombre buscado, un documento): solo los nombres.
  static String _withoutQueryValues(String route) {
    final q = route.indexOf('?');
    if (q < 0) return route;
    final names = route
        .substring(q + 1)
        .split('&')
        .map((p) => p.split('=').first)
        .where((n) => n.isNotEmpty)
        .join('&');
    return names.isEmpty ? route.substring(0, q) : '${route.substring(0, q)}?$names';
  }
}

/// Evita pedir lo mismo varias veces seguidas: si ya hay una petición en
/// curso se comparte, y si la última terminó hace menos de [minInterval]
/// no se repite (salvo `force`).
class SharedRequest {
  SharedRequest({required this.minInterval, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Duration minInterval;
  final DateTime Function() _now;
  Future<void>? _running;
  DateTime? _finishedAt;

  /// Peticiones que se ahorraron (para el diagnóstico y las pruebas).
  int skipped = 0;

  Future<void> run(Future<void> Function() body, {bool force = false}) {
    final running = _running;
    if (running != null) {
      skipped++;
      return running;
    }
    final finished = _finishedAt;
    if (!force && finished != null && _now().difference(finished) < minInterval) {
      skipped++;
      return Future<void>.value();
    }
    return _running = body().whenComplete(() {
      _running = null;
      _finishedAt = _now();
    });
  }

  /// Cambió la sesión (otro usuario o negocio): lo siguiente se pide ya.
  void reset() => _finishedAt = null;
}
