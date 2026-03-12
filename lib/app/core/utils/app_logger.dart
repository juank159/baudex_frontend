import 'package:flutter/foundation.dart';

/// Logger centralizado para la aplicación Baudex
///
/// Proporciona métodos de logging consistentes con niveles de severidad:
/// - debug: Información detallada para desarrollo
/// - info: Información general de operaciones
/// - warning: Advertencias que no afectan el funcionamiento
/// - error: Errores que requieren atención
///
/// En modo release, solo se muestran warnings y errores.
///
/// Uso con métodos estáticos:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.w('Warning message');
/// AppLogger.e('Error message', error: e, stackTrace: st);
/// ```
///
/// O con la instancia global:
/// ```dart
/// logger.debug('message');
/// ```
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  // ==================== MÉTODOS ESTÁTICOS (RECOMENDADOS) ====================

  /// Log de debug - atajo estático
  static void d(String message, {String? tag, Object? data}) {
    _instance.debug(message, tag: tag, data: data);
  }

  /// Log de info - atajo estático
  static void i(String message, {String? tag}) {
    _instance.info(message, tag: tag);
  }

  /// Log de warning - atajo estático
  static void w(String message, {String? tag, Object? error}) {
    _instance.warning(message, tag: tag, error: error);
  }

  /// Log de error - atajo estático
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance.error(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log de sincronización - atajo estático
  static void syncLog(String message, {bool isError = false, Object? data}) {
    _instance.sync(message, isError: isError, data: data);
  }

  /// Log de red - atajo estático
  static void net(String message, {String? method, String? url, int? statusCode, Object? error}) {
    _instance.network(message, method: method, url: url, statusCode: statusCode, error: error);
  }

  /// Log de base de datos - atajo estático
  static void dbLog(String message, {String? collection, String? operation}) {
    _instance.db(message, collection: collection, operation: operation);
  }

  /// Log de cache - atajo estático
  static void cacheLog(String message, {String? key, bool hit = true}) {
    _instance.cache(message, key: key, hit: hit);
  }

  /// Iniciar medición de tiempo para una operación
  static Stopwatch startTimer(String operationName, {String? tag}) {
    _instance.debug('Starting: $operationName', tag: tag);
    return Stopwatch()..start();
  }

  /// Finalizar medición y loguear tiempo
  static void endTimer(String operationName, Stopwatch stopwatch, {String? tag, bool success = true}) {
    stopwatch.stop();
    final status = success ? 'completed' : 'failed';
    _instance.info('$operationName $status in ${stopwatch.elapsedMilliseconds}ms', tag: tag);
  }

  /// Log de métricas de sincronización
  static void syncMetrics({required int pending, required int completed, required int failed}) {
    _instance.info('Sync metrics - Pending: $pending, Completed: $completed, Failed: $failed', tag: 'SYNC');
  }

  // ==================== CONFIGURACIÓN ====================

  /// Habilitar/deshabilitar logs de debug (solo en modo debug)
  bool _debugEnabled = kDebugMode;

  /// Habilitar/deshabilitar todos los logs
  bool _enabled = true;

  /// Habilitar logs de debug
  void enableDebug() => _debugEnabled = true;

  /// Deshabilitar logs de debug
  void disableDebug() => _debugEnabled = false;

  /// Habilitar todos los logs
  void enable() => _enabled = true;

  /// Deshabilitar todos los logs
  void disable() => _enabled = false;

  /// Log de nivel DEBUG
  ///
  /// Solo se muestra en modo debug y cuando _debugEnabled es true.
  /// Útil para información detallada durante desarrollo.
  void debug(String message, {String? tag, Object? data}) {
    if (!_enabled || !_debugEnabled || !kDebugMode) return;

    final prefix = tag != null ? '[$tag]' : '[DEBUG]';
    debugPrint('$prefix $message');
    if (data != null) {
      debugPrint('  Data: $data');
    }
  }

  /// Log de nivel INFO
  ///
  /// Se muestra en modo debug para información general de operaciones.
  void info(String message, {String? tag}) {
    if (!_enabled || !kDebugMode) return;

    final prefix = tag != null ? '[$tag]' : '[INFO]';
    debugPrint('$prefix $message');
  }

  /// Log de nivel WARNING
  ///
  /// Se muestra siempre. Útil para advertencias que no afectan el funcionamiento.
  void warning(String message, {String? tag, Object? error}) {
    if (!_enabled) return;

    final prefix = tag != null ? '[$tag]' : '[WARN]';
    debugPrint('$prefix $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
  }

  /// Log de nivel ERROR
  ///
  /// Se muestra siempre. Para errores que requieren atención.
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;

    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    debugPrint('$prefix $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('  Stack: $stackTrace');
    }
  }

  /// Log de sincronización
  ///
  /// Categoría especial para operaciones de sync offline/online.
  void sync(String message, {bool isError = false, Object? data}) {
    if (!_enabled) return;

    final prefix = isError ? '[SYNC ERROR]' : '[SYNC]';
    debugPrint('$prefix $message');
    if (data != null && kDebugMode) {
      debugPrint('  Data: $data');
    }
  }

  /// Log de operación de red
  ///
  /// Categoría especial para operaciones HTTP.
  void network(
    String message, {
    String? method,
    String? url,
    int? statusCode,
    Object? error,
  }) {
    if (!_enabled || !kDebugMode) return;

    final statusEmoji = statusCode != null
        ? (statusCode >= 200 && statusCode < 300 ? '  ' : '  ')
        : '  ';

    final prefix = '[NET$statusEmoji]';
    final details = <String>[];

    if (method != null) details.add(method);
    if (statusCode != null) details.add('$statusCode');

    final detailsStr = details.isNotEmpty ? ' (${details.join(' ')})' : '';
    debugPrint('$prefix $message$detailsStr');

    if (url != null) {
      debugPrint('  URL: $url');
    }
    if (error != null) {
      debugPrint('  Error: $error');
    }
  }

  /// Log de cache
  ///
  /// Categoría especial para operaciones de cache local.
  void cache(String message, {String? key, bool hit = true}) {
    if (!_enabled || !kDebugMode) return;

    final emoji = hit ? 'HIT' : 'MISS';
    final prefix = '[CACHE $emoji]';
    debugPrint('$prefix $message');
    if (key != null) {
      debugPrint('  Key: $key');
    }
  }

  /// Log de base de datos
  ///
  /// Categoría especial para operaciones ISAR.
  void db(String message, {String? collection, String? operation}) {
    if (!_enabled || !kDebugMode) return;

    final prefix = '[DB]';
    final details = <String>[];

    if (collection != null) details.add(collection);
    if (operation != null) details.add(operation);

    final detailsStr = details.isNotEmpty ? ' (${details.join('.')})' : '';
    debugPrint('$prefix $message$detailsStr');
  }
}

/// Instancia global del logger
final logger = AppLogger();
